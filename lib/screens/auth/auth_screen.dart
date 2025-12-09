import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/reusable/app_logo.dart';
import '../../widgets/reusable/custom_button.dart';
import '../../services/storage_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_localizations.dart';

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

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _loginEmailController = TextEditingController();
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
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerLicenseController.dispose();
    super.dispose();
  }

  void _handleSuccess(
    String role,
    String email,
    String name,
    String? license,
  ) async {
    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: name,
      email: email,
      role: role,
      licenseNumber: license,
    );

    await StorageService.saveUser(user);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/patient_dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (keeping build method as is)
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const AppLogo(size: 100),
              const SizedBox(height: AppDimensions.paddingL),
              Text(
                AppLocalizations.of(context)!.get('accessAccount'),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.paddingL),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryBlue,
                unselectedLabelColor: AppColors.grey,
                indicatorColor: AppColors.primaryBlue,
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.get('login')),
                  Tab(text: AppLocalizations.of(context)!.get('createAccount')),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingL),
              SizedBox(
                height: 500, // Fixed height for constraints
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildLoginForm(), _buildRegisterForm()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ...
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
              onPressed: () {},
              child: Text(AppLocalizations.of(context)!.get('forgotPassword')),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingL),
          CustomButton(
            text: AppLocalizations.of(context)!.get('login'),
            onPressed: () {
              if (_loginFormKey.currentState!.validate()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.get('processingLogin'),
                    ),
                  ),
                );
                // Real Login logic using captured email
                _handleSuccess(
                  'Patient', // Login is always patient in this simple demo or fetched from backend
                  _loginEmailController.text,
                  'Returning User', // In real app, name is fetched from backend
                  null,
                );
              }
            },
          ),
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
              onPressed: () {
                if (_registerFormKey.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.get('creatingAccount'),
                      ),
                    ),
                  );
                  _handleSuccess(
                    _selectedRole == AppLocalizations.of(context)!.get('doctor')
                        ? 'Doctor'
                        : 'Patient', // Normalize role
                    _registerEmailController.text,
                    _registerNameController.text,
                    _selectedRole == AppLocalizations.of(context)!.get('doctor')
                        ? _registerLicenseController.text
                        : null,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleButton(String role) {
    // ... (keeping role button as is)
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
}
