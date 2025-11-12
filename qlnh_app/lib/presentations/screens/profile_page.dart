import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'user_info_screen.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/user.dart';


// Profile Tab
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  User? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (!AuthService.instance.isLoggedIn) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await UserService.instance.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLoginSuccess() async {
    await _loadUserProfile();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng nhập thành công')),
      );
    }
  }

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
                          await _handleLoginSuccess();
                        }
                      },
                      child: const Text('Đăng nhập'),
                    )
                  ],
                ),
              ),
            )
          else
            // Profile info card for logged-in users
            _isLoading
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                : Card(
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentUser?.displayName ?? 'Người dùng',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _currentUser?.contactInfo ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                if (_currentUser?.soDienThoai.isNotEmpty ?? false)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'SĐT: ${_currentUser?.soDienThoai}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
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
                  // Navigate to user info screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserInfoScreen()),
                  );
                }),
                
                _buildMenuOption(Icons.notifications_outlined, 'Thông báo', () {}),
                // _buildMenuOption(Icons.help_outline, 'Hỗ trợ', () {}),
                // _buildMenuOption(Icons.info_outline, 'Về chúng tôi', () {}),
                const Divider(),
                _buildMenuOption(Icons.logout, 'Đăng xuất', () async {
                  if (AuthService.instance.isLoggedIn) {
                    // CRITICAL: Wait for logout to complete
                    await AuthService.instance.logout();
                    
                    // Update state
                    if (mounted) {
                      setState(() {
                        _currentUser = null;
                      });
                    }
                    
                    // Navigate to login screen with mounted check
                    if (mounted && context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false, // Remove all previous routes
                      );
                      
                      // Show snackbar after navigation
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã đăng xuất'))
                          );
                        }
                      });
                    }
                  }
                  else {
                    if (mounted && context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
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

