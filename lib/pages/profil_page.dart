import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'riwayat_aktivitas_page.dart';
import 'login_page.dart';
import 'absensi_page.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User belum login")),
      );
    }

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

          StreamBuilder<DatabaseEvent>(
            stream: FirebaseDatabase.instance
                .ref()
                .child('users')
                .child(user.uid)
                .onValue,
            builder: (context, snapshot) {
              if (!snapshot.hasData ||
                  snapshot.data!.snapshot.value == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final data =
                  Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

              return SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _header(context),
                        const SizedBox(height: 24),
                        _profileCard(data),
                        const SizedBox(height: 24),
                        _menuSection(context),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
          child: _iconBox(Icons.arrow_back),
        ),
        const Text("Profil",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        _iconBox(Icons.more_horiz),
      ],
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }

  Widget _profileCard(Map<String, dynamic> data) {
    final usia = data['tanggal_lahir'] != null &&
            data['tanggal_lahir'].toString().isNotEmpty
        ? _hitungUsia(data['tanggal_lahir'])
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha:.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['nama'] ?? '-',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                      _labelTujuan(data['tujuan']),
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoBox("${data['tb'] ?? '-'} cm", "Tinggi"),
              _infoBox("${data['bb'] ?? '-'} kg", "Berat"),
              _infoBox(usia != null ? "$usia th" : "-", "Usia"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String value, String label) {
    return Container(
      width: 95,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Color(0xFF92A3FD), fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _menuSection(BuildContext context) {
    return Column(
      children: [
        _menuCard("Akun", [
          "Data Pribadi",
          "Riwayat Aktivitas",
          "Absensi",
        ], context),
        const SizedBox(height: 16),
        _menuCard("Lainnya", [
          "Kebijakan Privasi",
          "Pengaturan",
          "Keluar",
        ], context),
      ],
    );
  }

  Widget _menuCard(String title, List<String> items, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha:.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 12),

          ...items.map(
            (e) => GestureDetector(
              onTap: () {
                if (e == "Keluar") {
                  _confirmLogout(context);
                } 
                else if (e == "Riwayat Aktivitas") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RiwayatAktivitasPage()),
                  );
                } 
                else if (e == "Absensi") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AbsensiPage()),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      e,
                      style: TextStyle(
                          color: e == "Keluar"
                              ? Colors.red
                              : Colors.white70),
                    ),
                    Icon(
                      e == "Keluar"
                          ? Icons.logout
                          : Icons.chevron_right,
                      size: 18,
                      color: e == "Keluar"
                          ? Colors.red
                          : Colors.white70,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text("Keluar Akun"),
        content: const Text("Yakin ingin keluar?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Keluar"),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm == true) _logout();
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator()),
    );

    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  int _hitungUsia(String tanggalLahir) {
    try {
      DateTime birthDate = DateTime.parse(tanggalLahir);
      final today = DateTime.now();
      int age = today.year - birthDate.year;

      if (today.month < birthDate.month ||
          (today.month == birthDate.month &&
              today.day < birthDate.day)) {
        age--;
      }

      return age;
    } catch (_) {
      return 0;
    }
  }

  String _labelTujuan(String? tujuan) {
    switch (tujuan) {
      case 'bulking':
        return 'Program Bulking';
      case 'cutting':
        return 'Program Cutting';
      case 'maintaining':
        return 'Program Maintaining';
      default:
        return 'Belum memilih program';
    }
  }
}