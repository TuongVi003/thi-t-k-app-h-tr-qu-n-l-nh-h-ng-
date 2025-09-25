import 'package:flutter/material.dart';
import '../models/don_hang.dart';
import '../services/api_service.dart';

class BookingManagementScreen extends StatefulWidget {
  const BookingManagementScreen({super.key});

  @override
  State<BookingManagementScreen> createState() => _BookingManagementScreenState();
}

class _BookingManagementScreenState extends State<BookingManagementScreen> {
  List<DonHang> bookings = [];
  bool isLoading = false;
  String? errorMessage;
  DonHangStatus? selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final bookingList = await ApiService.fetchDonHangList();
      setState(() {
        bookings = bookingList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi tải dữ liệu: $e';
        isLoading = false;
      });
    }
  }

  List<DonHang> get filteredBookings {
    if (selectedStatusFilter == null) {
      return bookings;
    }
    return bookings.where((booking) => booking.trangThai == selectedStatusFilter).toList();
  }

  Future<void> _updateBookingStatus(DonHang booking, DonHangStatus newStatus) async {
    try {
      setState(() {
        isLoading = true;
      });

      await ApiService.updateBookingStatus(
        booking.id,
        newStatus.apiValue,
      );

      // Hiển thị thông báo thành công
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật trạng thái thành ${newStatus.displayName}. Đang tải lại dữ liệu...'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Gọi lại API để lấy dữ liệu mới nhất từ backend
      await _loadBookings();
      
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStatusUpdateDialog(DonHang booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cập nhật trạng thái - Bàn ${booking.banAn.soBan}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Khách hàng: ${booking.khachHang.hoTen}'),
            Text('Số điện thoại: ${booking.khachHang.soDienThoai}'),
            Text('Trạng thái hiện tại: ${booking.trangThai.displayName}'),
            const SizedBox(height: 16),
            const Text('Chọn trạng thái mới:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...DonHangStatus.values.map((status) => ListTile(
              leading: Icon(
                Icons.circle,
                color: status.color,
                size: 12,
              ),
              title: Text(status.displayName),
              onTap: () {
                Navigator.pop(context);
                if (status != booking.trangThai) {
                  _updateBookingStatus(booking, status);
                }
              },
              trailing: booking.trangThai == status 
                ? const Icon(Icons.check, color: Colors.green) 
                : null,
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đặt bàn'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang tải lại dữ liệu từ server...'),
                  duration: Duration(seconds: 1),
                ),
              );
              await _loadBookings();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới dữ liệu từ server',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.filter_list, size: 18, color: const Color(0xFF2E7D32)),
                    const SizedBox(width: 8),
                    Text(
                      'Lọc theo trạng thái (Local):',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildStatusFilterChip('Tất cả', null),
                    ...DonHangStatus.values.map((status) => 
                      _buildStatusFilterChip(status.displayName, status)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Lưu ý: Filter chỉ áp dụng trên dữ liệu đã tải. Dùng nút Refresh để tải mới từ server.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Statistics
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2E7D32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Chờ xác nhận',
                  bookings.where((b) => b.trangThai == DonHangStatus.pending).length,
                  DonHangStatus.pending.color,
                ),
                _buildStatCard(
                  'Đã xác nhận',
                  bookings.where((b) => b.trangThai == DonHangStatus.confirmed).length,
                  DonHangStatus.confirmed.color,
                ),
                _buildStatCard(
                  'Đã hủy',
                  bookings.where((b) => b.trangThai == DonHangStatus.canceled).length,
                  DonHangStatus.canceled.color,
                ),
              ],
            ),
          ),

          // Booking list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đang làm mới từ server...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                await _loadBookings();
              },
              child: isLoading && bookings.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF2E7D32)),
                          SizedBox(height: 16),
                          Text('Đang tải danh sách đặt bàn từ server...'),
                        ],
                      ),
                    )
                  : errorMessage != null && bookings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, 
                                size: 64, 
                                color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadBookings,
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredBookings.length,
                          itemBuilder: (context, index) {
                            final booking = filteredBookings[index];
                            return _buildBookingCard(booking);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, DonHangStatus? status) {
    final isSelected = selectedStatusFilter == status;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedStatusFilter = selectedStatusFilter == status ? null : status;
          });
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF2E7D32),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBookingCard(DonHang booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bàn ${booking.banAn.soBan}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: booking.trangThai.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: booking.trangThai.color),
                  ),
                  child: Text(
                    booking.trangThai.displayName,
                    style: TextStyle(
                      color: booking.trangThai.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Khách hàng: ${booking.khachHang.hoTen}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'SĐT: ${booking.khachHang.soDienThoai}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Sức chứa: ${booking.banAn.sucChua} người',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Khu vực: ${booking.banAn.khuVuc}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Ngày đặt: ${_formatDateTime(booking.ngayDat)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            if (booking.khachVangLai != null) ...[
              const SizedBox(height: 4),
              Text(
                'Khách vãng lai: ${booking.khachVangLai}',
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  ElevatedButton(
                    onPressed: () => _showStatusUpdateDialog(booking),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cập nhật trạng thái'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}