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
      print("Starting Google Sign-In...");
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        print("Google Sign-In cancelled by user.");
        return null;
      }
      print("Google Account obtained: ${googleUser.email}");

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print("Google Auth tokens obtained.");

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      print("Signing in to Firebase with Google credential...");
      final userCred = await _auth.signInWithCredential(credential);
      print("Firebase Sign-In successful: ${userCred.user?.uid}");
      return userCred;
    } catch (e) {
      print("Google Sign-In Error: $e");
      rethrow;
    }
  }

  // ==================== SIGN OUT ====================

  /// Sign out from all providers
  /// Sign out from all providers
  static Future<void> signOut() async {
    print("DEBUG: Executing signOut...");
    try {
      await _googleSignIn.signOut();
      print("DEBUG: Google Sign-Out successful.");
    } catch (e) {
      print("DEBUG: Google Sign-Out error (ignoring): $e");
    }

    try {
      await _auth.signOut();
      print("DEBUG: Firebase Sign-Out successful.");
    } catch (e) {
      print("DEBUG: Firebase Sign-Out error: $e");
    }
  }
}
