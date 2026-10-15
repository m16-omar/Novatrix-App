import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/assessment.dart';
import '../data/models/course.dart';
import '../data/models/facilitator.dart';
import '../data/models/learning.dart';
import '../data/models/notification.dart';
import '../data/models/portal.dart';
import '../data/models/site_catalog.dart';
import 'providers.dart';

/// Rebuilds signed-in data when the account changes, so nothing leaks between people.
int? _account(Ref ref) => ref.watch(sessionProvider.select((s) => s.value?.user.id));

/* ---------- public ---------- */

/// Services, industries, and insights from the website, bundled with the app.
final siteCatalogProvider = FutureProvider<SiteCatalog>((ref) async =>
    SiteCatalog.fromJson(jsonDecode(await rootBundle.loadString('assets/content/site.json')) as Map<String, dynamic>));

final coursesProvider = FutureProvider<List<Course>>((ref) => ref.watch(catalogRepositoryProvider).courses());

final courseProvider = FutureProvider.family<Course, String>(
  (ref, slug) => ref.watch(catalogRepositoryProvider).course(slug),
);

final curriculumProvider = FutureProvider.family<List<ModuleOutline>, String>(
  (ref, slug) => ref.watch(catalogRepositoryProvider).curriculum(slug),
);

/* ---------- learning ---------- */

final enrollmentsProvider = FutureProvider<List<Enrollment>>((ref) {
  _account(ref);
  return ref.watch(learningRepositoryProvider).enrollments();
});

final ordersProvider = FutureProvider<List<Order>>((ref) {
  _account(ref);
  return ref.watch(learningRepositoryProvider).orders();
});

final learnCourseProvider = FutureProvider.family<LearnCourse, String>((ref, slug) {
  _account(ref);
  return ref.watch(learningRepositoryProvider).course(slug);
});

final lessonProvider = FutureProvider.family<LessonDetail, (String, int)>((ref, key) {
  _account(ref);
  return ref.watch(learningRepositoryProvider).lesson(key.$1, key.$2);
});

/* ---------- teaching ---------- */

final teachingCoursesProvider = FutureProvider<List<TeachingCourse>>((ref) {
  _account(ref);
  return ref.watch(teachingRepositoryProvider).courses();
});

final reviewsProvider = FutureProvider.family<List<ReviewItem>, SubmissionStatus?>((ref, status) {
  _account(ref);
  return ref.watch(teachingRepositoryProvider).reviews(status: status);
});

final learnersProvider = FutureProvider<List<CourseLearner>>((ref) {
  _account(ref);
  return ref.watch(teachingRepositoryProvider).learners();
});

/* ---------- client ---------- */

final projectsProvider = FutureProvider<List<ClientProject>>((ref) {
  _account(ref);
  return ref.watch(portalRepositoryProvider).projects();
});

final ticketsProvider = FutureProvider<List<Ticket>>((ref) {
  _account(ref);
  return ref.watch(portalRepositoryProvider).tickets();
});

/* ---------- notifications ---------- */

/// The signed-in person's notifications, newest first.
final notificationsProvider = FutureProvider<List<AppNotification>>((ref) {
  if (_account(ref) == null) return const [];
  return ref.watch(notificationsRepositoryProvider).list();
});

/// How many are unread, for the bell's badge. Quiet on failure: a badge isn't worth an error.
final unreadNotificationsProvider = FutureProvider<int>((ref) async {
  if (_account(ref) == null) return 0;
  try {
    return await ref.watch(notificationsRepositoryProvider).unreadCount();
  } catch (_) {
    return 0;
  }
});

/* ---------- quizzes and exams ---------- */

final assessmentProvider = FutureProvider.family<AssessmentDetail, (String, int)>((ref, key) {
  _account(ref);
  return ref.watch(learningRepositoryProvider).assessment(key.$1, key.$2);
});

final attemptResultProvider = FutureProvider.family<AttemptResult, (String, int)>((ref, key) {
  _account(ref);
  return ref.watch(learningRepositoryProvider).attemptResult(key.$1, key.$2);
});
