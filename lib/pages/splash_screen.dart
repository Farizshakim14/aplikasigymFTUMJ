import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'onboarding_page.dart';
import 'dashboard.dart';
import 'register_profile_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _rotateAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      _handleNavigation();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// ================= AUTH + PROFIL GUARD =================
  Future<void> _handleNavigation() async {
    final navigator = Navigator.of(context);

    final user = FirebaseAuth.instance.currentUser;

    /// ❌ BELUM LOGIN
    if (user == null) {
      if (!mounted) return;
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
      );
      return;
    }

    /// ✅ SUDAH LOGIN → cek profilLengkap
    final snap = await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(user.uid)
        .get();

    if (!mounted) return;

    if (!snap.exists) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
      );
      return;
    }

    final data = Map<String, dynamic>.from(snap.value as Map);
    final lengkap = data['profilLengkap'] ?? false;

    /// ❌ PROFIL BELUM LENGKAP
    if (!lengkap) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const RegisterProfilePage()),
      );
      return;
    }

    /// ✅ SEMUA AMAN → DASHBOARD
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      body: Stack(
        children: [

          /// BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              "assets/fotobackground.jpg",
              fit: BoxFit.cover,
            ),
          ),

          /// DARK OVERLAY
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: .4),
            ),
          ),

          /// BLUR EFFECT
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.transparent),
            ),
          ),

          /// CONTENT
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotateAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.fitness_center,
                    size: 115,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  "GYMNASIUM",
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "FT UMJ",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}