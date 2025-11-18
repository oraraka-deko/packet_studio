import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studio_packet/providers/workspace_provider.dart';

import 'code_editor/constants.dart';
import 'code_editor/themes.dart';

class CodeEditorPanel extends ConsumerStatefulWidget {
  const CodeEditorPanel({super.key});

  @override
  ConsumerState<CodeEditorPanel> createState() => _CodeEditorPanelState();
}

class _CodeEditorPanelState extends ConsumerState<CodeEditorPanel> {
  bool _hasChanges = false;
List<Issue> _issues =[];
late CodeController _codeController = CodeController();
  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
    analyzer: const DefaultLocalAnalyzer(),
    analysisResult :  AnalysisResult(issues: _issues),
    language: builtinLanguages["dart"],
    namedSectionParser: const BracketsStartEndNamedSectionParser(),
    text: _codeController.text,
  );
    _codeController.addListener((){
if (!_hasChanges) {
        setState(() => _hasChanges = true);
      }

    });
   }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _saveFile() {
    if (_hasChanges) {
      ref.read(workspaceProvider.notifier).saveFile(_codeController.text);
      setState(() => _hasChanges = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceProvider);
    final selectedFile = workspaceState.selectedFile;
    final fileContent = workspaceState.fileContent;
  final codeFieldFocusNode = FocusNode();
   

    // Update controller when file content changes
    if (fileContent != null && _codeController.text != fileContent) {
      _codeController.text = fileContent;
      _hasChanges = false;
    }

    return Container(
      color: const Color(0xFF1E1F20),
      child: Column(
        children: [
          // File tab bar
          Container(
            color: const Color(0xFF131314),
            child: Row(
              children: [
                if (selectedFile != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1F20),
                      border: Border(
                        right: BorderSide(color: Colors.grey[850]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          selectedFile.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        if (_hasChanges)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'No file selected',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                const Spacer(),
                if (selectedFile != null && _hasChanges)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ElevatedButton.icon(
                      onPressed: _saveFile,
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Code Editor
          Expanded(
            child: selectedFile != null
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView(
        children: [
          CodeTheme(
            data: CodeThemeData(styles: themes["vs2015"]),
            child: CodeField(
              onChanged:(p0) => _hasChanges,
              focusNode: codeFieldFocusNode,
              controller: _codeController,
              textStyle: const TextStyle(fontFamily: 'SourceCode'),
              gutterStyle: GutterStyle(
                textStyle: const TextStyle(
                  color: Colors.purple,
                ),
                showLineNumbers: true,
                showErrors: true,
                showFoldingHandles: true,
              ),
            ),
          ),
        ],
      ),
                  )
                : Center(
                    child: Text(
                      'Select a file to edit',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
