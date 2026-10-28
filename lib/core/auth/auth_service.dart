import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../firebase/firebase_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  FirebaseAuth? get _auth {
    if (!FirebaseService.instance.isInitialized) return null;
    return FirebaseAuth.instance;
  }

  /// Current authenticated Firebase user (null if not logged in or Firebase offline)
  User? get currentUser => _auth?.currentUser;

  /// Stream of user auth state changes
  Stream<User?> get authStateChanges {
    if (_auth == null) {
      return Stream.value(null);
    }
    return _auth!.authStateChanges();
  }

  /// Sign in with Google OAuth on Android / iOS
  Future<UserCredential?> signInWithGoogle({String? serverClientId}) async {
    try {
      // Re-init GoogleSignIn if a custom serverClientId is specified
      final googleSignIn = serverClientId != null && serverClientId.isNotEmpty
          ? GoogleSignIn(serverClientId: serverClientId, scopes: ['email', 'profile'])
          : _googleSignIn;

      // 1. Trigger the native Google Account chooser modal
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[AuthService] User cancelled Google Sign-In');
        return null;
      }

      // 2. Obtain auth tokens from Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (_auth == null) {
        throw Exception('Firebase is not initialized yet. Please add google-services.json.');
      }

      // 3. Create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Authenticate with Firebase
      final userCredential = await _auth!.signInWithCredential(credential);
      debugPrint('[AuthService] Successfully signed in: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('[AuthService] Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Sign out from both Firebase and Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth?.signOut();
      debugPrint('[AuthService] Signed out successfully');
    } catch (e) {
      debugPrint('[AuthService] Sign-Out Error: $e');
    }
  }
}
