import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/config/app_config.dart';
import '../../core/data_providers.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/learning.dart';
import '../shell/app_shell.dart';
import '../shell/workspace.dart';

String certificateLink(String number) => '${AppConfig.siteUrl}/certificates?number=${Uri.encodeComponent(number)}';

/// Totals across a learner's enrollments.
class LearningTotals {
  LearningTotals(List<Enrollment> enrollments)
      : courses = enrollments.length,
        completed = enrollments.where((e) => e.isCompleted).length,
        lessonsDone = enrollments.fold(0, (n, e) => n + e.learning.completedLessons),
        lessonsTotal = enrollments.fold(0, (n, e) => n + e.learning.totalLessons),
        certificates = enrollments.where((e) => e.certificateNumber != null).length,
        average = enrollments.isEmpty
            ? 0
            : (enrollments.fold(0, (n, e) => n + e.progress) / enrollments.length).round();

  final int courses;
  final int completed;
  final int lessonsDone;
  final int lessonsTotal;
  final int certificates;
  final int average;
}

class LearnerDashboardScreen extends ConsumerWidget {
  const LearnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).value?.user;
    return Scaffold(
      appBar: const WorkspaceAppBar(workspace: Workspace.learner),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(enrollmentsProvider.future),
        child: ListView(
          padding: pagePadding,
          children: [
            PageHeader(
              eyebrow: 'My learning',
              title: 'Welcome back, ${user?.firstName ?? ''}.',
              intro: 'Pick up where you left off and keep track of your progress.',
            ),
            const SizedBox(height: 20),
            AsyncBody(
              provider: enrollmentsProvider,
              loadingLabel: 'Loading your dashboard…',
              builder: (enrollments) {
                final totals = LearningTotals(enrollments);
                final active = enrollments.where((e) => e.isActive).toList()
                  ..sort((a, b) {
                    final at = a.learning.lastActivityAt ?? a.createdAt ?? DateTime(2000);
                    final bt = b.learning.lastActivityAt ?? b.createdAt ?? DateTime(2000);
                    return bt.compareTo(at);
                  });
                final incomplete = (user?.profile.firstName.isEmpty ?? true) || (user?.profile.lastName.isEmpty ?? true);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StatGrid(children: [
                      StatTile(
                        icon: LucideIcons.bookOpen,
                        label: 'Courses',
                        value: '${totals.courses}',
                        detail: '${totals.completed} completed',
                        onTap: () => context.go('/learn/courses'),
                      ),
                      StatTile(
                        icon: LucideIcons.circleCheck,
                        label: 'Lessons completed',
                        value: '${totals.lessonsDone}',
                        detail: totals.lessonsTotal > 0 ? 'of ${totals.lessonsTotal} lessons' : null,
                      ),
                      StatTile(icon: LucideIcons.gauge, label: 'Average progress', value: '${totals.average}%'),
                      StatTile(
                        icon: LucideIcons.award,
                        label: 'Certificates',
                        value: '${totals.certificates}',
                        detail: 'View certificates',
                        onTap: () => context.go('/learn/certificates'),
                      ),
                    ]),
                    if (incomplete) ...[
                      const SizedBox(height: 12),
                      AppCard(
                        onTap: () => context.go('/profile/edit'),
                        highlight: context.palette.brand.withValues(alpha: 0.5),
                        child: Row(
                          children: [
                            Icon(LucideIcons.userPen, color: context.palette.brand),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text("Add your full name to your profile. It's the name printed on your certificates."),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SectionTitle(
                      'Continue learning',
                      action: enrollments.isEmpty ? null : 'All courses',
                      onAction: () => context.go('/learn/courses'),
                    ),
                    if (enrollments.isEmpty)
                      EmptyState(
                        icon: LucideIcons.bookOpen,
                        title: "You haven't enrolled in a course yet.",
                        action: GradientButton(
                          label: 'Browse courses',
                          expand: false,
                          onPressed: () => context.go('/courses'),
                        ),
                      )
                    else if (active.isEmpty)
                      EmptyState(
                        icon: LucideIcons.award,
                        title: "You've finished all your courses.",
                        message: 'Your certificates are ready to view and share.',
                        action: GradientButton(
                          label: 'View certificates',
                          expand: false,
                          onPressed: () => context.go('/learn/certificates'),
                        ),
                      )
                    else
                      for (final e in active) ...[ContinueCard(enrollment: e), const SizedBox(height: 12)],
                    const SizedBox(height: 8),
                    SecondaryButton(
                      label: 'Browse more courses',
                      icon: LucideIcons.graduationCap,
                      onPressed: () => context.go('/courses'),
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

class ContinueCard extends StatelessWidget {
  const ContinueCard({super.key, required this.enrollment});
  final Enrollment enrollment;

  @override
  Widget build(BuildContext context) {
    final e = enrollment;
    final l = e.learning;
    final next = l.nextLessonId;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(e.course.title, style: context.text.titleMedium),
          const SizedBox(height: 4),
          Text(
            e.cohort != null
                ? '${e.cohort!.name} · starts ${formatDate(e.cohort!.startDate)}'
                : 'Cohort dates will be emailed to you before the course starts.',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 14),
          ProgressLine(
            value: e.progress,
            label: l.totalLessons > 0 ? '${l.completedLessons} of ${l.totalLessons} lessons' : 'Course progress',
          ),
          const SizedBox(height: 12),
          if (l.nextLessonTitle != null)
            Text.rich(TextSpan(children: [
              TextSpan(text: 'Next up: ', style: context.text.bodySmall),
              TextSpan(text: l.nextLessonTitle, style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ]))
          else
            Text(
              l.totalLessons > 0
                  ? 'All lessons done. Your facilitator will issue your certificate.'
                  : 'Lessons will appear when the course opens.',
              style: context.text.bodySmall,
            ),
          if (l.lastActivityAt != null) ...[
            const SizedBox(height: 2),
            Text('Last active ${timeAgo(l.lastActivityAt)}', style: context.text.bodySmall),
          ],
          const SizedBox(height: 14),
          GradientButton(
            label: next == null && l.totalLessons > 0
                ? 'Review course'
                : (l.completedLessons > 0 ? 'Continue' : 'Start course'),
            icon: LucideIcons.circlePlay,
            expand: false,
            onPressed: () => context.go(next != null
                ? '/learn/course/${e.course.slug}/lesson/$next'
                : '/learn/course/${e.course.slug}'),
          ),
        ],
      ),
    );
  }
}

class MyCoursesScreen extends ConsumerWidget {
  const MyCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: const WorkspaceAppBar(workspace: Workspace.learner),
        body: RefreshIndicator(
          onRefresh: () => ref.refresh(enrollmentsProvider.future),
          child: ListView(
            padding: pagePadding,
            children: [
              const PageHeader(
                eyebrow: 'My learning',
                title: 'My courses',
                intro: 'Every course you are enrolled in, with your progress and materials.',
              ),
              const SizedBox(height: 20),
              AsyncBody(
                provider: enrollmentsProvider,
                loadingLabel: 'Loading your courses…',
                builder: (enrollments) => enrollments.isEmpty
                    ? EmptyState(
                        icon: LucideIcons.bookOpen,
                        title: "You haven't enrolled in a course yet.",
                        action: GradientButton(
                          label: 'Browse courses',
                          expand: false,
                          onPressed: () => context.go('/courses'),
                        ),
                      )
                    : Column(
                        children: [
                          for (final e in enrollments) ...[_EnrollmentCard(enrollment: e), const SizedBox(height: 12)],
                          TextButton.icon(
                            onPressed: () => context.go('/learn/orders'),
                            icon: const Icon(LucideIcons.receipt, size: 16),
                            label: const Text('Orders and payments'),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      );
}

class _EnrollmentCard extends StatelessWidget {
  const _EnrollmentCard({required this.enrollment});
  final Enrollment enrollment;

  @override
  Widget build(BuildContext context) {
    final e = enrollment;
    final p = context.palette;
    return AppCard(
      onTap: () => context.go('/learn/course/${e.course.slug}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(e.course.title, style: context.text.titleMedium)),
              const SizedBox(width: 8),
              Pill(e.statusDisplay, tone: e.isCompleted ? PillTone.success : PillTone.neutral),
            ],
          ),
          const SizedBox(height: 12),
          ProgressLine(value: e.progress, label: 'Course progress'),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat('${e.learning.completedLessons}/${e.learning.totalLessons}', 'Lessons'),
              const SizedBox(width: 8),
              _MiniStat('${e.learning.assignmentsSubmitted}/${e.learning.assignmentsTotal}', 'Assignments'),
            ],
          ),
          if (e.resources.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Resources', style: context.text.labelLarge),
            for (final r in e.resources)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(LucideIcons.fileText, size: 18, color: p.brand),
                title: Text(r.title),
                trailing: const Icon(LucideIcons.externalLink, size: 14),
                onTap: () => openLink(context, r.url),
              ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text(e.progress > 0 ? 'Continue course' : 'Open course',
                  style: context.text.labelLarge?.copyWith(color: p.brand)),
              const SizedBox(width: 4),
              Icon(LucideIcons.arrowRight, size: 16, color: p.brand),
              const Spacer(),
              if (e.certificateNumber != null)
                TextButton.icon(
                  onPressed: () => openLink(context, certificateLink(e.certificateNumber!)),
                  icon: const Icon(LucideIcons.award, size: 16),
                  label: const Text('Certificate'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: context.palette.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(value, style: context.text.titleMedium),
              Text(label, style: context.text.bodySmall),
            ],
          ),
        ),
      );
}

class CertificatesScreen extends ConsumerWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: const WorkspaceAppBar(workspace: Workspace.learner),
        body: RefreshIndicator(
          onRefresh: () => ref.refresh(enrollmentsProvider.future),
          child: ListView(
            padding: pagePadding,
            children: [
              const PageHeader(
                eyebrow: 'My learning',
                title: 'Certificates',
                intro: "Certificates of completion you've earned. Anyone can verify them with the link.",
              ),
              const SizedBox(height: 20),
              AsyncBody(
                provider: enrollmentsProvider,
                loadingLabel: 'Loading your certificates…',
                builder: (enrollments) {
                  final earned = enrollments.where((e) => e.certificateNumber != null).toList();
                  final pending = enrollments.where((e) => e.certificateNumber == null).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (earned.isEmpty)
                        const EmptyState(
                          icon: LucideIcons.award,
                          title: 'No certificates yet.',
                          message: 'Finish a course and your facilitator will issue your certificate here.',
                        )
                      else
                        for (final e in earned) ...[_CertificateCard(enrollment: e), const SizedBox(height: 12)],
                      if (pending.isNotEmpty) ...[
                        const SectionTitle('Still to earn'),
                        for (final e in pending) ...[
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.course.title, style: context.text.titleMedium),
                                const SizedBox(height: 10),
                                ProgressLine(
                                  value: e.progress,
                                  label: '${e.learning.completedLessons} of ${e.learning.totalLessons} lessons',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
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

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.enrollment});
  final Enrollment enrollment;

  @override
  Widget build(BuildContext context) {
    final number = enrollment.certificateNumber!;
    final p = context.palette;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(gradient: p.gradient, shape: BoxShape.circle),
            child: const Icon(LucideIcons.award, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(enrollment.course.title, style: context.text.titleMedium),
          const SizedBox(height: 2),
          SelectableText(number, style: context.text.bodySmall?.copyWith(fontFamily: 'monospace')),
          if (enrollment.certificateIssuedAt != null)
            Text('Issued ${formatDate(enrollment.certificateIssuedAt)}', style: context.text.bodySmall),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  label: 'View & print',
                  icon: LucideIcons.externalLink,
                  onPressed: () => openLink(context, certificateLink(number)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SecondaryButton(
                  label: 'Copy link',
                  icon: LucideIcons.link,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: certificateLink(number)));
                    if (context.mounted) showMessage(context, 'Verification link copied.');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Orders')),
        body: RefreshIndicator(
          onRefresh: () => ref.refresh(ordersProvider.future),
          child: ListView(
            padding: pagePadding,
            children: [
              AsyncBody(
                provider: ordersProvider,
                loadingLabel: 'Loading your orders…',
                builder: (orders) => orders.isEmpty
                    ? const EmptyState(icon: LucideIcons.receipt, title: 'No orders yet.')
                    : Column(
                        children: [
                          for (final o in orders) ...[
                            AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(o.courses.join(', '), style: context.text.titleMedium),
                                      ),
                                      Pill(
                                        o.statusDisplay,
                                        tone: switch (o.status) {
                                          'paid' => PillTone.success,
                                          'pending' => PillTone.warning,
                                          'failed' || 'cancelled' => PillTone.danger,
                                          _ => PillTone.neutral,
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text('${formatMoney(o.total, o.currency)} · ${formatDate(o.createdAt)}'),
                                  SelectableText(o.reference, style: context.text.bodySmall),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      );
}
