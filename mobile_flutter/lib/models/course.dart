class Course {
  final int id;
  final String name;
  final String slug;
  final String shortDescription;
  final String description;
  final String courseMajor;
  final String thumbnail;
  final bool isFeatured;
  final bool isPurchased;
  final bool isLocked;

  Course({
    required this.id,
    required this.name,
    required this.slug,
    required this.shortDescription,
    required this.description,
    required this.courseMajor,
    required this.thumbnail,
    required this.isFeatured,
    required this.isPurchased,
    required this.isLocked,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      shortDescription: json['short_description']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      courseMajor: json['course_major']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString() ?? '',
      isFeatured: json['is_featured'] == true || json['is_featured'] == 1,
      isPurchased: json['is_purchased'] == true || json['is_purchased'] == 1,
      isLocked: json['is_locked'] == true || json['is_locked'] == 1,
    );
  }
}

class CourseLesson {
  final int id;
  final String title;
  final String description;
  final String contentType;
  final String videoUrl;
  final String mediaUrl;
  final String duration;
  final int sortOrder;
  final List<dynamic> questions;

  CourseLesson({
    required this.id,
    required this.title,
    required this.description,
    required this.contentType,
    required this.videoUrl,
    required this.mediaUrl,
    required this.duration,
    required this.sortOrder,
    required this.questions,
  });

  factory CourseLesson.fromJson(Map<String, dynamic> json) {
    return CourseLesson(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      contentType: json['content_type']?.toString() ?? '',
      videoUrl: json['video_url']?.toString() ?? '',
      mediaUrl: json['media_url']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      sortOrder: int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
      questions: json['questions'] is List ? json['questions'] : [],
    );
  }
}