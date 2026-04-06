import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/reusable/vital_card.dart';
import '../../widgets/reusable/status_card.dart';
import '../../widgets/reusable/decorated_background.dart';
import '../../utils/app_localizations.dart';
import '../../services/storage_service.dart';
import '../../services/appointment_api_service.dart';

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
                    label: 'Body Temp',
                    value: '--',
                    unit: '°C',
                    icon: Icons.thermostat,
                    color: Colors.orange,
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
}
