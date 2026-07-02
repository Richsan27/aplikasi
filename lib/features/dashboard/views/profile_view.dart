import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';

const String googleProfileSvg = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="12" fill="#E5E7EB"/>
  <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z" fill="#9CA3AF"/>
</svg>
''';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  Widget buildProfileInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isCompact = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 15,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? const Color(0xFF1E1E24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFE5E7EB).withOpacity(.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final email = user?.email ?? '-';
    final defaultName = email.split('@').first.toUpperCase();
    final displayName = user?.displayName ?? defaultName;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 10),

          // ================= HEADER =================
          buildCard(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      color: const Color(0xFF6B7280),
                      onPressed: () {
                        _showEditProfileDialog(context, user, displayName);
                      },
                    ),
                  ),
                ),

                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 105,
                      height: 105,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFDBA31),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFDBA31).withOpacity(.18),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: SvgPicture.string(
                          googleProfileSvg,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDBA31),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1E24),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDBA31).withOpacity(.12),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Text(
                    "Kasir Utama",
                    style: TextStyle(
                      color: Color(0xFFFFA000),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ================= INFO =================
          buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Informasi Akun",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1E24),
                  ),
                ),

                const SizedBox(height: 18),

                buildProfileInfoRow(
                  icon: Icons.storefront_rounded,
                  label: "Nama Toko",
                  value: "Photocopy Porina",
                ),

                const Divider(
                  height: 28,
                  thickness: 1,
                  color: Color(0xFFF3F4F6),
                ),

                buildProfileInfoRow(
                  icon: Icons.badge_outlined,
                  label: "UID Pengguna",
                  value: user?.uid ?? '-',
                  isCompact: true,
                ),

                const Divider(
                  height: 28,
                  thickness: 1,
                  color: Color(0xFFF3F4F6),
                ),

                buildProfileInfoRow(
                  icon: Icons.verified_user_outlined,
                  label: "Status Akun",
                  value: "Aktif",
                  valueColor: const Color(0xFF15803D),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ================= LOGOUT =================
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  final prefs =
                      await SharedPreferences.getInstance();

                  await prefs.setBool(
                    'just_logged_out',
                    true,
                  );

                  await FirebaseAuth.instance.signOut();

                  if (context.mounted) {
                    Navigator.pushReplacementNamed(
                      context,
                      '/login',
                    );
                  }
                },
                child: Ink(
                  padding:
                      const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFFECDD3),
                      width: 1.5,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFE11D48),
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Keluar dari Akun",
                        style: TextStyle(
                          color: Color(0xFFE11D48),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, User? user, String currentName) {
    final nameController = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Dialog Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Edit Profil",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E1E24),
                              ),
                            ),
                            IconButton(
                              onPressed: isLoading ? null : () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                              color: const Color(0xFF6B7280),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Avatar container with Google SVG
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFDBA31),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFDBA31).withOpacity(.18),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: SvgPicture.string(
                                  googleProfileSvg,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDBA31),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Display name text field
                        TextFormField(
                          controller: nameController,
                          enabled: !isLoading,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E24),
                          ),
                          decoration: InputDecoration(
                            labelText: "Nama Lengkap",
                            labelStyle: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w600,
                            ),
                            floatingLabelStyle: const TextStyle(
                              color: Color(0xFFFFA000),
                              fontWeight: FontWeight.bold,
                            ),
                            hintText: "Masukkan nama lengkap",
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                              color: Color(0xFF6B7280),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFFFA000), width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF7F8FA),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Nama tidak boleh kosong";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isLoading ? null : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                                ),
                                child: const Text(
                                  "Batal",
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                        if (formKey.currentState!.validate()) {
                                          setDialogState(() {
                                            isLoading = true;
                                          });

                                          try {
                                            await user?.updateDisplayName(nameController.text.trim());
                                            
                                            // Refresh internal state of ProfileView
                                            setState(() {});

                                            if (context.mounted) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: const Row(
                                                    children: [
                                                      Icon(Icons.check_circle_rounded, color: Colors.white),
                                                      SizedBox(width: 10),
                                                      Text(
                                                        "Profil berhasil diperbarui",
                                                        style: TextStyle(fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor: const Color(0xFF15803D),
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            setDialogState(() {
                                              isLoading = false;
                                            });
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    "Gagal memperbarui profil: $e",
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                  backgroundColor: const Color(0xFFE11D48),
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFDBA31),
                                  foregroundColor: const Color(0xFF1E1E24),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Color(0xFF1E1E24),
                                        ),
                                      )
                                    : const Text(
                                        "Simpan",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}