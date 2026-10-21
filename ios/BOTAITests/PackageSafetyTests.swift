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
}
