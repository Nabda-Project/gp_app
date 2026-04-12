import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/app_localizations.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_api_service.dart';
import '../../services/notification_api_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/reusable/decorated_background.dart';
import '../../widgets/animations/fade_slide_transition.dart';
import '../../widgets/animations/animated_list_item.dart';
import '../../widgets/reusable/list_skeleton.dart';
import '../../widgets/reusable/empty_state_view.dart';
import 'package:intl/intl.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  bool _isLoading = true;
  List<AppointmentModel> _appointments = [];
  String? _errorMessage;
  bool _todayOnly = false;
  int _initialIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      if (args['todayOnly'] == true) {
        _todayOnly = true;
      }
      if (args['initialIndex'] != null) {
        _initialIndex = args['initialIndex'];
      }
    }
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = StorageService.getUser();
      if (user?.backendId == null) {
        throw Exception("Doctor ID not found in session");
      }
      final appointments = await AppointmentApiService.getDoctorAppointments(
        user!.backendId!,
      );
      // Auto mark appointment notifications as read when viewing this screen
      NotificationApiService.markAppointmentsAsRead(user.backendId!);

      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(
    AppointmentModel appointment,
    String newStatus,
  ) async {
    try {
      if (appointment.id == null) return;

      // Optimistic update
      setState(() {
        final index = _appointments.indexWhere((a) => a.id == appointment.id);
        if (index != -1) {
          _appointments[index] = AppointmentModel(
            id: appointment.id,
            doctorId: appointment.doctorId,
            doctorName: appointment.doctorName,
            patientId: appointment.patientId,
            patientName: appointment.patientName,
            appointmentDate: appointment.appointmentDate,
            reason: appointment.reason,
            status: newStatus,
          );
        }
      });

      await AppointmentApiService.updateAppointmentStatus(
        appointment.id!,
        newStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment status updated to $newStatus')),
        );
      }
    } catch (e) {
      // Revert on failure (simple refetch for safety)
      _fetchAppointments();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: _initialIndex,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
           title: Text(
            _initialIndex == 1
                ? (AppLocalizations.of(context)?.get('missedAppointments') ?? 'المواعيد الفائتة')
                : _todayOnly
                    ? (AppLocalizations.of(context)!.get('todayAppointments'))
                    : AppLocalizations.of(context)!.get('appointments'),
             style: const TextStyle(
              color: AppColors.darkBlue,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
           ),
          backgroundColor: AppColors.white,
          elevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: AppColors.darkBlue),
        ),
        body: DecoratedBackground(
          child: Column(
            children: [
              // Custom Segmented Control TabBar
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingL,
                  vertical: AppDimensions.paddingM,
                ),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: EdgeInsets.zero,
                  indicator: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: AppColors.primaryBlue,
                  unselectedLabelColor: AppColors.grey,
                  dividerColor: Colors.transparent,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  tabs: const [
                    Tab(height: 48, child: Text('Upcoming', textAlign: TextAlign.center)),
                    Tab(height: 48, child: Text('Missed', textAlign: TextAlign.center)),
                    Tab(height: 48, child: Text('Completed', textAlign: TextAlign.center)),
                    Tab(height: 48, child: Text('Cancelled', textAlign: TextAlign.center)),
                  ],
                ),
              ),
              Expanded(
                child:
                    _isLoading
                        ? const ListSkeleton(itemCount: 4, hasAvatar: false, compact: false)
                        : _errorMessage != null
                        ? EmptyStateView(
                            icon: Icons.error_outline_rounded,
                            title: 'Error loading',
                            description: _errorMessage!,
                            actionText: 'Retry',
                            onAction: _fetchAppointments,
                          )
                        : TabBarView(
                          children: [
                            _buildUpcomingTab(),
                            _buildMissedTab(),
                            _buildStatusTab('COMPLETED'),
                            _buildStatusTab('CANCELLED'),
                          ],
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTab(String status) {
    final filtered = _appointments.where((a) => a.status == status).toList();

    // Sort by date descending
    filtered.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

    if (filtered.isEmpty) {
      return EmptyStateView(
        icon: Icons.event_busy_rounded,
        title: 'No ${status.toLowerCase()} appointments',
        description: 'There are no $status appointments to show.',
      );
    }

    int indexCounter = 0;
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildAppointmentCard(filtered[index], indexCounter++);
      },
    );
  }

  Widget _buildUpcomingTab() {
    var upcoming =
        _appointments.where((a) => a.status == 'SCHEDULED').toList();

    // Only show today and future appointments
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    upcoming = upcoming.where((a) {
      final apptDateLocal = a.appointmentDate.toLocal();
      final apptDay = DateTime(apptDateLocal.year, apptDateLocal.month, apptDateLocal.day);
      
      if (_todayOnly) {
        return apptDay.isAtSameMomentAs(today);
      }
      return apptDay.isAtSameMomentAs(today) || apptDay.isAfter(today);
    }).toList();

    if (upcoming.isEmpty) {
      return EmptyStateView(
        icon: Icons.event_available_rounded,
        title: _todayOnly ? 'No appointments today' : 'No upcoming appointments',
        description: 'You have a clear schedule!',
      );
    }
    final todaysAppointments = <AppointmentModel>[];
    final tomorrowsAppointments = <AppointmentModel>[];
    final nextWeekAppointments = <AppointmentModel>[];
    final followingWeekAppointments = <AppointmentModel>[];
    final laterAppointments = <AppointmentModel>[];

    for (var appt in upcoming) {
      final apptDateLocal = appt.appointmentDate.toLocal();
      final apptDay = DateTime(
        apptDateLocal.year,
        apptDateLocal.month,
        apptDateLocal.day,
      );

      final diff = apptDay.difference(today).inDays;

      if (diff <= 0) {
        todaysAppointments.add(appt);
      } else if (diff == 1) {
        tomorrowsAppointments.add(appt);
      } else if (diff >= 2 && diff <= 7) {
        nextWeekAppointments.add(appt);
      } else if (diff >= 8 && diff <= 14) {
        followingWeekAppointments.add(appt);
      } else {
        laterAppointments.add(appt);
      }
    }

    void sortAppts(List<AppointmentModel> list) {
      list.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
    }

    sortAppts(todaysAppointments);
    sortAppts(tomorrowsAppointments);
    sortAppts(nextWeekAppointments);
    sortAppts(followingWeekAppointments);
    sortAppts(laterAppointments);

    int indexCounter = 0;
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      children: [
        if (todaysAppointments.isNotEmpty) ...[
          _buildSectionHeader('Today', Icons.today_rounded),
          ...todaysAppointments.map(
            (a) => _buildAppointmentCard(a, indexCounter++),
          ),
          const SizedBox(height: AppDimensions.paddingL),
        ],
        if (tomorrowsAppointments.isNotEmpty) ...[
          _buildSectionHeader('Tomorrow', Icons.wb_sunny_rounded),
          ...tomorrowsAppointments.map(
            (a) => _buildAppointmentCard(a, indexCounter++),
          ),
          const SizedBox(height: AppDimensions.paddingL),
        ],
        if (nextWeekAppointments.isNotEmpty) ...[
          _buildSectionHeader('Next Week', Icons.date_range_rounded),
          ...nextWeekAppointments.map(
            (a) => _buildAppointmentCard(a, indexCounter++),
          ),
          const SizedBox(height: AppDimensions.paddingL),
        ],
        if (followingWeekAppointments.isNotEmpty) ...[
          _buildSectionHeader('Following Week', Icons.event_note_rounded),
          ...followingWeekAppointments.map(
            (a) => _buildAppointmentCard(a, indexCounter++),
          ),
          const SizedBox(height: AppDimensions.paddingL),
        ],
        if (laterAppointments.isNotEmpty) ...[
          _buildSectionHeader('Later', Icons.history_rounded),
          ...laterAppointments.map(
            (a) => _buildAppointmentCard(a, indexCounter++),
          ),
        ],
      ],
    );
  }

  Widget _buildMissedTab() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final missed = _appointments.where((a) {
      if (a.status != 'SCHEDULED') return false;
      final apptDateLocal = a.appointmentDate.toLocal();
      final apptDay = DateTime(apptDateLocal.year, apptDateLocal.month, apptDateLocal.day);
      return apptDay.isBefore(today);
    }).toList();

    missed.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

    if (missed.isEmpty) {
      return const EmptyStateView(
        icon: Icons.event_available_rounded,
        title: 'No missed appointments',
        description: 'Great job! All appointments were attended.',
      );
    }

    int indexCounter = 0;
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      itemCount: missed.length,
      itemBuilder: (context, index) {
        return _buildAppointmentCard(missed[index], indexCounter++);
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppDimensions.paddingM,
        top: AppDimensions.paddingS,
      ),
      child: FadeSlideTransition(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.darkBlue,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Divider(
                color: AppColors.lightGrey.withValues(alpha: 0.5),
                thickness: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment, int index) {
    final localDateTime = appointment.appointmentDate.toLocal();
    final isDone = appointment.status == 'COMPLETED';
    final isCancelled = appointment.status == 'CANCELLED';

    final Color statusColor =
        isDone
            ? Colors.green
            : isCancelled
            ? Colors.red
            : AppColors.primaryBlue;

    return AnimatedListItem(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.paddingL),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkBlue.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      isDone
                          ? Icons.check_circle
                          : (isCancelled
                              ? Icons.cancel
                              : Icons.event_available),
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.patientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBlue,
                          ),
                        ),
                        if (appointment.reason != null &&
                            appointment.reason!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            appointment.reason!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      appointment.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Section
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.calendar_month,
                          size: 16,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, MMM d, yyyy').format(localDateTime),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.access_time_filled,
                          size: 16,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('h:mm a').format(localDateTime),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkBlue,
                        ),
                      ),
                    ],
                  ),
                  if (appointment.status == 'SCHEDULED') ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        height: 1,
                        color: AppColors.lightGrey.withValues(alpha: 0.5),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed:
                              () => _updateStatus(appointment, 'CANCELLED'),
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          label: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed:
                              () => _updateStatus(appointment, 'COMPLETED'),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Complete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
