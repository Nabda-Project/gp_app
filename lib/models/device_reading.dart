/// Represents a single reading received from the Nabda wearable device.
///
/// - [heartRate] comes from the analog Pulse Sensor (`PULSE_reading`).
/// - [spo2] comes from the MAX30105 digital sensor (`MAX30105_reading`).
///   **WARNING:** The current firmware computes HR (beat detection) for
///   this value, NOT actual SpO2. Treat this as a secondary HR reading
///   until the firmware implements a proper SpO2 algorithm.
/// - [batteryLevel] is the converted percentage from the raw ADC0832 value.
class DeviceReading {
  final double heartRate;
  final double spo2;
  final int batteryLevel;
  final DateTime timestamp;

  const DeviceReading({
    required this.heartRate,
    required this.spo2,
    required this.batteryLevel,
    required this.timestamp,
  });

  @override
  String toString() =>
      'DeviceReading(hr=${heartRate.toStringAsFixed(1)}, spo2=${spo2.toStringAsFixed(1)}, batt=$batteryLevel%)';
}
