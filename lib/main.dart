import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/firebase_options.dart';
import 'package:connext_app/pages/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    // Keep Play Integrity as default. Force reCAPTCHA only when explicitly enabled.
    const forceRecaptcha = bool.fromEnvironment('FORCE_FIREBASE_RECAPTCHA');
    await FirebaseAuth.instance.setSettings(forceRecaptchaFlow: forceRecaptcha);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Connext',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        colorScheme: .fromSeed(seedColor: AppTheme.primary),
        fontFamily: 'PlusJakartaSans',
      ),
      home: SplashScreen(),
    );
  }
}
