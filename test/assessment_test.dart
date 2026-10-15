import 'package:flutter_test/flutter_test.dart';
import 'package:novatrix_app/data/models/assessment.dart';
import 'package:novatrix_app/features/shell/workspace.dart';

void main() {
  test('an exam in progress keeps its timer and saved answers', () {
    final a = AttemptInProgress.fromJson({
      'attempt_id': 7,
      'assessment_id': 3,
      'kind': 'exam',
      'title': 'Final exam',
      'seconds_left': 2700,
      'answers': {'11': [21, 22]},
      'questions': [
        {'id': 11, 'kind': 'multiple', 'text': 'Pick two', 'choices': [{'id': 21, 'text': 'A'}, {'id': 22, 'text': 'B'}]},
      ],
    });
    expect(a.isExam, isTrue);
    expect(a.secondsLeft, 2700);
    expect(a.answers[11], {21, 22});
    expect(a.questions.single.allowsSeveral, isTrue);
  });

  test('an exam result has no answer review; a quiz result does', () {
    final exam = AttemptResult.fromJson({
      'attempt_id': 7, 'assessment_id': 3, 'kind': 'exam', 'score_percent': 80,
      'correct_count': 8, 'question_count': 10, 'pass_mark': 70, 'passed': true, 'review': null,
    });
    expect(exam.attemptId, 7);
    expect(exam.review, isNull);

    final quiz = AttemptResult.fromJson({
      'attempt_id': 8, 'assessment_id': 4, 'kind': 'quiz', 'score_percent': 0,
      'correct_count': 0, 'question_count': 1, 'pass_mark': 70, 'passed': false,
      'review': [
        {'question_id': 1, 'text': 'Q', 'choices': [{'id': 2, 'text': 'A'}], 'chosen': [],
         'correct_choice_ids': [2], 'correct': false, 'explanation': 'Because.'},
      ],
    });
    expect(quiz.review!.single.correctChoiceIds, contains(2));
    expect(quiz.review!.single.explanation, 'Because.');
  });

  test('unlimited quiz attempts read as null', () {
    final s = AssessmentSummary.fromJson({
      'id': 1, 'kind': 'quiz', 'title': 'Module 1 quiz', 'question_count': 5,
      'pass_mark': 70, 'max_attempts': null, 'attempts_left': null, 'can_start': true,
    });
    expect(s.maxAttempts, isNull);
    expect(s.attemptsLeft, isNull);
    expect(s.facts, '5 questions · Pass 70%');
  });

  test('taking a quiz or exam hides the bottom bar; its intro and result keep it', () {
    expect(isFocusedPath('/learn/course/cloud/assessment/4/take'), isTrue);
    expect(isFocusedPath('/learn/course/cloud/assessment/4'), isFalse);
    expect(isFocusedPath('/learn/course/cloud/result/9'), isFalse);
  });
}
