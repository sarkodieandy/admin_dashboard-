import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/profile_provider.dart';
import '../auth/login_screen.dart';
import '../checkout/address_edit_screen.dart';
import '../profile/profile_setup_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  static const routePath = '/app/account';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final addresses = context.watch<AddressProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.account)),
      body: SafeArea(
        child: auth.isSignedIn
            ? ListView(
                padding: const EdgeInsets.all(AppSpacing.x16),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                (profileProvider.profile?.name ?? (auth.isGuest ? 'Guest' : '')),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            if (auth.isGuest)
                              Chip(
                                label: const Text('Guest'),
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.x8),
                        Text(
                          profileProvider.profile?.phone ?? 'Add your phone number for delivery updates.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.25,
                          ),
                        ),
                        if ((profileProvider.profile?.defaultDeliveryNote ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.x8),
                          Text(
                            profileProvider.profile!.defaultDeliveryNote!,
                            style: theme.textTheme.bodyMedium?.copyWith(height: 1.25),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.x12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.push(ProfileSetupScreen.routePath),
                                child: const Text('Edit profile'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.x12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  await context.read<AuthProvider>().signOut();
                                },
                                child: const Text('Log out'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x16),
                  Row(
                    children: [
                      Text(
                        'Saved addresses',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.push(AddressEditScreen.routePath),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x10),
                  if (addresses.isLoading && addresses.addresses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.x16),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else if (addresses.addresses.isEmpty)
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.x16),
                      child: Row(
                        children: [
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(AppRadius.r16),
                            ),
                            child: Icon(Icons.location_on_outlined, color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(width: AppSpacing.x12),
                          Expanded(
                            child: Text(
                              'Add an address (with landmarks) for faster confirmations.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: addresses.addresses.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.x10),
                      itemBuilder: (context, index) {
                        final a = addresses.addresses[index];
                        return AppCard(
                          padding: const EdgeInsets.all(AppSpacing.x14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 44,
                                width: 44,
                                decoration: BoxDecoration(
                                  color: a.isDefault
                                      ? theme.colorScheme.primaryContainer
                                      : theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(AppRadius.r16),
                                ),
                                child: Icon(
                                  Icons.location_on_rounded,
                                  color: a.isDefault
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.x12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            a.title,
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ),
                                        if (a.isDefault)
                                          Chip(
                                            label: const Text('Default'),
                                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.x6),
                                    Text(
                                      a.subtitle,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        height: 1.25,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.x10),
                                    Row(
                                      children: [
                                        TextButton(
                                          onPressed: () => context.push(AddressEditScreen.routePath, extra: a),
                                          child: const Text('Edit'),
                                        ),
                                        const SizedBox(width: 6),
                                        TextButton(
                                          onPressed: () => context.read<AddressProvider>().setDefault(a.id),
                                          child: const Text('Set default'),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          tooltip: 'Delete',
                                          onPressed: () async {
                                            final addressProvider = context.read<AddressProvider>();
                                            final ok = await showDialog<bool>(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  title: const Text('Delete address?'),
                                                  content: Text('Remove “${a.title}”?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.of(context).pop(false),
                                                      child: const Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () => Navigator.of(context).pop(true),
                                                      child: const Text('Delete'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                            if (ok == true) {
                                              await addressProvider.deleteAddress(a.id);
                                            }
                                          },
                                          icon: const Icon(Icons.delete_outline),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: AppSpacing.x24),
                ],
              )
            : AppEmptyState(
                title: 'Welcome',
                body: 'Log in to save addresses, track orders, and reorder in one tap.',
                icon: Icons.person_outline,
                actionLabel: AppStrings.logIn,
                onAction: () => context.push(LoginScreen.routePath),
              ),
      ),
    );
  }
}
