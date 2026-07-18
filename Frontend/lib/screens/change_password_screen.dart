import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../app_theme.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends ConsumerState<ChangePasswordScreen> {
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
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      await AuthService().changePassword(
        currentPassword: _currentCtrl.text.trim(),
        newPassword: _newCtrl.text.trim(),
      );
      setState(() {
        _success = true;
        _isLoading = false;
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) context.pop();
    } catch (e) {
      final msg = e.toString().contains('WRONG_PASSWORD')
          ? 'Current password is incorrect'
          : 'Something went wrong. Please try again.';
      setState(() {
        _errorMsg = msg;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Change Password',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('Update your password',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4)),
              const SizedBox(height: 6),
              const Text('Choose a strong password with at least 8 characters.',
                  style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4)),
              const SizedBox(height: 32),

              // Current password
              const _Label('Current password'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _currentCtrl,
                obscureText: _obscureCurrent,
                textInputAction: TextInputAction.next,
                decoration: _inputDeco('Enter current password',
                    Icons.lock_outline_rounded,
                    suffix: _EyeBtn(
                      obscure: _obscureCurrent,
                      onTap: () => setState(
                          () => _obscureCurrent = !_obscureCurrent),
                    )),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // New password
              const _Label('New password'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _newCtrl,
                obscureText: _obscureNew,
                textInputAction: TextInputAction.next,
                decoration: _inputDeco(
                    'Min 8 characters', Icons.lock_rounded,
                    suffix: _EyeBtn(
                      obscure: _obscureNew,
                      onTap: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    )),
                validator: (v) {
                  if (v == null || v.length < 8) {
                    return 'At least 8 characters';
                  }
                  if (v == _currentCtrl.text) {
                    return 'Must be different from current';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Confirm
              const _Label('Confirm new password'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: _inputDeco('Re-enter new password',
                    Icons.check_circle_outline_rounded,
                    suffix: _EyeBtn(
                      obscure: _obscureConfirm,
                      onTap: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                    )),
                validator: (v) =>
                    v != _newCtrl.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 24),

              // Error
              if (_errorMsg != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFE53E3E)
                            .withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Color(0xFFE53E3E), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(_errorMsg!,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFE53E3E)))),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              // Success
              if (_success) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF059669)
                            .withValues(alpha: 0.3)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.check_circle_rounded,
                        color: Color(0xFF059669), size: 18),
                    SizedBox(width: 10),
                    Text('Password changed successfully!',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF059669))),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              // Submit
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isLoading || _success) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          _success ? 'Password Updated ✓' : 'Update Password',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text('Use letters, numbers & symbols for a strong password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textLight)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon,
      {Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.textLight, fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF7F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8E8EE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8E8EE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE53E3E)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFE53E3E), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary));
}

class _EyeBtn extends StatelessWidget {
  final bool obscure;
  final VoidCallback onTap;
  const _EyeBtn({required this.obscure, required this.onTap});
  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(
          obscure
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          size: 20,
          color: AppColors.textSecondary,
        ),
        onPressed: onTap,
      );
}
