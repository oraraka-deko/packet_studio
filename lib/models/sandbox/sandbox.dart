import 'package:path_provider/path_provider.dart';
import 'package:studio_packet/models/sandbox/workspace.dart';


class Sandbox {
List<Workspace> workspaces;
String path;
  Sandbox({required this.workspaces, required this.path});

  factory Sandbox.fromJson(Map<String, dynamic> json) {
    return Sandbox(
      workspaces: (json['workspaces'] as List<dynamic>)
          .map((e) => Workspace.fromJson(e as Map<String, dynamic>))
          .toList(), path: ("${getApplicationSupportDirectory()}/sandboxes/"),
    );
  }

  Map<String, dynamic> toJson()  {
    return {
      'workspaces': workspaces.map((e) => e.toJson()).toList(),
    };
  }
  Sandbox copyWith({
    List<Workspace>? workspaces,
    String? path,
  }) {
    return Sandbox(
      workspaces: workspaces ?? this.workspaces, path: path ?? this.path,
    );
  }



}