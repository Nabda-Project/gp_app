/// Welcome screen for the cardiac health assessment.
import 'package:flutter/material.dart';
import '../widgets/assessment_theme.dart';

class AssessmentWelcomeScreen extends StatefulWidget {
  const AssessmentWelcomeScreen({super.key});

  @override
  State<AssessmentWelcomeScreen> createState() => _AssessmentWelcomeScreenState();
}

class _AssessmentWelcomeScreenState extends State<AssessmentWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic)),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.5, curve: Curves.easeOutBack)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF0F5FF),
                Color(0xFFE8F0FF),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      // Heart icon with pulse effect
                      ScaleTransition(
                        scale: _scaleAnim,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: AssessmentColors.cardGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AssessmentColors.primary.withOpacity(0.3),
                                blurRadius: 40,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 70,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Title
                      const Text(
                        'تقييم صحة القلب',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AssessmentColors.textPrimary,
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Subtitle
                      Text(
                        'سنطرح عليك بعض الأسئلة البسيطة حول صحتك\nلإنشاء تقرير طبي ذكي يساعدك في فهم حالتك',
                        style: TextStyle(
                          fontSize: 15,
                          color: AssessmentColors.textSecondary,
                          fontFamily: 'Cairo',
                          height: 1.7,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      // Features
                      _buildFeatureRow(Icons.timer_outlined, 'يستغرق 5-10 دقائق'),
                      _buildFeatureRow(Icons.lock_outline_rounded, 'بياناتك محمية وآمنة'),
                      _buildFeatureRow(Icons.psychology_outlined, 'تحليل ذكي بالذكاء الاصطناعي'),
                      const Spacer(flex: 2),
                      // Start button
                      Container(
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: AssessmentColors.cardGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AssessmentShadows.button,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, '/assessment_flow');
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'ابدأ التقييم',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Disclaimer
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AssessmentColors.warning.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: AssessmentColors.warning.withOpacity(0.8), size: 18),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'هذا التقييم استرشادي ولا يُغني عن استشارة الطبيب',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AssessmentColors.textSecondary,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AssessmentColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AssessmentColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AssessmentColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
