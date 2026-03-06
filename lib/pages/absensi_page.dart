import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'qr_scan_page.dart';

class AbsensiPage extends StatefulWidget {
  const AbsensiPage({super.key});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> {
  String mode = "qr";
  String modeType = "checkin";

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  bool loading = false;

  final user = FirebaseAuth.instance.currentUser;

  String get formattedDate => DateFormat("yyyy-MM-dd").format(selectedDate);
  String get formattedTime =>
      "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";

  Future<bool> _hasBookingToday() async {
    if (user == null) return false;

    final ref = FirebaseDatabase.instance.ref("bookings/${user!.uid}");
    final snap = await ref.get();
    if (!snap.exists) return false;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    for (var b in snap.children) {
      final data = Map<String, dynamic>.from(b.value as Map);
      if (data["gym_date"] == today && data["status"] != "Batal") {
        return true;
      }
    }
    return false;
  }

  Future<bool> _hasCheckInToday() async {
    if (user == null) return false;

    final ref = FirebaseDatabase.instance.ref("absensi/${user!.uid}");
    final snap = await ref.get();
    if (!snap.exists) return false;

    final today = DateFormat("yyyy-MM-dd").format(DateTime.now());

    for (var d in snap.children) {
      final data = Map<String, dynamic>.from(d.value as Map);
      if (data["tanggal"] == today && data["status"] == "Check-In") {
        return true;
      }
    }
    return false;
  }

  Future<bool> _hasCheckOutToday() async {
    if (user == null) return false;

    final ref = FirebaseDatabase.instance.ref("absensi/${user!.uid}");
    final snap = await ref.get();
    if (!snap.exists) return false;

    final today = DateFormat("yyyy-MM-dd").format(DateTime.now());

    for (var d in snap.children) {
      final data = Map<String, dynamic>.from(d.value as Map);
      if (data["tanggal"] == today && data["status"] == "Check-Out") {
        return true;
      }
    }
    return false;
  }

  Future<DatabaseReference?> _getTodayBookingRef() async {
    if (user == null) return null;

    final today = DateFormat("yyyy-MM-dd").format(DateTime.now());
    final ref = FirebaseDatabase.instance.ref("bookings/${user!.uid}");

    final snap = await ref.orderByChild("gym_date").equalTo(today).get();
    if (!snap.exists) return null;

    for (var b in snap.children) {
      final data = Map<String, dynamic>.from(b.value as Map);
      if (data["status"] != "Batal") {
        return b.ref;
      }
    }
    return null;
  }

  Future<void> _saveManual() async {
    if (user == null) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => loading = true);

    final hasBooking = await _hasBookingToday();
    if (!mounted) return;

    if (!hasBooking) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Anda harus booking terlebih dahulu")),
      );
      setState(() => loading = false);
      return;
    }

    final hasCheckIn = await _hasCheckInToday();
    if (!mounted) return;

    if (modeType == "checkin" && hasCheckIn) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Anda sudah Check-In hari ini")),
      );
      setState(() => loading = false);
      return;
    }

    if (modeType == "checkout" && !hasCheckIn) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Anda belum Check-In hari ini")),
      );
      setState(() => loading = false);
      return;
    }

    final hasCheckOut = await _hasCheckOutToday();
    if (!mounted) return;

    if (modeType == "checkout" && hasCheckOut) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Anda sudah Check-Out hari ini")),
      );
      setState(() => loading = false);
      return;
    }

    final bookingRef = await _getTodayBookingRef();
    if (bookingRef != null) {
      if (modeType == "checkin") {
        await bookingRef.update({"status": "Hadir"});
      } else {
        await bookingRef.update({"status": "Selesai"});
      }
    }

    final ref = FirebaseDatabase.instance.ref("absensi/${user!.uid}").push();

    await ref.set({
      "tanggal": formattedDate,
      "jam": formattedTime,
      "status": modeType == "checkin" ? "Check-In" : "Check-Out",
      "mode": "manual",
    });

    if (!mounted) return;

    setState(() => loading = false);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          "Absensi manual ${modeType == "checkin" ? "Check-In" : "Check-Out"} berhasil",
        ),
      ),
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _openQRScanner() async {
    final messenger = ScaffoldMessenger.of(context);

    final hasBooking = await _hasBookingToday();
    if (!mounted) return;

    if (!hasBooking) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Anda harus booking terlebih dahulu")),
      );
      return;
    }

    final hasCheckIn = await _hasCheckInToday();
    if (!mounted) return;

    if (modeType == "checkout" && !hasCheckIn) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Anda belum Check-In hari ini")),
      );
      return;
    }

    final hasCheckOut = await _hasCheckOutToday();
    if (!mounted) return;

    if (modeType == "checkout" && hasCheckOut) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Anda sudah Check-Out hari ini")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRScanPage(modeType: modeType),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        Positioned.fill(
          child: Image.asset(
            "assets/fotobackground.jpg",
            fit: BoxFit.cover,
          ),
        ),

        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xAA0A0F1C),
                    Color(0xCC111B2E),
                    Color(0xDD000000),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),

        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.black.withValues(alpha:0.6),
            centerTitle: true,
            title: const Text("Absensi Gym",
                style: TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),

          body: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Pilih Mode Absensi",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text("QR Mode"),
                              selected: mode == "qr",
                              onSelected: (_) =>
                                  setState(() => mode = "qr"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text("Manual Mode"),
                              selected: mode == "manual",
                              onSelected: (_) =>
                                  setState(() => mode = "manual"),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        "Jenis Absensi",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text("Check-In"),
                              selected: modeType == "checkin",
                              onSelected: (_) =>
                                  setState(() => modeType = "checkin"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text("Check-Out"),
                              selected: modeType == "checkout",
                              onSelected: (_) =>
                                  setState(() => modeType = "checkout"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (mode == "qr") _qrModeUI(),
                if (mode == "manual") _manualModeUI(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _qrModeUI() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner,
                size: 120, color: Colors.blueAccent),
            const SizedBox(height: 10),
            Text(
              "Scan QR Untuk ${modeType == "checkin" ? "Check-In" : "Check-Out"}",
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _openQRScanner,
              child: const Text("Buka Kamera Scan"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _manualModeUI() {
    return Expanded(
      child: Column(
        children: [
          _card("Tanggal", formattedDate, Icons.calendar_month, _pickDate),
          const SizedBox(height: 14),
          _card("Jam", formattedTime, Icons.access_time, _pickTime),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: loading ? null : () async => await _saveManual(),
              child: Text(
                loading
                    ? "Menyimpan..."
                    : "Simpan ${modeType == "checkin" ? "Check-In" : "Check-Out"}",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, String value, IconData icon, VoidCallback tap) {
    return InkWell(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
            Text(value, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2090),
    );
    if (p != null) setState(() => selectedDate = p);
  }

  Future<void> _pickTime() async {
    final p =
        await showTimePicker(context: context, initialTime: selectedTime);
    if (p != null) setState(() => selectedTime = p);
  }
}