import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class SpiceIndicator extends StatelessWidget {
  const SpiceIndicator({
    super.key,
    required this.level,
    this.showLabel = true,
    this.compact = false,
  });

  final int level;
  final bool showLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = level.clamp(0, 3);
    final label = switch (clamped) {
      0 => AppStrings.spiceMild,
      1 => AppStrings.spicePepper,
      2 => AppStrings.spiceHot,
      _ => AppStrings.spiceExtraHot,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(
          3,
          (i) => Padding(
            padding: EdgeInsets.only(right: i == 2 ? 0 : 2),
            child: Icon(
              Icons.local_fire_department_rounded,
              size: compact ? 14 : 16,
              color: i < clamped ? AppColors.spicy : theme.colorScheme.outlineVariant,
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: AppSpacing.x6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
