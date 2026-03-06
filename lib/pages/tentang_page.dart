import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dashboard.dart';

class TentangPage extends StatelessWidget {
  const TentangPage({super.key});

  // === BUKA LINK IG ===
  Future<void> _openInstagram() async {
    final Uri url = Uri.parse("https://www.instagram.com/gym.fteknik/");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Tidak bisa membuka Instagram');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,

        // ========= TOMBOL BACK (KE DASHBOARD) =========
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardPage()),
            );
          },
        ),

        title: const Text(
          'Tentang Aplikasi',
          style: TextStyle(color: Colors.white),
        ),
      ),

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
          SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // ===================== CARD ======================
                AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.blueAccent.withValues(alpha: .6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: .4),
                        blurRadius: 25,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // ================= LOGO UMJ =================
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          "assets/logo.umj.png",
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        "Tim Pengembang Aplikasi Gym\n"
                        "Fakultas Teknik Informatika\n"
                        "Universitas Muhammadiyah Jakarta\n",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 17,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 15),

                      const ContactItem(
                        icon: FontAwesomeIcons.whatsapp,
                        text: "+62 8582144478",
                        color: Colors.greenAccent,
                      ),

                      const SizedBox(height: 10),

                      // ================= IG BUTTON =================
                      GestureDetector(
                        onTap: _openInstagram,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              FontAwesomeIcons.instagram,
                              color: Colors.pinkAccent,
                              size: 22,
                            ),
                            SizedBox(width: 10),
                            Text(
                              "@gym.fteknik",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      const ContactItem(
                        icon: FontAwesomeIcons.envelope,
                        text: "gymapp@univxyz.ac.id",
                        color: Colors.orangeAccent,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                Divider(
                  color: Colors.white.withValues(alpha: .3),
                  thickness: 1,
                ),

                const SizedBox(height: 10),

                const Text(
                  "Versi Aplikasi: 1.0.0",
                  style: TextStyle(color: Colors.white60),
                ),

                const SizedBox(height: 20),

                const Text(
                  "© 2026 Universitas Muhammadiyah Jakarta.\nSemua hak cipta dilindungi.",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ===================== CONTACT ITEM ======================
class ContactItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const ContactItem({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 700),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}