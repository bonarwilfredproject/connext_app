import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/pages/auth/daftar_page.dart';
import 'package:connext_app/pages/home_page/home_page.dart';
import 'package:connext_app/pages/landing_page/landing_page.dart';
import 'package:connext_app/pages/auth/log_in_page.dart';
import 'package:connext_app/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Connext',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        colorScheme: .fromSeed(seedColor: AppTheme.primary),
        fontFamily: 'RacingSansOne',
      ),
      home: SplashScreen(),
    );
  }
}
