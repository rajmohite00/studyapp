import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_overlay.dart';
import '../app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authStateProvider.notifier).login(
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
                  // Back
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          size: 20, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Logo + title
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 20),
                  const Text('Welcome back',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  const Text('Sign in to continue your study journey',
                      style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4)),
                  const SizedBox(height: 36),

                  // Email
                  _Label('Email address'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDeco('you@example.com',
                        Icons.email_outlined),
                    validator: (v) => v == null || !v.contains('@')
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Password
                  _Label('Password'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                    decoration: _inputDeco('••••••••', Icons.lock_outlined,
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
                  const SizedBox(height: 8),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => context.push('/otp',
                          extra: _emailCtrl.text.trim()),
                      child: const Text('Forgot password?',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Sign in button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: state.isLoading ? null : _login,
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
                          : const Text('Sign In',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?",
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => context.pushReplacement('/signup'),
                        child: const Text('Sign up',
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

  InputDecoration _inputDeco(String hint, IconData icon,
      {Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: AppColors.textLight, fontSize: 14),
        prefixIcon:
            Icon(icon, size: 20, color: AppColors.textSecondary),
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
          borderSide: const BorderSide(
              color: Color(0xFFE53E3E), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
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
