import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
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
import '../../data/models/learning.dart';
import 'learner_screens.dart' show certificateLink;

IconData lessonIcon(LessonKind kind) => switch (kind) {
      LessonKind.video => LucideIcons.video,
      LessonKind.assignment => LucideIcons.clipboardCheck,
      LessonKind.live => LucideIcons.presentation,
      LessonKind.reading => LucideIcons.fileText,
    };

class CourseOutlineScreen extends ConsumerWidget {
  const CourseOutlineScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(learnCourseProvider(slug).future),
        child: ListView(
          padding: pagePadding,
          children: [
            AsyncBody(
              provider: learnCourseProvider(slug),
              loadingLabel: 'Loading course…',
              builder: (course) => _Outline(slug: slug, course: course),
            ),
          ],
        ),
      ),
    );
  }
}

class _Outline extends StatelessWidget {
  const _Outline({required this.slug, required this.course});

  final String slug;
  final LearnCourse course;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final lessons = course.lessons;
    final done = lessons.where((l) => l.completed).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          eyebrow: course.isFacilitatorPreview ? 'Facilitator preview' : 'My course',
          title: course.course.title,
          intro: course.cohort != null
              ? '${course.cohort!.name} · ${formatDate(course.cohort!.startDate)} – ${formatDate(course.cohort!.endDate)}'
              : null,
        ),
        const SizedBox(height: 16),
        if (course.isFacilitatorPreview)
          const ErrorNote(
            "You're viewing this course as its facilitator. Progress isn't tracked.",
            title: 'Preview',
          )
        else
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProgressLine(value: course.progress, label: '$done of ${lessons.length} lessons'),
                if (course.certificateNumber != null) ...[
                  const SizedBox(height: 12),
                  GradientButton(
                    label: 'View certificate',
                    icon: LucideIcons.award,
                    onPressed: () => openLink(context, certificateLink(course.certificateNumber!)),
                  ),
                ] else if (lessons.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GradientButton(
                    label: done == 0 ? 'Start course' : 'Continue',
                    icon: LucideIcons.circlePlay,
                    onPressed: () {
                      final next = lessons.firstWhere((l) => !l.completed, orElse: () => lessons.first);
                      context.go('/learn/course/$slug/lesson/${next.id}');
                    },
                  ),
                ],
              ],
            ),
          ),
        if (course.announcements.isNotEmpty) ...[
          const SectionTitle('Announcements'),
          for (final a in course.announcements.take(3)) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.megaphone, size: 16, color: p.brand),
                      const SizedBox(width: 8),
                      Expanded(child: Text(a.title, style: context.text.titleMedium)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${a.authorName} · ${timeAgo(a.createdAt)}', style: context.text.bodySmall),
                  const SizedBox(height: 8),
                  Text(a.body),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
        if (course.resources.isNotEmpty) ...[
          const SectionTitle('Resources'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final r in course.resources)
                  ListTile(
                    leading: const Icon(LucideIcons.fileText),
                    title: Text(r.title),
                    trailing: const Icon(LucideIcons.externalLink, size: 16),
                    onTap: () => openLink(context, r.url),
                  ),
              ],
            ),
          ),
        ],
        const SectionTitle('Lessons'),
        if (course.modules.isEmpty)
          const EmptyState(
            icon: LucideIcons.bookOpen,
            title: 'Lessons are on their way.',
            message: 'Your facilitator is preparing the course. Check back soon.',
          ),
        for (final m in course.modules) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.title, style: context.text.titleMedium),
                if (m.summary.isNotEmpty) Text(m.summary, style: context.text.bodySmall),
              ],
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, l) in m.lessons.indexed) ...[
                  if (i > 0) const Divider(),
                  ListTile(
                    leading: l.completed
                        ? Icon(LucideIcons.circleCheck, color: p.success)
                        : Icon(lessonIcon(l.kind), color: p.mutedForeground),
                    title: Text(l.title),
                    subtitle: Text([
                      l.kind.label,
                      if (l.durationMinutes > 0) '${l.durationMinutes} min',
                      if (l.submissionStatus != null) l.submissionStatus!.label,
                    ].join(' · ')),
                    trailing: const Icon(LucideIcons.chevronRight, size: 18),
                    onTap: () => context.go('/learn/course/$slug/lesson/${l.id}'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class LessonScreen extends ConsumerWidget {
  const LessonScreen({super.key, required this.slug, required this.lessonId});

  final String slug;
  final int lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (slug, lessonId);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/learn/course/$slug')),
        title: Text(ref.watch(lessonProvider(key)).value?.moduleTitle ?? 'Lesson'),
      ),
      body: AsyncBody(
        provider: lessonProvider(key),
        loadingLabel: 'Loading lesson…',
        builder: (lesson) => _LessonBody(slug: slug, lesson: lesson),
      ),
    );
  }
}

class _LessonBody extends ConsumerStatefulWidget {
  const _LessonBody({required this.slug, required this.lesson});

  final String slug;
  final LessonDetail lesson;

  @override
  ConsumerState<_LessonBody> createState() => _LessonBodyState();
}

class _LessonBodyState extends ConsumerState<_LessonBody> {
  bool _busy = false;

  void _refreshCourse() {
    ref.invalidate(learnCourseProvider(widget.slug));
    ref.invalidate(enrollmentsProvider);
    ref.invalidate(lessonProvider((widget.slug, widget.lesson.id)));
  }

  Future<void> _toggleComplete() async {
    setState(() => _busy = true);
    try {
      await ref.read(learningRepositoryProvider).setComplete(widget.slug, widget.lesson.id, !widget.lesson.completed);
      _refreshCourse();
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final p = context.palette;
    return ListView(
      padding: pagePadding,
      children: [
        Wrap(
          spacing: 8,
          children: [
            Pill(lesson.kind.label),
            if (lesson.durationMinutes > 0) Pill('${lesson.durationMinutes} min'),
            if (lesson.completed) const Pill('Completed', tone: PillTone.success),
          ],
        ),
        const SizedBox(height: 10),
        Text(lesson.title, style: context.text.headlineSmall),
        const SizedBox(height: 16),
        if (lesson.videoUrl.isNotEmpty) ...[
          AppCard(
            onTap: () => openLink(context, lesson.videoUrl),
            padding: EdgeInsets.zero,
            child: Container(
              height: 180,
              decoration: BoxDecoration(gradient: p.gradient),
              alignment: Alignment.center,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.circlePlay, color: Colors.white, size: 56),
                  SizedBox(height: 8),
                  Text('Watch the video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (lesson.content.isNotEmpty)
          MarkdownBody(
            data: lesson.content,
            selectable: true,
            onTapLink: (_, href, _) {
              if (href != null) openLink(context, href);
            },
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: context.text.bodyLarge?.copyWith(height: 1.55),
              a: TextStyle(color: p.brand, decoration: TextDecoration.underline),
              code: context.text.bodyMedium?.copyWith(fontFamily: 'monospace', backgroundColor: p.muted),
              codeblockDecoration: BoxDecoration(color: p.muted, borderRadius: BorderRadius.circular(12)),
              blockquoteDecoration: BoxDecoration(
                border: Border(left: BorderSide(color: p.brand, width: 3)),
                color: p.muted.withValues(alpha: 0.5),
              ),
            ),
          ),
        if (lesson.resourceUrl.isNotEmpty) ...[
          const SizedBox(height: 16),
          SecondaryButton(
            label: lesson.kind == LessonKind.live ? 'Join the session' : 'Open resource',
            icon: LucideIcons.externalLink,
            onPressed: () => openLink(context, lesson.resourceUrl),
          ),
        ],
        if (lesson.kind == LessonKind.assignment) ...[
          const SectionTitle('Your submission'),
          _AssignmentPanel(slug: widget.slug, lesson: lesson, onSubmitted: _refreshCourse),
        ] else if (lesson.canTrack) ...[
          const SizedBox(height: 24),
          lesson.completed
              ? SecondaryButton(
                  label: 'Mark as not done',
                  icon: LucideIcons.refreshCw,
                  onPressed: _busy ? null : _toggleComplete,
                )
              : GradientButton(
                  label: 'Mark as complete',
                  icon: LucideIcons.circleCheck,
                  busy: _busy,
                  onPressed: _toggleComplete,
                ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            if (lesson.previousId != null)
              Expanded(
                child: SecondaryButton(
                  label: 'Previous',
                  icon: LucideIcons.arrowLeft,
                  onPressed: () => context.go('/learn/course/${widget.slug}/lesson/${lesson.previousId}'),
                ),
              ),
            if (lesson.previousId != null && lesson.nextId != null) const SizedBox(width: 10),
            if (lesson.nextId != null)
              Expanded(
                child: GradientButton(
                  label: 'Next lesson',
                  icon: LucideIcons.arrowRight,
                  onPressed: () => context.go('/learn/course/${widget.slug}/lesson/${lesson.nextId}'),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AssignmentPanel extends ConsumerStatefulWidget {
  const _AssignmentPanel({required this.slug, required this.lesson, required this.onSubmitted});

  final String slug;
  final LessonDetail lesson;
  final VoidCallback onSubmitted;

  @override
  ConsumerState<_AssignmentPanel> createState() => _AssignmentPanelState();
}

class _AssignmentPanelState extends ConsumerState<_AssignmentPanel> {
  final _form = GlobalKey<FormState>();
  late final _link = TextEditingController(text: widget.lesson.submission?.linkUrl ?? '');
  late final _notes = TextEditingController(text: widget.lesson.submission?.notes ?? '');
  late bool _editing = widget.lesson.submission == null;
  bool _busy = false;
  ApiException? _error;

  @override
  void didUpdateWidget(covariant _AssignmentPanel old) {
    super.didUpdateWidget(old);
    // A fresh submission came back from the server: show it instead of the form.
    if (widget.lesson.submission?.updatedAt != old.lesson.submission?.updatedAt) _editing = false;
  }

  @override
  void dispose() {
    _link.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(learningRepositoryProvider).submit(widget.slug, widget.lesson.id, link: _link.text, notes: _notes.text);
      widget.onSubmitted();
      if (mounted) showMessage(context, 'Submitted. Your facilitator has been notified.');
    } on ApiException catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final submission = widget.lesson.submission;
    final p = context.palette;
    if (!widget.lesson.canTrack) {
      return Text('Enrolled learners submit their work here.', style: context.text.bodySmall);
    }
    if (submission != null && !_editing) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Pill(
                  submission.status.label,
                  tone: switch (submission.status) {
                    SubmissionStatus.reviewed => PillTone.success,
                    SubmissionStatus.needsRevision => PillTone.warning,
                    SubmissionStatus.submitted => PillTone.neutral,
                  },
                ),
                const Spacer(),
                Text(formatDate(submission.updatedAt), style: context.text.bodySmall),
              ],
            ),
            if (submission.linkUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () => openLink(context, submission.linkUrl),
                child: Text(submission.linkUrl,
                    style: TextStyle(color: p.brand, decoration: TextDecoration.underline)),
              ),
            ],
            if (submission.notes.isNotEmpty) ...[const SizedBox(height: 8), Text(submission.notes)],
            if (submission.feedback.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.muted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(left: BorderSide(color: p.brand, width: 3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Feedback from your facilitator', style: context.text.labelLarge),
                    const SizedBox(height: 4),
                    Text(submission.feedback),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            SecondaryButton(
              label: submission.status == SubmissionStatus.needsRevision ? 'Submit a revision' : 'Update submission',
              icon: LucideIcons.refreshCw,
              onPressed: () => setState(() => _editing = true),
            ),
          ],
        ),
      );
    }
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[ErrorNote(_error!.firstError), const SizedBox(height: 12)],
          LabeledField(
            label: 'Link to your work',
            controller: _link,
            optional: true,
            keyboardType: TextInputType.url,
            helper: 'A repository, document, or dashboard link.',
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.isEmpty) return null;
              final uri = Uri.tryParse(t);
              return uri != null && uri.hasScheme && uri.host.isNotEmpty
                  ? null
                  : 'Enter a full link, starting with https://';
            },
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Notes for your facilitator',
            controller: _notes,
            optional: true,
            maxLines: 4,
            validator: (v) => (v?.trim().isEmpty ?? true) && _link.text.trim().isEmpty
                ? 'Add a link to your work or a note.'
                : null,
          ),
          const SizedBox(height: 16),
          GradientButton(label: 'Submit assignment', icon: LucideIcons.send, busy: _busy, onPressed: _submit),
          if (submission != null)
            TextButton(onPressed: () => setState(() => _editing = false), child: const Text('Cancel')),
        ],
      ),
    );
  }
}
