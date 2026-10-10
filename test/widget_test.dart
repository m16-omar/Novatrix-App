import 'package:flutter_test/flutter_test.dart';
import 'package:novatrix_app/core/format.dart';
import 'package:novatrix_app/core/network/api_exception.dart';
import 'package:novatrix_app/data/models/portal.dart';
import 'package:novatrix_app/data/models/user.dart';
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
}
