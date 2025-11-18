



import 'enums.dart';

class FileModel{
  final String id;
  final String name;
  final int size; // size in bytes
  final DateTime createdAt;
  final String path;
  final String type;
  final String fileExtentsion;
  String? content; // Optional content of the file
  Status status;

  FileModel({
    required this.id,
    required this.name,
    required this.size,
    required this.createdAt,
    required this.path,
    required this.type,
    required this.fileExtentsion,
    this.content,
    this.status = Status.unchanged,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      size: json['size'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      path: json['path'] as String,
      type: json['type'] as String,
      fileExtentsion: json['fileExtentsion'] as String,
      content: json['content'] as String?,
      status: Status.values.firstWhere((e) => e.toString() == 'Status.' + (json['status'] as String)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'size': size,
      'createdAt': createdAt.toIso8601String(),
      'path': path,
      'type': type,
      'fileExtentsion': fileExtentsion,
      'content': content,
      'status': status.toString().split('.').last,
    };
  }

  FileModel copyWith({
    String? id,
    String? name,
    int? size,
    DateTime? createdAt,
    String? path,
    String? type,
    String? fileExtentsion,
    String? content,
    Status? status,
  }) {
    return FileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      size: size ?? this.size,
      createdAt: createdAt ?? this.createdAt,
      path: path ?? this.path,
      type: type ?? this.type,
      fileExtentsion: fileExtentsion ?? this.fileExtentsion,
      content: content ?? this.content,
      status: status ?? this.status,
    );
  }
}
