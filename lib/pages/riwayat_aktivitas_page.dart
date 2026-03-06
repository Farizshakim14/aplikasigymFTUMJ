import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class RiwayatAktivitasPage extends StatefulWidget {
  const RiwayatAktivitasPage({super.key});

  @override
  State<RiwayatAktivitasPage> createState() => _RiwayatAktivitasPageState();
}

class _RiwayatAktivitasPageState extends State<RiwayatAktivitasPage> {
  final user = FirebaseAuth.instance.currentUser;
  String filter = "all";

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User belum login")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Riwayat Aktivitas"),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
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

          Column(
            children: [

              // ===== FILTER BUTTONS =====
              Padding(
                padding: const EdgeInsets.all(10),
                child: Wrap(
                  spacing: 8,
                  children: [
                    _chip("all", "Semua"),
                    _chip("booking", "Booking"),
                    _chip("absensi", "Absensi"),
                    _chip("ai", "AI"),
                    _chip("program", "Program"),
                  ],
                ),
              ),

              // ===== DATA LIST =====
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadTimeline(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final data = snapshot.data!;
                    if (data.isEmpty) {
                      return const Center(child: Text("Belum ada aktivitas"));
                    }

                    final grouped = _groupByMonth(data);

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: grouped.entries.map((e) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.key,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 8),

                            ...e.value.map((item) => _timelineCard(item)),
                            const SizedBox(height: 10),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= CHIP =================
  Widget _chip(String key, String text) {
    final active = filter == key;
    return ChoiceChip(
      label: Text(text),
      selected: active,
      onSelected: (_) => setState(() => filter = key),
    );
  }

  // ================= LOAD DATA =================
  Future<List<Map<String, dynamic>>> _loadTimeline() async {
    final List<Map<String, dynamic>> t = [];

    await _load("bookings/${user!.uid}", "booking", t);
    await _load("absensi/${user!.uid}", "absensi", t);
    await _load("history/${user!.uid}", "ai", t);
    await _load("checkin/${user!.uid}", "checkin", t);
    await _load("program_history/${user!.uid}", "program", t);

    // urut terbaru
    t.sort((a, b) => b['tanggal'].compareTo(a['tanggal']));

    // filter
    if (filter != "all") {
      t.removeWhere((item) => item["type"] != filter);
    }

    return t;
  }

  Future<void> _load(
      String path, String type, List<Map<String, dynamic>> list) async {
    final snap = await FirebaseDatabase.instance.ref(path).get();
    if (!snap.exists) return;

    final data = Map<String, dynamic>.from(snap.value as Map);

    for (var v in data.values) {
      final item = Map<String, dynamic>.from(v);

      list.add({
        "type": type,
        "tanggal": item["tanggal"] ?? DateTime.now().toString(),
        "title": _getTitle(type),
        "subtitle": _getSubtitle(type, item),
        "status": item["status"] ?? "-",
      });
    }
  }

  // ================= TITLE =================
  String _getTitle(String t) {
    switch (t) {
      case "booking":
        return "Booking Gym";
      case "absensi":
        return "Absensi Gym";
      case "ai":
        return "Rekomendasi AI";
      case "checkin":
        return "Check-In Gym";
      case "program":
        return "Program Latihan";
    }
    return "Aktivitas";
  }

  // ================= SUBTITLE =================
  String _getSubtitle(String t, Map item) {
    switch (t) {
      case "booking":
        return "Sesi: ${item['sesi']}";
      case "absensi":
        return "Jam: ${item['jam']}";
      case "ai":
        return "BMI: ${item['bmi']?.toStringAsFixed(1)} | Tujuan: ${item['tujuan']}";
      case "checkin":
        return "Check-in berhasil";
      case "program":
        return item["program"] ?? "Program Latihan";
    }
    return "";
  }

  // ================= GROUPING =================
  Map<String, List<Map<String, dynamic>>> _groupByMonth(
      List<Map<String, dynamic>> data) {
    final Map<String, List<Map<String, dynamic>>> result = {};
    final f = DateFormat("MMMM yyyy");

    for (var i in data) {
      DateTime d = DateTime.parse(i["tanggal"]);
      String bulan = f.format(d);

      result.putIfAbsent(bulan, () => []);
      result[bulan]!.add(i);
    }
    return result;
  }

  // ================= CARD =================
  Widget _timelineCard(Map<String, dynamic> item) {
    IconData icon;
    Color color;

    switch (item["type"]) {
      case "booking":
        icon = Icons.calendar_month;
        color = Colors.blue;
        break;
      case "absensi":
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case "ai":
        icon = Icons.auto_awesome;
        color = Colors.deepPurple;
        break;
      case "checkin":
        icon = Icons.login;
        color = Colors.teal;
        break;
      case "program":
        icon = Icons.fitness_center;
        color = Colors.orange;
        break;
      default:
        icon = Icons.timeline;
        color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha:.2),
            child: Icon(icon, color: color),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item["title"],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(item["subtitle"],
                    style: const TextStyle(color: Colors.grey)),
                Text(item["tanggal"],
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),

          Text(
            item["status"] ?? "-",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: (item["status"]?.contains("Selesai") ?? false ||
                      item["status"]?.contains("Hadir") ?? false)
                  ? Colors.green
                  : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}