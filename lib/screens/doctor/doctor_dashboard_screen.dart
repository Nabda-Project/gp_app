import 'package:flutter/material.dart';
import 'dart:developer';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../services/storage_service.dart';
import '../../services/doctor_api_service.dart';
import '../../services/chat_service.dart';
import '../../services/presence_service.dart';
import '../../models/user_model.dart';
import '../../models/patient_response_model.dart';
import '../../models/chat_contact_model.dart';
import '../../services/appointment_api_service.dart';
import '../../core/api/api_exceptions.dart';
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
import '../../widgets/reusable/assign_patient_sheet.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  int _currentIndex = 0;
  UserModel? _currentUser;
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();
  String _searchQuery = '';

  // Real data from API
  List<PatientResponseModel> _patients = [];
  bool _isLoadingPatients = true;
  String? _patientsError;

  int _todayAppointmentsCount = 0;

  // Chat-related state for the Chats tab
  List<ChatContactModel> _chatContacts = [];
  Map<int, PresenceStatus> _presenceMap = {};
  bool _isLoadingChats = true;

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
    _pageController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _loadUser() {
    final user = StorageService.getUser();
    setState(() {
      _currentUser = user;
    });
    if (user?.backendId != null) {
      _fetchPatients(user!.backendId!);
      _fetchAppointments(user.backendId!);
      _loadChatsData();
    } else {
      setState(() {
        _isLoadingPatients = false;
        _patientsError = 'Doctor ID not found. Please log in again.';
      });
    }
  }

  Future<void> _fetchPatients(int doctorId) async {
    setState(() {
      _isLoadingPatients = true;
      _patientsError = null;
    });

    try {
      final patients = await DoctorApiService.getAssignedPatients(doctorId);
      if (mounted) {
        setState(() {
          _patients = patients;
          _isLoadingPatients = false;
        });
      }
    } on NetworkException catch (e) {
      log('Network error fetching patients: ${e.message}', name: 'DoctorDashboard');
      if (mounted) {
        setState(() {
          _isLoadingPatients = false;
          _patientsError = AppLocalizations.of(context)!.get('connectionError');
        });
      }
    } on ServerException catch (e) {
      log('Server error fetching patients: ${e.message}', name: 'DoctorDashboard');
      if (mounted) {
        setState(() {
          _isLoadingPatients = false;
          _patientsError = AppLocalizations.of(context)!.get('serverError');
        });
      }
    } on ApiException catch (e) {
      log('Failed to fetch patients: ${e.message}', name: 'DoctorDashboard');
      if (mounted) {
        setState(() {
          _isLoadingPatients = false;
          _patientsError = e.message;
        });
      }
    } on DioException catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingPatients = false;
          _patientsError = AppLocalizations.of(context)!.get('connectionError');
        });
      }
    } catch (e) {
      log('Failed to fetch patients: $e', name: 'DoctorDashboard');
      if (mounted) {
        setState(() {
          _isLoadingPatients = false;
          _patientsError = AppLocalizations.of(context)!.get('unexpectedError');
        });
      }
    }
  }

  Future<void> _fetchAppointments(int doctorId) async {
    try {
      final appointments = await AppointmentApiService.getDoctorAppointments(doctorId);
      if (mounted) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        int count = 0;
        for (var appt in appointments) {
          if (appt.status != 'SCHEDULED') continue;
          final apptDateLocal = appt.appointmentDate.toLocal();
          final apptDay = DateTime(apptDateLocal.year, apptDateLocal.month, apptDateLocal.day);
          if (apptDay.isAtSameMomentAs(today)) {
            count++;
          }
        }
        setState(() {
          _todayAppointmentsCount = count;
        });
      }
    } catch (e) {
      log('Failed to fetch appointments for count: $e', name: 'DoctorDashboard');
    }
  }

  /// Refreshes the patient list silently in the background —
  /// the existing list stays visible (no spinner) while the API call runs.
  Future<void> _silentRefreshPatients(int doctorId) async {
    try {
      final patients = await DoctorApiService.getAssignedPatients(doctorId);
      if (mounted) {
        setState(() {
          _patients = patients;
        });
      }
    } catch (e) {
      log('Silent refresh failed: $e', name: 'DoctorDashboard');
      // Swallow silently — user still sees the optimistic update.
    }
  }

  /// Show a confirmation dialog then remove the patient (optimistic update).
  Future<void> _removePatient(PatientResponseModel patient) async {
    final doctorId = _currentUser?.backendId;
    if (doctorId == null) return;
    final loc = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.person_remove_rounded, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                loc.get('removePatient'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.darkBlue,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.get('removePatientConfirm'),
              style: const TextStyle(color: AppColors.grey, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.lightGrey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                    child: Text(
                      patient.fullName.isNotEmpty ? patient.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkBlue,
                          ),
                        ),
                        Text(
                          patient.email,
                          style: const TextStyle(color: AppColors.grey, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              loc.get('cancel'),
              style: const TextStyle(color: AppColors.grey),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: Text(loc.get('remove')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Optimistic removal
    setState(() {
      _patients = _patients.where((p) => p.id != patient.id).toList();
    });

    try {
      await DoctorApiService.removePatient(doctorId, patient.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.get('removePatientSuccess'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.accentTeal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      log('Failed to remove patient: $e', name: 'DoctorDashboard');
      // Rollback optimistic change
      if (mounted) {
        setState(() {
          _patients = [..._patients, patient];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.get('removePatientError')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  List<PatientResponseModel> get _filteredPatients {
    if (_searchQuery.isEmpty) {
      return _patients;
    }
    return _patients.where((patient) {
      final name = patient.fullName.toLowerCase();
      return name.contains(_searchQuery);
    }).toList();
  }

  /// Determine display status from priority
  String _priorityToStatus(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return 'Critical';
      case 'MEDIUM':
        return 'Warning';
      default:
        return 'Normal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboardContent(),
      _buildChatsContent(),
      _buildPatientsContent(),
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
            icon: Icons.chat_outlined,
            activeIcon: Icons.chat,
            label: AppLocalizations.of(context)?.get('chat') ?? 'Chats',
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
    final criticalCount = _patients.where((p) => _priorityToStatus(p.priority) == 'Critical').length;
    final warningCount = _patients.where((p) => _priorityToStatus(p.priority) != 'Normal').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            if (_currentUser?.backendId != null) {
              await Future.wait([
                _fetchPatients(_currentUser!.backendId!),
                _fetchAppointments(_currentUser!.backendId!),
                _loadChatsData(),
              ]);
            }
          },
          color: AppColors.primaryBlue,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                                      Icons.medical_services,
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
                                        "Dr. ${_currentUser?.fullName ?? 'Doctor'}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
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
                                    color: Colors.white.withValues(alpha: 0.15),
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
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.calendar_month_outlined,
                                      color: Colors.white,
                                    ),
                                    onPressed: () async {
                                      await Navigator.pushNamed(context, '/doctor_appointments');
                                      if (_currentUser?.backendId != null) {
                                        _fetchAppointments(_currentUser!.backendId!);
                                      }
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
                            value: '${_patients.length}',
                            label: AppLocalizations.of(context)!.get('totalPatients'),
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        AnimatedListItem(
                          index: 1,
                          child: StatCard(
                            icon: Icons.warning_amber_rounded,
                            value: '$warningCount',
                            label: AppLocalizations.of(context)!.get('needAttention'),
                            color: Colors.orange,
                          ),
                        ),
                        AnimatedListItem(
                          index: 2,
                          child: StatCard(
                            icon: Icons.message,
                            value: '${_chatContacts.where((c) => c.unreadCount > 0).length}',
                            label: AppLocalizations.of(context)!.get('pendingMessages'),
                            color: AppColors.accentTeal,
                          ),
                        ),
                        AnimatedListItem(
                          index: 3,
                          child: StatCard(
                            icon: Icons.calendar_today,
                            value: '$_todayAppointmentsCount',
                            label: AppLocalizations.of(context)!.get('todayAppointments'),
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingL),

                    // Critical Patients Alert
                    if (criticalCount > 0)
                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 400),
                        child: AlertCard(
                          title: AppLocalizations.of(context)!.get('criticalAlert'),
                          message:
                              '$criticalCount ${AppLocalizations.of(context)!.get('patientsNeedAttention')}',
                          buttonText: AppLocalizations.of(context)!.get('view'),
                          onTap: () {
                            // Navigate to patients tab
                            setState(() => _currentIndex = 1);
                            _pageController.animateToPage(
                              1,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
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
                          title: AppLocalizations.of(context)!.get('recentPatients'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _currentIndex = 2);
                            _pageController.animateToPage(
                              2,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
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

                    // Loading / Error / Real data
                    if (_isLoadingPatients)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_patientsError != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: AppColors.grey),
                              const SizedBox(height: 12),
                              Text(
                                _patientsError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.grey),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () {
                                  if (_currentUser?.backendId != null) {
                                    _fetchPatients(_currentUser!.backendId!);
                                  }
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_patients.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(Icons.people_outline, size: 48, color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                              const SizedBox(height: 12),
                              const Text(
                                'No patients assigned yet.',
                                style: TextStyle(color: AppColors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._patients.take(3).map(
                        (patient) => PatientCard(
                          name: patient.fullName,
                          email: patient.email,
                          status: _priorityToStatus(patient.priority),
                          heartRate: '--',
                          lastUpdate: '',
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/patient_detail',
                              arguments: {
                                'id': patient.id.toString(),
                                'backendId': patient.id,
                                'name': patient.fullName,
                                'email': patient.email,
                                'status': _priorityToStatus(patient.priority),
                                'heartRate': '--',
                                'lastUpdate': '',
                              },
                            ).then((_) {
                              if (_currentUser?.backendId != null) {
                                _fetchAppointments(_currentUser!.backendId!);
                              }
                            });
                          },
                          onMessageTap: () {
                            Navigator.pushNamed(
                              context,
                              '/patient_chat',
                              arguments: {
                                'name': patient.fullName,
                                'email': patient.email,
                                'backendId': patient.id,
                              },
                            ).then((_) {
                              setState(() => _isLoadingChats = true);
                              _loadChatsData();
                            });
                          },
                          onDeleteTap: () => _removePatient(patient),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
  // ─── Chats Tab ────────────────────────────────────────────────────────────

  /// Load conversations from the new API — only partners with existing messages.
  Future<void> _loadChatsData() async {
    final myId = _currentUser?.backendId;
    if (myId == null) return;

    try {
      final chatService = ChatService(currentUserId: myId);
      final contacts = await chatService.fetchConversations();

      // Fetch presence in parallel for each contact
      final presenceMap = <int, PresenceStatus>{};
      await Future.wait(contacts.map((contact) async {
        try {
          final presence =
              await PresenceService.fetchPresence(contact.partnerId);
          presenceMap[contact.partnerId] = presence;
        } catch (_) {
          presenceMap[contact.partnerId] =
              PresenceStatus(online: false, lastSeen: null);
        }
      }));

      if (mounted) {
        setState(() {
          _chatContacts = contacts;
          _presenceMap = presenceMap;
          _isLoadingChats = false;
        });
      }
    } catch (e) {
      log('Failed to load chats: $e', name: 'DoctorDashboard');
      if (mounted) {
        setState(() => _isLoadingChats = false);
      }
    }
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Offline';
    final now = DateTime.now();
    final diff = now.difference(lastSeen);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(lastSeen);
  }

  Widget _buildChatsContent() {
    // Trigger loading chats data once
    if (!_isLoadingPatients && _isLoadingChats) {
      _loadChatsData();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.get('chat') ?? 'Chats',
          style: const TextStyle(
            color: AppColors.darkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: DecoratedBackground(
        child: _isLoadingChats
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryBlue))
            : _chatContacts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64,
                            color: AppColors.grey.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text(
                          'No conversations yet.\nStart chatting from the Patients tab!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.grey.withValues(alpha: 0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      setState(() => _isLoadingChats = true);
                      await _loadChatsData();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingM,
                        vertical: AppDimensions.paddingS,
                      ),
                      itemCount: _chatContacts.length,
                      itemBuilder: (context, index) {
                        final contact = _chatContacts[index];
                        final presence =
                            _presenceMap[contact.partnerId];
                        final isOnline = presence?.online ?? false;

                        return _buildChatTile(
                          contact: contact,
                          isOnline: isOnline,
                          lastSeen: presence?.lastSeen,
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildChatTile({
    required ChatContactModel contact,
    required bool isOnline,
    DateTime? lastSeen,
  }) {
    final lastMsgText = contact.lastMessage.isNotEmpty
        ? contact.lastMessage
        : 'No messages yet';
    final lastMsgTime = contact.lastMessageTimestamp != null
        ? DateFormat('h:mm a').format(contact.lastMessageTimestamp!)
        : '';
    final statusText = isOnline ? 'Online' : _formatLastSeen(lastSeen);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/patient_chat',
              arguments: {
                'name': contact.partnerName,
                'email': contact.partnerEmail,
                'backendId': contact.partnerId,
              },
            ).then((_) {
              // Refresh chats data to update unread counts
              setState(() => _isLoadingChats = true);
              _loadChatsData();
            });
          },
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: 14,
            ),
            child: Row(
              children: [
                // Avatar with online indicator
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor:
                          AppColors.primaryBlue.withValues(alpha: 0.1),
                      child: Text(
                        contact.partnerName.isNotEmpty
                            ? contact.partnerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? AppColors.accentTeal
                              : AppColors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.white, width: 2.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppDimensions.paddingM),
                // Name + last message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.partnerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBlue,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMsgText,
                        style: TextStyle(
                          color: AppColors.grey.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Time, status & unread
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (lastMsgTime.isNotEmpty)
                      Text(
                        lastMsgTime,
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 11,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (contact.unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${contact.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? AppColors.accentTeal.withValues(alpha: 0.1)
                                : AppColors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: isOnline
                                  ? AppColors.accentTeal
                                  : AppColors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_currentUser?.backendId == null) return;
          AssignPatientSheet.show(
            context,
            doctorId: _currentUser!.backendId!,
            onAssigned: (PatientResponseModel newPatient) {
              // Optimistic update — add immediately without waiting for the API.
              setState(() {
                _patients = [..._patients, newPatient];
              });
              // Then silently sync with server in background.
              _silentRefreshPatients(_currentUser!.backendId!);
            },
          );
        },
        icon: const Icon(Icons.person_add_rounded),
        label: Text(AppLocalizations.of(context)!.get('assignPatient')),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
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
                    hintText: AppLocalizations.of(context)!.get('searchPatients'),
                    hintStyle: const TextStyle(color: AppColors.grey),
                    prefixIcon: const Icon(Icons.search, color: AppColors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.grey),
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
              child: _isLoadingPatients
                  ? const Center(child: CircularProgressIndicator())
                  : _patientsError != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 64, color: AppColors.grey),
                              const SizedBox(height: 16),
                              Text(
                                _patientsError!,
                                style: const TextStyle(color: AppColors.grey, fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () {
                                  if (_currentUser?.backendId != null) {
                                    _fetchPatients(_currentUser!.backendId!);
                                  }
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _filteredPatients.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No patients found'
                                        : 'No patients assigned yet.',
                                    style: const TextStyle(
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
                                return Dismissible(
                                  key: ValueKey(patient.id),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (_) async {
                                    await _removePatient(patient);
                                    // always return false — _removePatient manages state
                                    return false;
                                  },
                                  background: Container(
                                    margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.delete_rounded, color: Colors.white, size: 26),
                                        SizedBox(height: 4),
                                        Text(
                                          'Remove',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  child: PatientCard(
                                    name: patient.fullName,
                                    email: patient.email,
                                    status: _priorityToStatus(patient.priority),
                                    heartRate: '--',
                                    lastUpdate: '',
                                    highlightText: _searchQuery,
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/patient_detail',
                                        arguments: {
                                          'id': patient.id.toString(),
                                          'backendId': patient.id,
                                          'name': patient.fullName,
                                          'email': patient.email,
                                          'status': _priorityToStatus(patient.priority),
                                          'heartRate': '--',
                                          'lastUpdate': '',
                                        },
                                      ).then((_) {
                                        if (_currentUser?.backendId != null) {
                                          _fetchAppointments(_currentUser!.backendId!);
                                        }
                                      });
                                    },
                                    onMessageTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/patient_chat',
                                        arguments: {
                                          'name': patient.fullName,
                                          'email': patient.email,
                                          'backendId': patient.id,
                                        },
                                      ).then((_) {
                                        setState(() => _isLoadingChats = true);
                                        _loadChatsData();
                                      });
                                    },
                                    onDeleteTap: () => _removePatient(patient),
                                  ),
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
