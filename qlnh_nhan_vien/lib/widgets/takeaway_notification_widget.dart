import 'package:flutter/material.dart';
import '../models/takeaway_order.dart';

class TakeawayNotificationWidget extends StatelessWidget {
  final List<TakeawayOrder> orders;
  final VoidCallback onTap;

  const TakeawayNotificationWidget({
    super.key,
    required this.orders,
    required this.onTap,
  });

  int get pendingOrdersCount {
    return orders.where((order) => order.trangThai == 'pending').length;
  }

  int get readyOrdersCount {
    return orders.where((order) => order.trangThai == 'ready').length;
  }

  bool get hasNotifications {
    return pendingOrdersCount > 0 || readyOrdersCount > 0;
  }

  @override
  Widget build(BuildContext context) {
    if (!hasNotifications) {
      return IconButton(
        icon: const Icon(Icons.notifications_none),
        onPressed: onTap,
      );
    }

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: onTap,
        ),
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(
              minWidth: 20,
              minHeight: 20,
            ),
            child: Text(
              '${pendingOrdersCount + readyOrdersCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

class NotificationDialog extends StatelessWidget {
  final List<TakeawayOrder> orders;
  final VoidCallback onGoToTakeaway;

  const NotificationDialog({
    super.key,
    required this.orders,
    required this.onGoToTakeaway,
  });

  @override
  Widget build(BuildContext context) {
    final pendingOrders = orders.where((order) => order.trangThai == 'pending').toList();
    final readyOrders = orders.where((order) => order.trangThai == 'ready').toList();

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.notifications, color: Colors.orange),
          SizedBox(width: 8),
          Text('Thông báo'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pendingOrders.isNotEmpty) ...[
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${pendingOrders.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: const Text('Đơn hàng mới'),
                subtitle: const Text('Cần xác nhận'),
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
            ],
            if (readyOrders.isNotEmpty) ...[
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${readyOrders.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: const Text('Món sẵn sàng'),
                subtitle: const Text('Thông báo khách hàng'),
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
            ],
            if (pendingOrders.isEmpty && readyOrders.isEmpty) ...[
              const ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('Không có thông báo mới'),
                subtitle: Text('Tất cả đơn hàng đã được xử lý'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        if (pendingOrders.isNotEmpty || readyOrders.isNotEmpty)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onGoToTakeaway();
            },
            child: const Text('Xem chi tiết'),
          ),
      ],
    );
  }
}