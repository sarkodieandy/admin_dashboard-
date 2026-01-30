import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../home/home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const routePath = '/welcome';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.x24),
              Text(
                AppStrings.appName,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: AppSpacing.x8),
              Text(
                '${AppStrings.restaurantName} • ${AppStrings.restaurantLocation}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.x24),
              Expanded(
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.x20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.welcomeHeadline,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x8),
                      Text(
                        AppStrings.welcomeSubhead,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.25,
                        ),
                      ),
                      const Spacer(),
                      AppButton(
                        label: AppStrings.browseMenu,
                        icon: Icons.restaurant_menu_rounded,
                        onPressed: () => context.go(HomeScreen.routePath),
                      ),
                      const SizedBox(height: AppSpacing.x12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.push(SignupScreen.routePath),
                              child: const Text(AppStrings.signUp),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.x12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.push(LoginScreen.routePath),
                              child: const Text(AppStrings.logIn),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x12),
                      TextButton(
                        onPressed: () async {
                          final auth = context.read<AuthProvider>();
                          try {
                            await auth.signInAnonymously();
                          } catch (error, stackTrace) {
                            AppLogger.e(
                              'welcome_guest_signin_failed',
                              tag: 'auth',
                              error: error,
                              stackTrace: stackTrace,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            }
                          }

                          if (context.mounted) context.go(HomeScreen.routePath);
                        },
                        child: const Text(AppStrings.browseAsGuest),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x12),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.x8),
                  Expanded(
                    child: Text(
                      AppStrings.serviceAreaBody,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x8),
            ],
          ),
        ),
      ),
    );
  }
}
