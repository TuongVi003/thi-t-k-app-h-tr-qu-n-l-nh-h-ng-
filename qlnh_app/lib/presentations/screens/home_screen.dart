import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'reservation_screen.dart';
import '../../constants/app_colors.dart';
import 'home_tab.dart';
import 'order_history_page.dart';
import 'profile_page.dart';



class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  bool _showReservationTooltip = true;
  
    @override
    void initState() {
      super.initState();
      _selectedIndex = widget.initialIndex;
    }

  List<Widget> get _widgetOptions {
    return [
      const HomeTab(),
      OrderHistoryTab(),
      ProfileTab(),
    ];
  }

  void _onItemTapped(int index) {
    // Allow navigation between tabs for guests; protect sensitive actions instead.
    setState(() {
      _selectedIndex = index;
    });
  }

  void _hideReservationTooltip() {
    setState(() {
      _showReservationTooltip = false;
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // _selectedIndex is initialized from widget.initialIndex in initState
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text(
              'Nhà Hàng Moon',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textWhite,
              ),
            ),
            backgroundColor: AppColors.primary,
            elevation: 0,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.account_circle,
                  color: Colors.white,
                ),
                onSelected: (String value) {
                  if (value == 'logout') {
                    _logout();
                  } else if (value == 'reservation') {
                    _hideReservationTooltip(); // Hide tooltip when reservation is selected
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ReservationScreen()),
                    );
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'reservation',
                    child: ListTile(
                      leading: Icon(Icons.event_seat),
                      title: Text('Đặt bàn'),
                    ),
                  ),

                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Thông tin cá nhân'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings),
                      title: Text('Cài đặt'),
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Đăng xuất'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: _widgetOptions.elementAt(_selectedIndex),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Trang chủ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'Lịch sử',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Tài khoản',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: AppColors.primary,
            onTap: _onItemTapped,
          ),
        ),
        // Floating tooltip overlay
        if (_showReservationTooltip)
          Positioned(
            top: kToolbarHeight + 40, // Move closer to AppBar
            right: 60, // Move closer to the account icon
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Arrow pointing upward to the account icon
                Padding(
                  padding: const EdgeInsets.only(right: 8), // Much closer to right edge
                  child: CustomPaint(
                    size: const Size(80, 30), // Wider and shorter
                    painter: ArrowPainter(),
                  ),
                ),
                const SizedBox(height: 2), // Smaller gap
                // Tooltip box
                Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.accent,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.event_seat,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Đặt bàn tại đây!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _hideReservationTooltip,
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Nhấn vào biểu tượng tài khoản để xem menu đặt bàn',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// Custom painter for drawing curved arrow
class ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Start from the bottom left (from tooltip direction)
    final startX = size.width * 0.2;
    final startY = size.height * 0.9;
    
    // End point (account icon position)
    final endX = size.width * 0.95;
    final endY = 0.0;
    
    // Create a curved path pointing directly to the account icon position
    path.moveTo(startX, startY);
    
    // Curved line going up and sharply to the right (directly to account icon)
    path.quadraticBezierTo(
      size.width * 0.5, // control point x (curve middle)
      size.height * 0.3, // control point y (higher curve)
      endX, // end point x (very close to right edge - account icon position)
      endY, // end point y (top edge - AppBar level)
    );
    
    canvas.drawPath(path, paint);
    
    // Calculate the direction of the curve at the end point
    final controlX = size.width * 0.5;
    final controlY = size.height * 0.3;
    
    // Direction vector from control point to end point
    final directionX = endX - controlX;
    final directionY = endY - controlY;
    
    // Normalize the direction vector
    final length = (directionX * directionX + directionY * directionY).abs();
    final normalizedDirX = directionX / length * 10;
    final normalizedDirY = directionY / length * 10;
    
    // Draw arrowhead
    final arrowheadPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;
    
    final arrowPath = Path();
    
    // Create arrowhead pointing in the direction of the curve
    arrowPath.moveTo(endX, endY);
    arrowPath.lineTo(
      endX - normalizedDirX - normalizedDirY * 0.5, 
      endY - normalizedDirY + normalizedDirX * 0.5
    );
    arrowPath.lineTo(
      endX - normalizedDirX + normalizedDirY * 0.5, 
      endY - normalizedDirY - normalizedDirX * 0.5
    );
    arrowPath.close();
    
    canvas.drawPath(arrowPath, arrowheadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

