import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Courses someone wants to enroll in, by slug, kept on the device between launches (like the
/// website's cart). Prices always come from the live catalog, and the backend prices the order.
class CartController extends Notifier<List<String>> {
  static const _key = 'nvx_cart';

  /// A checkout started but not yet confirmed, so the app can confirm it after the person pays in
  /// the browser, even if the app was closed meanwhile.
  static const pendingKey = 'nvx_pending_checkout';

  @override
  List<String> build() {
    SharedPreferences.getInstance().then((prefs) {
      final saved = prefs.getStringList(_key) ?? const [];
      if (saved.isNotEmpty && state.isEmpty) state = saved;
    });
    return const [];
  }

  bool contains(String slug) => state.contains(slug);

  Future<void> add(String slug) => _save([...state.where((s) => s != slug), slug]);

  Future<void> remove(String slug) => _save(state.where((s) => s != slug).toList());

  Future<void> removeAll(Iterable<String> slugs) => _save(state.where((s) => !slugs.contains(s)).toList());

  Future<void> _save(List<String> slugs) async {
    state = slugs;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, slugs);
  }
}

final cartProvider = NotifierProvider<CartController, List<String>>(CartController.new);
