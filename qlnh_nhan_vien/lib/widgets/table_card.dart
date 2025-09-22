import 'package:flutter/material.dart';
import 'package:qlnh_nhan_vien/models/table.dart' as models;

class TableCard extends StatelessWidget {
  final models.Table table;
  final VoidCallback onTap;

  const TableCard({
    super.key,
    required this.table,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getStatusColor(),
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0), // Giảm padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Thêm dòng này
              children: [
                // Biểu tượng bàn
                Icon(
                  Icons.table_restaurant,
                  size: 28, // Giảm size
                  color: _getStatusColor(),
                ),
                const SizedBox(height: 6), // Giảm space
                
                // Số bàn
                Text(
                  'Bàn ${table.number}',
                  style: const TextStyle(
                    fontSize: 14, // Giảm font size
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // Sức chứa
                Text(
                  '${table.capacity} người',
                  style: const TextStyle(
                    fontSize: 10, // Giảm font size
                    color: Colors.grey,
                  ),
                ),
                
                const SizedBox(height: 6), // Giảm space
                
                // Trạng thái
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6, // Giảm padding
                    vertical: 2, // Giảm padding
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _getStatusColor().withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      fontSize: 9, // Giảm font size
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(),
                    ),
                  ),
                ),
                
                // Thông tin khách hàng (nếu có) - chỉ hiển thị khi có đủ không gian
                if (table.customerName != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    table.customerName!,
                    style: const TextStyle(
                      fontSize: 9, // Giảm font size
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                // Thời gian đặt bàn (nếu có)
                if (table.reservationTime != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${table.reservationTime!.hour.toString().padLeft(2, '0')}:${table.reservationTime!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 8, // Giảm font size
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (table.status) {
      case models.TableStatus.available:
        return Colors.green;
      case models.TableStatus.occupied:
        return Colors.red;
      case models.TableStatus.reserved:
        return Colors.orange;
      case models.TableStatus.cleaning:
        return Colors.blue;
    }
  }

  String _getStatusText() {
    switch (table.status) {
      case models.TableStatus.available:
        return 'Trống';
      case models.TableStatus.occupied:
        return 'Đã đặt';
      case models.TableStatus.reserved:
        return 'Đặt trước';
      case models.TableStatus.cleaning:
        return 'Dọn dẹp';
    }
  }
}