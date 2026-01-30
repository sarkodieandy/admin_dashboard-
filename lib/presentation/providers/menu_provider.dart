import 'dart:async';

import 'package:flutter/foundation.dart' hide Category;

import '../../core/utils/debouncer.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/promo.dart';
import '../../domain/repositories/menu_repository.dart';

class MenuProvider extends ChangeNotifier {
  MenuProvider({required MenuRepository repository})
      : _repository = repository,
        _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 250));

  final MenuRepository _repository;
  final Debouncer _searchDebouncer;

  bool _isHomeLoading = false;
  String? _homeError;
  List<Category> _categories = const [];
  List<Promo> _promos = const [];
  List<MenuItem> _popular = const [];

  bool get isHomeLoading => _isHomeLoading;
  String? get homeError => _homeError;
  List<Category> get categories => _categories;
  List<Promo> get promos => _promos;
  List<MenuItem> get popularItems => _popular;

  Future<void> loadHome({bool force = false}) async {
    if (_isHomeLoading) return;
    if (!force && (_categories.isNotEmpty || _popular.isNotEmpty || _promos.isNotEmpty)) return;

    _isHomeLoading = true;
    _homeError = null;
    notifyListeners();

    try {
      List<Category>? categories;
      List<Promo>? promos;
      List<MenuItem>? popular;
      final errors = <String>[];

      Future<void> loadCategories() async {
        try {
          categories = await _repository.fetchCategories();
        } catch (e) {
          errors.add('Categories: $e');
        }
      }

      Future<void> loadPromos() async {
        try {
          promos = await _repository.fetchActivePromos(limit: 5);
        } catch (e) {
          errors.add('Promos: $e');
        }
      }

      Future<void> loadPopular() async {
        try {
          popular = await _repository.fetchPopularItems(limit: 10);
        } catch (e) {
          errors.add('Popular: $e');
        }
      }

      await Future.wait<void>([loadCategories(), loadPromos(), loadPopular()]);

      if (categories != null) _categories = categories!;
      if (promos != null) _promos = promos!;
      if (popular != null) _popular = popular!;

      if (errors.isNotEmpty) _homeError = errors.join('\n');
    } finally {
      _isHomeLoading = false;
      notifyListeners();
    }
  }

  // =========
  // Search
  // =========

  String _searchQuery = '';
  bool _isSearching = false;
  String? _searchError;
  List<MenuItem> _searchResults = const [];

  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;
  String? get searchError => _searchError;
  List<MenuItem> get searchResults => _searchResults;

  void setSearchQuery(String query) {
    _searchQuery = query;
    _searchError = null;

    final q = query.trim();
    if (q.isEmpty) {
      _isSearching = false;
      _searchResults = const [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    _searchDebouncer.run(() {
      unawaited(_runSearch(q));
    });
  }

  Future<void> _runSearch(String query) async {
    try {
      final results = await _repository.searchMenuItems(query: query, limit: 10);
      if (_searchQuery.trim() != query) return;
      _searchResults = results;
    } catch (e) {
      if (_searchQuery.trim() != query) return;
      _searchError = e.toString();
      _searchResults = const [];
    } finally {
      if (_searchQuery.trim() == query) {
        _isSearching = false;
        notifyListeners();
      }
    }
  }

  // =========
  // Category pagination
  // =========

  final Map<String, _CategoryItemsState> _categoryStates = {};

  _CategoryItemsState _stateFor(String categoryId) =>
      _categoryStates.putIfAbsent(categoryId, () => _CategoryItemsState());

  List<MenuItem> categoryItems(String categoryId) => _stateFor(categoryId).items;
  bool isCategoryLoading(String categoryId) => _stateFor(categoryId).isLoading;
  bool isCategoryLoadingMore(String categoryId) => _stateFor(categoryId).isLoadingMore;
  bool categoryHasMore(String categoryId) => _stateFor(categoryId).hasMore;
  String? categoryError(String categoryId) => _stateFor(categoryId).error;

  Future<void> loadCategoryItems(String categoryId, {bool refresh = false}) async {
    final state = _stateFor(categoryId);
    if (state.isLoading) return;

    if (!refresh && state.items.isNotEmpty) return;

    state
      ..isLoading = true
      ..error = null
      ..offset = 0
      ..hasMore = true
      ..items = [];
    notifyListeners();

    try {
      final items = await _repository.fetchMenuItemsByCategory(
        categoryId: categoryId,
        limit: state.pageSize,
        offset: 0,
      );

      state.items = items;
      state.offset = items.length;
      state.hasMore = items.length >= state.pageSize;
    } catch (e) {
      state.error = e.toString();
    } finally {
      state.isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreCategoryItems(String categoryId) async {
    final state = _stateFor(categoryId);
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state.isLoadingMore = true;
    state.error = null;
    notifyListeners();

    try {
      final next = await _repository.fetchMenuItemsByCategory(
        categoryId: categoryId,
        limit: state.pageSize,
        offset: state.offset,
      );

      state.items = [...state.items, ...next];
      state.offset += next.length;
      state.hasMore = next.length >= state.pageSize;
    } catch (e) {
      state.error = e.toString();
    } finally {
      state.isLoadingMore = false;
      notifyListeners();
    }
  }

  // =========
  // Item detail
  // =========

  final Map<String, _ItemDetailState> _detailStates = {};

  _ItemDetailState _detailFor(String itemId) =>
      _detailStates.putIfAbsent(itemId, () => _ItemDetailState());

  MenuItem? itemDetail(String itemId) => _detailFor(itemId).item;
  bool isItemDetailLoading(String itemId) => _detailFor(itemId).isLoading;
  String? itemDetailError(String itemId) => _detailFor(itemId).error;

  Future<void> loadItemDetail(String itemId) async {
    final state = _detailFor(itemId);
    if (state.isLoading) return;
    if (state.item != null) return;

    state
      ..isLoading = true
      ..error = null;
    notifyListeners();

    try {
      state.item = await _repository.fetchMenuItemDetail(itemId: itemId);
    } catch (e) {
      state.error = e.toString();
    } finally {
      state.isLoading = false;
      notifyListeners();
    }
  }

  Future<List<MenuItem>> fetchFrequentlyBoughtTogether({
    required String itemId,
    required String? categoryId,
  }) {
    return _repository.fetchFrequentlyBoughtTogether(itemId: itemId, categoryId: categoryId);
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    super.dispose();
  }
}

class _CategoryItemsState {
  static const pageSizeDefault = 20;

  int get pageSize => pageSizeDefault;

  List<MenuItem> items = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  int offset = 0;
  String? error;
}

class _ItemDetailState {
  MenuItem? item;
  bool isLoading = false;
  String? error;
}
