import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool rememberMe = false;
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final justLoggedOut = prefs.getBool('just_logged_out') ?? false;
    setState(() {
      rememberMe = prefs.getBool('remember_me') ?? false;
      if (rememberMe) {
        emailController.text = prefs.getString('email') ?? '';
        passwordController.text = prefs.getString('password') ?? '';
        
        if (!justLoggedOut && emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
          login();
        }
      }
    });
    if (justLoggedOut) {
      await prefs.setBool('just_logged_out', false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final prefs = await SharedPreferences.getInstance();
      if (rememberMe) {
        await prefs.setBool('remember_me', true);
        await prefs.setString('email', emailController.text.trim());
        await prefs.setString('password', passwordController.text.trim());
      } else {
        await prefs.setBool('remember_me', false);
        await prefs.remove('email');
        await prefs.remove('password');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login berhasil")),
        );

        // 🔥 PINDAH KE DASHBOARD
        Navigator.pushReplacementNamed(context, '/dashboard');
      }

    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Login gagal")),
        );
      }
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // Beautiful Modern Logo Stack
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDBA31).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDBA31).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFDBA31),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x3DFDBA31),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.print_rounded,
                        size: 36,
                        color: Color(0xFF1E1E24),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 28),
                
                // App Title & Tagline
                const Text(
                  "PORINA POS",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E1E24),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Sistem Kasir & Manajemen Toko Modern",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 36),
                
                // Form Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Masuk Akun",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E24),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Email Field
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF6B7280)),
                          hintText: "Email Kasir",
                          filled: true,
                          fillColor: const Color(0xFFF7F8FA),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFFDBA31), width: 1.5),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Password Field
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF6B7280)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF6B7280),
                            ),
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                          hintText: "Password",
                          filled: true,
                          fillColor: const Color(0xFFF7F8FA),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFFDBA31), width: 1.5),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),

                      // Remember Me Checkbox Row
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: rememberMe,
                              activeColor: const Color(0xFFFDBA31),
                              checkColor: const Color(0xFF1E1E24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  rememberMe = val ?? false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Ingat Saya",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4B5563),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Modern Action Button (Get Started Style)
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFDBA31),
                            foregroundColor: const Color(0xFF1E1E24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 0,
                          ),
                          onPressed: isLoading ? null : login,
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF1E1E24),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(width: 24),
                                    Text(
                                      "Masuk Sekarang",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_rounded),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Footer
                const Text(
                  "© 2026 Photocopy Porina. All Rights Reserved.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}