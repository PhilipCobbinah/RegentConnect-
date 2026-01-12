import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionModel {
  final String id;
  final String courseCode;
  final String courseName;
  final String program;
  final int level;
  final int semester;
  final String academicYear;
  final String fileUrl;
  final String uploadedBy;
  final DateTime uploadedAt;
  final List<String> tags;
  final int downloadCount;

  QuestionModel({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.program,
    required this.level,
    required this.semester,
    required this.academicYear,
    required this.fileUrl,
    required this.uploadedBy,
    required this.uploadedAt,
    this.tags = const [],
    this.downloadCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseCode': courseCode,
      'courseName': courseName,
      'program': program,
      'level': level,
      'semester': semester,
      'academicYear': academicYear,
      'fileUrl': fileUrl,
      'uploadedBy': uploadedBy,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'tags': tags,
      'downloadCount': downloadCount,
    };
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['id'] ?? '',
      courseCode: map['courseCode'] ?? '',
      courseName: map['courseName'] ?? '',
      program: map['program'] ?? '',
      level: map['level']?.toInt() ?? 100,
      semester: map['semester']?.toInt() ?? 1,
      academicYear: map['academicYear'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      uploadedBy: map['uploadedBy'] ?? '',
      uploadedAt: map['uploadedAt'] is Timestamp
          ? (map['uploadedAt'] as Timestamp).toDate()
          : DateTime.now(),
      tags: List<String>.from(map['tags'] ?? []),
      downloadCount: map['downloadCount']?.toInt() ?? 0,
    );
  }

  QuestionModel copyWith({
    String? id,
    String? courseCode,
    String? courseName,
    String? program,
    int? level,
    int? semester,
    String? academicYear,
    String? fileUrl,
    String? uploadedBy,
    DateTime? uploadedAt,
    List<String>? tags,
    int? downloadCount,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      courseCode: courseCode ?? this.courseCode,
      courseName: courseName ?? this.courseName,
      program: program ?? this.program,
      level: level ?? this.level,
      semester: semester ?? this.semester,
      academicYear: academicYear ?? this.academicYear,
      fileUrl: fileUrl ?? this.fileUrl,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      tags: tags ?? this.tags,
      downloadCount: downloadCount ?? this.downloadCount,
    );
  }

  @override
  String toString() {
    return 'QuestionModel(id: $id, courseCode: $courseCode, courseName: $courseName)';
  }
}
