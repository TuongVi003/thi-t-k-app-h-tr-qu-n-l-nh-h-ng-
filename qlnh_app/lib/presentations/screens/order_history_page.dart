import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../../services/auth_service.dart';



class OrderHistoryTab extends StatelessWidget {
  const OrderHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final bool loggedIn = AuthService.instance.isLoggedIn;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lịch sử đặt hàng',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (!loggedIn)
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Đăng nhập để xem chi tiết lịch sử đặt hàng của bạn.',
                        style: TextStyle(color: Colors.orange.shade800),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final res = await Navigator.push<bool?>(
                          context,
                          MaterialPageRoute(builder: (c) => const LoginScreen()),
                        );
                        if (res == true || AuthService.instance.isLoggedIn) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đăng nhập thành công')),
                          );
                        }
                      },
                      child: const Text('Đăng nhập'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                _buildOrderHistoryCard(
                  '#ORD001',
                  '18/09/2025 - 14:30',
                  'Đã giao',
                  250000,
                  ['Phở Bò Tái', 'Nước Cam Tươi'],
                ),
                _buildOrderHistoryCard(
                  '#ORD002',
                  '17/09/2025 - 12:15',
                  'Đã giao',
                  180000,
                  ['Cơm Gà Teriyaki'],
                ),
                _buildOrderHistoryCard(
                  '#ORD003',
                  '15/09/2025 - 19:20',
                  'Đã giao',
                  320000,
                  ['Pizza Hải Sản', 'Trà Sữa Trân Châu', 'Bánh Flan'],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHistoryCard(String orderNumber, String date, String status, double total, List<String> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đơn hàng $orderNumber',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              date,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Món: ${items.join(', ')}',
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng: ${total.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ₫',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Show order details
                  },
                  child: const Text('Xem chi tiết'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
