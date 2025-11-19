import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studio_packet/utils/telegram_reporter.dart';

import '../providers/workspace_provider.dart';
import '../widgets/CodeEditorPanel.dart';
import '../widgets/FileExplorerPanel.dart';
import '../widgets/RightUtilityPanel.dart';

class MainIdeLayout extends ConsumerStatefulWidget {
  const MainIdeLayout({super.key});

  @override
  ConsumerState<MainIdeLayout> createState() => _MainIdeLayoutState();
}

class _MainIdeLayoutState extends ConsumerState<MainIdeLayout> {
  bool _isLeftSidebarVisible = true;
  bool _isRightSidebarVisible = false; // Start hidden on mobile
  double _leftSidebarWidth = 60;
  double _rightSidebarWidth = 60;

  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 900;
    
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
                        _showNewWorkspaceDialog(context);
                      } else if (value.startsWith('Switch to: ')) {
                        final workspacePath = value.replaceFirst('Switch to: ', '');
                        await ref.read(workspaceProvider.notifier).switchWorkspace(workspacePath);
                      } else {
                        TelegramReporter.sendLog("Selected: $value");
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
                      TelegramReporter.sendLog("Selected: $value");
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
                      TelegramReporter.sendLog("Selected: $value");
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
                      TelegramReporter.sendLog("Selected: $value");
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
                  if (_isLeftSidebarVisible) ...[
                    SizedBox(
                      width: isSmallScreen 
                          ? (screenWidth * 0.6).clamp(200.0, 300.0) 
                          : _leftSidebarWidth.clamp(200.0, 400.0),
                      child: Column(
                        children: [
                          // Header with close button
                          Container(
                            color: const Color(0xFF1E1F20),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                Icon(Icons.folder, size: 16, color: Colors.grey[400]),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.close, size: 16, color: Colors.grey[400]),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    setState(() {
                                      _isLeftSidebarVisible = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Expanded(child: FileExplorerPanel()),
                        ],
                      ),
                    ),
                    VerticalDivider(width: 1, color: Colors.grey[850]),
                  ],

                  // 2. Center Area (Code Editor) with toggle buttons
                  Expanded(
                    child: Stack(
                      children: [
                        const CodeEditorPanel(),
                        // Toggle buttons - more prominent
                        Positioned(
                          top: 50,
                          left: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 39, 36, 82),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(255, 43, 31, 75).withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Left sidebar toggle
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isLeftSidebarVisible = !_isLeftSidebarVisible;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      _isLeftSidebarVisible ? Icons.folder_open : Icons.folder,
                                      size: 20,
                                      color: _isLeftSidebarVisible ? Colors.blue : Colors.grey[400],
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 20,
                                  color: Colors.grey[700],
                                ),
                                // Right sidebar toggle
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isRightSidebarVisible = !_isRightSidebarVisible;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      _isRightSidebarVisible ? Icons.smart_toy : Icons.smart_toy_outlined,
                                      size: 20,
                                      color: _isRightSidebarVisible ? Colors.blue : Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Right Sidebar (AI & Console)
                  if (_isRightSidebarVisible) ...[
                    VerticalDivider(width: 1, color: Colors.grey[850]),
                    SizedBox(
                      width: isSmallScreen 
                          ? (screenWidth * 0.5).clamp(250.0, 350.0)
                          : _rightSidebarWidth.clamp(250.0, 500.0),
                      child: Column(
                        children: [
                          // Header with close button
                          Container(
                            color: const Color(0xFF1E1F20),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                Icon(Icons.smart_toy, size: 16, color: Colors.grey[400]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'AI Assistant',
                                    style: TextStyle(color: Colors.grey[300], fontSize: 12),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, size: 16, color: Colors.grey[400]),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    setState(() {
                                      _isRightSidebarVisible = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Expanded(child: RightUtilityPanel()),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewWorkspaceDialog(BuildContext context) {
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