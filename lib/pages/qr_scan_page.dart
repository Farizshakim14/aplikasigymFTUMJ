import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanPage extends StatefulWidget {
  final String modeType; // checkin / checkout
  const QRScanPage({super.key, required this.modeType});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  final user = FirebaseAuth.instance.currentUser;
  bool processing = false;

  // ================= CARI BOOKING HARI INI =================
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

  // ================= SIMPAN ABSENSI + UPDATE BOOKING =================
  Future<void> _saveAttendance() async {
    if (user == null) return;
    if (processing) return;
    processing = true;

    final messenger = ScaffoldMessenger.of(context);

    try {
      // ------------ UPDATE BOOKING STATUS ------------
      final bookingRef = await _getTodayBookingRef();
      if (bookingRef != null) {
        if (widget.modeType == "checkin") {
          await bookingRef.update({"status": "Hadir"});
        } else {
          await bookingRef.update({"status": "Selesai"});
        }
      }

      // ------------ SIMPAN ABSENSI ------------
      final ref =
          FirebaseDatabase.instance.ref("absensi/${user!.uid}").push();

      await ref.set({
        "tanggal": DateFormat("yyyy-MM-dd").format(DateTime.now()),
        "jam": DateFormat("HH:mm").format(DateTime.now()),
        "status":
            widget.modeType == "checkin" ? "Check-In" : "Check-Out",
        "mode": "qr",
      });

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            "QR ${widget.modeType == "checkin" ? "Check-In" : "Check-Out"} berhasil",
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      processing = false;
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text("Gagal menyimpan QR: $e")),
      );
    }
  }

  // ================= QR LISTENER =================
  void _onDetect(BarcodeCapture capture) async {
    if (processing) return;

    final barcode = capture.barcodes.first;
    final value = barcode.rawValue;

    if (value == null) return;

    // Contoh sederhana → jika QR valid (apapun isinya), langsung simpan
    await _saveAttendance();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "QR ${widget.modeType == "checkin" ? "Check-In" : "Check-Out"}",
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha:.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  "Arahkan kamera ke QR untuk ${widget.modeType == "checkin" ? "Check-In" : "Check-Out"}",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
