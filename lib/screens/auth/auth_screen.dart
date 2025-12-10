import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants.dart';
import '../../widgets/reusable/app_logo.dart';
import '../../widgets/reusable/custom_button.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../services/notification_service.dart';
import '../../utils/app_localizations.dart';
import '../../widgets/animations/fade_slide_transition.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  String _selectedRole = 'Patient';
  bool _isLoading = false;

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerLicenseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerLicenseController.dispose();
    super.dispose();
  }

  void _setLoading(bool value) {
    if (mounted) setState(() => _isLoading = value);
  }

  void _showError(String message) {
    if (!mounted) return;
    NotificationService.showError(title: 'Error', message: message);
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    NotificationService.showSuccess(title: 'Success', message: message);
  }

  Future<void> _handleAuthSuccess(
    User firebaseUser,
    String? role, {
    String? license,
  }) async {
    print(
      "DEBUG: _handleAuthSuccess started. Role: $role, User: ${firebaseUser.uid}",
    );
    try {
      if (role != null) {
        // REGISTRATION FLOW (Role is known)
        print("DEBUG: Registration flow. Creating user model...");
        final user = UserModel(
          id: firebaseUser.uid,
          fullName: firebaseUser.displayName ?? 'User',
          email: firebaseUser.email ?? '',
          role: role,
          licenseNumber: license,
        );

        // Save to Firestore & Local Storage
        print("DEBUG: Saving to Firestore...");
        await FirestoreService.saveUser(user);
        print("DEBUG: Saved to Firestore. Saving to local storage...");
        await StorageService.saveUser(user);
        print("DEBUG: Saved to local storage. Navigating...");

        if (mounted) {
          _navigateToDashboard(role);
        }
      } else {
        // LOGIN FLOW (Role unknown, check Firestore)
        print("DEBUG: Login flow. checking Firestore for user...");
        final existingUser = await FirestoreService.getUser(firebaseUser.uid);
        print("DEBUG: Firestore check complete. Result: ${existingUser?.role}");

        if (existingUser != null) {
          // Returning user -> Save to local storage & Navigate
          print("DEBUG: Saving existing user to local storage...");
          await StorageService.saveUser(existingUser);
          if (mounted) {
            _navigateToDashboard(existingUser.role);
          }
        } else {
          // New user via Google/Phone -> Go to Role Selection
          print("DEBUG: User not found in Firestore. Going to Role Selection.");
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/role_selection');
          }
        }
      }
    } catch (e, stack) {
      print("DEBUG: Error in _handleAuthSuccess: $e");
      print("DEBUG: Stack trace: $stack");
      _showError("Error fetching user profile: $e");
    } finally {
      print("DEBUG: _handleAuthSuccess completed.");
    }
  }

  void _navigateToDashboard(String role) {
    if (role == 'Doctor') {
      Navigator.pushReplacementNamed(context, '/doctor_dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/patient_dashboard');
    }
  }

  // ==================== EMAIL/PASSWORD LOGIN ====================
  Future<void> _handleEmailLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    _setLoading(true);
    try {
      final credential = await AuthService.signInWithEmail(
        _loginEmailController.text.trim(),
        _loginPasswordController.text,
      );
      if (credential.user != null) {
        await _handleAuthSuccess(credential.user!, null);
      }
    } on FirebaseAuthException catch (e) {
      _showError(_getAuthErrorMessage(e.code));
    } catch (e) {
      _showError('Login failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== EMAIL/PASSWORD REGISTER ====================
  Future<void> _handleEmailRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    _setLoading(true);
    try {
      final credential = await AuthService.registerWithEmail(
        _registerEmailController.text.trim(),
        _passwordController.text,
      );

      // Update display name
      await credential.user?.updateDisplayName(
        _registerNameController.text.trim(),
      );

      if (credential.user != null) {
        final role =
            _selectedRole == AppLocalizations.of(context)!.get('doctor')
                ? 'Doctor'
                : 'Patient';
        final license =
            role == 'Doctor' ? _registerLicenseController.text : null;
        await _handleAuthSuccess(credential.user!, role, license: license);
      }
    } on FirebaseAuthException catch (e) {
      _showError(_getAuthErrorMessage(e.code));
    } catch (e) {
      _showError('Registration failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== GOOGLE SIGN-IN ====================
  Future<void> _handleGoogleSignIn() async {
    _setLoading(true);
    try {
      final credential = await AuthService.signInWithGoogle();
      if (credential?.user != null) {
        // Pass null for role to trigger Firestore check
        await _handleAuthSuccess(credential!.user!, null);
      }
    } on FirebaseAuthException catch (e) {
      _showError(_getAuthErrorMessage(e.code));
    } catch (e) {
      _showError('Google Sign-In failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== FORGOT PASSWORD ====================
  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(AppLocalizations.of(context)!.get('resetPassword')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context)!.get('resetPasswordDesc')),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    )!.get('emailAddress'),
                    prefixIcon: const Icon(
                      Icons.email,
                      color: AppColors.primaryBlue,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.get('cancel')),
              ),
              ElevatedButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (email.isEmpty || !email.contains('@')) {
                    _showError(AppLocalizations.of(context)!.get('validEmail'));
                    return;
                  }
                  Navigator.pop(context);
                  _setLoading(true);
                  try {
                    await AuthService.sendPasswordResetEmail(email);
                    _showSuccess(
                      'Password reset email sent! Check your inbox.',
                    );
                  } on FirebaseAuthException catch (e) {
                    _showError(_getAuthErrorMessage(e.code));
                  } catch (e) {
                    _showError('Failed to send reset email: $e');
                  } finally {
                    _setLoading(false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.get('sendResetLink'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      case 'invalid-verification-code':
        return 'Invalid OTP code';
      case 'invalid-phone-number':
        return 'Invalid phone number';
      default:
        return 'Authentication error: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            children: [
              const SizedBox(height: 20),
              FadeSlideTransition(
                delay: const Duration(milliseconds: 100),
                child: const AppLogo(size: 100),
              ),
              const SizedBox(height: AppDimensions.paddingL),
              FadeSlideTransition(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  AppLocalizations.of(context)!.get('accessAccount'),
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingL),
              FadeSlideTransition(
                delay: const Duration(milliseconds: 300),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryBlue,
                  unselectedLabelColor: AppColors.grey,
                  indicatorColor: AppColors.primaryBlue,
                  tabs: [
                    Tab(text: AppLocalizations.of(context)!.get('login')),
                    Tab(
                      text: AppLocalizations.of(context)!.get('createAccount'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.paddingL),
              FadeSlideTransition(
                delay: const Duration(milliseconds: 400),
                child: SizedBox(
                  height: 520,
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildLoginForm(), _buildRegisterForm()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          _buildTextField(
            AppLocalizations.of(context)!.get('emailAddress'),
            Icons.email,
            controller: _loginEmailController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.get('enterEmail');
              }
              if (!value.contains('@')) {
                return AppLocalizations.of(context)!.get('validEmail');
              }
              return null;
            },
          ),
          const SizedBox(height: AppDimensions.paddingM),
          _buildTextField(
            AppLocalizations.of(context)!.get('password'),
            Icons.lock,
            isPassword: true,
            controller: _loginPasswordController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.get('enterPassword');
              }
              if (value.length < 6) {
                return AppLocalizations.of(context)!.get('passwordLength');
              }
              return null;
            },
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPasswordDialog,
              child: Text(AppLocalizations.of(context)!.get('forgotPassword')),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          CustomButton(
            text: AppLocalizations.of(context)!.get('login'),
            isLoading: _isLoading,
            onPressed: _handleEmailLogin,
          ),
          const SizedBox(height: AppDimensions.paddingL),
          _buildDivider(),
          const SizedBox(height: AppDimensions.paddingM),
          _buildSocialButtons(),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Role Selection Toggle
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildRoleButton(
                      AppLocalizations.of(context)!.get('patient'),
                    ),
                  ),
                  Expanded(
                    child: _buildRoleButton(
                      AppLocalizations.of(context)!.get('doctor'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),

            _buildTextField(
              AppLocalizations.of(context)!.get('fullName'),
              Icons.person,
              controller: _registerNameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.get('enterName');
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Doctor-specific field
            if (_selectedRole ==
                AppLocalizations.of(context)!.get('doctor')) ...[
              _buildTextField(
                AppLocalizations.of(context)!.get('medicalLicense'),
                Icons.badge,
                controller: _registerLicenseController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.get('enterLicense');
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.paddingM),
            ],

            _buildTextField(
              AppLocalizations.of(context)!.get('emailAddress'),
              Icons.email,
              controller: _registerEmailController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.get('enterEmail');
                }
                if (!value.contains('@')) {
                  return AppLocalizations.of(context)!.get('validEmail');
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.paddingM),
            _buildTextField(
              AppLocalizations.of(context)!.get('password'),
              Icons.lock,
              isPassword: true,
              controller: _passwordController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.get('enterPassword');
                }
                if (value.length < 8) {
                  return AppLocalizations.of(context)!.get('passwordLength8');
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.paddingM),
            _buildTextField(
              AppLocalizations.of(context)!.get('confirmPassword'),
              Icons.lock,
              isPassword: true,
              controller: _confirmPasswordController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(
                    context,
                  )!.get('confirmPasswordReq');
                }
                if (value != _passwordController.text) {
                  return AppLocalizations.of(context)!.get('passwordsNoMatch');
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.paddingL),
            CustomButton(
              text: AppLocalizations.of(context)!.get('createAccount'),
              isLoading: _isLoading,
              onPressed: _handleEmailRegister,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalizations.of(context)!.get('or'),
            style: TextStyle(
              color: AppColors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        // Google Sign-In Button
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _handleGoogleSignIn,
          icon: Image.network(
            'https://www.google.com/favicon.ico',
            height: 24,
            width: 24,
            errorBuilder:
                (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24),
          ),
          label: Text(AppLocalizations.of(context)!.get('continueWithGoogle')),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleButton(String role) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Text(
          role,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.primaryBlue : AppColors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon, {
    bool isPassword = false,
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryBlue),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    String iconUrl,
    String label,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Image.network(
        iconUrl,
        height: 24,
        width: 24,
        errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24),
      ),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }
}
