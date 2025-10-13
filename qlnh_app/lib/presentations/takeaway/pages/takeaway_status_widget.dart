import 'package:flutter/material.dart';
import 'package:qlnh_app/constants/app_colors.dart';
import 'package:qlnh_app/presentations/screens/home_screen.dart';
import '../../../models/takeaway_order.dart';
import '../service/takeaway_service.dart';

class TakeawayStatusWidget extends StatefulWidget {
  const TakeawayStatusWidget({super.key});

  @override
  State<TakeawayStatusWidget> createState() => _TakeawayStatusWidgetState();
}

class _TakeawayStatusWidgetState extends State<TakeawayStatusWidget> {
  List<TakeawayOrder> _activeOrders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadActiveOrders();
  }

  Future<void> _loadActiveOrders() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final orders = await TakeawayService.getMyTakeawayOrders();
      final activeOrders = orders.where((order) => 
        ['pending', 'confirmed', 'cooking', 'ready', 'completed', 'canceled'].contains(order.trangThai)
      ).toList();

      setState(() {
        _activeOrders = activeOrders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
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
        return AppColors.accent;
      case 'canceled':
        return AppColors.orderCancelled;
      default:
        return AppColors.textLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_activeOrders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(initialIndex: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.takeout_dining, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  const Text(
                    'Đơn hàng mang về',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_activeOrders.length}',
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
              
              // Show latest active order
              if (_activeOrders.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đơn hàng #${_activeOrders.first.id}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_activeOrders.first.items.length} món • ${_activeOrders.first.tongTien.toStringAsFixed(0)}đ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_activeOrders.first.trangThai),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _activeOrders.first.trangThaiDisplay,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (_activeOrders.length > 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    'và ${_activeOrders.length - 1} đơn hàng khác...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
              
              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  Text(
                    'Nhấn để xem chi tiết',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.blue.shade700,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}