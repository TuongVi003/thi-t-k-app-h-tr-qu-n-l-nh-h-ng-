import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../../services/auth_service.dart';


// Profile Tab
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final bool loggedIn = AuthService.instance.isLoggedIn;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tài khoản',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),

          if (!loggedIn)
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text('Bạn đang xem dưới tư cách khách.'),
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
                    )
                  ],
                ),
              ),
            )
          else
            // Profile info card for logged-in users (simple placeholder)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.orange.shade100,
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nguyễn Văn A',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'nguyenvana@email.com',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Menu options
          Expanded(
            child: ListView(
              children: [
                _buildMenuOption(Icons.person_outline, 'Thông tin cá nhân', () async {
                  if (!AuthService.instance.isLoggedIn) {
                    final res = await Navigator.push<bool?>(
                      context,
                      MaterialPageRoute(builder: (c) => const LoginScreen()),
                    );
                    if (res != true && !AuthService.instance.isLoggedIn) return;
                  }
                  // TODO: open personal info screen
                }),
                _buildMenuOption(Icons.location_on_outlined, 'Địa chỉ giao hàng', () async {
                  if (!AuthService.instance.isLoggedIn) {
                    final res = await Navigator.push<bool?>(
                      context,
                      MaterialPageRoute(builder: (c) => const LoginScreen()),
                    );
                    if (res != true && !AuthService.instance.isLoggedIn) return;
                  }
                }),
                _buildMenuOption(Icons.payment, 'Phương thức thanh toán', () async {
                  if (!AuthService.instance.isLoggedIn) {
                    final res = await Navigator.push<bool?>(
                      context,
                      MaterialPageRoute(builder: (c) => const LoginScreen()),
                    );
                    if (res != true && !AuthService.instance.isLoggedIn) return;
                  }
                }),
                _buildMenuOption(Icons.notifications_outlined, 'Thông báo', () {}),
                _buildMenuOption(Icons.help_outline, 'Hỗ trợ', () {}),
                _buildMenuOption(Icons.info_outline, 'Về chúng tôi', () {}),
                const Divider(),
                _buildMenuOption(Icons.logout, 'Đăng xuất', () {
                  if (AuthService.instance.isLoggedIn) {
                    AuthService.instance.logout();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đăng xuất')));
                  }
                }, textColor: Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption(IconData icon, String title, VoidCallback onTap, {Color? textColor}) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

