import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../../services/auth_service.dart';
import '../../services/reservation_service.dart';
import '../../constants/app_colors.dart';
import '../../models/model.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final _formKey = GlobalKey<FormState>();

  int _people = 2;
  String? _area;
  DateTime? _dateTime;
  BanAn? _selectedTable;
  List<BanAn> _availableTables = [];
  bool _isLoadingTables = false;

  final List<Map<String, String>> _areas = [
    {'id': 'inside', 'name': 'Trong nhà'},
    {'id': 'outside', 'name': 'Ngoài trời'},
    {'id': 'private-room', 'name': 'VIP'},
  ];

  void _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;

    // Choose a sensible initial time. If the user picked today's date, start
    // the time picker at the current time (plus one minute) so selecting a
    // past time is less likely.
    final bool isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final initialTime = isToday
        ? TimeOfDay.fromDateTime(now.add(const Duration(minutes: 1)))
        : TimeOfDay(hour: now.hour, minute: 0);

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (time == null) return;

    final selected = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    // If the user selected a past time for today, show a dialog and allow
    // them to pick again or cancel.
    if (isToday && selected.isBefore(now)) {
      final retry = await showDialog<bool?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Thời gian không hợp lệ'),
          content: const Text('Bạn đã chọn thời gian trong quá khứ. Vui lòng chọn thời gian trong tương lai.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Chọn lại'),
            ),
          ],
        ),
      );

      if (retry == true) {
        // Let user pick date/time again.
        _pickDateTime();
        return;
      }
      return;
    }

    setState(() {
      _dateTime = selected;
    });
  }

  Future<void> _loadTablesForArea(String khuVuc) async {
    setState(() {
      _isLoadingTables = true;
      _selectedTable = null;
    });

    try {
      final tables = await ReservationService.getTablesForReservation(khuVuc);
      // Hiển thị tất cả bàn, không filter available
      if (mounted) {
        setState(() {
          _availableTables = tables;
          _isLoadingTables = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTables = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải danh sách bàn: $e')),
        );
      }
    }
  }

  void _onAreaChanged(String? newArea) {
    setState(() {
      _area = newArea;
      _selectedTable = null;
    });
    if (newArea != null) {
      _loadTablesForArea(newArea);
    }
  }

  void _onPeopleChanged() {
    // Reload tables when number of people changes
    if (_area != null) {
      _loadTablesForArea(_area!);
    }
  }

  void _submit() async {
    if (!AuthService.instance.isLoggedIn) {
      // Redirect to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      if (_dateTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn thời gian tới nhà hàng')),
        );
        return;
      }

      if (_selectedTable == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn bàn')),
        );
        return;
      }

      try {
          await ReservationService.makeReservation(
          accessToken: AuthService.instance.accessToken!,
          sucChua: _people,
          khuVuc: _area!,
          ngayDat: _dateTime!,
          banAnId: _selectedTable!.id,
        );

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đặt bàn thành công')));

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đặt bàn thất bại: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt bàn'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.accent.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Vui lòng điền đầy đủ thông tin để đặt bàn',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Số người',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (_people > 1) _people--;
                      });
                      _onPeopleChanged();
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppColors.primary,
                  ),
                  Text(
                    '$_people',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _people++;
                      });
                      _onPeopleChanged();
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.accent,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Khu vực mong muốn',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _area,
                items: _areas.map((a) => DropdownMenuItem(value: a['id'], child: Text(a['name']!))).toList(),
                onChanged: _onAreaChanged,
                validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng chọn khu vực' : null,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Chọn bàn',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoadingTables)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_area == null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, color: AppColors.textSecondary),
                      SizedBox(width: 8),
                      Text(
                        'Vui lòng chọn khu vực trước',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else if (_availableTables.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.table_restaurant, color: AppColors.textSecondary),
                      SizedBox(width: 8),
                      Text(
                        'Không có bàn nào trong khu vực này',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: _availableTables.length,
                    itemBuilder: (context, index) {
                      final table = _availableTables[index];
                      final isSelected = _selectedTable?.id == table.id;
                      final canSelect = table.isAvailable && table.sucChua >= _people;

                      return InkWell(
                        onTap: canSelect ? () => setState(() => _selectedTable = table) : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : table.isOccupied
                                    ? AppColors.error.withOpacity(0.1)
                                    : table.isUnderMaintenance
                                        ? AppColors.warning.withOpacity(0.1)
                                        : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : table.isOccupied
                                      ? AppColors.error
                                      : table.isUnderMaintenance
                                          ? AppColors.warning
                                          : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ] : null,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.table_restaurant,
                                  size: 20,
                                  color: isSelected
                                      ? AppColors.textWhite
                                      : table.isOccupied
                                          ? AppColors.error
                                          : table.isUnderMaintenance
                                              ? AppColors.warning
                                              : AppColors.primary,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Bàn ${table.soban}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? AppColors.textWhite
                                        : table.isOccupied
                                            ? AppColors.error
                                            : table.isUnderMaintenance
                                                ? AppColors.warning
                                                : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${table.sucChua} người',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isSelected
                                        ? AppColors.textWhite.withOpacity(0.8)
                                        : table.isOccupied
                                            ? AppColors.error.withOpacity(0.7)
                                            : table.isUnderMaintenance
                                                ? AppColors.warning.withOpacity(0.7)
                                                : AppColors.textSecondary,
                                  ),
                                ),
                                if (table.isOccupied) ...[
                                  const SizedBox(height: 1),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Đã đặt',
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: AppColors.textWhite,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ] 
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 24),

              const Text(
                'Thời gian tới nhà hàng',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.surface,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _dateTime == null
                            ? 'Chưa chọn thời gian'
                            : '${_dateTime!.day}/${_dateTime!.month}/${_dateTime!.year} ${_dateTime!.hour.toString().padLeft(2, '0')}:${_dateTime!.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 15,
                          color: _dateTime == null ? AppColors.textLight : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _pickDateTime,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.textWhite,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Chọn'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.event_seat),
                  label: const Text(
                    'Đặt bàn',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
