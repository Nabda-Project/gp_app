import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/reusable/app_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/storage_service.dart';
import '../../services/firestore_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2000), () {});

    if (!mounted) return;

    final firebaseUser = FirebaseAuth.instance.currentUser;
    print("DEBUG: Splash - FirebaseAuth User: ${firebaseUser?.uid}");

    if (firebaseUser != null) {
      // User is signed in with Firebase
      // Check if we have local user data
      var user = StorageService.getUser();
      print("DEBUG: Splash - Local User: ${user?.email}");

      if (user == null) {
        // No local data (likely fresh install), fetch from Firestore
        print("Fetching user profile from Firestore...");
        try {
          user = await FirestoreService.getUser(firebaseUser.uid);
          if (user != null) {
            await StorageService.saveUser(user);
          }
        } catch (e) {
          print("Error fetching user in Splash: $e");
          // Proceed to role selection if fetch fails or no profile found
        }
      }

      if (mounted) {
        if (user != null) {
          // Profile exists, go to specific dashboard
          if (user.role == 'Doctor') {
            Navigator.pushReplacementNamed(context, '/doctor_dashboard');
          } else {
            Navigator.pushReplacementNamed(context, '/patient_dashboard');
          }
        } else {
          // Logged in but no profile -> Role Selection
          Navigator.pushReplacementNamed(context, '/role_selection');
        }
      }
    } else {
      // Not logged in
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: const AppLogo(size: 120),
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  Text(
                    AppStrings.appName,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
