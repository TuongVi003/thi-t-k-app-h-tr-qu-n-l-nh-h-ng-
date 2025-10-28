import 'package:flutter/material.dart';
import '../services/takeaway_service.dart';
import '../services/menu_service.dart';
import '../models/mon_an.dart';

class CreateTakeawayOrderScreen extends StatefulWidget {
  const CreateTakeawayOrderScreen({super.key});

  @override
  State<CreateTakeawayOrderScreen> createState() => _CreateTakeawayOrderScreenState();
}

class _CreateTakeawayOrderScreenState extends State<CreateTakeawayOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  DateTime? _pickupTime;
  String _deliveryMethod = 'Tự đến lấy';
  
  final List<OrderItemInput> _items = [];
  bool _isSubmitting = false;
  bool _isLoadingMenu = true;

  List<MonAn> _menuItems = [];

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    try {
      final menuService = MenuService();
      final items = await menuService.getMenuItems();
      setState(() {
        _menuItems = items.where((item) => item.available).toList();
        _isLoadingMenu = false;
      });
    } catch (e) {
      setState(() => _isLoadingMenu = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải menu: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_menuItems.isEmpty) return;
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

    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin khách hàng')),
      );
      return;
    }

    if (_deliveryMethod == 'Giao hàng tận nơi' && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập địa chỉ giao hàng')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final monAnList = _items.map((item) => {
        'mon_an_id': item.monAnId,
        'so_luong': item.soLuong,
      }).toList();

      await TakeawayService.staffCreateOrder(
        khachHoTen: _nameController.text.trim(),
        khachSoDienThoai: _phoneController.text.trim(),
        monAnList: monAnList,
        ghiChu: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        thoiGianKhachLay: _pickupTime,
        phuongThucGiaoHang: _deliveryMethod,
        diaChiGiaoHang: _deliveryMethod == 'Giao hàng tận nơi' ? _addressController.text.trim() : null,
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
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '').replaceAll('Lỗi tạo đơn: ', '')}'),
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
      total += menu.gia * item.soLuong;
    }
    return total;
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tạo đơn mang về',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingMenu
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải menu...'),
                ],
              ),
            )
          : _menuItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Không có món ăn nào',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadMenu,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Customer info
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.person, color: Colors.green),
                                          SizedBox(width: 8),
                                          Text(
                                            'Thông tin khách hàng',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _nameController,
                                        decoration: const InputDecoration(
                                          labelText: 'Tên khách hàng *',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.person_outline),
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
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Pickup time
                              Card(
                                child: ListTile(
                                  leading: const Icon(Icons.access_time, color: Colors.green),
                                  title: const Text('Thời gian lấy món'),
                                  subtitle: Text(
                                    _pickupTime != null
                                        ? '${_pickupTime!.day}/${_pickupTime!.month} ${_pickupTime!.hour}:${_pickupTime!.minute.toString().padLeft(2, '0')}'
                                        : 'Chưa chọn (tùy chọn)',
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: _selectPickupTime,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Delivery method
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.local_shipping, color: Colors.green),
                                          SizedBox(width: 8),
                                          Text(
                                            'Phương thức giao hàng',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      RadioListTile<String>(
                                        title: const Text('Tự đến lấy'),
                                        value: 'Tự đến lấy',
                                        groupValue: _deliveryMethod,
                                        onChanged: (value) {
                                          setState(() {
                                            _deliveryMethod = value!;
                                            _addressController.clear();
                                          });
                                        },
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      RadioListTile<String>(
                                        title: const Text('Giao hàng tận nơi'),
                                        value: 'Giao hàng tận nơi',
                                        groupValue: _deliveryMethod,
                                        onChanged: (value) {
                                          setState(() {
                                            _deliveryMethod = value!;
                                          });
                                        },
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      if (_deliveryMethod == 'Giao hàng tận nơi') ...[
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: _addressController,
                                          decoration: const InputDecoration(
                                            labelText: 'Địa chỉ giao hàng *',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(Icons.location_on),
                                            hintText: 'Nhập địa chỉ giao hàng',
                                          ),
                                          maxLines: 2,
                                          validator: (value) {
                                            if (_deliveryMethod == 'Giao hàng tận nơi' && 
                                                (value == null || value.trim().isEmpty)) {
                                              return 'Vui lòng nhập địa chỉ giao hàng';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
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
                                          Row(
                                            children: const [
                                              Icon(Icons.restaurant_menu, color: Colors.green),
                                              SizedBox(width: 8),
                                              Text(
                                                'Danh sách món',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          TextButton.icon(
                                            onPressed: _addItem,
                                            icon: const Icon(Icons.add),
                                            label: const Text('Thêm'),
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
                                                    size: 48, color: Colors.grey.shade300),
                                                const SizedBox(height: 12),
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
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: DropdownButtonFormField<int>(
                                                        value: item.monAnId,
                                                        decoration: const InputDecoration(
                                                          labelText: 'Món ăn',
                                                          border: OutlineInputBorder(),
                                                          isDense: true,
                                                        ),
                                                        items: _menuItems.map((menu) {
                                                          return DropdownMenuItem(
                                                            value: menu.id,
                                                            child: Text(
                                                              '${menu.tenMon} - ${_formatCurrency(menu.gia)}đ',
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          );
                                                        }).toList(),
                                                        onChanged: (value) {
                                                          if (value != null) {
                                                            _updateItemDish(index, value);
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    IconButton(
                                                      onPressed: () => _removeItem(index),
                                                      icon: const Icon(Icons.delete, color: Colors.red),
                                                      tooltip: 'Xóa',
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    const Text('Số lượng:'),
                                                    const SizedBox(width: 12),
                                                    IconButton(
                                                      onPressed: item.soLuong > 1
                                                          ? () => _updateItemQuantity(index, item.soLuong - 1)
                                                          : null,
                                                      icon: const Icon(Icons.remove_circle_outline),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                      decoration: BoxDecoration(
                                                        border: Border.all(color: Colors.grey),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        '${item.soLuong}',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      onPressed: () => _updateItemQuantity(index, item.soLuong + 1),
                                                      icon: const Icon(Icons.add_circle_outline),
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                      '${_formatCurrency(selectedMenu.gia * item.soLuong)}đ',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.green,
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
                                      prefixIcon: Icon(Icons.note),
                                    ),
                                    maxLines: 3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom bar
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
                                    '${_formatCurrency(_calculateTotal())}đ',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
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
                                  backgroundColor: Colors.green,
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
