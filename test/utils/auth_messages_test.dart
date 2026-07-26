import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larger/utils/auth_messages.dart';

void main() {
  group('friendlyAuthError', () {
    test('maps invalid credential to generic login failure', () {
      final error = FirebaseAuthException(code: 'invalid-credential');
      expect(friendlyAuthError(error), 'Incorrect email or password.');
    });

    test('maps email already in use', () {
      final error = FirebaseAuthException(code: 'email-already-in-use');
      expect(
        friendlyAuthError(error),
        'An account already exists for that email.',
      );
    });

    test('maps weak password', () {
      final error = FirebaseAuthException(code: 'weak-password');
      expect(
        friendlyAuthError(error),
        'Password is too weak. Use at least 6 characters.',
      );
    });

    test('maps remaining auth codes', () {
      expect(
        friendlyAuthError(FirebaseAuthException(code: 'invalid-email')),
        'That email address looks invalid.',
      );
      expect(
        friendlyAuthError(FirebaseAuthException(code: 'user-disabled')),
        'This account has been disabled.',
      );
      expect(
        friendlyAuthError(FirebaseAuthException(code: 'user-not-found')),
        'Incorrect email or password.',
      );
      expect(
        friendlyAuthError(FirebaseAuthException(code: 'wrong-password')),
        'Incorrect email or password.',
      );
      expect(
        friendlyAuthError(FirebaseAuthException(code: 'network-request-failed')),
        'Network error. Check your connection.',
      );
      expect(
        friendlyAuthError(FirebaseAuthException(code: 'operation-not-allowed')),
        'Email/password sign-in is not enabled in Firebase.',
      );
    });

    test('maps unknown FirebaseAuthException message', () {
      final error = FirebaseAuthException(
        code: 'something-else',
        message: 'Custom failure',
      );
      expect(friendlyAuthError(error), 'Custom failure');
    });

    test('maps non-auth errors to generic failure', () {
      expect(friendlyAuthError(Exception('boom')), 'Authentication failed.');
    });
  });
}
