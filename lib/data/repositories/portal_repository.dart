import '../../core/network/api_client.dart';
import '../models/json.dart';
import '../models/portal.dart';

/// The client dashboard: projects, documents, updates, and support tickets.
class PortalRepository {
  PortalRepository(this._api);

  final ApiClient _api;

  Future<List<ClientProject>> projects() async =>
      listOf(await _api.get<Object>('/services/portal/projects/', auth: true)).map(ClientProject.fromJson).toList();

  Future<List<Ticket>> tickets() async =>
      listOf(await _api.get<Object>('/services/portal/tickets/', auth: true)).map(Ticket.fromJson).toList();

  /// Raises a support ticket. Signed in, it is linked to the account (and project).
  Future<String> raiseTicket({
    required String name,
    required String email,
    required String organization,
    required String serviceType,
    required String urgency,
    required String affectedSystem,
    required String description,
    String phone = '',
    int? projectId,
  }) async {
    final res = await _api.post<Json>(
      '/services/support-tickets/',
      auth: true,
      body: {
        'client_name': name.trim(),
        'email': email.trim(),
        'organization': organization.trim(),
        'phone': phone.trim(),
        'service_type': serviceType,
        'urgency': urgency,
        'affected_system': affectedSystem.trim(),
        'issue_description': description.trim(),
        'privacy_consent': true,
        'client_project': ?projectId,
      },
    );
    return str(res['ticket_number']).padRight(8).substring(0, 8).trim().toUpperCase();
  }
}

const ticketServiceTypes = [
  ('bug_incident', "Something isn't working"),
  ('maintenance', 'Maintenance or health check'),
  ('enhancement', 'Enhancement or new feature'),
  ('optimization', 'Performance or security'),
];

const ticketUrgencies = [
  ('low', 'Low', 'A question or minor issue with a workaround'),
  ('medium', 'Medium', 'Some users or features affected'),
  ('high', 'High', 'A key feature is unavailable'),
  ('critical', 'Critical', 'The system is down or data is at risk'),
];
