import 'package:flutter/material.dart';
import '../models/takeaway_order.dart';
import '../services/takeaway_service.dart';
import '../services/about_us_service.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'takeaway_order_detail_screen.dart';
import 'create_takeaway_order_screen.dart';
import '../utils/app_utils.dart';

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
  
  // Per-order loading states (use sets of order IDs)
  final Set<int> acceptingIds = <int>{};
  final Set<int> confirmingIds = <int>{};
  final Set<int> markingReadyIds = <int>{};
  final Set<int> completingIds = <int>{};

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

    acceptingIds.add(order.id);
    setState(() {});

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
    } finally {
      acceptingIds.remove(order.id);
      if (mounted) setState(() {});
    }
  }

  /// Start cooking: call confirmTime with null to indicate start cooking
  Future<void> _confirmTime(TakeawayOrder order) async {
    confirmingIds.add(order.id);
    setState(() {});

    try {
      await TakeawayService.confirmTime(order.id, null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã bắt đầu nấu')),
      );
      await _loadOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi bắt đầu nấu: ${e.toString()}')),
      );
    } finally {
      confirmingIds.remove(order.id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _updateStatus(TakeawayOrder order, TakeawayOrderStatus status) async {
    final isReady = status == TakeawayOrderStatus.ready;
    final isCompleting = status == TakeawayOrderStatus.completed;
    
    // If completing, ask for payment method first
    String? paymentMethod;
    if (isCompleting) {
      paymentMethod = await _showPaymentMethodDialog();
      if (paymentMethod == null) {
        // User cancelled the dialog
        return;
      }
    }
    
    if (isReady) {
      markingReadyIds.add(order.id);
    } else if (isCompleting) {
      completingIds.add(order.id);
    }
    setState(() {});

    try {
      await TakeawayService.updateStatus(order.id, status, paymentMethod: paymentMethod);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật trạng thái thành công')),
      );
      await _loadOrders();
    } catch (e) {
      print('Error updating status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật trạng thái: ${e.toString()}')),
      );
    } finally {
      if (isReady) {
        markingReadyIds.remove(order.id);
      } else if (isCompleting) {
        completingIds.remove(order.id);
      }
      if (mounted) setState(() {});
    }
  }

  Future<String?> _showPaymentMethodDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Phương thức thanh toán',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Khách hàng thanh toán bằng:'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.money, color: Colors.green),
                title: const Text('Tiền mặt'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onTap: () => Navigator.of(context).pop('cash'),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.blue),
                title: const Text('Thẻ/QR'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onTap: () => Navigator.of(context).pop('qr_selected'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );

    // If user selected QR, show QR dialog
    if (result == 'qr_selected') {
      final qrConfirmed = await _showQrCodeDialog();
      if (qrConfirmed == true) {
        return 'card'; // Return 'card' as payment method
      }
      return null; // User cancelled QR dialog
    }

    return result; // Return 'cash' or null
  }

  Future<bool?> _showQrCodeDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Quét mã QR để thanh toán',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: FutureBuilder<String?>(
              future: AboutUsService.getPaymentQrUrl(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError || snapshot.data == null) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Không thể tải mã QR\n${snapshot.error ?? ""}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  );
                }

                final qrUrl = snapshot.data!;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Khách hàng vui lòng quét mã QR bên dưới:',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.network(
                        qrUrl,
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey.shade200,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Không thể tải ảnh', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey.shade100,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sau khi khách đã thanh toán, nhấn "Xác nhận"',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.check),
              label: const Text('Xác nhận đã thanh toán'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
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
              
              // Delivery method (highlighted) and address (if delivery)
              if (order.phuongThucGiaoHang != null && order.phuongThucGiaoHang!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      avatar: Icon(
                        order.phuongThucGiaoHang == 'Giao hàng tận nơi'
                            ? Icons.delivery_dining
                            : Icons.storefront,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        order.phuongThucGiaoHang!,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: order.phuongThucGiaoHang == 'Giao hàng tận nơi'
                          ? Colors.deepOrangeAccent
                          : Colors.green,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                // On narrow space or for clearer visibility, render address in a subtle box below
                if (order.phuongThucGiaoHang == 'Giao hàng tận nơi' && order.diaChiGiaoHang != null && order.diaChiGiaoHang!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.deepOrangeAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.diaChiGiaoHang!,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],

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
                      onPressed: acceptingIds.contains(order.id) ? null : () => _acceptOrder(order),
                      icon: acceptingIds.contains(order.id)
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check, size: 16),
                      label: Text(acceptingIds.contains(order.id) ? 'Đang...' : 'Nhận đơn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: acceptingIds.contains(order.id) ? Colors.grey : Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  
                  if (canConfirmTime)
                    ElevatedButton.icon(
                      onPressed: confirmingIds.contains(order.id) ? null : () => _confirmTime(order),
                      icon: confirmingIds.contains(order.id)
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.kitchen, size: 16),
                      label: Text(confirmingIds.contains(order.id) ? 'Đang...' : 'Bắt đầu nấu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmingIds.contains(order.id) ? Colors.grey : Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),

                  if (canMarkReady)
                    ElevatedButton.icon(
                      onPressed: markingReadyIds.contains(order.id) ? null : () => _updateStatus(order, TakeawayOrderStatus.ready),
                      icon: markingReadyIds.contains(order.id)
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.restaurant, size: 16),
                      label: Text(markingReadyIds.contains(order.id) ? 'Đang...' : 'Món sẵn sàng'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: markingReadyIds.contains(order.id) ? Colors.grey : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),

                  if (canComplete)
                    ElevatedButton.icon(
                      onPressed: completingIds.contains(order.id) ? null : () => _updateStatus(order, TakeawayOrderStatus.completed),
                      icon: completingIds.contains(order.id)
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.done_all, size: 16),
                      label: Text(completingIds.contains(order.id) ? 'Đang...' : 'Hoàn thành'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: completingIds.contains(order.id) ? Colors.grey : Colors.grey,
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
      floatingActionButton: isWorkingShift
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateTakeawayOrderScreen(),
                  ),
                );
                if (result == true) {
                  _loadOrders();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Tạo đơn mang về'),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }
}