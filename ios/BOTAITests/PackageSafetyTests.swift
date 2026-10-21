import Foundation
import Testing
import ZIPFoundation
@testable import BOTAI

struct PackageSafetyTests {
    @Test func archiveWithoutManifestIsRejected() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try Data("hello".utf8).write(to: root.appendingPathComponent("other.txt"))
        let archive = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("botai")
        defer { try? FileManager.default.removeItem(at: archive) }
        try FileManager.default.zipItem(at: root, to: archive, shouldKeepParent: false)
        #expect(throws: BOTAIPackageError.self) {
            try BOTAIPackageService.validateArchive(archive)
        }
    }

    @Test func normalManifestArchivePassesPreflight() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try Data("{}".utf8).write(to: root.appendingPathComponent("manifest.json"))
        let archive = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("botai")
        defer { try? FileManager.default.removeItem(at: archive) }
        try FileManager.default.zipItem(at: root, to: archive, shouldKeepParent: false)
        try BOTAIPackageService.validateArchive(archive)
    }

    @Test func rejectsArchiveWithTooManyEntries() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try Data("{}".utf8).write(to: root.appendingPathComponent("manifest.json"))
        for index in 0..<1001 {
            try Data().write(to: root.appendingPathComponent("item-\(index).txt"))
        }
        let archive = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("botai")
        defer { try? FileManager.default.removeItem(at: archive) }
        try FileManager.default.zipItem(at: root, to: archive, shouldKeepParent: false)
        #expect(throws: BOTAIPackageError.self) {
            try BOTAIPackageService.validateArchive(archive)
        }
    }

    @Test func ordinaryCSVArchiveDoesNotNeedManifest() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try Data("A,B\n1,2".utf8).write(to: root.appendingPathComponent("table.csv"))
        let archive = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("zip")
        defer { try? FileManager.default.removeItem(at: archive) }
        try FileManager.default.zipItem(at: root, to: archive, shouldKeepParent: false)
        try BOTAIPackageService.validateArchive(archive, requiresManifest: false)
        #expect(throws: BOTAIPackageError.self) {
            try BOTAIPackageService.validateArchive(archive)
        }
    }

    @Test func rejectsEscapingImageReference() throws {
        let json = #"{"formatVersion":1,"title":"Test","description":"","tags":"","kind":"reference","fields":[{"key":"picture","title":"Picture","position":0,"type":"image"}],"rows":[{"picture":"media/../../outside.png"}],"questionSets":[{"kind":"card","promptTemplate":"{1}","promptFieldKeys":["picture"],"answers":[{"template":"{1}","fieldKeys":["picture"],"correct":true}],"showCorrectCount":false,"enabled":true}]}"#
        let manifest = try JSONDecoder().decode(BOTAIPackageManifest.self, from: Data(json.utf8))
        #expect(throws: BOTAIPackageError.self) {
            try BOTAIPackageService.validateManifest(manifest)
        }
    }

    @Test func acceptsImageWithinMediaDirectory() throws {
        let json = #"{"formatVersion":1,"title":"Test","description":"","tags":"","kind":"reference","fields":[{"key":"picture","title":"Picture","position":0,"type":"image"}],"rows":[{"picture":"media/photo.png"}],"questionSets":[{"kind":"card","promptTemplate":"{1}","promptFieldKeys":["picture"],"answers":[{"template":"{1}","fieldKeys":["picture"],"correct":true}],"showCorrectCount":false,"enabled":true}]}"#
        let manifest = try JSONDecoder().decode(BOTAIPackageManifest.self, from: Data(json.utf8))
        try BOTAIPackageService.validateManifest(manifest)
    }
}
