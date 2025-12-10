import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/reusable/status_card.dart';
import '../../widgets/reusable/vital_card.dart';
import '../../services/storage_service.dart';
import '../../models/user_model.dart';
import '../profile/profile_screen.dart';
import '../../widgets/reusable/section_title.dart';
import '../../utils/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../widgets/reusable/decorated_background.dart';
import '../../widgets/animations/fade_slide_transition.dart';
import '../../widgets/animations/animated_list_item.dart';
import '../../widgets/reusable/custom_bottom_nav.dart';
import 'doctor_chat_screen.dart'; // Added import

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  int _currentIndex = 0;
  UserModel? _currentUser;
  final PageController _pageController =
      PageController(); // Added PageController

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadUser() {
    setState(() {
      _currentUser = StorageService.getUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboardContent(), // 0: Dashboard
      const DoctorChatScreen(), // 1: Doctor Chat
      const ProfileScreen(), // 2: Profile
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        physics: const BouncingScrollPhysics(),
        children: pages,
      ),
      floatingActionButton:
          _currentIndex == 1
              ? null
              : FloatingActionButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/chatbot');
                },
                backgroundColor: AppColors.primaryBlue,
                child: const FaIcon(
                  FontAwesomeIcons.robot,
                  color: Colors.white,
                ),
              ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: [
          CustomNavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: AppLocalizations.of(context)!.get('dashboard'),
          ),
          CustomNavItem(
            icon: Icons.message_outlined,
            activeIcon: Icons.message,
            label: AppLocalizations.of(context)!.get('chat'),
          ),
          CustomNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: AppLocalizations.of(context)!.get('profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBackground(
        child: CustomScrollView(
          slivers: [
            // Custom App Bar (Matching Doctor Dashboard)
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.white,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                    ),
                    // Decorative circles
                    Positioned(
                      top: -60,
                      right: -30,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -40,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Content
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.paddingL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.person, // Person icon for patient
                                      color: AppColors.primaryBlue,
                                      size: 26,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.paddingM),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.get('hello'),
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        _currentUser?.fullName ?? 'User',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          "${['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][DateTime.now().weekday - 1]}, ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][DateTime.now().month - 1]} ${DateTime.now().day}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/notifications',
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Animated Status Card
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 100),
                      child: StatusCard(
                        title: AppLocalizations.of(
                          context,
                        )!.get('currentHealthStatus'),
                        status: AppLocalizations.of(context)!.get('normal'),
                        isHealthy: true,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingL),
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 200),
                      child: SectionTitle(
                        title: AppLocalizations.of(context)!.get('vitals'),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingM),
                    // Animated Vitals Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: AppDimensions.paddingM,
                      mainAxisSpacing: AppDimensions.paddingM,
                      childAspectRatio: 1.5,
                      children: [
                        AnimatedListItem(
                          index: 0,
                          child: VitalCard(
                            label: AppLocalizations.of(
                              context,
                            )!.get('heartRate'),
                            value: "72",
                            unit: "bpm",
                            icon: Icons.favorite,
                            color: Colors.redAccent,
                          ),
                        ),
                        AnimatedListItem(
                          index: 1,
                          child: VitalCard(
                            label: AppLocalizations.of(
                              context,
                            )!.get('bloodOxygen'),
                            value: "98",
                            unit: "%",
                            icon: Icons.water_drop,
                            color: Colors.lightBlue,
                          ),
                        ),
                        AnimatedListItem(
                          index: 2,
                          child: VitalCard(
                            label: AppLocalizations.of(
                              context,
                            )!.get('bloodPressure'),
                            value: "120/80",
                            unit: "mmHg",
                            icon: Icons.speed,
                            color: Colors.orange,
                          ),
                        ),
                        AnimatedListItem(
                          index: 3,
                          child: VitalCard(
                            label: AppLocalizations.of(
                              context,
                            )!.get('nextFollowUp'),
                            value: "Oct 15",
                            unit: "",
                            icon: Icons.calendar_today,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingL),
                    // Animated Follow-up Card
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 500),
                      child: _buildFollowUpCard(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.get('nextFollowUp'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/follow_ups');
                    },
                    child: Text(AppLocalizations.of(context)!.get('seeAll')),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingS),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: AppColors.lightGrey,
              child: Icon(Icons.calendar_today, color: AppColors.primaryBlue),
            ),
            title: Text(AppLocalizations.of(context)!.get('drSarahJohnson')),
            subtitle: Text(
              AppLocalizations.of(context)!.get('appointmentDate'),
            ),
          ),
        ],
      ),
    );
  }
}
