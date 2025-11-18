import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:studio_packet/models/sandbox/enums.dart';
import 'package:studio_packet/models/sandbox/file.dart';
import 'package:studio_packet/models/sandbox/folder.dart';

class WorkspaceService {
  Future<FolderModel> loadWorkspace(String workspacePath) async {
    final dir = Directory(workspacePath);
    return await _loadFolder(dir);
  }

  Future<FolderModel> _loadFolder(Directory dir) async {
    final entities = await dir.list().toList();
    final files = <FileModel>[];
    
    for (final entity in entities) {
      if (entity is File) {
        final stat = await entity.stat();
        files.add(FileModel(
          id: entity.path.hashCode.toString(),
          name: path.basename(entity.path),
          size: stat.size,
          createdAt: stat.changed,
          path: entity.path,
          type: _getFileType(entity.path),
          fileExtentsion: path.extension(entity.path),
        ));
      }
    }

    return FolderModel(
      id: dir.path.hashCode.toString(),
      name: path.basename(dir.path),
      createdAt: await dir.stat().then((s) => s.changed),
      path: dir.path,
      includedFiles: files,
      status: Status.unchanged,
    );
  }

  String _getFileType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.dart':
        return 'dart';
      case '.yaml':
      case '.yml':
        return 'yaml';
      case '.json':
        return 'json';
      case '.md':
        return 'markdown';
      case '.html':
        return 'html';
      case '.css':
        return 'css';
      case '.js':
        return 'javascript';
      default:
        return 'text';
    }
  }

  Future<String> readFile(String filePath) async {
    final file = File(filePath);
    return await file.readAsString();
  }

  Future<void> writeFile(String filePath, String content) async {
    final file = File(filePath);
    await file.writeAsString(content);
  }

  Future<void> createFile(String parentPath, String fileName) async {
    final filePath = path.join(parentPath, fileName);
    final file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsString('');
  }

  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> createFolder(String parentPath, String folderName) async {
    final folderPath = path.join(parentPath, folderName);
    final dir = Directory(folderPath);
    await dir.create(recursive: true);
  }

  Future<void> deleteFolder(String folderPath) async {
    final dir = Directory(folderPath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<List<FileSystemEntity>> getDirectoryContents(String dirPath) async {
    final dir = Directory(dirPath);
    return await dir.list().toList();
  }
}
