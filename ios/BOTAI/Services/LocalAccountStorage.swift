import Foundation

enum LocalAccountStorage {
    enum Identity: Equatable {
        case guest
        case authenticated(UUID)
    }

    static func directoryName(for identity: Identity, uiTesting: Bool = false) -> String {
        let prefix = uiTesting ? "BOTAI-UITests" : "BOTAI"
        switch identity {
        case .guest: return prefix + "-guest"
        case .authenticated(let id): return prefix + "-user-" + id.uuidString.lowercased()
        }
    }

    static func directory(for identity: Identity, support: URL, uiTesting: Bool = false) -> URL {
        support.appendingPathComponent(directoryName(for: identity, uiTesting: uiTesting), isDirectory: true)
    }

    /// Only invoke after an explicit ownership decision and after the source database is closed.
    /// A WAL-mode database requires a checkpoint before this file-copy migration.
    /// Never overwrite an existing account database or remove the legacy source.
    static func copyCheckpointedLegacyDatabase(
        from legacyFolder: URL, to identity: Identity, support: URL,
        uiTesting: Bool = false, fileManager: FileManager = .default
    ) throws -> Bool {
        let source = legacyFolder.appendingPathComponent("learning.sqlite")
        guard fileManager.fileExists(atPath: source.path) else { return false }
        guard !fileManager.fileExists(atPath: source.path + "-wal") else { return false }
        let destination = directory(for: identity, support: support, uiTesting: uiTesting)
        let target = destination.appendingPathComponent("learning.sqlite")
        guard !fileManager.fileExists(atPath: target.path) else { return false }
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        try fileManager.copyItem(at: source, to: target)
        return true
    }
}
