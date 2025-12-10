import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';

/// A reusable logout confirmation dialog with modern styling.
///
/// Shows a beautiful dialog with icon, title, description and action buttons.
/// Handles the logout process and navigation automatically.
class LogoutDialog extends StatelessWidget {
  /// The route to navigate to after successful logout.
  /// Defaults to '/onboarding'.
  final String navigateToRoute;

  const LogoutDialog({super.key, this.navigateToRoute = '/onboarding'});

  /// Shows the logout dialog.
  ///
  /// Usage:
  /// ```dart
  /// LogoutDialog.show(context);
  /// // or with custom route:
  /// LogoutDialog.show(context, navigateToRoute: '/auth');
  /// ```
  static Future<void> show(
    BuildContext context, {
    String navigateToRoute = '/onboarding',
  }) {
    return showDialog(
      context: context,
      builder:
          (dialogContext) => LogoutDialog(navigateToRoute: navigateToRoute),
    );
  }

  Future<void> _handleLogout(
    BuildContext context,
    BuildContext dialogContext,
  ) async {
    Navigator.pop(dialogContext);
    await AuthService.signOut();
    await StorageService.logout();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        navigateToRoute,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Container with gradient background
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.error.withValues(alpha: 0.1),
                    AppColors.error.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              AppLocalizations.of(context)!.get('logout'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              AppLocalizations.of(context)!.get('logoutConfirm'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.grey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            // Buttons Row
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: AppColors.grey.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.get('cancel'),
                      style: const TextStyle(
                        color: AppColors.darkBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Logout Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleLogout(context, context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.get('logout'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
