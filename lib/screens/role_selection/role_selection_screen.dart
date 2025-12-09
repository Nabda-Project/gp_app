import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/reusable/custom_card.dart';
import '../../widgets/reusable/custom_button.dart';
import '../../widgets/reusable/section_title.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? selectedRole;

  void _selectRole(String role) {
    setState(() {
      selectedRole = role;
    });
  }

  @override
  void initState() {
    super.initState();
    print("DEBUG: RoleSelectionScreen initialized");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBlue),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppDimensions.paddingM),
            const SectionTitle(
              title: AppStrings.roleSelectionTitle,
              center: true,
            ),
            const SizedBox(height: 50),

            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: CustomCard(
                      label: AppStrings.roleDoctor,
                      icon: Icons.local_hospital, // Using standard icon
                      isSelected: selectedRole == 'doctor',
                      onTap: () => _selectRole('doctor'),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingM),
                  Expanded(
                    child: CustomCard(
                      label: AppStrings.rolePatient,
                      icon: Icons.person, // Using standard icon
                      isSelected: selectedRole == 'patient',
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
                text:
                    "Continue as ${selectedRole == 'doctor' ? 'Doctor' : 'Patient'}",
                onPressed:
                    selectedRole != null
                        ? () {
                          // Navigate to Auth Screen, passing selected role if needed
                          Navigator.pushNamed(context, '/auth');
                        }
                        : () {}, // No-op if not visible
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
