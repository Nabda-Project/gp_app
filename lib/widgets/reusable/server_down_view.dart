import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/app_localizations.dart';

class ServerDownView extends StatefulWidget {
  final Future<bool> Function() onRefresh;

  const ServerDownView({super.key, required this.onRefresh});

  @override
  State<ServerDownView> createState() => _ServerDownViewState();
}

class _ServerDownViewState extends State<ServerDownView> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  late AnimationController _rippleController;
  
  Timer? _pollingTimer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startPolling();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  void _startPolling() {
    // Ping server every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_isChecking || !mounted) return;
      setState(() => _isChecking = true);
      
      final isBackOnline = await widget.onRefresh();
      
      if (mounted) {
        setState(() => _isChecking = false);
        if (isBackOnline) {
          _pollingTimer?.cancel();
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    _pollingTimer?.cancel();
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
                    AppColors.primaryBlue.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Radar / Icon
              SizedBox(
                height: 200,
                width: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ...List.generate(3, (index) {
                      return AnimatedBuilder(
                        animation: _rippleController,
                        builder: (context, child) {
                          // Offset each ripple
                          double progress = (_rippleController.value + (index * 0.33)) % 1.0;
                          return Transform.scale(
                            scale: 1.0 + (progress * 1.5),
                            child: Opacity(
                              opacity: 1.0 - progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.redAccent.withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                    
                    // Center Pulsing Icon
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.dns_rounded,
                          size: 64,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Text Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.get('serverDownTitle'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.get('serverDownDesc'),
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
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.get('reconnecting'),
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
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
