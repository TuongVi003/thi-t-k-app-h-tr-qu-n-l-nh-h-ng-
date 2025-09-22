import 'package:flutter/material.dart';
import 'package:qlnh_nhan_vien/models/table.dart' as models;
import 'package:qlnh_nhan_vien/widgets/table_card.dart';
import 'package:qlnh_nhan_vien/widgets/table_detail_dialog.dart';
import 'package:qlnh_nhan_vien/services/api_service.dart';

class TableManagementScreen extends StatefulWidget {
  const TableManagementScreen({super.key});

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen> {
  List<models.Table> tables = [];
  models.TableStatus? selectedFilter;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final tablesFromApi = await ApiService.fetchTablesFromDonHang();
      setState(() {
        tables = tablesFromApi;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi tải dữ liệu: $e';
        isLoading = false;
        // Sử dụng dữ liệu mẫu khi API lỗi
        tables = [
          models.Table(id: '1', number: 1, capacity: 2, status: models.TableStatus.available),
          models.Table(id: '2', number: 2, capacity: 4, status: models.TableStatus.occupied, 
                customerName: 'Nguyễn Văn A', customerPhone: '0123456789'),
          models.Table(id: '3', number: 3, capacity: 6, status: models.TableStatus.reserved,
                customerName: 'Trần Thị B', customerPhone: '0987654321',
                reservationTime: DateTime.now().add(const Duration(hours: 1))),
          models.Table(id: '4', number: 4, capacity: 4, status: models.TableStatus.available),
          models.Table(id: '5', number: 5, capacity: 2, status: models.TableStatus.cleaning),
          models.Table(id: '6', number: 6, capacity: 8, status: models.TableStatus.occupied,
                customerName: 'Lê Văn C', customerPhone: '0345678912'),
          models.Table(id: '7', number: 7, capacity: 4, status: models.TableStatus.available),
          models.Table(id: '8', number: 8, capacity: 2, status: models.TableStatus.reserved,
                customerName: 'Phạm Thị D', customerPhone: '0456789123',
                reservationTime: DateTime.now().add(const Duration(hours: 2))),
        ];
      });
    }
  }

  List<models.Table> get filteredTables {
    if (selectedFilter == null) {
      return tables;
    }
    return tables.where((table) => table.status == selectedFilter).toList();
  }

  int get availableTablesCount {
    return tables.where((table) => table.status == models.TableStatus.available).length;
  }

  int get occupiedTablesCount {
    return tables.where((table) => table.status == models.TableStatus.occupied).length;
  }

  int get reservedTablesCount {
    return tables.where((table) => table.status == models.TableStatus.reserved).length;
  }

  void _showTableDetail(models.Table table) {
    showDialog(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
                    const Text(
                      'Trạng thái bàn ăn',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                    _buildStatusCard(
                      'Đặt trước', 
                      reservedTablesCount, 
                      Colors.orange,
                      models.TableStatus.reserved,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Filter buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tất cả', null),
                  const SizedBox(width: 8),
                  _buildFilterChip('Bàn trống', models.TableStatus.available),
                  const SizedBox(width: 8),
                  _buildFilterChip('Đã đặt', models.TableStatus.occupied),
                  const SizedBox(width: 8),
                  _buildFilterChip('Đặt trước', models.TableStatus.reserved),
                  const SizedBox(width: 8),
                  _buildFilterChip('Dọn dẹp', models.TableStatus.cleaning),
                ],
              ),
            ),
          ),
          
          // Danh sách bàn
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTables,
              child: isLoading && tables.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF2E7D32)),
                          SizedBox(height: 16),
                          Text('Đang tải dữ liệu bàn ăn...'),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
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
          ),
        ],
      ),
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

  Widget _buildFilterChip(String label, models.TableStatus? status) {
    final isSelected = selectedFilter == status;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedFilter = selected ? status : null;
        });
      },
      selectedColor: const Color(0xFF2E7D32).withOpacity(0.3),
      checkmarkColor: const Color(0xFF2E7D32),
    );
  }
}