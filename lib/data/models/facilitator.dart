import 'course.dart';
import 'json.dart';
import 'learning.dart';

class TeachingCourse {
  const TeachingCourse({
    required this.course,
    this.learnerCount = 0,
    this.lessonCount = 0,
    this.pendingReviews = 0,
  });

  final CourseRef course;
  final int learnerCount;
  final int lessonCount;
  final int pendingReviews;

  factory TeachingCourse.fromJson(Json j) => TeachingCourse(
        course: CourseRef.fromJson(j),
        learnerCount: intOf(j['learner_count']),
        lessonCount: intOf(j['lesson_count']),
        pendingReviews: intOf(j['pending_reviews']),
      );
}

class CourseLearner {
  const CourseLearner({
    required this.enrollmentId,
    required this.name,
    required this.email,
    required this.course,
    this.cohort,
    this.status = 'active',
    this.progress = 0,
    this.completedLessons = 0,
    this.submissions = 0,
    this.certificateNumber,
    this.enrolledAt,
  });

  final int enrollmentId;
  final String name;
  final String email;
  final CourseRef course;
  final String? cohort;
  final String status;
  final int progress;
  final int completedLessons;
  final int submissions;
  final String? certificateNumber;
  final DateTime? enrolledAt;

  factory CourseLearner.fromJson(Json j) => CourseLearner(
        enrollmentId: intOf(j['enrollment_id']),
        name: str(j['name']),
        email: str(j['email']),
        course: CourseRef.fromJson(jsonOf(j['course'])),
        cohort: strOrNull(j['cohort']),
        status: str(j['status']),
        progress: intOf(j['progress_percent']),
        completedLessons: intOf(j['completed_lessons']),
        submissions: intOf(j['submissions']),
        certificateNumber: strOrNull(j['certificate_number']),
        enrolledAt: dateOf(j['enrolled_at']),
      );
}

class ReviewItem {
  const ReviewItem({
    required this.submission,
    required this.lessonTitle,
    required this.learnerName,
    required this.learnerEmail,
    required this.course,
  });

  final Submission submission;
  final String lessonTitle;
  final String learnerName;
  final String learnerEmail;
  final CourseRef course;

  factory ReviewItem.fromJson(Json j) => ReviewItem(
        submission: Submission.fromJson(j),
        lessonTitle: str(j['lesson_title']),
        learnerName: str(j['learner_name']),
        learnerEmail: str(j['learner_email']),
        course: CourseRef.fromJson(jsonOf(j['course'])),
      );
}
