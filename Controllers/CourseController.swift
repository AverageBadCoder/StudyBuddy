import Foundation

final class CourseController {
    // Create a new Course under a subject
    func createCourse(subject: Subject, courseName: String, topicTag: String = "", instructor: String = "") -> Course {
        let course = Course(courseName: courseName, topicTag: topicTag, courseID: Account.randomId(), instructor: instructor)
        _ = subject.addCourse(course)
        return course
    }

    func removeCourse(subject: Subject, courseId: String) -> Bool {
        return subject.removeCourse(byId: courseId)
    }

    func listCourses(subject: Subject) -> [Course] {
        subject.coursesSortedByName()
    }

    func archiveOldQuestions(course: Course, olderThanDays days: Int, by userId: String? = nil) -> Int {
        course.archiveQuestions(olderThanDays: days, by: userId)
    }
}