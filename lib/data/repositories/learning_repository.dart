import '../../core/network/api_client.dart';
import '../models/json.dart';
import '../models/learning.dart';

/// The learner's courses, the course player, and certificates.
class LearningRepository {
  LearningRepository(this._api);

  final ApiClient _api;

  String _base(String slug) => '/services/learn/${Uri.encodeComponent(slug)}';

  Future<List<Enrollment>> enrollments() async =>
      listOf(await _api.get<Object>('/services/me/enrollments/', auth: true)).map(Enrollment.fromJson).toList();

  Future<List<Order>> orders() async =>
      listOf(await _api.get<Object>('/services/me/orders/', auth: true)).map(Order.fromJson).toList();

  Future<LearnCourse> course(String slug) async =>
      LearnCourse.fromJson(await _api.get<Json>('${_base(slug)}/', auth: true));

  Future<LessonDetail> lesson(String slug, int id) async =>
      LessonDetail.fromJson(await _api.get<Json>('${_base(slug)}/lessons/$id/', auth: true));

  /// Marks a lesson done (or not). Returns the new course progress.
  Future<int> setComplete(String slug, int id, bool done) async {
    final path = '${_base(slug)}/lessons/$id/complete/';
    final res = done ? await _api.post<Json>(path, auth: true) : await _api.delete<Json>(path);
    return intOf(res['progress_percent']);
  }

  Future<Submission> submit(String slug, int id, {String link = '', String notes = ''}) async =>
      Submission.fromJson(await _api.post<Json>(
        '${_base(slug)}/lessons/$id/submission/',
        body: {'link_url': link.trim(), 'notes': notes.trim()},
        auth: true,
      ));
}
