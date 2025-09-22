import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'reservation_screen.dart';
import '../../models/model.dart';
import '../widgets/menu_tab_widget.dart';
import 'cart_page.dart';
import 'order_history_page.dart';
import 'profile_page.dart';


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
    // Allow navigation between tabs for guests; protect sensitive actions instead.
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
                  _onItemTapped(1);
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
              } else if (value == 'reservation') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReservationScreen()),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'reservation',
                child: ListTile(
                  leading: Icon(Icons.event_seat),
                  title: Text('Đặt bàn'),
                ),
              ),
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

