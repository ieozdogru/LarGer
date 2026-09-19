import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

class DebugSession extends Notifier<bool> {
  @override
  bool build() => false;

  void enter() {
    if (kDebugMode) state = true;
  }

  void clear() {
    state = false;
  }
}

final debugSessionProvider = NotifierProvider<DebugSession, bool>(
  DebugSession.new,
);

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier(this._auth, [this._ref]) : super(const AsyncValue.data(null));

  final FirebaseAuth _auth;
  final Ref? _ref;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    });
  }

  Future<void> signInDebug() async {
    if (!kDebugMode) return;
    _ref?.read(debugSessionProvider.notifier).enter();
    state = const AsyncValue.data(null);
  }

  Future<void> signOut() async {
    if (kDebugMode) {
      _ref?.read(debugSessionProvider.notifier).clear();
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_auth.signOut);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
      return AuthNotifier(ref.watch(firebaseAuthProvider), ref);
    });
