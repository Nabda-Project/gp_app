import 'package:flutter/material.dart';
import 'dart:developer';
import '../../utils/constants.dart';
import '../../widgets/reusable/vital_card.dart';
import '../../widgets/reusable/status_card.dart';
import '../../widgets/reusable/decorated_background.dart';
import '../../utils/app_localizations.dart';
import '../../services/storage_service.dart';
import '../../services/appointment_api_service.dart';
import '../../services/doctor_api_service.dart';

class PatientDetailScreen extends StatefulWidget {
  const PatientDetailScreen({super.key});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
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
                status: patient['status'] ?? 'Normal',
                isHealthy: patient['status'] == 'Normal',
              ),
              const SizedBox(height: AppDimensions.paddingL),

              // Vitals Grid
              Text(
                AppLocalizations.of(context)!.get('vitals'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBlue,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingM),

              // Vitals Grid - mock data (Bluetooth smartwatch integration pending)
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
                    value: '--',
                    unit: 'bpm',
                    icon: Icons.favorite,
                    color: Colors.redAccent,
                  ),
                  VitalCard(
                    label: AppLocalizations.of(context)!.get('bloodOxygen'),
                    value: '--',
                    unit: '%',
                    icon: Icons.water_drop,
                    color: Colors.lightBlue,
                  ),
                  VitalCard(
                    label: AppLocalizations.of(context)!.get('batteryLevel'),
                    value: '--',
                    unit: '%',
                    icon: Icons.battery_charging_full,
                    color: Colors.green,
                  ),
                  VitalCard(
                    label: AppLocalizations.of(context)!.get('nextFollowUp'),
                    value: 'N/A',
                    unit: '',
                    icon: Icons.calendar_today,
                    color: AppColors.primaryBlue,
                  ),
                ],
              ),
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
          CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.primaryBlue,
            child: Text(
              patient['name'].toString().substring(0, 1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
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
                      '${AppLocalizations.of(context)!.get('lastUpdate')}: ${patient['lastUpdate'] ?? 'N/A'}',
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
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                    child: Text(
                      (patient['name'] ?? '?').toString().isNotEmpty
                          ? patient['name'].toString()[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
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
