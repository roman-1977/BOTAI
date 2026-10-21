import Foundation
import Testing
@testable import BOTAI

struct RemoteQuestionMappingTests {
    @Test func mappingPersistsAcrossDatabaseReopen() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let path = directory.appendingPathComponent("learning.sqlite").path
        let local = UUID(), remote = UUID(), version = UUID()
        do {
            let repository = RemoteQuestionMappingRepository(database: try AppDatabase(path: path))
            #expect(try repository.mapping(for: local) == nil)
            try repository.saveVerified(localQuestionID: local, remoteQuestionID: remote, remoteVersionID: version)
        }
        let reopened = RemoteQuestionMappingRepository(database: try AppDatabase(path: path))
        let mapping = try #require(try reopened.mapping(for: local))
        #expect(mapping.remoteQuestionID == remote.uuidString)
        #expect(mapping.remoteQuestionVersionID == version.uuidString)
        #expect(try reopened.mapping(for: UUID()) == nil)
    }
}
