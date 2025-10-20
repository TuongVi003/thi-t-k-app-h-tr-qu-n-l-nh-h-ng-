import 'package:flutter/material.dart';
import '../../../models/takeaway_order.dart';
import '../../../constants/app_colors.dart';
import 'package:qlnh_app/constants/utils.dart';

class TakeawaySuccessScreen extends StatelessWidget {
  final TakeawayOrder order;

  const TakeawaySuccessScreen({
    super.key,
    required this.order,
  });

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.successBackground,
      appBar: AppBar(
        title: const Text('Đặt hàng thành công'),
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.textWhite,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    // Success icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 60,
                        color: AppColors.textWhite,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Success message
                    const Text(
                      'Đặt hàng thành công!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      order.id != null
                          ? 'Đơn hàng #${order.id} của bạn đã được gửi đến nhà hàng'
                          : 'Đơn hàng của bạn đã được gửi đến nhà hàng (mã chưa có)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Order details card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Thông tin đơn hàng',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.orderPending,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    order.trangThaiDisplay,
                                    style: const TextStyle(
                                      color: AppColors.textWhite,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Order info
                            Row(
                              children: [
                                const Icon(Icons.receipt_long, size: 16),
                                const SizedBox(width: 8),
                                Text('Mã đơn hàng: #${order.id}'),
                              ],
                            ),
                            const SizedBox(height: 8),

                            if (order.orderTime != null) ...[
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                      'Thời gian đặt: ${_formatDateTime(order.orderTime!.add(Duration(hours: 7)))}'),
                                      // cộng 7 giờ để hiển thị đúng giờ Việt Nam
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],

                            if (order.thoiGianKhachLay != null) ...[
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                      'Thời gian lấy: ${_formatDateTime(order.thoiGianKhachLay!)}'),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],

                            Row(
                              children: [
                                const Icon(Icons.restaurant, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                    'Loại: ${order.loaiOrder == 'takeaway' ? 'Mang về' : 'Ăn tại chỗ'}'),
                              ],
                            ),

                            if (order.ghiChu != null &&
                                order.ghiChu!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.note, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('Ghi chú: ${order.ghiChu}'),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Order items
                            Text(
                              'Món đã đặt:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),
                            ...order.items.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (item.hinhAnh != null && item.hinhAnh!.isNotEmpty)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Image.network(
                                            Utils.imageUrl(item.hinhAnh!),
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => 
                                              Container(
                                                width: 40,
                                                height: 40,
                                                color: AppColors.primaryVeryLight,
                                                child: const Icon(
                                                  Icons.restaurant,
                                                  size: 20,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                          ),
                                        )
                                      else
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryVeryLight,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Icon(
                                            Icons.restaurant,
                                            size: 20,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '${item.soLuong}x ${item.tenMon}',
                                          style: const TextStyle(fontSize: 14),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${item.thanhTien.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
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
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${order.tongTien.toStringAsFixed(0)}đ',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Information card
                    const Card(
                      color: AppColors.infoBackground,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: AppColors.info),
                                SizedBox(width: 8),
                                Text(
                                  'Thông tin quan trọng',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '• Nhà hàng sẽ xác nhận đơn hàng trong ít phút\n'
                              '• Bạn sẽ nhận được thông báo khi món sẵn sàng\n'
                              '• Vui lòng đến nhà hàng để lấy món theo thời gian đã hẹn\n'
                              '• Thanh toán khi nhận món',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Buttons
            Column(
              children: [
                // SizedBox(
                //   width: double.infinity,
                //   child: ElevatedButton(
                //     onPressed: order.id != null
                //         ? () {
                //             Navigator.push(
                //               context,
                //               MaterialPageRoute(
                //                 builder: (context) =>
                //                     TakeawayOrderTrackingScreen(
                //                   orderId: order.id!,
                //                   initialOrder: order,
                //                 ),
                //               ),
                //             );
                //           }
                //         : null,
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: AppColors.primary,
                //       foregroundColor: AppColors.textWhite,
                //       padding: const EdgeInsets.symmetric(vertical: 16),
                //     ),
                //     child: const Text(
                //       'Theo dõi đơn hàng',
                //       style:
                //           TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                //     ),
                //   ),
                // ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.popUntil(
                        context,
                        (route) => route.isFirst,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.accent),
                    ),
                    child: const Text(
                      'Về trang chủ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
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
}
