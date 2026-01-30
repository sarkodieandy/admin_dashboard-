import '../entities/cart_snapshot.dart';

abstract class CartRepository {
  Future<CartSnapshot> load();
  Future<void> save(CartSnapshot snapshot);
  Future<void> clear();
}

