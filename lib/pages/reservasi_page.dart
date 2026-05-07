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

  Map<String, dynamic>? _selectedSlot;
  bool _loading = false;
  late Future<List<Map<String, dynamic>>> _slotsFuture;

  @override
  void initState() {
    super.initState();
    _slotsFuture = _loadAvailableSlots();
  }

  Future<List<Map<String, dynamic>>> _loadAvailableSlots() async {
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final nextWeek = today.add(const Duration(days: 7));
    final nextWeekStr = DateFormat('yyyy-MM-dd').format(nextWeek);

    final slotSnap = await FirebaseDatabase.instance
        .ref("slots")
        .orderByChild("date")
        .startAt(todayStr)
        .endAt(nextWeekStr)
        .get();
    
    List<Map<String, dynamic>> slots = [];
    if (slotSnap.exists) {
      for (var slot in slotSnap.children) {
        final data = Map<String, dynamic>.from(slot.value as Map);
        data['id'] = slot.key;
        slots.add(data);
      }
    }
    slots.sort((a, b) {
      int dateCmp = (a['date'] ?? '').compareTo(b['date'] ?? '');
      if (dateCmp != 0) return dateCmp;
      return (a['time'] ?? '').compareTo(b['time'] ?? '');
    });
    return slots;
  }

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

    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan pilih sesi terlebih dahulu")),
      );
      return;
    }

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
        setState(() => _loading = false);
        return;
      }

      final userSnap = await FirebaseDatabase.instance.ref("users/${user.uid}").get();
      String userName = "-";
      String userGender = "";
      if (userSnap.exists) {
        final data = Map<String, dynamic>.from(userSnap.value as Map);
        userName = data["nama"] ?? "-";
        userGender = data["jk"] ?? "";
      }

      final slotId = _selectedSlot!['id'];
      final dateKey = _selectedSlot!['date'];
      final targetSlotRef = FirebaseDatabase.instance.ref("slots/$slotId");
      
      final slotSnap = await targetSlotRef.get();
      if (!slotSnap.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Slot sudah tidak tersedia")));
        setState(() => _loading = false);
        return;
      }

      final data = Map<String, dynamic>.from(slotSnap.value as Map);
      final slotGender = "${data["gender"]}";
      final status = data["status"] ?? "Buka";
      int sisa = int.tryParse("${data["remaining"]}") ?? int.tryParse("${data["kapasitas"]}") ?? 0;

      if (status == "Ditutup" || status == "Tutup") {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sesi ini sudah ditutup")));
        setState(() => _loading = false);
        return;
      }

      if (sisa <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Slot sudah penuh")));
        setState(() => _loading = false);
        return;
      }

      bool isGenderMatch = false;
      if (slotGender == "Campur") {
        isGenderMatch = true;
      } else if (slotGender == "Laki-laki" && userGender == "L") {
        isGenderMatch = true;
      } else if (slotGender == "Perempuan" && userGender == "P") {
        isGenderMatch = true;
      }

      if (!isGenderMatch) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sesi ini khusus untuk gender yang berbeda")));
        setState(() => _loading = false);
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

      await userBookingRef.push().set({
        "user_id": user.uid,
        "user_name": userName,
        "gym_date": dateKey,
        "sesi": data["time"],
        "status": "Pending",
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
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Stack(
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
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [

                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _slotsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(color: Colors.white));
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Center(child: Text("Belum ada slot tersedia untuk 7 hari kedepan.", style: TextStyle(fontWeight: FontWeight.bold))),
                              );
                            }

                            final slots = snapshot.data!;
                            
                            // Group slots by date
                            Map<String, List<Map<String, dynamic>>> groupedSlots = {};
                            for (var slot in slots) {
                              final date = slot['date'] as String;
                              groupedSlots.putIfAbsent(date, () => []).add(slot);
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: const Text(
                                      "Slot Tersedia (Minggu Ini):",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                ...groupedSlots.entries.map((entry) {
                                  final dateStr = entry.key;
                                  final daySlots = entry.value;
                                  
                                  DateTime parsedDate = DateTime.tryParse(dateStr) ?? DateTime.now();
                                  String formattedDateStr = DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(parsedDate);
                                  
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8, bottom: 8, top: 8),
                                        child: Text(formattedDateStr, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                                      ),
                                      ...daySlots.map((slot) {
                                        final time = slot["time"] ?? "-";
                                        final gender = slot["gender"] ?? "Campur";
                                        final status = slot["status"] ?? "Buka";
                                        final kapasitas = int.tryParse("${slot["kapasitas"]}") ?? 0;
                                        final sisa = int.tryParse("${slot["remaining"]}") ?? kapasitas;
                                        final isSelected = _selectedSlot?['id'] == slot['id'];
                                        
                                        final bool isClosed = status == "Ditutup" || status == "Tutup";
                                        final bool isFull = sisa <= 0;
                                        final bool disabled = isClosed || isFull;

                                        return GestureDetector(
                                          onTap: () {
                                            if (!disabled) {
                                              setState(() {
                                                _selectedSlot = slot;
                                              });
                                            }
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 10),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: disabled ? Colors.grey[300] : (isSelected ? Colors.blueAccent : Colors.white),
                                              borderRadius: BorderRadius.circular(18),
                                              border: Border.all(color: isSelected ? Colors.blue : Colors.transparent, width: 2),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.access_time, color: disabled ? Colors.grey : (isSelected ? Colors.white : Colors.grey)),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(time, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: disabled ? Colors.grey[600] : (isSelected ? Colors.white : Colors.black))),
                                                      const SizedBox(height: 4),
                                                      Text("Gender: $gender", style: TextStyle(color: disabled ? Colors.grey[600] : (isSelected ? Colors.white70 : Colors.grey[700]), fontSize: 13)),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    if (isClosed)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)),
                                                        child: const Text("Ditutup", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                                      )
                                                    else ...[
                                                      Text("Kapasitas", style: TextStyle(fontSize: 12, color: disabled ? Colors.grey[600] : (isSelected ? Colors.white70 : Colors.grey))),
                                                      Text("$sisa/$kapasitas", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: disabled ? Colors.red : (isSelected ? Colors.white : Colors.green))),
                                                    ]
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                      const SizedBox(height: 10),
                                    ],
                                  );
                                }),
                              ],
                            );
                          },
                        ),

                        // Spacer supaya card terakhir tidak ketutup tombol fixed bawah
                        const SizedBox(height: 110),

                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: IconButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/dashboard'),
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.9),
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
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
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Reservasi',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

  }

  // Removed _cardItem and _pickDate as they are no longer needed
}