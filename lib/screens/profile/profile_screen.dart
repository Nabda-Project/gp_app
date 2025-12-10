import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../models/user_model.dart';
import '../../utils/app_localizations.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/reusable/decorated_background.dart';
import '../../widgets/animations/fade_slide_transition.dart';
import '../../widgets/animations/animated_list_item.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    setState(() {
      _currentUser = StorageService.getUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.get('myProfile'),
          style: const TextStyle(
            color: AppColors.darkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBlue),
      ),
      body: DecoratedBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            children: [
              // Animated Profile Card
              FadeSlideTransition(
                delay: const Duration(milliseconds: 100),
                child: SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingL),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.primaryBlue,
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.paddingM),
                          Text(
                            _currentUser?.fullName ??
                                AppLocalizations.of(context)!.get('guestUser'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppDimensions.paddingS),
                          Text(
                            _currentUser?.email ??
                                AppLocalizations.of(context)!.get('noEmail'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingL),
              // Animated Profile Options
              AnimatedListItem(
                index: 0,
                child: _buildProfileOption(
                  icon: Icons.settings,
                  title: AppLocalizations.of(context)!.get('settings'),
                  onTap: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
              ),
              AnimatedListItem(
                index: 1,
                child: _buildProfileOption(
                  icon: Icons.history,
                  title: AppLocalizations.of(context)!.get('medicalHistory'),
                  onTap: () {
                    Navigator.pushNamed(context, '/medical_history');
                  },
                ),
              ),
              const SizedBox(height: AppDimensions.paddingL),
              AnimatedListItem(
                index: 2,
                child: _buildProfileOption(
                  icon: Icons.logout,
                  title: AppLocalizations.of(context)!.get('logout'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text(
                              AppLocalizations.of(context)!.get('logout'),
                            ),
                            content: Text(
                              AppLocalizations.of(
                                context,
                              )!.get('logoutConfirm'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  AppLocalizations.of(context)!.get('cancel'),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await AuthService.signOut();
                                  await StorageService.logout();
                                  if (context.mounted) {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/onboarding',
                                      (route) => false,
                                    );
                                  }
                                },
                                child: Text(
                                  AppLocalizations.of(context)!.get('logout'),
                                  style: const TextStyle(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryBlue),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.darkBlue,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
        onTap: onTap,
      ),
    );
  }
}
