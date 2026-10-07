import Foundation

// MARK: - 网络错误

enum APIError: LocalizedError {
    case invalidURL
    case http(Int)
    case emptyBody
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的请求地址"
        case .http(let code): return "请求失败 HTTP \(code)"
        case .emptyBody: return "响应内容为空"
        case .decoding(let msg): return "数据解析失败: \(msg)"
        }
    }
}

// MARK: - API 客户端 (对应 Android ApiClient + VideoParseApiService)
//
// 说明：
//  - Base URL / 超时 / 请求头与 Android 端完全一致
//  - 使用 URLSession 替代 OkHttp/Retrofit，Codable 替代 Moshi

final class APIClient {

    static let shared = APIClient()

    static let baseURLString = "https://api-new.ifphp.com/"
    static let updateCheckURLString = "https://raw.githubusercontent.com/yr123466/JSON/refs/heads/main/bugpkmini.json"

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 25
        config.timeoutIntervalForResource = 25
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
    }

    // MARK: 请求构造

    private func makeRequest(path: String,
                             query: [String: String],
                             apiKey: String? = nil,
                             absoluteURL: String? = nil) throws -> URLRequest {
        let url: URL
        if let absoluteURL = absoluteURL, let u = URL(string: absoluteURL) {
            url = u
        } else {
            guard let u = URL(string: Self.baseURLString + path) else { throw APIError.invalidURL }
            url = u
        }

        guard var comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        if !query.isEmpty {
            comps.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let finalURL = comps.url else { throw APIError.invalidURL }

        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (Linux; Android 14; Mobile) VideoParse/1.0",
                         forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let key = apiKey, !key.isEmpty {
            request.setValue(key, forHTTPHeaderField: "X-API-Key")
        }
        return request
    }

    // MARK: 解析视频  GET api/svparse?url=&key=

    func parseVideo(url: String, key: String) async throws -> ParseResponse {
        let request = try makeRequest(path: "api/svparse",
                                      query: ["url": url, "key": key],
                                      apiKey: key)
        let (data, response) = try await session.data(for: request)
        try validate(response)
        do {
            return try decoder.decode(ParseResponse.self, from: data)
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }

    // MARK: 接口状态诊断  GET system-api/market/apis/5

    func checkApiStatus() async throws -> Data {
        let request = try makeRequest(path: "system-api/market/apis/5", query: [:])
        let (data, response) = try await session.data(for: request)
        try validate(response)
        return data
    }

    // MARK: 检查更新  GET <raw github>

    func checkUpdate() async throws -> AppUpdateInfo {
        let request = try makeRequest(path: "",
                                      query: [:],
                                      absoluteURL: Self.updateCheckURLString)
        let (data, response) = try await session.data(for: request)
        try validate(response)
        do {
            return try decoder.decode(AppUpdateInfo.self, from: data)
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }

    // MARK: 校验

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.http(http.statusCode)
        }
    }
}
