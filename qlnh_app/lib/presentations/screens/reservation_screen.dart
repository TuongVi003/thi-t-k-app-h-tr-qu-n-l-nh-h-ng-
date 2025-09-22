import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../../services/auth_service.dart';

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

  final List<String> _areas = [
    'Gần cửa sổ',
    'Khu trong nhà',
    'Khu ngoài trời',
    'Phòng riêng',
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

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null) return;

    setState(() {
      _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _submit() {
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

      // For now just show a confirmation dialog; in a real app we'd call an API.
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận đặt bàn'),
          content: Text('Bạn muốn đặt bàn cho $_people người tại ${_area ?? 'Không chọn'} vào ${_dateTime.toString()} ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đặt bàn thành công')));
                Navigator.pop(context);
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt bàn'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Số người', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (_people > 1) _people--;
                      });
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$_people', style: const TextStyle(fontSize: 18)),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _people++;
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text('Khu vực mong muốn', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _area,
                items: _areas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                onChanged: (v) => setState(() => _area = v),
                validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng chọn khu vực' : null,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),

              const SizedBox(height: 16),

              const Text('Thời gian tới nhà hàng', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(_dateTime == null ? 'Chưa chọn' : '${_dateTime!.toLocal()}'.split('.').first),
                  ),
                  ElevatedButton(
                    onPressed: _pickDateTime,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
                    child: const Text('Chọn'),
                  ),
                ],
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('Đặt bàn', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
