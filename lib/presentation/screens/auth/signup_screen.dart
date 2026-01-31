import 'dart:ui';

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
  static const _bgUrl =
      'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?auto=format&fit=crop&w=1400&q=70';
  static const _chefGifUrl = 'https://media.giphy.com/media/3o7TKMt1VVNkHV2PaE/giphy.gif';

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
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(AppStrings.signUp),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _bgUrl,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(color: theme.colorScheme.surfaceContainerHighest);
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.surfaceContainerHighest,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              );
            },
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.62),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.x16),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.94, end: 1),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, child) => Transform.scale(scale: v, child: child),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.x16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(alpha: 0.78),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 30,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Create your account',
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.x6),
                                        Text(
                                          'Sign up to save addresses, track orders, and chat with the restaurant.',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            height: 1.25,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Opacity(
                                      opacity: 0.88,
                                      child: Image.network(
                                        _chefGifUrl,
                                        height: 74,
                                        width: 74,
                                        fit: BoxFit.cover,
                                        filterQuality: FilterQuality.medium,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.x16),
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
                              const SizedBox(height: AppSpacing.x12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account?',
                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                  TextButton(
                                    onPressed: _isLoading ? null : () => context.pop(),
                                    child: const Text('Log in'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
