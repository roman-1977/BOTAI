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
}
