class Major {
  final int id;
  final String title;
  final String code;
  final String group;
  final String desc;
  final String image;
  final String careerProspects;
  final String skills;
  final List<String> tags;
  final List<String> topSchools;

  Major({
    required this.id,
    required this.title,
    required this.code,
    required this.group,
    required this.desc,
    required this.image,
    required this.careerProspects,
    required this.skills,
    required this.tags,
    required this.topSchools,
  });

  factory Major.fromJson(Map<String, dynamic> json) {
    return Major(
      id: _toInt(json['id']),
      title: _toText(json['title'] ?? json['name']),
      code: _toText(json['code']),
      group: _toText(json['group'] ?? json['category'] ?? json['major_group']),
      desc: _toText(json['desc'] ?? json['description']),
      image: _toText(json['image'] ?? json['image_url']),
      careerProspects: _toText(json['career_prospects']),
      skills: _toText(json['skills']),
      tags: _toStringList(json['tags']),
      topSchools: _toStringList(json['top_schools']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _toText(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value
          .map((e) {
            if (e is Map) {
              return e['name'] ??
                  e['title'] ??
                  e['school_name'] ??
                  e['major_name'] ??
                  '';
            }

            return e;
          })
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (value is String) {
      return value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return [value.toString()];
  }
}