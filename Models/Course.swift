import Foundation

/// Course manages classification and storage of Question objects under a specific course.
/// Relies on Question (Models/User.swift) and Archive (Models/Archive.swift).
class Course: Subject, Codable {
    var courseName: String
    var topicTag: String
    var courseID: String
    var instructor: String

    /// Questions currently active in this course
    private(set) var questions: [Question]

    /// Archive for this course (stores snapshots of removed/old questions)
    private(set) var archive: Archive

    enum CodingKeys: String, CodingKey {
        case courseName, topicTag, courseID, instructor, questions, archive
    }

    init(courseName: String,
         topicTag: String = "",
         courseID: String = Account.randomId(),
         instructor: String = "") {
        self.courseName = courseName
        self.topicTag = topicTag
        self.courseID = courseID
        self.instructor = instructor
        self.questions = []
        self.archive = Archive(id: UUID().uuidString, courseID: courseID)
        super.init()
    }

    // MARK: - Codable

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.courseName = try container.decode(String.self, forKey: .courseName)
        self.topicTag = try container.decode(String.self, forKey: .topicTag)
        self.courseID = try container.decode(String.self, forKey: .courseID)
        self.instructor = try container.decode(String.self, forKey: .instructor)
        self.questions = try container.decodeIfPresent([Question].self, forKey: .questions) ?? []
        self.archive = try container.decodeIfPresent(Archive.self, forKey: .archive) ?? Archive(courseID: courseID)
        super.init()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(courseName, forKey: .courseName)
        try container.encode(topicTag, forKey: .topicTag)
        try container.encode(courseID, forKey: .courseID)
        try container.encode(instructor, forKey: .instructor)
        try container.encode(questions, forKey: .questions)
        try container.encode(archive, forKey: .archive)
    }

    // MARK: - Question management

    @discardableResult
    func addQuestion(_ question: Question) -> Bool {
        guard !questions.contains(where: { $0.id == question.id }) else { return false }
        questions.append(question)
        return true
    }

    @discardableResult
    func createQuestion(authorId: String, title: String, body: String) -> Question {
        let q = Question(authorId: authorId, title: title, body: body)
        questions.append(q)
        return q
    }

    func getQuestions(sortedByNewest: Bool = true) -> [Question] {
        if sortedByNewest {
            return questions.sorted { $0.createdAt > $1.createdAt }
        } else {
            return questions
        }
    }

    func findQuestion(byId id: String) -> Question? {
        return questions.first(where: { $0.id == id })
    }

    @discardableResult
    func removeQuestion(byId id: String, archiveIt: Bool = true, archivedBy userId: String? = nil) -> Bool {
        guard let idx = questions.firstIndex(where: { $0.id == id }) else { return false }
        let q = questions.remove(at: idx)
        if archiveIt {
            archive.archive(q, by: userId)
        }
        return true
    }

    /// Edit question owned by its author (caller should verify permissions).
    @discardableResult
    func editQuestion(id: String, newTitle: String? = nil, newBody: String? = nil) -> Bool {
        guard let idx = questions.firstIndex(where: { $0.id == id }) else { return false }
        if let t = newTitle { questions[idx].title = t }
        if let b = newBody { questions[idx].body = b }
        questions[idx].editedAt = Date()
        return true
    }

    // MARK: - Archiving helpers

    /// Archive questions older than `days`. Returns number archived.
    @discardableResult
    func archiveQuestions(olderThanDays days: Int, by userId: String? = nil) -> Int {
        guard days > 0 else { return 0 }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date.distantPast
        let toArchive = questions.filter { $0.createdAt < cutoff }
        toArchive.forEach { archive.archive($0, archivedBy: userId) }
        questions.removeAll { $0.createdAt < cutoff }
        return toArchive.count
    }

    /// Archive a single question by id.
    func archiveQuestion(byId id: String, archivedBy userId: String? = nil) -> Bool {
        return removeQuestion(byId: id, archiveIt: true, archivedBy: userId)
    }

    /// Update archive maintenance (prune items older than given days).
    func updateArchive(pruneOlderThanDays days: Int) {
        archive.prune(olderThanDays: days)
    }

    // MARK: - Query helpers

    func questionsByAuthor(_ authorId: String) -> [Question] {
        return questions.filter { $0.authorId == authorId }
    }

    func searchQuestions(containing text: String) -> [Question] {
        let lower = text.lowercased()
        return questions.filter { $0.title.lowercased().contains(lower) || $0.body.lowercased().contains(lower)