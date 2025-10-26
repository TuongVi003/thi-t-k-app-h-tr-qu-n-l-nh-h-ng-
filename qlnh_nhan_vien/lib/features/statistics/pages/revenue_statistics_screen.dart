// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../models/statistics.dart';
// import '../services/statistics_service.dart';

// class RevenueStatisticsScreen extends StatefulWidget {
//   const RevenueStatisticsScreen({super.key});

//   @override
//   State<RevenueStatisticsScreen> createState() => _RevenueStatisticsScreenState();
// }

// class _RevenueStatisticsScreenState extends State<RevenueStatisticsScreen> {
//   RevenueStatistics? _revenueStats;
//   bool _isLoading = false;
//   String? _error;
  
//   // Date range
//   DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
//   DateTime _endDate = DateTime.now();
  
//   // Period: 'day' or 'month'
//   String _period = 'day';

//   @override
//   void initState() {
//     super.initState();
//     _loadRevenueStatistics();
//   }

//   Future<void> _loadRevenueStatistics() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });

//     try {
//       final stats = await StatisticsService.getRevenueStatistics(
//         startDate: DateFormat('yyyy-MM-dd').format(_startDate),
//         endDate: DateFormat('yyyy-MM-dd').format(_endDate),
//         period: _period,
//       );
      
//       setState(() {
//         _revenueStats = stats;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _error = e.toString();
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _selectDateRange() async {
//     final picked = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//       initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: Color(0xFF2E7D32),
//               onPrimary: Colors.white,
//               surface: Colors.white,
//               onSurface: Colors.black,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (picked != null) {
//       setState(() {
//         _startDate = picked.start;
//         _endDate = picked.end;
//       });
//       _loadRevenueStatistics();
//     }
//   }

//   String _formatCurrency(double amount) {
//     final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
//     return formatter.format(amount);
//   }

//   String _formatDate(DateTime date) {
//     if (_period == 'month') {
//       return DateFormat('MM/yyyy').format(date);
//     }
//     return DateFormat('dd/MM/yyyy').format(date);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Thống kê doanh thu',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: const Color(0xFF2E7D32),
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: Column(
//         children: [
//           // Filter Section
//           Container(
//             color: Colors.white,
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 // Period Selector
//                 Row(
//                   children: [
//                     Expanded(
//                       child: SegmentedButton<String>(
//                         segments: const [
//                           ButtonSegment(
//                             value: 'day',
//                             label: Text('Theo ngày'),
//                             icon: Icon(Icons.calendar_today, size: 16),
//                           ),
//                           ButtonSegment(
//                             value: 'month',
//                             label: Text('Theo tháng'),
//                             icon: Icon(Icons.calendar_month, size: 16),
//                           ),
//                         ],
//                         selected: {_period},
//                         onSelectionChanged: (Set<String> newSelection) {
//                           setState(() {
//                             _period = newSelection.first;
//                           });
//                           _loadRevenueStatistics();
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 // Date Range Picker
//                 InkWell(
//                   onTap: _selectDateRange,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Row(
//                           children: [
//                             const Icon(Icons.date_range, color: Color(0xFF2E7D32)),
//                             const SizedBox(width: 8),
//                             Text(
//                               '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
//                               style: const TextStyle(fontSize: 14),
//                             ),
//                           ],
//                         ),
//                         const Icon(Icons.arrow_drop_down),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const Divider(height: 1),
          
//           // Content
//           Expanded(
//             child: _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : _error != null
//                     ? _buildErrorWidget()
//                     : _buildRevenueContent(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildErrorWidget() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.error_outline, size: 64, color: Colors.red),
//           const SizedBox(height: 16),
//           Text(
//             'Không thể tải dữ liệu',
//             style: Theme.of(context).textTheme.titleLarge,
//           ),
//           const SizedBox(height: 8),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 32),
//             child: Text(
//               _error ?? 'Lỗi không xác định',
//               textAlign: TextAlign.center,
//               style: const TextStyle(color: Colors.grey),
//             ),
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton.icon(
//             onPressed: _loadRevenueStatistics,
//             icon: const Icon(Icons.refresh),
//             label: const Text('Thử lại'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF2E7D32),
//               foregroundColor: Colors.white,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRevenueContent() {
//     if (_revenueStats == null || _revenueStats!.data.isEmpty) {
//       return const Center(
//         child: Text(
//           'Không có dữ liệu trong khoảng thời gian này',
//           style: TextStyle(color: Colors.grey),
//         ),
//       );
//     }

//     return RefreshIndicator(
//       onRefresh: _loadRevenueStatistics,
//       child: SingleChildScrollView(
//         physics: const AlwaysScrollableScrollPhysics(),
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Summary Card
//             _buildSummaryCard(),
//             const SizedBox(height: 24),
            
//             // Chart
//             const Text(
//               'Biểu đồ doanh thu',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF2E7D32),
//               ),
//             ),
//             const SizedBox(height: 8),
//             _buildRevenueChart(),
//             const SizedBox(height: 24),
            
//             // Data List
//             const Text(
//               'Chi tiết',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF2E7D32),
//               ),
//             ),
//             const SizedBox(height: 8),
//             _buildDataList(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSummaryCard() {
//     final summary = _revenueStats!.summary;
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Tổng quan',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const Divider(height: 24),
//             _buildSummaryRow(
//               'Tổng doanh thu:',
//               _formatCurrency(summary.totalRevenue),
//               const Color(0xFF2E7D32),
//             ),
//             const SizedBox(height: 12),
//             _buildSummaryRow(
//               'Tổng số đơn:',
//               '${summary.totalOrders}',
//               Colors.blue,
//             ),
//             const SizedBox(height: 12),
//             _buildSummaryRow(
//               'Giá trị TB/đơn:',
//               _formatCurrency(summary.averageOrderValue),
//               Colors.orange,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSummaryRow(String label, String value, Color valueColor) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: valueColor,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildRevenueChart() {
//     final data = _revenueStats!.data;
//     final maxRevenue = data.map((e) => e.totalRevenue).reduce((a, b) => a > b ? a : b);
    
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: data.map((item) {
//             final percentage = maxRevenue > 0 ? (item.totalRevenue / maxRevenue).toDouble() : 0.0;
//             return Padding(
//               padding: const EdgeInsets.symmetric(vertical: 8),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         _formatDate(item.date),
//                         style: const TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       Text(
//                         _formatCurrency(item.totalRevenue),
//                         style: const TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF2E7D32),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(4),
//                     child: LinearProgressIndicator(
//                       value: percentage,
//                       minHeight: 20,
//                       backgroundColor: Colors.grey[200],
//                       valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     '${item.totalOrders} đơn',
//                     style: TextStyle(
//                       fontSize: 10,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }

//   Widget _buildDataList() {
//     final data = _revenueStats!.data;
//     return Card(
//       elevation: 2,
//       child: Column(
//         children: [
//           // Header
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.grey[100],
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(4),
//                 topRight: Radius.circular(4),
//               ),
//             ),
//             child: Row(
//               children: const [
//                 Expanded(
//                   flex: 2,
//                   child: Text(
//                     'Ngày',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 Expanded(
//                   child: Text(
//                     'Đơn',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//                 Expanded(
//                   flex: 2,
//                   child: Text(
//                     'Doanh thu',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                     textAlign: TextAlign.right,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Data rows
//           ...data.map((item) => _buildDataRow(item)).toList(),
//         ],
//       ),
//     );
//   }

//   Widget _buildDataRow(RevenueData item) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         border: Border(
//           bottom: BorderSide(color: Colors.grey[200]!),
//         ),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             flex: 2,
//             child: Text(
//               _formatDate(item.date),
//               style: const TextStyle(fontSize: 14),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               '${item.totalOrders}',
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),
//           Expanded(
//             flex: 2,
//             child: Text(
//               _formatCurrency(item.totalRevenue),
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF2E7D32),
//               ),
//               textAlign: TextAlign.right,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
