import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class RekomendasiAIPage extends StatefulWidget {
  const RekomendasiAIPage({super.key});

  @override
  State<RekomendasiAIPage> createState() => _RekomendasiAIPageState();
}

class _RekomendasiAIPageState extends State<RekomendasiAIPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nama = TextEditingController();
  final TextEditingController _usia = TextEditingController();
  final TextEditingController _bb = TextEditingController();
  final TextEditingController _tb = TextEditingController();

  String _jk = "L";
  String _tujuan = "bulking";

  String? _hasilGizi;
  String? _hasilProgram;

  double? _bmi;
  String _bmiStatus = "";
  Color _bmiColor = Colors.grey;

  bool _loading = false;

  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _loadDataFromFirebase();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _loadDataFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final ref = FirebaseDatabase.instance.ref('users/${user.uid}');
      final snapshot = await ref.get();

      if (!snapshot.exists) return;

      final data = Map<String, dynamic>.from(snapshot.value as Map);

      setState(() {
        _nama.text = data['nama'] ?? '';
        _usia.text = (data['usia'] ?? '').toString();
        _bb.text = (data['bb'] ?? '').toString();
        _tb.text = (data['tb'] ?? '').toString();
        _jk = data['jk'] ?? 'L';

        final validOptions = ["bulking", "cutting", "maintain"];
        _tujuan = validOptions.contains(data["tujuan"])
            ? data["tujuan"]
            : "bulking";
      });
    } catch (e) {
      debugPrint("Gagal ambil data: $e");
    }
  }

Future<List<dynamic>> loadDataset() async {
  String jsonString =
      await rootBundle.loadString('assets/dataset.json');
  return json.decode(jsonString);
}

  Future<void> _prosesAI() async {
    final nama = _nama.text;
    final usia = int.tryParse(_usia.text) ?? 0;
    final bb = double.tryParse(_bb.text) ?? 0;
    final tb = double.tryParse(_tb.text) ?? 0;

    if (nama.isEmpty || usia == 0 || bb == 0 || tb == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Isi semua data dulu")));
      return;
    }

   setState(() => _loading = true);

await Future.delayed(const Duration(seconds: 2));

final bmiVal = bb / ((tb / 100) * (tb / 100));
_setBMIResult(bmiVal);

final gizi = hitungGizi(bb, tb, _jk, _tujuan);

final dataset = await loadDataset();

int goalUser =
    _tujuan == "bulking" ? 2 :
    _tujuan == "cutting" ? 1 : 3;

var hasilData = dataset
    .where((item) => item['Goal'] == goalUser)
    .toList();

var aktivitas = hasilData.isNotEmpty
    ? "Durasi Workout: ${hasilData[0]['Workout']} menit"
    : "Program tidak ditemukan";
    
final user = FirebaseAuth.instance.currentUser;
if (user != null) {
  final ref =
      FirebaseDatabase.instance.ref("history/${user.uid}").push();
  await ref.set({
    "nama": nama,
    "bb": bb,
    "tb": tb,
    "usia": usia,
    "tujuan": _tujuan,
    "bmi": bmiVal,
    "tanggal": DateTime.now().toString()
  });
}

setState(() {
  _hasilGizi = """
Kalori: ${gizi["Kalori"]!.toStringAsFixed(0)} kkal
Protein: ${gizi["Protein"]!.toStringAsFixed(1)} g
Karbohidrat: ${gizi["Karbohidrat"]!.toStringAsFixed(1)} g
Lemak: ${gizi["Lemak"]!.toStringAsFixed(1)} g
Serat: ${gizi["Serat"]!.toStringAsFixed(1)} g
""";

    _hasilProgram = aktivitas.toString(); // 🔥 penting pakai toString()
    _loading = false;
    _anim.forward(from: 0);
  });
  }

  void _setBMIResult(double bmi) {
    _bmi = bmi;
    if (bmi < 18.5) {
      _bmiStatus = "Kurus";
      _bmiColor = Colors.blue;
    } else if (bmi < 25) {
      _bmiStatus = "Normal";
      _bmiColor = Colors.green;
    } else if (bmi < 30) {
      _bmiStatus = "Overweight";
      _bmiColor = Colors.orange;
    } else {
      _bmiStatus = "Obesitas";
      _bmiColor = Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: .3,
        title: const Text(
          "Rekomendasi Nutrisi dan Aktivitas",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, "/dashboard");
          },
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
              color: Colors.black.withValues(alpha:.35),
            ),
          ),

          /// BLUR EFFECT
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.transparent),
            ),
          ),

          /// CONTENT
          SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        "Masukkan Data Diri Kamu 🧠",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 16),

                      _field("Nama", _nama),
                      _field("Usia", _usia, number: true),
                      _field("Berat Badan (kg)", _bb, number: true),
                      _field("Tinggi Badan (cm)", _tb, number: true),

                      const SizedBox(height: 8),

                      const Text("Jenis Kelamin",
                          style: TextStyle(fontWeight: FontWeight.bold)),

                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                              value: "L",
                              label: Text("Laki-laki"),
                              icon: Icon(Icons.male)),
                          ButtonSegment(
                              value: "P",
                              label: Text("Perempuan"),
                              icon: Icon(Icons.female)),
                        ],
                        selected: {_jk},
                        onSelectionChanged: (value) =>
                            setState(() => _jk = value.first),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Tujuan",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      DropdownButtonFormField(
                        initialValue: _tujuan,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: "bulking",
                              child: Text("Bulking / Naik Massa Otot")),
                          DropdownMenuItem(
                              value: "cutting",
                              child: Text("Cutting / Turun Lemak")),
                          DropdownMenuItem(
                              value: "maintain",
                              child: Text(
                                  "Maintain / Menjaga Berat Badan")),
                        ],
                        onChanged: (v) => setState(() => _tujuan = v!),
                      ),

                      const SizedBox(height: 10),

                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _prosesAI,
                          icon: const Icon(Icons.auto_awesome),
                          label: Text(_loading
                              ? "Memproses..."
                              : "Dapatkan Rekomendasi"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF92A3FD),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child:
                        CircularProgressIndicator(color: Colors.white),
                  ),

                if (_bmi != null) ...[
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _anim,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 40 * (1 - _anim.value)),
                        child: Opacity(
                          opacity: _anim.value,
                          child: child,
                        ),
                      );
                    },
                    child: _resultCard(
                      "BMI Result",
                      "BMI: ${_bmi!.toStringAsFixed(1)}\nStatus: $_bmiStatus",
                      Icons.health_and_safety,
                      color: _bmiColor,
                    ),
                  ),
                ],

                if (_hasilGizi != null)
                  _resultCard("Asupan Gizi", _hasilGizi!, Icons.fastfood),

                if (_hasilProgram != null)
                  _resultCard(
                      "Program Gym", _hasilProgram!, Icons.fitness_center),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(String title, String text, IconData icon,
      {Color color = Colors.deepPurple}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha:.2),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              )
            ]),
            const SizedBox(height: 8),
            Text(text, style: const TextStyle(fontSize: 16)),
          ]),
    );
  }

  Widget _field(String label, TextEditingController c,
      {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          label: Text(label),
          filled: true,
          fillColor: Colors.grey.shade200,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}

/// ================= LOGIKA =================
double prediksiKalori(
  double bb,
  double tb,
  String jk,
  String tujuan,
) {
  double bmi = bb / ((tb / 100) * (tb / 100));
  int gender = jk == "L" ? 1 : 0;

  if (bb <= 110.5) {
    if (bb <= 87.5) {
      if (tb <= 172.5) {
        if (bb <= 73) {
          return gender == 0 ? 1726 : 1883;
        } else {
          return bmi <= 42.7 ? 2110 : 2445;
        }
      } else {
        return gender == 0 ? 2217 : 2549;
      }
    } else {
      return gender == 0 ? 2500 : 2850;
    }
  } else {
    return gender == 0 ? 3400 : 3900;
  }
}

Map<String, double> hitungGizi(
  double bb,
  double tb,
  String jk,
  String tujuan,
) {
  double kalori = prediksiKalori(bb, tb, jk, tujuan);

  double protein =
      tujuan == "cutting"
          ? bb * 2.2
          : tujuan == "bulking"
              ? bb * 2.0
              : bb * 1.8;

  double lemak =
      tujuan == "cutting"
          ? bb * 0.8
          : tujuan == "bulking"
              ? bb * 1.0
              : bb * 0.9;

  double sisa = kalori - ((protein * 4) + (lemak * 9));
  double karbo = sisa / 4;

  return {
    "Kalori": kalori,
    "Protein": protein,
    "Karbohidrat": karbo,
    "Lemak": lemak,
    "Serat": 25,
  };
}

String rekomendasiGym(String tujuan, String jk) {
  if (tujuan == "cutting") {
    return "Aktivitas 60 menit/hari\nCardio + HIIT";
  } else if (tujuan == "bulking") {
    return "Aktivitas 45 menit/hari\nWeight Training";
  }

  return "Aktivitas 30 menit/hari\nFull Body Workout";
}