// End-to-end journey against a running backend, with screenshots.
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/app_test.dart -d <simulator> \
//     --dart-define=API_BASE_URL=http://localhost:8001/api/v1
//
// Needs the QA accounts and data from the backend's mobile QA seed.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:novatrix_app/core/network/token_store.dart';
import 'package:novatrix_app/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

const email = 'qa-app@example.com';
const password = 'Qa-Str0ng-pass!';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> waitFor(WidgetTester t, Finder f, {int seconds = 25}) async {
    final end = DateTime.now().add(Duration(seconds: seconds));
    while (DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 200));
      if (f.evaluate().isNotEmpty) return;
    }
    await binding.takeScreenshot('zz-failure');
    throw TestFailure('Timed out waiting for $f');
  }

  Future<void> settle(WidgetTester t, [int ms = 800]) async {
    for (var i = 0; i < ms ~/ 100; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester t, String name) async {
    await settle(t, 600);
    await binding.takeScreenshot(name);
  }

  Future<void> tapText(WidgetTester t, String text) async {
    if (find.text(text).evaluate().isEmpty) {
      // Lazily built lists only create what's near the screen: scroll down to it.
      await t.scrollUntilVisible(find.text(text), 300,
          scrollable: find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first);
    }
    final f = find.text(text).first;
    await t.ensureVisible(f);
    await settle(t, 300);
    await t.tap(f);
    await settle(t, 300);
  }

  Future<void> tapNav(WidgetTester t, String label) async {
    await t.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
    await settle(t, 300);
  }

  Future<void> switchArea(WidgetTester t, String chip, String option) async {
    final switcher = find.byKey(const ValueKey('workspace-switcher'));
    expect(find.descendant(of: switcher, matching: find.text(chip)), findsOneWidget);
    await t.tap(switcher);
    await waitFor(t, find.text(option));
    await t.tap(find.text(option));
    await settle(t, 600);
  }

  testWidgets('public site, learning, teaching, client, and profile', (t) async {
    await TokenStore().write(null); // start signed out
    await (await SharedPreferences.getInstance()).remove('nvx_onboarded'); // and as a first launch
    app.main();

    // Welcome slides
    await waitFor(t, find.text('Technology that\nworks for you'));
    await shot(t, '00-welcome');
    await tapText(t, 'Continue');
    await waitFor(t, find.text('Connect your\nsystems'));
    await tapText(t, 'Continue');
    await waitFor(t, find.text('Get started'));
    await tapText(t, 'Get started');

    // Public
    await waitFor(t, find.text('Build better systems.'));
    await waitFor(t, find.text('Four connected services. One delivery partner.'));
    await shot(t, '01-home');

    await tapNav(t, 'Courses');
    await waitFor(t, find.text('Data Analytics'));
    await shot(t, '02-courses');
    await tapText(t, 'Data Analytics');
    await waitFor(t, find.text("What you'll learn"));
    expect(find.text('Enroll on the website'), findsOneWidget);
    await shot(t, '03-course-detail');

    // Log in
    await tapNav(t, 'Settings');
    await waitFor(t, find.byKey(const ValueKey('guest-login')));
    await t.tap(find.byKey(const ValueKey('guest-login')));
    await settle(t, 300);
    await waitFor(t, find.text('Welcome back'));
    await shot(t, '04-login');
    await t.enterText(find.byType(TextFormField).at(0), email);
    await t.enterText(find.byType(TextFormField).at(1), password);
    await t.tap(find.byKey(const ValueKey('login-submit')));
    await settle(t, 300);

    // Learning
    await waitFor(t, find.text('Welcome back, Ada.'));
    await waitFor(t, find.textContaining('Funnels in practice', findRichText: true));
    await shot(t, '05-learning-dashboard');

    await tapText(t, 'Continue');
    await waitFor(t, find.text('Mark as complete'));
    await shot(t, '06-lesson');
    await tapText(t, 'Mark as complete');
    await waitFor(t, find.text('Mark as not done'));

    await tapText(t, 'Next lesson');
    await waitFor(t, find.text('Submit assignment'));
    await t.enterText(find.byType(TextFormField).at(0), 'https://example.com/my-dashboard');
    await tapText(t, 'Submit assignment');
    await waitFor(t, find.text('Awaiting review'));
    await shot(t, '07-assignment-submitted');

    await t.pageBack();
    await waitFor(t, find.text('Week 1: Foundations'));
    await shot(t, '08-course-outline');

    // Teaching (the switcher sits on each area's main screens)
    await tapNav(t, 'Dashboard');
    await waitFor(t, find.text('Continue learning'));
    await switchArea(t, 'LEARNING', 'Switch to teaching');
    await waitFor(t, find.text('Welcome, Ada.'));
    await waitFor(t, find.text('QA Intro to Python'));
    await shot(t, '09-teaching-dashboard');
    await tapNav(t, 'Reviews');
    await waitFor(t, find.text('Tunde Bello'));
    await shot(t, '10-reviews');
    await t.enterText(find.byType(TextField).first, 'Great cleanup. Add tests next time.');
    await tapText(t, 'Mark reviewed');
    await waitFor(t, find.text("You're all caught up."));

    // Client
    await switchArea(t, 'TEACHING', 'Switch to client dashboard');
    await waitFor(t, find.text('QA School Portal'));
    await shot(t, '11-client-dashboard');
    await t.tap(find.byKey(const ValueKey('open-focus-project')));
    await settle(t, 300);
    await waitFor(t, find.text('Project stage'));
    await shot(t, '12-project');

    // Profile
    await tapNav(t, 'Profile');
    await waitFor(t, find.text('Ada Okafor'));
    await shot(t, '13-profile');
    await tapText(t, 'Light');
    await shot(t, '14-profile-light');
    await tapText(t, 'System');

    await tapText(t, 'Log out');
    await waitFor(t, find.text('Build better systems.'));
  });
}
