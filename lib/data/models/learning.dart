import 'course.dart';
import 'assessment.dart';
import 'json.dart';

class Resource {
  const Resource({required this.id, required this.title, required this.kind, required this.url, this.description = ''});

  final int id;
  final String title;
  final String kind;
  final String url;
  final String description;

  factory Resource.fromJson(Json j) => Resource(
        id: intOf(j['id']),
        title: str(j['title']),
        kind: str(j['kind']),
        url: str(j['url']),
        description: str(j['description']),
      );
}

/// Lesson-level progress the backend adds to each enrollment.
class LearningProgress {
  const LearningProgress({
    this.totalLessons = 0,
    this.completedLessons = 0,
    this.assignmentsTotal = 0,
    this.assignmentsSubmitted = 0,
    this.assignmentsReviewed = 0,
    this.nextLessonId,
    this.nextLessonTitle,
    this.lastActivityAt,
  });

  final int totalLessons;
  final int completedLessons;
  final int assignmentsTotal;
  final int assignmentsSubmitted;
  final int assignmentsReviewed;
  final int? nextLessonId;
  final String? nextLessonTitle;
  final DateTime? lastActivityAt;

  factory LearningProgress.fromJson(Json j) {
    final next = j['next_lesson'] is Map ? jsonOf(j['next_lesson']) : null;
    return LearningProgress(
      totalLessons: intOf(j['total_lessons']),
      completedLessons: intOf(j['completed_lessons']),
      assignmentsTotal: intOf(j['assignments_total']),
      assignmentsSubmitted: intOf(j['assignments_submitted']),
      assignmentsReviewed: intOf(j['assignments_reviewed']),
      nextLessonId: next == null ? null : intOf(next['id']),
      nextLessonTitle: next == null ? null : str(next['title']),
      lastActivityAt: dateOf(j['last_activity_at']),
    );
  }
}

class Enrollment {
  const Enrollment({
    required this.id,
    required this.course,
    required this.status,
    required this.statusDisplay,
    required this.progress,
    required this.learning,
    this.cohort,
    this.certificateNumber,
    this.certificateIssuedAt,
    this.createdAt,
    this.resources = const [],
  });

  final int id;
  final CourseRef course;
  final String status;
  final String statusDisplay;
  final int progress;
  final LearningProgress learning;
  final Cohort? cohort;
  final String? certificateNumber;
  final DateTime? certificateIssuedAt;
  final DateTime? createdAt;
  final List<Resource> resources;

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';

  factory Enrollment.fromJson(Json j) => Enrollment(
        id: intOf(j['id']),
        course: CourseRef.fromJson(jsonOf(j['course'])),
        status: str(j['status']),
        statusDisplay: str(j['status_display']),
        progress: intOf(j['progress_percent']),
        learning: LearningProgress.fromJson(jsonOf(j['learning'])),
        cohort: j['cohort'] is Map ? Cohort.fromJson(jsonOf(j['cohort'])) : null,
        certificateNumber: strOrNull(j['certificate_number']),
        certificateIssuedAt: dateOf(j['certificate_issued_at']),
        createdAt: dateOf(j['created_at']),
        resources: jsonList(j['resources']).map(Resource.fromJson).toList(),
      );
}

class Order {
  const Order({
    required this.reference,
    required this.status,
    required this.statusDisplay,
    required this.currency,
    required this.total,
    required this.courses,
    this.createdAt,
  });

  final String reference;
  final String status;
  final String statusDisplay;
  final String currency;
  final double total;
  final List<String> courses;
  final DateTime? createdAt;

  factory Order.fromJson(Json j) => Order(
        reference: str(j['reference']),
        status: str(j['status']),
        statusDisplay: str(j['status_display']),
        currency: str(j['currency']),
        total: doubleOf(j['total_amount']),
        courses: jsonList(j['items']).map((i) => str(jsonOf(i['course'])['title'])).toList(),
        createdAt: dateOf(j['created_at']),
      );
}

/* ---------- course player ---------- */

enum LessonKind {
  reading('Reading'),
  video('Video'),
  assignment('Assignment'),
  live('Live session');

  const LessonKind(this.label);
  final String label;

  static LessonKind parse(Object? v) =>
      LessonKind.values.firstWhere((k) => k.name == '$v', orElse: () => LessonKind.reading);
}

enum SubmissionStatus {
  submitted('Awaiting review'),
  reviewed('Reviewed'),
  needsRevision('Needs revision');

  const SubmissionStatus(this.label);
  final String label;

  String get apiValue => this == needsRevision ? 'needs_revision' : name;

  static SubmissionStatus? parse(Object? v) => switch ('$v') {
        'submitted' => submitted,
        'reviewed' => reviewed,
        'needs_revision' => needsRevision,
        _ => null,
      };
}

class LessonOutline {
  const LessonOutline({
    required this.id,
    required this.title,
    required this.kind,
    this.durationMinutes = 0,
    this.isPreview = false,
    this.completed = false,
    this.submissionStatus,
  });

  final int id;
  final String title;
  final LessonKind kind;
  final int durationMinutes;
  final bool isPreview;
  final bool completed;
  final SubmissionStatus? submissionStatus;

  factory LessonOutline.fromJson(Json j) => LessonOutline(
        id: intOf(j['id']),
        title: str(j['title']),
        kind: LessonKind.parse(j['kind']),
        durationMinutes: intOf(j['duration_minutes']),
        isPreview: boolOf(j['is_preview']),
        completed: boolOf(j['completed']),
        submissionStatus: SubmissionStatus.parse(j['submission_status']),
      );
}

class ModuleOutline {
  const ModuleOutline({
    required this.id,
    required this.title,
    this.summary = '',
    this.lessons = const [],
    this.quizzes = const [],
  });

  final int id;
  final String title;
  final String summary;
  final List<LessonOutline> lessons;

  /// Practice quizzes at the end of the module.
  final List<AssessmentSummary> quizzes;

  factory ModuleOutline.fromJson(Json j) => ModuleOutline(
        id: intOf(j['id']),
        title: str(j['title']),
        summary: str(j['summary']),
        lessons: jsonList(j['lessons']).map(LessonOutline.fromJson).toList(),
        quizzes: jsonList(j['quizzes']).map(AssessmentSummary.fromJson).toList(),
      );
}

class Announcement {
  const Announcement({required this.id, required this.title, required this.body, this.authorName = '', this.createdAt});

  final int id;
  final String title;
  final String body;
  final String authorName;
  final DateTime? createdAt;

  factory Announcement.fromJson(Json j) => Announcement(
        id: intOf(j['id']),
        title: str(j['title']),
        body: str(j['body']),
        authorName: str(j['author_name']),
        createdAt: dateOf(j['created_at']),
      );
}

/// Everything the course player needs (`/services/learn/{slug}/`).
class LearnCourse {
  const LearnCourse({
    required this.course,
    required this.role,
    required this.modules,
    this.enrollmentStatus,
    this.progress = 0,
    this.certificateNumber,
    this.cohort,
    this.announcements = const [],
    this.resources = const [],
    this.finalExam,
  });

  final CourseRef course;

  /// Passing it is required for the certificate. Null when the course has none.
  final AssessmentSummary? finalExam;
  final String role;
  final List<ModuleOutline> modules;
  final String? enrollmentStatus;
  final int progress;
  final String? certificateNumber;
  final Cohort? cohort;
  final List<Announcement> announcements;
  final List<Resource> resources;

  bool get isFacilitatorPreview => role == 'facilitator';
  List<LessonOutline> get lessons => [for (final m in modules) ...m.lessons];

  factory LearnCourse.fromJson(Json j) {
    final enrollment = j['enrollment'] is Map ? jsonOf(j['enrollment']) : null;
    return LearnCourse(
      course: CourseRef.fromJson(jsonOf(j['course'])),
      role: str(j['role']),
      modules: jsonList(j['modules']).map(ModuleOutline.fromJson).toList(),
      enrollmentStatus: enrollment == null ? null : str(enrollment['status']),
      progress: enrollment == null ? 0 : intOf(enrollment['progress_percent']),
      certificateNumber: enrollment == null ? null : strOrNull(enrollment['certificate_number']),
      cohort: enrollment?['cohort'] is Map ? Cohort.fromJson(jsonOf(enrollment!['cohort'])) : null,
      announcements: jsonList(j['announcements']).map(Announcement.fromJson).toList(),
      resources: jsonList(j['resources']).map(Resource.fromJson).toList(),
      finalExam: j['final_exam'] is Map ? AssessmentSummary.fromJson(jsonOf(j['final_exam'])) : null,
    );
  }
}

class Submission {
  const Submission({
    required this.id,
    required this.status,
    this.linkUrl = '',
    this.notes = '',
    this.feedback = '',
    this.submittedAt,
    this.updatedAt,
    this.reviewedAt,
  });

  final int id;
  final SubmissionStatus status;
  final String linkUrl;
  final String notes;
  final String feedback;
  final DateTime? submittedAt;
  final DateTime? updatedAt;
  final DateTime? reviewedAt;

  factory Submission.fromJson(Json j) => Submission(
        id: intOf(j['id']),
        status: SubmissionStatus.parse(j['status']) ?? SubmissionStatus.submitted,
        linkUrl: str(j['link_url']),
        notes: str(j['notes']),
        feedback: str(j['feedback']),
        submittedAt: dateOf(j['submitted_at']),
        updatedAt: dateOf(j['updated_at']),
        reviewedAt: dateOf(j['reviewed_at']),
      );
}

class LessonDetail {
  const LessonDetail({
    required this.id,
    required this.title,
    required this.kind,
    this.content = '',
    this.videoUrl = '',
    this.resourceUrl = '',
    this.durationMinutes = 0,
    this.moduleTitle = '',
    this.completed = false,
    this.previousId,
    this.nextId,
    this.submission,
    this.canTrack = false,
  });

  final int id;
  final String title;
  final LessonKind kind;
  final String content;
  final String videoUrl;
  final String resourceUrl;
  final int durationMinutes;
  final String moduleTitle;
  final bool completed;
  final int? previousId;
  final int? nextId;
  final Submission? submission;
  final bool canTrack;

  factory LessonDetail.fromJson(Json j) => LessonDetail(
        id: intOf(j['id']),
        title: str(j['title']),
        kind: LessonKind.parse(j['kind']),
        content: str(j['content']),
        videoUrl: str(j['video_url']),
        resourceUrl: str(j['resource_url']),
        durationMinutes: intOf(j['duration_minutes']),
        moduleTitle: str(j['module_title']),
        completed: boolOf(j['completed']),
        previousId: intOrNull(j['previous_id']),
        nextId: intOrNull(j['next_id']),
        submission: j['submission'] is Map ? Submission.fromJson(jsonOf(j['submission'])) : null,
        canTrack: boolOf(j['can_track']),
      );
}
