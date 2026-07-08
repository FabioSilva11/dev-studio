import '/core/result/result.dart';
import '/domain/common/auth/models/app_user.dart';

abstract class AuthRepository {
  AppUser? get currentUser;

  bool get isAuthenticated;

  Stream<AppUser?> authStateChanges();

  AsyncResult<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  AsyncResult<AppUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  AsyncResult<Unit> signOut();
}
