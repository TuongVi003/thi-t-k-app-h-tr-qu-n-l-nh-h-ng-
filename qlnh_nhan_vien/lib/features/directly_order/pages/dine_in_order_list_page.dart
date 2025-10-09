import 'package:flutter/material.dart';
import '../models/dine_in_order.dart';
import '../services/dine_in_order_service.dart';
import 'dine_in_order_detail_page.dart';
import 'create_dine_in_order_page.dart';

class DineInOrderListPage extends StatefulWidget {
  const DineInOrderListPage({Key? key}) : super(key: key);

  @override
  State<DineInOrderListPage> createState() => _DineInOrderListPageState();
}

class _DineInOrderListPageState extends State<DineInOrderListPage> {
  final DineInOrderService _service = DineInOrderService();
  List<DineInOrder> _orders = [];
  bool _isLoading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _service.getDineInOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  List<DineInOrder> get _filteredOrders {
    if (_filterStatus == 'all') return _orders;
    return _orders.where((order) => order.trangThai == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn ăn tại chỗ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                    ? const Center(child: Text('Không có đơn hàng'))
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.builder(
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                            return _buildOrderCard(order);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateDineInOrderPage(),
            ),
          );
          if (result != null) {
            _loadOrders();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Tạo đơn mới'),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Tất cả', 'all'),
            _buildFilterChip('Chờ xác nhận', 'pending'),
            _buildFilterChip('Đã xác nhận', 'confirmed'),
            _buildFilterChip('Đang nấu', 'cooking'),
            _buildFilterChip('Sẵn sàng', 'ready'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String status) {
    final isSelected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filterStatus = status);
        },
        selectedColor: Colors.blue.shade200,
      ),
    );
  }

  Widget _buildOrderCard(DineInOrder order) {
    Color statusColor = _getStatusColor(order.trangThai);
    IconData statusIcon = _getStatusIcon(order.trangThai);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          'Bàn ${order.banAnSoBan ?? "N/A"} - #${order.id}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trạng thái: ${order.getTrangThaiText()}'),
            Text('Tổng tiền: ${order.tongTien.toStringAsFixed(0)} VND'),
            Text('NV: ${order.nhanVienHoTen}'),
            if (order.thoiGianLay != null)
              Text('Thời gian: ${order.thoiGianLay} phút'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DineInOrderDetailPage(orderId: order.id),
            ),
          );
          if (result == true) {
            _loadOrders();
          }
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'cooking':
        return Colors.purple;
      case 'ready':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'cooking':
        return Icons.restaurant;
      case 'ready':
        return Icons.done_all;
      case 'completed':
        return Icons.check;
      case 'canceled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}
