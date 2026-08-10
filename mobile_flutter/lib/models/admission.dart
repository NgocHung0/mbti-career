import 'dart:convert';

class Admission {
  final int id;
  final String schoolName;
  final String majorName;
  final String? city;
  final String? shortDescription;
  final String? imageUrl;
  final List<String> tags;
  final String status;
  final bool featured;
  final String? tuitionFee;
  final String? duration;
  final String? degree;
  final String? admissionMethod;
  final String? applicationDeadline;
  final String? startDate;
  final String? registerLink;
  final String? contactPhone;
  final String? contactEmail;
  final int sortOrder;
  final bool isActive;

  const Admission({
    required this.id,
    required this.schoolName,
    required this.majorName,
    this.city,
    this.shortDescription,
    this.imageUrl,
    this.tags = const [],
    this.status = 'coming_soon',
    this.featured = false,
    this.tuitionFee,
    this.duration,
    this.degree,
    this.admissionMethod,
    this.applicationDeadline,
    this.startDate,
    this.registerLink,
    this.contactPhone,
    this.contactEmail,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory Admission.fromJson(Map<String, dynamic> json) {
    return Admission(
      id: _toInt(json['id']),
      schoolName: _cleanText(json['school_name']) ?? 'Chưa cập nhật trường',
      majorName: _cleanText(json['major_name']) ?? 'Chưa cập nhật ngành',
      city: _cleanText(json['city']),
      shortDescription: _cleanText(json['short_description']),
      imageUrl: _cleanText(json['image_url']),
      tags: _toCleanList(json['tags']),
      status: (_cleanText(json['status']) ?? 'coming_soon').toLowerCase(),
      featured: _toBool(json['featured']),
      tuitionFee: _cleanText(json['tuition_fee']),
      duration: _cleanText(json['duration']),
      degree: _cleanText(json['degree']),
      admissionMethod: _cleanMultiline(json['admission_method']),
      applicationDeadline: _cleanText(json['application_deadline']),
      startDate: _cleanText(json['start_date']),
      registerLink: _cleanText(json['register_link']),
      contactPhone: _cleanText(json['contact_phone']),
      contactEmail: _cleanText(json['contact_email']),
      sortOrder: _toInt(json['sort_order']),
      isActive: json.containsKey('is_active') ? _toBool(json['is_active']) : true,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'open':
        return 'Đang mở';
      case 'coming_soon':
        return 'Sắp mở';
      case 'closed':
        return 'Đã đóng';
      default:
        return 'Đang cập nhật';
    }
  }

  bool matchesKeyword(String keyword) {
    final q = keyword.trim().toLowerCase();
    if (q.isEmpty) return true;

    final content = [
      schoolName,
      majorName,
      city ?? '',
      shortDescription ?? '',
      tuitionFee ?? '',
      duration ?? '',
      degree ?? '',
      admissionMethod ?? '',
      applicationDeadline ?? '',
      ...tags,
    ].join(' ').toLowerCase();

    return content.contains(q);
  }

  static String? _cleanText(dynamic value) {
    if (value == null) return null;

    var text = value.toString().trim();
    if (text.isEmpty || text == 'null') return null;

    text = text
        .replaceAll(r'\"', '"')
        .replaceAll(r'\\', '')
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .trim();

    return text.isEmpty ? null : text;
  }

  static String? _cleanMultiline(dynamic value) {
    final list = _toCleanList(value);
    if (list.isNotEmpty) return list.join('\n');

    return _cleanText(value);
  }

  static List<String> _toCleanList(dynamic value) {
    if (value == null) return [];

    dynamic current = value;

    for (int i = 0; i < 3; i++) {
      if (current is String) {
        final text = current.trim();
        if (text.isEmpty) return [];

        try {
          current = jsonDecode(text);
          continue;
        } catch (_) {
          return text
              .replaceAll(r'\"', '"')
              .replaceAll(r'\\', '')
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('"', '')
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }

      if (current is List) {
        return current
            .map((e) => _cleanText(e))
            .whereType<String>()
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    return [];
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value == 1;

    final text = value.toString().trim().toLowerCase();
    return text == '1' || text == 'true' || text == 'yes';
  }
}