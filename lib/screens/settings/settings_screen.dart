import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../models/settings_model.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/reusable/custom_button.dart';
import '../../utils/app_localizations.dart';
import '../../widgets/animations/fade_slide_transition.dart';
import '../../widgets/animations/animated_list_item.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsModel _settings;

  @override
  void initState() {
    super.initState();
    _settings = StorageService.getSettings();
  }

  void _toggleNotifications(bool value) {
    setState(() {
      _settings.enableNotifications = value;
    });
    StorageService.saveSettings(_settings);
  }

  void _handleLogout() async {
    await AuthService.signOut();
    await StorageService.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.get('settings'),
          style: const TextStyle(
            color: AppColors.darkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBlue),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          children: [
            AnimatedListItem(
              index: 0,
              child: _buildSwitchTile(
                title: AppLocalizations.of(context)!.get('notifications'),
                subtitle: AppLocalizations.of(
                  context,
                )!.get('notificationsDesc'),
                value: _settings.enableNotifications,
                onChanged: _toggleNotifications,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            AnimatedListItem(
              index: 1,
              child: Container(
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
                  title: Text(
                    AppLocalizations.of(context)!.get('language'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  subtitle: Text(
                    _settings.languageCode == 'ar' ? "العربية" : "English",
                    style: const TextStyle(color: AppColors.grey),
                  ),
                  trailing: DropdownButton<String>(
                    value: _settings.languageCode,
                    underline: const SizedBox(),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.primaryBlue,
                    ),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _settings.languageCode = newValue;
                        });
                        StorageService.saveSettings(_settings);
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text("English")),
                      DropdownMenuItem(value: 'ar', child: Text("العربية")),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            FadeSlideTransition(
              delay: const Duration(milliseconds: 300),
              child: CustomButton(
                text: AppLocalizations.of(context)!.get('logout'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text(
                            AppLocalizations.of(context)!.get('logout'),
                          ),
                          content: Text(
                            AppLocalizations.of(context)!.get('logoutConfirm'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                AppLocalizations.of(context)!.get('cancel'),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Close dialog
                                _handleLogout();
                              },
                              child: Text(
                                AppLocalizations.of(context)!.get('logout'),
                                style: const TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                  );
                },
                backgroundColor: AppColors.error,
                textColor: AppColors.white,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
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
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.darkBlue,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.grey)),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryBlue,
      ),
    );
  }
}
