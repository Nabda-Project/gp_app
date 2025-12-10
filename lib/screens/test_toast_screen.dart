import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class ToastTestScreen extends StatelessWidget {
  const ToastTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toast Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                NotificationService.showSuccess(
                  title: 'Success!',
                  message: 'This is a success message.',
                );
              },
              child: const Text('Show Success'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                NotificationService.showError(
                  title: 'Error!',
                  message: 'Something went wrong.',
                );
              },
              child: const Text('Show Error'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                NotificationService.showWarning(
                  title: 'Warning',
                  message: 'Be careful with this action.',
                );
              },
              child: const Text('Show Warning'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                NotificationService.showInfo(
                  title: 'Info',
                  message: 'Here is some useful information.',
                );
              },
              child: const Text('Show Info'),
            ),
          ],
        ),
      ),
    );
  }
}
