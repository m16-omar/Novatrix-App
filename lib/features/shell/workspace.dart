import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/models/user.dart';

/// The app's areas. Like the website, the bottom navigation follows the area a page
/// belongs to: the public site, learning, teaching, or the client dashboard.
enum Workspace {
  public('Novatrix', '/'),
  learner('Learning', '/learn'),
  facilitator('Teaching', '/teach'),
  client('Client', '/client');

  const Workspace(this.label, this.home);
  final String label;
  final String home;

  String get switchLabel => switch (this) {
        Workspace.learner => 'Switch to learning',
        Workspace.facilitator => 'Switch to teaching',
        Workspace.client => 'Switch to client dashboard',
        Workspace.public => 'Explore Novatrix',
      };

  static Workspace forPath(String path, Roles? roles) {
    if (path.startsWith('/teach')) return Workspace.facilitator;
    if (path.startsWith('/client')) return Workspace.client;
    if (path.startsWith('/learn')) return Workspace.learner;
    if (path.startsWith('/profile') && roles != null) return primaryFor(roles);
    return Workspace.public;
  }

  /// Where someone lands after signing in: the area they actually use.
  static Workspace primaryFor(Roles roles) {
    if (roles.enrolledCourses > 0) return Workspace.learner;
    if (roles.isFacilitator) return Workspace.facilitator;
    if (roles.hasClientProjects) return Workspace.client;
    return Workspace.learner;
  }

  static List<Workspace> available(Roles roles) => [
        if (roles.enrolledCourses > 0 || (!roles.isFacilitator && !roles.hasClientProjects)) Workspace.learner,
        if (roles.isFacilitator) Workspace.facilitator,
        if (roles.hasClientProjects) Workspace.client,
      ];
}

class Tab {
  const Tab(this.path, this.label, this.icon, {this.badge});
  final String path;
  final String label;
  final IconData icon;
  final int Function(Roles roles)? badge;
}

List<Tab> tabsFor(Workspace workspace, {required bool signedIn}) => switch (workspace) {
      Workspace.public => [
          const Tab('/', 'Home', LucideIcons.house),
          const Tab('/courses', 'Courses', LucideIcons.graduationCap),
          const Tab('/consultation', 'Consult', LucideIcons.messageSquarePlus),
          Tab(signedIn ? '/profile' : '/login', signedIn ? 'Account' : 'Log in', LucideIcons.circleUserRound),
        ],
      Workspace.learner => const [
          Tab('/learn', 'Dashboard', LucideIcons.layoutDashboard),
          Tab('/learn/courses', 'My courses', LucideIcons.bookOpen),
          Tab('/learn/certificates', 'Certificates', LucideIcons.award),
          Tab('/profile', 'Profile', LucideIcons.circleUserRound),
        ],
      Workspace.facilitator => [
          const Tab('/teach', 'Dashboard', LucideIcons.layoutDashboard),
          Tab('/teach/reviews', 'Reviews', LucideIcons.clipboardCheck, badge: (r) => r.pendingReviews),
          const Tab('/teach/learners', 'Learners', LucideIcons.users),
          const Tab('/profile', 'Profile', LucideIcons.circleUserRound),
        ],
      Workspace.client => [
          const Tab('/client', 'Dashboard', LucideIcons.layoutDashboard),
          const Tab('/client/projects', 'Projects', LucideIcons.briefcase),
          Tab('/client/support', 'Support', LucideIcons.lifeBuoy, badge: (r) => r.openTickets),
          const Tab('/profile', 'Profile', LucideIcons.circleUserRound),
        ],
    };

/// Which tab a path belongs to: the longest tab path that prefixes it.
int tabIndexFor(List<Tab> tabs, String path) {
  var best = 0;
  var bestLength = -1;
  for (var i = 0; i < tabs.length; i++) {
    final t = tabs[i].path;
    final matches = t == '/' ? path == '/' : (path == t || path.startsWith('$t/'));
    if (matches && t.length > bestLength) {
      best = i;
      bestLength = t.length;
    }
  }
  // Course pages live under the Courses tab on the public site.
  if (bestLength < 0 && path.startsWith('/courses')) {
    return tabs.indexWhere((t) => t.path == '/courses').clamp(0, tabs.length - 1);
  }
  return best;
}
