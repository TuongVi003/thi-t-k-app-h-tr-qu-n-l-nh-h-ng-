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
    if (contentType == 'json') {
      try {
        // Remove outer quotes if present and parse
        final jsonString = noiDung.trim();
        if (jsonString.startsWith('"') && jsonString.endsWith('"')) {
          final unquoted = jsonString.substring(1, jsonString.length - 1);
          return _parseJsonString(unquoted);
        }
        return _parseJsonString(jsonString);
      } catch (e) {
        print('Error parsing JSON content: $e');
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> _parseJsonString(String jsonString) {
    // Simple JSON parser for the opening hours format
    final Map<String, dynamic> result = {};
    final cleaned = jsonString.replaceAll('{', '').replaceAll('}', '').trim();
    final pairs = cleaned.split(',');
    
    for (final pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        final key = parts[0].trim().replaceAll('"', '');
        final value = parts[1].trim().replaceAll('"', '');
        result[key] = value;
      }
    }
    
    return result;
  }
}
