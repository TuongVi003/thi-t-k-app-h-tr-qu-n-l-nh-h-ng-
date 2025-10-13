import 'package:flutter/material.dart';
import 'package:qlnh_app/models/model.dart';
import 'package:qlnh_app/services/menu_service.dart';
import 'package:qlnh_app/constants/app_colors.dart';
import 'takeaway_status_widget.dart';

class MenuTab extends StatefulWidget {
  final Function(MenuItem) onAddToCart;

  const MenuTab({super.key, required this.onAddToCart});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  int? _selectedCategory; // null nghĩa là tất cả danh mục
  final List<DanhMuc> _categories = [];
  List<MonAn> _menuItems = [];
  bool _isLoadingCategories = true;
  bool _isLoadingMenuItems = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchMenuItems();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await MenuService.layDanhSachDanhMuc();
      setState(() {
        _categories.clear();
        _categories.addAll(categories);
        _isLoadingCategories = false;
      });
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _fetchMenuItems({int? categoryId}) async {
    setState(() {
      _isLoadingMenuItems = true;
    });

    try {
      final menuItems = await MenuService.layDanhSachMonAn(categoryId: categoryId);
      setState(() {
        _menuItems = menuItems;
        _isLoadingMenuItems = false;
      });
    } catch (e) {
      print('Error fetching menu items: $e');
      setState(() {
        _isLoadingMenuItems = false;
      });
    }
  }

  void _addToCart(MonAn item) {
    // Convert MonAn to MenuItem và gọi callback
    final menuItem = MenuItem(
      id: item.id.toString(),
      name: item.tenMon,
      description: item.moTa,
      price: item.gia,
      category: item.tenDanhMuc ?? '',
      imageUrl: item.hinhAnh ?? '',
    );
    
    widget.onAddToCart(menuItem);
    
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('${item.tenMon} đã được thêm vào giỏ hàng mang về'),
    //     duration: const Duration(seconds: 1),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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

          // Takeaway status widget
          const TakeawayStatusWidget(),

          // Info banner (no separate cart, use main cart from HomeScreen)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.infoBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.infoLight,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.takeout_dining,
                  color: AppColors.info,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đặt món mang về',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.info,
                        ),
                      ),
                      Text(
                        'Thêm món vào giỏ hàng và thanh toán',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Category filter
          SizedBox(
            height: 40,
            child: _isLoadingCategories
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length + 1, // +1 for "Tất cả" option
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // "Tất cả" option
                        final isSelected = _selectedCategory == null;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: const Text('Tất cả'),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected && _selectedCategory != null) {
                                setState(() {
                                  _selectedCategory = null;
                                });
                                _fetchMenuItems();
                              }
                            },
                            backgroundColor: AppColors.chipBackground,
                            selectedColor: AppColors.chipSelectedBackground,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.chipSelectedText
                                  : AppColors.chipText,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }

                      final category = _categories[index - 1];
                      final isSelected = _selectedCategory == category.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(category.tenDanhMuc),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected && _selectedCategory != category.id) {
                              setState(() {
                                _selectedCategory = category.id;
                              });
                              _fetchMenuItems(categoryId: category.id);
                            }
                          },
                          backgroundColor: AppColors.chipBackground,
                          selectedColor: AppColors.chipSelectedBackground,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.chipSelectedText
                                : AppColors.chipText,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),

          // Menu items
          _isLoadingMenuItems
              ? const Center(child: CircularProgressIndicator())
              : _menuItems.isEmpty
                  ? const Center(
                      child: Text(
                        'Không có món ăn nào',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _menuItems.length,
                      itemBuilder: (context, index) {
                        final item = _menuItems[index];

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
                                // Menu item image
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryVeryLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: item.hinhAnh != null && item.hinhAnh!.isNotEmpty
                                        ? Builder(
                                            builder: (context) {
                                              final imageUrl = 'https://d9p0zhfk-8000.asse.devtunnels.ms/images/${item.hinhAnh!}';
                                              return Image.network(
                                                imageUrl,
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  print('Image load error: $error');
                                                  return const Icon(
                                                    Icons.restaurant,
                                                    size: 40,
                                                    color: AppColors.primary,
                                                  );
                                                },
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) {
                                                    print('Image loaded successfully: $imageUrl');
                                                    return child;
                                                  }
                                                  return const Center(
                                                    child: CircularProgressIndicator(
                                                      value: null,
                                                      strokeWidth: 2,
                                                      color: AppColors.primary,
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          )
                                        : const Icon(
                                            Icons.restaurant,
                                            size: 40,
                                            color: AppColors.primary,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Menu item details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.tenMon,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.moTa,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${item.gia.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ₫',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.accent,
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => _addToCart(item),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.accent,
                                              foregroundColor: AppColors.textWhite,
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
        ],
      ),
    );
  }
}
