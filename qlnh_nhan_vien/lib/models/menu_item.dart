enum MenuCategory {
  appetizer,    // Khai vị
  mainCourse,   // Món chính
  dessert,      // Tráng miệng
  beverage,     // Đồ uống
  soup,         // Canh/Súp
  salad,        // Salad
  seafood,      // Hải sản
  vegetarian    // Chay
}

class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final MenuCategory category;
  final bool isAvailable;
  final List<String> ingredients;
  final int preparationTime; // phút

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.isAvailable = true,
    this.ingredients = const [],
    this.preparationTime = 15,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category.toString(),
      'isAvailable': isAvailable,
      'ingredients': ingredients,
      'preparationTime': preparationTime,
    };
  }

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      imageUrl: json['imageUrl'],
      category: MenuCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
        orElse: () => MenuCategory.mainCourse,
      ),
      isAvailable: json['isAvailable'] ?? true,
      ingredients: List<String>.from(json['ingredients'] ?? []),
      preparationTime: json['preparationTime'] ?? 15,
    );
  }
}