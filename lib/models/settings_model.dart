import 'package:hive/hive.dart';

class SettingsModel {
  bool isDarkMode;
  bool enableNotifications;
  String languageCode;

  SettingsModel({
    this.isDarkMode = false,
    this.enableNotifications = true,
    this.languageCode = 'en',
  });
}

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 2; // Unique ID for this adapter

  @override
  SettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsModel(
      enableNotifications: fields[1] as bool,
      languageCode: fields.containsKey(2) ? fields[2] as String : 'en',
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(1)
      ..write(obj.enableNotifications)
      ..writeByte(2)
      ..write(obj.languageCode);
  }
}
