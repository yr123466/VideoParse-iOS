import Foundation
import Combine

// MARK: - 历史记录存储 (对应 Android Room 数据库)
//
// 说明：使用本地 JSON 文件持久化，功能等价于 Room 的
// getAllHistory / getFavorites / search / insert / toggleFavorite / delete / clearAll

final class HistoryStore: ObservableObject {

    static let shared = HistoryStore()

    @Published private(set) var items: [ParseHistoryItem] = []

    /// 对外暴露的数据变化发布者
    var itemsPublisher: AnyPublisher<[ParseHistoryItem], Never> {
        return $items.eraseToAnyPublisher()
    }

    private let fileURL: URL
    private let ioQueue = DispatchQueue(label: "com.videoparse.history.io", qos: .utility)

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = docs.appendingPathComponent("videoparse_history.json")
        load()
    }

    // MARK: 持久化

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([ParseHistoryItem].self, from: data) else {
            items = []
            return
        }
        items = decoded.sorted { $0.timestamp > $1.timestamp }
    }

    private func persist() {
        let snapshot = items
        let url = fileURL
        ioQueue.async {
            do {
                let data = try JSONEncoder().encode(snapshot)
                try data.write(to: url, options: .atomic)
            } catch {
                print("[HistoryStore] persist error: \(error)")
            }
        }
    }

    private var nextId: Int64 {
        return (items.map { $0.id }.max() ?? 0) + 1
    }

    // MARK: 写入

    func insert(_ item: ParseHistoryItem) {
        var newItem = item
        if newItem.id == 0 { newItem.id = nextId }
        items.append(newItem)
        items.sort { $0.timestamp > $1.timestamp }
        persist()
    }

    func toggleFavorite(id: Int64, current: Bool) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isFavorite = !current
        persist()
    }

    func delete(id: Int64) {
        items.removeAll { $0.id == id }
        persist()
    }

    func clearAll() {
        items.removeAll()
        persist()
    }

    // MARK: 读取

    var favorites: [ParseHistoryItem] {
        return items.filter { $0.isFavorite }
    }

    func search(_ query: String) -> [ParseHistoryItem] {
        guard !query.isEmpty else { return items }
        return items.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.authorName.localizedCaseInsensitiveContains(query) ||
            $0.platform.localizedCaseInsensitiveContains(query)
        }
    }
}
