import Foundation
import Testing
@testable import BOTAI

struct RemoteQuestionMappingTests {
    @Test func editingOrDeletingMaterialInvalidatesRemoteMappings() throws {
        let database = try AppDatabase()
        let materials = MaterialRepository(database: database)
        let mappings = RemoteQuestionMappingRepository(database: database)
        let materialID = UUID(), ruleID = UUID(), rowID = UUID()
        let material = StudyMaterialRecord(id: materialID, title: "Тест", kind: .quiz,
                                           source: .created, createdAt: .now, updatedAt: .now)
        let rule = QuestionRule(id: ruleID, materialID: materialID, kind: .card,
                                promptFieldKey: "name", answerFieldKey: "answer", enabled: true)
        let row = KnowledgeRow(id: rowID, materialID: materialID, position: 0,
                               values: ["name": "Первый", "answer": "Ответ"])
        let localID = StudyQuestionBuilder.stableID(ruleID: ruleID, rowID: rowID)
        try materials.save(material: material, fields: [], rows: [row], rules: [rule])
        try mappings.saveVerified(localQuestionID: localID, remoteQuestionID: UUID(), remoteVersionID: UUID())
        #expect(try mappings.mapping(for: localID) != nil)
        var edited = row
        edited.values["name"] = "Изменённый"
        try materials.save(material: material, fields: [], rows: [edited], rules: [rule])
        #expect(try mappings.mapping(for: localID) == nil)
        try mappings.saveVerified(localQuestionID: localID, remoteQuestionID: UUID(), remoteVersionID: UUID())
        try materials.delete(id: materialID)
        #expect(try mappings.mapping(for: localID) == nil)
    }

    @Test func pendingAttemptKeepsOriginalVersionAfterMaterialEdit() throws {
        let database = try AppDatabase()
        let materials = MaterialRepository(database: database)
        let learning = LearningRepository(database: database)
        let mappings = RemoteQuestionMappingRepository(database: database)
        let materialID = UUID(), ruleID = UUID(), rowID = UUID()
        let material = StudyMaterialRecord(id: materialID, title: "История", kind: .quiz,
                                           source: .created, createdAt: .now, updatedAt: .now)
        let rule = QuestionRule(id: ruleID, materialID: materialID, kind: .card,
                                promptFieldKey: "name", answerFieldKey: "answer", enabled: true)
        let row = KnowledgeRow(id: rowID, materialID: materialID, position: 0,
                               values: ["name": "Старый", "answer": "Ответ"])
        let localID = StudyQuestionBuilder.stableID(ruleID: ruleID, rowID: rowID)
        let oldQuestion = UUID(), oldVersion = UUID()
        try materials.save(material: material, fields: [], rows: [row], rules: [rule])
        try mappings.saveVerified(localQuestionID: localID,
                                  remoteQuestionID: oldQuestion, remoteVersionID: oldVersion)
        let attempt = Attempt(id: UUID(), questionID: localID, occurredAt: .now, rating: .good)
        try learning.record(attempt, state: LearningState())
        var changed = row
        changed.values["name"] = "Новый"
        try materials.save(material: material, fields: [], rows: [changed], rules: [rule])
        #expect(try mappings.mapping(for: localID) == nil)
        let pending = try #require(try learning.mappedUploadBatch().attempts.first)
        #expect(pending.id == attempt.id)
        #expect(pending.questionID == oldQuestion)
        #expect(pending.questionVersionID == oldVersion)
        try mappings.saveVerified(localQuestionID: localID,
                                  remoteQuestionID: UUID(), remoteVersionID: UUID())
        let stillOld = try #require(try learning.mappedUploadBatch().attempts.first)
        #expect(stillOld.questionID == oldQuestion)
        #expect(stillOld.questionVersionID == oldVersion)
    }

    @Test func unpublishedAttemptIsNotMisattributedAfterMaterialEdit() throws {
        let database = try AppDatabase()
        let materials = MaterialRepository(database: database)
        let learning = LearningRepository(database: database)
        let mappings = RemoteQuestionMappingRepository(database: database)
        let materialID = UUID(), ruleID = UUID(), rowID = UUID()
        let material = StudyMaterialRecord(id: materialID, title: "Тест", kind: .quiz,
                                           source: .created, createdAt: .now, updatedAt: .now)
        let rule = QuestionRule(id: ruleID, materialID: materialID, kind: .card,
                                promptFieldKey: "name", answerFieldKey: "answer", enabled: true)
        let row = KnowledgeRow(id: rowID, materialID: materialID, position: 0,
                               values: ["name": "До", "answer": "Ответ"])
        let localID = StudyQuestionBuilder.stableID(ruleID: ruleID, rowID: rowID)
        try materials.save(material: material, fields: [], rows: [row], rules: [rule])
        let attempt = Attempt(id: UUID(), questionID: localID, occurredAt: .now, rating: .good)
        try learning.record(attempt, state: LearningState())
        var edited = row
        edited.values["name"] = "После"
        try materials.save(material: material, fields: [], rows: [edited], rules: [rule])
        try mappings.saveVerified(localQuestionID: localID,
                                  remoteQuestionID: UUID(), remoteVersionID: UUID())
        #expect(try learning.mappedUploadBatch().attempts.isEmpty)
        #expect(try learning.outboxCount() == 1)
        #expect(try learning.load().0.map(\.id) == [attempt.id])
    }

    @Test func completionAtomicallyRemovesResumableSession() throws {
        let repository = LearningRepository(database: try AppDatabase())
        let question = StudyQuestion(id: UUID(), prompt: "Example", answer: "Answer", kind: .reveal, choices: [], correctChoiceIndexes: [])
        let session = StudySession(id: UUID(), startedAt: .now, endedAt: .now,
            activeSeconds: 15, answered: 1, correct: 1)
        try repository.saveResumableSession(ResumableStudySession(id: session.id,
            startedAt: session.startedAt, title: "Test", targetMinutes: 1,
            questions: [question], nextIndex: 0, answered: 0, correct: 0, activeSeconds: 0))
        #expect(try repository.loadResumableSession() != nil)
        try repository.completeSession(session)
        #expect(try repository.loadResumableSession() == nil)
        #expect(try repository.pendingSessionSummaries().count == 1)
        try repository.completeSession(session)
        #expect(try repository.pendingSessionSummaries().count == 1)
    }

    @Test func sessionSummaryAcknowledgementIsIdempotent() throws {
        let learning = LearningRepository(database: try AppDatabase())
        let id = UUID()
        let session = StudySession(id: id, startedAt: .now, endedAt: .now,
            activeSeconds: 60, answered: 3, correct: 2)
        try learning.completeSession(session)
        #expect(try learning.pendingSessionSummaries().count == 1)
        try learning.acknowledgeSessionSummaries([UUID()])
        #expect(try learning.pendingSessionSummaries().count == 1)
        try learning.acknowledgeSessionSummaries([id, id])
        #expect(try learning.pendingSessionSummaries().isEmpty)
        try learning.acknowledgeSessionSummaries([id])
        #expect(try learning.sessions().count == 1)
    }

    @Test func completedSessionSummaryIsDurableIdempotentAndAggregateOnly() throws {
        let database = try AppDatabase()
        let learning = LearningRepository(database: database)
        let id = UUID()
        let first = StudySession(id: id, startedAt: .now, endedAt: .now,
            activeSeconds: 120, answered: 5, correct: 4)
        try learning.saveSession(first)
        #expect(try learning.pendingSessionSummaries().isEmpty)
        try learning.completeSession(first)
        try learning.completeSession(first)
        let summaries = try learning.pendingSessionSummaries()
        #expect(summaries.count == 1)
        #expect(summaries.first?.sessionID == id)
        #expect(summaries.first?.answered == 5)
        #expect(summaries.first?.correct == 4)
        #expect(summaries.first?.activeSeconds == 120)
        #expect(try learning.sessions().count == 1)
    }

    @Test func recordedAttemptRetainsOriginalQuestionContent() throws {
        let database = try AppDatabase()
        let learning = LearningRepository(database: database)
        let id = UUID()
        let question = StudyQuestion(id: id, prompt: "Старый вопрос", answer: "Старый ответ",
                                     kind: .pair, choices: [], correctChoiceIndexes: [])
        let attempt = Attempt(id: UUID(), questionID: id, occurredAt: .now, rating: .good)
        try learning.record(attempt, state: LearningState(), question: question)
        let stored = try #require(try learning.attempt(id: attempt.id.uuidString))
        #expect(stored.snapshotPrompt == "Старый вопрос")
        #expect(stored.snapshotAnswer == "Старый ответ")
        #expect(stored.snapshotKind == "pair")
        #expect(try learning.outboxCount() == 1)
    }

    @Test func snapshotRecoveryPinsOldAttemptWithoutChangingEditedCard() throws {
        let database = try AppDatabase()
        let learning = LearningRepository(database: database)
        let mapping = RemoteQuestionMappingRepository(database: database)
        let localID = UUID(), attemptID = UUID()
        let question = StudyQuestion(id: localID, prompt: "До изменения", answer: "Ответ",
                                     kind: .reveal, choices: [], correctChoiceIndexes: [])
        let attempt = Attempt(id: attemptID, questionID: localID, occurredAt: .now, rating: .good)
        try learning.record(attempt, state: LearningState(), question: question)
        let snapshots = try learning.unpublishedSnapshots()
        #expect(snapshots.count == 1)
        #expect(snapshots.first?.attemptID == attemptID)
        #expect(snapshots.first?.question.prompt == "До изменения")
        let oldRemote = UUID(), oldVersion = UUID()
        try learning.pinPublishedSnapshot(attemptID: attemptID,
                                          remoteQuestionID: oldRemote, versionID: oldVersion)
        try mapping.saveVerified(localQuestionID: localID,
                                 remoteQuestionID: UUID(), remoteVersionID: UUID())
        let upload = try #require(try learning.mappedUploadBatch().attempts.first)
        #expect(upload.questionID == oldRemote)
        #expect(upload.questionVersionID == oldVersion)
        #expect(try learning.unpublishedSnapshots().isEmpty)
    }

    @Test func mappingDoesNotAlterExistingLearningAttempts() throws {
        let database = try AppDatabase()
        let learning = LearningRepository(database: database)
        let local = UUID()
        let attempt = Attempt(id: UUID(), questionID: local, occurredAt: .now, rating: .good)
        try learning.record(attempt, state: LearningState(intervalDays: 1, streak: 1, nextDueAt: .now))
        let mapping = RemoteQuestionMappingRepository(database: database)
        try mapping.saveVerified(localQuestionID: local, remoteQuestionID: UUID(), remoteVersionID: UUID())
        let restored = try learning.load()
        #expect(restored.0.count == 1)
        #expect(restored.0.first?.id == attempt.id)
        #expect(restored.0.first?.questionID == attempt.questionID)
        #expect(restored.0.first?.rating == attempt.rating)
        #expect(abs((restored.0.first?.occurredAt.timeIntervalSince1970 ?? 0) - attempt.occurredAt.timeIntervalSince1970) < 1)
        #expect(try learning.outboxCount() == 1)
    }

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
import Foundation
import Testing
@testable import BOTAI

struct StudyQuestionAttributionTests {
    @Test func sharedQuestionAcrossTopicsIsNotGuessed() {
        let ref = CourseRuleReference(materialID: UUID(), ruleID: UUID())
        let first = CourseTopic(id: UUID(), title: "First", questionSets: [ref])
        let second = CourseTopic(id: UUID(), title: "Second", questionSets: [ref])
        let section = CourseSection(id: UUID(), title: "Chapter", description: "", estimatedMinutes: nil,
            topics: [first, second])
        let course = StudyCourse(id: UUID(), title: "Subject", description: "", subject: "Science",
            audience: "", estimatedMinutes: nil, author: nil, language: "ru", coverSymbol: "",
            source: .created, sections: [section], goals: [], createdAt: .now, updatedAt: .now)
        let question = StudyQuestion(id: UUID(), prompt: "Q", answer: "A", kind: .reveal,
            choices: [], correctChoiceIndexes: [])
        let resolved = StudyQuestionAttributionResolver.uniqueAttributions(
            courses: [course], questionsByReference: [ref: [question]])
        #expect(resolved[question.id] == nil)
    }

    @Test func uniquelyScopedQuestionKeepsStableIDs() {
        let ref = CourseRuleReference(materialID: UUID(), ruleID: UUID())
        let topic = CourseTopic(id: UUID(), title: "Topic", questionSets: [ref])
        let section = CourseSection(id: UUID(), title: "Chapter", description: "", estimatedMinutes: nil,
            topics: [topic])
        let course = StudyCourse(id: UUID(), title: "Subject", description: "", subject: "Physics",
            audience: "", estimatedMinutes: nil, author: nil, language: "ru", coverSymbol: "",
            source: .created, sections: [section], goals: [], createdAt: .now, updatedAt: .now)
        let question = StudyQuestion(id: UUID(), prompt: "Q", answer: "A", kind: .reveal,
            choices: [], correctChoiceIndexes: [])
        let resolved = StudyQuestionAttributionResolver.uniqueAttributions(
            courses: [course], questionsByReference: [ref: [question]])
        #expect(resolved[question.id] == StudyQuestionAttribution(
            courseID: course.id, sectionID: section.id, topicID: topic.id))
    }
}

struct SessionTopicAccumulatorTests {
    @Test func mixedTopicsAndUnknownAnswersAreCountedWithoutGuessing() {
        let first = StudyQuestionAttribution(courseID: UUID(), sectionID: UUID(), topicID: UUID())
        let second = StudyQuestionAttribution(courseID: UUID(), sectionID: UUID(), topicID: UUID())
        var accumulator = SessionTopicAccumulator()
        accumulator.record(correct: true, attribution: first)
        accumulator.record(correct: false, attribution: second)
        accumulator.record(correct: false, attribution: first)
        accumulator.record(correct: true, attribution: nil)
        #expect(accumulator.answered == 4)
        #expect(accumulator.correct == 2)
        #expect(accumulator.unattributedAnswered == 1)
        #expect(accumulator.unattributedCorrect == 1)
        #expect(accumulator.buckets[first]?.answered == 2)
        #expect(accumulator.buckets[first]?.correct == 1)
        #expect(accumulator.buckets[second]?.answered == 1)
        #expect(accumulator.buckets[second]?.correct == 0)
        #expect(accumulator.breakdown.count == 2)
    }

    @Test func checkpointRoundTripPreservesExactBuckets() throws {
        let attribution = StudyQuestionAttribution(courseID: UUID(), sectionID: UUID(), topicID: UUID())
        var accumulator = SessionTopicAccumulator()
        accumulator.record(correct: true, attribution: attribution)
        accumulator.record(correct: false, attribution: nil)
        let restored = try JSONDecoder().decode(SessionTopicAccumulator.self,
            from: JSONEncoder().encode(accumulator))
        #expect(restored == accumulator)
        #expect(restored.answered == 2)
    }
}

struct SessionAttributionCheckpointTests {
    @Test func answerTimeBucketsSurviveSQLiteResume() throws {
        let repository = LearningRepository(database: try AppDatabase())
        let question = StudyQuestion(id: UUID(), prompt: "Q", answer: "A", kind: .reveal,
            choices: [], correctChoiceIndexes: [])
        let attribution = StudyQuestionAttribution(courseID: UUID(), sectionID: UUID(), topicID: UUID())
        var accumulator = SessionTopicAccumulator()
        accumulator.record(correct: true, attribution: attribution)
        let snapshot = ResumableStudySession(id: UUID(), startedAt: .now, title: "Session",
            targetMinutes: 5, questions: [question], nextIndex: 0, answered: 1, correct: 1,
            activeSeconds: 12, attributionByQuestion: [question.id: attribution],
            topicAccumulator: accumulator)
        try repository.saveResumableSession(snapshot)
        let restored = try #require(try repository.loadResumableSession())
        #expect(restored.attributionByQuestion == [question.id: attribution])
        #expect(restored.topicAccumulator == accumulator)
        #expect(restored.topicAccumulator?.answered == restored.answered)
    }

    @Test func oldCheckpointWithoutAttributionStillDecodes() throws {
        let question = StudyQuestion(id: UUID(), prompt: "Q", answer: "A", kind: .reveal,
            choices: [], correctChoiceIndexes: [])
        let old = ResumableStudySession(id: UUID(), startedAt: .now, title: "Old",
            targetMinutes: 1, questions: [question], nextIndex: 0, answered: 0,
            correct: 0, activeSeconds: 0)
        let data = try JSONEncoder().encode(old)
        let restored = try JSONDecoder().decode(ResumableStudySession.self, from: data)
        #expect(restored.attributionByQuestion == nil)
        #expect(restored.topicAccumulator == nil)
    }
}

struct CompletedSessionTopicPersistenceTests {
    @Test func completedSummaryRetainsMixedBuckets() throws {
        let repository = LearningRepository(database: try AppDatabase())
        let attribution = StudyQuestionAttribution(courseID: UUID(), sectionID: UUID(), topicID: UUID())
        var topics = SessionTopicAccumulator()
        topics.record(correct: true, attribution: attribution)
        topics.record(correct: false, attribution: nil)
        let session = StudySession(id: UUID(), startedAt: .now, endedAt: .now,
            activeSeconds: 30, answered: 2, correct: 1)
        try repository.completeSession(session, topics: topics)
        let saved = try #require(repository.pendingSessionSummaries().first)
        #expect(saved.topicBreakdown == topics.breakdown)
        #expect(saved.unattributedAnswered == 1)
        #expect(saved.unattributedCorrect == 0)
        try repository.completeSession(session, topics: topics)
        #expect(try repository.pendingSessionSummaries().count == 1)
    }

    @Test func mismatchedCountsAreRejected() throws {
        let repository = LearningRepository(database: try AppDatabase())
        var topics = SessionTopicAccumulator()
        topics.record(correct: true, attribution: nil)
        let session = StudySession(id: UUID(), startedAt: .now, endedAt: .now,
            activeSeconds: 30, answered: 2, correct: 1)
        #expect(throws: BOTAIBackendError.invalidAcknowledgement.self) {
            try repository.completeSession(session, topics: topics)
        }
        #expect(try repository.pendingSessionSummaries().isEmpty)
    }

    @Test func oldSummaryStillDecodes() throws {
        let session = StudySession(id: UUID(), startedAt: .now, endedAt: .now,
            activeSeconds: 3, answered: 0, correct: 0)
        let data = try JSONEncoder().encode(CompletedSessionSummary(session: session))
        let decoded = try JSONDecoder().decode(CompletedSessionSummary.self, from: data)
        #expect(decoded.topicBreakdown == nil)
    }
}
