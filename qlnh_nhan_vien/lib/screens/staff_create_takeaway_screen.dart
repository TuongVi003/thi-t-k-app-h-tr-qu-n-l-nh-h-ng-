import 'package:flutter/material.dart';
import '../services/takeaway_service.dart';

class StaffCreateTakeawayScreen extends StatefulWidget {
  const StaffCreateTakeawayScreen({Key? key}) : super(key: key);

  @override
  State<StaffCreateTakeawayScreen> createState() => _StaffCreateTakeawayScreenState();
}

class _StaffCreateTakeawayScreenState extends State<StaffCreateTakeawayScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  // Customer type: 'registered' or 'guest'
  String _customerType = 'guest';
  int? _selectedCustomerId;
  DateTime? _pickupTime;
  
  final List<OrderItemInput> _items = [];
  bool _isSubmitting = false;

  // Mock menu items - trong thực tế nên lấy từ API
  final List<MenuItemSimple> _menuItems = [
    MenuItemSimple(id: 1, name: 'Gà quay', price: 170000),
    MenuItemSimple(id: 2, name: 'Gà Hầm Năng', price: 150000),
    MenuItemSimple(id: 3, name: 'Vịt quay Bắc Kinh', price: 300000),
    MenuItemSimple(id: 6, name: 'Bánh kem dâu tây', price: 150000),
    MenuItemSimple(id: 13, name: 'Thịt bò xào rau cần', price: 200000),
    MenuItemSimple(id: 14, name: 'Chả ram', price: 120000),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(OrderItemInput(monAnId: _menuItems[0].id, soLuong: 1));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _updateItemQuantity(int index, int quantity) {
    if (quantity > 0) {
      setState(() {
        _items[index].soLuong = quantity;
      });
    }
  }

  void _updateItemDish(int index, int monAnId) {
    setState(() {
      _items[index].monAnId = monAnId;
    });
  }

  Future<void> _selectPickupTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null && mounted) {
        setState(() {
          _pickupTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất 1 món')),
      );
      return;
    }

    // Validate customer info
    if (_customerType == 'guest') {
      if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin khách hàng')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final monAnList = _items.map((item) => {
        'mon_an_id': item.monAnId,
        'so_luong': item.soLuong,
      }).toList();

      await TakeawayService.staffCreateOrder(
        khachHangId: _customerType == 'registered' ? _selectedCustomerId : null,
        khachHoTen: _customerType == 'guest' ? _nameController.text.trim() : null,
        khachSoDienThoai: _customerType == 'guest' ? _phoneController.text.trim() : null,
        monAnList: monAnList,
        ghiChu: _noteController.text.trim(),
        thoiGianKhachLay: _pickupTime,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo đơn mang về thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _calculateTotal() {
    double total = 0;
    for (var item in _items) {
      final menu = _menuItems.firstWhere((m) => m.id == item.monAnId);
      total += menu.price * item.soLuong;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo đơn mang về'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Customer type selector
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Loại khách hàng',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('Khách vãng lai'),
                                    value: 'guest',
                                    groupValue: _customerType,
                                    onChanged: (value) {
                                      setState(() {
                                        _customerType = value!;
                                      });
                                    },
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                // Expanded(
                                //   child: RadioListTile<String>(
                                //     title: const Text('Khách đăng ký'),
                                //     value: 'registered',
                                //     groupValue: _customerType,
                                //     onChanged: (value) {
                                //       setState(() {
                                //         _customerType = value!;
                                //       });
                                //     },
                                //     dense: true,
                                //     contentPadding: EdgeInsets.zero,
                                //   ),
                                // ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Customer info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thông tin khách hàng',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_customerType == 'guest') ...[
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Tên khách hàng *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Vui lòng nhập tên';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Số điện thoại *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.phone),
                                  hintText: '0987654321',
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Vui lòng nhập số điện thoại';
                                  }
                                  if (!RegExp(r'^0\d{9}$').hasMatch(value.trim())) {
                                    return 'Số điện thoại không hợp lệ';
                                  }
                                  return null;
                                },
                              ),
                            ] else ...[
                              // TODO: Implement customer search/selection
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Chức năng tìm khách hàng đang phát triển...',
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Pickup time
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.access_time, color: Color(0xFF2E7D32)),
                        title: const Text('Thời gian lấy món (tùy chọn)'),
                        subtitle: Text(
                          _pickupTime != null
                              ? '${_pickupTime!.day}/${_pickupTime!.month} ${_pickupTime!.hour}:${_pickupTime!.minute.toString().padLeft(2, '0')}'
                              : 'Chưa chọn',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _selectPickupTime,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Order items
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Danh sách món',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _addItem,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Thêm món'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_items.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Icon(Icons.restaurant_menu,
                                          size: 64, color: Colors.grey.shade300),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Chưa có món nào',
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ...List.generate(_items.length, (index) {
                                final item = _items[index];
                                final selectedMenu = _menuItems.firstWhere(
                                  (m) => m.id == item.monAnId,
                                );

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Món ${index + 1}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            icon: const Icon(Icons.delete, size: 20),
                                            onPressed: () => _removeItem(index),
                                            color: Colors.red,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<int>(
                                        value: item.monAnId,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                        ),
                                        items: _menuItems.map((menu) {
                                          return DropdownMenuItem(
                                            value: menu.id,
                                            child: Text(
                                              '${menu.name} - ${(menu.price / 1000).toStringAsFixed(0)}k',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          if (value != null) {
                                            _updateItemDish(index, value);
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Text('SL:', style: TextStyle(fontSize: 13)),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                                            onPressed: item.soLuong > 1
                                                ? () => _updateItemQuantity(index, item.soLuong - 1)
                                                : null,
                                            color: Colors.red,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade300),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${item.soLuong}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline, size: 20),
                                            onPressed: () => _updateItemQuantity(index, item.soLuong + 1),
                                            color: Colors.green,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${((selectedMenu.price * item.soLuong) / 1000).toStringAsFixed(0)}k',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade700,
                                              ),
                                              textAlign: TextAlign.right,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Note
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextFormField(
                          controller: _noteController,
                          decoration: const InputDecoration(
                            labelText: 'Ghi chú (tùy chọn)',
                            border: OutlineInputBorder(),
                            hintText: 'Ví dụ: Không hành, nhiều rau...',
                          ),
                          maxLines: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom bar with total and submit button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (_items.isNotEmpty)
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
                          '${(_calculateTotal() / 1000).toStringAsFixed(0)}k VND',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  if (_items.isNotEmpty) const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Tạo đơn',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderItemInput {
  int monAnId;
  int soLuong;

  OrderItemInput({required this.monAnId, required this.soLuong});
}

class MenuItemSimple {
  final int id;
  final String name;
  final double price;

  MenuItemSimple({required this.id, required this.name, required this.price});
}
