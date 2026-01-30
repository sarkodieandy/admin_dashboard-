import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';

class SupabaseSetupScreen extends StatelessWidget {
  const SupabaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.supabaseMissingTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.supabaseMissingBody,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.25),
              ),
              const SizedBox(height: AppSpacing.x16),
              const AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Run with:'),
                    SizedBox(height: 10),
                    SelectableText(
                      'flutter run \\\n'
                      '  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \\\n'
                      '  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.x16),
              Text(
                'Also apply the SQL migrations in `supabase/migrations/` to your Supabase project.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

