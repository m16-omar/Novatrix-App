import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/user.dart';
import '../notifications/notifications_screen.dart';
import 'workspace.dart' as ws;

/// Bottom navigation for the area the person is in. Signed in, it's always their own area's bar
/// (learning, teaching, or client), also on shared pages like Home; signed out, the public bar.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// The area the person was last in, so someone who both learns and teaches keeps their bar on
  /// shared pages.
  ws.Workspace? _lastArea;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).value;
    final roles = session?.roles;
    final location = widget.location;
    final here = ws.Workspace.forPath(location, roles);
    if (session == null) {
      _lastArea = null;
    } else if (here != ws.Workspace.public && !location.startsWith('/profile')) {
      _lastArea = here;
    }
    final workspace = ws.barWorkspaceFor(location, roles, lastArea: _lastArea);
    final tabs = ws.tabsFor(workspace, signedIn: session != null);
    final match = ws.matchingTab(tabs, location);
    final p = context.palette;

    Widget bar = NavigationBar(
      selectedIndex: match ?? 0,
      onDestinationSelected: (i) => context.go(tabs[i].path),
      destinations: [
        for (final tab in tabs)
          NavigationDestination(
            icon: _withBadge(tab, roles, Icon(tab.icon)),
            selectedIcon: _withBadge(tab, roles, Icon(tab.icon, color: match == null ? null : p.brand)),
            label: tab.label,
            tooltip: tab.label,
          ),
      ],
    );
    if (match == null) {
      // A shared page that isn't one of these tabs: show none of them as selected. (The bar
      // always selects one, so the selected one is drawn like the others.)
      final theme = Theme.of(context);
      final base = theme.navigationBarTheme;
      bar = Theme(
        data: theme.copyWith(
          navigationBarTheme: base.copyWith(
            labelTextStyle: WidgetStatePropertyAll(
              base.labelTextStyle?.resolve(const <WidgetState>{}),
            ),
            iconTheme: WidgetStatePropertyAll(base.iconTheme?.resolve(const <WidgetState>{})),
          ),
        ),
        child: bar,
      );
    }

    // While a quiz or exam is open, leaving goes through its own "Leave for now?" question.
    if (ws.isFocusedPath(location)) return widget.child;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: p.border)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, -2))],
        ),
        child: bar,
      ),
    );
  }

  Widget _withBadge(ws.Tab tab, Roles? roles, Widget icon) {
    final count = roles == null ? 0 : (tab.badge?.call(roles) ?? 0);
    if (count == 0) return icon;
    return Badge(label: Text('$count'), child: icon);
  }
}

/// Top bar for workspace home screens: the logo, the area's name, and a switcher.
class WorkspaceAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const WorkspaceAppBar({super.key, required this.workspace, this.actions = const []});

  final ws.Workspace workspace;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final session = ref.watch(sessionProvider).value;
    return AppBar(
      // Area screens are tabs: moving between them uses the bottom bar, not a back arrow.
      automaticallyImplyLeading: false,
      toolbarHeight: 64,
      titleSpacing: 20,
      title: Row(
        children: [
          InkWell(onTap: () => context.go('/'), child: const NovatrixLogo(height: 34)),
          const SizedBox(width: 12),
          if (workspace != ws.Workspace.public)
            Semantics(
              button: true,
              label: '${workspace.label} area. Switch area',
              child: InkWell(
                key: const ValueKey('workspace-switcher'),
                borderRadius: BorderRadius.circular(99),
                onTap: session == null ? null : () => showWorkspaceSwitcher(context, session.roles, workspace),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: p.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                        shaderCallback: (r) => p.gradient.createShader(r),
                        child: Text(
                          workspace.label.toUpperCase(),
                          style: context.text.labelSmall
                              ?.copyWith(color: Colors.white, letterSpacing: 1.6, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(LucideIcons.chevronDown, size: 14, color: p.mutedForeground),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      actions: [
        ...actions,
        if (session != null) const NotificationBell(),
        if (session != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              tooltip: 'My profile',
              onPressed: () => context.go('/profile'),
              icon: Avatar(user: session.user, size: 34),
            ),
          ),
      ],
    );
  }
}

/// Lets people who learn, teach, and/or are clients move between their areas.
void showWorkspaceSwitcher(BuildContext context, Roles roles, ws.Workspace current) {
  final options = [...ws.Workspace.available(roles), ws.Workspace.public].where((w) => w != current).toList();
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text('Switch area', style: sheet.text.titleLarge),
          ),
          for (final w in options)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: Icon(switch (w) {
                ws.Workspace.learner => LucideIcons.graduationCap,
                ws.Workspace.facilitator => LucideIcons.presentation,
                ws.Workspace.client => LucideIcons.briefcase,
                ws.Workspace.public => LucideIcons.globe,
              }),
              title: Text(w.switchLabel),
              trailing: const Icon(LucideIcons.chevronRight, size: 18),
              onTap: () {
                Navigator.pop(sheet);
                context.go(w.home);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
