import 'package:flutter/material.dart';
import 'package:qlnh_nhan_vien/models/table.dart' as models;
import 'package:qlnh_nhan_vien/widgets/table_card.dart';
import 'package:qlnh_nhan_vien/widgets/table_detail_dialog.dart';
import 'package:qlnh_nhan_vien/widgets/hotline_reservation_dialog.dart';
import 'package:qlnh_nhan_vien/services/api_service.dart';

class TableManagementScreen extends StatefulWidget {
  const TableManagementScreen({super.key});

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen> {
  List<models.Table> tables = [];
  models.TableStatus? selectedFilter;
  models.AreaType? selectedAreaFilter;
  bool isLoading = false;
  String? errorMessage;


  final Map<models.AreaType, String> areas = {
    models.AreaType.inside: 'Trong nhà',
    models.AreaType.outside: 'Ngoài trời',
    models.AreaType.privateRoom: 'VIP',
  };

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      tables = []; // Clear old data before loading
    });

    try {
      final tablesFromApi = await ApiService.fetchTablesFromApi();
      print('📋 Loaded ${tablesFromApi.length} tables from API');
      for (var table in tablesFromApi) {
        print('   Table ${table.number}: ${table.status} - Customer: ${table.customerName ?? "none"}');
      }
      setState(() {
        tables = tablesFromApi;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading tables: $e');
      setState(() {
        errorMessage = 'Lỗi tải dữ liệu: $e';
        isLoading = false;
      });
    }
  }

  List<models.Table> get filteredTables {
    List<models.Table> filtered = tables;
    
    // Lọc theo trạng thái
    if (selectedFilter != null) {
      filtered = filtered.where((table) => table.status == selectedFilter).toList();
    }
    
    // Lọc theo khu vực
    if (selectedAreaFilter != null) {
      filtered = filtered.where((table) => table.area == selectedAreaFilter).toList();
    }
    
    return filtered;
  }

  int get availableTablesCount {
    return tables.where((table) => table.status == models.TableStatus.available).length;
  }

  int get occupiedTablesCount {
    return tables.where((table) => table.status == models.TableStatus.occupied).length;
  }

  // Thống kê theo khu vực
  int getTablesCountByArea(models.AreaType area) {
    return tables.where((table) => table.area == area).length;
  }

  int getAvailableTablesCountByArea(models.AreaType area) {
    return tables.where((table) => 
      table.area == area && table.status == models.TableStatus.available
    ).length;
  }

  int getOccupiedTablesCountByArea(models.AreaType area) {
    return tables.where((table) => 
      table.area == area && table.status == models.TableStatus.occupied
    ).length;
  }

  void _showTableDetail(models.Table table) {
    // Nếu bàn trống, hiện dialog đặt bàn hotline
    if (table.status == models.TableStatus.available) {
      _showHotlineReservationDialog(preselectedTable: table);
    } else {
      // Nếu bàn đã có khách, hiện dialog chi tiết
      showDialog<bool>(
        context: context,
        builder: (context) => TableDetailDialog(
          table: table,
          onTableUpdated: (updatedTable) {
            setState(() {
              final index = tables.indexWhere((t) => t.id == updatedTable.id);
              if (index >= 0) {
                tables[index] = updatedTable;
              }
            });
          },
        ),
      ).then((didClear) {
        if (didClear == true) {
          _loadTables();
        }
      });
    }
  }

  void _showHotlineReservationDialog({models.Table? preselectedTable}) {
    showDialog(
      context: context,
      builder: (context) => HotlineReservationDialog(
        preselectedTable: preselectedTable,
        onReservationSuccess: _loadTables,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadTables,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Thống kê tổng quan
              Container(
                padding: const EdgeInsets.all(16.0),
                color: const Color(0xFF2E7D32),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Trạng thái bàn ăn hôm nay',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        else
                          IconButton(
                            onPressed: _loadTables,
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            tooltip: 'Làm mới dữ liệu',
                          ),
                      ],
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Đang sử dụng dữ liệu mẫu',
                                style: TextStyle(
                                  color: Colors.orange[100],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatusCard(
                          'Trống', 
                          availableTablesCount, 
                          Colors.green,
                          models.TableStatus.available,
                        ),
                        _buildStatusCard(
                          'Đã đặt', 
                          occupiedTablesCount, 
                          Colors.red,
                          models.TableStatus.occupied,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Improved filters section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Area and Status filters
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Area filter
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 18, color: const Color(0xFF2E7D32)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Khu vực:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _buildImprovedAreaChip('Trong nhà', models.AreaType.inside),
                                  _buildImprovedAreaChip('Ngoài trời', models.AreaType.outside),
                                  _buildImprovedAreaChip('VIP', models.AreaType.privateRoom),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 20),
                        
                        // Status filter
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.filter_list, size: 18, color: const Color(0xFF2E7D32)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Trạng thái:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _buildImprovedStatusChip('Tất cả', null),
                                  _buildImprovedStatusChip('Bàn trống', models.TableStatus.available),
                                  _buildImprovedStatusChip('Đã đặt', models.TableStatus.occupied),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Danh sách bàn - sử dụng ConstrainedBox để có chiều cao tối thiểu
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.6, // Chiều cao tối thiểu
                ),
                child: isLoading && tables.isEmpty
                    ? SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Color(0xFF2E7D32)),
                              SizedBox(height: 16),
                              Text('Đang tải dữ liệu bàn ăn...'),
                            ],
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: GridView.builder(
                          shrinkWrap: true, // Quan trọng: cho phép GridView co lại theo nội dung
                          physics: const NeverScrollableScrollPhysics(), // Tắt scroll riêng của GridView
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: filteredTables.length,
                          itemBuilder: (context, index) {
                            final table = filteredTables[index];
                            return TableCard(
                              table: table,
                              onTap: () => _showTableDetail(table),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _showHotlineReservationDialog,
      //   backgroundColor: const Color(0xFF2E7D32),
      //   icon: const Icon(Icons.phone_in_talk, color: Colors.white),
      //   label: const Text(
      //     'Đặt bàn Hotline',
      //     style: TextStyle(
      //       color: Colors.white,
      //       fontWeight: FontWeight.bold,
      //     ),
      //   ),
      // ),
    );
  }

  Widget _buildStatusCard(String title, int count, Color color, models.TableStatus status) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = selectedFilter == status ? null : status;
        });
      },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: selectedFilter == status ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Improved chip builders with better UX

  Widget _buildImprovedAreaChip(String label, models.AreaType? areaValue) {
    final isSelected = selectedAreaFilter == areaValue;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedAreaFilter = selectedAreaFilter == areaValue ? null : areaValue;
          });
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[300]!,
              width: 1.5,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: const Color(0xFF2E7D32).withOpacity(0.3),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ] : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF2E7D32),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImprovedStatusChip(String label, models.TableStatus? status) {
    final isSelected = selectedFilter == status;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedFilter = selectedFilter == status ? null : status;
          });
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[300]!,
              width: 1.5,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: const Color(0xFF2E7D32).withOpacity(0.3),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ] : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF2E7D32),
            ),
          ),
        ),
      ),
    );
  }
}