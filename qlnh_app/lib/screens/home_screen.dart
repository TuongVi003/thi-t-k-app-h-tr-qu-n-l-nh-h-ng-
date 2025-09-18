import 'package:flutter/material.dart';
import 'login_screen.dart';

// Data models
class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
  });
}

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({required this.menuItem, this.quantity = 1});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<CartItem> _cartItems = [];

  void _addToCart(MenuItem item) {
    setState(() {
      final existingItemIndex = _cartItems.indexWhere((cartItem) => cartItem.menuItem.id == item.id);
      if (existingItemIndex >= 0) {
        _cartItems[existingItemIndex].quantity++;
      } else {
        _cartItems.add(CartItem(menuItem: item));
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} đã được thêm vào giỏ hàng'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removeFromCart(String itemId) {
    setState(() {
      _cartItems.removeWhere((cartItem) => cartItem.menuItem.id == itemId);
    });
  }

  void _updateCartQuantity(String itemId, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        _removeFromCart(itemId);
      } else {
        final itemIndex = _cartItems.indexWhere((cartItem) => cartItem.menuItem.id == itemId);
        if (itemIndex >= 0) {
          _cartItems[itemIndex].quantity = newQuantity;
        }
      }
    });
  }

  double get _totalPrice {
    return _cartItems.fold(0.0, (total, cartItem) => total + (cartItem.menuItem.price * cartItem.quantity));
  }

  int get _cartItemCount {
    return _cartItems.fold(0, (total, cartItem) => total + cartItem.quantity);
  }

  List<Widget> get _widgetOptions {
    return [
      MenuTab(onAddToCart: _addToCart),
      CartTab(
        cartItems: _cartItems,
        onRemoveFromCart: _removeFromCart,
        onUpdateQuantity: _updateCartQuantity,
        totalPrice: _totalPrice,
      ),
      OrderHistoryTab(),
      ProfileTab(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nhà Hàng Delicious',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange.shade700,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedIndex = 1; // Navigate to cart
                  });
                },
                icon: const Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                ),
              ),
              if (_cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.account_circle,
              color: Colors.white,
            ),
            onSelected: (String value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Thông tin cá nhân'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Cài đặt'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Đăng xuất'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Giỏ hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Lịch sử',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange.shade700,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Hard-coded menu data
final List<MenuItem> _menuItems = [
  // Món chính
  MenuItem(
    id: '1',
    name: 'Phở Bò Tái',
    description: 'Phở bò tái thơm ngon với nước dùng đậm đà, bánh phở mềm',
    price: 85000,
    category: 'Món chính',
    imageUrl: 'assets/images/pho_bo.jpg',
  ),
  MenuItem(
    id: '2',
    name: 'Cơm Gà Teriyaki',
    description: 'Cơm gà teriyaki Nhật Bản với sốt đặc biệt và rau củ',
    price: 95000,
    category: 'Món chính',
    imageUrl: 'assets/images/com_ga.jpg',
  ),
  MenuItem(
    id: '3',
    name: 'Bún Chả Hà Nội',
    description: 'Bún chả truyền thống với chả nướng thơm phức',
    price: 75000,
    category: 'Món chính',
    imageUrl: 'assets/images/bun_cha.jpg',
  ),
  MenuItem(
    id: '4',
    name: 'Pizza Hải Sản',
    description: 'Pizza hải sản với tôm, mực, cua và phô mai mozzarella',
    price: 120000,
    category: 'Món chính',
    imageUrl: 'assets/images/pizza.jpg',
  ),
  MenuItem(
    id: '5',
    name: 'Mì Ý Sốt Kem',
    description: 'Mì Ý sốt kem với thịt gà và nấm',
    price: 89000,
    category: 'Món chính',
    imageUrl: 'assets/images/mi_y.jpg',
  ),
  
  // Đồ uống
  MenuItem(
    id: '6',
    name: 'Nước Cam Tươi',
    description: 'Nước cam tươi vắt 100% không đường',
    price: 25000,
    category: 'Đồ uống',
    imageUrl: 'assets/images/nuoc_cam.jpg',
  ),
  MenuItem(
    id: '7',
    name: 'Café Đen Đá',
    description: 'Café đen truyền thống đá viên',
    price: 20000,
    category: 'Đồ uống',
    imageUrl: 'assets/images/cafe_den.jpg',
  ),
  MenuItem(
    id: '8',
    name: 'Trà Sữa Trân Châu',
    description: 'Trà sữa trân châu đen thơm ngon',
    price: 35000,
    category: 'Đồ uống',
    imageUrl: 'assets/images/tra_sua.jpg',
  ),
  MenuItem(
    id: '9',
    name: 'Sinh Tố Bơ',
    description: 'Sinh tố bơ sáp ngon với sữa đặc',
    price: 30000,
    category: 'Đồ uống',
    imageUrl: 'assets/images/sinh_to_bo.jpg',
  ),
  
  // Món tráng miệng
  MenuItem(
    id: '10',
    name: 'Chè Bưởi',
    description: 'Chè bưởi truyền thống với nước cốt dừa',
    price: 18000,
    category: 'Tráng miệng',
    imageUrl: 'assets/images/che_buoi.jpg',
  ),
  MenuItem(
    id: '11',
    name: 'Kem Vani',
    description: 'Kem vani thơm ngon, mát lạnh',
    price: 22000,
    category: 'Tráng miệng',
    imageUrl: 'assets/images/kem_vani.jpg',
  ),
  MenuItem(
    id: '12',
    name: 'Bánh Flan',
    description: 'Bánh flan caramel mềm mịn',
    price: 25000,
    category: 'Tráng miệng',
    imageUrl: 'assets/images/banh_flan.jpg',
  ),
];

// Menu Tab
class MenuTab extends StatefulWidget {
  final Function(MenuItem) onAddToCart;

  const MenuTab({super.key, required this.onAddToCart});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  String _selectedCategory = 'Tất cả';
  final List<String> _categories = ['Tất cả', 'Món chính', 'Đồ uống', 'Tráng miệng'];

  List<MenuItem> get _filteredItems {
    if (_selectedCategory == 'Tất cả') {
      return _menuItems;
    }
    return _menuItems.where((item) => item.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Menu nhà hàng',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          // Category filter
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: Colors.orange.shade100,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.orange.shade700 : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // Menu items
          Expanded(
            child: ListView.builder(
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Menu item image placeholder
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.restaurant,
                            size: 40,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Menu item details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item.price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ₫',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => widget.onAddToCart(item),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange.shade700,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                    ),
                                    child: const Text('Thêm'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Cart Tab
class CartTab extends StatelessWidget {
  final List<CartItem> cartItems;
  final Function(String) onRemoveFromCart;
  final Function(String, int) onUpdateQuantity;
  final double totalPrice;

  const CartTab({
    super.key,
    required this.cartItems,
    required this.onRemoveFromCart,
    required this.onUpdateQuantity,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giỏ hàng',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          if (cartItems.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Giỏ hàng trống',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hãy thêm một số món ăn vào giỏ hàng',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final cartItem = cartItems[index];
                  final item = cartItem.menuItem;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.restaurant,
                              size: 30,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ₫',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => onUpdateQuantity(item.id, cartItem.quantity - 1),
                                icon: const Icon(Icons.remove_circle_outline),
                                color: Colors.grey.shade600,
                              ),
                              Text(
                                cartItem.quantity.toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () => onUpdateQuantity(item.id, cartItem.quantity + 1),
                                icon: const Icon(Icons.add_circle_outline),
                                color: Colors.orange.shade700,
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => onRemoveFromCart(item.id),
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red.shade400,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Total and checkout section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
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
                        '${totalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ₫',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement checkout
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Chức năng thanh toán đang được phát triển'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Đặt hàng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Order History Tab
class OrderHistoryTab extends StatelessWidget {
  const OrderHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lịch sử đặt hàng',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildOrderHistoryCard(
                  '#ORD001',
                  '18/09/2025 - 14:30',
                  'Đã giao',
                  250000,
                  ['Phở Bò Tái', 'Nước Cam Tươi'],
                ),
                _buildOrderHistoryCard(
                  '#ORD002',
                  '17/09/2025 - 12:15',
                  'Đã giao',
                  180000,
                  ['Cơm Gà Teriyaki'],
                ),
                _buildOrderHistoryCard(
                  '#ORD003',
                  '15/09/2025 - 19:20',
                  'Đã giao',
                  320000,
                  ['Pizza Hải Sản', 'Trà Sữa Trân Châu', 'Bánh Flan'],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHistoryCard(String orderNumber, String date, String status, double total, List<String> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đơn hàng $orderNumber',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              date,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Món: ${items.join(', ')}',
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng: ${total.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ₫',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Show order details
                  },
                  child: const Text('Xem chi tiết'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Profile Tab
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tài khoản',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          
          // Profile info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.orange.shade100,
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nguyễn Văn A',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'nguyenvana@email.com',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Menu options
          Expanded(
            child: ListView(
              children: [
                _buildMenuOption(Icons.person_outline, 'Thông tin cá nhân', () {}),
                _buildMenuOption(Icons.location_on_outlined, 'Địa chỉ giao hàng', () {}),
                _buildMenuOption(Icons.payment, 'Phương thức thanh toán', () {}),
                _buildMenuOption(Icons.notifications_outlined, 'Thông báo', () {}),
                _buildMenuOption(Icons.help_outline, 'Hỗ trợ', () {}),
                _buildMenuOption(Icons.info_outline, 'Về chúng tôi', () {}),
                const Divider(),
                _buildMenuOption(Icons.logout, 'Đăng xuất', () {}, textColor: Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption(IconData icon, String title, VoidCallback onTap, {Color? textColor}) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}