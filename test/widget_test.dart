import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novatrix_app/core/format.dart';
import 'package:novatrix_app/core/network/api_exception.dart';
import 'package:novatrix_app/core/push.dart';
import 'package:novatrix_app/data/models/course.dart';
import 'package:novatrix_app/data/models/portal.dart';
import 'package:novatrix_app/data/models/site_catalog.dart';
import 'package:novatrix_app/data/models/user.dart';
import 'package:novatrix_app/features/learner/lesson_text.dart';
import 'package:novatrix_app/features/shell/workspace.dart';

void main() {
  group('API errors', () {
    test('field errors and messages come from the backend envelope', () {
      final e = ApiException.fromResponse(400, {
        'success': false,
        'detail': {'old_password': ['Your current password is incorrect.'], 'non_field_errors': ['Check the form.']},
      });
      expect(e.field('old_password'), 'Your current password is incorrect.');
      expect(e.message, 'Check the form.');
    });

    test('verification errors keep their code and numbers', () {
      final wrong = ApiException.fromResponse(400, {
        'success': false, 'code': 'code_invalid', 'attempts_left': 3, 'message': 'That code is not right.',
      });
      expect(wrong.code, 'code_invalid');
      expect(wrong.info['attempts_left'], 3);
      expect(wrong.message, 'That code is not right.');
      final blocked = ApiException.fromResponse(403, {
        'success': false, 'status_code': 403,
        'detail': {'detail': 'Confirm your email address to continue.', 'code': 'email_not_verified'},
      });
      expect(blocked.code, 'email_not_verified');
      expect(blocked.fieldErrors, isEmpty);
      expect(blocked.info, isEmpty);
    });

    test('server errors never show internals', () {
      expect(ApiException.fromResponse(500, {'detail': 'Traceback…'}).message,
          'Something went wrong on our side. Please try again.');
    });
  });

  group('workspaces', () {
    test('people land in the area they use', () {
      expect(Workspace.primaryFor(const Roles(enrolledCourses: 1, isFacilitator: true)), Workspace.learner);
      expect(Workspace.primaryFor(const Roles(isFacilitator: true)), Workspace.facilitator);
      expect(Workspace.primaryFor(const Roles(hasClientProjects: true)), Workspace.client);
      expect(Workspace.primaryFor(Roles.none), Workspace.learner);
    });

    test('paths map to their area and tab', () {
      expect(Workspace.forPath('/client/projects/3', null), Workspace.client);
      final tabs = tabsFor(Workspace.learner, signedIn: true);
      expect(tabs[tabIndexFor(tabs, '/learn/course/web/lesson/4')].label, 'Dashboard');
      expect(tabs[tabIndexFor(tabs, '/learn/certificates')].label, 'Certificates');
      final public = tabsFor(Workspace.public, signedIn: false);
      expect(public[tabIndexFor(public, '/courses/data-analytics')].label, 'Courses');
      expect(public[tabIndexFor(public, '/login')].label, 'Settings');
      expect(public[tabIndexFor(public, '/cart')].label, 'Courses');
      expect(public[tabIndexFor(public, '/signup')].label, 'Settings');
      expect(tabsFor(Workspace.public, signedIn: true).last.label, 'Profile');
    });
  });

  test('project stage tracker positions', () {
    ClientProject project(String status) =>
        ClientProject(id: 1, title: 't', organization: 'o', status: status, statusDisplay: status);
    expect(project('discovery').stageIndex, 0);
    expect(project('testing').stageIndex, 2);
    expect(project('closed').stageIndex, projectStages.length);
  });

  test('formatting', () {
    expect(plural(1, 'lesson'), '1 lesson');
    expect(plural(3, 'lesson'), '3 lessons');
    expect(formatMoney(99, 'USD'), r'$99');
  });

  test('the bundled website content is complete and its links resolve', () {
    final catalog = SiteCatalog.fromJson(jsonDecode(File('assets/content/site.json').readAsStringSync()));
    expect(catalog.offerings.map((o) => o.slug), contains('software-development'));
    expect(catalog.industries, hasLength(greaterThanOrEqualTo(1)));
    expect(catalog.insights.every((i) => i.body.isNotEmpty), isTrue);
    for (final o in catalog.allOfferings) {
      expect(o.title, isNotEmpty, reason: o.slug);
      expect(o.process, isNotEmpty, reason: o.slug);
      for (final i in o.industries) {
        expect(catalog.industry(i), isNotNull, reason: '${o.slug} lists industry $i');
      }
    }
    for (final i in catalog.insights) {
      for (final r in i.related) {
        expect(catalog.insight(r), isNotNull, reason: '${i.slug} links to $r');
      }
    }
  });

  test('notifications only open learner, client, and teaching screens', () {
    expect(notificationRoute({'route': '/learn/course/web/lesson/4'}), '/learn/course/web/lesson/4');
    expect(notificationRoute({'route': '/client/support'}), '/client/support');
    expect(notificationRoute({'route': '/profile/delete'}), isNull);
    expect(notificationRoute({'route': 'https://evil.example'}), isNull);
    expect(notificationRoute({'route': '//evil.example/learn'}), isNull);
    expect(notificationRoute({}), isNull);
  });

  test('courses marked free show as free and cost nothing', () {
    final marked = Course.fromJson({'slug': 'a', 'price_amount': '49.00', 'price_currency': 'USD', 'is_free': true});
    expect(marked.isFree, isTrue);
    expect(marked.priceLabel, 'Free');
    expect(marked.effectivePrice, 0);
    final paid = Course.fromJson({'slug': 'b', 'price_amount': '49.00', 'price_currency': 'USD', 'is_free': false});
    expect(paid.priceLabel, r'$49');
    // Older backends don't send is_free: a course priced at nothing is free.
    expect(Course.fromJson({'slug': 'c', 'price_amount': '0.00'}).isFree, isTrue);
  });

  test('signed-in people always get their own bottom bar', () {
    const learner = Roles(enrolledCourses: 1);
    const both = Roles(enrolledCourses: 1, isFacilitator: true);
    // Visitors: the public bar.
    expect(barWorkspaceFor('/', null), Workspace.public);
    // Signed in, on shared pages: their main area...
    expect(barWorkspaceFor('/', learner), Workspace.learner);
    expect(barWorkspaceFor('/courses/web', learner), Workspace.learner);
    // ...or the one they were last in.
    expect(barWorkspaceFor('/consultation', both, lastArea: Workspace.facilitator), Workspace.facilitator);
    // Area pages keep their own bar.
    expect(barWorkspaceFor('/client/support', learner), Workspace.client);
    // A shared page matches none of the area's tabs.
    expect(matchingTab(tabsFor(Workspace.learner, signedIn: true), '/'), isNull);
    expect(matchingTab(tabsFor(Workspace.learner, signedIn: true), '/learn/certificates'), 2);
  });

  test('plain-text lessons get headings, and a repeated title is dropped', () {
    const raw = 'Lesson 1.1: What Does a Cloud Engineer Do?\n\nWelcome to **Week 1**!\n\n\n\n🎯 Learning Objectives\n'
        'By the end of this lesson, you will be able to:\n- Define the role.\n\n 🏗 The 4 Core Buckets\n\n1. Provisioning';
    final md = lessonMarkdown(raw, title: 'What Does a Cloud Engineer Do?');
    expect(md, startsWith('Welcome to **Week 1**!'));
    expect(md, contains('### 🎯 Learning Objectives\n\nBy the end'));
    expect(md, contains('### 🏗 The 4 Core Buckets'));
    expect(md, contains('1. Provisioning'));
    expect(md, isNot(contains('\n\n\n')));
    // Already Markdown: left as written.
    expect(lessonMarkdown('# Intro\n🎯 Goals', title: 'Intro'), '# Intro\n🎯 Goals');
  });
}
