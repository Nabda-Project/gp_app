import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Get current Firebase user
  static User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ==================== EMAIL/PASSWORD AUTH ====================

  /// Sign in with email and password
  static Future<UserCredential> signInWithEmail(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Register with email and password
  static Future<UserCredential> registerWithEmail(
    String email,
    String password,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ==================== GOOGLE SIGN-IN ====================

  /// Sign in with Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      log("Starting Google Sign-In...", name: 'AuthService');
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        log("Google Sign-In cancelled by user.", name: 'AuthService');
        return null;
      }
      log("Google Account obtained: ${googleUser.email}", name: 'AuthService');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      log("Google Auth tokens obtained.", name: 'AuthService');

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      log(
        "Signing in to Firebase with Google credential...",
        name: 'AuthService',
      );
      final userCred = await _auth.signInWithCredential(credential);
      log(
        "Firebase Sign-In successful: ${userCred.user?.uid}",
        name: 'AuthService',
      );
      return userCred;
    } catch (e) {
      log("Google Sign-In Error: $e", name: 'AuthService', error: e);
      rethrow;
    }
  }

  // ==================== SIGN OUT ====================

  /// Sign out from all providers
  /// Sign out from all providers
  static Future<void> signOut() async {
    log("Executing signOut...", name: 'AuthService');
    try {
      await _googleSignIn.signOut();
      log("Google Sign-Out successful.", name: 'AuthService');
    } catch (e) {
      log("Google Sign-Out error (ignoring): $e", name: 'AuthService');
    }

    try {
      await _auth.signOut();
      log("Firebase Sign-Out successful.", name: 'AuthService');
    } catch (e) {
      log("Firebase Sign-Out error: $e", name: 'AuthService', error: e);
    }
  }
}
