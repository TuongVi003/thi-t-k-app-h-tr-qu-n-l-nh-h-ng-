import 'package:flutter/material.dart';
import 'package:qlnh_nhan_vien/models/table.dart' as models;
import 'package:qlnh_nhan_vien/services/api_service.dart';

class HotlineReservationDialog extends StatefulWidget {
  final models.Table? preselectedTable;
  final VoidCallback onReservationSuccess;

  const HotlineReservationDialog({
    super.key,
    this.preselectedTable,
    required this.onReservationSuccess,
  });

  @override
  State<HotlineReservationDialog> createState() => _HotlineReservationDialogState();
}

class _HotlineReservationDialogState extends State<HotlineReservationDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  models.Table? _selectedTable;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSubmitting = false;
  List<models.Table> _availableTables = [];
  bool _isLoadingTables = false;

  @override
  void initState() {
    super.initState();
    // Don't set _selectedTable here, will be set after loading tables
    _loadAvailableTables();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableTables() async {
    setState(() { _isLoadingTables = true; });
    try {
      final tables = await ApiService.fetchTablesFromApi();
      setState(() {
        _availableTables = tables.where((t) => t.status == models.TableStatus.available).toList();
        // If a table was preselected, find the matching one from loaded tables by ID
        if (widget.preselectedTable != null) {
          try {
            _selectedTable = _availableTables.firstWhere(
              (t) => t.id == widget.preselectedTable!.id,
            );
          } catch (e) {
            // If preselected table not found in available list, don't set it
            // This prevents the DropdownButton error
            print('⚠️ Preselected table ${widget.preselectedTable!.id} not found in available tables');
            _selectedTable = null;
          }
        }
        _isLoadingTables = false;
      });
    } catch (e) {
      setState(() { _isLoadingTables = false; });
      print('Error loading tables: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn bàn')),
      );
      return;
    }

    setState(() { _isSubmitting = true; });

    try {
      // Combine date and time into ISO 8601 format
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      final isoDate = dateTime.toUtc().toIso8601String();

      await ApiService.createHotlineReservation(
        banAnId: int.parse(_selectedTable!.id),
        khachHoTen: _nameController.text.trim(),
        khachSoDienThoai: _phoneController.text.trim(),
        ngayDat: isoDate,
        trangThai: 'pending',
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to signal success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã đặt bàn ${_selectedTable!.number} thành công cho ${_nameController.text}'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onReservationSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isSubmitting = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.phone_in_talk,
                          color: Color(0xFF2E7D32),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đặt bàn qua Hotline',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Khách hàng gọi đặt bàn',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
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
                  
                  const SizedBox(height: 24),

                  // Chọn bàn
                  const Text(
                    'Chọn bàn *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _isLoadingTables
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<models.Table>(
                          value: _selectedTable,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.table_restaurant),
                            hintText: 'Chọn bàn trống',
                          ),
                          items: _availableTables.map((table) {
                            return DropdownMenuItem(
                              value: table,
                              child: Text('Bàn ${table.number} - ${table.capacity} người'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedTable = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) return 'Vui lòng chọn bàn';
                            return null;
                          },
                        ),

                  const SizedBox(height: 16),

                  // Tên khách hàng
                  const Text(
                    'Tên khách hàng *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person),
                      hintText: 'Nhập tên khách hàng',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên khách hàng';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Số điện thoại
                  const Text(
                    'Số điện thoại *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.phone),
                      hintText: '0987654321',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập số điện thoại';
                      }
                      if (!RegExp(r'^0\d{9}$').hasMatch(value.trim())) {
                        return 'Số điện thoại không hợp lệ (10 số, bắt đầu bằng 0)';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Ngày và giờ
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ngày đặt *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _selectDate(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                        style: const TextStyle(fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Giờ đặt *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _selectTime(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitReservation,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(_isSubmitting ? 'Đang xử lý...' : 'Xác nhận đặt bàn'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
