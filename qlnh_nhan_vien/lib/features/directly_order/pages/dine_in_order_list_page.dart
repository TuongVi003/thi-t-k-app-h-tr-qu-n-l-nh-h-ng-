import 'package:flutter/material.dart';
import '../models/dine_in_order.dart';
import '../services/dine_in_order_service.dart';
import '../widgets/add_items_dialog.dart';
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
    
    // Format thời gian đặt hàng
    String formattedTime = '${order.orderTime.day.toString().padLeft(2, '0')}/'
        '${order.orderTime.month.toString().padLeft(2, '0')} '
        '${order.orderTime.hour.toString().padLeft(2, '0')}:'
        '${order.orderTime.minute.toString().padLeft(2, '0')}';
    
    // Format số tiền
    String formattedPrice = order.tongTien >= 1000 
        ? '${(order.tongTien / 1000).toStringAsFixed(0)}k'
        : '${order.tongTien.toStringAsFixed(0)}';

    // Kiểm tra xem có thể thêm món không (chỉ pending/confirmed/cooking)
    bool canAddItems = ['pending', 'confirmed', 'cooking'].contains(order.trangThai);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: InkWell(
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Bàn + Trạng thái
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.table_restaurant, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Bàn ${order.banAnSoBan}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            order.getTrangThaiText(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    '#${order.id}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              // Thông tin chi tiết
              Row(
                children: [
                  // Cột trái: thời gian và số món
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.restaurant_menu, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              '${order.chiTietOrder.length} món',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        if (order.thoiGianLay != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.timer, size: 14, color: Colors.orange.shade600),
                              const SizedBox(width: 4),
                              Text(
                                '${order.thoiGianLay} phút',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Cột phải: giá + nhân viên
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$formattedPrice VND',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (order.nhanVienHoTen.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person, size: 12, color: Colors.grey.shade600),
                              const SizedBox(width: 2),
                              Text(
                                order.nhanVienHoTen,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              // Nút thêm món (nếu đơn chưa hoàn thành)
              if (canAddItems) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddItemsDialog(order),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Thêm món'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade700,
                          side: BorderSide(color: Colors.blue.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAddItemsDialog(DineInOrder order) {
    showDialog(
      context: context,
      builder: (context) => AddItemsDialog(
        orderId: order.id,
        onSuccess: _loadOrders,
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
