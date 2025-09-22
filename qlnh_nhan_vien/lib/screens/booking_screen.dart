import 'package:flutter/material.dart';
import 'package:qlnh_nhan_vien/models/booking.dart';
import 'package:qlnh_nhan_vien/models/table.dart' as models;
import 'package:qlnh_nhan_vien/widgets/booking_card.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Booking> bookings = [];
  List<models.Table> availableTables = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
    _loadAvailableTables();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadBookings() {
    // Dữ liệu mẫu
    bookings = [
      Booking(
        id: '1',
        customerName: 'Nguyễn Văn A',
        customerPhone: '0123456789',
        customerEmail: 'nva@email.com',
        bookingTime: DateTime.now().add(const Duration(hours: 1)),
        numberOfGuests: 4,
        preferredTableNumber: 2,
        status: BookingStatus.confirmed,
        specialRequests: 'Gần cửa sổ',
      ),
      Booking(
        id: '2',
        customerName: 'Trần Thị B',
        customerPhone: '0987654321',
        bookingTime: DateTime.now().add(const Duration(hours: 2)),
        numberOfGuests: 2,
        preferredTableNumber: 5,
        status: BookingStatus.pending,
      ),
      Booking(
        id: '3',
        customerName: 'Lê Văn C',
        customerPhone: '0345678912',
        bookingTime: DateTime.now().subtract(const Duration(hours: 1)),
        numberOfGuests: 6,
        status: BookingStatus.completed,
      ),
    ];
  }

  void _loadAvailableTables() {
    // Dữ liệu mẫu các bàn trống
    availableTables = [
      models.Table(id: '1', number: 1, capacity: 2, status: models.TableStatus.available),
      models.Table(id: '4', number: 4, capacity: 4, status: models.TableStatus.available),
      models.Table(id: '7', number: 7, capacity: 4, status: models.TableStatus.available),
    ];
  }

  void _showNewBookingForm() {
    showDialog(
      context: context,
      builder: (context) => NewBookingDialog(
        availableTables: availableTables,
        onBookingCreated: (newBooking) {
          setState(() {
            bookings.add(newBooking);
          });
        },
      ),
    );
  }

  List<Booking> get todayBookings {
    return bookings.where((booking) => booking.isToday()).toList();
  }

  List<Booking> get upcomingBookings {
    return bookings.where((booking) => booking.isUpcoming() && !booking.isToday()).toList();
  }

  List<Booking> get pastBookings {
    return bookings.where((booking) => !booking.isUpcoming()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120), // Tăng height
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min, // Thêm dòng này
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Giảm vertical padding
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded( // Thêm Expanded
                          child: Text(
                            'Quản lý đặt bàn',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18, // Giảm font size
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10, // Giảm padding
                            vertical: 4,    // Giảm padding
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16), // Giảm border radius
                          ),
                          child: Text(
                            'Tổng: ${bookings.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11, // Giảm font size
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible( // Thay thế TabBar bằng Flexible
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      labelStyle: const TextStyle(fontSize: 12), // Giảm font size
                      unselectedLabelStyle: const TextStyle(fontSize: 12),
                      tabs: [
                        Tab(
                          text: 'Hôm nay (${todayBookings.length})',
                        ),
                        Tab(
                          text: 'Sắp tới (${upcomingBookings.length})',
                        ),
                        Tab(
                          text: 'Lịch sử (${pastBookings.length})',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingList(todayBookings),
          _buildBookingList(upcomingBookings),
          _buildBookingList(pastBookings),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewBookingForm,
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBookingList(List<Booking> bookingList) {
    if (bookingList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Không có đơn đặt bàn',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookingList.length,
      itemBuilder: (context, index) {
        final booking = bookingList[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BookingCard(
            booking: booking,
            onTap: () => _showBookingDetail(booking),
            onStatusChanged: (newStatus) {
              setState(() {
                final bookingIndex = bookings.indexWhere((b) => b.id == booking.id);
                if (bookingIndex >= 0) {
                  bookings[bookingIndex] = bookings[bookingIndex].copyWith(status: newStatus);
                }
              });
            },
          ),
        );
      },
    );
  }

  void _showBookingDetail(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => BookingDetailDialog(
        booking: booking,
        availableTables: availableTables,
        onBookingUpdated: (updatedBooking) {
          setState(() {
            final index = bookings.indexWhere((b) => b.id == updatedBooking.id);
            if (index >= 0) {
              bookings[index] = updatedBooking;
            }
          });
        },
      ),
    );
  }
}

// Dialog tạo đặt bàn mới
class NewBookingDialog extends StatefulWidget {
  final List<models.Table> availableTables;
  final Function(Booking) onBookingCreated;

  const NewBookingDialog({
    super.key,
    required this.availableTables,
    required this.onBookingCreated,
  });

  @override
  State<NewBookingDialog> createState() => _NewBookingDialogState();
}

class _NewBookingDialogState extends State<NewBookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _guestsController = TextEditingController();
  final TextEditingController _requestsController = TextEditingController();
  
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  int? selectedTableNumber;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _guestsController.dispose();
    _requestsController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void _createBooking() {
    if (_formKey.currentState!.validate()) {
      final bookingDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      final newBooking = Booking(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerName: _nameController.text,
        customerPhone: _phoneController.text,
        customerEmail: _emailController.text.isEmpty ? null : _emailController.text,
        bookingTime: bookingDateTime,
        numberOfGuests: int.parse(_guestsController.text),
        preferredTableNumber: selectedTableNumber,
        status: BookingStatus.pending,
        specialRequests: _requestsController.text.isEmpty ? null : _requestsController.text,
      );

      widget.onBookingCreated(newBooking);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85, // Giới hạn height
          maxWidth: MediaQuery.of(context).size.width * 0.9,   // Giới hạn width
        ),
        child: Padding(
          padding: const EdgeInsets.all(16), // Giảm padding
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                const Text(
                  'Đặt bàn mới',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Thông tin khách hàng
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên khách hàng *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên khách hàng';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Số khách
                TextFormField(
                  controller: _guestsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số khách *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số khách';
                    }
                    final guests = int.tryParse(value);
                    if (guests == null || guests < 1) {
                      return 'Số khách phải là số dương';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                // Chọn ngày
                InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 12),
                        Text(
                          'Ngày: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Chọn giờ
                InkWell(
                  onTap: _selectTime,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time),
                        const SizedBox(width: 12),
                        Text(
                          'Giờ: ${selectedTime.format(context)}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Chọn bàn
                DropdownButtonFormField<int>(
                  value: selectedTableNumber,
                  decoration: const InputDecoration(
                    labelText: 'Bàn mong muốn',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.table_restaurant),
                  ),
                  items: widget.availableTables.map((table) {
                    return DropdownMenuItem<int>(
                      value: table.number,
                      child: Text('Bàn ${table.number} (${table.capacity} người)'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedTableNumber = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                
                // Yêu cầu đặc biệt
                TextFormField(
                  controller: _requestsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Yêu cầu đặc biệt',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _createBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Đặt bàn'),
                    ),
                  ],
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}

// Dialog chi tiết đặt bàn (placeholder)
class BookingDetailDialog extends StatelessWidget {
  final Booking booking;
  final List<models.Table> availableTables;
  final Function(Booking) onBookingUpdated;

  const BookingDetailDialog({
    super.key,
    required this.booking,
    required this.availableTables,
    required this.onBookingUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Chi tiết đặt bàn ${booking.customerName}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }
}