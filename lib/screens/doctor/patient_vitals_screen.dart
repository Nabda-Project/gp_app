import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../services/iot_api_service.dart';
import '../../services/chat_service.dart';
import '../../models/daily_summary_model.dart';
import '../../models/hourly_summary_model.dart';
import '../../models/health_metric_model.dart';
import '../../widgets/reusable/decorated_background.dart';

class PatientVitalsScreen extends StatefulWidget {
  const PatientVitalsScreen({super.key});

  @override
  State<PatientVitalsScreen> createState() => _PatientVitalsScreenState();
}

class _PatientVitalsScreenState extends State<PatientVitalsScreen>
    with TickerProviderStateMixin {
  int? _patientId;
  String _patientName = '';

  // Data
  HealthMetricModel? _latestMetric;
  List<_ChartDataPoint> _summaries = [];
  bool _loading = true;
  bool _loadError = false;
  int _selectedDays = 7;
  int _chartMode = 0; // 0=HR, 1=SpO2, 2=Both
  bool _fitToScreen = false; // true=show full period, false=zoomed with pan

  // WebSocket
  StreamSubscription<Map<String, dynamic>>? _vitalsSub;
  StreamSubscription<WebSocketState>? _wsSub;
  WebSocketState _wsState = WebSocketState.disconnected;

  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_patientId == null) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _patientId = args?['patientId'] as int? ??
          args?['backendId'] as int? ??
          int.tryParse(args?['id']?.toString() ?? '');
      _patientName = args?['name'] as String? ?? 'Patient';
      _loadData();
      _subscribeToVitals();
      _subscribeToConnectionState();
    }
  }

  @override
  void dispose() {
    _vitalsSub?.cancel();
    _wsSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _subscribeToConnectionState() {
    _wsState = ChatService.instance?.wsState ?? WebSocketState.disconnected;
    _wsSub = ChatService.instance?.connectionState.listen((state) {
      if (mounted) setState(() => _wsState = state);
    });
  }

  void _subscribeToVitals() {
    _vitalsSub = ChatService.instance?.vitalsUpdates.listen((data) {
      final pid = data['patientId'];
      if (pid != null && pid == _patientId && mounted) {
        setState(() {
          _latestMetric = HealthMetricModel(
            id: data['metricId'] as int? ?? 0,
            heartRate: (data['heartRate'] as num?)?.toDouble(),
            spo2: (data['spo2'] as num?)?.toDouble(),
            batteryLevel: data['batteryLevel'] as int?,
            isCritical: data['isCritical'] as bool? ?? false,
            priority: data['priority'] as String?,
            healthStatus: data['healthStatus'] as String?,
          );
        });
      }
    });
  }

  Future<void> _loadData() async {
    if (_patientId == null) return;
    setState(() => _loading = true);
    try {
      final latestFuture = IoTApiService.getLatest(_patientId!);
      List<_ChartDataPoint> points = [];

      if (_selectedDays == 1) {
        final results = await Future.wait([
          latestFuture,
          IoTApiService.getHourlySummary(_patientId!, hours: 24),
        ]);
        _latestMetric = results[0] as HealthMetricModel? ?? _latestMetric;
        final hourly = results[1] as List<HourlySummaryModel>;
        points = hourly.map((h) => _ChartDataPoint(
          date: h.dateTime,
          avgHR: h.avgHeartRate,
          minHR: h.minHeartRate,
          maxHR: h.maxHeartRate,
          avgSpo2: h.avgSpo2,
          minSpo2: h.minSpo2,
          maxSpo2: h.maxSpo2,
          readingCount: h.readingCount,
        )).toList();
      } else {
        final results = await Future.wait([
          latestFuture,
          IoTApiService.getDailySummary(_patientId!, days: _selectedDays),
        ]);
        _latestMetric = results[0] as HealthMetricModel? ?? _latestMetric;
        final daily = results[1] as List<DailySummaryModel>;
        points = daily.map((d) => _ChartDataPoint(
          date: d.date,
          avgHR: d.avgHeartRate,
          minHR: d.minHeartRate,
          maxHR: d.maxHeartRate,
          avgSpo2: d.avgSpo2,
          minSpo2: d.minSpo2,
          maxSpo2: d.maxSpo2,
          readingCount: d.readingCount,
        )).toList();
      }

      if (mounted) {
        setState(() {
          _summaries = points;
          _loading = false;
          _loadError = false;
        });
      }
    } catch (e) {
      log('Failed to load vitals data: $e', name: 'PatientVitals');
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOffline = _wsState != WebSocketState.connected;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_patientName,
            style: const TextStyle(
                color: AppColors.darkBlue, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBlue),
      ),
      body: DecoratedBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  children: [
                    // Connection status banner
                    if (isOffline || _loadError) _buildConnectionBanner(),
                    _buildLiveVitalCards(),
                    const SizedBox(height: 24),
                    _buildChartSection(),
                    const SizedBox(height: 24),
                    if (_summaries.isNotEmpty) _buildStatsSummary(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildConnectionBanner() {
    final Color bgColor;
    final IconData icon;
    final String text;
    if (_loadError && _wsState != WebSocketState.connected) {
      bgColor = AppColors.error;
      icon = Icons.cloud_off;
      text = _latestMetric != null
          ? 'Offline — showing last known data'
          : 'Server unavailable — no data';
    } else if (_wsState == WebSocketState.reconnecting) {
      bgColor = Colors.orange;
      icon = Icons.sync;
      text = 'Reconnecting...';
    } else if (_wsState == WebSocketState.disconnected) {
      bgColor = AppColors.error;
      icon = Icons.wifi_off;
      text = _latestMetric != null
          ? 'Disconnected — showing last known data'
          : 'Disconnected';
    } else {
      bgColor = Colors.orange;
      icon = Icons.warning_amber;
      text = 'Connection issue — data may be stale';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: bgColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: bgColor, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          if (_wsState == WebSocketState.reconnecting)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: bgColor),
            ),
        ],
      ),
    );
  }

  // ── Live Vital Cards ─────────────────────────────────────────────────────
  Widget _buildLiveVitalCards() {
    final hasData = _latestMetric != null;
    final bool isActive;
    if (_latestMetric?.timestamp != null) {
      isActive = DateTime.now().difference(_latestMetric!.timestamp!).inSeconds < 60;
    } else {
      isActive = false;
    }

    // Only show actual values when data exists
    final hr = hasData ? _latestMetric?.heartRate : null;
    final spo2 = hasData ? _latestMetric?.spo2 : null;
    final batt = hasData ? _latestMetric?.batteryLevel : null;

    // Build "last seen" label
    String statusLabel;
    Color statusColor;
    if (isActive) {
      statusLabel = 'Active';
      statusColor = Colors.green;
    } else if (hasData && _latestMetric?.timestamp != null) {
      final diff = DateTime.now().difference(_latestMetric!.timestamp!);
      if (diff.inMinutes < 60) {
        statusLabel = 'Last seen ${diff.inMinutes} min ago';
      } else if (diff.inHours < 24) {
        statusLabel = 'Last seen ${diff.inHours}h ago';
      } else {
        statusLabel = 'Last seen ${diff.inDays}d ago';
      }
      statusColor = Colors.orange;
    } else {
      statusLabel = 'No Data';
      statusColor = AppColors.grey;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Live Vitals',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue)),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(statusLabel,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (!hasData)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.lightGrey),
            ),
            child: Column(
              children: [
                Icon(Icons.watch_off, size: 40, color: AppColors.grey.withValues(alpha: 0.5)),
                const SizedBox(height: 8),
                const Text('Device not connected',
                    style: TextStyle(color: AppColors.grey, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Wear your device to start live monitoring',
                    style: TextStyle(color: AppColors.grey, fontSize: 12)),
              ],
            ),
          )
        else
          Row(
            children: [
              Expanded(child: _buildHRCard(hr)),
              const SizedBox(width: 12),
              Expanded(child: _buildSpO2Card(spo2)),
              const SizedBox(width: 12),
              Expanded(child: _buildBatteryCard(batt)),
            ],
          ),
      ],
    );
  }

  Widget _buildHRCard(double? hr) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF1744).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Transform.scale(
                scale: hr != null ? _pulseAnimation.value : 1.0,
                child: const Icon(Icons.favorite, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                hr != null ? hr.toStringAsFixed(0) : '--',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              const Text('BPM',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpO2Card(double? spo2) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.water_drop, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            spo2 != null ? spo2.toStringAsFixed(0) : '--',
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const Text('SpO2 %',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBatteryCard(int? batt) {
    final Color battColor = batt == null
        ? AppColors.grey
        : batt > 50
            ? Colors.green
            : batt > 20
                ? Colors.orange
                : Colors.red;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: battColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            batt == null
                ? Icons.battery_unknown
                : batt > 50
                    ? Icons.battery_full
                    : batt > 20
                        ? Icons.battery_3_bar
                        : Icons.battery_1_bar,
            color: battColor,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            batt != null ? '$batt' : '--',
            style: TextStyle(
                color: battColor, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Text('Battery %',
              style: TextStyle(color: AppColors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  // ── Chart Section ────────────────────────────────────────────────────────
  Widget _buildChartSection() {
    final is24H = _selectedDays == 1;
    final periodType = is24H ? 'hourly avg' : 'daily avg';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFDFDFF), Color(0xFFF5F7FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Health Trends',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue)),
              _buildPeriodSelector(),
            ],
          ),
          const SizedBox(height: 8),
          Text(is24H 
              ? 'Chart shows hourly averages • Shaded area shows raw min/max'
              : 'Chart shows daily averages • Shaded area shows raw min/max',
              style: TextStyle(fontSize: 11, color: AppColors.grey.withValues(alpha: 0.8))),
          const SizedBox(height: 12),
          // Metric toggle row
          Row(
            children: [
              _buildMetricToggle('Heart Rate', 0, const Color(0xFFFF5252)),
              const SizedBox(width: 8),
              _buildMetricToggle('SpO2', 1, const Color(0xFF2196F3)),
              const SizedBox(width: 8),
              _buildMetricToggle('Both', 2, AppColors.primaryBlue),
              const Spacer(),
              // Fit / Scroll toggle
              if (_summaries.length > 2)
                GestureDetector(
                  onTap: () => setState(() => _fitToScreen = !_fitToScreen),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _fitToScreen
                          ? AppColors.primaryBlue.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _fitToScreen ? Icons.fit_screen : Icons.swipe,
                          size: 14,
                          color: _fitToScreen ? AppColors.primaryBlue : AppColors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _fitToScreen ? 'Fit' : 'Scroll',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _fitToScreen ? AppColors.primaryBlue : AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Chart(s)
          if (_summaries.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 48,
                        color: AppColors.grey.withValues(alpha: 0.4)),
                    const SizedBox(height: 8),
                    Text(_selectedDays == 1
                        ? 'No readings in the last 24 hours'
                        : 'No data for this period',
                        style: const TextStyle(color: AppColors.grey, fontSize: 14)),
                  ],
                ),
              ),
            )
          else if (_chartMode == 2) ...[
            // Both: two stacked charts
            _buildSingleChart(
              title: '❤ Heart Rate ($periodType)',
              color: const Color(0xFFFF5252),
              getAvg: (s) => s.avgHR,
              getMin: (s) => s.minHR,
              getMax: (s) => s.maxHR,
              unit: 'bpm',
              height: 180,
            ),
            const SizedBox(height: 16),
            _buildSingleChart(
              title: '💧 SpO2 ($periodType)',
              color: const Color(0xFF2196F3),
              getAvg: (s) => s.avgSpo2,
              getMin: (s) => s.minSpo2,
              getMax: (s) => s.maxSpo2,
              unit: '%',
              height: 180,
            ),
          ] else
            _buildSingleChart(
              title: _chartMode == 0
                  ? '❤ Heart Rate ($periodType)'
                  : '💧 SpO2 ($periodType)',
              color: _chartMode == 0
                  ? const Color(0xFFFF5252)
                  : const Color(0xFF2196F3),
              getAvg: _chartMode == 0 ? (s) => s.avgHR : (s) => s.avgSpo2,
              getMin: _chartMode == 0 ? (s) => s.minHR : (s) => s.minSpo2,
              getMax: _chartMode == 0 ? (s) => s.maxHR : (s) => s.maxSpo2,
              unit: _chartMode == 0 ? 'bpm' : '%',
              height: 240,
            ),
        ],
      ),
    );
  }

  Widget _buildMetricToggle(String label, int mode, Color color) {
    final isSelected = _chartMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _chartMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.lightGrey,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            )),
      ),
    );
  }

  Widget _buildSingleChart({
    required String title,
    required Color color,
    required double? Function(_ChartDataPoint) getAvg,
    required double? Function(_ChartDataPoint) getMin,
    required double? Function(_ChartDataPoint) getMax,
    required String unit,
    required double height,
  }) {
    // Build data points from summaries
    final dataPoints = <_ChartPoint>[];
    double globalMin = double.infinity;
    double globalMax = -double.infinity;

    for (final s in _summaries) {
      final avg = getAvg(s);
      final minVal = getMin(s);
      final maxVal = getMax(s);
      if (avg != null) {
        dataPoints.add(_ChartPoint(date: s.date, avg: avg, min: minVal, max: maxVal));
        // Track global min/max from ALL values (avg, min, max)
        final low = minVal ?? avg;
        final high = maxVal ?? avg;
        if (low < globalMin) globalMin = low;
        if (high > globalMax) globalMax = high;
        if (avg < globalMin) globalMin = avg;
        if (avg > globalMax) globalMax = avg;
      }
    }

    final is24H = _selectedDays == 1;
    final now = DateTime.now();

    // Calculate strict X-axis bounds so Fit mode truly spans the exact period
    final DateTime axisMin = is24H
        ? now.subtract(const Duration(hours: 24))
        : DateTime(now.year, now.month, now.day).subtract(Duration(days: _selectedDays - 1));
    final DateTime axisMax = now;

    // Dynamic Y-axis: pad by 10% of range so extremes aren't clipped
    final range = globalMax - globalMin;
    final yPad = range > 0 ? range * 0.15 : 10.0;
    final yMin = (globalMin - yPad).floorToDouble();
    final yMax = (globalMax + yPad).ceilToDouble();
    // Round interval to a nice number
    final yInterval = _niceInterval(yMax - yMin);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBlue)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: height,
            child: dataPoints.isEmpty
                ? Center(
                    child: Text(
                        is24H
                            ? 'No readings in the last 24 hours'
                            : 'No $unit data available',
                        style: const TextStyle(color: AppColors.grey, fontSize: 13)),
                  )
                : SfCartesianChart(
                    key: ValueKey('$_fitToScreen-$_selectedDays'), // Forces complete reset of zoom state when toggled
                    zoomPanBehavior: ZoomPanBehavior(
                      enablePinching: !_fitToScreen,
                      enablePanning: !_fitToScreen,
                      enableDoubleTapZooming: !_fitToScreen,
                      zoomMode: ZoomMode.x,
                    ),
                    margin: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                    plotAreaBorderWidth: 0,
                    tooltipBehavior: TooltipBehavior(
                      enable: true,
                      header: '',
                      canShowMarker: true,
                      activationMode: ActivationMode.singleTap,
                      builder: (dynamic data, dynamic point, dynamic series,
                          int pointIndex, int seriesIndex) {
                        if (data is _ChartPoint && seriesIndex == 1) {
                          final timeStr = is24H
                              ? DateFormat('HH:mm').format(data.date)
                              : DateFormat('MMM d').format(data.date);
                          final minStr = data.min?.toStringAsFixed(0) ?? '--';
                          final maxStr = data.max?.toStringAsFixed(0) ?? '--';
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E2E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$timeStr\nAvg: ${data.avg.toStringAsFixed(1)} $unit\nRange: $minStr – $maxStr',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    primaryXAxis: DateTimeAxis(
                      dateFormat: DateFormat(is24H ? 'HH:mm' : 'd/M'),
                      intervalType: is24H
                          ? DateTimeIntervalType.hours
                          : DateTimeIntervalType.days,
                      // Label interval: wider in Fit mode to avoid overlap
                      interval: is24H
                          ? (_fitToScreen ? 4 : 3)
                          : (_fitToScreen
                              ? (_selectedDays >= 30 ? 7 : 1)
                              : (_summaries.length > 14 ? 5 : (_summaries.length > 7 ? 2 : 1))),
                      minimum: axisMin,
                      maximum: axisMax,
                      // Zoom: Fit shows everything, Scroll zooms in for panning
                      initialZoomFactor: _fitToScreen
                          ? 1.0
                          : (is24H ? 0.5 : (_selectedDays >= 30 ? 0.5 : 1.0)),
                      initialZoomPosition: 1.0,
                      majorGridLines: const MajorGridLines(width: 0),
                      labelStyle: const TextStyle(
                          fontSize: 10, color: AppColors.grey),
                      edgeLabelPlacement: EdgeLabelPlacement.shift,
                      labelIntersectAction: AxisLabelIntersectAction.rotate45,
                      maximumLabels: is24H ? (_fitToScreen ? 6 : 4) : 8,
                    ),
                    primaryYAxis: NumericAxis(
                      minimum: dataPoints.isNotEmpty ? yMin : null,
                      maximum: dataPoints.isNotEmpty ? yMax : null,
                      interval: dataPoints.isNotEmpty ? yInterval : null,
                      axisLine: const AxisLine(width: 0),
                      labelStyle: const TextStyle(
                          fontSize: 10, color: AppColors.grey),
                      majorGridLines: MajorGridLines(
                        width: 0.8,
                        color: AppColors.lightGrey.withValues(alpha: 0.4),
                      ),
                    ),
                    series: <CartesianSeries>[
                      // Min/Max band
                      RangeAreaSeries<_ChartPoint, DateTime>(
                        dataSource: dataPoints,
                        xValueMapper: (_ChartPoint p, _) => p.date,
                        lowValueMapper: (_ChartPoint p, _) =>
                            p.min ?? p.avg,
                        highValueMapper: (_ChartPoint p, _) =>
                            p.max ?? p.avg,
                        color: color.withValues(alpha: 0.12),
                        borderWidth: 0,
                        animationDuration: 600,
                        emptyPointSettings: EmptyPointSettings(
                          mode: EmptyPointMode.gap,
                        ),
                      ),
                      // Average line (no spline to avoid misleading interpolation across gaps)
                      LineSeries<_ChartPoint, DateTime>(
                        dataSource: dataPoints,
                        xValueMapper: (_ChartPoint p, _) => p.date,
                        yValueMapper: (_ChartPoint p, _) => p.avg,
                        color: color,
                        width: 2.5,
                        markerSettings: MarkerSettings(
                          isVisible: true,
                          shape: DataMarkerType.circle,
                          width: 6,
                          height: 6,
                          borderWidth: 2,
                          borderColor: Colors.white,
                          color: color,
                        ),
                        animationDuration: 600,
                        emptyPointSettings: EmptyPointSettings(
                          mode: EmptyPointMode.gap,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPeriodChip('24H', 1),
          _buildPeriodChip('7D', 7),
          _buildPeriodChip('30D', 30),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, int days) {
    final isSelected = _selectedDays == days;
    return GestureDetector(
      onTap: () {
        if (_selectedDays != days) {
          setState(() => _selectedDays = days);
          _loadData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            )),
      ),
    );
  }

  // ── Stats Summary ────────────────────────────────────────────────────────
  Widget _buildStatsSummary() {
    double avgHR = 0, avgSpo2 = 0;
    double minHR = double.infinity, maxHR = 0;
    double minSpo2 = double.infinity, maxSpo2 = 0;
    int hrCount = 0, spo2Count = 0;
    int totalReadings = 0;

    for (final s in _summaries) {
      if (s.avgHR != null) {
        avgHR += s.avgHR!;
        hrCount++;
      }
      if (s.minHR != null && s.minHR! < minHR) minHR = s.minHR!;
      if (s.maxHR != null && s.maxHR! > maxHR) maxHR = s.maxHR!;
      if (s.minSpo2 != null && s.minSpo2! < minSpo2) minSpo2 = s.minSpo2!;
      if (s.maxSpo2 != null && s.maxSpo2! > maxSpo2) maxSpo2 = s.maxSpo2!;
      if (s.avgSpo2 != null) {
        avgSpo2 += s.avgSpo2!;
        spo2Count++;
      }
      if (s.readingCount > 0) totalReadings += s.readingCount;
    }
    if (hrCount > 0) avgHR /= hrCount;
    if (spo2Count > 0) avgSpo2 /= spo2Count;

    final is24H = _selectedDays == 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(is24H ? 'Summary for today' : 'Period Summary',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(is24H ? 'Last 24 hours' : 'Last $_selectedDays days',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue)),
              ),
            ],
          ),
          if (totalReadings > 0) ...[
            const SizedBox(height: 6),
            Text(is24H ? '$totalReadings readings in last 24 hours' : '$totalReadings readings across ${_summaries.length} days',
                style: const TextStyle(fontSize: 12, color: AppColors.grey)),
            const SizedBox(height: 2),
            Text(is24H ? 'Chart shows hourly averages • Ranges show raw min/max' : 'Chart shows daily averages • Ranges show raw min/max',
                style: TextStyle(fontSize: 10, color: AppColors.grey.withValues(alpha: 0.7), fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Avg HR', null, '${avgHR.toStringAsFixed(0)} bpm',
                  const Color(0xFFFF5252),
                  _getHRStatus(avgHR),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Avg SpO2', null, '${avgSpo2.toStringAsFixed(0)}%',
                  const Color(0xFF2196F3),
                  _getSpO2Status(avgSpo2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Raw HR Range', 'Lowest/highest individual readings',
                  '${minHR.isFinite ? minHR.toStringAsFixed(0) : "--"} - ${maxHR > 0 ? maxHR.toStringAsFixed(0) : "--"}',
                  const Color(0xFFFF5252).withValues(alpha: 0.7),
                  null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Raw SpO2 Range', 'Lowest/highest individual readings',
                  '${minSpo2.isFinite ? minSpo2.toStringAsFixed(0) : "--"} - ${maxSpo2 > 0 ? maxSpo2.toStringAsFixed(0) : "--"}',
                  const Color(0xFF2196F3).withValues(alpha: 0.7),
                  null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String? subtitle, String value, Color color, String? status) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: AppColors.grey, fontWeight: FontWeight.w500)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(
                    color: color.withValues(alpha: 0.5),
                    fontSize: 9,
                    fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          if (status != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor(status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(status,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(status))),
            ),
          ],
        ],
      ),
    );
  }

  // Chart summary labels only — health status card uses backend healthStatus
  String _getHRStatus(double hr) {
    if (hr == 0) return 'No Data';
    if (hr > 120 || hr < 40) return 'Critical';
    if (hr > 100 || hr < 50) return 'Warning';
    return 'Normal';
  }

  String _getSpO2Status(double spo2) {
    if (spo2 == 0) return 'No Data';
    if (spo2 < 90) return 'Critical';
    if (spo2 < 95) return 'Warning';
    return 'Normal';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Critical':
        return AppColors.error;
      case 'Warning':
        return Colors.orange;
      case 'Normal':
        return Colors.green;
      default:
        return AppColors.grey;
    }
  }

  /// Returns a clean Y-axis interval for the given data range.
  double _niceInterval(double range) {
    if (range <= 0) return 10;
    // Target ~5-7 labels
    final raw = range / 6;
    if (raw <= 5) return 5;
    if (raw <= 10) return 10;
    if (raw <= 20) return 20;
    if (raw <= 25) return 25;
    return (raw / 10).ceilToDouble() * 10;
  }
}

/// Unified data point for both Daily and Hourly chart modes.
class _ChartDataPoint {
  final DateTime date;
  final double? avgHR;
  final double? minHR;
  final double? maxHR;
  final double? avgSpo2;
  final double? minSpo2;
  final double? maxSpo2;
  final int readingCount;

  _ChartDataPoint({
    required this.date,
    this.avgHR, this.minHR, this.maxHR,
    this.avgSpo2, this.minSpo2, this.maxSpo2,
    this.readingCount = 0,
  });
}

/// Internal class for Syncfusion plotting.
class _ChartPoint {
  final DateTime date;
  final double avg;
  final double? min;
  final double? max;
  _ChartPoint({required this.date, required this.avg, this.min, this.max});
}
