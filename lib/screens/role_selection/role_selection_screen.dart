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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _gender;

  @override
  void dispose() {
    _phoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

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

    // Require DOB for all users (both Doctor and Patient)
    if (_dateOfBirth == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your Date of Birth')),
        );
      }
      return;
    }

    if (_gender == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your Gender')),
        );
      }
      return;
    }

    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your phone number')),
        );
      }
      return;
    }

    double? heightVal;
    double? weightVal;
    
    if (selectedRole == 'patient') {
      final hText = _heightController.text.trim();
      final wText = _weightController.text.trim();
      
      if (hText.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter your height')),
          );
        }
        return;
      }
      if (wText.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter your weight')),
          );
        }
        return;
      }
      
      heightVal = double.tryParse(hText);
      weightVal = double.tryParse(wText);
      
      if (heightVal == null || weightVal == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter valid numbers for height and weight')),
          );
        }
        return;
      }
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
          phoneNumber: phone,
          role: backendRole,
          dateOfBirth: _dateOfBirth!,
          gender: _gender!,
          height: heightVal,
          weight: weightVal,
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

        // If we don't have the backendId yet (e.g. user already existed),
        // fetch it from the /api/user/me endpoint using the JWT
        if (backendId == null) {
          try {
            final profile = await BackendAuthService.fetchCurrentUser();
            backendId = profile['id'] as int?;
            log(
              'Fetched backendId=$backendId from /user/me',
              name: 'RoleSelection',
            );
          } catch (e) {
            log('Failed to fetch user profile: $e', name: 'RoleSelection');
          }
        }
      } catch (e) {
        log('Back-end login failed: $e', name: 'RoleSelection');
      }

      final user = UserModel(
        id: firebaseUser.uid,
        backendId: backendId,
        fullName: fullName,
        email: email,
        phoneNumber: phone,
        role: role,
        dateOfBirth: _dateOfBirth,
        gender: _gender,
        height: heightVal,
        weight: weightVal,
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
        child: SingleChildScrollView(
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

              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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

              const SizedBox(height: 20),

              // Phone number field (shown only when a role is selected)
              AnimatedOpacity(
                opacity: selectedRole != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child:
                    selectedRole == null
                        ? const SizedBox.shrink()
                        : TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: const Icon(
                              Icons.phone,
                              color: AppColors.primaryBlue,
                            ),
                            filled: true,
                            fillColor: AppColors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
              ),
              const SizedBox(height: 20),

              // Date of Birth field
              AnimatedOpacity(
                opacity: selectedRole != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child:
                    selectedRole == null
                        ? const SizedBox.shrink()
                        : InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().subtract(
                                const Duration(days: 365 * 18),
                              ),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _dateOfBirth = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Date of Birth',
                              prefixIcon: const Icon(
                                Icons.calendar_today,
                                color: AppColors.primaryBlue,
                              ),
                              filled: true,
                              fillColor: AppColors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            child: Text(
                              _dateOfBirth == null
                                  ? 'Select Date of Birth'
                                  : '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
              ),
              const SizedBox(height: 20),

              // Gender Dropdown
              AnimatedOpacity(
                opacity: selectedRole != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child:
                    selectedRole == null
                        ? const SizedBox.shrink()
                        : DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Gender',
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: AppColors.primaryBlue,
                            ),
                            filled: true,
                            fillColor: AppColors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          value: _gender,
                          items: const [
                            DropdownMenuItem(
                              value: 'MALE',
                              child: Text('Male'),
                            ),
                            DropdownMenuItem(
                              value: 'FEMALE',
                              child: Text('Female'),
                            ),
                          ],
                          onChanged: (value) => setState(() => _gender = value),
                        ),
              ),
              const SizedBox(height: 20),

              // Height and Weight Fields (Patients Only)
              AnimatedOpacity(
                opacity: isPatient ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: !isPatient
                    ? const SizedBox.shrink()
                    : Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _heightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Height (cm)',
                                prefixIcon: const Icon(Icons.height, color: AppColors.primaryBlue),
                                filled: true,
                                fillColor: AppColors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.paddingM),
                          Expanded(
                            child: TextField(
                              controller: _weightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Weight (kg)',
                                prefixIcon: const Icon(Icons.monitor_weight_outlined, color: AppColors.primaryBlue),
                                filled: true,
                                fillColor: AppColors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              if (isPatient) const SizedBox(height: 20),

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
      ),
    );
  }
}
