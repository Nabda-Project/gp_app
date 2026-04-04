import 'dart:developer';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/reusable/status_card.dart';
import '../../widgets/reusable/vital_card.dart';
import '../../services/storage_service.dart';
import '../../services/patient_api_service.dart';
import '../../models/user_model.dart';
import '../../models/doctor_info_model.dart';
import '../profile/profile_screen.dart';
import '../../widgets/reusable/section_title.dart';
import '../../utils/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../widgets/reusable/decorated_background.dart';
import '../../widgets/animations/fade_slide_transition.dart';
import '../../widgets/animations/animated_list_item.dart';
import '../../widgets/reusable/custom_bottom_nav.dart';
import 'doctor_chat_screen.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  int _currentIndex = 0;
  UserModel? _currentUser;
  DoctorInfoModel? _assignedDoctor;
  bool _loadingDoctor = true;
  final PageController _pageController = PageController();

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

  Future<void> _loadUser() async {
    final user = StorageService.getUser();
    setState(() {
      _currentUser = user;
    });
    await _fetchAssignedDoctor(user);
  }

  Future<void> _fetchAssignedDoctor(UserModel? user) async {
    if (user?.backendId == null) {
      setState(() => _loadingDoctor = false);
      return;
    }
    try {
      final doctor = await PatientApiService.getAssignedDoctor(user!.backendId!);
      if (mounted) {
        setState(() {
          _assignedDoctor = doctor;
          _loadingDoctor = false;
        });
      }
    } catch (e) {
      log('Could not load assigned doctor: $e', name: 'PatientDashboard');
      if (mounted) setState(() => _loadingDoctor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboardContent(),
      DoctorChatScreen(doctorName: _assignedDoctor?.fullName),
      const ProfileScreen(),
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
            // ── App Bar ──────────────────────────────────────────────────────
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
                                      Icons.person,
                                      color: AppColors.primaryBlue,
                                      size: 26,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.paddingM),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.get('hello'),
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
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
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(20),
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
                                      Navigator.pushNamed(context, '/notifications');
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

            // ── Body ─────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Assigned Doctor Card ──────────────────────────────
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 50),
                      child: _buildDoctorCard(),
                    ),
                    const SizedBox(height: AppDimensions.paddingL),

                    // Status Card
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 100),
                      child: StatusCard(
                        title: AppLocalizations.of(context)!.get('currentHealthStatus'),
                        status: 'Normal',
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

                    // Vitals Grid – mock data (Bluetooth smartwatch pending)
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
                            label: AppLocalizations.of(context)!.get('heartRate'),
                            value: '--',
                            unit: "bpm",
                            icon: Icons.favorite,
                            color: Colors.redAccent,
                          ),
                        ),
                        AnimatedListItem(
                          index: 1,
                          child: VitalCard(
                            label: AppLocalizations.of(context)!.get('bloodOxygen'),
                            value: '--',
                            unit: "%",
                            icon: Icons.water_drop,
                            color: Colors.lightBlue,
                          ),
                        ),
                        AnimatedListItem(
                          index: 2,
                          child: VitalCard(
                            label: 'Body Temp',
                            value: '--',
                            unit: "°C",
                            icon: Icons.thermostat,
                            color: Colors.orange,
                          ),
                        ),
                        AnimatedListItem(
                          index: 3,
                          child: VitalCard(
                            label: AppLocalizations.of(context)!.get('nextFollowUp'),
                            value: "N/A",
                            unit: "",
                            icon: Icons.calendar_today,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingL),

                    // Follow-up Card
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

  // ── Assigned Doctor Card ───────────────────────────────────────────────────
  Widget _buildDoctorCard() {
    return GestureDetector(
      onTap: _assignedDoctor == null
          ? null
          : () {
              // Jump to the Chat tab
              _pageController.animateToPage(
                1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              setState(() => _currentIndex = 1);
            },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(
          gradient: _assignedDoctor != null
              ? const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: _assignedDoctor != null ? null : AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          boxShadow: [
            BoxShadow(
              color: _assignedDoctor != null
                  ? const Color(0xFF1565C0).withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: _loadingDoctor
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryBlue,
                  ),
                ),
              )
            : _assignedDoctor != null
                ? Row(
                    children: [
                      // Avatar
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _assignedDoctor!.fullName.isNotEmpty
                                ? _assignedDoctor!.fullName[0].toUpperCase()
                                : 'D',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingM),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Doctor',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Dr. ${_assignedDoctor!.fullName}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _assignedDoctor!.email,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Chat icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_search_outlined,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No doctor assigned yet',
                              style: TextStyle(
                                color: AppColors.darkBlue.withValues(alpha: 0.8),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your care team will be shown here once assigned.',
                              style: TextStyle(
                                color: AppColors.darkBlue.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
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
