import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/app_localizations.dart';

class NoInternetView extends StatefulWidget {
  const NoInternetView({super.key});

  @override
  State<NoInternetView> createState() => _NoInternetViewState();
}

class _NoInternetViewState extends State<NoInternetView> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Gradient Element
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.orangeAccent.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Icon
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orangeAccent.withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 80,
                    color: Colors.orangeAccent,
                  ),
                ),
              ),
              
              const SizedBox(height: 50),
              
              // Text Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.get('noInternetTitle'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.get('noInternetDesc'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.darkBlue.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Animated Status Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.get('reconnecting'),
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
