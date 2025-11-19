import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studio_packet/models/sandbox/file.dart';
import 'package:studio_packet/models/sandbox/folder.dart';
import 'package:studio_packet/services/workspace_service.dart';

import '../services/setup_service.dart';


class WorkspaceState {
    final String? currentWorkspacePath;
   List<String> availableWorkspaces=[];

  final FolderModel? rootFolder;
  final FileModel? selectedFile;
  final String? fileContent;
  final bool isLoading;

  WorkspaceState(
    {
          required this.availableWorkspaces,

    this.currentWorkspacePath,

    this.rootFolder,
    this.selectedFile,
    this.fileContent,
    this.isLoading = false,
  });

  WorkspaceState copyWith({
    FolderModel? rootFolder,
    FileModel? selectedFile,
    String? fileContent,
    bool? isLoading,    String? currentWorkspacePath,
    List<String>? availableWorkspaces,
  }) {
        return WorkspaceState(

      currentWorkspacePath: currentWorkspacePath ?? this.currentWorkspacePath,
      availableWorkspaces: availableWorkspaces ?? this.availableWorkspaces,
      rootFolder: rootFolder ?? this.rootFolder,
      selectedFile: selectedFile ?? this.selectedFile,
      fileContent: fileContent ?? this.fileContent,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final workspaceProvider = StateNotifierProvider<WorkspaceNotifier, WorkspaceState>((ref) {
  return WorkspaceNotifier();
});

class WorkspaceNotifier extends StateNotifier<WorkspaceState> {
  WorkspaceNotifier() : super(WorkspaceState(availableWorkspaces: []));
  final WorkspaceService _workspaceService = WorkspaceService();

  Future<void> loadWorkspace(String workspacePath) async {
    state = state.copyWith(isLoading: true);
    final rootFolder = await _workspaceService.loadWorkspace(workspacePath);
    state = state.copyWith(rootFolder: rootFolder, isLoading: false);
  }

  Future<void> selectFile(FileModel file) async {
    state = state.copyWith(selectedFile: file, isLoading: true);
    final content = await _workspaceService.readFile(file.path);
    state = state.copyWith(fileContent: content, isLoading: false);
  }

  Future<void> saveFile(String content) async {
    if (state.selectedFile != null) {
      await _workspaceService.writeFile(state.selectedFile!.path, content);
      state = state.copyWith(fileContent: content);
    }
  }

  Future<void> createFile(String parentPath, String fileName) async {
    await _workspaceService.createFile(parentPath, fileName);
    final workspacePath = state.rootFolder?.path;
    if (workspacePath != null) {
      await loadWorkspace(workspacePath);
    }
  }

  Future<void> deleteFile(String filePath) async {
    await _workspaceService.deleteFile(filePath);
    final workspacePath = state.rootFolder?.path;
    if (workspacePath != null) {
      await loadWorkspace(workspacePath);
    }
    if (state.selectedFile?.path == filePath) {
      state = state.copyWith(selectedFile: null, fileContent: null);
    }
  }

  Future<void> createFolder(String parentPath, String folderName) async {
    await _workspaceService.createFolder(parentPath, folderName);
    final workspacePath = state.rootFolder?.path;
    if (workspacePath != null) {
      await loadWorkspace(workspacePath);
    }
  }

  Future<void> deleteFolder(String folderPath) async {
    await _workspaceService.deleteFolder(folderPath);
    final workspacePath = state.rootFolder?.path;
    if (workspacePath != null) {
      await loadWorkspace(workspacePath);
    }
  }
  Future<List<String>> _loadWorkspaces(String sandboxPath) async {
    final sandboxDir = Directory(sandboxPath);
    if (!await sandboxDir.exists()) return [];
    final entities = await sandboxDir.list().toList();
    return entities
        .where((e) => e is Directory)
        .map((e) => e.path)
        .toList();
  }
  Future<void> createNewWorkspace(String workspaceName, Function(String) onProgress) async {
    final prefs = await SharedPreferences.getInstance();
    final sandboxPath = prefs.getString('sandboxPath') ?? '';
    final dartSdkPath = prefs.getString('dartSdkPath') ?? '';

    if (sandboxPath.isEmpty || dartSdkPath.isEmpty) {
      throw Exception('Sandbox or Dart SDK path not initialized');
    }

    onProgress('Creating new workspace: $workspaceName...');
    final setupService = SetupService();
    final dartExecutable = p.join(dartSdkPath, 'bin', 'dart');
    final workspacePath = p.join(sandboxPath, workspaceName);

    final result = await setupService.runProcess(
      dartExecutable,
      ['create', workspaceName],
      workingDirectory: sandboxPath,
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to create workspace: ${result.stderr.isNotEmpty ? result.stderr : result.stdout}');
    }

    await prefs.setString('workspacePath', workspacePath);
    final updatedWorkspaces = await _loadWorkspaces(sandboxPath);
    state = state.copyWith(
      currentWorkspacePath: workspacePath,
      availableWorkspaces: updatedWorkspaces,
    );

    onProgress('Workspace $workspaceName created successfully!');
  }

  Future<void> switchWorkspace(String workspacePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('workspacePath', workspacePath);
    state = state.copyWith(currentWorkspacePath: workspacePath);
  }

}
