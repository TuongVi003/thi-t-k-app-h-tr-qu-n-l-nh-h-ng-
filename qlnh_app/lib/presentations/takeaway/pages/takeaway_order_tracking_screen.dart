import 'package:flutter/material.dart';
import '../../../models/takeaway_order.dart';
import '../../../constants/app_colors.dart';
import '../service/takeaway_service.dart';

class TakeawayOrderTrackingScreen extends StatefulWidget {
  final int orderId;
  final TakeawayOrder? initialOrder;

  const TakeawayOrderTrackingScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
  });

  @override
  State<TakeawayOrderTrackingScreen> createState() => _TakeawayOrderTrackingScreenState();
}

class _TakeawayOrderTrackingScreenState extends State<TakeawayOrderTrackingScreen> {
  TakeawayOrder? _order;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialOrder != null) {
      _order = widget.initialOrder;
    } else {
      _loadOrderDetails();
    }
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final order = await TakeawayService.getTakeawayOrderDetail(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadOrderDetails();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.orderPending;
      case 'confirmed':
        return AppColors.orderProcessing;
      case 'cooking':
        return AppColors.orderReady;
      case 'ready':
        return AppColors.orderCompleted;
      case 'completed':
        return AppColors.success;
      case 'canceled':
        return AppColors.orderCancelled;
      default:
        return AppColors.textLight;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'cooking':
        return Icons.restaurant;
      case 'ready':
        return Icons.done_all;
      case 'completed':
        return Icons.shopping_bag;
      case 'canceled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  int _getStatusStep(String status) {
    switch (status) {
      case 'pending':
        return 0;
      case 'confirmed':
        return 1;
      case 'cooking':
        return 2;
      case 'ready':
        return 3;
      case 'completed':
        return 4;
      case 'canceled':
        return -1;
      default:
        return 0;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_order?.id != null ? 'Đơn hàng #${_order!.id}' : 'Theo dõi đơn hàng'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _order == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _order == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: AppColors.errorLight),
            const SizedBox(height: 16),
            Text(
              'Không thể tải đơn hàng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadOrderDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_order == null) {
      return const Center(child: Text('Không tìm thấy đơn hàng'));
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            // _buildStatusTimeline(),
            const SizedBox(height: 16),
            _buildOrderInfo(),
            const SizedBox(height: 16),
            _buildOrderItems(),
            const SizedBox(height: 16),
            _buildCustomerInfo(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final statusColor = _getStatusColor(_order!.trangThai);
    final statusIcon = _getStatusIcon(_order!.trangThai);

    return Card(
      elevation: 4,
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, size: 48, color: statusColor),
            ),
            const SizedBox(height: 12),
            Text(
              _order!.trangThaiDisplay,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 8),
            if (_order!.trangThai == 'pending')
              Text(
                'Đơn hàng đang chờ nhà hàng xác nhận',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              )
            else if (_order!.trangThai == 'confirmed')
              Text(
                'Đơn hàng đã được xác nhận và đang chuẩn bị',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              )
            else if (_order!.trangThai == 'cooking')
              Text(
                'Món ăn đang được chế biến',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              )
            else if (_order!.trangThai == 'ready')
              Text(
                'Món ăn đã sẵn sàng! Vui lòng đến lấy',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              )
            else if (_order!.trangThai == 'completed')
              Text(
                'Đơn hàng đã hoàn thành',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              )
            else if (_order!.trangThai == 'canceled')
              Text(
                'Đơn hàng đã bị hủy',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            if (_order!.thoiGianLay != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer, size: 16, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      'Thời gian lấy: ~${_order!.thoiGianLay} phút',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline() {
    if (_order!.trangThai == 'canceled') {
      return const SizedBox.shrink();
    }

    final currentStep = _getStatusStep(_order!.trangThai);
    final steps = [
      {'label': 'Chờ xác nhận', 'status': 'pending'},
      {'label': 'Đã xác nhận', 'status': 'confirmed'},
      {'label': 'Đang nấu', 'status': 'cooking'},
      {'label': 'Sẵn sàng', 'status': 'ready'},
      {'label': 'Hoàn thành', 'status': 'completed'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trạng thái đơn hàng',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(steps.length, (index) {
              final step = steps[index];
              final isActive = index <= currentStep;
              final isCurrent = index == currentStep;
              final isLast = index == steps.length - 1;

              return Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? _getStatusColor(step['status'] as String)
                              : AppColors.borderLight,
                        ),
                        child: Icon(
                          isActive ? Icons.check : Icons.circle,
                          size: isCurrent ? 20 : 16,
                          color: AppColors.textWhite,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step['label'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isActive ? AppColors.textPrimary : AppColors.textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isLast)
                    Container(
                      margin: const EdgeInsets.only(left: 15, top: 4, bottom: 4),
                      width: 2,
                      height: 24,
                      color: isActive ? AppColors.divider : AppColors.borderLight,
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin đơn hàng',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.receipt_long, 'Mã đơn hàng', '#${_order!.id ?? 'N/A'}'),
            const SizedBox(height: 8),
            if (_order!.orderTime != null)
              _buildInfoRow(
                Icons.access_time,
                'Thời gian đặt',
                _formatDateTime(_order!.orderTime!),
              ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.restaurant,
              'Loại đơn',
              _order!.loaiOrder == 'takeaway' ? 'Mang về' : 'Ăn tại chỗ',
            ),
            if (_order!.ghiChu != null && _order!.ghiChu!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.note, 'Ghi chú', _order!.ghiChu!),
            ],
            if (_order!.thoiGianSanSang != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.schedule,
                'Thời gian sẵn sàng',
                _formatDateTime(_order!.thoiGianSanSang!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItems() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Món đã đặt',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._order!.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: item.hinhAnh != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.hinhAnh!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.restaurant,
                                color: AppColors.textLight,
                              ),
                            ),
                          )
                        : Icon(Icons.restaurant, color: AppColors.textLight),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.tenMon,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.gia.toStringAsFixed(0)}đ x ${item.soLuong}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${item.thanhTien.toStringAsFixed(0)}đ',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_order!.tongTien.toStringAsFixed(0)}đ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _order!.khachHangXacNhanThanhToan == true
                          ? Icons.check_circle
                          : Icons.payment,
                      size: 20,
                      color: _order!.khachHangXacNhanThanhToan == true
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Trạng thái thanh toán',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _order!.khachHangXacNhanThanhToan == true
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _order!.khachHangXacNhanThanhToan == true
                          ? Colors.green
                          : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _order!.khachHangXacNhanThanhToan == true
                        ? 'Đã thanh toán'
                        : 'Bạn chưa xác nhận thanh toán',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _order!.khachHangXacNhanThanhToan == true
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    // This section could display customer info if needed
    // For now, we'll show a helpful info card
    return Card(
      color: AppColors.infoBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info),
                const SizedBox(width: 8),
                const Text(
                  'Lưu ý',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '• Kéo xuống để làm mới trạng thái đơn hàng\n'
              '• Thanh toán khi nhận món\n'
              '• Liên hệ nhà hàng nếu cần hỗ trợ',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    // Cho phép hủy khi pending hoặc confirmed (chưa bắt đầu nấu)
    final canCancel = _order!.trangThai == 'pending' || _order!.trangThai == 'confirmed';
    // Cho phép xác nhận thanh toán khi chưa thanh toán và đơn hàng đã completed
    final canConfirmPayment = _order!.khachHangXacNhanThanhToan != true;
    
    return Column(
      children: [
        if (canConfirmPayment) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () {
                _showConfirmPaymentDialog();
              },
              icon: const Icon(Icons.payment),
              label: const Text('Xác nhận đã thanh toán'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (canCancel) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () {
                _showCancelDialog();
              },
              icon: const Icon(Icons.cancel),
              label: const Text('Hủy đơn hàng'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orderCancelled,
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Quay lại'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  void _showConfirmPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn xác nhận đã thanh toán cho đơn hàng này?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppColors.success),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Xác nhận rằng bạn đã thanh toán đầy đủ',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
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
            onPressed: () async {
              Navigator.pop(context);
              await _confirmPayment();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: AppColors.textWhite,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy đơn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc chắn muốn hủy đơn hàng này không?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppColors.warning),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Lưu ý: Sau khi hủy không thể hoàn tác',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelOrder();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orderCancelled,
              foregroundColor: AppColors.textWhite,
            ),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPayment() async {
    try {
      setState(() => _isLoading = true);
      
      // Gọi API xác nhận thanh toán
      final updatedOrder = await TakeawayService.confirmPayment(_order!.id!);
      
      if (mounted) {
        setState(() {
          _order = updatedOrder;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xác nhận thanh toán thành công'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        String errorMessage = e.toString();
        errorMessage = errorMessage.replaceAll('Exception: Lỗi xác nhận thanh toán: Exception: ', '');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _cancelOrder() async {
    try {
      setState(() => _isLoading = true);
      
      // Gọi API hủy đơn và nhận về order đã cập nhật
      final updatedOrder = await TakeawayService.cancelTakeawayOrder(_order!.id!);
      
      if (mounted) {
        setState(() {
          _order = updatedOrder;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hủy đơn hàng thành công'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Parse error message để hiển thị thông báo dễ hiểu hơn
        String errorMessage = e.toString();
        if (errorMessage.contains('Không thể hủy đơn hàng đã bắt đầu chế biến')) {
          errorMessage = 'Không thể hủy đơn hàng đã bắt đầu chế biến hoặc hoàn thành';
        } else if (errorMessage.contains('Chỉ chủ đơn mới được hủy')) {
          errorMessage = 'Bạn không có quyền hủy đơn hàng này';
        } else {
          errorMessage = errorMessage.replaceAll('Exception: Lỗi hủy đơn hàng: Exception: ', '');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
