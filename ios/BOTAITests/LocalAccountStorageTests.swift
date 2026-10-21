import Foundation
import Testing
@testable import BOTAI

struct LocalAccountStorageTests {
    @Test func namespacesAreDistinctAndDeterministic() {
        let first = UUID()
        let second = UUID()
        let guest = LocalAccountStorage.directoryName(for: .guest)
        let account = LocalAccountStorage.directoryName(for: .authenticated(first))
        #expect(guest != account)
        #expect(account != LocalAccountStorage.directoryName(for: .authenticated(second)))
        #expect(account == LocalAccountStorage.directoryName(for: .authenticated(first)))
        #expect(account.hasPrefix("BOTAI-user-"))
        #expect(LocalAccountStorage.directoryName(for: .guest, uiTesting: true) != guest)
    }
}
