import 'package:flutter/material.dart';
import '../../../models/mon_an.dart';
import '../../../models/ban_an.dart';
import '../../../services/menu_service.dart';
import '../../../services/table_service.dart';
import '../services/dine_in_order_service.dart';
import '../models/dine_in_order.dart';
import 'package:qlnh_nhan_vien/utils/app_utils.dart';

class CreateDineInOrderPage extends StatefulWidget {
  const CreateDineInOrderPage({Key? key}) : super(key: key);

  @override
  State<CreateDineInOrderPage> createState() => _CreateDineInOrderPageState();
}

class _CreateDineInOrderPageState extends State<CreateDineInOrderPage> {
  final DineInOrderService _dineInOrderService = DineInOrderService();
  final MenuService _menuService = MenuService();
  final TableService _tableService = TableService();

  List<MonAn> _menuItems = [];
  List<BanAn> _tables = [];
  BanAn? _selectedTable;
  final Map<int, int> _selectedItems = {}; // monAnId -> soLuong
  final TextEditingController _ghiChuController = TextEditingController();

  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final menuItems = await _menuService.getMenuItems();
      final tables = await _tableService.getTables();

      setState(() {
        _menuItems = menuItems.where((item) => item.available).toList();
        _tables = tables;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  void _toggleMenuItem(int monAnId) {
    setState(() {
      if (_selectedItems.containsKey(monAnId)) {
        _selectedItems.remove(monAnId);
      } else {
        _selectedItems[monAnId] = 1;
      }
    });
  }

  void _updateQuantity(int monAnId, int delta) {
    setState(() {
      final currentQty = _selectedItems[monAnId] ?? 0;
      final newQty = currentQty + delta;
      if (newQty <= 0) {
        _selectedItems.remove(monAnId);
      } else {
        _selectedItems[monAnId] = newQty;
      }
    });
  }

  double _calculateTotal() {
    double total = 0;
    _selectedItems.forEach((monAnId, soLuong) {
      final menuItem = _menuItems.firstWhere((item) => item.id == monAnId);
      total += menuItem.gia * soLuong;
    });
    return total;
  }

  Future<void> _createOrder() async {
    if (_selectedTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn bàn')),
      );
      return;
    }

    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn món ăn')),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      final request = CreateDineInOrderRequest(
        banAnId: _selectedTable!.id,
        monAnList: _selectedItems.entries
            .map((entry) => OrderItem(monAnId: entry.key, soLuong: entry.value))
            .toList(),
        ghiChu: _ghiChuController.text,
      );

      final order = await _dineInOrderService.createDineInOrder(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo đơn thành công')),
        );
        Navigator.pop(context, order);
      }
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt món tại chỗ'),
        actions: [
          if (_selectedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () => _showCartDialog(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTableSelector(),
                const Divider(),
                Expanded(child: _buildMenuList()),
              ],
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildTableSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn bàn:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButton<BanAn>(
            isExpanded: true,
            value: _selectedTable,
            hint: const Text('-- Chọn bàn --'),
            items: _tables.map((table) {
              return DropdownMenuItem(
                value: table,
                child: Text(
                  'Bàn ${table.soBan} - ${table.getKhuVucText()} (${table.sucChua} người)',
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedTable = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList() {
    if (_menuItems.isEmpty) {
      return const Center(child: Text('Không có món ăn'));
    }

    return ListView.builder(
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        final isSelected = _selectedItems.containsKey(item.id);
        final quantity = _selectedItems[item.id] ?? 0;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: item.hinhAnh != null && item.hinhAnh!.isNotEmpty
                ? Image.network(
                    AppUtils.imageUrl(item.hinhAnh!),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.restaurant, size: 60),
                  )
                : const Icon(Icons.restaurant, size: 60),
            title: Text(item.tenMon),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.gia.toStringAsFixed(0)} VND'),
                if (item.moTa != null) Text(item.moTa!, maxLines: 2),
              ],
            ),
            trailing: isSelected
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _updateQuantity(item.id, -1),
                      ),
                      Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => _updateQuantity(item.id, 1),
                      ),
                    ],
                  )
                : IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: () => _toggleMenuItem(item.id),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    final total = _calculateTotal();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng cộng:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                '${total.toStringAsFixed(0)} VND',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCreating ? null : _createOrder,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
              child: _isCreating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Tạo đơn (${_selectedItems.length} món)',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Giỏ hàng'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _selectedItems.entries.map((entry) {
              final item = _menuItems.firstWhere((m) => m.id == entry.key);
              return ListTile(
                title: Text(item.tenMon),
                subtitle: Text('${item.gia.toStringAsFixed(0)} VND x ${entry.value}'),
                trailing: Text('${(item.gia * entry.value).toStringAsFixed(0)} VND'),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ghiChuController.dispose();
    super.dispose();
  }
}
