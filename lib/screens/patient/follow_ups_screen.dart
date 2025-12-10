import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/app_localizations.dart';
import '../../widgets/reusable/decorated_background.dart';

class FollowUpsScreen extends StatelessWidget {
  const FollowUpsScreen({super.key});

  // Mock follow-up appointments
  List<Map<String, String>> get _followUps => [
    {
      'doctor': 'Dr. Sarah Johnson',
      'specialty': 'General Physician',
      'date': 'Tue, Dec 12',
      'time': '10:00 AM',
    },
    {
      'doctor': 'Dr. Ahmed Hassan',
      'specialty': 'Cardiologist',
      'date': 'Thu, Dec 21',
      'time': '2:30 PM',
    },
    {
      'doctor': 'Dr. Maria Chen',
      'specialty': 'Dermatologist',
      'date': 'Mon, Jan 8',
      'time': '11:00 AM',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.get('nextFollowUp'),
          style: const TextStyle(color: AppColors.darkBlue),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBlue),
      ),
      body: DecoratedBackground(
        child: ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          itemCount: _followUps.length,
          itemBuilder: (context, index) {
            final followUp = _followUps[index];
            return Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(AppDimensions.paddingM),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.calendar_today,
                    color: AppColors.primaryBlue,
                  ),
                ),
                title: Text(
                  followUp['doctor']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      followUp['specialty']!,
                      style: const TextStyle(color: AppColors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${followUp['date']} • ${followUp['time']}',
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.message_outlined,
                    color: AppColors.primaryBlue,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/doctor_chat');
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
