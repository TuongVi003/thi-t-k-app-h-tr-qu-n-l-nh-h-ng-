import 'package:flutter/material.dart';
import 'package:qlnh_nhan_vien/screens/table_management_screen.dart';
import 'package:qlnh_nhan_vien/screens/booking_management_screen.dart';
import 'package:qlnh_nhan_vien/screens/login_screen.dart';
import 'package:qlnh_nhan_vien/screens/takeaway_management_screen.dart';
import 'package:qlnh_nhan_vien/services/auth_service.dart';
import 'package:qlnh_nhan_vien/services/takeaway_service.dart';
import 'package:qlnh_nhan_vien/models/user.dart';
import 'package:qlnh_nhan_vien/models/takeaway_order.dart';
import 'package:qlnh_nhan_vien/features/directly_order/directly_order.dart';
import 'package:qlnh_nhan_vien/features/statistics/pages/statistics_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  User? _currentUser;
  bool _isWorkingShift = false;
  bool _isLoadingShift = false;
  List<TakeawayOrder> _pendingOrders = [];
  
  final List<Widget> _screens = [
    const TableManagementScreen(),
    const BookingManagementScreen(),
    const DineInOrderListPage(),
    const TakeawayManagementScreen(),
    const StatisticsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await AuthService.getStoredUser();
    setState(() {
      _currentUser = user;
      _isWorkingShift = user?.dangLamViec ?? false;
    });
    _loadTakeawayOrders();
  }

  Future<void> _refreshUserDataFromServer() async {
    print('Starting user data refresh...');
    try {
      // Use the AuthService method to refresh user profile
      final updatedUser = await AuthService.refreshUserProfile();
      
      if (updatedUser != null) {
        setState(() {
          _currentUser = updatedUser;
          _isWorkingShift = updatedUser.dangLamViec;
        });
        
        print('✅ User data refreshed successfully!');
        print('New working status: ${updatedUser.dangLamViec}');
      } else {
        print('❌ Failed to refresh user profile');
      }
    } catch (e) {
      print('❌ Error refreshing user data: $e');
    }
  }

  Future<void> _loadTakeawayOrders() async {
    try {
      final orders = await TakeawayService.getTakeawayOrders();
      setState(() {
        _pendingOrders = orders.where((order) => order.trangThai == 'dang-doi').toList();
      });
    } catch (e) {
      print('Error loading takeaway orders: $e');
    }
  }

  Future<void> _handleCheckInOut() async {
    if (_isLoadingShift) return;

    setState(() {
      _isLoadingShift = true;
    });

    try {
      Map<String, dynamic> result;
      String message;
      
      if (_isWorkingShift) {
        // Checkout
        result = await TakeawayService.checkOut();
        message = 'Kết thúc ca thành công!';
      } else {
        // Checkin
        result = await TakeawayService.checkIn();
        message = 'Vào ca thành công!';
      }

      print('Check-in/out result: $result');
      
      // Refresh user data from server to get updated working status
      await _refreshUserDataFromServer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingShift = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showUserProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông tin nhân viên'),
        content: _currentUser != null
            ? SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('ID:', _currentUser!.id.toString()),
                    _buildInfoRow('Username:', _currentUser!.username),
                    _buildInfoRow('Họ tên:', _currentUser!.hoTen),
                    _buildInfoRow('Số điện thoại:', _currentUser!.soDienThoai),
                    _buildInfoRow('Loại người dùng:', _getChucVuDisplay(_currentUser!.loaiNguoiDung)),
                    _buildInfoRow('Chức vụ:', _getChucVuDisplay(_currentUser!.chucVu)),
                    _buildInfoRow('Ca làm:', _getCaLamDisplay(_currentUser!.caLam)),
                    _buildInfoRow('Đang làm việc:', _currentUser!.dangLamViec ? 'Có' : 'Không'),
                    _buildInfoRow('Trạng thái hoạt động:', _currentUser!.isActive ? 'Hoạt động' : 'Không hoạt động'),
                    _buildInfoRow('Đăng nhập lần cuối:', _currentUser!.lastLogin != null 
                        ? '${_currentUser!.lastLogin!.day}/${_currentUser!.lastLogin!.month}/${_currentUser!.lastLogin!.year} ${_currentUser!.lastLogin!.hour}:${_currentUser!.lastLogin!.minute.toString().padLeft(2, '0')}' 
                        : 'Chưa đăng nhập'),
                    _buildInfoRow('Ngày tham gia:', '${_currentUser!.dateJoined.day}/${_currentUser!.dateJoined.month}/${_currentUser!.dateJoined.year}'),
                    _buildInfoRow('Email:', _currentUser!.email ?? 'Chưa có'),
                  ],
                ),
              )
            : const CircularProgressIndicator(),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: _handleLogout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getChucVuDisplay(String chucVu) {
    switch (chucVu) {
      case 'khach_hang':
        return 'Khách hàng';
      case 'nhan_vien':
        return 'Nhân Viên';
      default:
        return chucVu;
    }
  }

  String _getCaLamDisplay(String? caLam) {
    if (caLam == null) return 'Chưa có';
    switch (caLam) {
      case 'sang':
        return 'Ca sáng (8:00-14:00)';
      case 'chieu':
        return 'Ca chiều (14:00-20:00)';
      case 'dem':
        return 'Ca đêm (20:00-24:00)';
      default:
        return caLam;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản lý Nhà hàng',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  // Navigate to takeaway orders
                  setState(() {
                    _selectedIndex = 3; // Takeaway tab
                  });
                },
              ),
              if (_pendingOrders.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_pendingOrders.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  _showUserProfile();
                  break;
                case 'checkinout':
                  _handleCheckInOut();
                  break;
                case 'logout':
                  _handleLogout();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_currentUser?.hoTen ?? 'Thông tin'),
                        Text(
                          _isWorkingShift ? 'Đang trong ca' : 'Ngoài ca',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isWorkingShift ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'checkinout',
                child: Row(
                  children: [
                    Icon(
                      _isWorkingShift ? Icons.logout : Icons.login,
                      color: _isWorkingShift ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isWorkingShift ? 'Kết thúc ca' : 'Vào ca',
                      style: TextStyle(
                        color: _isWorkingShift ? Colors.red : Colors.green,
                      ),
                    ),
                    if (_isLoadingShift)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.table_restaurant),
            label: 'Bàn ăn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_history),
            label: 'QL Đặt bàn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Đặt món',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.takeout_dining),
            label: 'Mang về',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Thống kê',
          ),
        ],
      ),
    );
  }
}

