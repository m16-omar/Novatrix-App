import '../../core/network/api_client.dart';
import '../../core/network/token_store.dart';
import '../models/json.dart';
import '../models/user.dart';

class AuthRepository {
  AuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStore _tokens;

  Future<bool> hasSession() async => await _tokens.read() != null;

  Future<User> login(String email, String password) async {
    final res = await _api.post<Json>('/auth/login/', body: {'email': email.trim(), 'password': password});
    return _startSession(res);
  }

  Future<User> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String phone = '',
  }) async {
    final res = await _api.post<Json>('/auth/register/', body: {
      'email': email.trim(),
      'password': password,
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      if (phone.trim().isNotEmpty) 'phone': phone.trim(),
    });
    return _startSession(res);
  }

  Future<User> _startSession(Json res) async {
    await _tokens.write(Tokens.fromJson(jsonOf(res['tokens'])));
    return User.fromJson(jsonOf(res['user']));
  }

  Future<void> logout() => _tokens.write(null);

  Future<User> me() async => User.fromJson(jsonOf((await _api.get<Json>('/auth/me/', auth: true))['user']));

  Future<Roles> roles() async => Roles.fromJson(await _api.get<Json>('/services/me/roles/', auth: true));

  Future<User> updateProfile(Profile profile) async =>
      User.fromJson(jsonOf((await _api.patch<Json>('/auth/me/', body: profile.toJson()))['user']));

  Future<void> changePassword(String current, String next) =>
      _api.post<Json>('/auth/change-password/', body: {'old_password': current, 'new_password': next}, auth: true);

  /// Emails a reset link. The link opens the website's reset page.
  Future<void> requestPasswordReset(String email) =>
      _api.post<Json>('/auth/password-reset/', body: {'email': email.trim()});
}
