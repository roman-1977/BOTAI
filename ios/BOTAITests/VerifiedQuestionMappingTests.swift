import Foundation
import Testing
@testable import BOTAI

private struct FakePairLookup: RemoteQuestionPairLookup {
    let visible: Bool
    let fails: Bool
    func isVisiblePair(questionID: UUID, versionID: UUID) async throws -> Bool {
        if fails { throw BOTAIBackendError.missingServerQuestionMapping }
        return visible
    }
}

struct VerifiedQuestionMappingTests {
    @Test func inaccessiblePairDoesNotPersist() async throws {
        let repository = RemoteQuestionMappingRepository(database: try AppDatabase())
        let local = UUID()
        let service = VerifiedQuestionMappingService(lookup: FakePairLookup(visible: false, fails: false), repository: repository)
        #expect(try await service.verifyAndSave(localQuestionID: local, remoteQuestionID: UUID(), remoteVersionID: UUID()) == false)
        #expect(try repository.mapping(for: local) == nil)
    }

    @Test func serverFailureDoesNotPersist() async throws {
        let repository = RemoteQuestionMappingRepository(database: try AppDatabase())
        let local = UUID()
        let service = VerifiedQuestionMappingService(lookup: FakePairLookup(visible: false, fails: true), repository: repository)
        await #expect(throws: BOTAIBackendError.missingServerQuestionMapping) {
            try await service.verifyAndSave(localQuestionID: local, remoteQuestionID: UUID(), remoteVersionID: UUID())
        }
        #expect(try repository.mapping(for: local) == nil)
    }

    @Test func visiblePairPersists() async throws {
        let repository = RemoteQuestionMappingRepository(database: try AppDatabase())
        let local = UUID(), question = UUID(), version = UUID()
        let service = VerifiedQuestionMappingService(lookup: FakePairLookup(visible: true, fails: false), repository: repository)
        #expect(try await service.verifyAndSave(localQuestionID: local, remoteQuestionID: question, remoteVersionID: version))
        let saved = try #require(try repository.mapping(for: local))
        #expect(saved.remoteQuestionID == question.uuidString)
        #expect(saved.remoteQuestionVersionID == version.uuidString)
    }
}
