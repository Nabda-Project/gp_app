import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../utils/constants.dart';
import '../../widgets/reusable/app_logo.dart';
import '../../widgets/reusable/no_internet_view.dart';
import '../../widgets/reusable/server_down_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/storage_service.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/token_service.dart';
import '../../services/api_service.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ─── Heartbeat pulse controller (logo scale) ───
  late AnimationController _heartbeatController;
  late Animation<double> _heartbeatAnimation;

  // ─── ECG line draw controller ───
  late AnimationController _ecgDrawController;
  late Animation<double> _ecgDrawAnimation;

  // ─── Fade-in for text ───
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // ─── Floating decorative circles ───
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  // ─── Pulse ring (expanding ring behind logo) ───
  late AnimationController _pulseRingController;
  late Animation<double> _pulseRingScale;
  late Animation<double> _pulseRingOpacity;

  // ─── Network gate state ───
  /// null = still in splash animation, 'noInternet' or 'serverDown' = blocked
  String? _networkBlock;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _navigateToNext();
  }

  void _initAnimations() {
    // ── Heartbeat: realistic double-beat rhythm ──
    // Lub-dub pattern: quick scale up → down → smaller scale up → down → pause
    _heartbeatController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _heartbeatAnimation = TweenSequence<double>([
      // First beat (lub) — strong
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12)
          .chain(CurveTween(curve: Curves.easeOut)), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.97)
          .chain(CurveTween(curve: Curves.easeIn)), weight: 8),
      // Second beat (dub) — softer
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.06)
          .chain(CurveTween(curve: Curves.easeOut)), weight: 6),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0)
          .chain(CurveTween(curve: Curves.easeIn)), weight: 6),
      // Diastolic pause
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 72),
    ]).animate(_heartbeatController);

    // ── ECG line drawing ──
    _ecgDrawController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();

    _ecgDrawAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ecgDrawController, curve: Curves.easeInOut),
    );

    // ── Fade animation for text ──
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // ── Float animation for decorative circles ──
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // ── Pulse ring ──
    _pulseRingController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();

    _pulseRingScale = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _pulseRingController, curve: Curves.easeOut),
    );
    _pulseRingOpacity = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(parent: _pulseRingController, curve: Curves.easeOut),
    );

    // Start fade after a short delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _heartbeatController.dispose();
    _ecgDrawController.dispose();
    _fadeController.dispose();
    _floatController.dispose();
    _pulseRingController.dispose();
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

      // Check for zombie state: Firebase survived a reinstall, but backend credentials wiped.
      final credentials = await TokenService.getCredentials();
      if (credentials == null) {
        log("Backend credentials missing but Firebase user exists. Performing clean logout.", name: 'SplashScreen');
        await AuthService.signOut();
        if (mounted) {
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
        return;
      }

      // ── Connectivity + Server Gate ──────────────────────────────────────
      // For authenticated users, verify we can reach the backend before
      // allowing navigation to the dashboard.
      final connectivityResult = await Connectivity().checkConnectivity();
      final isDisconnected = connectivityResult.isEmpty ||
          (connectivityResult.contains(ConnectivityResult.none) &&
           !connectivityResult.contains(ConnectivityResult.wifi) &&
           !connectivityResult.contains(ConnectivityResult.mobile) &&
           !connectivityResult.contains(ConnectivityResult.ethernet));

      if (isDisconnected) {
        log('No internet connection – blocking navigation', name: 'SplashScreen');
        if (mounted) setState(() => _networkBlock = 'noInternet');
        return;
      }

      // Check if server is reachable
      try {
        final check = await ApiService.testConnection();
        if (check.contains('Error') || check.contains('Exception')) {
          log('Server unreachable – blocking navigation', name: 'SplashScreen');
          if (mounted) setState(() => _networkBlock = 'serverDown');
          return;
        }
      } catch (_) {
        log('Server unreachable (exception) – blocking navigation', name: 'SplashScreen');
        if (mounted) setState(() => _networkBlock = 'serverDown');
        return;
      }
      // ── End connectivity gate ──────────────────────────────────────────

      // Proactively refresh the back-end JWT so the first API call won't 401.
      // This handles the common case where the token expired while the app was closed.
      try {
        final refreshed = await AuthService.refreshBackendToken();
        if (!refreshed) {
          log("JWT refresh failed (non-critical, maybe server down) – will rely on auto-retry",
              name: 'SplashScreen');
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
            // ── First-time profile guard ─────────────────────────────────
            // If essential profile fields are missing, the patient hasn't
            // completed the initial setup.  Redirect to the AI assessment
            // welcome screen so they complete the intake first.
            //
            // TODO(backend): Replace this local heuristic with a dedicated
            //   backend flag (e.g. `user.hasCompletedInitialAssessment`)
            //   once the backend supports it.
            final profileIncomplete = user.dateOfBirth == null ||
                user.gender == null ||
                user.height == null ||
                user.weight == null;

            if (profileIncomplete) {
              Navigator.pushReplacementNamed(context, '/assessment_welcome');
            } else {
              Navigator.pushReplacementNamed(context, '/patient_dashboard');
            }
          }
        } else {
          // Logged in but no profile -> Role Selection
          Navigator.pushReplacementNamed(context, '/role_selection');
        }
      }
    } else {
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
    // ── Network block screens (shown INSTEAD of splash when gate fails) ──
    if (_networkBlock == 'noInternet') {
      return const NoInternetView();
    }
    if (_networkBlock == 'serverDown') {
      return Scaffold(
        body: ServerDownView(
          onRefresh: () async {
            try {
              final result = await ApiService.testConnection();
              if (result.contains('Error') || result.contains('Exception')) return false;
              // Server is back — restart the navigation flow
              if (mounted) {
                setState(() => _networkBlock = null);
                _navigateToNext();
              }
              return true;
            } catch (_) {
              return false;
            }
          },
        ),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Stack(
          children: [
            // ─── Floating decorative circles ───
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

            // ─── Background ECG waveform (subtle) ───
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ecgDrawAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _BackgroundEcgPainter(
                      progress: _ecgDrawAnimation.value,
                    ),
                  );
                },
              ),
            ),

            // ─── Main content ───
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // ── Pulse ring + heartbeat logo ──
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Expanding pulse ring
                        AnimatedBuilder(
                          animation: _pulseRingController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseRingScale.value,
                              child: Container(
                                width: 168,
                                height: 168,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(
                                      alpha: _pulseRingOpacity.value,
                                    ),
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Second ring (offset timing)
                        AnimatedBuilder(
                          animation: _pulseRingController,
                          builder: (context, child) {
                            // Offset by half cycle for layered effect
                            final offset = (_pulseRingController.value + 0.5) % 1.0;
                            final scale = 1.0 + (0.8 * offset);
                            final opacity = 0.3 * (1.0 - offset);
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 168,
                                height: 168,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: opacity),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Logo with heartbeat scale
                        ScaleTransition(
                          scale: _heartbeatAnimation,
                          child: Hero(
                            tag: 'app_logo',
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              child: AppLogo(
                                size: 120,
                                animate: true,
                                animation: _ecgDrawAnimation,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingL),

                  // ── App name with fade ──
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          AppStrings.appName,
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 6,
                                fontSize: 38,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your Health, Your Pulse',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w300,
                              ),
                        ),
                      ],
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

/// Paints a subtle, continuously scrolling ECG waveform across the
/// entire background of the splash screen.
class _BackgroundEcgPainter extends CustomPainter {
  final double progress;

  _BackgroundEcgPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cy = size.height * 0.5;
    final totalW = size.width * 2; // doubled so it can scroll
    final offsetX = -totalW * progress; // scrolling offset

    final path = Path();
    final segmentWidth = totalW / 4; // 4 heartbeat segments across

    for (int seg = 0; seg < 4; seg++) {
      final baseX = offsetX + seg * segmentWidth;
      final amp = size.height * 0.06;

      // Build one heartbeat segment
      final points = _buildSegment(baseX, cy, segmentWidth, amp);
      if (seg == 0) {
        path.moveTo(points.first.dx, points.first.dy);
      }
      for (final p in points) {
        path.lineTo(p.dx, p.dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  List<Offset> _buildSegment(double startX, double cy, double w, double amp) {
    final List<Offset> pts = [];
    const int steps = 60;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = startX + t * w;
      double y = cy;

      // P wave
      if (t > 0.15 && t < 0.25) {
        final lt = (t - 0.15) / 0.10;
        y = cy - amp * 0.3 * math.sin(lt * math.pi);
      }
      // QRS complex
      else if (t > 0.30 && t < 0.35) {
        final lt = (t - 0.30) / 0.05;
        y = cy + amp * 0.4 * math.sin(lt * math.pi); // Q dip
      } else if (t > 0.35 && t < 0.42) {
        final lt = (t - 0.35) / 0.07;
        y = cy - amp * math.sin(lt * math.pi); // R spike
      } else if (t > 0.42 && t < 0.48) {
        final lt = (t - 0.42) / 0.06;
        y = cy + amp * 0.5 * math.sin(lt * math.pi); // S dip
      }
      // T wave
      else if (t > 0.55 && t < 0.70) {
        final lt = (t - 0.55) / 0.15;
        y = cy - amp * 0.35 * math.sin(lt * math.pi);
      }

      pts.add(Offset(x, y));
    }
    return pts;
  }

  @override
  bool shouldRepaint(covariant _BackgroundEcgPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
