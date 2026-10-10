import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_screens.dart';
import '../features/client/client_screens.dart';
import '../features/learner/course_player.dart';
import '../features/learner/learner_screens.dart';
import '../features/profile/profile_screens.dart';
import '../features/public/public_screens.dart';
import '../features/shell/app_shell.dart';
import '../features/shell/splash_screen.dart';
import '../features/shell/workspace.dart';
import '../features/teaching/teaching_screens.dart';
import 'providers.dart';

const _protected = ['/learn', '/teach', '/client', '/profile'];

bool _isProtected(String path) => _protected.any((p) => path == p || path.startsWith('$p/'));

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final path = state.matchedLocation;

      // Wait for the stored session to be checked before deciding anything.
      if (session.isLoading && !session.hasValue) {
        return path == '/splash' ? null : '/splash?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      final signedIn = session.value != null;

      if (path == '/splash') {
        final from = state.uri.queryParameters['from'];
        if (signedIn && (from == null || from == '/')) {
          return Workspace.primaryFor(session.value!.roles).home;
        }
        return from ?? '/';
      }
      if (!signedIn && _isProtected(path)) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.matchedLocation, child: child),
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
          GoRoute(path: '/consultation', builder: (_, _) => const ConsultationScreen()),
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
            ],
          ),
        ],
      ),
    ],
  );
});
