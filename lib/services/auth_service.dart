import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../models/register_request.dart';
import '../models/login_request.dart';
import '../services/backend_auth_service.dart';
import '../services/token_service.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';

/// Orchestrates the hybrid authentication flow:
///   Firebase Auth (identity) + Back-end JWT (API access).
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================================================================
  //  Sign Out (clears both Firebase session and back-end JWT)
  // =========================================================================

  static Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
    await TokenService.clearAll();
    log('Signed out of Firebase + cleared JWT', name: 'AuthService');
  }

  // =========================================================================
  //  PASSWORD RESET (Firebase-only feature)
  // =========================================================================

  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // =========================================================================
  //  REGISTRATION — Back-end first, then Firebase
  //  (if back-end rejects, we don't create a Firebase user)
  // =========================================================================

  /// Full registration flow:
  /// 1) POST /api/auth/register  → creates user in PostgreSQL
  /// 2) Firebase createUser       → creates Firebase identity
  /// 3) POST /api/auth/login      → obtains JWT
  /// 4) Save user + JWT locally
  ///
  /// Returns the created [UserModel].
  static Future<UserModel> registerWithEmailAndPassword({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String role, // 'Doctor' or 'Patient' (title-case from UI)
  }) async {
    // ── 1. Register on back-end (source of truth) ──
    final backendRole = role == 'Doctor' ? 'DOCTOR' : 'PATIENT';
    final registerRequest = RegisterRequest(
      fullName: fullName,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
      role: backendRole,
    );

    Map<String, dynamic> backendUser;
    try {
      backendUser = await BackendAuthService.register(registerRequest);
    } catch (e) {
      log('Back-end registration failed: $e', name: 'AuthService');
      rethrow; // Let UI handle (e.g., ConflictException = email exists)
    }

    // ── 2. Create Firebase user ──
    UserCredential firebaseCred;
    try {
      firebaseCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await firebaseCred.user?.updateDisplayName(fullName);
    } on FirebaseAuthException catch (e) {
      // If Firebase rejects (e.g., email already in use), we still have the
      // back-end user created. This is acceptable – next login will reconcile.
      log('Firebase createUser failed (back-end user exists): ${e.message}',
          name: 'AuthService');
      // Try to sign in instead (the back-end user was created successfully)
      try {
        firebaseCred = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (signInError) {
        rethrow;
      }
    }

    // ── 3. Login to back-end to get JWT ──
    final loginRequest = LoginRequest(email: email, password: password);
    final authResponse = await BackendAuthService.login(loginRequest);
    await TokenService.saveToken(authResponse.token);
    await TokenService.saveCredentials(email, password);

    // ── 4. Build UserModel and persist ──
    final user = UserModel.fromBackendJson(
      backendUser,
      firebaseUid: firebaseCred.user?.uid,
    );

    // Save to Firestore (for existing Firestore-dependent features)
    try {
      await FirestoreService.saveUser(user);
    } catch (e) {
      log('Firestore save failed (non-critical): $e', name: 'AuthService');
    }

    // Save to local Hive storage
    await StorageService.saveUser(user);

    log('Registration complete: ${user.email} (backendId=${user.backendId})',
        name: 'AuthService');
    return user;
  }

  // =========================================================================
  //  EMAIL / PASSWORD LOGIN — Firebase first, then back-end JWT
  // =========================================================================

  /// Hybrid login flow:
  /// 1) Firebase signIn     → verifies identity
  /// 2) POST /api/auth/login → obtains JWT
  /// 3) Save JWT + refresh local user data
  ///
  /// Returns the [UserModel].
  static Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // ── 1. Firebase login ──
    final UserCredential cred;
    try {
      cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      log('Firebase login failed: ${e.message}', name: 'AuthService');
      rethrow;
    }

    // ── 2. Back-end login for JWT ──
    final loginRequest = LoginRequest(email: email, password: password);
    try {
      final authResponse = await BackendAuthService.login(loginRequest);
      await TokenService.saveToken(authResponse.token);
      await TokenService.saveCredentials(email, password);
      log('Back-end JWT obtained', name: 'AuthService');
    } catch (e) {
      log('Back-end login failed (JWT not obtained): $e', name: 'AuthService');
      // Continue – user can still use Firebase-only features
      // But API calls will fail without JWT
    }

    // ── 3. Load / refresh user data ──
    UserModel? user = StorageService.getUser();
    if (user == null || user.email != email) {
      // Try loading from Firestore
      try {
        user = await FirestoreService.getUser(cred.user!.uid);
      } catch (e) {
        log('Firestore user fetch failed: $e', name: 'AuthService');
      }
    }

    // If still no user data, create a minimal model from Firebase
    user ??= UserModel(
      id: cred.user!.uid,
      fullName: cred.user!.displayName ?? 'User',
      email: email,
      role: 'Patient', // Default; will be corrected on role selection
    );

    // If backendId is missing, try to fetch it from the back-end
    UserModel finalUser = user;
    if (finalUser.backendId == null) {
      try {
        final profile = await BackendAuthService.fetchCurrentUser();
        final backendId = profile['id'] as int?;
        final backendRole = profile['role'] as String? ?? 'PATIENT';
        finalUser = finalUser.copyWith(
          backendId: backendId,
          role: backendRole == 'DOCTOR' ? 'Doctor' : 'Patient',
        );
        log('Fetched backendId=$backendId from /user/me', name: 'AuthService');
      } catch (e) {
        log('Failed to fetch back-end profile: $e', name: 'AuthService');
      }
    }

    await StorageService.saveUser(finalUser);
    return finalUser;
  }

  // =========================================================================
  //  GOOGLE SIGN-IN — Firebase auth only, backend handled by role selection
  // =========================================================================

  /// Google Sign-In hybrid flow:
  /// 1) Google OAuth → Firebase credential
  /// 2) For returning users: login to back-end for JWT + fetch profile
  /// 3) For new users: no back-end action (role selection will handle it)
  ///
  /// Returns `null` if user cancels the Google picker.
  /// New users will be directed to role selection by the calling screen.
  static Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // User cancelled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final firebaseUser = userCredential.user!;

    // Use Firebase UID as a deterministic "password" for the back-end account
    final generatedPassword = 'GoogleAuth_${firebaseUser.uid}';
    final email = firebaseUser.email ?? '';
    final fullName = firebaseUser.displayName ?? 'User';

    // Do NOT register on back-end here — let role selection handle that
    // so the user can choose their role (Doctor or Patient).
    // Only try to LOGIN for returning users who already registered.
    try {
      final loginRequest = LoginRequest(
        email: email,
        password: generatedPassword,
      );
      final authResponse = await BackendAuthService.login(loginRequest);
      await TokenService.saveToken(authResponse.token);
      await TokenService.saveCredentials(email, generatedPassword);
      log('Google user JWT obtained (returning user)', name: 'AuthService');

      // Fetch the user profile from back-end to get the backendId
      try {
        final backendProfile = await BackendAuthService.fetchCurrentUser();
        final backendId = backendProfile['id'] as int?;
        final backendRole = backendProfile['role'] as String? ?? 'PATIENT';
        final role = backendRole == 'DOCTOR' ? 'Doctor' : 'Patient';

        final user = UserModel(
          id: firebaseUser.uid,
          backendId: backendId,
          fullName: fullName,
          email: email,
          role: role,
        );
        await StorageService.saveUser(user);

        // Also save to Firestore for consistency
        try {
          await FirestoreService.saveUser(user);
        } catch (e) {
          log('Firestore save failed (non-critical): $e', name: 'AuthService');
        }

        log('Google sign-in complete: $email (backendId=$backendId)',
            name: 'AuthService');
      } catch (e) {
        log('Failed to fetch back-end profile: $e', name: 'AuthService');
      }
    } catch (e) {
      // Login failed = new user who hasn't registered on back-end yet.
      // That's expected — role selection screen will handle registration.
      log('Google back-end login failed (new user): $e', name: 'AuthService');
    }

    return userCredential;
  }

  // =========================================================================
  //  TOKEN REFRESH — Re-login when JWT expires (no refresh endpoint)
  // =========================================================================

  /// Attempt to re-login to the back-end using stored credentials.
  /// Call this when a 401 is encountered.
  static Future<bool> refreshBackendToken() async {
    final credentials = await TokenService.getCredentials();
    if (credentials == null) return false;

    try {
      final loginRequest = LoginRequest(
        email: credentials['email']!,
        password: credentials['password']!,
      );
      final authResponse = await BackendAuthService.login(loginRequest);
      await TokenService.saveToken(authResponse.token);
      log('JWT refreshed successfully', name: 'AuthService');
      return true;
    } catch (e) {
      log('JWT refresh failed: $e', name: 'AuthService');
      return false;
    }
  }
}
