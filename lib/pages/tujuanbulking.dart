import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class TujuanBulkingPage extends StatefulWidget {
  const TujuanBulkingPage({super.key});

  @override
  State<TujuanBulkingPage> createState() => _TujuanBulkingPageState();
}

class _TujuanBulkingPageState extends State<TujuanBulkingPage> {
  String? selectedGoal;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreviousGoal();
  }

  Future<void> _loadPreviousGoal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot =
        await FirebaseDatabase.instance.ref("users/${user.uid}/tujuan").get();

    if (snapshot.exists) {
      selectedGoal = snapshot.value.toString();
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<void> _simpanTujuan(String tujuan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseDatabase.instance.ref("users/${user.uid}").update({
      "tujuan": tujuan,
      "profilLengkap": true,
    });

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, "/selamatdatang");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      body: Stack(
        children: [

          Positioned.fill(
            child: Image.asset(
              "assets/fotobackground.jpg",
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: .4),
            ),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.transparent),
            ),
          ),

          SafeArea(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      double screenWidth = constraints.maxWidth;

                      double cardWidth = screenWidth * 0.9;
                      if (cardWidth > 500) cardWidth = 500;

                      return Center(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 18),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(Icons.arrow_back,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                Image.asset(
                                  "assets/onboard2.png",
                                  height: screenWidth < 400
                                      ? 150
                                      : screenWidth < 700
                                          ? 190
                                          : 230,
                                ),

                                const SizedBox(height: 14),

                                const Text(
                                  "Apa tujuan Anda?",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                const Text(
                                  "Pilih tujuan fitness utama Anda agar kami dapat menyesuaikan program.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),

                                const SizedBox(height: 28),

                                _goalCard(
                                  title: "Bulking",
                                  subtitle: "Ingin meningkatkan massa otot",
                                  tujuan: "bulking",
                                  colors: const [
                                    Color(0xFF92A3FD),
                                    Color(0xFF9DCEFF)
                                  ],
                                  icon: Icons.fitness_center,
                                  width: cardWidth,
                                ),

                                const SizedBox(height: 16),

                                _goalCard(
                                  title: "Maintaining",
                                  subtitle: "Ingin menjaga kondisi tubuh",
                                  tujuan: "maintaining",
                                  colors: const [
                                    Color(0xFF77E2C6),
                                    Color(0xFF62D2A2)
                                  ],
                                  icon: Icons.verified,
                                  width: cardWidth,
                                ),

                                const SizedBox(height: 16),

                                _goalCard(
                                  title: "Cutting",
                                  subtitle: "Ingin menurunkan berat badan",
                                  tujuan: "cutting",
                                  colors: const [
                                    Color(0xFFFF9A9E),
                                    Color(0xFFFAD0C4)
                                  ],
                                  icon: Icons.local_fire_department,
                                  width: cardWidth,
                                ),

                                const SizedBox(height: 14),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _goalCard({
    required String title,
    required String subtitle,
    required String tujuan,
    required List<Color> colors,
    required IconData icon,
    required double width,
  }) {
    final bool isSelected = selectedGoal == tujuan;

    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: isSelected ? 1.03 : 1,

      child: InkWell(
        borderRadius: BorderRadius.circular(25),

        onTap: () async {
          final confirm =
              await _showConfirmDialog("Yakin memilih $title sebagai tujuan?");

          if (confirm == true) {
            if (!mounted) return;
            setState(() => selectedGoal = tujuan);
            await _simpanTujuan(tujuan);
          }
        },

        child: Ink(
          width: width,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),

          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white30,
                child: Icon(icon, color: Colors.white),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String message) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Konfirmasi"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Ya, lanjut"),
            ),
          ],
        );
      },
    );
  }
}