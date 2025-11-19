import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studio_packet/models/sandbox/file.dart';
import 'package:studio_packet/providers/workspace_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

// Constants for consistency and responsiveness
const double kSmallScreenThreshold = 500.0; // Phones: <500dp
const double kMediumScreenThreshold = 800.0; // Tablets: 500-800dp
const Color kBackgroundColor = Color(0xFF131314);
const Color kItemColor = Color(0xFF1E1E1E);
const double kBasePadding = 8.0;
const double kBaseFontSize = 14.0;
const double kBaseIconSize = 20.0;

class FileExplorerPanel extends ConsumerStatefulWidget {
  const FileExplorerPanel({super.key});

  @override
  ConsumerState<FileExplorerPanel> createState() => _FileExplorerPanelState();
}

class _FileExplorerPanelState extends ConsumerState<FileExplorerPanel>
    with TickerProviderStateMixin {
  Map<String, bool> expandedFolders = {};
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _loadWorkspace();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkspace() async {
    final prefs = await SharedPreferences.getInstance();
    final workspacePath = prefs.getString('workspacePath');
    if (workspacePath != null) {
      ref.read(workspaceProvider.notifier).loadWorkspace(workspacePath);
    }
  }

  double _getResponsiveValue(double small, double large, {double? medium}) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < kSmallScreenThreshold) return small;
    if (screenWidth < kMediumScreenThreshold) return medium ?? (small + large) / 2;
    return large;
  }

  bool get isSmallScreen => MediaQuery.of(context).size.width < kSmallScreenThreshold;

  Widget _buildFileItem(FileModel file, {int indent = 0}) {
    final isSelected = ref.watch(workspaceProvider).selectedFile?.path == file.path;
    final padding = _getResponsiveValue(4.0, 8.0);
    final fontSize = _getResponsiveValue(12.0, kBaseFontSize).clamp(12.0, 16.0);
    final iconSize = _getResponsiveValue(16.0, kBaseIconSize);

    return ListTile(
      key: ValueKey(file.path),
      dense: isSmallScreen,
      contentPadding: EdgeInsets.only(
        left: padding + (indent * _getResponsiveValue(12.0, 16.0)),
        right: padding,
        top: padding,
        bottom: padding,
      ),
      leading: Icon(
        _getFileIcon(file.fileExtentsion),
        color: _getFileColor(file.fileExtentsion),
        size: iconSize,
      ),
      title: Text(
        file.name,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[300],
              fontSize: fontSize,
            ) ??
            TextStyle(color: Colors.grey[300], fontSize: fontSize),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isSmallScreen
          ? null // Hide on very small for space; use long press
          : PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: iconSize - 2, color: Colors.grey[600]),
              padding: EdgeInsets.zero,
              onSelected: (value) => _handleFileAction(value, file),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
      selected: isSelected,
      selectedTileColor: Colors.blue.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      onTap: () => ref.read(workspaceProvider.notifier).selectFile(file),
      onLongPress: isSmallScreen ? () => _showFilePopup(file) : null, // Long press on small
      tileColor: kItemColor.withOpacity(0.5),
      hoverColor: Colors.grey.withOpacity(0.1), // Desktop hover
    );
  }

  Widget _buildFolderItem(String folderPath, String folderName, {int indent = 0}) {
    final isExpanded = expandedFolders[folderPath] ?? false;
    final padding = _getResponsiveValue(4.0, 8.0);
    final fontSize = _getResponsiveValue(12.0, kBaseFontSize).clamp(12.0, 16.0);
    final iconSize = _getResponsiveValue(16.0, kBaseIconSize);
    final expandIconSize = _getResponsiveValue(14.0, 18.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          dense: isSmallScreen,
          contentPadding: EdgeInsets.only(
            left: padding + (indent * _getResponsiveValue(12.0, 16.0)),
            right: padding,
            top: padding,
            bottom: padding,
          ),
          leading: Icon(
            Icons.folder,
            color: Colors.blue[400],
            size: iconSize,
          ),
          title: Text(
            folderName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[300],
                  fontWeight: FontWeight.w500,
                  fontSize: fontSize,
                ) ??
                TextStyle(
                  color: Colors.grey[300],
                  fontWeight: FontWeight.w500,
                  fontSize: fontSize,
                ),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                color: Colors.grey[600],
                size: expandIconSize,
              ),
              if (!isSmallScreen)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: iconSize - 2, color: Colors.grey[600]),
                  padding: EdgeInsets.zero,
                  onSelected: (value) => _handleFolderAction(value, folderPath),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'new_file', child: Text('New File')),
                    const PopupMenuItem(value: 'new_folder', child: Text('New Folder')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          onTap: () {
            setState(() {
              expandedFolders[folderPath] = !isExpanded;
            });
            if (isExpanded) _animationController.reverse(); else _animationController.forward();
          },
          onLongPress: isSmallScreen ? () => _showFolderPopup(folderPath) : null,
          tileColor: kItemColor.withOpacity(0.5),
          hoverColor: Colors.grey.withOpacity(0.1),
        ),
        // Animated expansion
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            child: child,
          ),
          child: isExpanded
              ? _buildFolderContents(folderPath, indent + 1)
              : const SizedBox.shrink(),
        ),
        const Divider(height: 1, color: Colors.grey, endIndent: 16), // Subtle divider
      ],
    );
  }

  Widget _buildFolderContents(String folderPath, int indent) {
    return StreamBuilder<List<FileSystemEntity>>(
      stream: Stream.value(Directory(folderPath).listSync()), // Sync for initial, watch for changes
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator(color: Colors.grey[600], strokeWidth: 2)),
          );
        }

        final entities = snapshot.data!;
        entities.sort((a, b) {
          if (a is Directory && b is File) return -1;
          if (a is File && b is Directory) return 1;
          return path.basename(a.path).toLowerCase().compareTo(path.basename(b.path).toLowerCase());
        });

        if (entities.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Empty folder',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entities.map((entity) {
            if (entity is Directory) {
              return _buildFolderItem(entity.path, path.basename(entity.path), indent: indent);
            } else if (entity is File) {
              final file = FileModel(
                id: entity.path.hashCode.toString(),
                name: path.basename(entity.path),
                size: 0, // Could compute File(entity.path).lengthSync() if needed
                createdAt: DateTime.now(),
                path: entity.path,
                type: 'text',
                fileExtentsion: path.extension(entity.path),
              );
              return _buildFileItem(file, indent: indent);
            }
            return const SizedBox.shrink();
          }).toList(),
        );
      },
    );
  }

  void _handleFileAction(String action, FileModel file) {
    if (action == 'delete') {
      _showDeleteConfirmation(
        'Delete file "${file.name}"?',
        () async {
          try {
            await ref.read(workspaceProvider.notifier).deleteFile(file.path);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File deleted')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error deleting file: $e')),
              );
            }
          }
        },
      );
    }
  }

  void _handleFolderAction(String action, String folderPath) {
    switch (action) {
      case 'new_file':
        _showCreateDialog('New File', 'File name', (name) async {
          await ref.read(workspaceProvider.notifier).createFile(folderPath, name);
        });
        break;
      case 'new_folder':
        _showCreateDialog('New Folder', 'Folder name', (name) async {
          await ref.read(workspaceProvider.notifier).createFolder(folderPath, name);
        });
        break;
      case 'delete':
        _showDeleteConfirmation(
          'Delete folder and contents?',
          () async {
            try {
              await ref.read(workspaceProvider.notifier).deleteFolder(folderPath);
              setState(() => expandedFolders.remove(folderPath)); // Close if deleted
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Folder deleted')),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting folder: $e')),
                );
              }
            }
          },
        );
        break;
    }
  }

  void _showFilePopup(FileModel file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _handleFileAction('delete', file);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFolderPopup(String folderPath) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.add, color: Colors.green),
              title: const Text('New File'),
              onTap: () {
                Navigator.pop(context);
                _handleFolderAction('new_file', folderPath);
              },
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder, color: Colors.green),
              title: const Text('New Folder'),
              onTap: () {
                Navigator.pop(context);
                _handleFolderAction('new_folder', folderPath);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _handleFolderAction('delete', folderPath);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(String title, String hint, Future<void> Function(String) onCreate) {
    final controller = TextEditingController();
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.add),
              ),
              autofocus: true,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  onCreate(value.trim());
                  Navigator.pop(context);
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        onCreate(controller.text.trim());
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Create'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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
        return Icons.inventory_2; // Better than settings
      case '.json':
        return Icons.data_object;
      case '.md':
        return Icons.description;
      case '.html':
        return Icons.language;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String extension) {
    switch (extension.toLowerCase()) {
      case '.dart':
        return Colors.green[400]!;
      case '.yaml':
      case '.yml':
        return Colors.orange[400]!;
      case '.json':
        return Colors.amber[400]!;
      case '.md':
        return Colors.blue[400]!;
      case '.html':
        return Colors.purple[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceProvider);
    final rootFolder = workspaceState.rootFolder;
    final padding = _getResponsiveValue(8.0, 16.0);
    final fontSize = _getResponsiveValue(10.0, 12.0).clamp(10.0, 14.0);

    return Container(
      color: kBackgroundColor,
      padding: EdgeInsets.only(top: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rootFolder?.name.toUpperCase() ?? "WORKSPACE",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                            ) ??
                            TextStyle(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (rootFolder != null)
                        Text(
                          rootFolder.path.split(path.separator).last,
                          style: TextStyle(color: Colors.grey[600], fontSize: fontSize - 2),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
IconButton(
  icon: Icon(Icons.refresh, size: _getResponsiveValue(16.0, 20.0), color: Colors.grey[600]),
  padding: EdgeInsets.all(_getResponsiveValue(4.0, 8.0)),
  constraints: const BoxConstraints(),
  onPressed: () {
    if (rootFolder != null) {
      ref.read(workspaceProvider.notifier).loadWorkspace(rootFolder.path);
      // Optional: Add a brief feedback (e.g., SnackBar) for UX
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workspace refreshed'), duration: Duration(seconds: 1)),
        );
      }
    }
  },
  tooltip: 'Refresh',
),                IconButton(
                  icon: Icon(Icons.add, size: _getResponsiveValue(16.0, 20.0), color: Colors.green[400]),
                  padding: EdgeInsets.all(_getResponsiveValue(4.0, 8.0)),
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    if (rootFolder != null) {
                      _showCreateDialog('New File', 'File name', (name) async {
                        await ref.read(workspaceProvider.notifier).createFile(rootFolder.path, name);
                      });
                    }
                  },
                  tooltip: 'Add New',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: workspaceState.isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(strokeWidth: 2),
                        SizedBox(height: 8),
                        Text('Loading workspace...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : rootFolder != null
                    ? ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _buildFolderContents(rootFolder.path, 0),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_off, color: Colors.grey[600], size: 48),
                            const SizedBox(height: 8),
                            Text(
                              'No workspace loaded',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}