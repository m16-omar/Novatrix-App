import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/user.dart';
import 'workspace.dart' as ws;

/// Bottom navigation that follows the area the current page belongs to.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final roles = session?.roles;
    final workspace = ws.Workspace.forPath(location, roles);
    final tabs = ws.tabsFor(workspace, signedIn: session != null);
    final index = ws.tabIndexFor(tabs, location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(tabs[i].path),
        destinations: [
          for (final tab in tabs)
            NavigationDestination(
              icon: _withBadge(tab, roles, Icon(tab.icon)),
              label: tab.label,
              tooltip: tab.label,
            ),
        ],
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
