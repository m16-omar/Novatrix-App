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
import '../notifications/notifications_screen.dart';
import '../shell/app_shell.dart';
import '../shell/workspace.dart';

/// Projects and tickets together, for the dashboard.
final _overviewProvider = FutureProvider<(List<ClientProject>, List<Ticket>)>((ref) async {
  final results = await Future.wait([ref.watch(projectsProvider.future), ref.watch(ticketsProvider.future)]);
  return (results[0] as List<ClientProject>, results[1] as List<Ticket>);
});

/// Where a project is in delivery: Discovery → Build → Testing → Launch → Support.
class StageTracker extends StatelessWidget {
  const StageTracker({super.key, required this.project, this.onBrand = false});
  final ClientProject project;

  /// Drawn in white, for the gradient banner on the client home.
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final white = Colors.white;
    final line = onBrand ? white.withValues(alpha: 0.3) : p.muted;
    final done = onBrand ? white : p.brand;
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
                            color: i == 0 ? Colors.transparent : (i <= current ? done : line),
                          ),
                        ),
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: i < current && !onBrand ? p.gradient : null,
                            color: i < current ? (onBrand ? white : null) : (onBrand ? Colors.transparent : p.card),
                            border: Border.all(
                              color: i == current ? done : (i < current ? Colors.transparent : (onBrand ? line : p.border)),
                              width: i == current ? 2 : 1,
                            ),
                          ),
                          child: i < current
                              ? Icon(LucideIcons.check, size: 13, color: onBrand ? p.brand : white)
                              : Text('${i + 1}',
                                  style: context.text.labelSmall?.copyWith(
                                    color: onBrand
                                        ? (i == current ? white : white.withValues(alpha: 0.7))
                                        : (i == current ? p.brand : p.mutedForeground),
                                    fontWeight: FontWeight.w700,
                                  )),
                        ),
                        Expanded(
                          child: Container(
                            height: 2,
                            color: i == projectStages.length - 1
                                ? Colors.transparent
                                : (i < current ? done : line),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stage.$2,
                      style: context.text.labelSmall?.copyWith(
                        color: onBrand
                            ? (i == current ? white : white.withValues(alpha: 0.75))
                            : (i == current ? p.foreground : p.mutedForeground),
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
    final session = ref.watch(sessionProvider).value;
    final p = context.palette;
    final areas = session == null ? const <Workspace>[] : Workspace.available(session.roles);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(projectsProvider);
            ref.invalidate(ticketsProvider);
            await ref.read(sessionProvider.notifier).refreshRoles();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${greeting()}, ${session?.user.firstName ?? ''} 👋', style: context.text.titleLarge),
                        const SizedBox(height: 2),
                        Text("Here's where your projects stand.", style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  const NotificationBell(),
                  if (session != null)
                    IconButton(
                      tooltip: 'My profile',
                      onPressed: () => context.go('/profile'),
                      icon: Avatar(user: session.user, size: 40),
                    ),
                ],
              ),
              // People who also learn or teach can switch area from here.
              if (session != null && areas.length > 1) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    key: const ValueKey('workspace-switcher'),
                    avatar: Icon(LucideIcons.briefcase, size: 15, color: p.brand),
                    label: const Text('Client area'),
                    onPressed: () => showWorkspaceSwitcher(context, session.roles, Workspace.client),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              AsyncBody(
                provider: _overviewProvider,
                loadingLabel: 'Loading your dashboard…',
                builder: (data) => _ClientHomeBody(projects: data.$1, tickets: data.$2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientHomeBody extends StatelessWidget {
  const _ClientHomeBody({required this.projects, required this.tickets});

  final List<ClientProject> projects;
  final List<Ticket> tickets;

  @override
  Widget build(BuildContext context) {
    final active = projects.where((p) => !p.isClosed).toList()
      ..sort((a, b) => (a.targetEndDate ?? DateTime(9999)).compareTo(b.targetEndDate ?? DateTime(9999)));
    // The banner shows the active project due soonest; the rest are listed below.
    final focus = active.firstOrNull ?? projects.firstOrNull;
    final others = [for (final p in (active.isEmpty ? projects : active)) if (p != focus) p];
    final open = tickets.where((t) => t.isOpen).toList();
    final urgent = open.where((t) => t.isUrgent).length;
    final documents = projects.fold(0, (n, p) => n + p.documents.length);
    final updates = [
      for (final p in projects)
        for (final u in p.updates) (u, p),
    ]..sort((a, b) => (b.$1.createdAt ?? DateTime(2000)).compareTo(a.$1.createdAt ?? DateTime(2000)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (focus == null) const _NoProjectBanner() else _ProjectBanner(project: focus),
        const SizedBox(height: 18),
        const _QuickActions(),
        const SizedBox(height: 18),
        Row(
          children: [
            _Count(
              icon: LucideIcons.briefcase,
              value: active.length,
              label: active.length == 1 ? 'Project' : 'Projects',
              onTap: () => context.go('/client/projects'),
            ),
            const SizedBox(width: 10),
            _Count(
              icon: LucideIcons.lifeBuoy,
              value: open.length,
              label: urgent > 0 ? 'Open · $urgent urgent' : (open.length == 1 ? 'Open ticket' : 'Open tickets'),
              warning: urgent > 0,
              onTap: () => context.go('/client/support'),
            ),
            const SizedBox(width: 10),
            _Count(icon: LucideIcons.fileText, value: documents, label: documents == 1 ? 'Document' : 'Documents'),
          ],
        ),
        if (others.isNotEmpty) ...[
          SectionTitle('Other projects', action: 'All projects', onAction: () => context.go('/client/projects')),
          for (final p in others.take(3)) ...[ProjectCard(project: p), const SizedBox(height: 12)],
        ],
        const SectionTitle('Latest updates'),
        if (updates.isEmpty)
          const _Placeholder(
            icon: LucideIcons.megaphone,
            text: "Your project team's updates will appear here.",
          )
        else
          AppCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Column(
              children: [
                for (final (i, (u, p)) in updates.take(4).indexed)
                  _UpdateRow(update: u, projectTitle: projects.length > 1 ? p.title : null, last: i == updates.take(4).length - 1),
              ],
            ),
          ),
        SectionTitle(
          'Support requests',
          action: tickets.isEmpty ? null : 'All tickets',
          onAction: () => context.go('/client/support'),
        ),
        if (tickets.isEmpty)
          const _Placeholder(icon: LucideIcons.lifeBuoy, text: "You have no support requests. We're here if anything comes up.")
        else
          for (final t in (open.isNotEmpty ? open : tickets).take(3)) ...[TicketTile(ticket: t), const SizedBox(height: 10)],
        const SizedBox(height: 18),
        AppCard(
          onTap: () => context.push('/consultation'),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.palette.brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(LucideIcons.sparkles, size: 19, color: context.palette.brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Planning something new?', style: context.text.labelLarge),
                    Text('Request a consultation for your next project.', style: context.text.bodySmall),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: context.palette.mutedForeground),
            ],
          ),
        ),
      ],
    );
  }
}

/// The gradient banner: the project that needs attention soonest, and where it is.
class _ProjectBanner extends StatelessWidget {
  const _ProjectBanner({required this.project});
  final ClientProject project;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final white = Colors.white;
    final pr = project;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(gradient: p.gradient, borderRadius: BorderRadius.circular(18)),
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
                    Text(pr.organization.toUpperCase(),
                        style: context.text.labelSmall?.copyWith(
                            color: white.withValues(alpha: 0.85), letterSpacing: 1.4, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(pr.title, style: context.text.headlineSmall?.copyWith(color: white)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(99)),
                child: Text(pr.statusDisplay,
                    style: context.text.labelSmall?.copyWith(color: white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          StageTracker(project: pr, onBrand: true),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(LucideIcons.calendarClock, size: 15, color: white.withValues(alpha: 0.9)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  pr.targetEndDate != null ? 'Target ${formatDate(pr.targetEndDate)}' : 'Dates to be confirmed',
                  style: context.text.bodySmall?.copyWith(color: white.withValues(alpha: 0.9)),
                ),
              ),
              Material(
                color: white,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  key: const ValueKey('open-focus-project'),
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => context.go('/client/projects/${pr.id}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Open project', style: context.text.labelLarge?.copyWith(color: p.brand)),
                        const SizedBox(width: 4),
                        Icon(LucideIcons.chevronRight, size: 16, color: p.brand),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoProjectBanner extends StatelessWidget {
  const _NoProjectBanner();

  @override
  Widget build(BuildContext context) {
    final white = Colors.white;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: context.palette.gradient, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.briefcase, color: white),
          const SizedBox(height: 12),
          Text('No project linked yet', style: context.text.titleLarge?.copyWith(color: white)),
          const SizedBox(height: 6),
          Text(
            "If you're a Novatrix client, ask your project lead to add this email address to your project. "
            'You can still raise support requests.',
            style: context.text.bodySmall?.copyWith(color: white.withValues(alpha: 0.9), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final actions = [
      (LucideIcons.messageSquarePlus, 'New request', () => context.go('/client/support/new')),
      (LucideIcons.briefcase, 'Projects', () => context.go('/client/projects')),
      (LucideIcons.lifeBuoy, 'Support', () => context.go('/client/support')),
      (LucideIcons.sparkles, 'Consult', () => context.push('/consultation')),
    ];
    return Row(
      children: [
        for (final (icon, label, onTap) in actions)
          Expanded(
            child: Semantics(
              button: true,
              label: label,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: p.brand.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: p.brand, size: 22),
                      ),
                      const SizedBox(height: 6),
                      ExcludeSemantics(
                        child: Text(label, style: context.text.labelMedium, textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.icon, required this.value, required this.label, this.warning = false, this.onTap});

  final IconData icon;
  final int value;
  final String label;
  final bool warning;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tint = warning ? p.warning : p.brand;
    return Expanded(
      child: AppCard(
        onTap: onTap,
        highlight: warning ? p.warning.withValues(alpha: 0.6) : null,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: tint),
            const SizedBox(height: 8),
            Text('$value', style: context.text.headlineSmall),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// One project update in the timeline.
class _UpdateRow extends StatelessWidget {
  const _UpdateRow({required this.update, required this.last, this.projectTitle});

  final ProjectUpdate update;
  final String? projectTitle;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(gradient: p.gradient, shape: BoxShape.circle),
              ),
              if (!last) Expanded(child: Container(width: 2, color: p.brand.withValues(alpha: 0.15))),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text([timeAgo(update.createdAt), ?projectTitle].join(' · '), style: context.text.bodySmall),
                  const SizedBox(height: 2),
                  Text(update.title, style: context.text.labelLarge),
                  if (update.body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(update.body, maxLines: 3, overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(height: 1.4)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: context.palette.mutedForeground),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: context.text.bodySmall)),
          ],
        ),
      );
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
