import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Pages
import 'pages/splash_screen.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/register_profile_page.dart';
import 'pages/selamatdatang.dart';
import 'pages/dashboard.dart'; // ✅ TAMBAH
import 'pages/reservasi_page.dart';
import 'pages/panduan_page.dart';
import 'pages/rekomendasi_page.dart';
import 'pages/profil_page.dart';
import 'pages/statistik_page.dart';
import 'pages/tentang_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('id_ID', null);

  runApp(const GymnastikApp());
}

class GymnastikApp extends StatelessWidget {
  const GymnastikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gymnastik FT UMJ',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        fontFamily: "Poppins",
      ),

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('en', 'US'),
        Locale('id', 'ID'),
      ],

      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/register-profile': (context) => const RegisterProfilePage(),
        '/selamatdatang': (context) => const SelamatDatangPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/reservasi': (context) => const ReservasiPage(),
        '/panduan': (context) => const PanduanPage(),
        '/rekomendasi': (context) => const RekomendasiAIPage(),
        '/profil': (context) => const ProfilPage(),
        '/statistik': (context) => const StatistikPage(),
        '/tentang': (context) => const TentangPage(),
      },
    );
  }
}
