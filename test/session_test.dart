import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novatrix_app/core/network/api_client.dart';
import 'package:novatrix_app/core/network/api_exception.dart';
import 'package:novatrix_app/core/network/token_store.dart';
import 'package:novatrix_app/core/providers.dart';
import 'package:novatrix_app/data/models/user.dart';
import 'package:novatrix_app/data/repositories/auth_repository.dart';

/// The backend, answering with whatever each test sets.
class FakeAuth extends AuthRepository {
  FakeAuth(TokenStore store) : super(ApiClient(store), store);

  Object? meResult;

  @override
  Future<User> me() async {
    final result = meResult;
    if (result is Exception) throw result;
    return result as User;
  }

  @override
  Future<Roles> roles() async {
    if (meResult is Exception) throw meResult as Exception;
    return const Roles(enrolledCourses: 2);
  }
}

const ada = User(id: 7, email: 'ada@example.com', profile: Profile(firstName: 'Ada'));

void main() {
  late TokenStore store;
  late FakeAuth auth;

  ProviderContainer start() => ProviderContainer(overrides: [
        tokenStoreProvider.overrideWithValue(store),
        authRepositoryProvider.overrideWithValue(auth),
      ]);

  /// A returning user: signed in before, with their details saved on the device.
  void returningUser() => FlutterSecureStorage.setMockInitialValues({
        'nvx_access': 'a',
        'nvx_refresh': 'r',
        'nvx_session': jsonEncode({
          'user': ada.toJson(),
          'roles': const Roles(hasClientProjects: true).toJson(),
        }),
      });

  setUp(() {
    store = TokenStore();
    auth = FakeAuth(store);
  });

  test('a returning user stays signed in with saved details when the backend is down', () async {
    returningUser();
    auth.meResult = ApiException("We couldn't reach our server.");
    final session = await start().read(sessionProvider.future);
    expect(session?.user.email, 'ada@example.com');
    expect(session?.roles.hasClientProjects, isTrue);
    expect(session?.offline, isTrue);
    expect(await store.read(), isNotNull, reason: 'the login is kept');
  });

  test('a server error is treated like an outage, not a sign-out', () async {
    returningUser();
    auth.meResult = ApiException('Something went wrong.', status: 503);
    expect((await start().read(sessionProvider.future))?.offline, isTrue);
  });

  test('a session the backend rejects is signed out and its saved details removed', () async {
    returningUser();
    auth.meResult = ApiException('Please log in to continue.', status: 401);
    expect(await start().read(sessionProvider.future), isNull);
    expect(await store.read(), isNull);
    expect(await store.readSaved(), isNull);
  });

  test('confirmed details are saved for next time', () async {
    returningUser();
    auth.meResult = const User(id: 7, email: 'ada@example.com', profile: Profile(firstName: 'Adaeze'));
    final session = await start().read(sessionProvider.future);
    expect(session?.offline, isFalse);
    expect(session?.roles.enrolledCourses, 2);
    final saved = await store.readSaved();
    expect((saved?['user'] as Map)['profile']['first_name'], 'Adaeze');
  });

  test('a session restored offline is confirmed once the backend is back', () async {
    returningUser();
    auth.meResult = ApiException("We couldn't reach our server.");
    final container = start();
    await container.read(sessionProvider.future);
    auth.meResult = ada;
    await container.read(sessionProvider.notifier).revalidate();
    expect(container.read(sessionProvider).value?.offline, isFalse);
  });
}
