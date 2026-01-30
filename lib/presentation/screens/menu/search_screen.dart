import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/menu/spice_indicator.dart';
import 'menu_item_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  static const routePath = '/app/home/search';

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      context.read<MenuProvider>().setSearchQuery(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.search)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x16),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: AppStrings.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: menu.searchQuery.trim().isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _controller.clear();
                            context.read<MenuProvider>().setSearchQuery('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.x16),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final q = menu.searchQuery.trim();
                    if (q.isEmpty) {
                      return const AppEmptyState(
                        title: AppStrings.whatAreYouCravingTitle,
                        body: AppStrings.whatAreYouCravingBody,
                        icon: Icons.search_rounded,
                      );
                    }

                    if (menu.searchError != null && menu.searchResults.isEmpty) {
                      return AppErrorState(
                        title: AppStrings.searchFailedTitle,
                        body: menu.searchError!,
                        onRetry: () => context.read<MenuProvider>().setSearchQuery(q),
                      );
                    }

                    if (!menu.isSearching && menu.searchResults.isEmpty) {
                      return AppEmptyState(
                        title: AppStrings.noResultsFor(q),
                        body: AppStrings.noResultsBody,
                        icon: Icons.restaurant_menu_rounded,
                      );
                    }

                    final results = menu.searchResults;
                    return ListView.separated(
                      itemCount: results.length + (menu.isSearching ? 1 : 0),
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        if (index >= results.length) {
                          return Padding(
                            padding: const EdgeInsets.all(AppSpacing.x16),
                            child: Row(
                              children: [
                                SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.x10),
                                Text(
                                  AppStrings.searching,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final item = results[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          leading: AppNetworkImage(
                            url: item.imageUrl,
                            height: 56,
                            width: 56,
                            borderRadius: 14,
                          ),
                          title: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                Money.format(item.basePrice),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.x12),
                              SpiceIndicator(level: item.spiceLevel, compact: true),
                            ],
                          ),
                          trailing: item.isSoldOut
                              ? Chip(
                                  label: const Text(AppStrings.soldOut),
                                  backgroundColor: theme.colorScheme.errorContainer,
                                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.w800,
                                  ),
                                )
                              : Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                          onTap: () => context.push(MenuItemDetailScreen.routePathFor(item.id)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
