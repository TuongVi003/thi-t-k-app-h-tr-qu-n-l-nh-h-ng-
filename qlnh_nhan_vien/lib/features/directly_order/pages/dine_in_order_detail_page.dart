import 'package:flutter/material.dart';
import '../models/dine_in_order.dart';
import '../services/dine_in_order_service.dart';
import '../../../services/about_us_service.dart';
import 'package:qlnh_nhan_vien/widgets/invoice_button.dart';

class DineInOrderDetailPage extends StatefulWidget {
  final int orderId;

  const DineInOrderDetailPage({Key? key, required this.orderId})
      : super(key: key);

  @override
  State<DineInOrderDetailPage> createState() => _DineInOrderDetailPageState();
}

class _DineInOrderDetailPageState extends State<DineInOrderDetailPage> {
  final DineInOrderService _service = DineInOrderService();
  DineInOrder? _order;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    setState(() => _isLoading = true);
    try {
      final order = await _service.getDineInOrderDetail(widget.orderId);
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final errMsg = _getErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $errMsg')),
        );
      }
    }
  }

  Future<void> _confirmTime() async {
    final TextEditingController timeController = TextEditingController();

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thời gian'),
        content: TextField(
          controller: timeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Thời gian chế biến (phút)',
            hintText: 'Ví dụ: 15',
          ),
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
      setState(() => _isProcessing = true);
      try {
        final updatedOrder = await _service.confirmTime(widget.orderId, result);
        setState(() {
          _order = updatedOrder;
          _isProcessing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xác nhận thời gian')),
          );
        }
      } catch (e) {
        setState(() => _isProcessing = false);
        if (mounted) {
          final errMsg = _getErrorMessage(e);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $errMsg')),
          );
        }
      }
    }
  }

  Future<void> _startCooking() async {
    setState(() => _isProcessing = true);
    try {
      final updatedOrder = await _service.startCooking(widget.orderId);
      setState(() {
        _order = updatedOrder;
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã bắt đầu chế biến')),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        final errMsg = _getErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $errMsg')),
        );
      }
    }
  }

  Future<void> _markReady() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Món đã sẵn sàng để phục vụ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      try {
        final updatedOrder = await _service.markReady(widget.orderId);
        setState(() {
          _order = updatedOrder;
          _isProcessing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Món đã sẵn sàng')),
          );
        }
      } catch (e) {
        setState(() => _isProcessing = false);
        if (mounted) {
          final errMsg = _getErrorMessage(e);
          print('Lỗi: $errMsg');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $errMsg')),
          );
        }
      }
    }
  }

  Future<void> _deliverToTable() async {
    // First ask for payment method: 'cash' or 'card'
    String? paymentMethod = await showDialog<String>(
      context: context,
      builder: (context) {
        String? selected;
        return AlertDialog(
          title: const Text('Chọn phương thức thanh toán'),
          content: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('Tiền mặt'),
                  value: 'cash',
                  groupValue: selected,
                  onChanged: (v) => setState(() => selected = v),
                ),
                RadioListTile<String>(
                  title: const Text('Thẻ'),
                  value: 'card',
                  groupValue: selected,
                  onChanged: (v) => setState(() => selected = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('Tiếp tục'),
            ),
          ],
        );
      },
    );

    if (paymentMethod == null) return; // cancelled or not selected

    bool? confirm;
    if (paymentMethod == 'card') {
      // Fetch payment QR URL and show it to the user before confirming
      setState(() => _isProcessing = true);
      String? qrUrl;
      try {
        qrUrl = await AboutUsService.getPaymentQrUrl();
      } catch (e) {
        setState(() => _isProcessing = false);
        if (mounted) {
          final errMsg = _getErrorMessage(e);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi lấy QR: $errMsg')),
          );
        }
        return;
      }
      setState(() => _isProcessing = false);

      if (qrUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy mã QR thanh toán')),
          );
        }
        return;
      }

      confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Xác nhận đã đem món tới bàn?\nPhương thức: Thẻ'),
              const SizedBox(height: 12),
              Image.network(
                qrUrl!,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Text('Không thể tải ảnh QR'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      );
    } else {
      confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận'),
          content: const Text('Xác nhận đã đem món tới bàn?\nPhương thức: Tiền mặt'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      );
    }

    if (confirm == true) {
      setState(() => _isProcessing = true);
      try {
        final updatedOrder = await _service.deliverToTable(widget.orderId, paymentMethod: paymentMethod);
        setState(() {
          _order = updatedOrder;
          _isProcessing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã hoàn thành đơn hàng')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() => _isProcessing = false);
        if (mounted) {
          final errMsg = _getErrorMessage(e);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $errMsg')),
          );
        }
      }
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: const Text('Bạn có chắc muốn hủy đơn hàng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      try {
        final updatedOrder = await _service.cancelOrder(widget.orderId);
        setState(() {
          _order = updatedOrder;
          _isProcessing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã hủy đơn hàng')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() => _isProcessing = false);
        if (mounted) {
          final errMsg = _getErrorMessage(e);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $errMsg')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đơn #${widget.orderId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrderDetail,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Không tìm thấy đơn hàng'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 16),
                      _buildInfoCard(),
                      const SizedBox(height: 16),
                      _buildOrderItems(),
                      const SizedBox(height: 16),
                      // Invoice print button (ask for invoice ID if unknown)
                      // InvoiceButton(hoaDonId: null, label: 'In hóa đơn'),
                      const SizedBox(height: 16),
                      _buildActionButtons(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor = _getStatusColor(_order!.trangThai);
    return Card(
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              _getStatusIcon(_order!.trangThai),
              size: 48,
              color: statusColor,
            ),
            const SizedBox(height: 8),
            Text(
              _order!.getTrangThaiText(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    String formatDateTime(DateTime dt) {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin đơn hàng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('Bàn số:', _order!.banAnSoBan ?? 'N/A'),
            _buildInfoRow('Nhân viên:', _order!.nhanVienHoTen),
            _buildInfoRow('Thời gian đặt:', formatDateTime(_order!.orderTime)),
            if (_order!.thoiGianLay != null)
              _buildInfoRow('Thời gian chế biến:', '${_order!.thoiGianLay} phút'),
            if (_order!.thoiGianSanSang != null)
              _buildInfoRow(
                'Thời gian sẵn sàng:',
                formatDateTime(_order!.thoiGianSanSang!),
              ),
            if (_order!.ghiChu != null && _order!.ghiChu!.isNotEmpty)
              _buildInfoRow('Ghi chú:', _order!.ghiChu!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
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
              'Chi tiết món ăn',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ..._order!.chiTietOrder.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.tenMonAn} x${item.soLuong}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Text(
                        '${item.thanhTien.toStringAsFixed(0)} VND',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )),
            const Divider(),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tổng cộng:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${_order!.tongTien.toStringAsFixed(0)} VND',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isProcessing) {
      return const Center(child: CircularProgressIndicator());
    }

    List<Widget> buttons = [];

    switch (_order!.trangThai) {
      case 'pending':
        buttons.add(
          ElevatedButton.icon(
            onPressed: _confirmTime,
            icon: const Icon(Icons.schedule),
            label: const Text('Xác nhận thời gian'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        );
        buttons.add(const SizedBox(height: 8));
        buttons.add(
          OutlinedButton.icon(
            onPressed: _cancelOrder,
            icon: const Icon(Icons.cancel),
            label: const Text('Hủy đơn'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        );
        break;

      case 'confirmed':
        buttons.add(
          ElevatedButton.icon(
            onPressed: _startCooking,
            icon: const Icon(Icons.restaurant),
            label: const Text('Bắt đầu chế biến'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        );
        buttons.add(const SizedBox(height: 8));
        buttons.add(
          OutlinedButton.icon(
            onPressed: _cancelOrder,
            icon: const Icon(Icons.cancel),
            label: const Text('Hủy đơn'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        );
        break;

      case 'cooking':
        buttons.add(
          ElevatedButton.icon(
            onPressed: _markReady,
            icon: const Icon(Icons.done_all),
            label: const Text('Đánh dấu sẵn sàng'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        );
        break;

      case 'ready':
        buttons.add(
          ElevatedButton.icon(
            onPressed: _deliverToTable,
            icon: const Icon(Icons.delivery_dining),
            label: const Text('Hoàn thành đơn hàng'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        );
        break;

      case 'completed':
        buttons.add(
          const Center(
            child: Text(
              'Đơn hàng đã hoàn thành',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
          ),
        );
        break;

      case 'canceled':
        buttons.add(
          const Center(
            child: Text(
              'Đơn hàng đã bị hủy',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ),
        );
        break;
    }

    return Column(children: buttons);
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

  // Helper: return a cleaned error message from an exception object.
  // Removes leading 'Exception:' prefixes (case-insensitive) and trims whitespace.
  String _getErrorMessage(Object e) {
    var msg = e.toString();
    msg = msg.replaceAll(RegExp(r'(?i)\bexception:\s*'), '');
    return msg.trim();
  }
}
