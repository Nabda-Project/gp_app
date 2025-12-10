import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/storage_service.dart';
import '../../models/user_model.dart';
import '../profile/profile_screen.dart';
import '../../utils/app_localizations.dart';
import '../../widgets/reusable/decorated_background.dart';
import '../../widgets/reusable/section_title.dart';
import '../../widgets/reusable/patient_card.dart';
import '../../widgets/reusable/stat_card.dart';
import '../../widgets/reusable/alert_card.dart';
import '../../widgets/animations/fade_slide_transition.dart';
import '../../widgets/animations/animated_list_item.dart';
import '../../widgets/reusable/custom_bottom_nav.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  int _currentIndex = 0;
  UserModel? _currentUser;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Mock data for patients
  final List<Map<String, dynamic>> _mockPatients = [
    {
      'id': '1',
      'name': 'Ahmed Hassan',
      'email': 'ahmed@email.com',
      'status': 'Normal',
      'heartRate': '72',
      'lastUpdate': '2h ago',
    },
    {
      'id': '2',
      'name': 'Sara Mohamed',
      'email': 'sara@email.com',
      'status': 'Warning',
      'heartRate': '95',
      'lastUpdate': '1h ago',
    },
    {
      'id': '3',
      'name': 'Omar Ali',
      'email': 'omar@email.com',
      'status': 'Normal',
      'heartRate': '68',
      'lastUpdate': '30m ago',
    },
    {
      'id': '4',
      'name': 'Fatima Youssef',
      'email': 'fatima@email.com',
      'status': 'Critical',
      'heartRate': '110',
      'lastUpdate': '5m ago',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _loadUser() {
    setState(() {
      _currentUser = StorageService.getUser();
    });
  }

  List<Map<String, dynamic>> get _filteredPatients {
    if (_searchQuery.isEmpty) {
      return _mockPatients;
    }
    return _mockPatients.where((patient) {
      final name = patient['name'].toString().toLowerCase();
      return name.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboardContent(),
      _buildPatientsContent(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: pages[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          CustomNavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: AppLocalizations.of(context)!.get('dashboard'),
          ),
          CustomNavItem(
            icon: Icons.people_outline,
            activeIcon: Icons.people,
            label: AppLocalizations.of(context)!.get('myPatients'),
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
            // Custom App Bar
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
                                    radius: 26, // Slightly larger
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.medical_services,
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
                                        "Dr. ${_currentUser?.fullName ?? 'Doctor'}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22, // Larger font
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Date display
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          AppLocalizations.of(context)!
                                              .get('appointmentDate')
                                              .split('•')
                                              .first, // Reusing localized date part
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
                                    color: Colors.white.withValues(alpha: 0.15),
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
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Stats Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppDimensions.paddingM,
                      crossAxisSpacing: AppDimensions.paddingM,
                      childAspectRatio: 1.5,
                      children: [
                        AnimatedListItem(
                          index: 0,
                          child: StatCard(
                            icon: Icons.people,
                            value: '${_mockPatients.length}',
                            label: AppLocalizations.of(
                              context,
                            )!.get('totalPatients'),
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        AnimatedListItem(
                          index: 1,
                          child: StatCard(
                            icon: Icons.warning_amber_rounded,
                            value:
                                '${_mockPatients.where((p) => p['status'] != 'Normal').length}',
                            label: AppLocalizations.of(
                              context,
                            )!.get('needAttention'),
                            color: Colors.orange,
                          ),
                        ),
                        AnimatedListItem(
                          index: 2,
                          child: StatCard(
                            icon: Icons.message,
                            value: '3',
                            label: AppLocalizations.of(
                              context,
                            )!.get('pendingMessages'),
                            color: AppColors.accentTeal,
                          ),
                        ),
                        AnimatedListItem(
                          index: 3,
                          child: StatCard(
                            icon: Icons.calendar_today,
                            value: '2',
                            label: AppLocalizations.of(
                              context,
                            )!.get('todayAppointments'),
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingL),

                    // Critical Patients Alert
                    if (_mockPatients.any((p) => p['status'] == 'Critical'))
                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 400),
                        child: AlertCard(
                          title: AppLocalizations.of(
                            context,
                          )!.get('criticalAlert'),
                          message:
                              '${_mockPatients.where((p) => p['status'] == 'Critical').length} ${AppLocalizations.of(context)!.get('patientsNeedAttention')}',
                          buttonText: AppLocalizations.of(context)!.get('view'),
                          onTap: () {
                            final criticalPatients =
                                _mockPatients
                                    .where((p) => p['status'] == 'Critical')
                                    .toList();
                            Navigator.pushNamed(
                              context,
                              '/patient_detail',
                              arguments: criticalPatients.first,
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: AppDimensions.paddingL),

                    // Recent Patients Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SectionTitle(
                          title: AppLocalizations.of(
                            context,
                          )!.get('recentPatients'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _currentIndex = 1;
                            });
                          },
                          child: Text(
                            AppLocalizations.of(context)!.get('seeAll'),
                            style: const TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingS),
                    ..._mockPatients
                        .take(3)
                        .map(
                          (patient) => PatientCard(
                            name: patient['name'],
                            email: patient['email'],
                            status: patient['status'],
                            heartRate: patient['heartRate'],
                            lastUpdate: patient['lastUpdate'],
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/patient_detail',
                                arguments: patient,
                              );
                            },
                            onMessageTap: () {
                              Navigator.pushNamed(
                                context,
                                '/patient_chat',
                                arguments: patient,
                              );
                            },
                          ),
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

  Widget _buildPatientsContent() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.get('myPatients'),
          style: const TextStyle(
            color: AppColors.darkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: DecoratedBackground(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(
                      context,
                    )!.get('searchPatients'),
                    hintStyle: const TextStyle(color: AppColors.grey),
                    prefixIcon: const Icon(Icons.search, color: AppColors.grey),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppColors.grey,
                              ),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                            : null,
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            // Patient List
            Expanded(
              child:
                  _filteredPatients.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: AppColors.primaryBlue.withValues(
                                alpha: 0.1,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No patients found',
                              style: TextStyle(
                                color: AppColors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingM,
                        ),
                        itemCount: _filteredPatients.length,
                        itemBuilder: (context, index) {
                          final patient = _filteredPatients[index];
                          return PatientCard(
                            name: patient['name'],
                            email: patient['email'],
                            status: patient['status'],
                            heartRate: patient['heartRate'],
                            lastUpdate: patient['lastUpdate'],
                            highlightText: _searchQuery,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/patient_detail',
                                arguments: patient,
                              );
                            },
                            onMessageTap: () {
                              Navigator.pushNamed(
                                context,
                                '/patient_chat',
                                arguments: patient,
                              );
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
