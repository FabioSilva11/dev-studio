class AppUser {
  final String id;
  final String? email;
  final String? displayName;
  final bool isEmailVerified;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.isEmailVerified,
  });
}
