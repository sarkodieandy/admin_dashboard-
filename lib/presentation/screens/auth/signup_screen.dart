import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../home/home_screen.dart';
import '../profile/profile_setup_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  static const routePath = '/auth/signup';

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();

    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await auth.signUp(
            email: email,
            password: password,
            name: name.isEmpty ? null : name,
          );

      if (!mounted) return;

      if (!auth.isSignedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check your email to verify, then log in.')),
        );
        context.pop();
        return;
      }

      await profileProvider.refresh();

      if (!mounted) return;
      context.go(profileProvider.isComplete ? HomeScreen.routePath : ProfileSetupScreen.routePath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.signUp)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x16),
          child: Column(
            children: [
              AppTextField(controller: _name, label: AppStrings.name),
              const SizedBox(height: AppSpacing.x12),
              AppTextField(
                controller: _email,
                label: AppStrings.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.x12),
              AppTextField(
                controller: _password,
                label: AppStrings.password,
                obscureText: true,
              ),
              const SizedBox(height: AppSpacing.x16),
              AppButton(
                label: AppStrings.continueText,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
