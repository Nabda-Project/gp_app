import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import '../../models/appointment_model.dart';
import '../../services/appointment_api_service.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../widgets/reusable/decorated_background.dart';
import '../../widgets/animations/fade_slide_transition.dart';
import '../../widgets/animations/animated_list_item.dart';
import '../../widgets/reusable/custom_bottom_nav.dart';
import '../../services/chat_service.dart';
import '../../services/notification_api_service.dart';
import '../../services/notification_service.dart';
import '../../services/push_notification_service.dart';
import '../../models/chat_message_model.dart';
import 'doctor_chat_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../widgets/reusable/dashboard_skeleton.dart';
import '../../widgets/reusable/server_down_view.dart';
import '../../widgets/reusable/no_internet_view.dart';
import '../../widgets/reusable/user_avatar.dart';
import '../../core/api/api_exceptions.dart';
import '../../services/api_service.dart';
import '../../services/health_monitor_service.dart';
import '../../services/iot_api_service.dart';
import '../../models/device_reading.dart';
import '../../models/health_metric_model.dart';
import '../../services/token_service.dart';
import '../../core/config/api_config.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../../features/ai_assessment/data/ai_assessment_api.dart';

enum AppNetworkState { checking, normal, noInternet, serverDown }

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
  AppointmentModel? _nextAppointment;
  bool _loadingAppointment = true;
  final PageController _pageController = PageController();
  StreamSubscription<Map<String, dynamic>>? _systemEventSubscription;
  StreamSubscription<ChatMessageModel>? _chatMessageSubscription;
  StreamSubscription<dynamic>? _connectivitySubscription;
  AppNetworkState _networkState = AppNetworkState.checking;
  int _unreadChatCount = 0;
  int _unreadNotifCount = 0;

  // ── Device integration state (now driven by HealthMonitorService) ──
  StreamSubscription<Map<String, dynamic>?>? _serviceReadingSub;
  StreamSubscription<Map<String, dynamic>?>? _serviceStatusSub;
  StreamSubscription<Map<String, dynamic>?>? _serviceMetricSub;
  DeviceReading? _latestReading;
  HealthMetricModel? _latestMetric;
  bool _deviceConnected = false;
  /// True when the foreground service is running (may or may not have readings).
  bool _serviceRunning = false;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _loadUser();
    _restoreServiceState();
  }

  /// On app launch / resume, check if the foreground service is already
  /// running and subscribe to its IPC streams.
  Future<void> _restoreServiceState() async {
    final running = await HealthMonitorService.isRunning();
    if (running) {
      log('Service already running — restoring UI state', name: 'PatientDashboard');
      _subscribeToService();
      if (mounted) setState(() => _serviceRunning = true);
    }
  }

  /// Subscribe to the background service IPC streams.
  void _subscribeToService() {
    _serviceReadingSub?.cancel();
    _serviceStatusSub?.cancel();
    _serviceMetricSub?.cancel();

    _serviceReadingSub = HealthMonitorService.on.listen((data) {
      if (data == null || !mounted) return;
      final connected = data['connected'] as bool? ?? false;
      if (connected) {
        final reading = DeviceReading(
          heartRate: (data['hr'] as num?)?.toDouble() ?? 0,
          spo2: (data['spo2'] as num?)?.toDouble() ?? 0,
          batteryLevel: (data['battery'] as num?)?.toInt() ?? 0,
          timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
        );
        setState(() {
          _latestReading = reading;
          _deviceConnected = true;
        });
      } else {
        setState(() {
          _deviceConnected = false;
          _latestReading = null;
        });
      }
    });

    _serviceStatusSub = HealthMonitorService.onStatus.listen((data) {
      if (data == null || !mounted) return;
      final status = data['status'] as String?;
      if (status == 'authError') {
        log('Service reported auth error', name: 'PatientDashboard');
        setState(() {
          _serviceRunning = false;
          _deviceConnected = false;
          _latestReading = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Login required — health monitoring paused'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    });

    // Listen for metric responses from backend uploads.
    _serviceMetricSub = FlutterBackgroundService().on('metricUpdate').listen((data) {
      if (data == null || !mounted) return;
      try {
        final metric = HealthMetricModel.fromJson(data);
        setState(() => _latestMetric = metric);
      } catch (e) {
        log('Could not parse metricUpdate: $e', name: 'PatientDashboard');
      }
    });
  }

  void _initConnectivity() async {
    final initialResult = await Connectivity().checkConnectivity();
    _updateNetworkState(initialResult);

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateNetworkState);
  }

  void _updateNetworkState(dynamic result) {
    bool isDisconnected = false;
    if (result is List) {
      if (result.isEmpty || result.contains(ConnectivityResult.none)) {
         if (!result.contains(ConnectivityResult.wifi) && 
             !result.contains(ConnectivityResult.mobile) && 
             !result.contains(ConnectivityResult.ethernet)) {
           isDisconnected = true;
         }
      }
    } else {
      isDisconnected = result == ConnectivityResult.none;
    }
        
    log('Network state updated: disconnected=$isDisconnected, raw_result=$result', name: 'PatientDashboard');

    if (mounted) {
      setState(() {
        if (isDisconnected) {
          _networkState = AppNetworkState.noInternet;
        } else {
          if (_networkState == AppNetworkState.noInternet) {
            _networkState = AppNetworkState.checking;
            _loadUser(); // Retry loading when internet comes back
          }
        }
      });
    }
  }

  void _handleApiException(dynamic e) {
    if (e is ServerException || e is NetworkException) {
      if (mounted && _networkState != AppNetworkState.noInternet) {
        setState(() => _networkState = AppNetworkState.serverDown);
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _systemEventSubscription?.cancel();
    _chatMessageSubscription?.cancel();
    _serviceReadingSub?.cancel();
    _serviceStatusSub?.cancel();
    _serviceMetricSub?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // ── Device Integration Methods ──────────────────────────────────────────

  void _showConnectDeviceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.watch, size: 48, color: AppColors.primaryBlue),
              ),
              const SizedBox(height: 20),
              const Text(
                'Connect Nabda Device',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkBlue),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStep('1', 'Enable your phone\'s Mobile Hotspot'),
                    const SizedBox(height: 10),
                    _buildStep('2', 'Set hotspot name to: nabda'),
                    const SizedBox(height: 10),
                    _buildStep('3', 'Set password to: 12345678'),
                    const SizedBox(height: 10),
                    _buildStep('4', 'Power on your Nabda device'),
                    const SizedBox(height: 10),
                    _buildStep('5', 'Wait for the device LED to stop blinking'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _connectDevice();
                    },
                    icon: const Icon(Icons.wifi_tethering, color: Colors.white),
                    label: const Text('Start Listening', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: AppColors.darkBlue))),
      ],
    );
  }

  /// Starts the foreground health-monitoring service.
  /// The service owns the UDP socket and backend uploads.
  Future<void> _connectDevice() async {
    final patientId = _currentUser?.backendId;
    if (patientId == null) {
      log('Cannot start service — no backendId', name: 'PatientDashboard');
      return;
    }

    // Check if already running.
    if (await HealthMonitorService.isRunning()) {
      log('Service already running — subscribing to updates',
          name: 'PatientDashboard');
      _subscribeToService();
      if (mounted) setState(() => _serviceRunning = true);
      return;
    }

    final token = await TokenService.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Login required to start health monitoring'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return;
    }

    try {
      final started = await HealthMonitorService.start(
        patientId: patientId,
        token: token,
        baseUrl: ApiConfig.baseUrl,
      );

      if (started) {
        _subscribeToService();
        if (mounted) setState(() => _serviceRunning = true);
        log('Foreground service started', name: 'PatientDashboard');

        // Show battery optimization dialog on first start.
        _maybeShowBatteryOptDialog();
      }
    } catch (e) {
      log('Failed to start foreground service: $e', name: 'PatientDashboard');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to start health monitoring service'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  /// Stops the foreground service and cleans up UI state.
  Future<void> _disconnectDevice() async {
    await HealthMonitorService.stop();
    _serviceReadingSub?.cancel();
    _serviceStatusSub?.cancel();
    _serviceMetricSub?.cancel();
    _serviceReadingSub = null;
    _serviceStatusSub = null;
    _serviceMetricSub = null;
    if (mounted) {
      setState(() {
        _serviceRunning = false;
        _deviceConnected = false;
        _latestReading = null;
      });
    }
    log('Foreground service stopped', name: 'PatientDashboard');
  }

  /// Show battery optimization exemption dialog once (first time only).
  Future<void> _maybeShowBatteryOptDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyAsked = prefs.getBool('bg_battery_opt_asked') ?? false;
    if (alreadyAsked || !mounted) return;

    await prefs.setBool('bg_battery_opt_asked', true);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.battery_saver, color: AppColors.primaryBlue),
            SizedBox(width: 8),
            Expanded(child: Text('Battery Optimization', style: TextStyle(fontSize: 18))),
          ],
        ),
        content: const Text(
          'For continuous health monitoring while the screen is off, '
          'please allow the battery optimization exception.\n\n'
          'Some devices may stop the monitoring service without this permission.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _requestBatteryOptimizationExemption();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Allow', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Open system battery optimization settings for this app.
  Future<void> _requestBatteryOptimizationExemption() async {
    try {
      // Use Android's built-in intent to request ignoring battery optimizations.
      // android.provider.Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS
      const channel = MethodChannel('com.example.gp_app/battery');
      await channel.invokeMethod('requestBatteryOptimization');
    } catch (e) {
      log('Could not open battery optimization settings: $e',
          name: 'PatientDashboard');
      // The dialog itself already informed the user about manual steps.
    }
  }

  Future<void> _loadUser() async {
    final user = StorageService.getUser();
    setState(() {
      _currentUser = user;
    });

    if (user?.backendId != null) {
      if (_networkState != AppNetworkState.noInternet) {
        try {
          final check = await ApiService.testConnection();
          if (check.contains('Error') || check.contains('Exception')) {
             if (mounted) setState(() => _networkState = AppNetworkState.serverDown);
             return;
          } else {
             if (mounted) setState(() => _networkState = AppNetworkState.normal);
          }
        } catch (_) {
           if (mounted) setState(() => _networkState = AppNetworkState.serverDown);
           return;
        }
      }

      // Initialize the global ChatService singleton (connects WebSocket + starts presence)
      // Fetch initial unread notification count
      _fetchUnreadNotifCount(user!.backendId!);

      ChatService.initialize(user.backendId!).then((_) {
        // Listen for system events (e.g. doctor assignment/removal)
        _systemEventSubscription = ChatService.instance?.systemEvents.listen((event) {
          if (event['type'] == 'PATIENT_ASSIGNED' && mounted) {
            _fetchAssignedDoctor(user);
            _fetchNextAppointment(user);
            _fetchUnreadNotifCount(user.backendId!);
            PushNotificationService.showHeadsUpNotification(
              title: 'Doctor Assigned',
              body: 'A doctor has been assigned to you',
            );
          } else if (event['type'] == 'PATIENT_REMOVED' && mounted) {
            setState(() {
              _assignedDoctor = null;
              _nextAppointment = null;
            });
            _fetchUnreadNotifCount(user.backendId!);
          } else if (event['type'] == 'APPOINTMENT_SCHEDULED' && mounted) {
            _fetchNextAppointment(user);
            _fetchUnreadNotifCount(user.backendId!);
            PushNotificationService.showHeadsUpNotification(
              title: 'New Appointment',
              body: 'A new appointment has been scheduled',
            );
          } else if (event['type'] == 'APPOINTMENT_CONFIRMED' && mounted) {
            _fetchNextAppointment(user);
            _fetchUnreadNotifCount(user.backendId!);
            PushNotificationService.showHeadsUpNotification(
              title: 'Appointment Confirmed',
              body: 'Your appointment has been confirmed',
            );
          } else if ((event['type'] == 'APPOINTMENT_CANCELLED' ||
                      event['type'] == 'APPOINTMENT_COMPLETED') && mounted) {
            setState(() => _nextAppointment = null);
            _fetchNextAppointment(user);
            _fetchUnreadNotifCount(user.backendId!);
          }
        });

        // Listen for new chat messages to update unread badge + play sound
        _chatMessageSubscription = ChatService.instance?.messages.listen((msg) {
          if (msg.senderId != user.backendId && mounted) {
            // Only increment if we're NOT currently on the chat tab
            if (_currentIndex != 1 || !_showChatTab) {
              setState(() => _unreadChatCount++);
              PushNotificationService.showHeadsUpNotification(
                title: msg.senderName ?? 'New Message',
                body: msg.content,
              );
            }
            _fetchUnreadNotifCount(user.backendId!);
          }
        });
      });
    }

    await Future.wait([
      _fetchAssignedDoctor(user),
      _fetchNextAppointment(user),
      _fetchLatestMetric(user!.backendId),
    ]);

    // NOTE: Service is NOT auto-started here.
    // It starts only when the user taps "Start Listening".
    // If the service is already running (from a previous session),
    // _restoreServiceState() handles re-subscribing to it.
  }

  Future<void> _fetchLatestMetric(int? backendId) async {
    if (backendId == null) return;
    try {
      final metric = await IoTApiService.getLatest(backendId);
      if (mounted) setState(() => _latestMetric = metric);
    } catch (e) {
      log('Could not load latest metric: $e', name: 'PatientDashboard');
    }
  }

  Future<void> _fetchNextAppointment(UserModel? user) async {
    if (user?.backendId == null) {
      setState(() => _loadingAppointment = false);
      return;
    }
    try {
      final appt = await AppointmentApiService.getNextAppointment(user!.backendId!);
      // Auto mark appointment notifications as read since user is looking at their dashboard
      NotificationApiService.markAppointmentsAsRead(user.backendId!);
      if (mounted) {
        setState(() {
          _nextAppointment = appt;
          _loadingAppointment = false;
        });
      }
    } catch (e) {
      log('Could not load next appointment: $e', name: 'PatientDashboard');
      _handleApiException(e);
      if (mounted) setState(() => _loadingAppointment = false);
    }
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
      _handleApiException(e);
      if (mounted) setState(() => _loadingDoctor = false);
    }
  }

  Future<void> _fetchUnreadNotifCount(int userId) async {
    try {
      final count = await NotificationApiService.getUnreadCount(userId);
      if (mounted) setState(() => _unreadNotifCount = count);
    } catch (e) {
      log('Could not load unread notification count: $e', name: 'PatientDashboard');
    }
  }

  /// Whether the chat tab should be visible (only when a doctor is assigned).
  bool get _showChatTab => _assignedDoctor != null;

  // ── Assessment Entry Bottom Sheet ──────────────────────────────────────

  void _showAssessmentEntrySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: _AssessmentEntrySheetContent(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_networkState == AppNetworkState.checking) {
      return const Scaffold(body: DashboardSkeleton());
    } else if (_networkState == AppNetworkState.noInternet) {
      return const NoInternetView();
    } else if (_networkState == AppNetworkState.serverDown) {
      return Scaffold(
        body: ServerDownView(
          onRefresh: () async {
            try {
              final result = await ApiService.testConnection();
              if (result.contains('Error') || result.contains('Exception')) return false;
              if (mounted) {
                setState(() => _networkState = AppNetworkState.checking);
                _loadUser();
              }
              return true;
            } catch (_) {
              return false;
            }
          },
        ),
      );
    }
  
    final List<Widget> pages = [
      _buildDashboardContent(),
      if (_showChatTab)
        DoctorChatScreen(
          doctorName: _assignedDoctor?.fullName,
          doctorId: _assignedDoctor?.id,
          doctorProfileImageUrl: _assignedDoctor?.profileImageUrl,
        ),
      const ProfileScreen(),
    ];

    // Determine the chat-tab-aware page index for the FAB visibility
    final bool isChatPage = _showChatTab && _currentIndex == 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          
          if (index == 0) {
            // Reload user in case profile was edited
            setState(() {
              _currentUser = StorageService.getUser();
            });
            // When returning to dashboard, refresh the general notification badge count
            if (_currentUser?.backendId != null) {
              _fetchUnreadNotifCount(_currentUser!.backendId!);
            }
          }
          
          // Clear badge when entering the chat tab and map it to DB via API
          if (_showChatTab && index == 1 && _unreadChatCount > 0) {
            setState(() => _unreadChatCount = 0);
            if (_currentUser?.backendId != null && _assignedDoctor?.id != null) {
              NotificationApiService.markChatAsRead(
                _currentUser!.backendId!,
                _assignedDoctor!.id,
              ).then((_) => _fetchUnreadNotifCount(_currentUser!.backendId!)); // Refresh general count too
            }
          }
        },
        physics: const BouncingScrollPhysics(),
        children: pages,
      ),
      floatingActionButton:
          isChatPage
              ? null
              : FloatingActionButton(
                onPressed: _showAssessmentEntrySheet,
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
          if (_showChatTab)
            CustomNavItem(
              icon: Icons.message_outlined,
              activeIcon: Icons.message,
              label: AppLocalizations.of(context)!.get('chat'),
              badgeCount: _unreadChatCount,
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
              expandedHeight: 180,
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
                                  child: UserAvatar(
                                    imageUrl: _currentUser?.profileImageUrl,
                                    name: _currentUser?.fullName,
                                    radius: 26,
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.primaryBlue,
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
                                  child: Stack(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.notifications_outlined,
                                          color: Colors.white,
                                        ),
                                        onPressed: () async {
                                          await Navigator.pushNamed(context, '/notifications');
                                          if (_currentUser?.backendId != null) {
                                            _fetchUnreadNotifCount(_currentUser!.backendId!);
                                          }
                                        },
                                      ),
                                      if (_unreadNotifCount > 0)
                                        Positioned(
                                          right: 8,
                                          top: 8,
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.red,
                                              border: Border.all(color: Colors.white, width: 1.5),
                                            ),
                                          ),
                                        ),
                                    ],
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
                        status: _latestMetric?.healthStatus ?? 'UNKNOWN',
                        healthStatus: _latestMetric?.healthStatus ?? 'UNKNOWN',
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingL),
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 200),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SectionTitle(
                                title: AppLocalizations.of(context)!.get('vitals'),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  if (_currentUser?.backendId != null) {
                                    Navigator.pushNamed(context, '/patient_vitals', arguments: {
                                      'patientId': _currentUser!.backendId,
                                      'name': 'My Vitals',
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.show_chart, size: 14, color: AppColors.primaryBlue),
                                      SizedBox(width: 4),
                                      Text('View Charts',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primaryBlue)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Connect / Disconnect device button
                          GestureDetector(
                            onTap: (_serviceRunning || _deviceConnected) ? _disconnectDevice : _showConnectDeviceSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: (_serviceRunning || _deviceConnected)
                                    ? AppColors.accentTeal.withValues(alpha: 0.1)
                                    : AppColors.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: (_serviceRunning || _deviceConnected) ? AppColors.accentTeal : AppColors.primaryBlue,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    (_serviceRunning || _deviceConnected) ? Icons.wifi : Icons.wifi_off,
                                    size: 16,
                                    color: (_serviceRunning || _deviceConnected) ? AppColors.accentTeal : AppColors.primaryBlue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _serviceRunning
                                        ? (_deviceConnected ? 'Listening' : 'Waiting…')
                                        : 'Start Listener',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: (_serviceRunning || _deviceConnected) ? AppColors.accentTeal : AppColors.primaryBlue,
                                    ),
                                  ),
                                  if (_serviceRunning && _deviceConnected && _latestReading != null) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      width: 6, height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingM),

                    // Vitals Grid – live data from Nabda device
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
                            value: _latestReading != null
                                ? _latestReading!.heartRate.toStringAsFixed(0)
                                : '--',
                            unit: "bpm",
                            icon: Icons.favorite,
                            color: Colors.redAccent,
                          ),
                        ),
                        AnimatedListItem(
                          index: 1,
                          child: VitalCard(
                            label: AppLocalizations.of(context)!.get('bloodOxygen'),
                            value: _latestReading != null
                                ? _latestReading!.spo2.toStringAsFixed(0)
                                : '--',
                            unit: "%",
                            icon: Icons.water_drop,
                            color: Colors.lightBlue,
                          ),
                        ),
                        AnimatedListItem(
                          index: 2,
                          child: VitalCard(
                            label: AppLocalizations.of(context)!.get('batteryLevel'),
                            value: _latestReading != null
                                ? '${_latestReading!.batteryLevel}'
                                : '--',
                            unit: "%",
                            icon: Icons.battery_charging_full,
                            color: Colors.green,
                          ),
                        ),
                        AnimatedListItem(
                          index: 3,
                          child: VitalCard(
                            label: AppLocalizations.of(context)!.get('nextFollowUp'),
                            value: _loadingAppointment
                                ? '...'
                                : _nextAppointment != null
                                    ? DateFormat('MMM d').format(_nextAppointment!.appointmentDate.toLocal())
                                    : 'N/A',
                            unit: _nextAppointment != null
                                ? DateFormat('h:mm a').format(_nextAppointment!.appointmentDate.toLocal())
                                : '',
                            icon: Icons.calendar_today,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 80), // Padding to prevent floating action button overlapping
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
                          child: UserAvatar(
                            imageUrl: _assignedDoctor!.profileImageUrl,
                            name: _assignedDoctor!.fullName,
                            radius: 26,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            foregroundColor: Colors.white,
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

  // Follow-up card removed — appointment info is now displayed in the vitals grid.
}

// ── Assessment Entry Bottom Sheet Content ─────────────────────────────────
// Self-contained StatefulWidget so it can manage its own async loading state.

class _AssessmentEntrySheetContent extends StatefulWidget {
  @override
  State<_AssessmentEntrySheetContent> createState() =>
      _AssessmentEntrySheetContentState();
}

enum _SheetState { loading, hasReports, noReports, error }

class _AssessmentEntrySheetContentState
    extends State<_AssessmentEntrySheetContent> {
  _SheetState _state = _SheetState.loading;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    if (mounted) setState(() => _state = _SheetState.loading);
    try {
      final reports = await AiAssessmentApiService.getMyReports();
      if (!mounted) return;
      setState(() {
        _state = reports.isEmpty ? _SheetState.noReports : _SheetState.hasReports;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _SheetState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Icon
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const FaIcon(
                FontAwesomeIcons.heartPulse,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            // Dynamic content based on state
            _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _SheetState.loading:
        return _buildLoading();
      case _SheetState.hasReports:
        return _buildHasReports();
      case _SheetState.noReports:
        return _buildNoReports();
      case _SheetState.error:
        return _buildError();
    }
  }

  Widget _buildLoading() {
    return const Column(
      children: [
        Text(
          'تقييم صحة القلب',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            color: AppColors.darkBlue,
          ),
        ),
        SizedBox(height: 20),
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            color: AppColors.primaryBlue,
            strokeWidth: 3,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'جارٍ التحقق من التقارير السابقة...',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Cairo',
            color: AppColors.grey,
          ),
        ),
        SizedBox(height: 12),
      ],
    );
  }

  Widget _buildHasReports() {
    return Column(
      children: [
        const Text(
          'تقييم صحة القلب',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            color: AppColors.darkBlue,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'هل تريد بدء تقييم جديد أم عرض تقاريرك السابقة؟',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Cairo',
            color: AppColors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // Start new assessment
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/assessment_welcome');
              },
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: const Text('بدء تقييم جديد',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // View previous reports
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/report_history');
            },
            icon: const Icon(Icons.history_rounded),
            label: const Text('عرض التقارير السابقة',
                style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoReports() {
    return Column(
      children: [
        const Text(
          'لا توجد تقارير سابقة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            color: AppColors.darkBlue,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'يمكنك بدء تقييم جديد الآن لإنشاء أول تقرير طبي.',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Cairo',
            color: AppColors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/assessment_welcome');
              },
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: const Text('بدء تقييم جديد',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.grey),
        const SizedBox(height: 12),
        const Text(
          'تعذر تحميل التقارير السابقة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            color: AppColors.darkBlue,
          ),
        ),
        const SizedBox(height: 24),
        // Start new assessment anyway
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/assessment_welcome');
              },
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: const Text('بدء تقييم جديد',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Retry
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _loadReports,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة',
                style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}
