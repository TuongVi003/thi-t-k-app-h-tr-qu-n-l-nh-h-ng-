import 'menu_item.dart';

class OrderItem {
  final MenuItem menuItem;
  int quantity;
  String? specialRequest;
  double get totalPrice => menuItem.price * quantity;

  OrderItem({
    required this.menuItem,
    this.quantity = 1,
    this.specialRequest,
  });

  OrderItem copyWith({
    MenuItem? menuItem,
    int? quantity,
    String? specialRequest,
  }) {
    return OrderItem(
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
      specialRequest: specialRequest ?? this.specialRequest,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItem': menuItem.toJson(),
      'quantity': quantity,
      'specialRequest': specialRequest,
      'totalPrice': totalPrice,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuItem: MenuItem.fromJson(json['menuItem']),
      quantity: json['quantity'],
      specialRequest: json['specialRequest'],
    );
  }
}

enum OrderStatus {
  pending,    // Đang chờ
  preparing,  // Đang chuẩn bị
  ready,      // Sẵn sàng phục vụ
  served,     // Đã phục vụ
  cancelled   // Đã hủy
}

class Order {
  final String id;
  final String tableId;
  final List<OrderItem> items;
  OrderStatus status;
  final DateTime createdAt;
  DateTime? completedAt;
  String? notes;
  double get totalAmount => items.fold(0, (sum, item) => sum + item.totalPrice);
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  Order({
    required this.id,
    required this.tableId,
    required this.items,
    this.status = OrderStatus.pending,
    DateTime? createdAt,
    this.completedAt,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  Order copyWith({
    String? id,
    String? tableId,
    List<OrderItem>? items,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      items: items ?? this.items,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }

  void addItem(OrderItem item) {
    // Kiểm tra xem món đã có trong order chưa
    final existingIndex = items.indexWhere(
      (existing) => existing.menuItem.id == item.menuItem.id &&
                   existing.specialRequest == item.specialRequest
    );
    
    if (existingIndex >= 0) {
      items[existingIndex].quantity += item.quantity;
    } else {
      items.add(item);
    }
  }

  void removeItem(String menuItemId) {
    items.removeWhere((item) => item.menuItem.id == menuItemId);
  }

  void updateItemQuantity(String menuItemId, int newQuantity) {
    final index = items.indexWhere((item) => item.menuItem.id == menuItemId);
    if (index >= 0) {
      if (newQuantity <= 0) {
        items.removeAt(index);
      } else {
        items[index].quantity = newQuantity;
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableId': tableId,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
      'totalAmount': totalAmount,
      'totalItems': totalItems,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      tableId: json['tableId'],
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      notes: json['notes'],
    );
  }
}