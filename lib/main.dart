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
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        useMaterial3: true,
        scaffoldBackgroundColor: AppTheme.primary,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: AppTheme.third,
              brightness: Brightness.dark,
            ).copyWith(
              primary: AppTheme.third,
              secondary: AppTheme.fourth,
              surface: const Color(0xFF171A33),
              onSurface: AppTheme.secondary,
              onPrimary: AppTheme.primary,
            ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.secondary,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF171A33),
          elevation: 12,
          shadowColor: AppTheme.third.withOpacity(0.2),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppTheme.third.withOpacity(0.12), width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.third,
            foregroundColor: AppTheme.primary,
            elevation: 10,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF171A33),
          hintStyle: TextStyle(color: AppTheme.secondary.withOpacity(0.6)),
          labelStyle: const TextStyle(color: AppTheme.secondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: AppTheme.third.withOpacity(0.16)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: AppTheme.third.withOpacity(0.16)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppTheme.third, width: 1.8),
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.secondary),
        textTheme: ThemeData.dark().textTheme.apply(
          fontFamily: 'PlusJakartaSans',
          bodyColor: AppTheme.secondary,
          displayColor: AppTheme.secondary,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF23264D),
          contentTextStyle: const TextStyle(
            color: AppTheme.secondary,
            fontFamily: 'PlusJakartaSans',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF171A33),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: ThemeData.dark().textTheme.titleLarge?.copyWith(
            color: AppTheme.secondary,
            fontWeight: FontWeight.w800,
            fontFamily: 'PlusJakartaSans',
          ),
          contentTextStyle: ThemeData.dark().textTheme.bodyMedium?.copyWith(
            color: AppTheme.secondary,
            fontFamily: 'PlusJakartaSans',
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.secondary,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontFamily: 'PlusJakartaSans',
            ),
          ),
        ),
      ),
      home: SplashScreen(),
    );
  }
}
