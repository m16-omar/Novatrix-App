import 'json.dart';

/// A module quiz (practice) or the final exam (required for the certificate), with where the
/// learner stands on it.
class AssessmentSummary {
  const AssessmentSummary({
    required this.id,
    required this.isExam,
    required this.title,
    required this.questionCount,
    required this.passMark,
    this.moduleId,
    this.timeLimitMinutes,
    this.maxAttempts,
    this.attemptsUsed = 0,
    this.attemptsLeft,
    this.bestScore,
    this.passed = false,
    this.openAttemptId,
    this.canStart = false,
  });

  final int id;
  final bool isExam;
  final String title;
  final int? moduleId;
  final int questionCount;
  final int? timeLimitMinutes;
  final int passMark;

  /// Null when attempts are unlimited (quizzes).
  final int? maxAttempts;
  final int attemptsUsed;
  final int? attemptsLeft;
  final int? bestScore;
  final bool passed;

  /// An attempt that was started and not submitted: it can be resumed.
  final int? openAttemptId;
  final bool canStart;

  factory AssessmentSummary.fromJson(Json j) => AssessmentSummary(
        id: intOf(j['id']),
        isExam: str(j['kind']) == 'exam',
        title: str(j['title']),
        moduleId: intOrNull(j['module_id']),
        questionCount: intOf(j['question_count']),
        timeLimitMinutes: intOrNull(j['time_limit_minutes']),
        passMark: intOf(j['pass_mark']),
        maxAttempts: intOrNull(j['max_attempts']),
        attemptsUsed: intOf(j['attempts_used']),
        attemptsLeft: intOrNull(j['attempts_left']),
        bestScore: intOrNull(j['best_score']),
        passed: boolOf(j['passed']),
        openAttemptId: intOrNull(j['open_attempt_id']),
        canStart: boolOf(j['can_start']),
      );

  /// "8 questions · 45 min · Pass 70%"
  String get facts => [
        '$questionCount questions',
        if (timeLimitMinutes != null) '$timeLimitMinutes min',
        'Pass $passMark%',
      ].join(' · ');
}

class PastAttempt {
  const PastAttempt({required this.id, required this.score, required this.passed, this.submittedAt});

  final int id;
  final int score;
  final bool passed;
  final DateTime? submittedAt;

  factory PastAttempt.fromJson(Json j) => PastAttempt(
        id: intOf(j['attempt_id']),
        score: intOf(j['score_percent']),
        passed: boolOf(j['passed']),
        submittedAt: dateOf(j['submitted_at']),
      );
}

class AssessmentDetail {
  const AssessmentDetail({required this.summary, this.instructions = '', this.attempts = const []});

  final AssessmentSummary summary;
  final String instructions;
  final List<PastAttempt> attempts;

  factory AssessmentDetail.fromJson(Json j) => AssessmentDetail(
        summary: AssessmentSummary.fromJson(j),
        instructions: str(j['instructions']),
        attempts: jsonList(j['attempts']).map(PastAttempt.fromJson).toList(),
      );
}

class AnswerChoice {
  const AnswerChoice(this.id, this.text);
  final int id;
  final String text;

  factory AnswerChoice.fromJson(Json j) => AnswerChoice(intOf(j['id']), str(j['text']));
}

class QuizQuestion {
  const QuizQuestion({required this.id, required this.allowsSeveral, required this.text, required this.choices});

  final int id;

  /// "Choose all that apply" rather than one answer.
  final bool allowsSeveral;
  final String text;
  final List<AnswerChoice> choices;

  factory QuizQuestion.fromJson(Json j) => QuizQuestion(
        id: intOf(j['id']),
        allowsSeveral: str(j['kind']) == 'multiple',
        text: str(j['text']),
        choices: jsonList(j['choices']).map(AnswerChoice.fromJson).toList(),
      );
}

/// An attempt in progress: the questions (never which answers are right) and any saved answers.
class AttemptInProgress {
  const AttemptInProgress({
    required this.id,
    required this.isExam,
    required this.title,
    required this.questions,
    this.secondsLeft,
    this.answers = const {},
  });

  final int id;
  final bool isExam;
  final String title;
  final List<QuizQuestion> questions;

  /// Null when untimed.
  final int? secondsLeft;
  final Map<int, Set<int>> answers;

  factory AttemptInProgress.fromJson(Json j) => AttemptInProgress(
        id: intOf(j['attempt_id']),
        isExam: str(j['kind']) == 'exam',
        title: str(j['title']),
        questions: jsonList(j['questions']).map(QuizQuestion.fromJson).toList(),
        secondsLeft: intOrNull(j['seconds_left']),
        answers: {
          for (final MapEntry(:key, :value) in jsonOf(j['answers']).entries)
            int.parse(key): {for (final c in value as List) intOf(c)},
        },
      );
}

class ReviewedQuestion {
  const ReviewedQuestion({
    required this.text,
    required this.choices,
    required this.chosen,
    required this.correctChoiceIds,
    required this.correct,
    this.explanation = '',
  });

  final String text;
  final List<AnswerChoice> choices;
  final Set<int> chosen;
  final Set<int> correctChoiceIds;
  final bool correct;
  final String explanation;

  factory ReviewedQuestion.fromJson(Json j) => ReviewedQuestion(
        text: str(j['text']),
        choices: jsonList(j['choices']).map(AnswerChoice.fromJson).toList(),
        chosen: {for (final c in j['chosen'] as List? ?? const []) intOf(c)},
        correctChoiceIds: {for (final c in j['correct_choice_ids'] as List? ?? const []) intOf(c)},
        correct: boolOf(j['correct']),
        explanation: str(j['explanation']),
      );
}

/// A marked attempt. Quizzes include a review of every question; exams only the score.
class AttemptResult {
  const AttemptResult({
    required this.attemptId,
    required this.assessmentId,
    required this.isExam,
    required this.title,
    required this.score,
    required this.correctCount,
    required this.questionCount,
    required this.passMark,
    required this.passed,
    this.review,
  });

  final int attemptId;
  final int assessmentId;
  final bool isExam;
  final String title;
  final int score;
  final int correctCount;
  final int questionCount;
  final int passMark;
  final bool passed;
  final List<ReviewedQuestion>? review;

  factory AttemptResult.fromJson(Json j) => AttemptResult(
        attemptId: intOf(j['attempt_id']),
        assessmentId: intOf(j['assessment_id']),
        isExam: str(j['kind']) == 'exam',
        title: str(j['title']),
        score: intOf(j['score_percent']),
        correctCount: intOf(j['correct_count']),
        questionCount: intOf(j['question_count']),
        passMark: intOf(j['pass_mark']),
        passed: boolOf(j['passed']),
        review: j['review'] is List ? jsonList(j['review']).map(ReviewedQuestion.fromJson).toList() : null,
      );
}
