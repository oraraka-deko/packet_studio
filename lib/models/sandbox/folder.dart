
import 'package:studio_packet/models/sandbox/enums.dart';
import 'package:studio_packet/models/sandbox/file.dart';

class FolderModel{
final String id;
  final String name;
  final DateTime createdAt;
  final String path;
  List<FileModel>? includedFiles;
  Status status;
  FolderModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.path,
    this.includedFiles,
    this.status = Status.unchanged,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      path: json['path'] as String,
      includedFiles: (json['includedFiles'] as List<dynamic>?)
          ?.map((e) => FileModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: Status.values.firstWhere(
        (e) => e.toString() == 'Status.${json['status']}',
        orElse: () => Status.unchanged,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'path': path,
      'includedFiles': includedFiles?.map((e) => e.toJson()).toList(),
      'status': status.toString().split('.').last,
    };
  }

  FolderModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    String? path,
    List<FileModel>? includedFiles,
    Status? status,
  }) {
    return FolderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      path: path ?? this.path,
      includedFiles: includedFiles ?? this.includedFiles,
      status: status ?? this.status,
    );
  }
}