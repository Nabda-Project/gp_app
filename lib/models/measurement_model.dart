import 'package:hive/hive.dart';

class MeasurementModel {
  final String type; // e.g., 'HeartRate', 'SpO2'
  final double value;
  final String unit;
  final DateTime timestamp;

  MeasurementModel({
    required this.type,
    required this.value,
    required this.unit,
    required this.timestamp,
  });
}

class MeasurementModelAdapter extends TypeAdapter<MeasurementModel> {
  @override
  final int typeId = 1;

  @override
  MeasurementModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MeasurementModel(
      type: fields[0] as String,
      value: fields[1] as double,
      unit: fields[2] as String,
      timestamp: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MeasurementModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.timestamp);
  }
}
