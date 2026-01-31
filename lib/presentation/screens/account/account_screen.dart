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
import '../../design_system/app_components.dart';
import '../auth/login_screen.dart';
import '../checkout/address_edit_screen.dart';
import '../orders/orders_screen.dart';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(AppStrings.account),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: auth.isSignedIn
          ? CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _AccountHero(
                    name: profileProvider.profile?.name ?? (auth.isGuest ? 'Guest' : ''),
                    phone: profileProvider.profile?.phone,
                    isGuest: auth.isGuest,
                    note: profileProvider.profile?.defaultDeliveryNote,
                    onEdit: () => context.push(ProfileSetupScreen.routePath),
                    onLogout: () async => context.read<AuthProvider>().signOut(),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.x16, 0, AppSpacing.x16, AppSpacing.x10),
                  sliver: SliverToBoxAdapter(
                    child: StaggeredSlideFadeIn(
                      index: 0,
                      child: _QuickActionsRow(
                        onOrders: () => context.go(OrdersScreen.routePath),
                        onAddress: () => context.push(AddressEditScreen.routePath),
                        onSupport: () {
                          AppComponents.haptic();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Support chat coming soon')),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.x16, AppSpacing.x10, AppSpacing.x16, AppSpacing.x10),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Text(
                          'Saved addresses',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () => context.push(AddressEditScreen.routePath),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (addresses.isLoading && addresses.addresses.isEmpty)
                  const SliverPadding(
                    padding: EdgeInsets.all(AppSpacing.x24),
                    sliver: SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  )
                else if (addresses.addresses.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.x16, 0, AppSpacing.x16, AppSpacing.x24),
                    sliver: SliverToBoxAdapter(
                      child: AppCard(
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
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.x16, 0, AppSpacing.x16, AppSpacing.x24),
                    sliver: SliverList.separated(
                      itemCount: addresses.addresses.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.x10),
                      itemBuilder: (context, index) {
                        final a = addresses.addresses[index];
                        return _AddressCard(
                          title: a.title,
                          subtitle: a.subtitle,
                          isDefault: a.isDefault,
                          onEdit: () => context.push(AddressEditScreen.routePath, extra: a),
                          onSetDefault: () => context.read<AddressProvider>().setDefault(a.id),
                          onDelete: () async {
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
                        );
                      },
                    ),
                  ),
              ],
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x16),
                child: AppEmptyState(
                  title: 'Welcome',
                  body: 'Log in to save addresses, track orders, and reorder in one tap.',
                  icon: Icons.person_outline,
                  actionLabel: AppStrings.logIn,
                  onAction: () => context.push(LoginScreen.routePath),
                ),
              ),
            ),
    );
  }
}

class _AccountHero extends StatelessWidget {
  const _AccountHero({
    required this.name,
    required this.phone,
    required this.isGuest,
    required this.note,
    required this.onEdit,
    required this.onLogout,
  });

  final String name;
  final String? phone;
  final bool isGuest;
  final String? note;
  final VoidCallback onEdit;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = (name.trim().isEmpty) ? (isGuest ? 'Guest' : 'Account') : name;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 64,
        left: AppSpacing.x16,
        right: AppSpacing.x16,
        bottom: AppSpacing.x16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.22),
            theme.colorScheme.secondary.withValues(alpha: 0.08),
            theme.colorScheme.surface.withValues(alpha: 0.0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.94, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) => Transform.scale(scale: v, child: child),
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.r20),
                    ),
                    child: Center(
                      child: Text(
                        displayName.characters.first.toUpperCase(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            if (isGuest)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: theme.colorScheme.outlineVariant),
                                ),
                                child: Text(
                                  'Guest',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.x6),
                        Text(
                          phone ?? 'Add your phone number for delivery updates.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if ((note ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.x12),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.x12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.r16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note_alt_outlined, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: AppSpacing.x10),
                      Expanded(
                        child: Text(
                          note!,
                          style: theme.textTheme.bodySmall?.copyWith(height: 1.25),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.x14),
              Row(
                children: [
                  Expanded(
                    child: PressScale(
                      child: FilledButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Edit profile'),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x12),
                  Expanded(
                    child: PressScale(
                      child: OutlinedButton.icon(
                        onPressed: onLogout,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Log out'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onOrders,
    required this.onAddress,
    required this.onSupport,
  });

  final VoidCallback onOrders;
  final VoidCallback onAddress;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _QuickActionTile(
            title: 'Orders',
            subtitle: 'History & tracking',
            icon: Icons.receipt_long_outlined,
            color: theme.colorScheme.primaryContainer,
            onTap: onOrders,
          ),
        ),
        const SizedBox(width: AppSpacing.x12),
        Expanded(
          child: _QuickActionTile(
            title: 'Addresses',
            subtitle: 'Delivery spots',
            icon: Icons.location_on_outlined,
            color: theme.colorScheme.surfaceContainerHighest,
            onTap: onAddress,
          ),
        ),
        const SizedBox(width: AppSpacing.x12),
        Expanded(
          child: _QuickActionTile(
            title: 'Support',
            subtitle: 'Help & chat',
            icon: Icons.support_agent_rounded,
            color: theme.colorScheme.secondaryContainer,
            onTap: onSupport,
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PressScale(
      child: InkWell(
        onTap: () {
          AppComponents.haptic();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppRadius.r20),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.r20),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.x12),
          child: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.r16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: AppSpacing.x10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.title,
    required this.subtitle,
    required this.isDefault,
    required this.onEdit,
    required this.onSetDefault,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final bool isDefault;
  final VoidCallback onEdit;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.x14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: isDefault ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.r16),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: isDefault ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
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
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Text(
                          'Default',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: AppSpacing.x10),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 6),
                    TextButton.icon(
                      onPressed: onSetDefault,
                      icon: const Icon(Icons.star_outline_rounded, size: 18),
                      label: const Text('Set default'),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: onDelete,
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
  }
}
