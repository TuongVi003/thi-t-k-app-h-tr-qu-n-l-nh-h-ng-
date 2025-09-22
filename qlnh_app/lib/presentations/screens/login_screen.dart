import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      final username = _emailController.text.trim();
      final password = _passwordController.text;

      final result = await AuthService.instance.loginWithApi(
        username: username,
        password: password,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (result['ok'] == true) {
        // If LoginScreen was pushed (can pop), return true to caller so it can continue
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        } else {
          // Otherwise (app entry), replace with HomeScreen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
            (route) => false,
          );
        }
      } else {
        final msg = result['message'] ?? 'Đăng nhập thất bại';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg.toString())),
        );
      }
    }
  }

  void _continueAsGuest() {
    // Do not mark as logged in. If this screen was pushed, just pop back with false.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(false);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo/Title section
                Column(
                  children: [
                    Icon(
                      Icons.restaurant,
                      size: 80,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Quản Lý Nhà Hàng',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đăng nhập để tiếp tục',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Phone field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại / Tên đăng nhập',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số điện thoại hoặc tên đăng nhập';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Login button
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Đăng nhập',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Continue as guest
                TextButton(
                  onPressed: _continueAsGuest,
                  child: Text(
                    'Tiếp tục không đăng nhập',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),

                // Forgot password
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chức năng đang được phát triển'),
                      ),
                    );
                  },
                  child: Text(
                    'Quên mật khẩu?',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
                // Register link
                TextButton(
                  onPressed: () async {
                    final res = await Navigator.of(context).push<bool?>(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                    // If registration succeeded (returned true), show message
                    if (res == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đăng ký thành công. Vui lòng đăng nhập.')),
                      );
                    }
                  },
                  child: Text(
                    'Đăng ký',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}