class CartAddon {
  const CartAddon({
    required this.id,
    required this.name,
    required this.price,
  });

  factory CartAddon.fromJson(Map<String, dynamic> json) {
    return CartAddon(
      id: json['id'] as String,
      name: json['name'] as String,
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0,
    );
  }

  final String id;
  final String name;
  final double price;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
      };
}

