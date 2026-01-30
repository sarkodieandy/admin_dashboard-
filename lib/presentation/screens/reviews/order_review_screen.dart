import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../domain/entities/order_item.dart';
import '../../../domain/entities/review.dart';
import '../../../domain/repositories/order_repository.dart';
import '../../../domain/repositories/review_repository.dart';

class OrderReviewScreen extends StatefulWidget {
  const OrderReviewScreen({super.key, required this.orderId});

  static const routePath = '/order/:orderId/review';
  static String routePathFor(String orderId) => '/order/$orderId/review';

  final String orderId;

  @override
  State<OrderReviewScreen> createState() => _OrderReviewScreenState();
}

class _OrderReviewScreenState extends State<OrderReviewScreen> {
  late final Future<_ReviewData> _future = _load();
  final _comment = TextEditingController();
  int _rating = 0;
  final Map<String, int> _itemRatings = {};
  bool _submitting = false;
  String? _error;

  Future<_ReviewData> _load() async {
    final reviewRepo = context.read<ReviewRepository>();
    final orderRepo = context.read<OrderRepository>();
    final results = await Future.wait<dynamic>([
      reviewRepo.fetchMyReviewForOrder(orderId: widget.orderId),
      orderRepo.fetchOrderItems(orderId: widget.orderId),
    ]);
    return _ReviewData(
      existing: results[0] as Review?,
      items: results[1] as List<OrderItem>,
    );
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit(List<OrderItem> items) async {
    if (_rating <= 0) {
      setState(() => _error = 'Please rate your order.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final reviewRepo = context.read<ReviewRepository>();
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await reviewRepo.createReview(
        orderId: widget.orderId,
        rating: _rating,
        comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
        items: [
          for (final it in items)
            ReviewItemDraft(
              itemId: it.itemId,
              rating: _itemRatings[it.id] ?? _rating,
            ),
        ],
      );

      messenger.showSnackBar(const SnackBar(content: Text('Thanks for the review!')));
      router.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Rate your order')),
      body: SafeArea(
        child: FutureBuilder<_ReviewData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return AppErrorState(
                title: AppStrings.somethingWentWrong,
                body: snapshot.error.toString(),
              );
            }

            final data = snapshot.data;
            if (data == null) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            }

            if (data.existing != null) {
              final r = data.existing!;
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.x16),
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.x16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thanks for your feedback',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x10),
                      _StarRating(
                        rating: r.rating,
                        onChanged: null,
                      ),
                      if ((r.comment ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.x12),
                        Text(
                          r.comment!,
                          style: theme.textTheme.bodyMedium?.copyWith(height: 1.25),
                        ),
                      ],
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final items = data.items;

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.x16),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.x16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How was everything?',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x10),
                      _StarRating(
                        rating: _rating,
                        onChanged: (v) => setState(() => _rating = v),
                      ),
                      const SizedBox(height: AppSpacing.x12),
                      TextField(
                        controller: _comment,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Optional: tell us what to improve (or what you loved).',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x12),
                if (items.isNotEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.x16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rate items (optional)',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: AppSpacing.x12),
                        for (final it in items) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  it.nameSnapshot,
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              _StarRating(
                                rating: _itemRatings[it.id] ?? _rating,
                                dense: true,
                                onChanged: (v) => setState(() => _itemRatings[it.id] = v),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.x10),
                        ],
                      ],
                    ),
                  ),
                if ((_error ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.x12),
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: AppSpacing.x24),
                ElevatedButton(
                  onPressed: _submitting ? null : () => _submit(items),
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit review'),
                ),
                const SizedBox(height: AppSpacing.x12),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({
    required this.rating,
    required this.onChanged,
    this.dense = false,
  });

  final int rating;
  final ValueChanged<int>? onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = dense ? 18.0 : 26.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= 5; i++)
          IconButton(
            constraints: BoxConstraints.tight(Size(size + 14, size + 14)),
            padding: EdgeInsets.zero,
            iconSize: size,
            tooltip: '$i',
            onPressed: onChanged == null ? null : () => onChanged!(i),
            icon: Icon(
              i <= rating ? Icons.star_rounded : Icons.star_border_rounded,
              color: i <= rating ? theme.colorScheme.tertiary : theme.colorScheme.outlineVariant,
            ),
          ),
      ],
    );
  }
}

class _ReviewData {
  const _ReviewData({required this.existing, required this.items});

  final Review? existing;
  final List<OrderItem> items;
}
