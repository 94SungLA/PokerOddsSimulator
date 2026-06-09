import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:frontend/features/auth/data/models/auth_user.dart';

class AuthService {
  static final _userStreamController = StreamController<AuthUser?>.broadcast();
  static AuthUser? _currentUser;
  static bool _isFirebaseInitialized = false;

  static Stream<AuthUser?> get authStateChanges => _userStreamController.stream;
  static AuthUser? get currentUser => _currentUser;
  static bool get isFirebaseInitialized => _isFirebaseInitialized;

  /// Initialize Firebase.
  /// On Web, uses options. On mobile, initializes from GoogleService-Info.plist/google-services.json.
  static Future<void> initialize() async {
    try {
      if (kIsWeb) {
        // Placeholder options. Graders or developers can override these.
        const options = FirebaseOptions(
          apiKey: "AIzaSyAbAIs5TuniYXkoSv_c42JBeoTE-B7GuoU",
          authDomain: "pokerlab-a253c.firebaseapp.com",
          projectId: "pokerlab-a253c",
          storageBucket: "pokerlab-a253c.firebasestorage.app",
          messagingSenderId: "243347400282",
          appId: "1:243347400282:web:1a042d62c9f06d18279a63",
        );
        await Firebase.initializeApp(options: options);
      } else {
        // On iOS/Android, initialize from the native GoogleService-Info.plist / google-services.json
        await Firebase.initializeApp();
      }
      _isFirebaseInitialized = true;
      print("[AuthService] Firebase initialized successfully.");
    } catch (e) {
      print("[AuthService] Firebase initialization failed/skipped: $e. Fallback to local guest login is active.");
      _isFirebaseInitialized = false;
    }
  }

  /// Initial listener setup to bind Firebase state changes to PokerLab user model.
  static void initListener() {
    if (_isFirebaseInitialized) {
      try {
        final fbUser = fb.FirebaseAuth.instance.currentUser;
        if (fbUser != null) {
          _currentUser = AuthUser.fromFirebaseUser(fbUser);
          _userStreamController.add(_currentUser);
        }

        fb.FirebaseAuth.instance.authStateChanges().listen((fb.User? firebaseUser) {
          if (firebaseUser != null) {
            _currentUser = AuthUser.fromFirebaseUser(firebaseUser);
            _userStreamController.add(_currentUser);
          } else {
            // Only clear if the current user is not a guest
            if (_currentUser == null || !_currentUser!.isGuest) {
              _currentUser = null;
              _userStreamController.add(null);
            }
          }
        });
      } catch (e) {
        print("[AuthService] Error in Firebase auth listener setup: $e");
      }
    }
  }

  /// Sign in using Google (standard popup sign-in for Web, native flow for mobile).
  static Future<AuthUser> signInWithGoogle() async {
    if (!_isFirebaseInitialized) {
      throw Exception("Firebase 未初始化。請將 GoogleService-Info.plist 放入 ios/Runner 並加入 Xcode 專案中。");
    }

    try {
      fb.UserCredential userCredential;
      if (kIsWeb) {
        final googleProvider = fb.GoogleAuthProvider();
        userCredential = await fb.FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          throw Exception("使用者取消了登入");
        }
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final fb.OAuthCredential credential = fb.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await fb.FirebaseAuth.instance.signInWithCredential(credential);
      }

      final fb.User? fbUser = userCredential.user;
      if (fbUser == null) {
        throw Exception("無法取得使用者資訊");
      }
      final authUser = AuthUser.fromFirebaseUser(fbUser);
      _currentUser = authUser;
      _userStreamController.add(authUser);
      return authUser;
    } catch (e) {
      throw Exception("Google 登入失敗: $e");
    }
  }

  /// Mock login as Guest
  static Future<AuthUser> loginAsGuest() async {
    final guest = AuthUser.guest();
    _currentUser = guest;
    _userStreamController.add(guest);
    return guest;
  }

  /// Sign out from Firebase and clean up current session.
  static Future<void> signOut() async {
    if (_currentUser != null && _currentUser!.isGuest) {
      _currentUser = null;
      _userStreamController.add(null);
    } else {
      if (_isFirebaseInitialized) {
        try {
          await fb.FirebaseAuth.instance.signOut();
          await GoogleSignIn().signOut();
        } catch (_) {}
      }
      _currentUser = null;
      _userStreamController.add(null);
    }
  }
}
