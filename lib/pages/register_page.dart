import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController namaDepanCtrl = TextEditingController();
  final TextEditingController namaBelakangCtrl = TextEditingController();
  final TextEditingController nimCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  @override
  void dispose() {
    namaDepanCtrl.dispose();
    namaBelakangCtrl.dispose();
    nimCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (emailCtrl.text.isEmpty ||
        passwordCtrl.text.isEmpty ||
        namaDepanCtrl.text.isEmpty ||
        nimCtrl.text.isEmpty) {
      _showMsg('Semua data wajib diisi');
      return;
    }

    if (passwordCtrl.text.length < 6) {
      _showMsg('Password minimal 6 karakter');
      return;
    }

    setState(() => isLoading = true);

    try {
      final userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
      );

      final uid = userCredential.user!.uid;

      await _db.child('users').child(uid).set({
        'nama':
            '${namaDepanCtrl.text.trim()} ${namaBelakangCtrl.text.trim()}',
        'email': emailCtrl.text.trim(),
        'nim': nimCtrl.text.trim(),
        'jk': '',
        'tanggal_lahir': '',
        'bb': '',
        'tb': '',
        'tujuan': '',
        'civitas': false,
        'profilLengkap': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed('/register-profile');
    } catch (e) {
      _showMsg('Register gagal: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double contentWidth =
        deviceWidth < 420 ? deviceWidth * 0.92 : 375.0;

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

          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: contentWidth,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(40),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Text(
                        'Halo',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Buat Akun',
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 28),

                      _InputField(
                        label: 'Nama Depan',
                        icon: Icons.person_outline,
                        controller: namaDepanCtrl,
                      ),
                      const SizedBox(height: 14),

                      _InputField(
                        label: 'Nama Belakang',
                        icon: Icons.person_outline,
                        controller: namaBelakangCtrl,
                      ),
                      const SizedBox(height: 14),

                      _InputField(
                        label: 'NIM',
                        icon: Icons.badge_outlined,
                        controller: nimCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),

                      _InputField(
                        label: 'Email',
                        icon: Icons.email_outlined,
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),

                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFEFEF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextField(
                          controller: passwordCtrl,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            icon: const Icon(Icons.lock_outline),
                            hintText: 'Password',
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              icon: Icon(obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(
                                  () => obscurePassword = !obscurePassword),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _register,
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('Daftar'),
                        ),
                      ),

                      const SizedBox(height: 18),

                      TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        child: const Text('Sudah punya akun? Masuk'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _InputField({
    required this.label,
    required this.icon,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          icon: Icon(icon),
          hintText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }
}