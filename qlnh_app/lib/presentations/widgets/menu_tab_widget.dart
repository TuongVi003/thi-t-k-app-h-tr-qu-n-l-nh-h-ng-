import 'package:flutter/material.dart';
import 'package:qlnh_app/models/model.dart';

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
