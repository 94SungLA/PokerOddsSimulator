import 'package:firebase_auth/firebase_auth.dart' as fb;

class AuthUser {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final bool isGuest;

  const AuthUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    required this.isGuest,
  });

  factory AuthUser.fromFirebaseUser(fb.User user) {
    return AuthUser(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
      isGuest: false,
    );
  }

  factory AuthUser.guest() {
    return const AuthUser(
      uid: 'guest_user_123',
      displayName: '德州撲克學習者 (Guest)',
      email: 'student@pokerlab.edu',
      photoUrl: null,
      isGuest: true,
    );
  }
}
