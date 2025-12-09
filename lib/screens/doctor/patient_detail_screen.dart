import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/reusable/vital_card.dart';
import '../../widgets/reusable/status_card.dart';
import '../../widgets/reusable/decorated_background.dart';
import '../../utils/app_localizations.dart';

class PatientDetailScreen extends StatelessWidget {
  const PatientDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get patient data from route arguments
    final patient =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {
          'id': '1',
          'name': 'Unknown Patient',
          'email': 'unknown@email.com',
          'status': 'Normal',
          'heartRate': '72',
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
                    value: patient['heartRate'] ?? '72',
                    unit: 'bpm',
                    icon: Icons.favorite,
                    color: Colors.redAccent,
                  ),
                  VitalCard(
                    label: AppLocalizations.of(context)!.get('bloodOxygen'),
                    value: '98',
                    unit: '%',
                    icon: Icons.water_drop,
                    color: Colors.lightBlue,
                  ),
                  VitalCard(
                    label: AppLocalizations.of(context)!.get('bloodPressure'),
                    value: '120/80',
                    unit: 'mmHg',
                    icon: Icons.speed,
                    color: Colors.orange,
                  ),
                  VitalCard(
                    label: AppLocalizations.of(context)!.get('nextFollowUp'),
                    value: 'Dec 15',
                    unit: '',
                    icon: Icons.calendar_today,
                    color: AppColors.primaryBlue,
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingL),

              // Recent Measurements
              _buildMeasurementsSection(context),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
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
            color: Colors.black.withOpacity(0.05),
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
                    Icon(Icons.access_time, size: 14, color: AppColors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${AppLocalizations.of(context)!.get('lastUpdate')}: ${patient['lastUpdate']}',
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

  Widget _buildMeasurementsSection(BuildContext context) {
    final measurements = [
      {
        'date': 'Dec 9, 10:30 AM',
        'heartRate': '72',
        'bp': '120/80',
        'oxygen': '98',
      },
      {
        'date': 'Dec 8, 09:15 AM',
        'heartRate': '75',
        'bp': '118/78',
        'oxygen': '97',
      },
      {
        'date': 'Dec 7, 11:00 AM',
        'heartRate': '70',
        'bp': '122/82',
        'oxygen': '99',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.get('vitalsHistory'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBlue,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingM),
        ...measurements.map(
          (m) => Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    m['date']!,
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.favorite,
                        size: 14,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        m['heartRate']!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.speed, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(m['bp']!, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.water_drop,
                        size: 14,
                        color: Colors.lightBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${m['oxygen']}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
