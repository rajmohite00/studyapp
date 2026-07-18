import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_overlay.dart';
import '../app_theme.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authStateProvider.notifier).register(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
    if (!mounted) return;
    final s = ref.read(authStateProvider);
    if (s.isAuthenticated) context.go('/home');
    if (s.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(s.error!),
        backgroundColor: const Color(0xFFE53E3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authStateProvider);
    return LoadingOverlay(
      isLoading: state.isLoading,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F8),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.arrow_back_rounded,
                          size: 20, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 36),

                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.school_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 20),
                  const Text('Create account',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  const Text('Start your AI-powered study journey',
                      style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4)),
                  const SizedBox(height: 36),

                  _Label('Full name'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDeco('Your full name', Icons.person_outline_rounded),
                    validator: (v) => v == null || v.trim().length < 2
                        ? 'Enter your name'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  _Label('Email address'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDeco('you@example.com', Icons.email_outlined),
                    validator: (v) => v == null || !v.contains('@')
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  _Label('Password'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _signup(),
                    decoration: _inputDeco('Min 8 characters', Icons.lock_outlined,
                        suffix: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        )),
                    validator: (v) => v == null || v.length < 8
                        ? 'At least 8 characters'
                        : null,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                      'By signing up, you agree to our Terms & Privacy Policy.',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight)),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: state.isLoading ? null : _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Create Account',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account?',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => context.pushReplacement('/login'),
                        child: const Text('Log in',
                            style: TextStyle(
                                fontSize: 14,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon, {Widget? suffix}) =>
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
