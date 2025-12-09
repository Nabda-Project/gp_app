import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants.dart';
import '../../widgets/reusable/custom_card.dart';
import '../../widgets/reusable/custom_button.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../models/user_model.dart';

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
      // Should not happen here, but handle safely
      Navigator.pushReplacementNamed(context, '/auth');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = UserModel(
        id: firebaseUser.uid,
        fullName: firebaseUser.displayName ?? 'User',
        email: firebaseUser.email ?? '',
        role: selectedRole == 'doctor' ? 'Doctor' : 'Patient',
        // Note: For doctors via Google, license might be collected later or assumed optional for now
      );

      // Save to Firestore
      await FirestoreService.saveUser(user);

      // Save locally (optional, for offline/quick access)
      await StorageService.saveUser(user);

      if (mounted) {
        if (selectedRole == 'doctor') {
          Navigator.pushReplacementNamed(context, '/doctor_dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/patient_dashboard');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
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
            Text(
              "Choose your account type",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),

            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: CustomCard(
                      label: "Doctor",
                      icon: Icons.local_hospital,
                      isSelected: isDoctor,
                      onTap: () => _selectRole('doctor'),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingM),
                  Expanded(
                    child: CustomCard(
                      label: "Patient",
                      icon: Icons.person,
                      isSelected: isPatient,
                      onTap: () => _selectRole('patient'),
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
