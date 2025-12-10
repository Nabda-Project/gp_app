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

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  int _currentIndex = 0;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
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
      const SizedBox(), // 1: Doctor Chat (Handled via pushNamed)
      const ProfileScreen(), // 2: Profile
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body:
          _currentIndex ==
                  2 // Profile is now index 2
              ? pages[2]
              : _currentIndex ==
                  1 // Doctor Chat is now index 1
              ? pages[1]
              : _buildDashboardContent(), // Default to dashboard (index 0)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/chatbot');
        },
        backgroundColor: AppColors.primaryBlue,
        child: const FaIcon(FontAwesomeIcons.robot, color: Colors.white),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/doctor_chat');
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
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
      // Web structure trick to keep AppBar specific to Dashboard if needed, or just return column
      // But dashboard has specific AppBar with "Hello User".
      // Profile has its own AppBar.
      // So I should extract the dashboard body + appbar into a widget or conditional.
      // Let's refactor: The main Scaffold body will change.
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "HealthSync",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue,
                fontSize: 20,
              ),
            ),
            if (_currentUser != null)
              Text(
                "Hello, ${_currentUser!.fullName}",
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.darkBlue,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
        ],
      ),
      body: DecoratedBackground(
        child: SingleChildScrollView(
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
                      label: AppLocalizations.of(context)!.get('heartRate'),
                      value: "72",
                      unit: "bpm",
                      icon: Icons.favorite,
                      color: Colors.redAccent,
                    ),
                  ),
                  AnimatedListItem(
                    index: 1,
                    child: VitalCard(
                      label: AppLocalizations.of(context)!.get('bloodOxygen'),
                      value: "98",
                      unit: "%",
                      icon: Icons.water_drop,
                      color: Colors.lightBlue,
                    ),
                  ),
                  AnimatedListItem(
                    index: 2,
                    child: VitalCard(
                      label: AppLocalizations.of(context)!.get('bloodPressure'),
                      value: "120/80",
                      unit: "mmHg",
                      icon: Icons.speed,
                      color: Colors.orange,
                    ),
                  ),
                  AnimatedListItem(
                    index: 3,
                    child: VitalCard(
                      label: AppLocalizations.of(context)!.get('nextFollowUp'),
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
