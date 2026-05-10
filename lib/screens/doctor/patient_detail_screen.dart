import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer';
import '../../utils/constants.dart';
import '../../widgets/reusable/vital_card.dart';
import '../../widgets/reusable/status_card.dart';
import '../../widgets/reusable/decorated_background.dart';
import '../../utils/app_localizations.dart';
import '../../services/storage_service.dart';
import '../../services/appointment_api_service.dart';
import '../../services/doctor_api_service.dart';
import '../../services/iot_api_service.dart';
import '../../services/chat_service.dart';
import '../../models/health_metric_model.dart';
import '../../widgets/reusable/user_avatar.dart';

class PatientDetailScreen extends StatefulWidget {
  const PatientDetailScreen({super.key});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  HealthMetricModel? _latestMetric;
  bool _loadingVitals = true;
  StreamSubscription<Map<String, dynamic>>? _vitalsSub;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadingVitals) {
      final patient =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
              {};
      final int patientId = patient['backendId'] ??
          int.tryParse(patient['id']?.toString() ?? '') ??
          0;
      if (patientId > 0) {
        _fetchLatestVitals(patientId);
        _subscribeToVitals(patientId);
      } else {
        setState(() => _loadingVitals = false);
      }
    }
  }

  @override
  void dispose() {
    _vitalsSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchLatestVitals(int patientId) async {
    try {
      final metric = await IoTApiService.getLatest(patientId);
      if (mounted) {
        setState(() {
          _latestMetric = metric;
          _loadingVitals = false;
        });
      }
    } catch (e) {
      log('Failed to fetch latest vitals: $e', name: 'PatientDetail');
      if (mounted) setState(() => _loadingVitals = false);
    }
  }

  void _subscribeToVitals(int patientId) {
    _vitalsSub = ChatService.instance?.vitalsUpdates.listen((data) {
      final pid = data['patientId'];
      if (pid != null && pid == patientId && mounted) {
        setState(() {
          _latestMetric = HealthMetricModel(
            id: data['metricId'] as int? ?? 0,
            heartRate: (data['heartRate'] as num?)?.toDouble(),
            spo2: (data['spo2'] as num?)?.toDouble(),
            batteryLevel: data['batteryLevel'] as int?,
            isCritical: data['isCritical'] as bool? ?? false,
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final patient =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {
          'id': '1',
          'name': 'Unknown Patient',
          'email': 'unknown@email.com',
          'status': 'Normal',
          'heartRate': '--',
          'lastUpdate': 'N/A',
        };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.get('patientDetails'),
          style: const TextStyle(
            color: AppColors.darkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBlue),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.person_remove_rounded,
                color: AppColors.error,
                size: 20,
              ),
            ),
            tooltip: AppLocalizations.of(context)!.get('removePatient'),
            onPressed: () => _removePatientFromDetail(context, patient),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: DecoratedBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Info Card
              _buildPatientInfoCard(context, patient),
              const SizedBox(height: AppDimensions.paddingL),

              // Health Status Card
              StatusCard(
                title: AppLocalizations.of(context)!.get('currentHealthStatus'),
                status: _latestMetric?.healthStatus ?? patient['status'] ?? 'UNKNOWN',
                healthStatus: _latestMetric?.healthStatus ?? 'UNKNOWN',
              ),
              const SizedBox(height: AppDimensions.paddingL),

              // Vitals Header with "View Charts" button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.get('vitals'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/patient_vitals', arguments: {
                        'patientId': patient['backendId'] ??
                            int.tryParse(patient['id']?.toString() ?? ''),
                        'name': patient['name'] ?? 'Patient',
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.show_chart, size: 16, color: AppColors.primaryBlue),
                          SizedBox(width: 4),
                          Text('View Charts',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryBlue)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingM),

              // Vitals Grid — real data from backend
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppDimensions.paddingM,
                mainAxisSpacing: AppDimensions.paddingM,
                childAspectRatio: 1.5,
                children: [
                  VitalCard(
                    label: AppLocalizations.of(context)!.get('heartRate'),
                    value: _latestMetric?.heartRateDisplay ?? '--',
                    unit: 'bpm',
                    icon: Icons.favorite,
                    color: Colors.redAccent,
                    subtleMode: true,
                  ),
                  VitalCard(
                    label: AppLocalizations.of(context)!.get('bloodOxygen'),
                    value: _latestMetric?.spo2Display ?? '--',
                    unit: '%',
                    icon: Icons.water_drop,
                    color: Colors.lightBlue,
                    subtleMode: true,
                  ),
                  VitalCard(
                    label: AppLocalizations.of(context)!.get('batteryLevel'),
                    value: _latestMetric?.batteryLevelDisplay ?? '--',
                    unit: '%',
                    icon: Icons.battery_charging_full,
                    color: Colors.green,
                    subtleMode: true,
                  ),
                  VitalCard(
                    label: AppLocalizations.of(context)!.get('nextFollowUp'),
                    value: 'N/A',
                    unit: '',
                    icon: Icons.calendar_today,
                    color: AppColors.primaryBlue,
                    subtleMode: true,
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingL),

              // Patient Bio Info section
              _buildPatientBioSection(context, patient),
              const SizedBox(height: 140), // Extra space for FABs
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'schedule_appointment_fab',
            onPressed: () => _scheduleAppointment(context, patient),
            backgroundColor: AppColors.white,
            icon: const Icon(
              Icons.calendar_month,
              color: AppColors.primaryBlue,
            ),
            label: const Text(
              'Schedule Appointment',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'send_message_fab',
            onPressed: () {
              Navigator.pushNamed(context, '/patient_chat', arguments: patient);
            },
            backgroundColor: AppColors.primaryBlue,
            icon: const Icon(Icons.message, color: Colors.white),
            label: Text(
              AppLocalizations.of(context)!.get('sendMessage'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCard(
    BuildContext context,
    Map<String, dynamic> patient,
  ) {
    final loc = AppLocalizations.of(context)!;
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
      child: Row(
        children: [
          UserAvatar(
            imageUrl: patient['profileImageUrl'] as String?,
            name: patient['name']?.toString(),
            radius: 35,
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  patient['email'] ?? 'No email',
                  style: const TextStyle(fontSize: 14, color: AppColors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${loc.get('lastUpdate')}: ${patient['lastUpdate'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the patient bio information section (gender, age, height, weight).
  Widget _buildPatientBioSection(
    BuildContext context,
    Map<String, dynamic> patient,
  ) {
    final loc = AppLocalizations.of(context)!;
    final String? gender = patient['gender'] as String?;
    final int? age = patient['age'] as int?;
    final double? height = patient['height'] as double?;
    final double? weight = patient['weight'] as double?;
    final String na = loc.get('notAvailable');

    // Translate gender value
    String genderDisplay = na;
    if (gender != null) {
      if (gender.toUpperCase() == 'MALE') {
        genderDisplay = loc.get('male');
      } else if (gender.toUpperCase() == 'FEMALE') {
        genderDisplay = loc.get('female');
      } else {
        genderDisplay = gender;
      }
    }

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
          Text(
            loc.get('patientInfo'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlue,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.person_outline,
                  label: loc.get('gender'),
                  value: genderDisplay,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: loc.get('age'),
                  value: age != null ? '$age ${loc.get('years')}' : na,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.height,
                  label: loc.get('heightCm'),
                  value: height != null ? '${height.toStringAsFixed(0)} cm' : na,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.monitor_weight_outlined,
                  label: loc.get('weightKg'),
                  value: weight != null ? '${weight.toStringAsFixed(0)} kg' : na,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A small info chip used to display patient bio data.
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.grey.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBlue,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scheduleAppointment(
    BuildContext context,
    Map<String, dynamic> patient,
  ) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null || !context.mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null || !context.mounted) return;

    final DateTime appointmentDate = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (appointmentDate.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot schedule appointments in the past.'),
        ),
      );
      return;
    }

    String? reason;
    final reasonController = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Schedule Appointment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'With ${patient['name'] ?? 'Unknown'} at ${pickedTime.format(context)} on ${pickedDate.day}/${pickedDate.month}',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Schedule'),
              ),
            ],
          ),
    );

    if (confirmed != true || !context.mounted) return;
    reason = reasonController.text.trim();

    try {
      final user = StorageService.getUser();
      if (user?.backendId == null) throw Exception("Doctor not logged in");

      final int backendId =
          patient['backendId'] ?? int.tryParse(patient['id'].toString()) ?? 0;
      if (backendId == 0) throw Exception("Invalid patient ID");

      await AppointmentApiService.scheduleAppointment(
        doctorId: user!.backendId!,
        patientId: backendId,
        date: appointmentDate,
        reason: reason.isNotEmpty ? reason : null,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment scheduled successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Automatically pop out so dashboard updates immediately!
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Remove (unlink) the patient from the current doctor, with confirmation.
  Future<void> _removePatientFromDetail(
    BuildContext context,
    Map<String, dynamic> patient,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final user = StorageService.getUser();
    final doctorId = user?.backendId;
    if (doctorId == null) return;

    final int patientId =
        patient['backendId'] ?? int.tryParse(patient['id'].toString()) ?? 0;
    if (patientId == 0) return;

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
                  UserAvatar(
                    imageUrl: patient['profileImageUrl'] as String?,
                    name: patient['name']?.toString(),
                    radius: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      patient['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkBlue,
                      ),
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

    if (confirmed != true || !context.mounted) return;

    try {
      await DoctorApiService.removePatient(doctorId, patientId);
      if (context.mounted) {
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
        Navigator.of(context).pop(true); // return true to signal removal
      }
    } catch (e) {
      log('Failed to remove patient from detail: $e', name: 'PatientDetail');
      if (context.mounted) {
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
}
