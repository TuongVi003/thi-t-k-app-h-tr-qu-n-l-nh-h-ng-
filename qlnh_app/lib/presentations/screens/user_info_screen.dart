import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';
import '../../constants/app_colors.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await UserService.instance.getCurrentUser();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thông tin: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thông tin cá nhân',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Không thể tải thông tin người dùng',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadUserInfo,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUserInfo,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Avatar Section
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _user!.displayName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '@${_user!.username}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Account Information Section
                        _buildSectionTitle('Thông tin tài khoản'),
                        const SizedBox(height: 12),
                        _buildInfoCard([
                          const Divider(height: 1),
                          _buildInfoRow(
                            Icons.account_circle_outlined,
                            'Tên đăng nhập',
                            _user!.username,
                          ),
                          const Divider(height: 1),
                          _buildInfoRow(
                            Icons.person_outline,
                            'Họ tên',
                            _user!.hoTen.isNotEmpty ? _user!.hoTen : 'Chưa cập nhật',
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // Contact Information Section
                        _buildSectionTitle('Thông tin liên hệ'),
                        const SizedBox(height: 12),
                        _buildInfoCard([
                          _buildInfoRow(
                            Icons.email_outlined,
                            'Email',
                            _user!.email.isNotEmpty ? _user!.email : 'Chưa cập nhật',
                          ),
                          const Divider(height: 1),
                          _buildInfoRow(
                            Icons.phone_outlined,
                            'Số điện thoại',
                            _user!.soDienThoai.isNotEmpty
                                ? _user!.soDienThoai
                                : 'Chưa cập nhật',
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // Account Status Section
                        _buildSectionTitle('Trạng thái tài khoản'),
                        const SizedBox(height: 12),
                        _buildInfoCard([
                          _buildInfoRow(
                            Icons.check_circle_outline,
                            'Kích hoạt',
                            _user!.isActive ? 'Đã kích hoạt' : 'Chưa kích hoạt',
                            valueColor: _user!.isActive ? Colors.green : Colors.red,
                          ),
                          const Divider(height: 1),
                          _buildInfoRow(
                            Icons.calendar_today_outlined,
                            'Ngày tham gia',
                            _formatDate(_user!.dateJoined),
                          ),
                          if (_user!.lastLogin != null) ...[
                            const Divider(height: 1),
                            _buildInfoRow(
                              Icons.login_outlined,
                              'Đăng nhập lần cuối',
                              _formatDate(_user!.lastLogin!),
                            ),
                          ],
                        ]),

                        const SizedBox(height: 32),

                        // Edit Button -> opens a dialog where user can edit allowed fields
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (_user == null) return;

                              final result = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  String hoTen = _user!.hoTen;
                                  String email = _user!.email;
                                  String soDienThoai = _user!.soDienThoai;
                                  String password = '';
                                  bool _saving = false;
                                  final _formKey = GlobalKey<FormState>();

                                  return StatefulBuilder(builder: (context, setState) {
                                    return AlertDialog(
                                      title: const Text('Chỉnh sửa thông tin'),
                                      content: Form(
                                        key: _formKey,
                                        child: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextFormField(
                                                initialValue: hoTen,
                                                decoration: const InputDecoration(labelText: 'Họ tên'),
                                                onChanged: (v) => hoTen = v.trim(),
                                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Họ tên không được để trống' : null,
                                              ),
                                              const SizedBox(height: 12),
                                              TextFormField(
                                                initialValue: email,
                                                decoration: const InputDecoration(labelText: 'Email'),
                                                onChanged: (v) => email = v.trim(),
                                                keyboardType: TextInputType.emailAddress,
                                                validator: (v) {
                                                  if (v == null || v.trim().isEmpty) return null; // email optional
                                                  final val = v.trim();
                                                  final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}");
                                                  return emailRegex.hasMatch(val) ? null : 'Email không hợp lệ';
                                                },
                                              ),
                                              const SizedBox(height: 12),
                                              TextFormField(
                                                initialValue: soDienThoai,
                                                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                                                onChanged: (v) => soDienThoai = v.trim(),
                                                keyboardType: TextInputType.phone,
                                              ),
                                              const SizedBox(height: 12),
                                              TextFormField(
                                                decoration: const InputDecoration(labelText: 'Mật khẩu - để trống nếu không đổi'),
                                                onChanged: (v) => password = v,
                                                obscureText: true,
                                                validator: (v) {
                                                  if (v == null || v.isEmpty) return null;
                                                  return v.length >= 6 ? null : 'Mật khẩu phải >= 6 ký tự';
                                                },
                                              ),
                                              if (_saving)
                                                const Padding(
                                                  padding: EdgeInsets.only(top: 12.0),
                                                  child: CircularProgressIndicator(),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                                          child: const Text('Hủy'),
                                        ),
                                        ElevatedButton(
                                          onPressed: _saving
                                              ? null
                                              : () async {
                                                  if (!(_formKey.currentState?.validate() ?? false)) return;
                                                  setState(() {
                                                    _saving = true;
                                                  });

                                                  final res = await UserService.instance.updateCurrentUser(
                                                    hoTen: hoTen,
                                                    email: email.isEmpty ? null : email,
                                                    soDienThoai: soDienThoai.isEmpty ? null : soDienThoai,
                                                    password: password.isEmpty ? null : password,
                                                  );

                                                  setState(() {
                                                    _saving = false;
                                                  });

                                                  if (res['ok'] == true) {
                                                    Navigator.of(context).pop(true);
                                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công')));
                                                  } else {
                                                    final msg = res['message'] ?? 'Cập nhật thất bại';
                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.toString())));
                                                  }
                                                },
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                          child: const Text('Lưu'),
                                        ),
                                      ],
                                    );
                                  });
                                },
                              );

                              if (result == true) {
                                await _loadUserInfo();
                              }
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Chỉnh sửa thông tin'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: AppColors.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor ?? Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
