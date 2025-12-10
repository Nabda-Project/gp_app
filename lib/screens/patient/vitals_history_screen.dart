import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/app_localizations.dart';

class VitalsHistoryScreen extends StatelessWidget {
  const VitalsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final List<Map<String, String>> history = [
      {
        "date": "Oct 14, 2024",
        "type": "Heart Rate",
        "value": "75 bpm",
        "status": "Normal",
      },
      {
        "date": "Oct 13, 2024",
        "type": "Blood Pressure",
        "value": "118/78 mmHg",
        "status": "Normal",
      },
      {
        "date": "Oct 12, 2024",
        "type": "Blood Oxygen",
        "value": "99%",
        "status": "Normal",
      },
      {
        "date": "Oct 10, 2024",
        "type": "Heart Rate",
        "value": "82 bpm",
        "status": "Elevated",
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.get('vitalsHistory'),
          style: const TextStyle(color: AppColors.darkBlue),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBlue),
      ),
      body:
          history.isEmpty
              ? Center(
                child: Text(
                  AppLocalizations.of(context)!.get('noVitalsData'),
                  style: const TextStyle(color: AppColors.grey),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  return Container(
                    margin: const EdgeInsets.only(
                      bottom: AppDimensions.paddingM,
                    ),
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusM,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['type']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkBlue,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['date']!,
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              item['value']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['status']!,
                              style: TextStyle(
                                color:
                                    item['status'] == 'Normal'
                                        ? Colors.green
                                        : Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
