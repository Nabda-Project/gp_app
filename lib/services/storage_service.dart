import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/measurement_model.dart';
import '../models/settings_model.dart';

class StorageService {
  static const String userBoxName = 'userBox';
  static const String measurementsBoxName = 'measurementsBox';
  static const String settingsBoxName = 'settingsBox';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MeasurementModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SettingsModelAdapter());
    }

    // Open Boxes
    await Hive.openBox<UserModel>(userBoxName);
    await Hive.openBox<MeasurementModel>(measurementsBoxName);
    await Hive.openBox<SettingsModel>(settingsBoxName);
  }

  // --- User Methods ---

  static Future<void> saveUser(UserModel user) async {
    final box = Hive.box<UserModel>(userBoxName);
    await box.put('currentUser', user);
  }

  static UserModel? getUser() {
    final box = Hive.box<UserModel>(userBoxName);
    return box.get('currentUser');
  }

  static bool get isLoggedIn => getUser() != null;

  static Future<void> logout() async {
    final box = Hive.box<UserModel>(userBoxName);
    await box.clear(); // Clears all data in the user box
  }

  // --- Measurement Methods ---

  static Future<void> saveMeasurement(MeasurementModel measurement) async {
    final box = Hive.box<MeasurementModel>(measurementsBoxName);
    await box.add(measurement);
  }

  static List<MeasurementModel> getMeasurements() {
    final box = Hive.box<MeasurementModel>(measurementsBoxName);
    return box.values.toList();
  }

  // --- Settings Methods ---

  static Future<void> saveSettings(SettingsModel settings) async {
    final box = Hive.box<SettingsModel>(settingsBoxName);
    await box.put('appSettings', settings);
  }

  static SettingsModel getSettings() {
    final box = Hive.box<SettingsModel>(settingsBoxName);
    return box.get('appSettings') ?? SettingsModel();
  }
}
