import 'package:flutter/material.dart';
import 'package:qlnh_nhan_vien/models/menu_item.dart';
import 'package:qlnh_nhan_vien/models/order.dart';
import 'package:qlnh_nhan_vien/models/table.dart' as models;
import 'package:qlnh_nhan_vien/widgets/menu_item_card.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MenuItem> menuItems = [];
  List<models.Table> occupiedTables = [];
  Order? currentOrder;
  String? selectedTableId;
  MenuCategory selectedCategory = MenuCategory.mainCourse;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMenuItems();
    _loadOccupiedTables();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadMenuItems() {
    // Dữ liệu mẫu menu
    menuItems = [
      // Món chính
      // MenuItem(
      //   id: '1',
      //   name: 'Phở Bò Tái',
      //   description: 'Phở bò truyền thống với thịt tái tươi ngon',
      //   price: 65000,
      //   imageUrl: 'https://via.placeholder.com/150',
      //   category: MenuCategory.mainCourse,
      //   ingredients: ['Thịt bò', 'Bánh phở', 'Hành lá', 'Ngò gai'],
      //   preparationTime: 10,
      // ),
      // MenuItem(
      //   id: '2',
      //   name: 'Cơm Gà Nướng',
      //   description: 'Cơm trắng với gà nướng mật ong thơm ngon',
      //   price: 85000,
      //   imageUrl: 'https://via.placeholder.com/150',
      //   category: MenuCategory.mainCourse,
      //   ingredients: ['Thịt gà', 'Cơm trắng', 'Mật ong', 'Rau củ'],
      //   preparationTime: 15,
      // ),
      
      // Khai vị
      MenuItem(
        id: '3',
        name: 'Salad Trái Cây',
        description: 'Salad trái cây tươi mát với sốt mayonnaise',
        price: 45000,
        imageUrl: 'https://via.placeholder.com/150',
        category: MenuCategory.appetizer,
        ingredients: ['Táo', 'Nho', 'Dứa', 'Mayonnaise'],
        preparationTime: 5,
      ),
      
      // Đồ uống
      MenuItem(
        id: '4',
        name: 'Nước Cam Ép',
        description: 'Nước cam tươi ép 100% không đường',
        price: 25000,
        imageUrl: 'https://via.placeholder.com/150',
        category: MenuCategory.beverage,
        ingredients: ['Cam tươi'],
        preparationTime: 3,
      ),
      MenuItem(
        id: '5',
        name: 'Trà Đá',
        description: 'Trà đá truyền thống mát lạnh',
        price: 15000,
        imageUrl: 'https://via.placeholder.com/150',
        category: MenuCategory.beverage,
        ingredients: ['Trà', 'Đá'],
        preparationTime: 2,
      ),
      
      // Tráng miệng
      MenuItem(
        id: '6',
        name: 'Chè Ba Màu',
        description: 'Chè ba màu truyền thống với đậu xanh, đỗ đen và khoai môn',
        price: 20000,
        imageUrl: 'https://via.placeholder.com/150',
        category: MenuCategory.dessert,
        ingredients: ['Đậu xanh', 'Đỗ đen', 'Khoai môn', 'Nước cốt dừa'],
        preparationTime: 5,
      ),
    ];
  }

  void _loadOccupiedTables() {
    // Dữ liệu mẫu các bàn đã có khách
    occupiedTables = [
      models.Table(
        id: '2',
        number: 2,
        capacity: 4,
        status: models.TableStatus.occupied,
        customerName: 'Nguyễn Văn A',
        customerPhone: '0123456789',
      ),
      models.Table(
        id: '6',
        number: 6,
        capacity: 8,
        status: models.TableStatus.occupied,
        customerName: 'Lê Văn C',
        customerPhone: '0345678912',
      ),
    ];
  }

  List<MenuItem> get filteredMenuItems {
    return menuItems.where((item) => 
      item.category == selectedCategory && item.isAvailable
    ).toList();
  }

  void _selectTable(String tableId) {
    setState(() {
      selectedTableId = tableId;
      currentOrder = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tableId: tableId,
        items: [],
      );
    });
  }

  void _addToOrder(MenuItem menuItem, {String? specialRequest}) {
    if (currentOrder != null) {
      setState(() {
        final orderItem = OrderItem(
          menuItem: menuItem,
          quantity: 1,
          specialRequest: specialRequest,
        );
        currentOrder!.addItem(orderItem);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn bàn trước khi order'),
        ),
      );
    }
  }

  void _updateItemQuantity(String menuItemId, int newQuantity) {
    if (currentOrder != null) {
      setState(() {
        currentOrder!.updateItemQuantity(menuItemId, newQuantity);
      });
    }
  }

  void _removeFromOrder(String menuItemId) {
    if (currentOrder != null) {
      setState(() {
        currentOrder!.removeItem(menuItemId);
      });
    }
  }

  void _submitOrder() {
    if (currentOrder != null && currentOrder!.items.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bàn: ${_getTableNumber(selectedTableId!)}'),
              Text('Tổng món: ${currentOrder!.totalItems}'),
              Text('Tổng tiền: ${_formatCurrency(currentOrder!.totalAmount)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _confirmOrder();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      );
    }
  }

  void _confirmOrder() {
    // Xử lý gửi order - trong thực tế sẽ gửi đến API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order đã được gửi đến bếp!'),
        backgroundColor: Colors.green,
      ),
    );
    
    setState(() {
      currentOrder = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tableId: selectedTableId!,
        items: [],
      );
    });
  }

  int _getTableNumber(String tableId) {
    final table = occupiedTables.firstWhere((t) => t.id == tableId);
    return table.number;
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order Món Ăn',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.restaurant_menu),
              text: 'Menu',
            ),
            Tab(
              icon: Icon(Icons.shopping_cart),
              text: 'Giỏ hàng',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Table selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn bàn:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: occupiedTables.map((table) {
                    final isSelected = selectedTableId == table.id;
                    return FilterChip(
                      label: Text('Bàn ${table.number}'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) _selectTable(table.id);
                      },
                      selectedColor: const Color(0xFF2E7D32).withOpacity(0.3),
                      checkmarkColor: const Color(0xFF2E7D32),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMenuTab(),
                _buildCartTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTab() {
    return Column(
      children: [
        // Category selector
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: MenuCategory.values.map((category) {
              final isSelected = selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_getCategoryName(category)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                  selectedColor: const Color(0xFF2E7D32).withOpacity(0.3),
                  checkmarkColor: const Color(0xFF2E7D32),
                ),
              );
            }).toList(),
          ),
        ),
        
        // Menu items
        Expanded(
          child: filteredMenuItems.isEmpty
              ? const Center(
                  child: Text(
                    'Không có món ăn nào trong danh mục này',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredMenuItems.length,
                  itemBuilder: (context, index) {
                    final menuItem = filteredMenuItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MenuItemCard(
                        menuItem: menuItem,
                        onAddToOrder: (item, specialRequest) {
                          _addToOrder(item, specialRequest: specialRequest);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCartTab() {
    if (currentOrder == null || currentOrder!.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Giỏ hàng trống',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            Text(
              'Thêm món từ menu để bắt đầu order',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: currentOrder!.items.length,
            itemBuilder: (context, index) {
              final item = currentOrder!.items[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF2E7D32),
                    child: Text(
                      item.quantity.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(item.menuItem.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatCurrency(item.menuItem.price)),
                      if (item.specialRequest != null)
                        Text(
                          'Ghi chú: ${item.specialRequest}',
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (item.quantity > 1) {
                            _updateItemQuantity(item.menuItem.id, item.quantity - 1);
                          } else {
                            _removeFromOrder(item.menuItem.id);
                          }
                        },
                        icon: const Icon(Icons.remove),
                      ),
                      Text(item.quantity.toString()),
                      IconButton(
                        onPressed: () {
                          _updateItemQuantity(item.menuItem.id, item.quantity + 1);
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Order summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng cộng:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatCurrency(currentOrder!.totalAmount),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedTableId != null ? _submitOrder : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    selectedTableId != null 
                        ? 'Gửi Order (${currentOrder!.totalItems} món)'
                        : 'Chọn bàn để order',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getCategoryName(MenuCategory category) {
    switch (category) {
      case MenuCategory.appetizer:
        return 'Khai vị';
      case MenuCategory.mainCourse:
        return 'Món chính';
      case MenuCategory.dessert:
        return 'Tráng miệng';
      case MenuCategory.beverage:
        return 'Đồ uống';
      case MenuCategory.soup:
        return 'Canh/Súp';
      case MenuCategory.salad:
        return 'Salad';
      case MenuCategory.seafood:
        return 'Hải sản';
      case MenuCategory.vegetarian:
        return 'Chay';
    }
  }
}