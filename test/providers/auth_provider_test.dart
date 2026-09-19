import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larger/providers/auth_provider.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

void main() {
  group('AuthNotifier', () {
    test('signUp creates a user successfully', () async {
      final auth = MockFirebaseAuth();
      final notifier = AuthNotifier(auth);

      await notifier.signUp(email: 'new@test.com', password: '123456');

      expect(notifier.state, isA<AsyncData<void>>());
      expect(auth.currentUser, isNotNull);
      expect(auth.currentUser!.email, 'new@test.com');
    });

    test('signIn authenticates an existing user', () async {
      final auth = MockFirebaseAuth();
      await auth.createUserWithEmailAndPassword(
        email: 'user@test.com',
        password: '123456',
      );
      await auth.signOut();

      final notifier = AuthNotifier(auth);
      await notifier.signIn(email: 'user@test.com', password: '123456');

      expect(notifier.state, isA<AsyncData<void>>());
      expect(auth.currentUser?.email, 'user@test.com');
    });

    test('signIn with wrong password sets error state', () async {
      final auth = MockFirebaseAuth();
      whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'invalid-credential'));

      final notifier = AuthNotifier(auth);
      await notifier.signIn(email: 'user@test.com', password: 'wrong-password');

      expect(notifier.state, isA<AsyncError<void>>());
    });

    test('signInDebug starts a local debug session', () async {
      final auth = MockFirebaseAuth();
      final container = ProviderContainer(
        overrides: [firebaseAuthProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.notifier).signInDebug();

      expect(container.read(authNotifierProvider), isA<AsyncData<void>>());
      expect(container.read(debugSessionProvider), isTrue);
      expect(auth.currentUser, isNull);

      await container.read(authNotifierProvider.notifier).signOut();
      expect(container.read(debugSessionProvider), isFalse);
    });

    test('signOut clears the current user', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(email: 'user@test.com'),
        signedIn: true,
      );
      final notifier = AuthNotifier(auth);

      await notifier.signOut();

      expect(notifier.state, isA<AsyncData<void>>());
      expect(auth.currentUser, isNull);
    });
  });
}
