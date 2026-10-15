import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data_providers.dart';
import '../../core/format.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/assessment.dart';

String _kindLabel(bool exam) => exam ? 'Final exam' : 'Module quiz';

void _refreshCourse(WidgetRef ref, String slug, int assessmentId) {
  ref.invalidate(learnCourseProvider(slug));
  ref.invalidate(assessmentProvider((slug, assessmentId)));
  ref.invalidate(enrollmentsProvider);
}

/* ---------- introduction ---------- */

/// A quiz or exam before starting: the rules, where you stand, and past attempts.
class AssessmentScreen extends ConsumerWidget {
  const AssessmentScreen({super.key, required this.slug, required this.assessmentId});

  final String slug;
  final int assessmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (slug, assessmentId);
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.go('/learn/course/$slug'))),
      body: AsyncBody(
        provider: assessmentProvider(key),
        loadingLabel: 'Loading…',
        builder: (detail) => _Intro(slug: slug, detail: detail),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.slug, required this.detail});

  final String slug;
  final AssessmentDetail detail;

  Future<void> _start(BuildContext context) async {
    final a = detail.summary;
    if (a.isExam && a.openAttemptId == null) {
      final go = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Start the final exam?'),
          content: Text([
            if (a.timeLimitMinutes != null) 'You have ${a.timeLimitMinutes} minutes once you start, and the timer keeps running if you leave.',
            if (a.attemptsLeft != null) 'This uses 1 of your ${a.attemptsLeft} remaining attempts.',
            'You need ${a.passMark}% to pass.',
          ].join(' ')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Not yet')),
            FilledButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Start exam')),
          ],
        ),
      );
      if (go != true) return;
    }
    if (context.mounted) context.push('/learn/course/$slug/assessment/${a.id}/take');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final a = detail.summary;
    final String buttonLabel;
    if (a.openAttemptId != null) {
      buttonLabel = a.isExam ? 'Resume exam' : 'Resume quiz';
    } else if (a.attemptsUsed > 0) {
      buttonLabel = 'Try again';
    } else {
      buttonLabel = a.isExam ? 'Start exam' : 'Start quiz';
    }
    final String? blocked = a.canStart
        ? null
        : a.isExam && a.passed
            ? "You've passed the final exam."
            : a.attemptsLeft == 0
                ? "You've used all ${a.maxAttempts} attempts. Contact your facilitator if you need another."
                : 'Questions are on their way. Check back soon.';

    return ListView(
      padding: pagePadding,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: p.gradient, borderRadius: BorderRadius.circular(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(a.isExam ? LucideIcons.graduationCap : LucideIcons.listChecks, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(_kindLabel(a.isExam).toUpperCase(),
                      style: context.text.labelSmall?.copyWith(
                          color: Colors.white, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              Text(a.title, style: context.text.headlineSmall?.copyWith(color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                a.isExam
                    ? 'Passing the final exam is required for your certificate.'
                    : 'Practice for this module: retake it as often as you like, and see why each answer is right.',
                style: context.text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _Fact(icon: LucideIcons.listOrdered, value: '${a.questionCount}', label: 'Questions'),
            const SizedBox(width: 10),
            _Fact(
              icon: LucideIcons.timer,
              value: a.timeLimitMinutes == null ? 'None' : '${a.timeLimitMinutes} min',
              label: 'Time limit',
            ),
            const SizedBox(width: 10),
            _Fact(icon: LucideIcons.target, value: '${a.passMark}%', label: 'To pass'),
            const SizedBox(width: 10),
            _Fact(
              icon: LucideIcons.rotateCcw,
              value: a.attemptsLeft == null ? '∞' : '${a.attemptsLeft}',
              label: 'Attempts',
            ),
          ],
        ),
        if (a.bestScore != null) ...[
          const SizedBox(height: 14),
          AppCard(
            highlight: a.passed ? p.success.withValues(alpha: 0.5) : null,
            child: Row(
              children: [
                Icon(a.passed ? LucideIcons.badgeCheck : LucideIcons.chartBar,
                    color: a.passed ? p.success : p.mutedForeground),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    a.passed ? 'Passed · best score ${a.bestScore}%' : 'Best score so far: ${a.bestScore}%',
                    style: context.text.labelLarge,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (detail.instructions.isNotEmpty) ...[
          const SectionTitle('Before you start'),
          Text(detail.instructions, style: context.text.bodyMedium?.copyWith(height: 1.5)),
        ],
        const SizedBox(height: 20),
        if (blocked != null)
          Text(blocked, textAlign: TextAlign.center, style: context.text.bodyMedium?.copyWith(color: p.mutedForeground))
        else
          GradientButton(
            key: const ValueKey('start-assessment'),
            label: buttonLabel,
            icon: LucideIcons.play,
            onPressed: () => _start(context),
          ),
        if (detail.attempts.isNotEmpty) ...[
          const SectionTitle('Your attempts'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, at) in detail.attempts.indexed) ...[
                  if (i > 0) const Divider(),
                  ListTile(
                    leading: Icon(at.passed ? LucideIcons.circleCheck : LucideIcons.circleX,
                        color: at.passed ? p.success : p.destructive),
                    title: Text('${at.score}% · ${at.passed ? 'Passed' : 'Not passed'}'),
                    subtitle: Text(formatDate(at.submittedAt)),
                    trailing: const Icon(LucideIcons.chevronRight, size: 18),
                    onTap: () => context.push('/learn/course/$slug/result/${at.id}'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            children: [
              Icon(icon, size: 17, color: context.palette.brand),
              const SizedBox(height: 6),
              Text(value, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
            ],
          ),
        ),
      );
}

/* ---------- taking it ---------- */

/// One question at a time. Answers autosave; an exam's timer submits it when time runs out.
class TakeAssessmentScreen extends ConsumerStatefulWidget {
  const TakeAssessmentScreen({super.key, required this.slug, required this.assessmentId});

  final String slug;
  final int assessmentId;

  @override
  ConsumerState<TakeAssessmentScreen> createState() => _TakeAssessmentScreenState();
}

class _TakeAssessmentScreenState extends ConsumerState<TakeAssessmentScreen> {
  AttemptInProgress? _attempt;
  ApiException? _error;
  final Map<int, Set<int>> _answers = {};
  int _index = 0;
  bool _submitting = false;
  DateTime? _endsAt;
  Timer? _ticker;
  Timer? _saveSoon;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _saveSoon?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final attempt = await ref.read(learningRepositoryProvider).startAttempt(widget.slug, widget.assessmentId);
      if (!mounted) return;
      setState(() {
        _attempt = attempt;
        _answers.addAll(attempt.answers);
        if (attempt.secondsLeft != null) _endsAt = DateTime.now().add(Duration(seconds: attempt.secondsLeft!));
      });
      if (_endsAt != null) {
        _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() {});
          if (_secondsLeft == 0) _submit(timedOut: true);
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  int get _secondsLeft => _endsAt == null ? 0 : math.max(0, _endsAt!.difference(DateTime.now()).inSeconds);

  void _choose(QuizQuestion q, int choiceId) {
    setState(() {
      final chosen = _answers.putIfAbsent(q.id, () => <int>{});
      if (q.allowsSeveral) {
        chosen.contains(choiceId) ? chosen.remove(choiceId) : chosen.add(choiceId);
      } else {
        chosen
          ..clear()
          ..add(choiceId);
      }
    });
    // Save shortly after the last change, so a timed-out exam keeps what was answered.
    _saveSoon?.cancel();
    _saveSoon = Timer(const Duration(milliseconds: 800), () {
      final attempt = _attempt;
      if (attempt == null || _submitting) return;
      ref.read(learningRepositoryProvider).saveAnswers(widget.slug, attempt.id, _answers).catchError((_) {});
    });
  }

  int get _unanswered => _attempt!.questions.where((q) => (_answers[q.id] ?? const {}).isEmpty).length;

  Future<void> _submit({bool timedOut = false}) async {
    final attempt = _attempt;
    if (attempt == null || _submitting) return;
    if (!timedOut) {
      final left = _unanswered;
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(attempt.isExam ? 'Submit your exam?' : 'Submit your answers?'),
          content: Text(left == 0
              ? "You've answered every question."
              : '$left ${left == 1 ? 'question is' : 'questions are'} not answered yet and will count as wrong.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Keep going')),
            FilledButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Submit')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    _ticker?.cancel();
    _saveSoon?.cancel();
    setState(() => _submitting = true);
    try {
      final result = await ref.read(learningRepositoryProvider).submitAttempt(widget.slug, attempt.id, _answers);
      if (!mounted) return;
      _refreshCourse(ref, widget.slug, widget.assessmentId);
      if (timedOut) showMessage(context, "Time's up. Your exam was submitted.");
      context.pushReplacement('/learn/course/${widget.slug}/result/${result.attemptId}');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showMessage(context, e.message);
    }
  }

  Future<bool> _confirmLeave() async {
    final exam = _attempt?.isExam ?? false;
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Leave for now?'),
        content: Text(exam
            ? 'Your answers are saved, but the timer keeps running. Come back before it ends to finish.'
            : 'Your answers are saved. You can come back and finish later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Stay')),
          FilledButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Leave')),
        ],
      ),
    );
    return leave == true;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final attempt = _attempt;
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Padding(
          padding: pagePadding,
          child: ErrorNote(_error!.message, title: "We couldn't start this."),
        ),
      );
    }
    if (attempt == null) return const Scaffold(body: LoadingView(label: 'Getting your questions…'));
    final q = attempt.questions[_index];
    final last = _index == attempt.questions.length - 1;
    final secondsLeft = _secondsLeft;
    final urgent = _endsAt != null && secondsLeft < 5 * 60;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) context.go('/learn/course/${widget.slug}');
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Leave',
            icon: const Icon(LucideIcons.x),
            onPressed: () async {
              if (await _confirmLeave() && context.mounted) context.go('/learn/course/${widget.slug}');
            },
          ),
          title: Text(attempt.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
          actions: [
            if (_endsAt != null)
              Container(
                key: const ValueKey('exam-timer'),
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (urgent ? p.destructive : p.brand).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.timer, size: 15, color: urgent ? p.destructive : p.brand),
                    const SizedBox(width: 5),
                    Text(
                      '${secondsLeft ~/ 60}:${(secondsLeft % 60).toString().padLeft(2, '0')}',
                      semanticsLabel: '${secondsLeft ~/ 60} minutes left',
                      style: context.text.labelLarge?.copyWith(
                        color: urgent ? p.destructive : p.brand,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Question ${_index + 1} of ${attempt.questions.length}', style: context.text.labelLarge),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: (_index + 1) / attempt.questions.length,
                      minHeight: 6,
                      backgroundColor: p.muted,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                children: [
                  Text(q.text, style: context.text.titleLarge?.copyWith(height: 1.35)),
                  const SizedBox(height: 6),
                  Text(q.allowsSeveral ? 'Choose all that apply.' : 'Choose one answer.', style: context.text.bodySmall),
                  const SizedBox(height: 16),
                  for (final c in q.choices) ...[
                    _ChoiceTile(
                      text: c.text,
                      selected: _answers[q.id]?.contains(c.id) ?? false,
                      several: q.allowsSeveral,
                      onTap: () => _choose(q, c.id),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: p.border))),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Row(
                    children: [
                      IconButton.outlined(
                        tooltip: 'Previous question',
                        onPressed: _index == 0 ? null : () => setState(() => _index--),
                        style: IconButton.styleFrom(
                          side: BorderSide(color: p.border),
                          minimumSize: const Size(48, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(LucideIcons.arrowLeft, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: last
                            ? GradientButton(
                                key: const ValueKey('submit-attempt'),
                                label: 'Submit',
                                icon: LucideIcons.send,
                                busy: _submitting,
                                onPressed: () => _submit(),
                              )
                            : GradientButton(
                                key: const ValueKey('next-question'),
                                label: 'Next question',
                                icon: LucideIcons.arrowRight,
                                onPressed: () => setState(() => _index++),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.text, required this.selected, required this.several, required this.onTap});

  final String text;
  final bool selected;
  final bool several;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: !several,
      child: Material(
        color: selected ? p.brand.withValues(alpha: 0.08) : p.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? p.brand : p.border, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  several
                      ? (selected ? LucideIcons.squareCheck : LucideIcons.square)
                      : (selected ? LucideIcons.circleDot : LucideIcons.circle),
                  color: selected ? p.brand : p.mutedForeground,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(text, style: context.text.bodyLarge)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------- result ---------- */

class AttemptResultScreen extends ConsumerWidget {
  const AttemptResultScreen({super.key, required this.slug, required this.attemptId});

  final String slug;
  final int attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back to course',
            icon: const Icon(LucideIcons.x),
            onPressed: () => context.go('/learn/course/$slug'),
          ),
        ),
        body: AsyncBody(
          provider: attemptResultProvider((slug, attemptId)),
          loadingLabel: 'Marking…',
          builder: (result) => _Result(slug: slug, result: result),
        ),
      );
}

class _Result extends ConsumerWidget {
  const _Result({required this.slug, required this.result});
  final String slug;
  final AttemptResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final r = result;
    final colour = r.passed ? p.success : p.destructive;
    final detail = ref.watch(assessmentProvider((slug, r.assessmentId))).value?.summary;
    final canRetry = detail?.canStart ?? !r.isExam;
    return ListView(
      padding: pagePadding,
      children: [
        const SizedBox(height: 8),
        Center(
          child: SizedBox.square(
            dimension: 150,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: r.score / 100,
                  strokeWidth: 12,
                  strokeCap: StrokeCap.round,
                  backgroundColor: p.muted,
                  color: colour,
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${r.score}%', style: context.text.displaySmall),
                      Text('${r.correctCount} of ${r.questionCount} right', style: context.text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          r.passed ? (r.isExam ? 'You passed the final exam!' : 'Well done, you passed!') : 'Not passed this time',
          textAlign: TextAlign.center,
          style: context.text.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          r.passed
              ? (r.isExam
                  ? 'Your facilitator can now issue your certificate once your coursework is complete.'
                  : 'This quiz counts towards your course progress.')
              : 'You needed ${r.passMark}%. ${r.isExam ? '' : 'Look at the answers below, then try again.'}',
          textAlign: TextAlign.center,
          style: context.text.bodyMedium?.copyWith(color: p.mutedForeground),
        ),
        const SizedBox(height: 20),
        if (canRetry && !r.passed)
          GradientButton(
            key: const ValueKey('retry-assessment'),
            label: 'Try again',
            icon: LucideIcons.rotateCcw,
            onPressed: () => context.pushReplacement('/learn/course/$slug/assessment/${r.assessmentId}/take'),
          ),
        const SizedBox(height: 10),
        SecondaryButton(label: 'Back to course', onPressed: () => context.go('/learn/course/$slug')),
        if (r.review != null && r.review!.isNotEmpty) ...[
          const SectionTitle('Your answers'),
          for (final (i, q) in r.review!.indexed) ...[_ReviewCard(number: i + 1, question: q), const SizedBox(height: 12)],
        ] else if (r.isExam) ...[
          const SizedBox(height: 16),
          Text(
            'Exam answers are not shown, so the questions stay fair for everyone.',
            textAlign: TextAlign.center,
            style: context.text.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.number, required this.question});
  final int number;
  final ReviewedQuestion question;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final q = question;
    return AppCard(
      highlight: (q.correct ? p.success : p.destructive).withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(q.correct ? LucideIcons.circleCheck : LucideIcons.circleX,
                  size: 18, color: q.correct ? p.success : p.destructive),
              const SizedBox(width: 8),
              Text('Question $number', style: context.text.labelLarge),
            ],
          ),
          const SizedBox(height: 8),
          Text(q.text, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          for (final c in q.choices)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    q.correctChoiceIds.contains(c.id)
                        ? LucideIcons.check
                        : (q.chosen.contains(c.id) ? LucideIcons.x : LucideIcons.dot),
                    size: 16,
                    color: q.correctChoiceIds.contains(c.id)
                        ? p.success
                        : (q.chosen.contains(c.id) ? p.destructive : p.mutedForeground),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.text + (q.chosen.contains(c.id) ? '  (your answer)' : ''),
                      style: context.text.bodyMedium?.copyWith(
                        fontWeight: q.correctChoiceIds.contains(c.id) ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (q.explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: p.muted, borderRadius: BorderRadius.circular(10)),
              child: Text(q.explanation, style: context.text.bodySmall?.copyWith(height: 1.4, color: p.foreground)),
            ),
          ],
        ],
      ),
    );
  }
}
