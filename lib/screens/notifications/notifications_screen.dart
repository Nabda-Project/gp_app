import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/app_localizations.dart';
import '../../widgets/reusable/decorated_background.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Mock Data - In a real app, this would be fetched from a service/provider
  final List<Map<String, String>> _notifications = [
    {
      "title": "Hydration Reminder",
      "message": "It's time to drink a glass of water.",
      "time": "10:30 AM",
      "isRead": "false",
    },
    {
      "title": "Appointment Confirmation",
      "message": "Your appointment with Dr. Sarah is confirmed for tomorrow.",
      "time": "Yesterday",
      "isRead": "true",
    },
    {
      "title": "Vitals Alert",
      "message": "Your heart rate was slightly elevated yesterday.",
      "time": "Yesterday",
      "isRead": "true",
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = "true";
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.get('markAllRead')),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.get('notificationsTitle'),
          style: const TextStyle(color: AppColors.darkBlue),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBlue),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(AppLocalizations.of(context)!.get('markAllRead')),
          ),
        ],
      ),
      body: DecoratedBackground(
        child:
            _notifications.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_off_outlined,
                        size: 64,
                        color: AppColors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.get('noNotifications'),
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final item = _notifications[index];
                    final isRead = item['isRead'] == 'true';
                    return Container(
                      margin: const EdgeInsets.only(
                        bottom: AppDimensions.paddingS,
                      ),
                      decoration: BoxDecoration(
                        color: isRead ? AppColors.white : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusM,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              isRead
                                  ? AppColors.lightGrey
                                  : AppColors.primaryBlue.withOpacity(0.2),
                          child: Icon(
                            Icons.notifications,
                            color:
                                isRead ? AppColors.grey : AppColors.primaryBlue,
                          ),
                        ),
                        title: Text(
                          item['title']!,
                          style: TextStyle(
                            fontWeight:
                                isRead ? FontWeight.normal : FontWeight.bold,
                            color: AppColors.darkBlue,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              item['message']!,
                              style: const TextStyle(color: AppColors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['time']!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
