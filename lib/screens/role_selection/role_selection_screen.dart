import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants.dart';
import '../../widgets/reusable/custom_card.dart';
import '../../widgets/reusable/custom_button.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../services/backend_auth_service.dart';
import '../../services/token_service.dart';
import '../../models/user_model.dart';
import '../../models/register_request.dart';
import '../../models/login_request.dart';
import '../../core/api/api_exceptions.dart';
import '../../widgets/animations/fade_slide_transition.dart';
import '../../widgets/animations/animated_list_item.dart';
import 'dart:developer';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? selectedRole;
  bool _isLoading = false;

  void _selectRole(String role) {
    setState(() {
      selectedRole = role;
    });
  }

  Future<void> _confirmRole() async {
    if (selectedRole == null) return;

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      Navigator.pushReplacementNamed(context, '/auth');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final role = selectedRole == 'doctor' ? 'Doctor' : 'Patient';
      final backendRole = role == 'Doctor' ? 'DOCTOR' : 'PATIENT';
      final email = firebaseUser.email ?? '';
      final fullName = firebaseUser.displayName ?? 'User';
      // For Google Sign-In users, use deterministic password
      final generatedPassword = 'GoogleAuth_${firebaseUser.uid}';

      // Try to register on back-end (may already exist from Google Sign-In)
      int? backendId;
      try {
        final registerRequest = RegisterRequest(
          fullName: fullName,
          email: email,
          password: generatedPassword,
          phoneNumber: '',
          role: backendRole,
        );
        final backendUser = await BackendAuthService.register(registerRequest);
        backendId = backendUser['id'] as int?;
        log('Back-end registration successful', name: 'RoleSelection');
      } on ConflictException {
        log('User already exists on back-end', name: 'RoleSelection');
      } catch (e) {
        log('Back-end registration failed: $e', name: 'RoleSelection');
      }

      // Login to back-end for JWT
      try {
        final loginRequest = LoginRequest(
          email: email,
          password: generatedPassword,
        );
        final authResponse = await BackendAuthService.login(loginRequest);
        await TokenService.saveToken(authResponse.token);
        await TokenService.saveCredentials(email, generatedPassword);
        log('JWT obtained', name: 'RoleSelection');
      } catch (e) {
        log('Back-end login failed: $e', name: 'RoleSelection');
      }

      final user = UserModel(
        id: firebaseUser.uid,
        backendId: backendId,
        fullName: fullName,
        email: email,
        role: role,
      );

      // Save to Firestore
      await FirestoreService.saveUser(user);
      // Save locally
      await StorageService.saveUser(user);

      if (mounted) {
        if (selectedRole == 'doctor') {
          Navigator.pushReplacementNamed(context, '/doctor_dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/patient_dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Basic localization fallback if needed
    final isDoctor = selectedRole == 'doctor';
    final isPatient = selectedRole == 'patient';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // iconTheme: const IconThemeData(color: AppColors.darkBlue),
        automaticallyImplyLeading: false, // Don't allow going back to auth
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppDimensions.paddingM),
            FadeSlideTransition(
              delay: const Duration(milliseconds: 100),
              child: Text(
                "Choose your account type",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBlue,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 50),

            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedListItem(
                      index: 0,
                      child: CustomCard(
                        label: "Doctor",
                        icon: Icons.local_hospital,
                        isSelected: isDoctor,
                        onTap: () => _selectRole('doctor'),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingM),
                  Expanded(
                    child: AnimatedListItem(
                      index: 1,
                      child: CustomCard(
                        label: "Patient",
                        icon: Icons.person,
                        isSelected: isPatient,
                        onTap: () => _selectRole('patient'),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Only show continue button if a role is selected
            AnimatedOpacity(
              opacity: selectedRole != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: CustomButton(
                text: "Continue as ${isDoctor ? 'Doctor' : 'Patient'}",
                isLoading: _isLoading,
                onPressed: selectedRole != null ? _confirmRole : () {},
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
