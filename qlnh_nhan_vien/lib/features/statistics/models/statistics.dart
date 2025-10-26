class Statistics {
  final TodayStats today;
  final MonthStats month;
  final TableStats tables;
  final List<TopDish> topDishes;

  Statistics({
    required this.today,
    required this.month,
    required this.tables,
    required this.topDishes,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      today: TodayStats.fromJson(json['today']),
      month: MonthStats.fromJson(json['month']),
      tables: TableStats.fromJson(json['tables']),
      topDishes: (json['top_dishes'] as List)
          .map((dish) => TopDish.fromJson(dish))
          .toList(),
    );
  }
}

class TodayStats {
  final int totalOrders;
  final int completedOrders;
  final int pendingOrders;
  final int totalReservations;
  final double revenue;

  TodayStats({
    required this.totalOrders,
    required this.completedOrders,
    required this.pendingOrders,
    required this.totalReservations,
    required this.revenue,
  });

  factory TodayStats.fromJson(Map<String, dynamic> json) {
    return TodayStats(
      totalOrders: json['total_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      pendingOrders: json['pending_orders'] ?? 0,
      totalReservations: json['total_reservations'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}

class MonthStats {
  final int totalOrders;
  final int completedOrders;
  final int totalReservations;
  final double revenue;

  MonthStats({
    required this.totalOrders,
    required this.completedOrders,
    required this.totalReservations,
    required this.revenue,
  });

  factory MonthStats.fromJson(Map<String, dynamic> json) {
    return MonthStats(
      totalOrders: json['total_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      totalReservations: json['total_reservations'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}

class TableStats {
  final int total;
  final int occupied;
  final int reserved;
  final int available;

  TableStats({
    required this.total,
    required this.occupied,
    required this.reserved,
    required this.available,
  });

  factory TableStats.fromJson(Map<String, dynamic> json) {
    return TableStats(
      total: json['total'] ?? 0,
      occupied: json['occupied'] ?? 0,
      reserved: json['reserved'] ?? 0,
      available: json['available'] ?? 0,
    );
  }
}

class TopDish {
  final String dishName;
  final int dishId;
  final int totalSold;
  final double revenue;

  TopDish({
    required this.dishName,
    required this.dishId,
    required this.totalSold,
    required this.revenue,
  });

  factory TopDish.fromJson(Map<String, dynamic> json) {
    return TopDish(
      dishName: json['mon_an__ten_mon'] ?? '',
      dishId: json['mon_an__id'] ?? 0,
      totalSold: json['total_sold'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}

// Revenue Statistics Models
class RevenueStatistics {
  final String period;
  final String startDate;
  final String endDate;
  final List<RevenueData> data;
  final RevenueSummary summary;

  RevenueStatistics({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.data,
    required this.summary,
  });

  factory RevenueStatistics.fromJson(Map<String, dynamic> json) {
    return RevenueStatistics(
      period: json['period'] ?? 'day',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      data: (json['data'] as List)
          .map((item) => RevenueData.fromJson(item, json['period'] ?? 'day'))
          .toList(),
      summary: RevenueSummary.fromJson(json['summary']),
    );
  }
}

class RevenueData {
  final DateTime date;
  final double totalRevenue;
  final int totalOrders;

  RevenueData({
    required this.date,
    required this.totalRevenue,
    required this.totalOrders,
  });

  factory RevenueData.fromJson(Map<String, dynamic> json, String period) {
    DateTime parseDate;
    if (period == 'month') {
      parseDate = DateTime.parse(json['month']);
    } else {
      parseDate = DateTime.parse(json['date']);
    }

    return RevenueData(
      date: parseDate,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      totalOrders: json['total_orders'] ?? 0,
    );
  }
}

class RevenueSummary {
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;

  RevenueSummary({
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
  });

  factory RevenueSummary.fromJson(Map<String, dynamic> json) {
    return RevenueSummary(
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      totalOrders: json['total_orders'] ?? 0,
      averageOrderValue: (json['average_order_value'] ?? 0).toDouble(),
    );
  }
}

// Order Statistics Models
class OrderStatistics {
  final String startDate;
  final String endDate;
  final List<OrderByStatus> byStatus;
  final List<OrderByType> byType;
  final List<OrderByStaff> byStaff;

  OrderStatistics({
    required this.startDate,
    required this.endDate,
    required this.byStatus,
    required this.byType,
    required this.byStaff,
  });

  factory OrderStatistics.fromJson(Map<String, dynamic> json) {
    return OrderStatistics(
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      byStatus: (json['by_status'] as List)
          .map((item) => OrderByStatus.fromJson(item))
          .toList(),
      byType: (json['by_type'] as List)
          .map((item) => OrderByType.fromJson(item))
          .toList(),
      byStaff: (json['by_staff'] as List)
          .map((item) => OrderByStaff.fromJson(item))
          .toList(),
    );
  }

  int get totalOrders {
    return byStatus.fold(0, (sum, item) => sum + item.count);
  }
}

class OrderByStatus {
  final String status;
  final int count;

  OrderByStatus({
    required this.status,
    required this.count,
  });

  factory OrderByStatus.fromJson(Map<String, dynamic> json) {
    return OrderByStatus(
      status: json['trang_thai'] ?? '',
      count: json['count'] ?? 0,
    );
  }

  String get displayName {
    switch (status) {
      case 'pending':
        return 'Đang chờ';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      case 'preparing':
        return 'Đang chuẩn bị';
      case 'ready':
        return 'Sẵn sàng';
      default:
        return status;
    }
  }
}

class OrderByType {
  final String type;
  final int count;

  OrderByType({
    required this.type,
    required this.count,
  });

  factory OrderByType.fromJson(Map<String, dynamic> json) {
    return OrderByType(
      type: json['loai_order'] ?? '',
      count: json['count'] ?? 0,
    );
  }

  String get displayName {
    switch (type) {
      case 'dine_in':
      case 'dine-in':
        return 'Tại chỗ';
      case 'takeaway':
        return 'Mang về';
      case 'delivery':
        return 'Giao hàng';
      case 'reservation':
        return 'Đặt bàn';
      default:
        return type;
    }
  }
}

class OrderByStaff {
  final String staffName;
  final int staffId;
  final int totalOrders;
  final int completedOrders;

  OrderByStaff({
    required this.staffName,
    required this.staffId,
    required this.totalOrders,
    required this.completedOrders,
  });

  factory OrderByStaff.fromJson(Map<String, dynamic> json) {
    return OrderByStaff(
      staffName: json['nhan_vien__ho_ten'] ?? 'N/A',
      staffId: json['nhan_vien__id'] ?? 0,
      totalOrders: json['total_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
    );
  }

  double get completionRate {
    if (totalOrders == 0) return 0.0;
    return (completedOrders / totalOrders) * 100;
  }
}

