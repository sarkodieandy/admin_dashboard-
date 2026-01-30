import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/env/app_env.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../domain/entities/order.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/profile_provider.dart';
import '../profile/profile_setup_screen.dart';
import '../payment/paystack_checkout_screen.dart';
import 'address_edit_screen.dart';
import '../orders/order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  static const routePath = '/checkout';

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String? _selectedAddressId;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isStartingPaystack = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final addressProvider = context.watch<AddressProvider>();
    if (_selectedAddressId == null && addressProvider.defaultAddress != null) {
      _selectedAddressId = addressProvider.defaultAddress!.id;
    }
  }

  Future<String?> _ensurePaystackEmail(String? existing) async {
    final preset = (existing ?? '').trim();
    if (preset.isNotEmpty) return preset;

    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Email required'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'you@example.com',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                final isValid = value.contains('@') && value.contains('.');
                if (!isValid) return;
                Navigator.of(context).pop(value);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return (email ?? '').trim().isEmpty ? null : email!.trim();
  }

  Future<({String authorizationUrl, String reference})> _paystackInit({
    required String email,
    required int amountPesewas,
  }) async {
    final res = await Supabase.instance.client.functions.invoke(
      'paystack-init',
      body: <String, dynamic>{
        'email': email,
        'amount': amountPesewas,
        'currency': 'GHS',
        'callback_url': AppEnv.paystackCallbackUrl,
      },
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      final authorizationUrl = (data['authorization_url'] ?? '').toString().trim();
      final reference = (data['reference'] ?? '').toString().trim();
      if (authorizationUrl.isNotEmpty && reference.isNotEmpty) {
        return (authorizationUrl: authorizationUrl, reference: reference);
      }
    }

    throw Exception('Invalid Paystack init response');
  }

  Future<void> _pickSchedule() async {
    final cart = context.read<CartProvider>();
    final now = DateTime.now();

    final selected = await showModalBottomSheet<_ScheduleOption>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.x16, AppSpacing.x8, AppSpacing.x16, AppSpacing.x16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.flash_on_rounded),
                  title: const Text('As soon as possible'),
                  subtitle: const Text('Freshly packed, then dispatched.'),
                  onTap: () => Navigator.of(context).pop(_ScheduleOption.asap),
                ),
                ListTile(
                  leading: const Icon(Icons.schedule_rounded),
                  title: const Text('Later today'),
                  subtitle: const Text('Pick a time that works for you.'),
                  onTap: () => Navigator.of(context).pop(_ScheduleOption.laterToday),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today_rounded),
                  title: const Text('Tomorrow'),
                  subtitle: const Text('Pick a time for tomorrow.'),
                  onTap: () => Navigator.of(context).pop(_ScheduleOption.tomorrow),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) return;

    if (selected == _ScheduleOption.asap) {
      await cart.setScheduledFor(null);
      return;
    }

    final isTomorrow = selected == _ScheduleOption.tomorrow;
    final base = isTomorrow ? now.add(const Duration(days: 1)) : now;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (!mounted || time == null) return;

    final scheduled = DateTime(base.year, base.month, base.day, time.hour, time.minute);
    await cart.setScheduledFor(scheduled);
  }

  Future<void> _pickTip() async {
    final cart = context.read<CartProvider>();

    final selected = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        final tips = [0.0, 5.0, 10.0, 15.0];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.x16, AppSpacing.x8, AppSpacing.x16, AppSpacing.x16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add a tip',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: AppSpacing.x10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final t in tips)
                      ChoiceChip(
                        label: Text(t == 0 ? 'No tip' : Money.format(t)),
                        selected: cart.tip == t,
                        onSelected: (_) => Navigator.of(context).pop(t),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) return;
    await cart.setTip(selected);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final addressProvider = context.watch<AddressProvider>();
    final cart = context.watch<CartProvider>();
    final orders = context.watch<OrderProvider>();
    final theme = Theme.of(context);
    final isBusy = orders.isPlacingOrder || _isStartingPaystack;

    if (cart.lines.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.checkout)),
        body: const AppEmptyState(
          title: 'Nothing to checkout',
          body: 'Add items to your cart first.',
          icon: Icons.shopping_bag_outlined,
        ),
      );
    }

    if (!auth.isSignedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.checkout)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Almost there',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.x8),
                Text(
                  'Sign in (or continue as guest) to save your address and place the order.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.25,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await context.read<AuthProvider>().signInAnonymously();
                    } catch (error, stackTrace) {
                      AppLogger.e(
                        'checkout_guest_signin_failed',
                        tag: 'auth',
                        error: error,
                        stackTrace: stackTrace,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
                    }
                  },
                  child: const Text(AppStrings.browseAsGuest),
                ),
                const SizedBox(height: AppSpacing.x12),
                OutlinedButton(
                  onPressed: () => context.push('/auth/login'),
                  child: const Text(AppStrings.logIn),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!profile.isComplete) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.checkout)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add your delivery details',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.x8),
                Text(
                  'A name and phone number helps the restaurant confirm quickly and call if needed.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.25,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => context.push(ProfileSetupScreen.routePath),
                  child: const Text(AppStrings.profileSetupTitle),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final selectedAddress = addressProvider.addresses.where((a) => a.id == _selectedAddressId).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.checkout)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.x16),
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.x14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Delivery address',
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
                  if (addressProvider.isLoading && addressProvider.addresses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.x16),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else if (addressProvider.addresses.isEmpty)
                    const AppEmptyState(
                      title: 'No saved addresses',
                      body: 'Add one so we can deliver quickly.',
                      icon: Icons.location_on_outlined,
                    )
                  else
                    RadioGroup<String>(
                      groupValue: _selectedAddressId,
                      onChanged: (v) => setState(() => _selectedAddressId = v),
                      child: Column(
                        children: [
                          for (final a in addressProvider.addresses) ...[
                            Container(
                              decoration: BoxDecoration(
                                color: a.id == _selectedAddressId
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(AppRadius.r16),
                                border: Border.all(color: theme.colorScheme.outlineVariant),
                              ),
                              child: RadioListTile<String>(
                                value: a.id,
                                enabled: !orders.isPlacingOrder,
                                title: Text(
                                  a.title,
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                subtitle: Text(
                                  a.subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.25,
                                  ),
                                ),
                                secondary: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (a.isDefault)
                                      Chip(
                                        label: const Text('Default'),
                                        backgroundColor: theme.colorScheme.surface,
                                      ),
                                    IconButton(
                                      tooltip: 'Edit',
                                      onPressed: () => context.push(
                                        AddressEditScreen.routePath,
                                        extra: a,
                                      ),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                  ],
                                ),
                                controlAffinity: ListTileControlAffinity.trailing,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.x10),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x12),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.x14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Schedule',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _pickSchedule,
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x10),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: AppSpacing.x10),
                      Expanded(
                        child: Text(
                          _scheduleLabel(cart.scheduledFor),
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
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
                    'Payment',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: AppSpacing.x10),
                  RadioGroup<PaymentMethod>(
                    groupValue: _paymentMethod,
                    onChanged: isBusy ? (_) {} : (v) => setState(() => _paymentMethod = v ?? _paymentMethod),
                    child: Column(
                      children: [
                        RadioListTile<PaymentMethod>(
                          value: PaymentMethod.cash,
                          enabled: !isBusy,
                          title: const Text('Cash on delivery'),
                          subtitle: const Text('Pay when your food arrives.'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<PaymentMethod>(
                          value: PaymentMethod.paystack,
                          enabled: !isBusy,
                          title: const Text('Paystack (GHS)'),
                          subtitle: const Text('Pay now with card or mobile money.'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<PaymentMethod>(
                          value: PaymentMethod.momo,
                          enabled: !isBusy,
                          title: const Text('Mobile Money (mock)'),
                          subtitle: const Text('Pluggable interface — we’ll stub the flow.'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x12),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.x14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Tip',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const Spacer(),
                      TextButton(onPressed: _pickTip, child: const Text('Change')),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x10),
                  Row(
                    children: [
                      Icon(Icons.favorite_border, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: AppSpacing.x10),
                      Expanded(
                        child: Text(
                          cart.tip == 0 ? 'No tip' : Money.format(cart.tip),
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
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
                    'Order summary',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: AppSpacing.x12),
                  _SummaryRow(label: 'Subtotal', value: Money.format(cart.subtotal)),
                  const SizedBox(height: AppSpacing.x8),
                  _SummaryRow(label: 'Delivery', value: Money.format(cart.deliveryFee)),
                  if (cart.discount > 0) ...[
                    const SizedBox(height: AppSpacing.x8),
                    _SummaryRow(label: 'Discount', value: '- ${Money.format(cart.discount)}'),
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
                    'Bekwai deliveries only • Minimum ${Money.format(AppConstants.minOrderSubtotal)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if ((orders.placeError ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.x12),
              Text(
                orders.placeError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  height: 1.25,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.x24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.x16, 0, AppSpacing.x16, AppSpacing.x16),
          child: ElevatedButton(
            onPressed: (!cart.meetsMinimumOrder || selectedAddress == null || isBusy)
                ? null
                : () async {
                    final orderProvider = context.read<OrderProvider>();
                    final cartProvider = context.read<CartProvider>();
                    final router = GoRouter.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final method = _paymentMethod;
                    final paymentStatus = _paymentMethod == PaymentMethod.cash
                        ? PaymentStatus.unpaid
                        : PaymentStatus.pending;

                    if (method == PaymentMethod.paystack) {
                      try {
                        setState(() => _isStartingPaystack = true);
                        final email = await _ensurePaystackEmail(auth.user?.email);
                        if (!mounted || email == null) return;

                        final amountPesewas = (cart.total * 100).round();
                        AppLogger.i(
                          'paystack_init_start amountPesewas=$amountPesewas',
                          tag: 'paystack',
                        );

                        final init = await _paystackInit(email: email, amountPesewas: amountPesewas);
                        AppLogger.i('paystack_init_ok reference=${init.reference}', tag: 'paystack');

                        if (!mounted) return;
                        final paid = await router.push<bool>(
                          PaystackCheckoutScreen.routePath,
                          extra: PaystackCheckoutArgs(
                            authorizationUrl: init.authorizationUrl,
                            reference: init.reference,
                            callbackUrl: AppEnv.paystackCallbackUrl,
                          ),
                        );

                        if (!mounted || paid != true) return;

                        final order = await orderProvider.finalizePaystackOrder(
                          reference: init.reference,
                          address: selectedAddress,
                          lines: cart.lines,
                          subtotal: cart.subtotal,
                          deliveryFee: cart.deliveryFee,
                          discount: cart.discount,
                          tip: cart.tip,
                          total: cart.total,
                          scheduledFor: cart.scheduledFor,
                        );

                        if (!mounted || order == null) return;

                        await cartProvider.clear();

                        if (!mounted) return;
                        router.go(OrderTrackingScreen.routePathFor(order.id));
                      } catch (error, stackTrace) {
                        AppLogger.e(
                          'paystack_checkout_failed',
                          tag: 'paystack',
                          error: error,
                          stackTrace: stackTrace,
                        );
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      } finally {
                        if (mounted) setState(() => _isStartingPaystack = false);
                      }
                      return;
                    }

                    final order = await orderProvider.placeOrder(
                      address: selectedAddress,
                      lines: cart.lines,
                      subtotal: cart.subtotal,
                      deliveryFee: cart.deliveryFee,
                      discount: cart.discount,
                      tip: cart.tip,
                      total: cart.total,
                      paymentMethod: method,
                      paymentStatus: paymentStatus,
                      scheduledFor: cart.scheduledFor,
                    );

                    if (!mounted || order == null) return;

                    await cartProvider.clear();

                    if (!mounted) return;
                    router.go(OrderTrackingScreen.routePathFor(order.id));
                  },
            child: orders.isPlacingOrder
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Place order • ${Money.format(cart.total)}'),
          ),
        ),
      ),
    );
  }

  String _scheduleLabel(DateTime? when) {
    if (when == null) return 'As soon as possible';
    final fmt = DateFormat('EEE, MMM d • HH:mm');
    return 'Scheduled: ${fmt.format(when)}';
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

enum _ScheduleOption { asap, laterToday, tomorrow }

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
