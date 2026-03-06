import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'tujuanbulking.dart';

class RegisterProfilePage extends StatefulWidget {
  const RegisterProfilePage({super.key});

  @override
  State<RegisterProfilePage> createState() => _RegisterProfilePageState();
}

class _RegisterProfilePageState extends State<RegisterProfilePage> {
  String? selectedGender;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  @override
  void dispose() {
    _dateController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      selectedGender != null &&
      _dateController.text.isNotEmpty &&
      _weightController.text.isNotEmpty &&
      _heightController.text.isNotEmpty;

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dateController.text =
            "${picked.year.toString().padLeft(4, '0')}-"
            "${picked.month.toString().padLeft(2, '0')}-"
            "${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  /// ================= SIMPAN PROFIL =================
  Future<void> _simpanProfil() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final navigator = Navigator.of(context);

    await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(user.uid)
        .update({
      'jk': selectedGender == 'Laki-laki' ? 'L' : 'P',
      'tanggal_lahir': _dateController.text.trim(),
      'bb': _weightController.text.trim(),
      'tb': _heightController.text.trim(),
      'profilLengkap': true,
    });

    if (!mounted) return;

    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const TujuanBulkingPage()),
    );
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
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.asset(
                          "assets/registerprofile.png",
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "Mari lengkapi profil Anda.",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Hal ini akan membantu kami untuk lebih mengenal Anda!",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        _dropdownGender(),
                        const SizedBox(height: 14),

                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: _inputField(
                              controller: _dateController,
                              icon: Icons.calendar_today_outlined,
                              label: "Tanggal Lahir",
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        _inputKgCmField(
                          controller: _weightController,
                          icon: Icons.monitor_weight_outlined,
                          label: "Berat Badan Anda",
                          unit: "KG",
                        ),
                        const SizedBox(height: 14),

                        _inputKgCmField(
                          controller: _heightController,
                          icon: Icons.height,
                          label: "Tinggi Badan Anda",
                          unit: "CM",
                        ),
                        const SizedBox(height: 32),

                        _buttonNext(),
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

  // ===================== DROPDOWN =====================
  Widget _dropdownGender() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _fieldDecoration(),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              selectedGender ?? "Pilih Jenis Kelamin",
              style: TextStyle(
                color: selectedGender == null
                    ? Colors.black45
                    : Colors.black,
                fontSize: 14,
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedGender,
              items: const [
                DropdownMenuItem(
                    value: "Laki-laki", child: Text("Laki-laki")),
                DropdownMenuItem(
                    value: "Perempuan", child: Text("Perempuan")),
              ],
              onChanged: (value) =>
                  setState(() => selectedGender = value),
            ),
          )
        ],
      ),
    );
  }

  // ===================== INPUT =====================
  Widget _inputField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
  }) {
    return Container(
      height: 48,
      decoration: _fieldDecoration(),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 18),
          hintText: label,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _inputKgCmField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String unit,
  }) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: _fieldDecoration(),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, size: 18),
                hintText: label,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 48,
          width: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFFFAC0FF), Color(0xFFB75CFF)],
            ),
          ),
          child: Text(
            unit,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ===================== BUTTON =====================
  Widget _buttonNext() {
    return InkWell(
      onTap: _isFormValid ? _simpanProfil : null,
      borderRadius: BorderRadius.circular(40),
      child: Opacity(
        opacity: _isFormValid ? 1 : 0.4,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF92A3FD), Color(0xFF9DCEFF)],
            ),
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Text(
            "Berikutnya ➤",
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _fieldDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}