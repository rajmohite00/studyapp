import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/primary_button.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMsg;
  bool _success = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMsg = null; });

    try {
      await AuthService().changePassword(
        currentPassword: _currentCtrl.text.trim(),
        newPassword: _newCtrl.text.trim(),
      );
      setState(() { _success = true; _isLoading = false; });
      // Auto-pop after success
      await Future.delayed(const Duration(seconds: 1, milliseconds: 800));
      if (mounted) context.pop();
    } catch (e) {
      final msg = e.toString().contains('WRONG_PASSWORD')
          ? 'Current password is incorrect'
          : 'Something went wrong. Please try again.';
      setState(() { _errorMsg = msg; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Change Password',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header banner ────────────────────────────────────────────
              FadeSlideIn(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Keep it secure 🔒', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
                            const SizedBox(height: 3),
                            Text('Choose a strong password with 8+ characters', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white.withOpacity(0.85))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Form card ────────────────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current password
                      _FieldLabel(label: 'Current Password'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _currentCtrl,
                        obscureText: _obscureCurrent,
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500),
                        decoration: _fieldDecor(
                          hint: 'Enter current password',
                          icon: Icons.lock_outline_rounded,
                          suffix: _EyeButton(
                            obscure: _obscureCurrent,
                            onTap: () => setState(() => _obscureCurrent = !_obscureCurrent),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),

                      // New password
                      _FieldLabel(label: 'New Password'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _newCtrl,
                        obscureText: _obscureNew,
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500),
                        decoration: _fieldDecor(
                          hint: 'Min 8 characters',
                          icon: Icons.lock_rounded,
                          suffix: _EyeButton(
                            obscure: _obscureNew,
                            onTap: () => setState(() => _obscureNew = !_obscureNew),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.length < 8) return 'At least 8 characters';
                          if (v == _currentCtrl.text) return 'New password must be different';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Confirm password
                      _FieldLabel(label: 'Confirm New Password'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscureConfirm,
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500),
                        decoration: _fieldDecor(
                          hint: 'Re-enter new password',
                          icon: Icons.check_circle_outline_rounded,
                          suffix: _EyeButton(
                            obscure: _obscureConfirm,
                            onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (v) => v != _newCtrl.text ? 'Passwords do not match' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Error banner ─────────────────────────────────────────────
              if (_errorMsg != null)
                FadeSlideIn(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4F0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_errorMsg!, style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFFEF4444)))),
                    ]),
                  ),
                ),

              // ── Success banner ───────────────────────────────────────────
              if (_success)
                FadeSlideIn(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 18),
                      const SizedBox(width: 10),
                      Text('Password changed! ✅', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.accentGreen, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),

              const SizedBox(height: 28),

              // ── Submit button ────────────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 160),
                child: PrimaryButton(
                  text: _success ? 'Password Updated ✓' : 'Update Password',
                  isLoading: _isLoading,
                  onPressed: _success ? null : _submit,
                ),
              ),

              const SizedBox(height: 12),
              // Tip
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: Center(
                  child: Text(
                    '💡 Use a mix of letters, numbers & symbols',
                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textLight),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecor({required String hint, required IconData icon, Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: AppColors.textLight, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.background,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primary, width: 1.8)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444))),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8)),
      );
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
      );
}

class _EyeButton extends StatelessWidget {
  final bool obscure;
  final VoidCallback onTap;
  const _EyeButton({required this.obscure, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: AppColors.textSecondary),
        onPressed: onTap,
      );
}
