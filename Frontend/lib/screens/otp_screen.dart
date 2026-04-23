import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_theme.dart';
import '../widgets/primary_button.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded)),
              const SizedBox(height: 24),
              const Text('Check your email 📬', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Enter the OTP sent to ${widget.email}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 36),
              TextFormField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(labelText: '6-digit OTP', prefixIcon: Icon(Icons.pin_outlined)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock_outline_rounded)),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Reset Password',
                isLoading: _loading,
                onPressed: () async {
                  setState(() => _loading = true);
                  await Future.delayed(const Duration(seconds: 1));
                  setState(() => _loading = false);
                  if (mounted) context.go('/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
