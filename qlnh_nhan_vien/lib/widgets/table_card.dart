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
            padding: const EdgeInsets.all(8.0), // Giảm padding thêm
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Biểu tượng bàn và số bàn trên cùng 1 dòng
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.table_restaurant,
                      size: 20, // Giảm size thêm
                      color: _getStatusColor(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Bàn ${table.number}',
                      style: const TextStyle(
                        fontSize: 12, // Giảm font size
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4), // Giảm space
                
                // Sức chứa và khu vực
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${table.capacity} người',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                      ),
                    ),
                    const Text(' • ', style: TextStyle(fontSize: 8, color: Colors.grey)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: _getAreaColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: _getAreaColor().withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        table.areaDisplayName,
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w500,
                          color: _getAreaColor(),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4), // Giảm space
                
                // Trạng thái
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4, // Giảm padding thêm
                    vertical: 1, // Giảm padding thêm
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8), // Giảm border radius
                    border: Border.all(
                      color: _getStatusColor().withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      fontSize: 8, // Giảm font size thêm
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(),
                    ),
                  ),
                ),
                
                // Thông tin khách hàng (nếu có)
                if (table.hasCustomer)
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 2),
                        // Loại khách hàng
                        if (table.customerType != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: _getCustomerTypeColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _getCustomerTypeColor().withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              table.customerTypeDisplayName,
                              style: TextStyle(
                                fontSize: 6,
                                fontWeight: FontWeight.w500,
                                color: _getCustomerTypeColor(),
                              ),
                            ),
                          ),
                        const SizedBox(height: 1),
                        // Tên khách hàng
                        Text(
                          table.customerName!,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Số điện thoại (nếu có)
                        if (table.customerPhone != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            table.customerPhone!,
                            style: const TextStyle(
                              fontSize: 7,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        // Thời gian đặt (nếu có)
                        if (table.reservationTime != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            '${table.reservationTime!.hour.toString().padLeft(2, '0')}:${table.reservationTime!.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 7,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
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

  Color _getCustomerTypeColor() {
    if (table.customerType == null) return Colors.grey;
    switch (table.customerType!) {
      case models.CustomerType.registered:
        return Colors.blue;
      case models.CustomerType.guest:
        return Colors.purple;
    }
  }

  Color _getAreaColor() {
    switch (table.area) {
      case models.AreaType.inside:
        return Colors.teal;
      case models.AreaType.outside:
        return Colors.indigo;
      case models.AreaType.privateRoom:
        return Colors.amber[700]!;
    }
  }
}