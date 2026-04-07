import Foundation

/// Subject represents a grouping (e.g., "Math", "CS") and stores Courses that belong to it.
class Subject: Codable {
    var subjectName: String
    private(set) var courses: [Course]

    init(subjectName: String = "") {
        self.subjectName = subjectName
        self.courses = []
    }

    /// Legacy placeholder kept for compatibility.
    func storeCourses() {
        // Intentionally left as a no-op for now — persistence handled elsewhere.
    }

    // MARK: - Course management

    /// Add a course to this subject. Returns false if a course with same courseID already exists.
    @discardableResult
    func addCourse(_ course: Course) -> Bool {
        guard !courses.contains(where: { $0.courseID == course.courseID }) else { return false }
        courses.append(course)
        return true
    }

    /// Remove a course by id. Returns true if removed.
    @discardableResult
    func removeCourse(byId id: String) -> Bool {
        guard let idx = courses.firstIndex(where: { $0.courseID == id }) else { return false }
        courses.remove(at: idx)
        return true
    }

    /// Find a course by id.
    func findCourse(byId id: String) -> Course? {
        return courses.first(where: { $0.courseID == id })
    }

    /// Return courses sorted by name (ascending).
    func coursesSortedByName() -> [Course] {
        return courses.sorted { $0.courseName.localizedCaseInsensitiveCompare($1.courseName) == .orderedAscending }
    }

    /// Return courses taught by a specific instructor.
    func coursesByInstructor(_ instructor: String) -> [Course] {
        return courses.filter { $0.instructor == instructor }
    }

    /// Move a course from this subject to another subject. Returns true on success.
    @discardableResult
    func moveCourse(courseId: String, toSubject destination: Subject) -> Bool {
        guard let idx = courses.firstIndex(where: { $0.courseID == courseId }) else { return false }
        let course = courses.remove(at: idx)
        return destination.addCourse(course)
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case subjectName, courses
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.subjectName = try container.decode(String.self, forKey: .subjectName)
        self.courses = try container.decodeIfPresent([Course].self, forKey: .courses) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(subjectName, forKey: .subjectName)
        try container.encode(courses, forKey: .courses)
    }
}