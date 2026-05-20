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

// ==========================================
// TAHAP 1: PERHITUNGAN BMI & KLASIFIKASI
// ==========================================
// Menghitung Body Mass Index (BMI) berdasarkan rumus standar internasional (kg/m2).
final bmiVal = bb / ((tb / 100) * (tb / 100));
_setBMIResult(bmiVal);

// ==========================================
// TAHAP 2: KALKULASI GIZI PRESISI (RUMUS)
// ==========================================
// Memanggil fungsi hitungGizi() untuk mendapatkan angka pasti gram protein, karbohidrat, dan lemak 
// sesuai dengan berat badan dan tujuan spesifik (bulking/cutting/maintain).
final gizi = hitungGizi(bb, tb, _jk, _tujuan);

// ==========================================
// TAHAP 3: MATCHING JADWAL & MENU DIET (AI DATASET GYM.json)
// ==========================================
// Memuat dataset GYM.json yang berisi knowledge-base aturan gaya hidup.
String gymDatasetStr = await rootBundle.loadString('assets/GYM.json');
List<dynamic> gymDataset = json.decode(gymDatasetStr);

// Mengklasifikasikan BMI angka menjadi teks bahasa Inggris agar cocok dengan struktur kolom dataset.
String engBmiCategory;
if (bmiVal < 18.5) engBmiCategory = "Underweight";
else if (bmiVal < 25) engBmiCategory = "Normal weight";
else if (bmiVal < 30) engBmiCategory = "Overweight";
else engBmiCategory = "Obesity";

// Konversi bahasa untuk Jenis Kelamin agar sama dengan format dataset GYM.json.
String engGender = _jk == "L" ? "Male" : "Female";

// Melakukan 'Exact Match Filtering': Mencari data yang persis dengan 3 parameter utama User.
var matchedGym = gymDataset.firstWhere(
  (item) => item["Gender"] == engGender && 
            item["Goal"] == _tujuan && 
            item["BMI Category"] == engBmiCategory,
  orElse: () => null
);

// Jika ditemukan, ambil rekomendasi menu dan jadwal latihannya.
String mealRec = matchedGym != null ? matchedGym["Meal Plan"] : "Gunakan menu gizi berimbang.";
String exerciseRec = matchedGym != null ? matchedGym["Exercise Schedule"] : "Lakukan olahraga ringan 30 menit sehari.";

// ==========================================
// TAHAP 4: PREDIKSI KALORI TERBAKAR (AI DATASET EXERCISE TRACKING)
// ==========================================
// Memuat dataset histori latihan member gym.
String trackingDatasetStr = await rootBundle.loadString('assets/gym_members_exercise_tracking.json');
List<dynamic> trackingDataset = json.decode(trackingDatasetStr);

double closestDiff = double.infinity;
double predictedCalories = 0.0;

// Logika Nearest Neighbor (Pencarian Jarak Terdekat):
// Sistem akan melakukan perulangan ke seluruh profil latihan di dataset.
// Ia mencari data orang dengan Jenis Kelamin yang sama, dan mencari yang nilai BMI-nya paling mirip (selisih / diff terkecil).
for (var item in trackingDataset) {
  if (item["Gender"] == engGender) {
    double itemBmi = (item["BMI"] ?? 0).toDouble();
    double diff = (itemBmi - bmiVal).abs(); // Mencari selisih (nilai mutlak)
    if (diff < closestDiff) {
      closestDiff = diff;
      predictedCalories = (item["Calories_Burned"] ?? 0).toDouble(); // Mengambil jumlah kalori yang terbakar dari profil mirip tersebut.
    }
  }
}
if (predictedCalories == 0.0) predictedCalories = 500.0; // Fallback default jika tidak ada data

// ==========================================
// TAHAP 5: PENYIMPANAN RIWAYAT (FIREBASE)
// ==========================================
// Menyimpan hasil rekomendasi dan profil fisik user saat ini ke database Firebase sebagai histori riwayat.
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

// ==========================================
// TAHAP 6: UPDATE TAMPILAN ANTARMUKA (UI)
// ==========================================
// Menggabungkan Output dari Algoritma Rumus (gizi presisi angka) dengan Output dari Dataset AI (kalimat teks).
setState(() {
  _hasilGizi = """
Target Kalori Harian: ${gizi["Kalori"]!.toStringAsFixed(0)} kkal
Protein: ${gizi["Protein"]!.toStringAsFixed(1)} g
Karbohidrat: ${gizi["Karbohidrat"]!.toStringAsFixed(1)} g
Lemak: ${gizi["Lemak"]!.toStringAsFixed(1)} g

🍽️ Rekomendasi Menu:
$mealRec
""";

    _hasilProgram = """
🔥 Prediksi Kalori Terbakar: ${predictedCalories.toStringAsFixed(0)} kkal/sesi

🏋️‍♂️ Latihan:
$exerciseRec
""";
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Rekomendasi",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
          SafeArea(
            child: SingleChildScrollView(
              // SafeArea mencegah konten ketumpuk dengan AppBar.
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
// ==============================================================================
// METODE AI: DECISION TREE REGRESSION (POHON KEPUTUSAN)
// ==============================================================================
// Fungsi prediksiKalori() ini BUKAN menggunakan rumus matematis linier (seperti BMR biasa), 
// melainkan merupakan hasil ekstraksi aturan (Rule-Extraction) dari model Machine Learning 
// Decision Tree Regression yang telah ditraining sebelumnya. 
// Algoritma Decision Tree memecah data berdasarkan fitur yang memberikan Information Gain 
// tertinggi atau meminimalkan Error. Angka-angka desimal (110.5, 87.5, 172.5) adalah 
// "Split Points" (Titik Potong) atau Thresholds optimal yang ditemukan oleh model saat training.
// ==============================================================================
double prediksiKalori(
  double bb,
  double tb,
  String jk,
  String tujuan,
) {
  double bmi = bb / ((tb / 100) * (tb / 100));
  int gender = jk == "L" ? 1 : 0; // Fitur Encoding (Label Encoding) untuk jenis kelamin
  double kaloriDasar = 0;

  // Root Node (Cabang Utama): Pemisahan fitur dengan Information Gain terbesar (Berat Badan ekstrem vs non-ekstrem)
  if (bb <= 110.5) {
    // Node Kedalaman 1 (Depth 1): Pemisahan individu berat badan normal/overweight dengan obesitas tinggi
    if (bb <= 87.5) {
      // Node Kedalaman 2 (Depth 2): Pemisahan berdasarkan Tinggi Badan (faktor massa tulang dan otot)
      if (tb <= 172.5) {
        // Node Kedalaman 3 (Depth 3): Threshold berat badan untuk orang yang relatif pendek/sedang
        if (bb <= 73) {
          // Leaf Node (Daun / Keputusan Akhir): Target Prediksi Kalori (1726 untuk wanita, 1883 pria)
          kaloriDasar = gender == 0 ? 1726 : 1883;
        } else {
          // Leaf Node: Menggunakan fitur turunan (BMI) sebagai threshold pemisah akhir
          kaloriDasar = bmi <= 42.7 ? 2110 : 2445;
        }
      } else {
        // Leaf Node: Prediksi target kalori untuk orang yang tinggi (> 172.5) tapi berat <= 87.5
        kaloriDasar = gender == 0 ? 2217 : 2549;
      }
    } else {
      // Leaf Node: Prediksi target kalori untuk kelas berat badan di atas 87.5 namun di bawah 110.5
      kaloriDasar = gender == 0 ? 2500 : 2850;
    }
  } else {
    // Leaf Node dari Root (Extreme Outlier): Prediksi kalori untuk berat badan sangat ekstrem (> 110.5)
    kaloriDasar = gender == 0 ? 3400 : 3900;
  }

  // Post-Processing Output AI:
  // Menyesuaikan target kalori prediksi model terhadap tujuan/goal akhir pengguna
  if (tujuan == "bulking") {
    kaloriDasar += 400; // Surplus kalori harian untuk program hipertrofi otot
  } else if (tujuan == "cutting") {
    kaloriDasar -= 400; // Defisit kalori harian untuk program fat loss
  }
  
  return kaloriDasar;
}

// Fungsi hitungGizi() bertujuan mengubah jumlah Target Kalori menjadi kebutuhan Makronutrien dalam satuan Gram.
// Logikanya mengacu pada prinsip diet dan kebugaran:
// 1. Protein dan Lemak disesuaikan dengan pengali berat badan (rasio berbeda untuk cutting/bulking).
// 2. 1 gram Protein = 4 kalori, 1 gram Lemak = 9 kalori.
// 3. Sisa kalori yang belum terpenuhi kemudian dialokasikan sepenuhnya untuk Karbohidrat (1 gram Karbo = 4 kalori).
Map<String, double> hitungGizi(
  double bb,
  double tb,
  String jk,
  String tujuan,
) {
  double kalori = prediksiKalori(bb, tb, jk, tujuan); // Mengambil nilai kalori dari fungsi di atas

  // Perhitungan rasio protein (Gram Protein per Kg Berat Badan)
  // Cutting butuh protein lebih banyak (2.2g) untuk menjaga otot tidak menyusut saat defisit kalori.
  double protein =
      tujuan == "cutting"
          ? bb * 2.2
          : tujuan == "bulking"
              ? bb * 2.0
              : bb * 1.8;

  // Perhitungan rasio lemak 
  double lemak =
      tujuan == "cutting"
          ? bb * 0.8
          : tujuan == "bulking"
              ? bb * 1.0
              : bb * 0.9;

  // Sisa kalori setelah dikurangi kalori dari protein & lemak, dijadikan karbohidrat
  double sisa = kalori - ((protein * 4) + (lemak * 9));
  double karbo = sisa / 4;

  return {
    "Kalori": kalori,
    "Protein": protein,
    "Karbohidrat": karbo,
    "Lemak": lemak,
    "Serat": 25, // Nilai default kebutuhan serat harian
  };
}

