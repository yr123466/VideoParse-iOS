import Foundation
import UIKit
import Photos

// MARK: - 媒体下载与保存 (对应 Android DownloadManager / SAF 自定义目录 / 相册保存)

enum MediaError: LocalizedError {
    case invalidURL
    case http(Int)
    case decodeFailed
    case saveFailed
    case permissionDenied
    case noCustomDir

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的媒体直链"
        case .http(let code): return "下载失败 HTTP \(code)"
        case .decodeFailed: return "图片数据解码失败"
        case .saveFailed: return "保存失败"
        case .permissionDenied: return "未获得相册访问权限，请前往系统设置开启"
        case .noCustomDir: return "未配置自定义保存目录"
        }
    }
}

final class MediaSaver {

    static let shared = MediaSaver()

    private init() {}

    // MARK: 下载到临时目录

    @discardableResult
    func downloadToTemporary(urlString: String, suggestedName: String) async throws -> URL {
        guard let url = URL(string: urlString) else { throw MediaError.invalidURL }
        let (tempURL, response) = try await URLSession.shared.download(from: url)
        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) {
            throw MediaError.http(http.statusCode)
        }
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(sanitizedFileName(suggestedName))
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: tempURL, to: destination)
        return destination
    }

    // MARK: 保存视频到相册

    func saveVideoToPhotos(urlString: String) async throws {
        let local = try await downloadToTemporary(
            urlString: urlString,
            suggestedName: "video_\(Int(Date().timeIntervalSince1970)).mp4"
        )
        try await ensurePhotoPermission()
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: local)
            }) { success, error in
                if success { cont.resume() }
                else { cont.resume(throwing: error ?? MediaError.saveFailed) }
            }
        }
    }

    // MARK: 保存图片到相册

    func saveImageToPhotos(urlString: String) async throws {
        guard let url = URL(string: urlString) else { throw MediaError.invalidURL }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else { throw MediaError.decodeFailed }
        try await ensurePhotoPermission()
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if success { cont.resume() }
                else { cont.resume(throwing: error ?? MediaError.saveFailed) }
            }
        }
    }

    // MARK: 保存到自定义目录（安全作用域书签）

    func saveToCustomDirectory(urlString: String,
                               filename: String,
                               settings: SettingsStore) async throws -> String {
        guard let dir = settings.resolveCustomSaveDir() else { throw MediaError.noCustomDir }
        let accessing = dir.startAccessingSecurityScopedResource()
        defer { if accessing { dir.stopAccessingSecurityScopedResource() } }

        let temp = try await downloadToTemporary(urlString: urlString,
                                                 suggestedName: filename)
        let destination = dir.appendingPathComponent(sanitizedFileName(filename))
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.copyItem(at: temp, to: destination)
        return settings.customSaveDirName
    }

    // MARK: 权限

    private func ensurePhotoPermission() async throws {
        let current = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if current == .authorized || current == .limited { return }
        let status: PHAuthorizationStatus = await withCheckedContinuation { cont in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { cont.resume(returning: $0) }
        }
        if status != .authorized && status != .limited {
            throw MediaError.permissionDenied
        }
    }

    // MARK: 文件名清洗（等价 Android 端正则替换）

    private func sanitizedFileName(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\:*?\"<>|")
        let cleaned = name.components(separatedBy: invalid).joined(separator: "_")
        return cleaned.isEmpty ? "video_\(Int(Date().timeIntervalSince1970))" : cleaned
    }
}
