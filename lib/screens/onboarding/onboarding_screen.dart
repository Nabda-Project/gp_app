import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/app_localizations.dart';
import '../../widgets/reusable/custom_button.dart';
import '../../widgets/animations/fade_slide_transition.dart';
import '../../widgets/reusable/app_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<double> _iconScaleAnimation;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _iconScaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // Top Image Section with Gradient
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Decorative circles with fade animation
                  Positioned(
                    top: -50,
                    right: -50,
                    child: FadeSlideTransition(
                      delay: const Duration(milliseconds: 200),
                      beginOffset: const Offset(-0.3, 0),
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 50,
                    left: -30,
                    child: FadeSlideTransition(
                      delay: const Duration(milliseconds: 400),
                      beginOffset: const Offset(0.3, 0),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                  ),
                  // Animated Main Icon (Hero)
                  FadeSlideTransition(
                    delay: const Duration(milliseconds: 100),
                    duration: const Duration(milliseconds: 800),
                    beginOffset: const Offset(
                      0,
                      0.2,
                    ), // Start slightly lower to match flight
                    child: ScaleTransition(
                      scale: _iconScaleAnimation,
                      child: Hero(
                        tag: 'app_logo',
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          child: const AppLogo(size: 80),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom Content Section with slide-up animation
          Expanded(
            flex: 4,
            child: FadeSlideTransition(
              delay: const Duration(milliseconds: 800), // Wait for Hero
              duration: const Duration(milliseconds: 800),
              beginOffset: const Offset(0, 0.3), // Slide from further down
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.radiusXL),
                    topRight: Radius.circular(AppDimensions.radiusXL),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 500),
                      child: Text(
                        AppLocalizations.of(context)!.get('onboardingTitle'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingM),
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 650),
                      child: Text(
                        AppLocalizations.of(context)!.get('onboardingSubtitle'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingXL),
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 800),
                      child: CustomButton(
                        text: AppLocalizations.of(context)!.get('getStarted'),
                        onPressed: () {
                          // Navigate to Auth Screen
                          Navigator.pushReplacementNamed(context, '/auth');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
