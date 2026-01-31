import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../design_system/app_components.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final index = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: _PremiumBottomNav(
            currentIndex: index,
            onSelect: (i) {
              AppComponents.haptic();
              navigationShell.goBranch(i, initialLocation: i == index);
            },
            theme: theme,
          ),
        ),
      ),
    );
  }
}

class _PremiumBottomNav extends StatelessWidget {
  const _PremiumBottomNav({
    required this.currentIndex,
    required this.onSelect,
    required this.theme,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: _NavItem(
              label: AppStrings.home,
              isSelected: currentIndex == 0,
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              onTap: () => onSelect(0),
            ),
          ),
          Expanded(
            child: _NavItem(
              label: AppStrings.orders,
              isSelected: currentIndex == 1,
              icon: Icons.receipt_long_outlined,
              selectedIcon: Icons.receipt_long_rounded,
              onTap: () => onSelect(1),
            ),
          ),
          Expanded(
            child: _NavItem(
              label: 'Chat',
              isSelected: currentIndex == 2,
              icon: Icons.chat_bubble_outline_rounded,
              selectedIcon: Icons.chat_bubble_rounded,
              onTap: () => onSelect(2),
            ),
          ),
          Expanded(
            child: _NavItem(
              label: AppStrings.account,
              isSelected: currentIndex == 3,
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              onTap: () => onSelect(3),
            ),
          ),
        ],
      )),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.isSelected,
    required this.icon,
    required this.selectedIcon,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final IconData icon;
  final IconData selectedIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = isSelected ? theme.colorScheme.secondary : theme.colorScheme.onSurfaceVariant;
    final bg = theme.colorScheme.secondaryContainer.withValues(alpha: isSelected ? 1 : 0);

    return PressScale(
      onPressed: null,
      pressedScale: 0.96,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeOutCubic,
              transitionBuilder: (child, anim) {
                final fade = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
                final scale = Tween<double>(begin: 0.92, end: 1).animate(fade);
                return FadeTransition(opacity: fade, child: ScaleTransition(scale: scale, child: child));
              },
              child: Column(
                key: ValueKey(isSelected),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isSelected ? selectedIcon : icon, color: fg),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: isSelected
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: fg,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.1,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
