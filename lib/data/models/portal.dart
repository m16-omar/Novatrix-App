import 'json.dart';

class ProjectDocument {
  const ProjectDocument({required this.id, required this.title, required this.url, this.createdAt});

  final int id;
  final String title;
  final String url;
  final DateTime? createdAt;

  factory ProjectDocument.fromJson(Json j) =>
      ProjectDocument(id: intOf(j['id']), title: str(j['title']), url: str(j['url']), createdAt: dateOf(j['created_at']));
}

class ProjectUpdate {
  const ProjectUpdate({required this.id, required this.title, required this.body, this.createdAt});

  final int id;
  final String title;
  final String body;
  final DateTime? createdAt;

  factory ProjectUpdate.fromJson(Json j) =>
      ProjectUpdate(id: intOf(j['id']), title: str(j['title']), body: str(j['body']), createdAt: dateOf(j['created_at']));
}

/// The delivery stages shown on the client dashboard's tracker.
const projectStages = [
  ('discovery', 'Discovery'),
  ('in_progress', 'Build'),
  ('testing', 'Testing'),
  ('launched', 'Launch'),
  ('support', 'Support'),
];

class ClientProject {
  const ClientProject({
    required this.id,
    required this.title,
    required this.organization,
    required this.status,
    required this.statusDisplay,
    this.summary = '',
    this.startDate,
    this.targetEndDate,
    this.documents = const [],
    this.updates = const [],
    this.openTickets = 0,
  });

  final int id;
  final String title;
  final String organization;
  final String status;
  final String statusDisplay;
  final String summary;
  final DateTime? startDate;
  final DateTime? targetEndDate;
  final List<ProjectDocument> documents;
  final List<ProjectUpdate> updates;
  final int openTickets;

  bool get isClosed => status == 'closed';

  /// Index of the current stage; past the end when the project is closed.
  int get stageIndex =>
      isClosed ? projectStages.length : projectStages.indexWhere((s) => s.$1 == status);

  factory ClientProject.fromJson(Json j) => ClientProject(
        id: intOf(j['id']),
        title: str(j['title']),
        organization: str(j['organization']),
        status: str(j['status']),
        statusDisplay: str(j['status_display']),
        summary: str(j['summary']),
        startDate: dateOf(j['start_date']),
        targetEndDate: dateOf(j['target_end_date']),
        documents: jsonList(j['documents']).map(ProjectDocument.fromJson).toList(),
        updates: jsonList(j['updates']).map(ProjectUpdate.fromJson).toList(),
        openTickets: intOf(j['open_tickets']),
      );
}

class Ticket {
  const Ticket({
    required this.reference,
    required this.affectedSystem,
    required this.description,
    required this.urgency,
    required this.urgencyDisplay,
    required this.status,
    required this.statusDisplay,
    this.resolutionNotes = '',
    this.projectId,
    this.projectTitle,
    this.createdAt,
    this.updatedAt,
  });

  final String reference;
  final String affectedSystem;
  final String description;
  final String urgency;
  final String urgencyDisplay;
  final String status;
  final String statusDisplay;
  final String resolutionNotes;
  final int? projectId;
  final String? projectTitle;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isOpen => status == 'new' || status == 'in_progress';
  bool get isUrgent => urgency == 'high' || urgency == 'critical';

  /// "Under Investigation / In Progress" → "Under Investigation".
  String get statusShort => statusDisplay.split(' / ').first;
  String get urgencyShort => urgencyDisplay.split(' - ').first;

  factory Ticket.fromJson(Json j) => Ticket(
        reference: str(j['reference']),
        affectedSystem: str(j['affected_system']),
        description: str(j['issue_description']),
        urgency: str(j['urgency']),
        urgencyDisplay: str(j['urgency_display']),
        status: str(j['status']),
        statusDisplay: str(j['status_display']),
        resolutionNotes: str(j['resolution_notes']),
        projectId: intOrNull(j['project_id']),
        projectTitle: strOrNull(j['project_title']),
        createdAt: dateOf(j['created_at']),
        updatedAt: dateOf(j['updated_at']),
      );
}
