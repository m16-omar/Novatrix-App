import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data_providers.dart';
import '../../core/format.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/portal.dart';
import '../../data/repositories/portal_repository.dart';
import '../shell/app_shell.dart';
import '../shell/workspace.dart';

/// Projects and tickets together, for the dashboard.
final _overviewProvider = FutureProvider<(List<ClientProject>, List<Ticket>)>((ref) async {
  final results = await Future.wait([ref.watch(projectsProvider.future), ref.watch(ticketsProvider.future)]);
  return (results[0] as List<ClientProject>, results[1] as List<Ticket>);
});

/// Where a project is in delivery: Discovery → Build → Testing → Launch → Support.
class StageTracker extends StatelessWidget {
  const StageTracker({super.key, required this.project});
  final ClientProject project;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final current = project.stageIndex;
    final currentLabel = current >= 0 && current < projectStages.length ? projectStages[current].$2 : 'Closed';
    return Semantics(
      label: 'Project stage: $currentLabel',
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (final (i, stage) in projectStages.indexed)
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 2,
                            color: i == 0 ? Colors.transparent : (i <= current ? p.brand : p.muted),
                          ),
                        ),
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: i < current ? p.gradient : null,
                            color: i < current ? null : p.card,
                            border: Border.all(
                              color: i == current ? p.brand : (i < current ? Colors.transparent : p.border),
                              width: i == current ? 2 : 1,
                            ),
                          ),
                          child: i < current
                              ? const Icon(LucideIcons.check, size: 13, color: Colors.white)
                              : Text('${i + 1}',
                                  style: context.text.labelSmall?.copyWith(
                                    color: i == current ? p.brand : p.mutedForeground,
                                    fontWeight: FontWeight.w700,
                                  )),
                        ),
                        Expanded(
                          child: Container(
                            height: 2,
                            color: i == projectStages.length - 1
                                ? Colors.transparent
                                : (i < current ? p.brand : p.muted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stage.$2,
                      style: context.text.labelSmall?.copyWith(
                        color: i == current ? p.foreground : p.mutedForeground,
                        fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Widget _statusPill(ClientProject p) => Pill(p.statusDisplay, tone: p.isClosed ? PillTone.neutral : PillTone.brand);

Widget _ticketPill(Ticket t) => Pill(t.statusShort, tone: t.isOpen ? PillTone.neutral : PillTone.success);

class ClientDashboardScreen extends ConsumerWidget {
  const ClientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).value?.user;
    return Scaffold(
      appBar: const WorkspaceAppBar(workspace: Workspace.client),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(projectsProvider);
          ref.invalidate(ticketsProvider);
          await ref.read(sessionProvider.notifier).refreshRoles();
        },
        child: ListView(
          padding: pagePadding,
          children: [
            PageHeader(
              eyebrow: 'Client dashboard',
              title: 'Welcome, ${user?.firstName ?? ''}.',
              intro: 'Your projects with Novatrix, the latest updates, and your support requests.',
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: 'Raise a support request',
              icon: LucideIcons.messageSquarePlus,
              onPressed: () => context.go('/client/support/new'),
            ),
            const SizedBox(height: 20),
            AsyncBody(
              provider: _overviewProvider,
              loadingLabel: 'Loading your dashboard…',
              builder: (data) {
                final (projects, tickets) = data;
                final active = projects.where((p) => !p.isClosed).toList();
                final open = tickets.where((t) => t.isOpen).toList();
                final urgent = open.where((t) => t.isUrgent).length;
                final updates = [
                  for (final p in projects)
                    for (final u in p.updates) (u, p),
                ]..sort((a, b) => (b.$1.createdAt ?? DateTime(2000)).compareTo(a.$1.createdAt ?? DateTime(2000)));
                final deadlines = active.map((p) => p.targetEndDate).whereType<DateTime>().toList()..sort();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StatGrid(children: [
                      StatTile(
                        icon: LucideIcons.briefcase,
                        label: 'Active projects',
                        value: '${active.length}',
                        detail: projects.length > active.length ? '${projects.length - active.length} closed' : null,
                        onTap: () => context.go('/client/projects'),
                      ),
                      StatTile(
                        icon: LucideIcons.lifeBuoy,
                        label: 'Open tickets',
                        value: '${open.length}',
                        highlight: urgent > 0,
                        detail: urgent > 0 ? '$urgent high priority' : '${tickets.length} in total',
                        onTap: () => context.go('/client/support'),
                      ),
                      StatTile(
                        icon: LucideIcons.fileText,
                        label: 'Shared documents',
                        value: '${projects.fold(0, (n, p) => n + p.documents.length)}',
                      ),
                      StatTile(
                        icon: LucideIcons.calendarClock,
                        label: 'Next target date',
                        value: deadlines.isEmpty ? '—' : formatDate(deadlines.first),
                      ),
                    ]),
                    SectionTitle(
                      'Your projects',
                      action: projects.isEmpty ? null : 'All projects',
                      onAction: () => context.go('/client/projects'),
                    ),
                    if (projects.isEmpty)
                      const EmptyState(
                        icon: LucideIcons.briefcase,
                        title: 'No projects are linked to your account yet.',
                        message: "If you're a Novatrix client, ask your project lead to add this email address "
                            'to your project. You can still raise support requests.',
                      )
                    else
                      for (final p in (active.isEmpty ? projects : active).take(4)) ...[
                        ProjectCard(project: p),
                        const SizedBox(height: 12),
                      ],
                    const SectionTitle('Latest updates'),
                    if (updates.isEmpty)
                      Text("Your project team's updates will appear here.", style: context.text.bodySmall)
                    else
                      for (final (u, p) in updates.take(5)) ...[
                        UpdateTile(update: u, projectTitle: p.title),
                        const SizedBox(height: 10),
                      ],
                    SectionTitle(
                      'Support requests',
                      action: tickets.isEmpty ? null : 'All tickets',
                      onAction: () => context.go('/client/support'),
                    ),
                    if (tickets.isEmpty)
                      Text('You have no support tickets.', style: context.text.bodySmall)
                    else
                      for (final t in tickets.take(4)) ...[TicketTile(ticket: t), const SizedBox(height: 10)],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.project});
  final ClientProject project;

  @override
  Widget build(BuildContext context) {
    final p = project;
    return AppCard(
      onTap: () => context.go('/client/projects/${p.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.organization, style: context.text.bodySmall),
                    Text(p.title, style: context.text.titleMedium),
                  ],
                ),
              ),
              _statusPill(p),
            ],
          ),
          const SizedBox(height: 18),
          StageTracker(project: p),
          const SizedBox(height: 14),
          Text(
            [
              p.targetEndDate != null ? 'Target ${formatDate(p.targetEndDate)}' : 'Dates to be confirmed',
              plural(p.documents.length, 'document'),
              if (p.openTickets > 0) plural(p.openTickets, 'open ticket'),
            ].join(' · '),
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class UpdateTile extends StatelessWidget {
  const UpdateTile({super.key, required this.update, this.projectTitle});

  final ProjectUpdate update;
  final String? projectTitle;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [formatDate(update.createdAt), ?projectTitle].join(' · '),
              style: context.text.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(update.title, style: context.text.titleMedium),
            const SizedBox(height: 4),
            Text(update.body, style: context.text.bodyMedium?.copyWith(color: context.palette.mutedForeground)),
          ],
        ),
      );
}

class TicketTile extends StatelessWidget {
  const TicketTile({super.key, required this.ticket, this.showProject = true});

  final Ticket ticket;
  final bool showProject;

  @override
  Widget build(BuildContext context) {
    final t = ticket;
    final p = context.palette;
    return AppCard(
      onTap: showProject && t.projectId != null ? () => context.go('/client/projects/${t.projectId}') : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(t.reference, style: context.text.bodySmall?.copyWith(fontFamily: 'monospace')),
              const Spacer(),
              _ticketPill(t),
            ],
          ),
          const SizedBox(height: 6),
          Text(t.affectedSystem, style: context.text.titleMedium),
          const SizedBox(height: 2),
          Text(t.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Pill(t.urgencyShort, tone: t.urgency == 'critical' ? PillTone.danger : (t.urgency == 'high' ? PillTone.warning : PillTone.neutral)),
              Text('Updated ${formatDate(t.updatedAt)}', style: context.text.bodySmall),
              if (showProject && t.projectTitle != null) Text('· ${t.projectTitle}', style: context.text.bodySmall),
            ],
          ),
          if (t.resolutionNotes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: p.muted, borderRadius: BorderRadius.circular(10)),
              child: Text.rich(TextSpan(children: [
                TextSpan(text: 'Resolution: ', style: context.text.labelMedium),
                TextSpan(text: t.resolutionNotes),
              ])),
            ),
          ],
        ],
      ),
    );
  }
}

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: const WorkspaceAppBar(workspace: Workspace.client),
        body: RefreshIndicator(
          onRefresh: () => ref.refresh(projectsProvider.future),
          child: ListView(
            padding: pagePadding,
            children: [
              const PageHeader(
                eyebrow: 'Client dashboard',
                title: 'Projects',
                intro: "Every engagement you're part of, with its current stage.",
              ),
              const SizedBox(height: 20),
              AsyncBody(
                provider: projectsProvider,
                loadingLabel: 'Loading projects…',
                builder: (projects) => projects.isEmpty
                    ? const EmptyState(
                        icon: LucideIcons.briefcase,
                        title: 'No projects are linked to your account yet.',
                        message: 'Ask your Novatrix project lead to add this email address to your project.',
                      )
                    : Column(
                        children: [
                          for (final p in projects) ...[ProjectCard(project: p), const SizedBox(height: 12)],
                        ],
                      ),
              ),
            ],
          ),
        ),
      );
}

class ProjectScreen extends ConsumerWidget {
  const ProjectScreen({super.key, required this.projectId});
  final int projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/client/projects')),
          title: const Text('Project'),
        ),
        body: AsyncBody(
          provider: _overviewProvider,
          loadingLabel: 'Loading project…',
          builder: (data) {
            final (projects, tickets) = data;
            final project = projects.where((p) => p.id == projectId).firstOrNull;
            if (project == null) {
              return const Padding(
                padding: pagePadding,
                child: ErrorNote(
                  "This project doesn't exist or isn't shared with your account.",
                  title: 'Project not found',
                ),
              );
            }
            final projectTickets = tickets.where((t) => t.projectId == project.id).toList();
            return ListView(
              padding: pagePadding,
              children: [
                PageHeader(
                  eyebrow: project.organization,
                  title: project.title,
                  intro: [
                    if (project.startDate != null) 'Started ${formatDate(project.startDate)}',
                    project.targetEndDate != null
                        ? 'Target ${formatDate(project.targetEndDate)}'
                        : 'Dates to be confirmed',
                  ].join(' · '),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('Project stage', style: context.text.titleMedium)),
                          _statusPill(project),
                        ],
                      ),
                      const SizedBox(height: 18),
                      StageTracker(project: project),
                      if (project.summary.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(project.summary, style: context.text.bodyMedium),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GradientButton(
                  label: 'Report an issue',
                  icon: LucideIcons.messageSquarePlus,
                  onPressed: () => context.go('/client/support/new?project=${project.id}'),
                ),
                const SectionTitle('Documents'),
                if (project.documents.isEmpty)
                  Text('No documents shared yet.', style: context.text.bodySmall)
                else
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final (i, d) in project.documents.indexed) ...[
                          if (i > 0) const Divider(),
                          ListTile(
                            leading: const Icon(LucideIcons.fileText),
                            title: Text(d.title),
                            subtitle: Text('Shared ${formatDate(d.createdAt)}'),
                            trailing: const Icon(LucideIcons.externalLink, size: 16),
                            onTap: () => openLink(context, d.url),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SectionTitle('Updates'),
                if (project.updates.isEmpty)
                  Text('No updates yet.', style: context.text.bodySmall)
                else
                  for (final u in project.updates) ...[UpdateTile(update: u), const SizedBox(height: 10)],
                const SectionTitle('Support tickets for this project'),
                if (projectTickets.isEmpty)
                  Text('No tickets raised for this project.', style: context.text.bodySmall)
                else
                  for (final t in projectTickets) ...[
                    TicketTile(ticket: t, showProject: false),
                    const SizedBox(height: 10),
                  ],
              ],
            );
          },
        ),
      );
}

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  String _filter = 'open';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const WorkspaceAppBar(workspace: Workspace.client),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/client/support/new'),
          icon: const Icon(LucideIcons.plus),
          label: const Text('New request'),
          backgroundColor: context.palette.brand,
          foregroundColor: Colors.white,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await ref.read(sessionProvider.notifier).refreshRoles();
            return ref.refresh(ticketsProvider.future);
          },
          child: ListView(
            padding: pagePadding.copyWith(bottom: 96),
            children: [
              const PageHeader(
                eyebrow: 'Client dashboard',
                title: 'Support',
                intro: 'Track your support requests and raise new ones.',
              ),
              const SizedBox(height: 16),
              AsyncBody(
                provider: ticketsProvider,
                loadingLabel: 'Loading tickets…',
                builder: (tickets) {
                  final open = tickets.where((t) => t.isOpen).length;
                  final shown = tickets
                      .where((t) => _filter == 'all' || (_filter == 'open' ? t.isOpen : !t.isOpen))
                      .toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final (value, label) in [
                            ('open', 'Open ($open)'),
                            ('resolved', 'Resolved (${tickets.length - open})'),
                            ('all', 'All (${tickets.length})'),
                          ])
                            ChoiceChip(
                              label: Text(label),
                              selected: _filter == value,
                              onSelected: (_) => setState(() => _filter = value),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (shown.isEmpty)
                        EmptyState(
                          icon: LucideIcons.lifeBuoy,
                          title: _filter == 'open' ? 'No open tickets.' : 'No tickets here.',
                        )
                      else
                        for (final t in shown) ...[TicketTile(ticket: t), const SizedBox(height: 10)],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
}

class NewTicketScreen extends ConsumerStatefulWidget {
  const NewTicketScreen({super.key, this.projectId});
  final int? projectId;

  @override
  ConsumerState<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends ConsumerState<NewTicketScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _organization = TextEditingController();
  final _phone = TextEditingController();
  final _system = TextEditingController();
  final _description = TextEditingController();
  String? _serviceType;
  String? _urgency;
  int? _project;
  bool _prefilled = false;
  bool _busy = false;
  String? _reference;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(sessionProvider).value?.user;
    _name.text = user?.fullName ?? '';
    _email.text = user?.email ?? '';
    _project = widget.projectId;
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _organization, _phone, _system, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Fill the organization from the client's projects, once they load.
  void _prefill(List<ClientProject> projects) {
    if (_prefilled) return;
    _prefilled = true;
    final selected = projects.where((p) => p.id == _project).firstOrNull;
    final orgs = {for (final p in projects) p.organization};
    if (_organization.text.isEmpty) {
      _organization.text = selected?.organization ?? (orgs.length == 1 ? orgs.first : '');
    }
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final reference = await ref.read(portalRepositoryProvider).raiseTicket(
            name: _name.text,
            email: _email.text,
            organization: _organization.text,
            phone: _phone.text,
            serviceType: _serviceType!,
            urgency: _urgency!,
            affectedSystem: _system.text,
            description: _description.text,
            projectId: _project,
          );
      ref.invalidate(ticketsProvider);
      ref.invalidate(projectsProvider);
      await ref.read(sessionProvider.notifier).refreshRoles();
      setState(() => _reference = reference);
    } on ApiException catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider).value ?? const <ClientProject>[];
    if (projects.isNotEmpty) _prefill(projects);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/client/support')),
        title: const Text('New support request'),
      ),
      body: ListView(
        padding: pagePadding,
        children: [
          if (_reference != null)
            EmptyState(
              icon: LucideIcons.circleCheck,
              title: 'Request received',
              message: 'Your reference is $_reference. We emailed you a confirmation and will update you here.',
              action: GradientButton(
                label: 'View my tickets',
                expand: false,
                onPressed: () => context.go('/client/support'),
              ),
            )
          else
            Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    ErrorNote(_error!.firstError, title: "We couldn't send your request."),
                    const SizedBox(height: 16),
                  ],
                  LabeledField(label: 'Name', controller: _name, errorText: _error?.field('client_name')),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'Email',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    validator: validateEmail,
                    errorText: _error?.field('email'),
                  ),
                  const SizedBox(height: 16),
                  LabeledField(label: 'Organization', controller: _organization, errorText: _error?.field('organization')),
                  const SizedBox(height: 16),
                  LabeledField(label: 'Phone or WhatsApp', controller: _phone, optional: true, keyboardType: TextInputType.phone),
                  if (projects.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    LabeledDropdown<int?>(
                      label: 'Project',
                      optional: true,
                      value: _project,
                      hint: 'Not related to a project',
                      items: [(null, 'Not related to a project'), for (final p in projects) (p.id, p.title)],
                      onChanged: (v) => setState(() {
                        _project = v;
                        final org = projects.where((p) => p.id == v).firstOrNull?.organization;
                        if (org != null && _organization.text.isEmpty) _organization.text = org;
                      }),
                    ),
                  ],
                  const SizedBox(height: 16),
                  LabeledDropdown<String>(
                    label: 'Type of support',
                    value: _serviceType,
                    hint: 'Choose the type of support',
                    items: ticketServiceTypes,
                    onChanged: (v) => setState(() => _serviceType = v),
                  ),
                  const SizedBox(height: 16),
                  Text.rich(TextSpan(
                    text: 'Urgency',
                    style: context.text.labelLarge,
                    children: [TextSpan(text: ' *', style: TextStyle(color: context.palette.destructive))],
                  )),
                  FormField<String>(
                    validator: (_) => _urgency == null ? 'Choose how urgent this is.' : null,
                    builder: (state) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RadioGroup<String>(
                          groupValue: _urgency,
                          onChanged: (v) {
                            setState(() => _urgency = v);
                            state.didChange(v);
                          },
                          child: Column(
                            children: [
                              for (final (value, label, hint) in ticketUrgencies)
                                RadioListTile<String>(
                                  value: value,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(label),
                                  subtitle: Text(hint),
                                ),
                            ],
                          ),
                        ),
                        if (state.hasError)
                          Text(state.errorText!,
                              style: context.text.bodySmall?.copyWith(color: context.palette.destructive)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  LabeledField(
                    label: 'Affected system',
                    controller: _system,
                    hint: 'e.g. Payroll export, Student portal',
                    errorText: _error?.field('affected_system'),
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'Describe the issue',
                    controller: _description,
                    maxLines: 5,
                    maxLength: 5000,
                    helper: 'What happened, what you expected, and any error messages.',
                    errorText: _error?.field('issue_description'),
                  ),
                  const SizedBox(height: 8),
                  ConsentField(
                    text: 'I agree that The Novatrix may use these details to handle this request, '
                        'as described in the Privacy Policy.',
                  ),
                  const SizedBox(height: 20),
                  GradientButton(label: 'Send request', icon: LucideIcons.send, busy: _busy, onPressed: _submit),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
