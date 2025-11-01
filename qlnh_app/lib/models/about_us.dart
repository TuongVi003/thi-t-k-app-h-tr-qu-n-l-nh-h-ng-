import 'dart:convert';

class AboutUs {
  final int id;
  final String key;
  final String noiDung;
  final bool public;
  final String contentType;

  AboutUs({
    required this.id,
    required this.key,
    required this.noiDung,
    required this.public,
    required this.contentType,
  });

  factory AboutUs.fromJson(Map<String, dynamic> json) {
    return AboutUs(
      id: json['id'] as int,
      key: json['key'] as String,
      noiDung: json['noi_dung'] as String,
      public: json['public'] as bool,
      contentType: json['content_type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'noi_dung': noiDung,
      'public': public,
      'content_type': contentType,
    };
  }

  // Parse JSON content for gio_mo_cua
  Map<String, dynamic>? parseJsonContent() {
    if (contentType != 'json') return null;

    try {
      final raw = noiDung.trim();

      // Attempt to decode directly
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) return decoded;

      // If it's a JSON string (double-encoded), decode again
      if (decoded is String) {
        final inner = json.decode(decoded);
        if (inner is Map<String, dynamic>) return inner;
      }

      // If raw is quoted JSON inside a string, try unquoting and decoding
      if (raw.startsWith('"') && raw.endsWith('"')) {
        final unquoted = raw.substring(1, raw.length - 1);
        final second = json.decode(unquoted);
        if (second is Map<String, dynamic>) return second;
      }

      return null;
    } catch (e) {
      print('Error parsing JSON content: $e');
      return null;
    }
  }
}
