import Foundation
import SwiftUI
import UIKit
import Photos

// MARK: - 错误

enum APIError: LocalizedError {
    case message(String)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .message(let m): return m
        case .transport(let m): return m
        }
    }
}

// MARK: - 接口客户端

struct APIClient {

    static let base = "https://api-new.ifphp.com"
    /// 方法 B：直接读取本仓库的 Release（公开仓库，无需 token）
    static let releaseAPI = "https://api.github.com/repos/yr123466/VideoParse-iOS/releases/latest"
    static let releasePage = "https://github.com/yr123466/VideoParse-iOS/releases/latest"

    static let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1 VideoParse/1.0"
    static let mediaUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

    private static func makeRequest(_ url: URL, key: String?, accept: String) -> URLRequest {
        var req = URLRequest(url: url)
        req.timeoutInterval = 25
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.setValue(accept, forHTTPHeaderField: "Accept")
        if let key = key, !key.isEmpty {
            req.setValue(key, forHTTPHeaderField: "X-API-Key")
        }
        return req
    }

    static func parse(url: String, key: String) async throws -> ParseResponse {
        guard var comps = URLComponents(string: base + "/api/svparse") else {
            throw APIError.message("接口地址异常")
        }
        comps.queryItems = [
            URLQueryItem(name: "url", value: url),
            URLQueryItem(name: "key", value: key)
        ]
        guard let finalURL = comps.url else { throw APIError.message("接口地址异常") }

        let req = makeRequest(finalURL, key: key, accept: "application/json")
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.message("网络响应异常")
            }
            guard (200..<300).contains(http.statusCode) else {
                throw APIError.message("服务返回 HTTP \(http.statusCode)，请稍后重试")
            }
            guard let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
                throw APIError.message("返回数据格式异常，请稍后重试")
            }
            return ParseResponse(json: obj)
        } catch let err as APIError {
            throw err
        } catch {
            throw APIError.transport("网络请求失败：\(error.localizedDescription)")
        }
    }

    static func status() async throws -> (latency: Int, body: String) {
        guard let url = URL(string: base + "/system-api/market/apis/5") else {
            throw APIError.message("接口地址异常")
        }
        let req = makeRequest(url, key: nil, accept: "application/json")
        let start = Date()
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            let latency = Int(Date().timeIntervalSince(start) * 1000)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw APIError.message("节点返回异常状态")
            }
            return (latency, String(data: data, encoding: .utf8) ?? "")
        } catch let err as APIError {
            throw err
        } catch {
            let latency = Int(Date().timeIntervalSince(start) * 1000)
            throw APIError.transport("连接超时或失败 (\(latency)ms)：\(error.localizedDescription)")
        }
    }

    static func checkUpdate() async throws -> AppUpdateInfo? {
        guard let url = URL(string: releaseAPI) else { return nil }
        var req = URLRequest(url: url)
        req.timeoutInterval = 18
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse, http.statusCode == 404 {
                return nil   // 还没有发布过 Release
            }
            guard let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
                return nil
            }
            let info = AppUpdateInfo(json: obj)
            return info.version.isEmpty ? nil : info
        } catch {
            throw APIError.transport("检查更新失败：\(error.localizedDescription)")
        }
    }
}

// MARK: - 下载模型

enum DownloadStatus: String {
    case pending
    case downloading
    case done
    case failed

    var label: String {
        switch self {
        case .pending: return "等待中"
        case .downloading: return "下载中"
        case .done: return "已完成"
        case .failed: return "失败"
        }
    }
}

struct DownloadItem: Identifiable {
    var id: UUID = UUID()
    var name: String
    var progress: Double = 0
    var status: DownloadStatus = .pending
    var savedURL: URL?
    var message: String?
    var sourceURL: String
}

struct SharePayload: Identifiable {
    let id = UUID()
    let items: [Any]
}

// MARK: - 下载管理器

final class DownloadManager: NSObject, ObservableObject {

    static let shared = DownloadManager()

    @Published var items: [DownloadItem] = []
    @Published var isVisible = false
    @Published var title = ""
    @Published var overall: Double = 0
    @Published var finished = false
    @Published var sharePayload: SharePayload?
    @Published var closedAutomatically = false

    private var session: URLSession!
    private var destinations: [Int: (id: UUID, url: URL)] = [:]
    private var results: [Int: Result<URL, Error>] = [:]
    private var continuations: [Int: CheckedContinuation<URL, Error>] = [:]

    override init() {
        super.init()
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 60
        cfg.timeoutIntervalForResource = 900
        cfg.allowsCellularAccess = true
        session = URLSession(configuration: cfg, delegate: self, delegateQueue: nil)
    }

    // MARK: 目录

    static var downloadDir: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("VideoParse", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func safeName(_ raw: String, maxLength: Int = 40) -> String {
        let invalid = CharacterSet(charactersIn: "/\\:*?\"<>|\n\r\t")
        var out = raw.components(separatedBy: invalid).joined(separator: "_")
        out = out.trimmingCharacters(in: .whitespacesAndNewlines)
        if out.isEmpty { out = "media" }
        if out.count > maxLength { out = String(out.prefix(maxLength)) }
        return out
    }

    /// 下载到临时目录（用于一次性任务，如存实况到相册）
    static func tempDownload(_ urlString: String, ext: String) async throws -> URL {
        guard let url = URL(string: urlString) else { throw APIError.message("地址无效") }
        var req = URLRequest(url: url)
        req.setValue(APIClient.mediaUserAgent, forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 60
        let (tmp, response) = try await URLSession.shared.download(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.message("下载失败")
        }
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("vp_\(UUID().uuidString).\(ext)")
        try? FileManager.default.removeItem(at: dest)
        try FileManager.default.moveItem(at: tmp, to: dest)
        return dest
    }

    static func savedFiles() -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: downloadDir, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey]))?
            .sorted { a, b in
                let da = (try? a.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let db = (try? b.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return da > db
            } ?? []
    }

    func cancelAll() {
        session.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
        DispatchQueue.main.async {
            self.finished = true
            for idx in self.items.indices where self.items[idx].status == .pending || self.items[idx].status == .downloading {
                self.items[idx].status = .failed
                self.items[idx].message = "已取消"
            }
        }
    }

    func dismiss() {
        isVisible = false
        items = []
        overall = 0
        finished = false
        title = ""
    }

    // MARK: 单文件

    func downloadSingle(url: String, filename: String, title: String, autoShare: Bool = true) {
        guard let src = URL(string: url) else { return }
        let item = DownloadItem(name: filename, sourceURL: url)
        self.title = title
        self.items = [item]
        self.overall = 0
        self.finished = false
        self.isVisible = true
        self.closedAutomatically = false

        Task {
            do {
                let dest = Self.uniqueDestination(Self.downloadDir.appendingPathComponent(filename))
                let saved = try await performDownload(src: src, dest: dest, id: item.id)
                await MainActor.run {
                    if let idx = self.items.firstIndex(where: { $0.id == item.id }) {
                        self.items[idx].status = .done
                        self.items[idx].progress = 1
                        self.items[idx].savedURL = saved
                    }
                    self.overall = 1
                    self.finished = true
                    if autoShare {
                        self.sharePayload = SharePayload(items: [saved])
                    }
                }
            } catch {
                await MainActor.run {
                    if let idx = self.items.firstIndex(where: { $0.id == item.id }) {
                        self.items[idx].status = .failed
                        self.items[idx].message = error.localizedDescription
                    }
                    self.finished = true
                }
            }
        }
    }

    // MARK: 批量

    func downloadBatch(urls: [String], baseTitle: String, ext: String, title: String) {
        guard !urls.isEmpty else { return }
        let safeTitle = Self.safeName(baseTitle)
        let stamp = Int(Date().timeIntervalSince1970)
        var buildItems: [DownloadItem] = []
        var plan: [(id: UUID, url: String, name: String)] = []
        for (index, link) in urls.enumerated() {
            let name = "\(safeTitle)_\(index + 1)_\(stamp).\(ext)"
            let item = DownloadItem(name: name, sourceURL: link)
            buildItems.append(item)
            plan.append((item.id, link, name))
        }

        self.title = title
        self.items = buildItems
        self.overall = 0
        self.finished = false
        self.isVisible = true
        self.closedAutomatically = false

        Task {
            var successCount = 0
            for entry in plan {
                await MainActor.run {
                    if let idx = self.items.firstIndex(where: { $0.id == entry.id }) {
                        self.items[idx].status = .downloading
                    }
                }
                guard let src = URL(string: entry.url) else { continue }
                do {
                    let dest = Self.uniqueDestination(Self.downloadDir.appendingPathComponent(entry.name))
                    let saved = try await performDownload(src: src, dest: dest, id: entry.id)
                    successCount += 1
                    await MainActor.run {
                        if let idx = self.items.firstIndex(where: { $0.id == entry.id }) {
                            self.items[idx].status = .done
                            self.items[idx].progress = 1
                            self.items[idx].savedURL = saved
                        }
                        self.recalculate()
                    }
                } catch {
                    await MainActor.run {
                        if let idx = self.items.firstIndex(where: { $0.id == entry.id }) {
                            self.items[idx].status = .failed
                            self.items[idx].message = error.localizedDescription
                        }
                        self.recalculate()
                    }
                }
            }
            let total = successCount
            await MainActor.run {
                self.finished = true
                self.recalculate()
                if total > 0 {
                    self.title = "\(title) · 成功 \(total)/\(self.items.count)"
                }
            }
        }
    }

    // MARK: 内部

    private static func uniqueDestination(_ url: URL) -> URL {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else { return url }
        let ext = url.pathExtension
        let base = url.deletingPathExtension().lastPathComponent
        let stamp = Int(Date().timeIntervalSince1970)
        let next = url.deletingLastPathComponent()
            .appendingPathComponent("\(base)_\(stamp)")
            .appendingPathExtension(ext)
        return next
    }

    private func performDownload(src: URL, dest: URL, id: UUID) async throws -> URL {
        var req = URLRequest(url: src)
        req.setValue(APIClient.mediaUserAgent, forHTTPHeaderField: "User-Agent")
        req.setValue("*/*", forHTTPHeaderField: "Accept")
        req.setValue("bytes=0-", forHTTPHeaderField: "Range")
        let task = session.downloadTask(with: req)
        task.taskDescription = id.uuidString
        return try await withCheckedThrowingContinuation { continuation in
            self.continuations[task.taskIdentifier] = continuation
            self.destinations[task.taskIdentifier] = (id, dest)
            task.resume()
        }
    }

    private func recalculate() {
        let done = items.filter { $0.status == .done }.count
        let failed = items.filter { $0.status == .failed }.count
        let inFlight = items.filter { $0.status == .downloading }
        var value = Double(done)
        for item in inFlight { value += item.progress }
        overall = items.isEmpty ? 0 : min(1, max(0, value / Double(items.count)))
        _ = failed
    }
}

extension DownloadManager: URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        guard let desc = downloadTask.taskDescription, let id = UUID(uuidString: desc) else { return }
        let taskID = downloadTask.taskIdentifier
        DispatchQueue.main.async {
            if let idx = self.items.firstIndex(where: { $0.id == id }) {
                self.items[idx].status = .downloading
                self.items[idx].progress = progress
            }
            _ = taskID
            self.recalculate()
        }
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        let key = downloadTask.taskIdentifier
        guard let info = destinations[key] else { return }
        do {
            try? FileManager.default.removeItem(at: info.url)
            try FileManager.default.moveItem(at: location, to: info.url)
            results[key] = .success(info.url)
        } catch {
            results[key] = .failure(error)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let key = task.taskIdentifier
        guard let continuation = continuations.removeValue(forKey: key) else { return }
        let stored = results.removeValue(forKey: key)
        destinations.removeValue(forKey: key)
        if let error = error {
            continuation.resume(throwing: error)
        } else if let stored = stored {
            continuation.resume(with: stored)
        } else {
            continuation.resume(throwing: APIError.message("下载失败，未获得文件"))
        }
    }
}

// MARK: - 相册保存

enum PhotoSaver {
    static func save(url: URL, isVideo: Bool) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw APIError.message("未获得相册写入权限，请在设置中允许访问相册")
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                if isVideo {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                } else {
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
                }
            }
        } catch {
            throw APIError.message("保存到相册失败：\(error.localizedDescription)")
        }
    }

    /// 保存一组实况照片（静态图 + 配对视频）为真正的 Live Photo
    static func saveLivePhoto(image: URL, video: URL, creationDate: Date? = nil) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw APIError.message("未获得相册写入权限，请在设置中允许访问相册")
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.creationDate = creationDate ?? Date()
                request.addResource(with: .photo, fileURL: image, options: nil)
                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = false
                request.addResource(with: .pairedVideo, fileURL: video, options: options)
            }
        } catch {
            throw APIError.message("保存实况失败：\(error.localizedDescription)")
        }
    }
}

// MARK: - 分享面板

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - 剪贴板

enum Clipboard {
    static func copy(_ text: String) {
        UIPasteboard.general.string = text
    }

    static func read() -> String? {
        UIPasteboard.general.string
    }
}
