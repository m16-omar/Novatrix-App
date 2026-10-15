import '../../core/network/api_client.dart';
import '../models/json.dart';
import '../models/notification.dart';

/// The signed-in person's notifications (the bell).
class NotificationsRepository {
  NotificationsRepository(this._api);

  final ApiClient _api;
  static const _base = '/notifications/inbox';

  Future<List<AppNotification>> list() async =>
      listOf(await _api.get<Object>('$_base/', auth: true, query: {'page_size': 50}))
          .map(AppNotification.fromJson)
          .toList();

  Future<int> unreadCount() async => intOf((await _api.get<Json>('$_base/unread-count/', auth: true))['unread']);

  Future<void> markRead(int id) => _api.post<Json>('$_base/$id/read/', auth: true);

  Future<void> markAllRead() => _api.post<Json>('$_base/read-all/', auth: true);
}
