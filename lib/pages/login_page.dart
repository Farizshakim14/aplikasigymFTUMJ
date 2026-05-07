import 'dart:convert';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard.dart';
import 'register_page.dart';
import 'register_profile_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool isLoading = false;
  bool isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  Future<void> _checkAutoLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseDatabase.instance.ref('users/${user.uid}').get();
    if (!mounted || !snap.exists) return;

    final data = Map<String, dynamic>.from(snap.value as Map);
    final lengkap = data['profilLengkap'] == true;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => lengkap ? const DashboardPage() : const RegisterProfilePage(),
      ),
      (route) => false,
    );
  }

  Future<void> _saveProfileToLocal(Map<String, dynamic> userData, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'data_profil',
      jsonEncode({
        'nama': userData['nama'] ?? user.displayName ?? 'User',
        'email': userData['email'] ?? user.email ?? '',
      }),
    );
  }

  Future<void> _routeAfterLogin(User user) async {
    final ref = FirebaseDatabase.instance.ref('users/${user.uid}');
    final snapshot = await ref.get();
    Map<String, dynamic> userData = {};

    if (!snapshot.exists) {
      userData = {
        'nama': user.displayName ?? 'User',
        'email': user.email ?? '',
        'phone': user.phoneNumber ?? '',
        'nim': '',
        'jk': '',
        'tanggal_lahir': '',
        'bb': '',
        'tb': '',
        'tujuan': '',
        'civitas': false,
        'profilLengkap': false,
        'createdAt': DateTime.now().toIso8601String(),
      };
      await ref.set(userData);
    } else {
      userData = Map<String, dynamic>.from(snapshot.value as Map);
      final updates = <String, dynamic>{};
      if ((userData['email'] ?? '').toString().isEmpty && user.email != null) {
        updates['email'] = user.email;
      }
      if ((userData['phone'] ?? '').toString().isEmpty && user.phoneNumber != null) {
        updates['phone'] = user.phoneNumber;
      }
      if ((userData['nama'] ?? '').toString().isEmpty && user.displayName != null) {
        updates['nama'] = user.displayName;
      }
      if (updates.isNotEmpty) {
        await ref.update(updates);
        userData.addAll(updates);
      }
    }

    await _saveProfileToLocal(userData, user);
    if (!mounted) return;
    final lengkap = userData['profilLengkap'] == true;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => lengkap ? const DashboardPage() : const RegisterProfilePage(),
      ),
      (route) => false,
    );
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  bool _isPhoneLikeInput(String value) {
    final cleaned = _normalizePhone(value);
    return RegExp(r'^\+?[0-9]{8,15}$').hasMatch(cleaned);
  }

  Set<String> _phoneVariants(String phone) {
    final cleaned = _normalizePhone(phone);
    if (cleaned.isEmpty) return {};

    final variants = <String>{cleaned};
    if (cleaned.startsWith('+62')) {
      variants.add('0${cleaned.substring(3)}');
      variants.add(cleaned.substring(1)); // 62xxxxxxxx
    } else if (cleaned.startsWith('62')) {
      variants.add('+$cleaned');
      variants.add('0${cleaned.substring(2)}');
    } else if (cleaned.startsWith('0')) {
      variants.add('+62${cleaned.substring(1)}');
      variants.add('62${cleaned.substring(1)}');
    }

    return variants;
  }

  String _toE164Indonesia(String phone) {
    final cleaned = _normalizePhone(phone);
    if (cleaned.startsWith('+')) return cleaned;
    if (cleaned.startsWith('62')) return '+$cleaned';
    if (cleaned.startsWith('0') && cleaned.length > 1) {
      return '+62${cleaned.substring(1)}';
    }
    return cleaned;
  }

  Future<String> _resolveEmailForLogin(String identity) async {
    final input = identity.trim();
    if (input.contains('@')) {
      return input;
    }

    if (!_isPhoneLikeInput(input)) {
      throw Exception('Format email/nomor telepon tidak valid');
    }

    final usersSnap = await FirebaseDatabase.instance.ref('users').get();
    if (!usersSnap.exists) {
      throw Exception('Data user tidak ditemukan');
    }

    final inputPhones = _phoneVariants(input);
    const phoneKeys = [
      'phone',
      'nohp',
      'no_hp',
      'nomor_hp',
      'nomor_telepon',
      'telepon',
      'whatsapp',
      'wa',
    ];

    for (final user in usersSnap.children) {
      final raw = user.value;
      if (raw is! Map) continue;
      final userData = Map<String, dynamic>.from(raw);

      final email = (userData['email'] ?? '').toString().trim();
      if (email.isEmpty) continue;

      for (final key in phoneKeys) {
        final value = (userData[key] ?? '').toString().trim();
        if (value.isEmpty) continue;

        final dbPhones = _phoneVariants(value);
        if (dbPhones.intersection(inputPhones).isNotEmpty) {
          return email;
        }
      }
    }

    throw Exception('Nomor telepon tidak terdaftar');
  }

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email/nomor telepon dan password tidak boleh kosong"),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final resolvedEmail = await _resolveEmailForLogin(emailController.text);
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: resolvedEmail,
        password: passwordController.text.trim(),
      );
      if (credential.user == null) throw Exception('User tidak ditemukan');
      await _routeAfterLogin(credential.user!);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Login gagal, cek email/nomor telepon dan password",
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => isLoading = true);
    try {
      UserCredential credential;
      if (kIsWeb) {
        credential = await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;
        final googleAuth = await googleUser.authentication;
        final authCredential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        credential = await FirebaseAuth.instance.signInWithCredential(authCredential);
      }

      if (credential.user == null) throw Exception('User Google tidak ditemukan');
      await _routeAfterLogin(credential.user!);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Google gagal")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loginWithPhone() async {
    phoneController.clear();
    otpController.clear();
    ConfirmationResult? confirmationResult;
    bool otpSent = false;
    bool otpLoading = false;
    String? verificationId;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> sendOtp() async {
              final rawPhone = phoneController.text.trim();
              if (!_isPhoneLikeInput(rawPhone)) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text("Format nomor telepon tidak valid")),
                );
                return;
              }

              setStateDialog(() => otpLoading = true);
              final phone = _toE164Indonesia(rawPhone);
              try {
                if (kIsWeb) {
                  confirmationResult = await FirebaseAuth.instance.signInWithPhoneNumber(phone);
                  setStateDialog(() => otpSent = true);
                } else {
                  await FirebaseAuth.instance.verifyPhoneNumber(
                    phoneNumber: phone,
                    verificationCompleted: (credential) async {
                      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                      setState(() => isLoading = true);
                      final userCredential =
                          await FirebaseAuth.instance.signInWithCredential(credential);
                      if (userCredential.user != null) {
                        await _routeAfterLogin(userCredential.user!);
                      }
                      if (mounted) setState(() => isLoading = false);
                    },
                    verificationFailed: (_) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text("Verifikasi nomor gagal")),
                      );
                    },
                    codeSent: (verId, _) {
                      verificationId = verId;
                      setStateDialog(() => otpSent = true);
                    },
                    codeAutoRetrievalTimeout: (_) {},
                  );
                }
              } catch (_) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text("Gagal mengirim OTP")),
                );
              } finally {
                setStateDialog(() => otpLoading = false);
              }
            }

            Future<void> verifyOtp() async {
              final code = otpController.text.trim();
              if (code.length < 6) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text("Kode OTP tidak valid")),
                );
                return;
              }

              setStateDialog(() => otpLoading = true);
              try {
                UserCredential userCredential;
                if (kIsWeb) {
                  if (confirmationResult == null) {
                    throw Exception('OTP belum dikirim');
                  }
                  userCredential = await confirmationResult!.confirm(code);
                } else {
                  if (verificationId == null) throw Exception('OTP belum dikirim');
                  final credential = PhoneAuthProvider.credential(
                    verificationId: verificationId!,
                    smsCode: code,
                  );
                  userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
                }

                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (userCredential.user == null) throw Exception('User tidak ditemukan');
                await _routeAfterLogin(userCredential.user!);
              } catch (_) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text("Verifikasi OTP gagal")),
                );
              } finally {
                if (dialogContext.mounted) {
                  setStateDialog(() => otpLoading = false);
                }
              }
            }

            return AlertDialog(
              title: const Text("Login Nomor Telepon"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Nomor Telepon",
                      hintText: "0812xxxx / +62812xxxx",
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (otpSent)
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Kode OTP",
                        hintText: "6 digit OTP",
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: otpLoading ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text("Batal"),
                ),
                TextButton(
                  onPressed: otpLoading ? null : (otpSent ? verifyOtp : sendOtp),
                  child: Text(otpSent ? "Verifikasi" : "Kirim OTP"),
                ),
              ],
            );
          },
        );
      },
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
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      const Text(
                        "Halo",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        "Selamat Datang Kembali",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 35),

                      // ================= EMAIL =================
                      Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            icon: Icon(Icons.alternate_email),
                            hintText: "Email / Nomor Telepon",
                            border: InputBorder.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ================= PASSWORD =================
                      Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: passwordController,
                          obscureText: !isPasswordVisible,
                          decoration: InputDecoration(
                            icon: const Icon(Icons.lock_outline),
                            hintText: "Password",
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          "Lupa kata sandi Anda?",
                          style: TextStyle(
                            color: Colors.white70,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),

                      const SizedBox(height: 60),

                      // ================= BUTTON =================
                      GestureDetector(
                        onTap: isLoading ? null : login,
                        child: Container(
                          height: 56,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF7AB9FF),
                                Color(0xFF7F7BFF),
                              ],
                            ),
                          ),
                          child: Center(
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.login, color: Colors.white),
                                      SizedBox(width: 6),
                                      Text(
                                        "Masuk",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    ],
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      Row(
                        children: const [
                          Expanded(child: Divider(color: Colors.white54)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              "Atau",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white54)),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isLoading ? null : _loginWithGoogle,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white70),
                                minimumSize: const Size.fromHeight(46),
                              ),
                              icon: const Icon(Icons.g_mobiledata, size: 26),
                              label: const Text("Google"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isLoading ? null : _loginWithPhone,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white70),
                                minimumSize: const Size.fromHeight(46),
                              ),
                              icon: const Icon(Icons.phone_android),
                              label: const Text("Nomor HP"),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Belum punya akun? ",
                            style: TextStyle(color: Colors.white),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterPage()),
                              );
                            },
                            child: const Text(
                              "Daftar",
                              style: TextStyle(
                                color: Colors.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
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