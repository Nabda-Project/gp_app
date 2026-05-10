import 'dart:async';
import 'dart:io';
import 'dart:developer';
import '../models/device_reading.dart';

/// Listens for UDP broadcasts from the Nabda ESP8266 wearable device
/// on port 4210 and converts raw sensor data into [DeviceReading]s.
///
/// The device sends packets in the format:
///   `MAX30105_reading: XX.XX | PULSE_reading: YY.YY | Batt: ZZ`
///
/// **Sensor mapping (IMPORTANT):**
///   - `PULSE_reading`    → Heart Rate (BPM) from analog Pulse Sensor
///   - `MAX30105_reading` → Heart Rate (BPM) from MAX30105 IR beat detection
///   - `Batt` (raw ADC 0–255) → Battery percentage (LiPo 3.0V–4.2V)
///
/// **Note:** Both sensor readings are heart rate values. The MAX30105 is
/// capable of SpO2 measurement, but the current firmware only uses
/// `checkForBeat(irValue)` (beat detection), NOT the red/IR ratio algorithm
/// needed for real SpO2. The `spo2` field in [DeviceReading] therefore
/// carries the MAX30105 heart rate reading and should NOT be treated as
/// actual blood oxygen saturation until the firmware is updated.
class UdpDeviceService {
  UdpDeviceService._();

  static UdpDeviceService? _instance;
  static UdpDeviceService get instance {
    _instance ??= UdpDeviceService._();
    return _instance!;
  }

  RawDatagramSocket? _socket;
  final StreamController<DeviceReading> _readingController =
      StreamController<DeviceReading>.broadcast();

  /// Whether the UDP listener is currently active.
  bool get isListening => _socket != null;

  /// Stream of parsed device readings.
  Stream<DeviceReading> get readings => _readingController.stream;

  /// Timestamp of the last received packet (used for connection-alive detection).
  DateTime? _lastPacketTime;
  DateTime? get lastPacketTime => _lastPacketTime;

  /// Whether we've received a packet in the last 5 seconds.
  bool get isReceivingData {
    if (_lastPacketTime == null) return false;
    return DateTime.now().difference(_lastPacketTime!).inSeconds < 5;
  }

  /// Start listening for UDP broadcasts on port 4210.
  ///
  /// Binds to `0.0.0.0` (all interfaces) so it receives packets regardless
  /// of which network interface the hotspot traffic arrives on.
  Future<void> start() async {
    if (_socket != null) {
      log('UDP listener already running', name: 'UdpDeviceService');
      return;
    }

    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        4210,
        reuseAddress: true,
      );
      _socket!.broadcastEnabled = true;

      log('UDP listener started on port 4210', name: 'UdpDeviceService');

      _socket!.listen(
        (RawSocketEvent event) {
          if (event == RawSocketEvent.read) {
            final datagram = _socket?.receive();
            if (datagram != null) {
              final message = String.fromCharCodes(datagram.data).trim();
              _handlePacket(message);
            }
          }
        },
        onError: (error) {
          log('UDP socket error: $error', name: 'UdpDeviceService');
        },
        onDone: () {
          log('UDP socket closed', name: 'UdpDeviceService');
        },
      );
    } catch (e) {
      log('Failed to start UDP listener: $e', name: 'UdpDeviceService');
      rethrow;
    }
  }

  /// Stop the UDP listener and clean up.
  void stop() {
    _socket?.close();
    _socket = null;
    _lastPacketTime = null;
    log('UDP listener stopped', name: 'UdpDeviceService');
  }

  /// Parse a raw UDP packet string into a [DeviceReading].
  ///
  /// Expected format:
  ///   `MAX30105_reading: 97.50 | PULSE_reading: 72.30 | Batt: 200`
  void _handlePacket(String message) {
    try {
      // Split by ' | ' to get the three segments
      final parts = message.split('|').map((s) => s.trim()).toList();
      if (parts.length < 3) {
        log('Malformed packet (expected 3 parts): $message',
            name: 'UdpDeviceService');
        return;
      }

      double? max30105Reading; // MAX30105 HR (mapped to spo2 field — NOT real SpO2)
      double? pulseReading; // Heart Rate from Pulse Sensor
      int? battRaw;

      for (final part in parts) {
        if (part.startsWith('MAX30105_reading:')) {
          max30105Reading =
              double.tryParse(part.replaceFirst('MAX30105_reading:', '').trim());
        } else if (part.startsWith('PULSE_reading:')) {
          pulseReading =
              double.tryParse(part.replaceFirst('PULSE_reading:', '').trim());
        } else if (part.startsWith('Batt:')) {
          battRaw = int.tryParse(part.replaceFirst('Batt:', '').trim());
        }
      }

      if (pulseReading == null || max30105Reading == null || battRaw == null) {
        log('Could not parse all fields from: $message',
            name: 'UdpDeviceService');
        return;
      }

      // Convert raw ADC battery value (0–255) to percentage.
      // LiPo assumption: 3.0V (0%) → 4.2V (100%).
      // ADC0832 maps 0–4.2V to 0–255.
      final voltage = battRaw / 255.0 * 4.2;
      final batteryPct = ((voltage - 3.0) / 1.2 * 100).clamp(0, 100).toInt();

      final reading = DeviceReading(
        heartRate: pulseReading,
        spo2: max30105Reading,
        batteryLevel: batteryPct,
        timestamp: DateTime.now(),
      );

      _lastPacketTime = DateTime.now();
      _readingController.add(reading);
    } catch (e) {
      log('Error parsing UDP packet "$message": $e',
          name: 'UdpDeviceService');
    }
  }

  /// Release all resources. Call when the app is shutting down.
  void dispose() {
    stop();
    _readingController.close();
    _instance = null;
  }
}
