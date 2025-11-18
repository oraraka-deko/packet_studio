import 'package:studio_packet/models/sandbox/enums.dart';

import 'file.dart';
import 'folder.dart';

class Workspace {
String id;
  String name;
  DateTime createdAt;
  List<FolderModel>? folders;
  List<FileModel>? files;
  Status status;
  Workspace({
    required this.id,
    required this.name,
    required this.createdAt,
    this.folders,
    this.files,
    this.status = Status.unchanged,
  });


  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      folders: (json['folders'] as List<dynamic>?)
          ?.map((e) => FolderModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      files: (json['files'] as List<dynamic>?)
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
      'folders': folders?.map((e) => e.toJson()).toList(),
      'files': files?.map((e) => e.toJson()).toList(),
      'status': status.toString().split('.').last,
    };
  }

  Workspace copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<FolderModel>? folders,
    List<FileModel>? files,
    Status? status,
  }) {
    return Workspace(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      folders: folders ?? this.folders,
      files: files ?? this.files,
      status: status ?? this.status,
    );
  }
}