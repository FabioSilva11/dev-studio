import 'package:firebase_auth/firebase_auth.dart';

import '/core/result/result.dart';
import '/domain/common/auth/models/app_user.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;

  AuthService({
    required FirebaseAuth firebaseAuth,
  }) : _firebaseAuth = firebaseAuth;

  AppUser? get currentUser => _mapUser(_firebaseAuth.currentUser);

  bool get isAuthenticated => _firebaseAuth.currentUser != null;

  Stream<AppUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(_mapUser);
  }

  AsyncResult<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = _mapUser(credential.user);
      if (user == null) {
        return const Failure(
          AppError(
            code: AppErrorCode.unexpected,
            message: 'Authentication succeeded but user is null.',
          ),
        );
      }

      return Success(user);
    } on FirebaseAuthException catch (error) {
      return Failure(_mapFirebaseAuthError(error));
    } catch (error) {
      return Failure(
        AppError(
          code: AppErrorCode.unexpected,
          message: 'Unexpected authentication error.',
          details: error,
        ),
      );
    }
  }

  AsyncResult<AppUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (displayName != null && displayName.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(displayName.trim());
        await credential.user?.reload();
      }

      final user = _mapUser(_firebaseAuth.currentUser ?? credential.user);
      if (user == null) {
        return const Failure(
          AppError(
            code: AppErrorCode.unexpected,
            message: 'Registration succeeded but user is null.',
          ),
        );
      }

      return Success(user);
    } on FirebaseAuthException catch (error) {
      return Failure(_mapFirebaseAuthError(error));
    } catch (error) {
      return Failure(
        AppError(
          code: AppErrorCode.unexpected,
          message: 'Unexpected registration error.',
          details: error,
        ),
      );
    }
  }

  AsyncResult<Unit> signOut() async {
    try {
      await _firebaseAuth.signOut();
      return const Success(unit);
    } on FirebaseAuthException catch (error) {
      return Failure(_mapFirebaseAuthError(error));
    } catch (error) {
      return Failure(
        AppError(
          code: AppErrorCode.unexpected,
          message: 'Unexpected sign out error.',
          details: error,
        ),
      );
    }
  }

  AppUser? _mapUser(User? user) {
    if (user == null) return null;

    return AppUser(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
      isEmailVerified: user.emailVerified,
    );
  }

  AppError _mapFirebaseAuthError(FirebaseAuthException error) {
    final code = switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => AppErrorCode.unauthenticated,
      'invalid-email' ||
      'weak-password' ||
      'email-already-in-use' => AppErrorCode.invalidData,
      'network-request-failed' => AppErrorCode.networkError,
      'too-many-requests' => AppErrorCode.timeout,
      _ => AppErrorCode.unexpected,
    };

    return AppError(
      code: code,
      message: error.message ?? 'Firebase auth error: ${error.code}',
      details: error,
    );
  }
}
