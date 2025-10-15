import 'package:flutter/material.dart';
import '../models/takeaway_order.dart';
import '../services/takeaway_service.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class TakeawayOrderDetailScreen extends StatefulWidget {
  final TakeawayOrder order;

  const TakeawayOrderDetailScreen({
    super.key,
    required this.order,
  });

  @override
  State<TakeawayOrderDetailScreen> createState() => _TakeawayOrderDetailScreenState();
}

class _TakeawayOrderDetailScreenState extends State<TakeawayOrderDetailScreen> {
  late TakeawayOrder order;
  User? currentUser;
  
  // Individual loading states for each action
  bool isAccepting = false;
  bool isConfirmingTime = false;
  bool isMarkingReady = false;
  bool isCompleting = false;

  @override
  void initState() {
    super.initState();
    order = widget.order;
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await AuthService.getStoredUser();
      setState(() {
        currentUser = user;
      });
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  Future<void> _acceptOrder() async {
    setState(() {
      isAccepting = true;
    });

    try {
      final updatedOrder = await TakeawayService.acceptOrder(order.id);
      setState(() {
        order = updatedOrder;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã nhận đơn thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi nhận đơn: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isAccepting = false;
      });
    }
  }

  /// Start cooking: call confirmTime with null to indicate start cooking without setting pickup time.
  Future<void> _confirmTime() async {
    setState(() {
      isConfirmingTime = true;
    });

    try {
      // Send thoi_gian_lay: null to start cooking
      final updatedOrder = await TakeawayService.confirmTime(order.id, null);
      setState(() {
        order = updatedOrder;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã bắt đầu nấu')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi bắt đầu nấu: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isConfirmingTime = false;
      });
    }
  }

  Future<void> _updateStatus(TakeawayOrderStatus status) async {
    final isReadyAction = status == TakeawayOrderStatus.ready;
    
    setState(() {
      if (isReadyAction) {
        isMarkingReady = true;
      } else {
        isCompleting = true;
      }
    });

    try {
      final updatedOrder = await TakeawayService.updateStatus(order.id, status);
      setState(() {
        order = updatedOrder;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật trạng thái thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật trạng thái: ${e.toString()}')),
      );
    } finally {
      setState(() {
        if (isReadyAction) {
          isMarkingReady = false;
        } else {
          isCompleting = false;
        }
      });
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final canAccept = order.trangThai == 'pending' && currentUser?.dangLamViec == true;
    final canConfirmTime = order.trangThai == 'confirmed' && 
                          order.nhanVienDetail?.id == currentUser?.id;
    final canMarkReady = order.trangThai == 'cooking' && 
                        currentUser?.chucVu == 'chef';
    final canComplete = order.trangThai == 'ready';

    return Scaffold(
      appBar: AppBar(
        title: Text('Đơn #${order.id}'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                // Status card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Trạng thái:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order.trangThai),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            order.trangThaiDisplay,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Customer info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông tin khách hàng',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (order.khachHangDetail != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.person, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                order.khachHangDetail!.hoTen,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.phone, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                order.khachHangDetail!.soDienThoai,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ] else ...[
                          const Text(
                            'Khách vãng lai',
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Order info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông tin đơn hàng',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              'Đặt lúc: ${_formatDateTime(order.orderTime)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        if (order.thoiGianLay != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.timer, color: Colors.purple),
                              const SizedBox(width: 8),
                              Text(
                                'Thời gian lấy: ${order.thoiGianLayDisplay}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                        if (order.nhanVienDetail != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.badge, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'Nhân viên: ${order.nhanVienDetail!.hoTen}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                        if (order.ghiChu != null && order.ghiChu!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.note, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Ghi chú: ${order.ghiChu}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
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

                const SizedBox(height: 16),

                // Order items card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chi tiết đơn hàng',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...order.chiTietOrder.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${item.soLuong}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.monAnDetail.tenMon,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (item.monAnDetail.moTa != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item.monAnDetail.moTa!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${item.gia}đ',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    '${item.thanhTien.toStringAsFixed(0)}đ',
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
                        )),
                        const Divider(),
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
                              '${order.tongTien.toStringAsFixed(0)}đ',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 100), // Space for floating buttons
              ],
            ),
          ),

      // Floating action buttons
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (canAccept) ...[
            FloatingActionButton.extended(
              onPressed: isAccepting ? null : _acceptOrder,
              backgroundColor: isAccepting ? Colors.grey : Colors.blue,
              icon: isAccepting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.check),
              label: Text(isAccepting ? 'Đang xử lý...' : 'Nhận đơn'),
            ),
            const SizedBox(height: 8),
          ],
          
          if (canConfirmTime) ...[
            FloatingActionButton.extended(
              onPressed: isConfirmingTime ? null : _confirmTime,
              backgroundColor: isConfirmingTime ? Colors.grey : Colors.orange,
              icon: isConfirmingTime 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.schedule),
              label: Text(isConfirmingTime ? 'Đang xử lý...' : 'Bắt đầu nấu'),
            ),
            const SizedBox(height: 8),
          ],

          if (canMarkReady) ...[
            FloatingActionButton.extended(
              onPressed: isMarkingReady ? null : () => _updateStatus(TakeawayOrderStatus.ready),
              backgroundColor: isMarkingReady ? Colors.grey : Colors.green,
              icon: isMarkingReady 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.restaurant),
              label: Text(isMarkingReady ? 'Đang xử lý...' : 'Món sẵn sàng'),
            ),
            const SizedBox(height: 8),
          ],

          if (canComplete) ...[
            FloatingActionButton.extended(
              onPressed: isCompleting ? null : () => _updateStatus(TakeawayOrderStatus.completed),
              backgroundColor: isCompleting ? Colors.grey : Colors.grey,
              icon: isCompleting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.done_all),
              label: Text(isCompleting ? 'Đang xử lý...' : 'Hoàn thành'),
            ),
          ],
        ],
      ),
    );
  }
}