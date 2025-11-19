import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studio_packet/models/sandbox/file.dart';
import 'package:studio_packet/providers/workspace_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class FileExplorerPanel extends ConsumerStatefulWidget {
  const FileExplorerPanel({super.key});

  @override
  ConsumerState<FileExplorerPanel> createState() => _FileExplorerPanelState();
}

class _FileExplorerPanelState extends ConsumerState<FileExplorerPanel> {
  Map<String, bool> expandedFolders = {};

  @override
  void initState() {
    super.initState();
    _loadWorkspace();
  }

  Future<void> _loadWorkspace() async {
    final prefs = await SharedPreferences.getInstance();
    final workspacePath = prefs.getString('workspacePath');
    if (workspacePath != null) {
      ref.read(workspaceProvider.notifier).loadWorkspace(workspacePath);
    }
  }

  Widget _buildFileItem(FileModel file) {
    final isSelected = ref.watch(workspaceProvider).selectedFile?.path == file.path;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 900;
    
    return InkWell(
      onTap: () {
        ref.read(workspaceProvider.notifier).selectFile(file);
      },
      child: Container(
        color: isSelected ? Colors.blue.withOpacity(0.2) : null,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : 16, 
          vertical: isSmallScreen ? 4 : 8,
        ),
        child: Row(
          children: [
            Icon(
              _getFileIcon(file.fileExtentsion), 
              color: _getFileColor(file.fileExtentsion), 
              size: isSmallScreen ? 16 : 18,
            ),
            SizedBox(width: isSmallScreen ? 4 : 8),
            Expanded(
              child: Text(
                file.name, 
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: isSmallScreen ? 12 : 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: isSmallScreen ? 14 : 16, color: Colors.grey[600]),
              padding: EdgeInsets.zero,
              onSelected: (value) async {
                if (value == 'delete') {
                  await ref.read(workspaceProvider.notifier).deleteFile(file.path);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderItem(String folderPath, String folderName, {int indent = 0}) {
    final isExpanded = expandedFolders[folderPath] ?? false;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              expandedFolders[folderPath] = !isExpanded;
            });
          },
          child: Padding(
            padding: EdgeInsets.only(
              left: (isSmallScreen ? 8.0 : 16.0) + (indent * (isSmallScreen ? 12 : 16)), 
              top: isSmallScreen ? 4 : 8, 
              bottom: isSmallScreen ? 4 : 8, 
              right: isSmallScreen ? 8 : 16,
            ),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  color: Colors.grey[600],
                  size: isSmallScreen ? 16 : 18,
                ),
                SizedBox(width: isSmallScreen ? 2 : 4),
                Icon(Icons.folder, color: Colors.blue, size: isSmallScreen ? 16 : 18),
                SizedBox(width: isSmallScreen ? 4 : 8),
                Expanded(
                  child: Text(
                    folderName, 
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: isSmallScreen ? 14 : 16, color: Colors.grey[600]),
                  padding: EdgeInsets.zero,
                  onSelected: (value) async {
                    if (value == 'new_file') {
                      _showCreateFileDialog(folderPath);
                    } else if (value == 'new_folder') {
                      _showCreateFolderDialog(folderPath);
                    } else if (value == 'delete') {
                      await ref.read(workspaceProvider.notifier).deleteFolder(folderPath);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'new_file', child: Text('New File')),
                    const PopupMenuItem(value: 'new_folder', child: Text('New Folder')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) _buildFolderContents(folderPath, indent + 1),
      ],
    );
  }

  Widget _buildFolderContents(String folderPath, int indent) {
    return FutureBuilder<List<FileSystemEntity>>(
      future: Directory(folderPath).list().toList(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final entities = snapshot.data!;
        entities.sort((a, b) {
          if (a is Directory && b is File) return -1;
          if (a is File && b is Directory) return 1;
          return path.basename(a.path).compareTo(path.basename(b.path));
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entities.map((entity) {
            if (entity is Directory) {
              return Padding(
                padding: EdgeInsets.only(left: indent * 16.0),
                child: _buildFolderItem(entity.path, path.basename(entity.path), indent: indent),
              );
            } else if (entity is File) {
              final file = FileModel(
                id: entity.path.hashCode.toString(),
                name: path.basename(entity.path),
                size: 0,
                createdAt: DateTime.now(),
                path: entity.path,
                type: 'text',
                fileExtentsion: path.extension(entity.path),
              );
              return Padding(
                padding: EdgeInsets.only(left: indent * 16.0),
                child: _buildFileItem(file),
              );
            }
            return const SizedBox.shrink();
          }).toList(),
        );
      },
    );
  }

  void _showCreateFileDialog(String parentPath) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'File name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await ref.read(workspaceProvider.notifier).createFile(parentPath, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog(String parentPath) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await ref.read(workspaceProvider.notifier).createFolder(parentPath, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case '.dart':
        return Icons.code;
      case '.yaml':
      case '.yml':
        return Icons.settings;
      case '.json':
        return Icons.data_object;
      case '.md':
        return Icons.description;
      case '.html':
        return Icons.web;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String extension) {
    switch (extension.toLowerCase()) {
      case '.dart':
        return Colors.green;
      case '.yaml':
      case '.yml':
        return Colors.orange;
      case '.json':
        return Colors.yellow;
      case '.md':
        return Colors.blue;
      case '.html':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceProvider);
    final rootFolder = workspaceState.rootFolder;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 900;

    return Container(
      color: const Color(0xFF131314),
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8.0 : 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    rootFolder?.name.toUpperCase() ?? "WORKSPACE",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 10 : 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, size: isSmallScreen ? 14 : 16, color: Colors.grey[600]),
                  padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    if (rootFolder != null) {
                      _showCreateFileDialog(rootFolder.path);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: workspaceState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : rootFolder != null
                    ? ListView(
                        children: [
                          _buildFolderContents(rootFolder.path, 0),
                        ],
                      )
                    : Center(
                        child: Text(
                          'No workspace loaded',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
