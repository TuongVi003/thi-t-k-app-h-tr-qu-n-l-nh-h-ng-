import 'package:flutter/material.dart';
import 'package:qlnh_nhan_vien/models/booking.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;
  final Function(BookingStatus) onStatusChanged;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onTap,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Thêm dòng này
            children: [
              // Header với tên và trạng thái
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.customerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              booking.customerPhone,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor().withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(),
                          size: 12,
                          color: _getStatusColor(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _getStatusColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Thông tin đặt bàn
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.schedule,
                      'Thời gian',
                      '${booking.bookingTime.day}/${booking.bookingTime.month} - ${booking.bookingTime.hour.toString().padLeft(2, '0')}:${booking.bookingTime.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.people,
                      'Số khách',
                      '${booking.numberOfGuests} người',
                    ),
                  ),
                ],
              ),
              
              if (booking.preferredTableNumber != null) ...[
                const SizedBox(height: 8),
                _buildInfoItem(
                  Icons.table_restaurant,
                  'Bàn mong muốn',
                  'Bàn ${booking.preferredTableNumber}',
                ),
              ],
              
              if (booking.specialRequests != null) ...[
                const SizedBox(height: 8),
                _buildInfoItem(
                  Icons.note,
                  'Yêu cầu',
                  booking.specialRequests!,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Action buttons
              Wrap( // Thay Row bằng Wrap để tự động xuống dòng
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  if (booking.status == BookingStatus.pending) ...[
                    TextButton.icon(
                      onPressed: () => onStatusChanged(BookingStatus.cancelled),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text(
                        'Hủy',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => onStatusChanged(BookingStatus.confirmed),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text(
                        'Xác nhận',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ] else if (booking.status == BookingStatus.confirmed) ...[
                    ElevatedButton.icon(
                      onPressed: () => onStatusChanged(BookingStatus.completed),
                      icon: const Icon(Icons.done, size: 16),
                      label: const Text(
                        'Hoàn thành',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (booking.status) {
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.completed:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon() {
    switch (booking.status) {
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.pending:
        return Icons.access_time;
      case BookingStatus.cancelled:
        return Icons.cancel;
      case BookingStatus.completed:
        return Icons.done;
    }
  }

  String _getStatusText() {
    switch (booking.status) {
      case BookingStatus.confirmed:
        return 'Đã xác nhận';
      case BookingStatus.pending:
        return 'Chờ xác nhận';
      case BookingStatus.cancelled:
        return 'Đã hủy';
      case BookingStatus.completed:
        return 'Hoàn thành';
    }
  }
}