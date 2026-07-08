import '/core/result/result.dart';
import '/data/repositories/auth/auth_repository.dart';
import '/domain/common/auth/models/app_user.dart';
import '../../services/auth/auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;

  AuthRepositoryImpl({required this._authService});

  @override
  AppUser? get currentUser => _authService.currentUser;

  @override
  bool get isAuthenticated => _authService.isAuthenticated;

  @override
  Stream<AppUser?> authStateChanges() => _authService.authStateChanges();

  @override
  AsyncResult<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  AsyncResult<AppUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _authService.registerWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
    );
  }

  @override
  AsyncResult<Unit> signOut() => _authService.signOut();
}
