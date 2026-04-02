import 'dart:developer';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/reusable/app_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/storage_service.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/token_service.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _navigateToNext();
  }

  void _initAnimations() {
    // Pulse animation for logo
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Fade animation for text
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    // Float animation for decorative circles
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Start fade animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2000), () {});

    if (!mounted) return;

    final firebaseUser = FirebaseAuth.instance.currentUser;
    log(
      "DEBUG: Splash - FirebaseAuth User: ${firebaseUser?.uid}",
      name: 'SplashScreen',
    );

    if (firebaseUser != null) {
      // User is signed in with Firebase
      // Check if we have local user data
      var user = StorageService.getUser();
      log("DEBUG: Splash - Local User: ${user?.email}", name: 'SplashScreen');

      if (user == null) {
        // No local data (likely fresh install), fetch from Firestore
        log("Fetching user profile from Firestore...", name: 'SplashScreen');
        try {
          user = await FirestoreService.getUser(firebaseUser.uid);
          if (user != null) {
            await StorageService.saveUser(user);
          }
        } catch (e) {
          log(
            "Error fetching user in Splash: $e",
            name: 'SplashScreen',
            error: e,
          );
          // Proceed to role selection if fetch fails or no profile found
        }
      }

      // Refresh back-end JWT (it may have expired since last session)
      try {
        final hasToken = await TokenService.hasToken();
        if (!hasToken) {
          log("No JWT found, attempting auto-re-login...", name: 'SplashScreen');
          await AuthService.refreshBackendToken();
        }
      } catch (e) {
        log("JWT refresh failed (non-critical): $e", name: 'SplashScreen');
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
      // Not logged in
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
          transitionDuration: const Duration(milliseconds: 1000),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
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
            // Animated decorative circles
            AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                return Positioned(
                  top: -100 + _floatAnimation.value,
                  left: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                return Positioned(
                  bottom: -80 - _floatAnimation.value,
                  right: -80,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                );
              },
            ),
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Animated logo with pulse effect
                  // Animated logo with pulse effect
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Hero(
                      tag: 'app_logo',
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        child: const AppLogo(size: 120),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  // Animated app name with fade
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      AppStrings.appName,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
