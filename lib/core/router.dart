import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_screens.dart';
import '../features/auth/verify_email_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/client/client_screens.dart';
import '../features/explore/explore_screens.dart';
import '../features/learner/assessment_screens.dart';
import '../features/learner/course_player.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/learner/learner_screens.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/profile_screens.dart';
import '../features/public/public_screens.dart';
import '../features/shell/app_shell.dart';
import '../features/shell/splash_screen.dart';
import '../features/shell/workspace.dart';
import '../features/teaching/teaching_screens.dart';
import 'providers.dart';
import 'theme/app_theme.dart';

const _protected = ['/learn', '/teach', '/client', '/profile', '/notifications'];

// Open to guests: the Profile page (log in and app settings), and account deletion, which signs the
// person out and must still show its confirmation.
const _openToGuests = {'/profile', '/profile/delete'};

/// Areas a learner or client reaches only after confirming their email (see VerifyEmailScreen).
const _needVerifiedEmail = ['/learn', '/client'];

bool _isProtected(String path) =>
    !_openToGuests.contains(path) && _protected.any((p) => path == p || path.startsWith('$p/'));

/// Leaving the splash (to the welcome slides or the app) cross-fades instead of sliding in.
Page<void> _fade(GoRouterState state, Widget child) => CustomTransitionPage(
      key: state.pageKey,
      transitionDuration: const Duration(milliseconds: 450),
      child: child,
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: BrandBackdrop(child: child),
      ),
    );

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.listen(onboardingProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final onboarded = ref.read(onboardingProvider);
      final path = state.matchedLocation;

      // Wait for the stored session (and whether onboarding was seen) before deciding anything.
      if ((session.isLoading && !session.hasValue) || (onboarded.isLoading && !onboarded.hasValue)) {
        return path == '/splash' ? null : '/splash?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      final signedIn = session.value != null;

      if (path == '/splash') {
        final from = state.uri.queryParameters['from'];
        if (signedIn && (from == null || from == '/')) {
          return Workspace.primaryFor(session.value!.roles).home;
        }
        // First launch: show the welcome slides, unless the app was opened on a specific page.
        if (!signedIn && onboarded.value == false && (from == null || from == '/')) return '/welcome';
        return from ?? '/';
      }
      if (!signedIn && _isProtected(path)) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      // Signed in but the email isn't confirmed yet: the code screen first, with a fresh code
      // (the sign-up one may have expired), then on to where they were going.
      if (signedIn &&
          session.value!.user.needsEmailVerification &&
          _needVerifiedEmail.any((p) => path == p || path.startsWith('$p/'))) {
        return '/verify-email?send=1&from=${Uri.encodeComponent(state.uri.toString())}';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', pageBuilder: (_, s) => _fade(s, const SplashScreen())),
      GoRoute(path: '/welcome', pageBuilder: (_, s) => _fade(s, const OnboardingScreen())),
      GoRoute(
        path: '/verify-email',
        builder: (_, s) => VerifyEmailScreen(
          from: s.uri.queryParameters['from'],
          sendOnOpen: s.uri.queryParameters['send'] == '1',
        ),
      ),
      ShellRoute(
        pageBuilder: (context, state, child) => _fade(state, AppShell(location: state.matchedLocation, child: child)),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
          GoRoute(
            path: '/courses',
            builder: (_, _) => const CoursesScreen(),
            routes: [
              GoRoute(
                path: ':slug',
                builder: (_, s) => CourseDetailScreen(slug: s.pathParameters['slug']!),
              ),
            ],
          ),
          GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
          GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
          GoRoute(
            path: '/consultation',
            builder: (_, s) => ConsultationScreen(
              service: s.uri.queryParameters['service'],
              about: s.uri.queryParameters['about'],
            ),
          ),
          GoRoute(
            path: '/training-inquiry',
            builder: (_, s) => TrainingInquiryScreen(
              program: s.uri.queryParameters['program'],
              topic: s.uri.queryParameters['topic'],
              forOrganization: s.uri.queryParameters['individual'] != '1',
            ),
          ),

          // Company: services, industries, insights, and about, from the website's content
          GoRoute(
            path: '/services',
            builder: (_, _) => const ServicesScreen(),
            routes: [GoRoute(path: ':slug', builder: (_, s) => OfferingScreen(slug: s.pathParameters['slug']!))],
          ),
          GoRoute(
            path: '/industries',
            builder: (_, _) => const IndustriesScreen(),
            routes: [GoRoute(path: ':slug', builder: (_, s) => IndustryScreen(slug: s.pathParameters['slug']!))],
          ),
          GoRoute(
            path: '/insights',
            builder: (_, _) => const InsightsScreen(),
            routes: [GoRoute(path: ':slug', builder: (_, s) => InsightScreen(slug: s.pathParameters['slug']!))],
          ),
          GoRoute(path: '/about', builder: (_, _) => const AboutScreen()),
          GoRoute(
            path: '/login',
            builder: (_, s) => LoginScreen(
              audience: s.uri.queryParameters['as'],
              from: s.uri.queryParameters['from'],
            ),
          ),
          GoRoute(path: '/signup', builder: (_, s) => SignupScreen(from: s.uri.queryParameters['from'])),
          GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),

          // Learning
          GoRoute(
            path: '/learn',
            builder: (_, _) => const LearnerDashboardScreen(),
            routes: [
              GoRoute(path: 'courses', builder: (_, _) => const MyCoursesScreen()),
              GoRoute(path: 'certificates', builder: (_, _) => const CertificatesScreen()),
              GoRoute(path: 'orders', builder: (_, _) => const OrdersScreen()),
              GoRoute(
                path: 'course/:slug',
                builder: (_, s) => CourseOutlineScreen(slug: s.pathParameters['slug']!),
                routes: [
                  GoRoute(
                    path: 'lesson/:id',
                    builder: (_, s) => LessonScreen(
                      slug: s.pathParameters['slug']!,
                      lessonId: int.parse(s.pathParameters['id']!),
                    ),
                  ),
                  GoRoute(
                    path: 'assessment/:id',
                    builder: (_, s) => AssessmentScreen(
                      slug: s.pathParameters['slug']!,
                      assessmentId: int.parse(s.pathParameters['id']!),
                    ),
                    routes: [
                      GoRoute(
                        path: 'take',
                        builder: (_, s) => TakeAssessmentScreen(
                          slug: s.pathParameters['slug']!,
                          assessmentId: int.parse(s.pathParameters['id']!),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'result/:attemptId',
                    builder: (_, s) => AttemptResultScreen(
                      slug: s.pathParameters['slug']!,
                      attemptId: int.parse(s.pathParameters['attemptId']!),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Teaching
          GoRoute(
            path: '/teach',
            builder: (_, _) => const TeachingDashboardScreen(),
            routes: [
              GoRoute(path: 'reviews', builder: (_, _) => const ReviewsScreen()),
              GoRoute(path: 'learners', builder: (_, _) => const LearnersScreen()),
            ],
          ),

          // Client
          GoRoute(
            path: '/client',
            builder: (_, _) => const ClientDashboardScreen(),
            routes: [
              GoRoute(
                path: 'projects',
                builder: (_, _) => const ProjectsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, s) => ProjectScreen(projectId: int.parse(s.pathParameters['id']!)),
                  ),
                ],
              ),
              GoRoute(
                path: 'support',
                builder: (_, _) => const SupportScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, s) => NewTicketScreen(projectId: int.tryParse(s.uri.queryParameters['project'] ?? '')),
                  ),
                ],
              ),
            ],
          ),

          // Account
          GoRoute(
            path: '/profile',
            builder: (_, _) => const ProfileScreen(),
            routes: [
              GoRoute(path: 'edit', builder: (_, _) => const EditProfileScreen()),
              GoRoute(path: 'password', builder: (_, _) => const ChangePasswordScreen()),
              GoRoute(path: 'delete', builder: (_, _) => const DeleteAccountScreen()),
            ],
          ),
        ],
      ),
    ],
  );
});
