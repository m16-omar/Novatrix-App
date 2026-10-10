import '../../core/network/api_client.dart';
import '../models/facilitator.dart';
import '../models/json.dart';
import '../models/learning.dart';

/// Facilitator tools. Course content is authored on the website.
class TeachingRepository {
  TeachingRepository(this._api);

  final ApiClient _api;
  static const _base = '/services/facilitator';

  Future<List<TeachingCourse>> courses() async =>
      listOf(await _api.get<Object>('$_base/courses/', auth: true)).map(TeachingCourse.fromJson).toList();

  Future<List<ReviewItem>> reviews({SubmissionStatus? status}) async => listOf(await _api.get<Object>(
        '$_base/submissions/',
        auth: true,
        query: status == null ? null : {'status': status.apiValue},
      )).map(ReviewItem.fromJson).toList();

  Future<List<CourseLearner>> learners() async =>
      listOf(await _api.get<Object>('$_base/learners/', auth: true)).map(CourseLearner.fromJson).toList();

  /// Records a review; the backend emails the learner.
  Future<void> review(int submissionId, SubmissionStatus status, String feedback) =>
      _api.patch<Json>('$_base/submissions/$submissionId/', body: {'status': status.apiValue, 'feedback': feedback.trim()});

  Future<String> issueCertificate(int enrollmentId) async =>
      str((await _api.post<Json>('$_base/enrollments/$enrollmentId/certificate/', auth: true))['certificate_number']);
}
