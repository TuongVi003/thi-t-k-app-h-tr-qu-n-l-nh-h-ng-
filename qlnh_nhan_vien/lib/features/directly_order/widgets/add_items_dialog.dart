import 'package:flutter/material.dart';
import '../models/dine_in_order.dart';
import '../services/dine_in_order_service.dart';
import '../../../services/menu_service.dart';
import '../../../models/mon_an.dart';

class AddItemsDialog extends StatefulWidget {
  final int orderId;
  final VoidCallback onSuccess;

  const AddItemsDialog({
    Key? key,
    required this.orderId,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<AddItemsDialog> createState() => _AddItemsDialogState();
}

class _AddItemsDialogState extends State<AddItemsDialog> {
  final DineInOrderService _service = DineInOrderService();
  final List<OrderItemInput> _items = [];
  bool _isSubmitting = false;
  bool _isLoadingMenu = true;

  // Danh sách món ăn từ API
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

  Future<void> _submitAddItems() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất 1 món')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final orderItems = _items
          .map((item) => OrderItem(monAnId: item.monAnId, soLuong: item.soLuong))
          .toList();

      final result = await _service.addItemsToOrder(widget.orderId, orderItems);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Đã thêm món thành công'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess();
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 500,
        ),
        child: _isLoadingMenu
            ? const Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang tải menu...'),
                  ],
                ),
              )
            : _menuItems.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restaurant_menu,
                            size: 64, color: Colors.grey.shade300),
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
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_shopping_cart, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thêm món vào đơn',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Đơn #${widget.orderId}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_items.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 32),
                            Icon(Icons.restaurant_menu,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có món nào',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _addItem,
                              icon: const Icon(Icons.add),
                              label: const Text('Thêm món'),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      )
                    else
                      ...List.generate(_items.length, (index) {
                        final item = _items[index];
                        final selectedMenu = _menuItems.firstWhere(
                          (m) => m.id == item.monAnId,
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
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
                                      icon: const Icon(Icons.delete,
                                          size: 20, color: Colors.red),
                                      onPressed: () => _removeItem(index),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<int>(
                                  value: item.monAnId,
                                  decoration: const InputDecoration(
                                    labelText: 'Chọn món',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  items: _menuItems.map((menu) {
                                    String priceText = menu.gia >= 1000 
                                        ? '${(menu.gia / 1000).toStringAsFixed(0)}k'
                                        : '${menu.gia.toStringAsFixed(0)}';
                                    return DropdownMenuItem(
                                      value: menu.id,
                                      child: Text(
                                        '${menu.tenMon} - $priceText VND',
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
                                    const Text('SL:',
                                        style: TextStyle(fontSize: 13)),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                                      onPressed: item.soLuong > 1
                                          ? () => _updateItemQuantity(
                                              index, item.soLuong - 1)
                                          : null,
                                      color: Colors.red,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade300),
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
                                      onPressed: () => _updateItemQuantity(
                                          index, item.soLuong + 1),
                                      color: Colors.green,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        () {
                                          final total = selectedMenu.gia * item.soLuong;
                                          return total >= 1000 
                                              ? '${(total / 1000).toStringAsFixed(0)}k'
                                              : '${total.toStringAsFixed(0)}';
                                        }(),
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
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                children: [
                  if (_items.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tổng cộng:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            () {
                              final total = _calculateTotal();
                              return total >= 1000 
                                  ? '${(total / 1000).toStringAsFixed(0)}k VND'
                                  : '${total.toStringAsFixed(0)} VND';
                            }(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      if (_items.isNotEmpty)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm món khác'),
                          ),
                        ),
                      if (_items.isNotEmpty) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitAddItems,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(_isSubmitting
                              ? 'Đang xử lý...'
                              : 'Xác nhận thêm'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
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
  }

  double _calculateTotal() {
    double total = 0;
    for (var item in _items) {
      final menu = _menuItems.firstWhere((m) => m.id == item.monAnId);
      total += menu.gia * item.soLuong;
    }
    return total;
  }
}

class OrderItemInput {
  int monAnId;
  int soLuong;

  OrderItemInput({required this.monAnId, required this.soLuong});
}
