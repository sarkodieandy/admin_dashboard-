import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_radius.dart';

/// Small shared UI components (UI-only).
class AppComponents {
  static void haptic() {
    HapticFeedback.selectionClick();
  }
}

class AppAnimatedBadge extends StatefulWidget {
  const AppAnimatedBadge({
    super.key,
    required this.count,
    this.max = 9,
    this.backgroundColor,
    this.foregroundColor,
  });

  final int count;
  final int max;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  State<AppAnimatedBadge> createState() => _AppAnimatedBadgeState();
}

class _AppAnimatedBadgeState extends State<AppAnimatedBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  int _prev = 0;

  @override
  void initState() {
    super.initState();
    _prev = widget.count;
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  }

  @override
  void didUpdateWidget(covariant AppAnimatedBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != _prev) {
      _prev = widget.count;
      _c
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final bg = widget.backgroundColor ?? theme.colorScheme.primary;
    final fg = widget.foregroundColor ?? theme.colorScheme.onPrimary;

    final label = widget.count > widget.max ? '${widget.max}+' : '${widget.count}';

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeOutBack.transform(_c.value);
        final s = 1 + (t * 0.18);
        return Transform.scale(
          scale: s,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: theme.colorScheme.surface, width: 2),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      },
    );
  }
}

class AppBadgeIcon extends StatelessWidget {
  const AppBadgeIcon({super.key, required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -6,
          top: -6,
          child: AppAnimatedBadge(count: count),
        ),
      ],
    );
  }
}

class StaggeredSlideFadeIn extends StatelessWidget {
  const StaggeredSlideFadeIn({
    super.key,
    required this.child,
    required this.index,
    this.baseDelay = const Duration(milliseconds: 40),
    this.duration = const Duration(milliseconds: 260),
    this.offsetY = 10,
    this.beginScale = 0.985,
  });

  final Widget child;
  final int index;
  final Duration baseDelay;
  final Duration duration;
  final double offsetY;
  final double beginScale;

  @override
  Widget build(BuildContext context) {
    final delay = baseDelay * index;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        // Hold at 0 during the "delay" portion.
        final effective = ((t * (duration + delay).inMilliseconds) - delay.inMilliseconds) /
            duration.inMilliseconds;
        final v = effective.clamp(0.0, 1.0);
        final s = beginScale + ((1 - beginScale) * v);
        return Opacity(
          opacity: v,
          child: Transform.scale(
            scale: s,
            child: Transform.translate(
              offset: Offset(0, (1 - v) * offsetY),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              if ((subtitle ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
        if (actionLabel != null) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
        ],
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    required this.onColor,
    this.icon,
  });

  final String label;
  final Color color;
  final Color onColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: onColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: onColor,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.onPressed,
    this.pressedScale = 0.98,
    this.duration = const Duration(milliseconds: 140),
  });

  final Widget child;
  final bool enabled;
  final VoidCallback? onPressed;
  final double pressedScale;
  final Duration duration;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  double _scale = 1;

  void _set(double v) {
    if (!mounted) return;
    setState(() => _scale = v);
  }

  @override
  Widget build(BuildContext context) {
    final content = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: widget.enabled ? (_) => _set(widget.pressedScale) : null,
      onPointerUp: widget.enabled ? (_) => _set(1) : null,
      onPointerCancel: widget.enabled ? (_) => _set(1) : null,
      child: AnimatedScale(
        scale: _scale,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );

    if (!widget.enabled || widget.onPressed == null) return content;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onPressed,
      child: content,
    );
  }
}
