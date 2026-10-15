import 'json.dart';

/// A notification in the person's list (the bell): feedback, an announcement, or a ticket update.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.route,
    required this.isRead,
    this.createdAt,
  });

  final int id;

  /// "feedback", "announcement", or "ticket".
  final String kind;
  final String title;
  final String body;

  /// The app screen it's about, e.g. "/learn/course/web/lesson/4". Empty if none.
  final String route;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Json j) => AppNotification(
        id: intOf(j['id']),
        kind: str(j['kind']),
        title: str(j['title']),
        body: str(j['body']),
        route: str(j['route']),
        isRead: boolOf(j['is_read']),
        createdAt: dateOf(j['created_at']),
      );

  AppNotification markedRead() =>
      AppNotification(id: id, kind: kind, title: title, body: body, route: route, isRead: true, createdAt: createdAt);
}
