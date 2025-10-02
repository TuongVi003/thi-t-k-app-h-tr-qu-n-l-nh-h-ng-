// Helper functions for safe type conversion
class SafeParser {
  static int toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.parse(value);
    if (value is double) return value.toInt();
    return 0;
  }

  static double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    return 0.0;
  }

  static bool toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value != 0;
    return false;
  }

  static int? toIntOrNull(dynamic value) {
    if (value == null) return null;
    try {
      return toInt(value);
    } catch (e) {
      return null;
    }
  }

  static DateTime? toDateTimeOrNull(dynamic value) {
    if (value == null) return null;
    try {
      final str = toStringSafe(value);
      if (str.isEmpty) return null;
      return DateTime.parse(str);
    } catch (e) {
      print('Error parsing DateTime: $e, value: $value');
      return null;
    }
  }

  static DateTime toDateTime(dynamic value, {DateTime? defaultValue}) {
    final result = toDateTimeOrNull(value);
    return result ?? defaultValue ?? DateTime.now();
  }

  static String toStringSafe(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  static String? toStringOrNull(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }
}