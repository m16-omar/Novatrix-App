import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/config/app_config.dart';
import '../../core/data_providers.dart';
import '../../core/format.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/facilitator.dart';
import '../../data/models/learning.dart';
import '../shell/app_shell.dart';
import '../shell/workspace.dart';

class TeachingDashboardScreen extends ConsumerWidget {
  const TeachingDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).value?.user;
    return Scaffold(
      appBar: const WorkspaceAppBar(workspace: Workspace.facilitator),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(sessionProvider.notifier).refreshRoles();
          return ref.refresh(teachingCoursesProvider.future);
        },
        child: ListView(
          padding: pagePadding,
          children: [
            PageHeader(
              eyebrow: 'Teaching dashboard',
              title: 'Welcome, ${user?.firstName ?? ''}.',
              intro: 'Follow your learners and review their work.',
            ),
            const SizedBox(height: 20),
            AsyncBody(
              provider: teachingCoursesProvider,
              loadingLabel: 'Loading your courses…',
              builder: (courses) {
                if (courses.isEmpty) {
                  return const EmptyState(
                    icon: LucideIcons.bookOpen,
                    title: "You're not assigned to any courses yet.",
                    message: 'A Novatrix administrator adds facilitators to courses. '
                        'Contact ${AppConfig.supportEmail} if you should have access.',
                  );
                }
                final pending = courses.fold(0, (n, c) => n + c.pendingReviews);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StatGrid(children: [
                      StatTile(icon: LucideIcons.presentation, label: 'Courses', value: '${courses.length}'),
                      StatTile(
                        icon: LucideIcons.users,
                        label: 'Learners',
                        value: '${courses.fold(0, (n, c) => n + c.learnerCount)}',
                        onTap: () => context.go('/teach/learners'),
                      ),
                      StatTile(
                        icon: LucideIcons.bookOpen,
                        label: 'Lessons',
                        value: '${courses.fold(0, (n, c) => n + c.lessonCount)}',
                      ),
                      StatTile(
                        icon: LucideIcons.clipboardCheck,
                        label: 'Awaiting review',
                        value: '$pending',
                        highlight: pending > 0,
                        detail: 'Open review queue',
                        onTap: () => context.go('/teach/reviews'),
                      ),
                    ]),
                    const SectionTitle('Your courses'),
                    for (final c in courses) ...[_TeachingCourseCard(course: c), const SizedBox(height: 12)],
                    const SizedBox(height: 4),
                    Text(
                      'Build lessons and post announcements from the facilitator workspace on thenovatrix.com.',
                      style: context.text.bodySmall,
                    ),
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

class _TeachingCourseCard extends StatelessWidget {
  const _TeachingCourseCard({required this.course});
  final TeachingCourse course;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget stat(IconData icon, int value, String label, {bool warn = false}) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: warn ? p.warning.withValues(alpha: 0.6) : p.border),
            ),
            child: Column(
              children: [
                Icon(icon, size: 16, color: p.brand),
                const SizedBox(height: 2),
                Text('$value', style: context.text.titleMedium),
                Text(label, style: context.text.bodySmall),
              ],
            ),
          ),
        );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(course.course.title, style: context.text.titleMedium),
          if (course.course.summary.isNotEmpty)
            Text(course.course.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
          const SizedBox(height: 12),
          Row(
            children: [
              stat(LucideIcons.users, course.learnerCount, 'Learners'),
              const SizedBox(width: 8),
              stat(LucideIcons.bookOpen, course.lessonCount, 'Lessons'),
              const SizedBox(width: 8),
              stat(LucideIcons.clipboardCheck, course.pendingReviews, 'To review', warn: course.pendingReviews > 0),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => context.go('/learn/course/${course.course.slug}'),
                icon: const Icon(LucideIcons.eye, size: 16),
                label: const Text('View as learner'),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => openLink(context, '${AppConfig.siteUrl}/facilitator/${course.course.slug}'),
                icon: const Icon(LucideIcons.externalLink, size: 16),
                label: const Text('Edit content'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ---------- reviews ---------- */

class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key});

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  SubmissionStatus? _status = SubmissionStatus.submitted;
  String? _course;

  @override
  Widget build(BuildContext context) {
    final provider = reviewsProvider(_status);
    return Scaffold(
      appBar: const WorkspaceAppBar(workspace: Workspace.facilitator),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(provider.future),
        child: ListView(
          padding: pagePadding,
          children: [
            const PageHeader(
              eyebrow: 'Teaching',
              title: 'Reviews',
              intro: 'Assignment submissions from learners on all your courses.',
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (value, label) in [
                    (SubmissionStatus.submitted, 'Awaiting review'),
                    (SubmissionStatus.needsRevision, 'Needs revision'),
                    (SubmissionStatus.reviewed, 'Reviewed'),
                    (null, 'All'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: _status == value,
                        onSelected: (_) => setState(() => _status = value),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AsyncBody(
              provider: provider,
              loadingLabel: 'Loading submissions…',
              builder: (items) {
                final courses = {for (final i in items) i.course.slug: i.course.title};
                final shown = items.where((i) => _course == null || i.course.slug == _course).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (courses.length > 1) ...[
                      DropdownButtonFormField<String?>(
                        initialValue: _course,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Course'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All courses')),
                          for (final e in courses.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
                        ],
                        onChanged: (v) => setState(() => _course = v),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (shown.isEmpty)
                      EmptyState(
                        icon: LucideIcons.clipboardCheck,
                        title: _status == SubmissionStatus.submitted ? "You're all caught up." : 'No submissions here.',
                        message: _status == SubmissionStatus.submitted
                            ? 'New assignment submissions will appear here.'
                            : null,
                      )
                    else
                      for (final item in shown) ...[
                        ReviewCard(
                          key: ValueKey(item.submission.id),
                          item: item,
                          onReviewed: () {
                            ref.invalidate(reviewsProvider);
                            ref.invalidate(teachingCoursesProvider);
                            ref.read(sessionProvider.notifier).refreshRoles();
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
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

class ReviewCard extends ConsumerStatefulWidget {
  const ReviewCard({super.key, required this.item, required this.onReviewed});

  final ReviewItem item;
  final VoidCallback onReviewed;

  @override
  ConsumerState<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<ReviewCard> {
  late final _feedback = TextEditingController(text: widget.item.submission.feedback);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  Future<void> _review(SubmissionStatus status) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(teachingRepositoryProvider).review(widget.item.submission.id, status, _feedback.text);
      if (mounted) {
        showMessage(context, 'Review saved. ${widget.item.learnerName} has been emailed.');
      }
      widget.onReviewed();
    } on ApiException catch (e) {
      setState(() => _error = e.firstError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final s = item.submission;
    final p = context.palette;
    return AppCard(
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
                    Text(item.learnerName, style: context.text.titleMedium),
                    Text('${item.course.title} · ${item.lessonTitle}', style: context.text.bodySmall),
                    Text('Submitted ${timeAgo(s.updatedAt)}', style: context.text.bodySmall),
                  ],
                ),
              ),
              Pill(s.status.label, tone: s.status == SubmissionStatus.reviewed ? PillTone.success : PillTone.neutral),
            ],
          ),
          if (s.linkUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => openLink(context, s.linkUrl),
              child: Row(
                children: [
                  Icon(LucideIcons.link, size: 14, color: p.brand),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(s.linkUrl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.brand, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ),
          ],
          if (s.notes.isNotEmpty) ...[const SizedBox(height: 8), Text(s.notes)],
          const SizedBox(height: 14),
          if (_error != null) ...[ErrorNote(_error!), const SizedBox(height: 10)],
          TextField(
            controller: _feedback,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Feedback for the learner', alignLabelWithHint: true),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  label: 'Mark reviewed',
                  busy: _busy,
                  onPressed: () => _review(SubmissionStatus.reviewed),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SecondaryButton(
                  label: 'Request revision',
                  onPressed: _busy ? null : () => _review(SubmissionStatus.needsRevision),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('The learner is emailed your feedback.', style: context.text.bodySmall),
        ],
      ),
    );
  }
}

/* ---------- learners ---------- */

class LearnersScreen extends ConsumerStatefulWidget {
  const LearnersScreen({super.key});

  @override
  ConsumerState<LearnersScreen> createState() => _LearnersScreenState();
}

class _LearnersScreenState extends ConsumerState<LearnersScreen> {
  String _query = '';
  String? _course;

  Future<void> _issue(CourseLearner learner) async {
    final warning = learner.progress < 100 ? ' They have completed ${learner.progress}% of the course.' : '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Issue certificate?'),
        content: Text('Issue a certificate of completion to ${learner.name} for ${learner.course.title}?$warning'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Issue certificate')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final number = await ref.read(teachingRepositoryProvider).issueCertificate(learner.enrollmentId);
      ref.invalidate(learnersProvider);
      if (mounted) showMessage(context, 'Certificate $number issued. ${learner.name} has been emailed.');
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WorkspaceAppBar(workspace: Workspace.facilitator),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(learnersProvider.future),
        child: ListView(
          padding: pagePadding,
          children: [
            const PageHeader(
              eyebrow: 'Teaching',
              title: 'Learners',
              intro: 'Everyone enrolled on your courses, with their progress.',
            ),
            const SizedBox(height: 16),
            AsyncBody(
              provider: learnersProvider,
              loadingLabel: 'Loading learners…',
              builder: (learners) {
                if (learners.isEmpty) {
                  return const EmptyState(
                    icon: LucideIcons.users,
                    title: 'No learners yet.',
                    message: 'Learners appear here once they enrol on a course you teach.',
                  );
                }
                final courses = {for (final l in learners) l.course.slug: l.course.title};
                final shown = learners
                    .where((l) => _course == null || l.course.slug == _course)
                    .where((l) => _query.isEmpty ||
                        l.name.toLowerCase().contains(_query) ||
                        l.email.toLowerCase().contains(_query))
                    .toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                      decoration: const InputDecoration(
                        hintText: 'Search by name or email',
                        prefixIcon: Icon(LucideIcons.search, size: 18),
                      ),
                    ),
                    if (courses.length > 1) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        initialValue: _course,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Course'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All courses')),
                          for (final e in courses.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
                        ],
                        onChanged: (v) => setState(() => _course = v),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Semantics(
                      liveRegion: true,
                      child: Text('${shown.length} of ${learners.length} learners', style: context.text.bodySmall),
                    ),
                    const SizedBox(height: 10),
                    for (final l in shown) ...[
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.name, style: context.text.titleMedium),
                            InkWell(
                              onTap: () => openLink(context, 'mailto:${l.email}'),
                              child: Text(l.email, style: context.text.bodySmall),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [l.course.title, if (l.cohort != null) l.cohort!].join(' · '),
                              style: context.text.bodySmall,
                            ),
                            const SizedBox(height: 10),
                            ProgressLine(
                              value: l.progress,
                              label: '${plural(l.completedLessons, 'lesson')} · ${plural(l.submissions, 'submission')}',
                            ),
                            const SizedBox(height: 8),
                            if (l.certificateNumber != null)
                              Row(
                                children: [
                                  Icon(LucideIcons.award, size: 16, color: context.palette.success),
                                  const SizedBox(width: 6),
                                  Text(l.certificateNumber!, style: context.text.bodySmall),
                                ],
                              )
                            else
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () => _issue(l),
                                  icon: const Icon(LucideIcons.award, size: 16),
                                  label: const Text('Issue certificate'),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
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
