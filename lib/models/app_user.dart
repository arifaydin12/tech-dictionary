/// The signed-in user (a Firebase account, or a local guest in demo mode).
class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    this.email,
    this.isGuest = false,
  });

  final String id;
  final String displayName;
  final String? email;
  final bool isGuest;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }
}
