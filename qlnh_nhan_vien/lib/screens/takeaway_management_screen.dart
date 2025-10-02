import 'package:flutter/material.dart';
import '../models/takeaway_order.dart';
import '../services/takeaway_service.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'takeaway_order_detail_screen.dart';

class TakeawayManagementScreen extends StatefulWidget {
  const TakeawayManagementScreen({super.key});

  @override
  State<TakeawayManagementScreen> createState() => _TakeawayManagementScreenState();
}

class _TakeawayManagementScreenState extends State<TakeawayManagementScreen> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  List<TakeawayOrder> orders = [];
  bool isLoading = true;
  String? error;
  User? currentUser;
  bool isWorkingShift = false;
  DateTime? _lastRefreshTime;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentUser();
    _loadOrders();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload user data when app returns to foreground
      _refreshUserFromServerIfNeeded();
    }
  }

  // Only refresh if it's been more than 2 seconds since last refresh
  Future<void> _refreshUserFromServerIfNeeded() async {
    final now = DateTime.now();
    if (_lastRefreshTime == null || 
        now.difference(_lastRefreshTime!).inSeconds >= 2) {
      _lastRefreshTime = now;
      await _refreshUserFromServer();
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await AuthService.getStoredUser();
      if (mounted) {
        setState(() {
          currentUser = user;
          isWorkingShift = user?.dangLamViec ?? false;
        });
        print('User data loaded from storage: dangLamViec = ${user?.dangLamViec}');
      }
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  Future<void> _refreshUserFromServer() async {
    try {
      print('Refreshing user data from server...');
      // Refresh user profile from server to get latest data
      final updatedUser = await AuthService.refreshUserProfile();
      if (updatedUser != null && mounted) {
        setState(() {
          currentUser = updatedUser;
          isWorkingShift = updatedUser.dangLamViec;
        });
        print('✅ User data refreshed from server: dangLamViec = ${updatedUser.dangLamViec}');
      }
    } catch (e) {
      print('❌ Error refreshing user from server: $e');
    }
  }



  Future<void> _loadOrders() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final loadedOrders = await TakeawayService.getTakeawayOrders();
      
      setState(() {
        orders = loadedOrders;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }



  Future<void> _acceptOrder(TakeawayOrder order) async {
    if (!isWorkingShift) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần vào ca làm việc để nhận đơn')),
      );
      return;
    }

    try {
      await TakeawayService.acceptOrder(order.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã nhận đơn thành công')),
      );
      await _loadOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi nhận đơn: ${e.toString()}')),
      );
    }
  }

  Future<void> _confirmTime(TakeawayOrder order) async {
    final timeController = TextEditingController();
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thời gian lấy món'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Đơn hàng #${order.id}'),
            const SizedBox(height: 16),
            TextField(
              controller: timeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Thời gian (phút)',
                border: OutlineInputBorder(),
                suffixText: 'phút',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final time = int.tryParse(timeController.text);
              if (time != null && time > 0) {
                Navigator.pop(context, time);
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await TakeawayService.confirmTime(order.id, result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xác nhận thời gian thành công')),
        );
        await _loadOrders();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xác nhận thời gian: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _updateStatus(TakeawayOrder order, TakeawayOrderStatus status) async {
    try {
      await TakeawayService.updateStatus(order.id, status);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật trạng thái thành công')),
      );
      await _loadOrders();
    } catch (e) {
      print('Error updating status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật trạng thái: ${e.toString()}')),
      );
    }
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
        return Colors.teal;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildOrderCard(TakeawayOrder order) {
    final canAccept = order.trangThai == 'pending' && isWorkingShift;
    final canConfirmTime = order.trangThai == 'confirmed' && 
                          order.nhanVienDetail?.id == currentUser?.id;
    final canMarkReady = order.trangThai == 'cooking' && 
                        currentUser?.chucVu == 'chef';
    final canComplete = order.trangThai == 'ready';

    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TakeawayOrderDetailScreen(order: order),
            ),
          ).then((_) => _loadOrders()); // Refresh khi quay lại
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đơn #${order.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.trangThai),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.trangThaiDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Customer info
              if (order.khachHangDetail != null) ...[
                Row(
                  children: [
                    const Icon(Icons.person, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${order.khachHangDetail!.hoTen} - ${order.khachHangDetail!.soDienThoai}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Staff info
              if (order.nhanVienDetail != null) ...[
                Row(
                  children: [
                    const Icon(Icons.badge, size: 16),
                    const SizedBox(width: 8),
                    Text('NV: ${order.nhanVienDetail!.hoTen}'),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Time info
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 8),
                  Text('Đặt lúc: ${_formatDateTime(order.orderTime)}'),
                ],
              ),
              
              if (order.thoiGianLay != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 16),
                    const SizedBox(width: 8),
                    Text('Thời gian lấy: ${order.thoiGianLayDisplay}'),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Order items
              const Text(
                'Món ăn:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...order.chiTietOrder.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('${item.soLuong}x ${item.monAnDetail.tenMon}'),
                    ),
                    Text(
                      '${(item.thanhTien).toStringAsFixed(0)}đ',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )),

              const Divider(),
              
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng cộng:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '${order.tongTien.toStringAsFixed(0)}đ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              // Notes
              if (order.ghiChu != null && order.ghiChu!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Ghi chú: ${order.ghiChu}',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Action buttons
              Wrap(
                spacing: 8,
                children: [
                  if (canAccept)
                    ElevatedButton.icon(
                      onPressed: () => _acceptOrder(order),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Nhận đơn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  
                  if (canConfirmTime)
                    ElevatedButton.icon(
                      onPressed: () => _confirmTime(order),
                      icon: const Icon(Icons.schedule, size: 16),
                      label: const Text('Xác nhận thời gian'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),

                  if (canMarkReady)
                    ElevatedButton.icon(
                      onPressed: () => _updateStatus(order, TakeawayOrderStatus.ready),
                      icon: const Icon(Icons.restaurant, size: 16),
                      label: const Text('Món sẵn sàng'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),

                  if (canComplete)
                    ElevatedButton.icon(
                      onPressed: () => _updateStatus(order, TakeawayOrderStatus.completed),
                      icon: const Icon(Icons.done_all, size: 16),
                      label: const Text('Hoàn thành'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    // Refresh user data when this screen becomes visible (but with throttling)
    _refreshUserFromServerIfNeeded();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đơn mang về'),
        actions: [
          IconButton(
            onPressed: () {
              _lastRefreshTime = null; // Force refresh
              _refreshUserFromServer();
              _loadOrders();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: isWorkingShift ? Colors.green.shade100 : Colors.red.shade100,
            child: Row(
              children: [
                Icon(
                  isWorkingShift ? Icons.work : Icons.work_off,
                  color: isWorkingShift ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  isWorkingShift ? 'Đang trong ca làm việc' : 'Chưa vào ca làm việc',
                  style: TextStyle(
                    color: isWorkingShift ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (currentUser != null) ...[
                  const Spacer(),
                  Text(
                    '${currentUser!.hoTen} (${currentUser!.chucVu})',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),

          // Content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Có lỗi xảy ra:\n$error',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadOrders,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : orders.isEmpty
                        ? const Center(
                            child: Text(
                              'Không có đơn hàng nào',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              return _buildOrderCard(orders[index]);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}