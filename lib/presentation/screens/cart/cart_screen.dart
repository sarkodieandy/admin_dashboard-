import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../providers/cart_provider.dart';
import '../home/home_screen.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  static const routePath = '/cart';

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _promo = TextEditingController();

  @override
  void dispose() {
    _promo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);

    if (cart.isRestoring) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.cart)),
      body: SafeArea(
        child: cart.lines.isEmpty
            ? AppEmptyState(
                title: 'Your cart is empty',
                body: 'Add a meal you love — we’ll keep it here while you browse.',
                icon: Icons.shopping_bag_outlined,
                actionLabel: AppStrings.browseMenu,
                onAction: () => context.go(HomeScreen.routePath),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.x16),
                      children: [
                        for (final line in cart.lines) ...[
                          AppCard(
                            padding: const EdgeInsets.all(AppSpacing.x12),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppNetworkImage(
                                      url: line.imageUrl,
                                      height: 64,
                                      width: 64,
                                      borderRadius: AppRadius.r16,
                                    ),
                                    const SizedBox(width: AppSpacing.x12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            line.name,
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          if ((line.variantName ?? '').trim().isNotEmpty) ...[
                                            const SizedBox(height: AppSpacing.x6),
                                            Text(
                                              line.variantName!,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Remove',
                                      onPressed: () => context.read<CartProvider>().removeLine(line.id),
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                                  ],
                                ),
                                if (line.addons.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.x10),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (final a in line.addons)
                                          Chip(
                                            label: Text(a.name),
                                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (line.note.trim().isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.x10),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Note: ${line.note.trim()}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.x12),
                                Row(
                                  children: [
                                    _QtyPill(
                                      qty: line.qty,
                                      onMinus: () => context.read<CartProvider>().updateQty(line.id, line.qty - 1),
                                      onPlus: () => context.read<CartProvider>().updateQty(line.id, line.qty + 1),
                                    ),
                                    const Spacer(),
                                    Text(
                                      Money.format(line.total),
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.x12),
                        ],
                        const SizedBox(height: AppSpacing.x4),
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.x14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Promo code',
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const Spacer(),
                                  if (cart.promoCode != null)
                                    TextButton(
                                      onPressed: () => context.read<CartProvider>().removePromo(),
                                      child: const Text('Remove'),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.x10),
                              if (cart.promoCode != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(AppRadius.r16),
                                    border: Border.all(color: theme.colorScheme.outlineVariant),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.local_offer_outlined, color: theme.colorScheme.onSurfaceVariant),
                                      const SizedBox(width: AppSpacing.x10),
                                      Expanded(
                                        child: Text(
                                          cart.promoCode!,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      if (cart.isApplyingPromo)
                                        const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                    ],
                                  ),
                                )
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _promo,
                                        textCapitalization: TextCapitalization.characters,
                                        decoration: const InputDecoration(
                                          hintText: 'e.g. FLK10',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.x12),
                                    SizedBox(
                                      height: 52,
                                      child: FilledButton(
                                        onPressed: cart.isApplyingPromo
                                            ? null
                                            : () async {
                                                final ok = await context
                                                    .read<CartProvider>()
                                                    .applyPromoCode(_promo.text);
                                                if (ok) _promo.clear();
                                              },
                                        child: cart.isApplyingPromo
                                            ? const SizedBox(
                                                height: 18,
                                                width: 18,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : const Text('Apply'),
                                      ),
                                    ),
                                  ],
                                ),
                              if ((cart.promoError ?? '').trim().isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.x10),
                                Text(
                                  cart.promoError!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x12),
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.x14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Summary',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: AppSpacing.x12),
                              _SummaryRow(label: 'Subtotal', value: Money.format(cart.subtotal)),
                              const SizedBox(height: AppSpacing.x8),
                              _SummaryRow(label: 'Delivery', value: Money.format(cart.deliveryFee)),
                              if (cart.discount > 0) ...[
                                const SizedBox(height: AppSpacing.x8),
                                _SummaryRow(
                                  label: 'Discount',
                                  value: '- ${Money.format(cart.discount)}',
                                ),
                              ],
                              if (cart.tip > 0) ...[
                                const SizedBox(height: AppSpacing.x8),
                                _SummaryRow(label: 'Tip', value: Money.format(cart.tip)),
                              ],
                              const SizedBox(height: AppSpacing.x12),
                              Divider(color: theme.colorScheme.outlineVariant),
                              const SizedBox(height: AppSpacing.x12),
                              _SummaryRow(
                                label: 'Total',
                                value: Money.format(cart.total),
                                isEmphasis: true,
                              ),
                              const SizedBox(height: AppSpacing.x10),
                              Text(
                                'Minimum order: ${Money.format(cart.minimumOrderSubtotal)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x24),
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.x16, 0, AppSpacing.x16, AppSpacing.x16),
                      child: Column(
                        children: [
                          if (!cart.meetsMinimumOrder)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.x10),
                              child: Text(
                                'Add ${Money.format(cart.minimumOrderSubtotal - cart.subtotal)} more to checkout.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ElevatedButton(
                            onPressed: cart.meetsMinimumOrder
                                ? () => context.push(CheckoutScreen.routePath)
                                : null,
                            child: Text('${AppStrings.checkout} • ${Money.format(cart.total)}'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _QtyPill extends StatelessWidget {
  const _QtyPill({
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });

  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          IconButton(onPressed: qty <= 1 ? null : onMinus, icon: const Icon(Icons.remove_rounded)),
          Text(
            '$qty',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          IconButton(onPressed: onPlus, icon: const Icon(Icons.add_rounded)),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isEmphasis = false,
  });

  final String label;
  final String value;
  final bool isEmphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = isEmphasis
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)
        : theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          );

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}
