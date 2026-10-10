import 'json.dart';

class Cohort {
  const Cohort({
    required this.name,
    this.startDate,
    this.endDate,
    this.schedule = '',
  });

  final String name;
  final DateTime? startDate;
  final DateTime? endDate;
  final String schedule;

  factory Cohort.fromJson(Json j) => Cohort(
        name: str(j['cohort_name']),
        startDate: dateOf(j['start_date']),
        endDate: dateOf(j['end_date']),
        schedule: str(j['schedule_description']),
      );
}

/// A course in the public catalog (`/services/courses/`).
class Course {
  const Course({
    required this.id,
    required this.slug,
    required this.title,
    required this.summary,
    this.topic = '',
    this.level = '',
    this.format = '',
    this.durationWeeks = 0,
    this.audience = '',
    this.outcomes = const [],
    this.prerequisites = '',
    this.projects = const [],
    this.certificate = '',
    this.price = 0,
    this.currency = 'USD',
    this.coverImageUrl,
    this.cohorts = const [],
  });

  final int id;
  final String slug;
  final String title;
  final String summary;
  final String topic;
  final String level;
  final String format;
  final int durationWeeks;
  final String audience;
  final List<String> outcomes;
  final String prerequisites;
  final List<String> projects;
  final String certificate;
  final double price;
  final String currency;
  final String? coverImageUrl;
  final List<Cohort> cohorts;

  factory Course.fromJson(Json j) => Course(
        id: intOf(j['id']),
        slug: str(j['slug']),
        title: str(j['title']),
        summary: str(j['summary']),
        topic: str(j['topic_display']),
        level: str(j['level_display']),
        format: str(j['format_display']),
        durationWeeks: intOf(j['duration_weeks']),
        audience: str(j['target_audience']),
        outcomes: strings(j['learning_outcomes']),
        prerequisites: str(j['prerequisites']),
        projects: strings(j['hands_on_projects']),
        certificate: str(j['certificate_details']),
        price: doubleOf(j['price_amount']),
        currency: str(j['price_currency']).isEmpty ? 'USD' : str(j['price_currency']),
        coverImageUrl: strOrNull(j['cover_image_url']),
        cohorts: jsonList(j['cohorts']).map(Cohort.fromJson).toList(),
      );

  /// Bundled photo for the launch courses when no cover is set in the admin.
  String? get bundledImage => switch (slug) {
        'data-analytics' => 'assets/images/course-data-analytics.jpg',
        'data-science' || 'machine-learning' => 'assets/images/course-data-science.jpg',
        'web-development' => 'assets/images/course-web-dev.jpg',
        'cloud-devops' => 'assets/images/course-cloud.jpg',
        _ => null,
      };

  /// The short level, e.g. "Intermediate" from "Intermediate / Career Transition".
  String get levelShort => level.split(' / ').first;
}

/// The light course reference embedded in enrollments and orders.
class CourseRef {
  const CourseRef({required this.slug, required this.title, this.summary = '', this.durationWeeks = 0});

  final String slug;
  final String title;
  final String summary;
  final int durationWeeks;

  factory CourseRef.fromJson(Json j) => CourseRef(
        slug: str(j['slug']),
        title: str(j['title']),
        summary: str(j['summary']),
        durationWeeks: intOf(j['duration_weeks']),
      );
}
