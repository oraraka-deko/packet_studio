import 'package:flutter_riverpod/legacy.dart';
import 'package:studio_packet/models/sandbox/file.dart';
import 'package:studio_packet/models/sandbox/folder.dart';
import 'package:studio_packet/services/workspace_service.dart';

class WorkspaceState {
  final FolderModel? rootFolder;
  final FileModel? selectedFile;
  final String? fileContent;
  final bool isLoading;

  WorkspaceState({
    this.rootFolder,
    this.selectedFile,
    this.fileContent,
    this.isLoading = false,
  });

  WorkspaceState copyWith({
    FolderModel? rootFolder,
    FileModel? selectedFile,
    String? fileContent,
    bool? isLoading,
  }) {
    return WorkspaceState(
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
  WorkspaceNotifier() : super(WorkspaceState());
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
}
