import 'package:flutter/material.dart';
import '../../../models/model.dart';
import '../../../constants/app_colors.dart';
import 'menu_tab_page.dart';
import '../../screens/cart_page.dart';

class TakeawayOrderScreen extends StatefulWidget {
  const TakeawayOrderScreen({super.key});

  @override
  State<TakeawayOrderScreen> createState() => _TakeawayOrderScreenState();
}

class _TakeawayOrderScreenState extends State<TakeawayOrderScreen> {
  List<CartItem> _cartItems = [];
  int _selectedTab = 0;

  void _addToCart(MenuItem item) {
    setState(() {
      final existingItemIndex = _cartItems.indexWhere(
        (cartItem) => cartItem.menuItem.id == item.id,
      );
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
        backgroundColor: AppColors.success,
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
        final itemIndex = _cartItems.indexWhere(
          (cartItem) => cartItem.menuItem.id == itemId,
        );
        if (itemIndex >= 0) {
          _cartItems[itemIndex].quantity = newQuantity;
        }
      }
    });
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
    });
  }

  double get _totalPrice {
    return _cartItems.fold(
      0.0,
      (total, cartItem) => total + (cartItem.menuItem.price * cartItem.quantity),
    );
  }

  int get _cartItemCount {
    return _cartItems.fold(0, (total, cartItem) => total + cartItem.quantity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt hàng mang về'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedTab = 1;
                  });
                },
                icon: const Icon(Icons.shopping_cart),
              ),
              if (_cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _cartItemCount > 99 ? '99+' : _cartItemCount.toString(),
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _selectedTab == 0
          ? MenuTab(onAddToCart: _addToCart)
          : CartTab(
              cartItems: _cartItems,
              onRemoveFromCart: _removeFromCart,
              onUpdateQuantity: _updateCartQuantity,
              totalPrice: _totalPrice,
              onClearCart: _clearCart,
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) {
          setState(() {
            _selectedTab = index;
          });
        },
        selectedItemColor: AppColors.primary,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (_cartItemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        _cartItemCount > 9 ? '9+' : _cartItemCount.toString(),
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Giỏ hàng',
          ),
        ],
      ),
    );
  }
}
