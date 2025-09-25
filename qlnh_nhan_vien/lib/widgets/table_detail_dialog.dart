import 'package:flutter/material.dart';
import 'package:qlnh_nhan_vien/models/table.dart' as models;

class TableDetailDialog extends StatefulWidget {
  final models.Table table;
  final Function(models.Table) onTableUpdated;

  const TableDetailDialog({
    super.key,
    required this.table,
    required this.onTableUpdated,
  });

  @override
  State<TableDetailDialog> createState() => _TableDetailDialogState();
}

class _TableDetailDialogState extends State<TableDetailDialog> {
  late models.Table currentTable;
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    currentTable = widget.table;
    _customerNameController.text = currentTable.customerName ?? '';
    _customerPhoneController.text = currentTable.customerPhone ?? '';
    _notesController.text = currentTable.notes ?? '';
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateTableStatus(models.TableStatus newStatus) {
    setState(() {
      currentTable = currentTable.copyWith(status: newStatus);
    });
  }

  void _saveChanges() {
    // Chỉ cho phép cập nhật trạng thái và ghi chú
    // Thông tin khách hàng từ API không được chỉnh sửa
    final updatedTable = currentTable.copyWith(
      notes: _notesController.text.isEmpty 
          ? null 
          : _notesController.text,
    );
    
    widget.onTableUpdated(updatedTable);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85, // Giới hạn height
          maxWidth: MediaQuery.of(context).size.width * 0.9,   // Giới hạn width
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Giảm padding
          child: SingleChildScrollView( // Thêm SingleChildScrollView
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.table_restaurant,
                  size: 32,
                  color: _getStatusColor(currentTable.status),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bàn ${currentTable.number}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Sức chứa: ${currentTable.capacity} người',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Trạng thái hiện tại
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(currentTable.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getStatusColor(currentTable.status).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(currentTable.status),
                    color: _getStatusColor(currentTable.status),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Trạng thái: ${_getStatusText(currentTable.status)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(currentTable.status),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Thông tin khách hàng
            Row(
              children: [
                const Text(
                  'Thông tin khách hàng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (currentTable.customerType != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getCustomerTypeColor(currentTable.customerType!).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getCustomerTypeColor(currentTable.customerType!).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      currentTable.customerTypeDisplayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getCustomerTypeColor(currentTable.customerType!),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: 'Tên khách hàng',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              readOnly: true, // Chỉ đọc vì dữ liệu từ API
            ),
            
            const SizedBox(height: 12),
            
            TextField(
              controller: _customerPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              readOnly: true, // Chỉ đọc vì dữ liệu từ API
            ),
            
            const SizedBox(height: 12),
            
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Nút thay đổi trạng thái
            const Text(
              'Thay đổi trạng thái',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusButton(
                  'Bàn trống',
                  models.TableStatus.available,
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatusButton(
                  'Đã đặt',
                  models.TableStatus.occupied,
                  Icons.people,
                  Colors.red,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Nút action
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Lưu thay đổi'),
                ),
              ],
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton(String label, models.TableStatus status, IconData icon, Color color) {
    final isSelected = currentTable.status == status;
    
    return ElevatedButton.icon(
      onPressed: () => _updateTableStatus(status),
      icon: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : color,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontSize: 12,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.transparent,
        foregroundColor: isSelected ? Colors.white : color,
        elevation: isSelected ? 2 : 0,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Color _getStatusColor(models.TableStatus status) {
    switch (status) {
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

  IconData _getStatusIcon(models.TableStatus status) {
    switch (status) {
      case models.TableStatus.available:
        return Icons.check_circle;
      case models.TableStatus.occupied:
        return Icons.people;
      case models.TableStatus.reserved:
        return Icons.schedule;
      case models.TableStatus.cleaning:
        return Icons.cleaning_services;
    }
  }

  String _getStatusText(models.TableStatus status) {
    switch (status) {
      case models.TableStatus.available:
        return 'Bàn trống';
      case models.TableStatus.occupied:
        return 'Đã đặt';
      case models.TableStatus.reserved:
        return 'Đặt trước';
      case models.TableStatus.cleaning:
        return 'Đang dọn dẹp';
    }
  }

  Color _getCustomerTypeColor(models.CustomerType customerType) {
    switch (customerType) {
      case models.CustomerType.registered:
        return Colors.blue;
      case models.CustomerType.guest:
        return Colors.purple;
    }
  }
}