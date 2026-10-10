import '../../core/network/api_client.dart';
import '../models/course.dart';
import '../models/json.dart';
import '../models/learning.dart';

/// Public content: the course catalog, syllabus, and the consultation form.
class CatalogRepository {
  CatalogRepository(this._api);

  final ApiClient _api;

  Future<List<Course>> courses() async =>
      listOf(await _api.get<Object>('/services/courses/', query: {'page_size': 100}))
          .map(Course.fromJson)
          .toList();

  Future<Course> course(String slug) async =>
      Course.fromJson(await _api.get<Json>('/services/courses/${Uri.encodeComponent(slug)}/'));

  /// Published modules and lesson titles; bodies only for free previews.
  Future<List<ModuleOutline>> curriculum(String slug) async {
    final res = await _api.get<Json>('/services/courses/${Uri.encodeComponent(slug)}/curriculum/');
    return jsonList(res['modules']).map(ModuleOutline.fromJson).toList();
  }

  Future<void> requestConsultation({
    required String name,
    required String email,
    required String phone,
    required String service,
    required String timeline,
    required String description,
    String organization = '',
  }) =>
      _api.post<Json>('/services/project-inquiries/', body: {
        'client_name': name.trim(),
        'organization': organization.trim(),
        'email': email.trim(),
        'phone_or_whatsapp': phone.trim(),
        'service_required': service,
        'desired_timeline': timeline,
        'budget_range': 'custom',
        'project_description': '${description.trim()}\n\n(Sent from the Novatrix mobile app)',
        'privacy_consent_recorded': true,
      });
}

const consultationServices = [
  ('custom_software', 'Custom software development'),
  ('system_implementation', 'System implementation'),
  ('systems_integration', 'Systems integration'),
  ('support_maintenance', 'Support and optimization'),
  ('other', 'Not sure yet / other'),
];

const consultationTimelines = [
  ('immediate', 'Immediately (within 30 days)'),
  ('1_to_3_months', 'Within 1–3 months'),
  ('3_to_6_months', 'Within 3–6 months'),
  ('planning', 'Still exploring or planning'),
];
