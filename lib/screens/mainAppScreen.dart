import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/AiPromptBar.dart';
import '../widgets/CodeEditorPanel.dart';
import '../widgets/FileExplorerPanel.dart';
import '../widgets/RightUtilityPanel.dart';

class MainIdeLayout extends ConsumerWidget {
  const MainIdeLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  Text("File", style: TextStyle(color: Colors.grey[300])),
                  const SizedBox(width: 16),
                  Text("Edit", style: TextStyle(color: Colors.grey[300])),
                  const SizedBox(width: 16),
                  Text("View", style: TextStyle(color: Colors.grey[300])),
                  const SizedBox(width: 16),
                  Text("Run", style: TextStyle(color: Colors.grey[300])),
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

                  // 3. Right Sidebar (AI & Console)
                  const SizedBox(
                    width: 320,
                    child: RightUtilityPanel(),
                  ),
                ],
              ),
            ),

            // Bottom AI Prompt Bar
            const AiPromptBar(),
          ],
        ),
      ),
    );
  }
}
