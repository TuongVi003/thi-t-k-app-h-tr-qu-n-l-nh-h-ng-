import 'package:flutter/material.dart';
import 'package:qlnh_app/models/cart_item.dart';
import 'package:qlnh_app/models/takeaway_order.dart';
import 'package:qlnh_app/presentations/takeaway/service/takeaway_service.dart';
import 'package:qlnh_app/constants/app_colors.dart';
import 'login_screen.dart';
import 'package:qlnh_app/services/auth_service.dart';
import '../takeaway/pages/takeaway_success_screen.dart';
import 'package:qlnh_app/constants/utils.dart';

class CartTab extends StatefulWidget {
  final List<CartItem> cartItems;
  final Function(String) onRemoveFromCart;
  final Function(String, int) onUpdateQuantity;
  final double totalPrice;
  final VoidCallback? onClearCart;

  const CartTab({
    super.key,
    required this.cartItems,
    required this.onRemoveFromCart,
    required this.onUpdateQuantity,
    required this.totalPrice,
    this.onClearCart,
  });

  @override
  State<CartTab> createState() => _CartTabState();
}

class _CartTabState extends State<CartTab> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckout(BuildContext context) async {
    // Check login
    if (!AuthService.instance.isLoggedIn) {
      final result = await Navigator.push<bool?>(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      if (result != true && !AuthService.instance.isLoggedIn) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bạn cần đăng nhập để đặt hàng')),
          );
        }
        return;
      }
    }

    // Pick date and time before showing loading
    final thoiGianLayMon = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
      initialDate: DateTime.now(),
      helpText: '',  // Empty to hide default helpText
      builder: (context, child) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Custom large help text header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accent, AppColors.accentDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: AppColors.textWhite,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'CHỌN NGÀY LẤY MÓN',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Native picker with custom theme, constrained to avoid vertical overflow
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: AppColors.accent,
                      onPrimary: AppColors.textWhite,
                      surface: AppColors.surface,
                      onSurface: AppColors.textPrimary,
                    ),
                    dialogBackgroundColor: AppColors.surface,
                  ),
                  child: SingleChildScrollView(child: child!),
                ),
              ),
            ],
          ),
        );
      },
    );
    
    if (thoiGianLayMon == null || !context.mounted) return;
    
    // Ensure user cannot pick a past time when the chosen date is today.
    final now = DateTime.now();
    final bool isToday = thoiGianLayMon.year == now.year &&
        thoiGianLayMon.month == now.month &&
        thoiGianLayMon.day == now.day;

    TimeOfDay initialTime = isToday
        ? TimeOfDay.fromDateTime(now.add(const Duration(minutes: 1)))
        : TimeOfDay.now();

    TimeOfDay? gioLayMon;
    DateTime ngayLayMon;

    while (true) {
      gioLayMon = await showTimePicker(
        context: context,
        initialTime: initialTime,
        helpText: '', // Empty to hide default helpText
        builder: (context, child) {
          return Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Custom large help text header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.accent, AppColors.accentDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: AppColors.textWhite,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'CHỌN GIỜ LẤY MÓN',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textWhite,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Native picker with custom theme, constrained to avoid vertical overflow
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: AppColors.accent,
                        onPrimary: AppColors.textWhite,
                        surface: AppColors.surface,
                        onSurface: AppColors.textPrimary,
                      ),
                      timePickerTheme: TimePickerThemeData(
                        dialHandColor: AppColors.accent,
                        dialBackgroundColor: AppColors.primaryVeryLight,
                        hourMinuteTextColor: MaterialStateColor.resolveWith(
                          (states) => AppColors.textPrimary,
                        ),
                      ),
                    ),
                    child: SingleChildScrollView(child: child!),
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (gioLayMon == null || !context.mounted) return;

      ngayLayMon = DateTime(
        thoiGianLayMon.year,
        thoiGianLayMon.month,
        thoiGianLayMon.day,
        gioLayMon.hour,
        gioLayMon.minute,
      );

      if (isToday && ngayLayMon.isBefore(now)) {
        final retry = await showDialog<bool?>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Thời gian không hợp lệ'),
            content: const Text('Bạn đã chọn giờ trong quá khứ. Vui lòng chọn giờ trong tương lai.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Chọn lại')),
            ],
          ),
        );

        if (retry == true) {
          // update initialTime to now+1min to help user pick a valid time
          initialTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(minutes: 1)));
          continue; // re-open time picker
        }
        return; // user cancelled
      }

      break; // picked valid time
    }

    // Ask for delivery method (pickup or delivery) and collect address if needed
    String? phuongThucGiaoHang;
    String? diaChiGiaoHang;

    final deliveryResult = await showDialog<Map<String, String?>?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        String selected = 'Tự đến lấy';
        final TextEditingController _addrCtl = TextEditingController();
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Phương thức giao hàng'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  value: 'Tự đến lấy',
                  groupValue: selected,
                  title: const Text('Tự đến lấy'),
                  onChanged: (v) => setState(() {
                    selected = v!;
                  }),
                ),
                RadioListTile<String>(
                  value: 'Giao hàng tận nơi',
                  groupValue: selected,
                  title: const Text('Giao hàng tận nơi'),
                  onChanged: (v) => setState(() {
                    selected = v!;
                  }),
                ),
                if (selected == 'Giao hàng tận nơi') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addrCtl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ giao hàng',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Hủy')),
              TextButton(
                onPressed: () {
                  if (selected == 'Giao hàng tận nơi' && _addrCtl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Vui lòng nhập địa chỉ giao hàng')));
                    return;
                  }
                  Navigator.of(ctx).pop({
                    'phuong_thuc_giao_hang': selected,
                    'dia_chi_giao_hang': _addrCtl.text.trim(),
                  });
                },
                child: const Text('Xác nhận'),
              ),
            ],
          ),
        );
      },
    );

    if (deliveryResult == null || !context.mounted) return;

    phuongThucGiaoHang = deliveryResult['phuong_thuc_giao_hang'];
    diaChiGiaoHang = deliveryResult['dia_chi_giao_hang'];

    // Show loading after getting time and delivery info
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      // Convert CartItem to TakeawayCartItem
      final takeawayItems = widget.cartItems.map((cartItem) {
        return TakeawayCartItem(
          monAnId: int.parse(cartItem.menuItem.id),
          tenMon: cartItem.menuItem.name,
          gia: cartItem.menuItem.price,
          hinhAnh: cartItem.menuItem.imageUrl,
          moTa: cartItem.menuItem.description,
          soLuong: cartItem.quantity,
        );
      }).toList();

      // Create takeaway order
      final order = await TakeawayService.createTakeawayOrder(
        cartItems: takeawayItems,
        ngay: ngayLayMon,
        ghiChu: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      // Close loading
      if (context.mounted) {
        Navigator.pop(context);

        // Clear cart
        widget.onClearCart?.call();

        print('Đặt hàng mang về thành công: ${order.toFullJson()}');
        // Navigate to success screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TakeawaySuccessScreen(order: order),
          ),
        );
      }
    } catch (e) {
      // Close loading
      print('Lỗi khi đặt hàng mang về: ${e}');
      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đặt hàng: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            'Giỏ hàng',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (!loggedIn)
            Card(
              color: AppColors.infoBackground,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Bạn đang xem dưới tư cách khách. Đăng nhập để lưu giỏ hàng và đặt hàng.',
                        style: TextStyle(color: AppColors.info),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final result = await Navigator.push<bool?>(
                          context,
                          MaterialPageRoute(
                              builder: (c) => const LoginScreen()),
                        );
                        if (result == true || AuthService.instance.isLoggedIn) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Đăng nhập thành công')),
                          );
                        }
                      },
                      child: const Text('Đăng nhập'),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.cartItems.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Giỏ hàng trống',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hãy thêm một số món ăn vào giỏ hàng',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Expanded(
              child: ListView.builder(
                itemCount: widget.cartItems.length,
                itemBuilder: (context, index) {
                  final cartItem = widget.cartItems[index];
                  final item = cartItem.menuItem;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          if (cartItem.menuItem.imageUrl.isEmpty)
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.primaryVeryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.restaurant,
                                size: 30,
                                color: AppColors.primary,
                              ),
                            )
                          else
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  Utils.imageUrl(cartItem.menuItem.imageUrl),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: AppColors.primaryVeryLight,
                                    child: const Icon(
                                      Icons.restaurant,
                                      size: 30,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ₫',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => widget.onUpdateQuantity(
                                    item.id, cartItem.quantity - 1),
                                icon: const Icon(Icons.remove_circle_outline),
                                color: AppColors.textSecondary,
                              ),
                              Text(
                                cartItem.quantity.toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () => widget.onUpdateQuantity(
                                    item.id, cartItem.quantity + 1),
                                icon: const Icon(Icons.add_circle_outline),
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => widget.onRemoveFromCart(item.id),
                            icon: const Icon(Icons.delete_outline),
                            color: AppColors.error,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Note input
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ghi chú (tùy chọn)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: Không hành, ít cay, giao nhanh...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Total and checkout section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng cộng:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.totalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ₫',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleCheckout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textWhite,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Đặt hàng mang về',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
