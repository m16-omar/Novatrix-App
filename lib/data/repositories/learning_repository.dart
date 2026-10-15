import '../../core/network/api_client.dart';
import '../models/json.dart';
import '../models/assessment.dart';
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

  Future<AssessmentDetail> assessment(String slug, int id) async =>
      AssessmentDetail.fromJson(await _api.get<Json>('${_base(slug)}/assessments/$id/', auth: true));

  /// Starts an attempt, or resumes the one in progress.
  Future<AttemptInProgress> startAttempt(String slug, int assessmentId) async => AttemptInProgress.fromJson(
      await _api.post<Json>('${_base(slug)}/assessments/$assessmentId/attempts/', auth: true));

  Map<String, List<int>> _answers(Map<int, Set<int>> answers) =>
      {for (final MapEntry(:key, :value) in answers.entries) '$key': value.toList()};

  /// Saves the answers so far, so a timed-out exam keeps them.
  Future<void> saveAnswers(String slug, int attemptId, Map<int, Set<int>> answers) =>
      _api.patch<Json>('${_base(slug)}/attempts/$attemptId/', body: {'answers': _answers(answers)});

  Future<AttemptResult> submitAttempt(String slug, int attemptId, Map<int, Set<int>> answers) async =>
      AttemptResult.fromJson(await _api.post<Json>('${_base(slug)}/attempts/$attemptId/submit/',
          body: {'answers': _answers(answers)}, auth: true));

  Future<AttemptResult> attemptResult(String slug, int attemptId) async =>
      AttemptResult.fromJson(await _api.get<Json>('${_base(slug)}/attempts/$attemptId/', auth: true));

  /// Starts paying for the courses in the cart. Free orders come back already paid; otherwise
  /// the person pays on [CheckoutStart.paymentUrl] and the app confirms with [verifyCheckout].
  Future<CheckoutStart> startCheckout(List<String> courseSlugs) async {
    final res = await _api.post<Json>('/services/checkout/', body: {'courses': courseSlugs}, auth: true);
    return CheckoutStart(
      reference: str(res['reference']),
      paid: str(res['status']) == 'paid',
      paymentUrl: strOrNull(res['authorization_url']),
    );
  }

  /// Asks the backend to check a payment with the payment provider. Pending until it's confirmed.
  Future<Order> verifyCheckout(String reference) async =>
      Order.fromJson(await _api.post<Json>('/services/checkout/verify/', body: {'reference': reference}, auth: true));

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

class CheckoutStart {
  const CheckoutStart({required this.reference, required this.paid, this.paymentUrl});

  final String reference;

  /// True for free orders, which are fulfilled straight away.
  final bool paid;
  final String? paymentUrl;
}
