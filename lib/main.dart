import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/storage_service.dart';
import 'models/settings_model.dart';
import 'utils/app_localizations.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    await StorageService.init();
  } catch (e) {
    print("StorageService Init Failed: $e");
  }
  runApp(const GPApp());
}

class GPApp extends StatelessWidget {
  const GPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<SettingsModel>>(
      valueListenable:
          Hive.box<SettingsModel>(StorageService.settingsBoxName).listenable(),
      builder: (context, box, _) {
        final settings = box.get('appSettings') ?? SettingsModel();

        return MaterialApp(
          title: 'HealthSync',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          locale: Locale(settings.languageCode),
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('ar', ''), // Arabic
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale?.languageCode) {
                return supportedLocale;
              }
            }
            return supportedLocales.first;
          },
          initialRoute: AppRoutes.splash,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
