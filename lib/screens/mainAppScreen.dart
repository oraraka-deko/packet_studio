import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/workspace_provider.dart';
import '../widgets/CodeEditorPanel.dart';
import '../widgets/FileExplorerPanel.dart';
import '../widgets/RightUtilityPanel.dart';

class MainIdeLayout extends ConsumerWidget {
  const MainIdeLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
        final workspaceState = ref.watch(workspaceProvider);
    return MaterialApp(
      title: 'Dart IDE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF131314),
        cardColor: const Color(0xFF1E1F20),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF444746),
          secondary: Color(0xFFA8C7FA),
          surface: Color(0xFF131314),
          onSurface: Colors.white,
        ),
        dividerColor: Colors.grey[850],
      ),
      home: Scaffold(
        body: Column(
          children: [
            // Top header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF1E1F20),
              child: Row(
                children: [
                  // File Menu with Dropdown
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'New Workspace') {
                        _showNewWorkspaceDialog(context, ref);
                      } else if (value.startsWith('Switch to: ')) {
                        final workspacePath = value.replaceFirst('Switch to: ', '');
                        await ref.read(workspaceProvider.notifier).switchWorkspace(workspacePath);
                      } else {
                        print("Selected: $value");
                      }
                    },
                    child: Text("File", style: TextStyle(color: Colors.grey[300])),
                    itemBuilder: (BuildContext context) {
                      final workspaceItems = workspaceState.availableWorkspaces
                          .where((path) => path != workspaceState.currentWorkspacePath)
                          .map((path) => PopupMenuItem<String>(
                                value: 'Switch to: $path',
                                child: Text('Switch to: ${path.split('/').last}'),
                              ))
                          .toList();

                      return <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'New Workspace',
                          child: Text('New Workspace'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'Open Project',
                          child: Text('Open Project'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'Export Project',
                          child: Text('Export Project'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'Save As',
                          child: Text('Save As'),
                        ),
                        if (workspaceItems.isNotEmpty) const PopupMenuDivider(),
                        ...workspaceItems,
                        const PopupMenuDivider(),
                        const PopupMenuItem<String>(
                          value: 'Exit',
                          child: Text('Exit'),
                        ),
                      ];
                    },
                  ),
                  const SizedBox(width: 16),

                  // Edit Menu with Dropdown
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      print("Selected: $value");
                    },
                    child: Text("Edit", style: TextStyle(color: Colors.grey[300])),
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'Undo',
                        child: Text('Undo'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Redo',
                        child: Text('Redo'),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'Cut',
                        child: Text('Cut'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Copy',
                        child: Text('Copy'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Paste',
                        child: Text('Paste'),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // View Menu with Dropdown
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      print("Selected: $value");
                    },
                    child: Text("View", style: TextStyle(color: Colors.grey[300])),
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'Zoom In',
                        child: Text('Zoom In'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Zoom Out',
                        child: Text('Zoom Out'),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'Full Screen',
                        child: Text('Full Screen'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Theme',
                        child: Text('Theme'),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Run Menu with Dropdown
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      print("Selected: $value");
                    },
                    child: Text("Run", style: TextStyle(color: Colors.grey[300])),
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'Run Code',
                        child: Text('Run Code'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Debug',
                        child: Text('Debug'),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'Run Tests',
                        child: Text('Run Tests'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Stop',
                        child: Text('Stop'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main 3-Column Content
            Expanded(
              child: Row(
                children: [
                  // 1. Left Sidebar (File Explorer)
                  const SizedBox(
                    width: 260,
                    child: FileExplorerPanel(),
                  ),
                  VerticalDivider(width: 1, color: Colors.grey[850]),

                  // 2. Center Area (Code Editor)
                  const Expanded(
                    child: CodeEditorPanel(),
                  ),
                  VerticalDivider(width: 1, color: Colors.grey[850]),

                  // 3. Right Sidebar (AI & Console) - Now with Full AI App
                  const SizedBox(
                    width: 320,
                    child: RightUtilityPanel(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewWorkspaceDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController _workspaceNameController = TextEditingController();
    String progressMessage = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create New Workspace'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _workspaceNameController,
                    decoration: const InputDecoration(
                      labelText: 'Workspace Name',
                      hintText: 'Enter workspace name',
                    ),
                  ),
                  if (progressMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(progressMessage, style: const TextStyle(color: Colors.grey)),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final workspaceName = _workspaceNameController.text.trim();
                    if (workspaceName.isEmpty) {
                      setState(() {
                        progressMessage = 'Please enter a valid name';
                      });
                      return;
                    }

                    try {
                      await ref.read(workspaceProvider.notifier).createNewWorkspace(
                            workspaceName,
                            (msg) {
                              setState(() {
                                progressMessage = msg;
                              });
                            },
                          );
                      Navigator.of(context).pop();
                    } catch (e) {
                      setState(() {
                        progressMessage = 'Error: $e';
                      });
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}