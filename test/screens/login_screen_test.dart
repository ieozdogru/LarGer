import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larger/providers/auth_provider.dart';
import 'package:larger/screens/login_screen.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

void main() {
  Widget buildLoginApp() {
    final mockAuth = MockFirebaseAuth();

    return ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(mockAuth),
        authNotifierProvider.overrideWith(
          (ref) => AuthNotifier(mockAuth),
        ),
      ],
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  testWidgets('shows sign-in UI by default', (tester) async {
    await tester.pumpWidget(buildLoginApp());

    expect(find.text('LarGer'), findsOneWidget);
    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);
    expect(find.text('Confirm password'), findsNothing);
  });

  testWidgets('toggles to create-account mode', (tester) async {
    await tester.pumpWidget(buildLoginApp());

    await tester.tap(find.text('Need an account? Create one'));
    await tester.pump();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('CREATE ACCOUNT'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
  });

  testWidgets('shows validation errors for empty sign-in form', (tester) async {
    await tester.pumpWidget(buildLoginApp());

    await tester.tap(find.text('SIGN IN'));
    await tester.pump();

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('shows password length validation', (tester) async {
    await tester.pumpWidget(buildLoginApp());

    await tester.enterText(find.byType(TextFormField).at(0), 'user@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.text('SIGN IN'));
    await tester.pump();

    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });

  testWidgets('signs in with valid credentials', (tester) async {
    final mockAuth = MockFirebaseAuth();
    await mockAuth.createUserWithEmailAndPassword(
      email: 'user@test.com',
      password: '123456',
    );
    await mockAuth.signOut();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockAuth),
          authNotifierProvider.overrideWith((ref) => AuthNotifier(mockAuth)),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'user@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text('SIGN IN'));
    await tester.pumpAndSettle();

    expect(mockAuth.currentUser?.email, 'user@test.com');
    expect(find.text('Incorrect email or password.'), findsNothing);
  });

  testWidgets('shows snackbar on failed sign in', (tester) async {
    final mockAuth = MockFirebaseAuth();
    whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
        .on(mockAuth)
        .thenThrow(FirebaseAuthException(code: 'invalid-credential'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockAuth),
          authNotifierProvider.overrideWith((ref) => AuthNotifier(mockAuth)),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'user@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'bad-password');
    await tester.tap(find.text('SIGN IN'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });

  testWidgets('creates an account from sign-up mode', (tester) async {
    final mockAuth = MockFirebaseAuth();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockAuth),
          authNotifierProvider.overrideWith((ref) => AuthNotifier(mockAuth)),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.text('Need an account? Create one'));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'new@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.enterText(find.byType(TextFormField).at(2), '123456');
    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pumpAndSettle();

    expect(mockAuth.currentUser?.email, 'new@test.com');
  });

  testWidgets('toggles password visibility icon', (tester) async {
    await tester.pumpWidget(buildLoginApp());

    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });
}
