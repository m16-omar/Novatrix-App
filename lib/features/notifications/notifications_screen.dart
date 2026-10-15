import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data_providers.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/push.dart' show notificationRoute;
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/notification.dart';

/// The bell for headers: opens the notification list, with how many are unread.
/// Shows nothing when signed out.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key, this.color});

  /// For headers on a coloured background.
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(sessionProvider).value == null) return const SizedBox.shrink();
    final unread = ref.watch(unreadNotificationsProvider).value ?? 0;
    final p = context.palette;
    return IconButton(
      key: const ValueKey('notification-bell'),
      tooltip: unread == 0 ? 'Notifications' : 'Notifications, $unread unread',
      onPressed: () => context.push('/notifications'),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        backgroundColor: p.brand2,
        child: Icon(LucideIcons.bell, color: color ?? p.foreground),
      ),
    );
  }
}

IconData _iconFor(String kind) => switch (kind) {
      'feedback' => LucideIcons.clipboardCheck,
      'announcement' => LucideIcons.megaphone,
      'ticket' => LucideIcons.lifeBuoy,
      _ => LucideIcons.bell,
    };

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  /// Read on this screen, shown as read straight away without waiting for a reload.
  final _readHere = <int>{};
  bool _allRead = false;

  bool _isRead(AppNotification n) => _allRead || n.isRead || _readHere.contains(n.id);

  Future<void> _refresh() async {
    setState(() {
      _readHere.clear();
      _allRead = false;
    });
    ref.invalidate(unreadNotificationsProvider);
    ref.invalidate(notificationsProvider);
    await ref.read(notificationsProvider.future);
  }

  /// For updates that finish after this screen may have closed (the bell lives on elsewhere).
  ProviderContainer get _container => ProviderScope.containerOf(context, listen: false);

  Future<void> _open(AppNotification n) async {
    if (!_isRead(n)) {
      setState(() => _readHere.add(n.id));
      final container = _container;
      container.read(notificationsRepositoryProvider).markRead(n.id).then(
            (_) => container.invalidate(unreadNotificationsProvider),
            onError: (_) {},
          );
    }
    final route = notificationRoute({'route': n.route});
    if (route != null && mounted) context.push(route);
  }

  Future<void> _markAllRead() async {
    setState(() => _allRead = true);
    final container = _container;
    try {
      await container.read(notificationsRepositoryProvider).markAllRead();
    } catch (_) {
      if (mounted) {
        setState(() => _allRead = false);
        showMessage(context, "We couldn't mark your notifications as read. Please try again.");
      }
    }
    container.invalidate(unreadNotificationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(notificationsProvider).value ?? const <AppNotification>[];
    final anyUnread = items.any((n) => !_isRead(n));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (anyUnread)
            TextButton(
              key: const ValueKey('mark-all-read'),
              onPressed: _markAllRead,
              child: const Text('Mark all as read'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: AsyncBody(
          provider: notificationsProvider,
          loadingLabel: 'Loading your notifications…',
          builder: (list) => list.isEmpty
              ? ListView(
                  padding: pagePadding,
                  children: const [
                    SizedBox(height: 24),
                    EmptyState(
                      icon: LucideIcons.bellOff,
                      title: "You're all caught up.",
                      message: 'Feedback on your work, course announcements, and updates to your support '
                          'requests will appear here.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: pagePadding,
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final n = list[i];
                    return _NotificationTile(notification: n, read: _isRead(n), onTap: () => _open(n));
                  },
                ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.read, required this.onTap});

  final AppNotification notification;
  final bool read;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = notification;
    return Semantics(
      label: read ? null : 'Unread.',
      child: AppCard(
        onTap: onTap,
        highlight: read ? null : p.brand.withValues(alpha: 0.35),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: p.brand.withValues(alpha: read ? 0.06 : 0.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(_iconFor(n.kind), size: 19, color: read ? p.mutedForeground : p.brand),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: context.text.labelLarge?.copyWith(fontWeight: read ? FontWeight.w500 : FontWeight.w700),
                  ),
                  if (n.body.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(n.body, maxLines: 3, overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(height: 1.4)),
                  ],
                  const SizedBox(height: 6),
                  Text(timeAgo(n.createdAt), style: context.text.bodySmall?.copyWith(color: p.mutedForeground)),
                ],
              ),
            ),
            if (!read)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 4),
                width: 9,
                height: 9,
                decoration: BoxDecoration(gradient: p.gradient, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
