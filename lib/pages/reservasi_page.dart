import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ReservasiPage extends StatefulWidget {
  const ReservasiPage({super.key});

  @override
  State<ReservasiPage> createState() => _ReservasiPageState();
}

class _ReservasiPageState extends State<ReservasiPage> {

  DateTime _tanggal = DateTime.now();
  String _sesi = 'Sesi 1 (08:00-10:00)';
  bool _loading = false;

  String get formattedDate =>
      DateFormat('dd MMM yyyy', 'id_ID').format(_tanggal);

  String normalize(String text) {
    try {
      if (text.contains("(")) {
        text = text.substring(text.indexOf("(") + 1, text.indexOf(")"));
      }

      return text
          .replaceAll(" ", "")
          .replaceAll(".", ":")
          .replaceAll("–", "-")
          .replaceAll("—", "-")
          .trim();
    } catch (_) {
      return text;
    }
  }

  Future<void> _simpanReservasi() async {

    if (_loading) return;

    setState(() {
      _loading = true;
    });

    try {

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login terlebih dahulu")),
        );

        setState(() {
          _loading = false;
        });

        return;
      }

      final userSnap =
          await FirebaseDatabase.instance.ref("users/${user.uid}").get();

      String userName = "-";

      if (userSnap.exists) {
        final data = Map<String, dynamic>.from(userSnap.value as Map);
        userName = data["nama"] ?? "-";
      }

      final dateKey = DateFormat('yyyy-MM-dd').format(_tanggal);
      final userSessionNormalized = normalize(_sesi);

      final slotsRef = FirebaseDatabase.instance.ref("slots");

      final slotSnap =
          await slotsRef.orderByChild("date").equalTo(dateKey).get();

      DatabaseReference? targetSlot;
      int remaining = 0;

      if (slotSnap.exists) {

        for (var slot in slotSnap.children) {

          final data = Map<String, dynamic>.from(slot.value as Map);

          final slotTime = normalize("${data["time"]}");

          int sisa =
              int.tryParse("${data["remaining"]}") ??
              int.tryParse("${data["kapasitas"]}") ??
              0;

          if (slotTime == userSessionNormalized && sisa > 0) {
            targetSlot = slot.ref;
            remaining = sisa;
            break;
          }

        }

      }

      if (targetSlot == null) {

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Slot tidak tersedia / sudah penuh"),
          ),
        );

        setState(() {
          _loading = false;
        });

        return;
      }

      final userBookingRef =
          FirebaseDatabase.instance.ref("bookings/${user.uid}");

      final check =
          await userBookingRef.orderByChild("gym_date").equalTo(dateKey).get();

      if (check.exists) {

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kamu sudah melakukan booking hari ini"),
          ),
        );

        setState(() {
          _loading = false;
        });

        return;
      }

      await targetSlot.update({
        "remaining": remaining - 1
      });

      await userBookingRef.push().set({

        "user_id": user.uid,
        "user_name": userName,
        "gym_date": dateKey,
        "sesi": _sesi,
        "created_at": DateTime.now().toIso8601String()

      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reservasi berhasil disimpan")),
      );

      Navigator.pushReplacementNamed(context, "/dashboard");

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal reservasi: $e")),
      );

    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/dashboard'),
        ),

        title: const Text(
          'Reservasi Gym',
          style: TextStyle(color: Colors.black),
        ),
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

          SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),

                  child: Padding(
                    padding: const EdgeInsets.all(20),

                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        _cardItem(
                          icon: Icons.calendar_month,
                          title: 'Tanggal',
                          value: formattedDate,
                          onTap: _pickDate,
                          clickable: true,
                        ),

                        const SizedBox(height: 14),

                        _cardItem(
                          icon: Icons.access_time,
                          title: 'Sesi',
                          value: _sesi,
                          onTap: _pickSesi,
                          clickable: true,
                        ),

                        const SizedBox(height: 40),

                        SizedBox(
                          width: double.infinity,
                          height: 56,

                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),

                            onPressed: _loading ? null : _simpanReservasi,

                            child: _loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    'Reservasi',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        )

                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

  }

  Widget _cardItem({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
    bool clickable = false,
  }) {

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: clickable ? onTap : null,

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),

        child: Row(
          children: [

            Icon(icon, color: Colors.grey),

            const SizedBox(width: 14),

            Expanded(child: Text(title)),

            Text(value, style: const TextStyle(color: Colors.grey)),

          ],
        ),
      ),
    );

  }

  Future<void> _pickDate() async {

    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      setState(() {
        _tanggal = picked;
      });
    }

  }

  void _pickSesi() {

    showModalBottomSheet(
      context: context,

      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          _sesiTile('Sesi 1 (08:00-10:00)'),
          _sesiTile('Sesi 2 (10:00-12:00)'),
          _sesiTile('Sesi 3 (13:00-15:00)'),
        ],
      ),

    );

  }

  Widget _sesiTile(String value) {

    return ListTile(
      title: Text(value),

      onTap: () {
        setState(() {
          _sesi = value;
        });
        Navigator.pop(context);
      },
    );

  }

}