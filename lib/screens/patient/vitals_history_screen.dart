import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../utils/app_localizations.dart';
import '../../services/iot_api_service.dart';
import '../../services/storage_service.dart';
import '../../models/health_metric_model.dart';

/// Displays a chronological list of health-metric readings fetched from
/// the back-end via `GET /api/iot/history/{patientId}?days=N`.
///
/// Replaces the previous mock-data implementation.
class VitalsHistoryScreen extends StatefulWidget {
  const VitalsHistoryScreen({super.key});

  @override
  State<VitalsHistoryScreen> createState() => _VitalsHistoryScreenState();
}

class _VitalsHistoryScreenState extends State<VitalsHistoryScreen> {
  List<HealthMetricModel> _history = [];
  bool _loading = true;
  bool _hasError = false;
  int _days = 7;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = StorageService.getUser();
    if (user?.backendId == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
      return;
    }

    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      final metrics = await IoTApiService.getHistory(user!.backendId!, days: _days);
      if (mounted) {
        setState(() {
          _history = metrics;
          _loading = false;
        });
      }
    } catch (e) {
      log('Could not load vitals history: $e', name: 'VitalsHistory');
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  String _statusLabel(HealthMetricModel metric) {
    final status = metric.healthStatus?.toUpperCase() ?? 'UNKNOWN';
    switch (status) {
      case 'CRITICAL':
        return 'Critical';
      case 'WARNING':
        return 'Elevated';
      case 'NORMAL':
        return 'Normal';
      default:
        return 'Unknown';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Critical':
        return Colors.red;
      case 'Elevated':
        return Colors.orange;
      case 'Normal':
        return Colors.green;
      default:
        return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          // Period selector
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_list, color: AppColors.darkBlue),
            onSelected: (days) {
              _days = days;
              _loadHistory();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 1, child: Text('Last 24 hours', style: TextStyle(fontWeight: _days == 1 ? FontWeight.bold : FontWeight.normal))),
              PopupMenuItem(value: 7, child: Text('Last 7 days', style: TextStyle(fontWeight: _days == 7 ? FontWeight.bold : FontWeight.normal))),
              PopupMenuItem(value: 30, child: Text('Last 30 days', style: TextStyle(fontWeight: _days == 30 ? FontWeight.bold : FontWeight.normal))),
            ],
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 48, color: AppColors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text(
              'Could not load vitals history',
              style: TextStyle(color: AppColors.grey, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your connection and try again.',
              style: TextStyle(color: AppColors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.monitor_heart_outlined, size: 48, color: AppColors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.get('noVitalsData'),
              style: const TextStyle(color: AppColors.grey, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'No readings in the last $_days days.',
              style: const TextStyle(color: AppColors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final metric = _history[index];
          final status = _statusLabel(metric);
          final dateStr = metric.timestamp != null
              ? DateFormat('MMM d, yyyy \u2013 h:mm a').format(metric.timestamp!.toLocal())
              : 'Unknown date';
          final hrStr = metric.heartRateDisplay;
          final spo2Str = metric.spo2Display;

          return Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: metric.isCritical
                  ? Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1.5)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Left: icon + info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (metric.isCritical)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(Icons.warning_amber, color: Colors.red, size: 16),
                            ),
                          Expanded(
                            child: Text(
                              dateStr,
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Heart Rate
                          Icon(Icons.favorite, size: 14, color: Colors.redAccent),
                          const SizedBox(width: 4),
                          Text(
                            '$hrStr bpm',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkBlue,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // SpO2
                          Icon(Icons.water_drop, size: 14, color: Colors.lightBlue),
                          const SizedBox(width: 4),
                          Text(
                            '$spo2Str%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkBlue,
                              fontSize: 14,
                            ),
                          ),
                          if (metric.batteryLevel != null) ...[
                            const SizedBox(width: 16),
                            Icon(Icons.battery_std, size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              '${metric.batteryLevelDisplay}%',
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Right: status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: _statusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
