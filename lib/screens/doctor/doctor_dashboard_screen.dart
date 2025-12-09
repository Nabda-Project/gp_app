import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/storage_service.dart';
import '../../models/user_model.dart';
import '../profile/profile_screen.dart';
import '../../utils/app_localizations.dart';
import '../../widgets/reusable/decorated_background.dart';
import '../../widgets/reusable/section_title.dart';
import '../../widgets/reusable/patient_card.dart';

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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: AppColors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              activeIcon: const Icon(Icons.dashboard),
              label: AppLocalizations.of(context)!.get('dashboard'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people_outline),
              activeIcon: const Icon(Icons.people),
              label: AppLocalizations.of(context)!.get('myPatients'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: AppLocalizations.of(context)!.get('profile'),
            ),
          ],
        ),
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
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: SafeArea(
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
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.medical_services,
                                    color: AppColors.primaryBlue,
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.paddingM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.get('hello'),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      "Dr. ${_currentUser?.fullName ?? 'Doctor'}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/notifications',
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
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
                    // Quick Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickStat(
                            icon: Icons.people,
                            value: '${_mockPatients.length}',
                            label: AppLocalizations.of(
                              context,
                            )!.get('totalPatients'),
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.paddingM),
                        Expanded(
                          child: _buildQuickStat(
                            icon: Icons.warning_amber_rounded,
                            value:
                                '${_mockPatients.where((p) => p['status'] != 'Normal').length}',
                            label: 'Need Attention',
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingM),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickStat(
                            icon: Icons.message,
                            value: '3',
                            label: AppLocalizations.of(
                              context,
                            )!.get('pendingMessages'),
                            color: AppColors.accentTeal,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.paddingM),
                        Expanded(
                          child: _buildQuickStat(
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
                      _buildCriticalAlert(),

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
                      color: Colors.black.withOpacity(0.04),
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
                              color: AppColors.grey.withOpacity(0.5),
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

  Widget _buildQuickStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalAlert() {
    final criticalPatients =
        _mockPatients.where((p) => p['status'] == 'Critical').toList();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.error.withOpacity(0.1),
            AppColors.error.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: AppColors.error,
              size: 24,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Critical Alert',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${criticalPatients.length} patient(s) need immediate attention',
                  style: TextStyle(
                    color: AppColors.error.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/patient_detail',
                arguments: criticalPatients.first,
              );
            },
            child: const Text(
              'View',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
