import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studio_packet/providers/workspace_provider.dart';

import 'code_editor/constants.dart';
import 'code_editor/themes.dart';

// Constants for consistency and responsiveness (reused from previous)
const double kSmallScreenThreshold = 500.0;
const double kMediumScreenThreshold = 800.0;
const Color kBackgroundColor = Color(0xFF1E1F20);
const Color kHeaderColor = Color(0xFF131314);
const Color kEditorBgColor = Color(0xFF0D1117); // GitHub-dark like
const double kBasePadding = 8.0;
const double kBaseFontSize = 14.0;
const double kBaseIconSize = 20.0;

class CodeEditorPanel extends ConsumerStatefulWidget {
  const CodeEditorPanel({super.key});

  @override
  ConsumerState<CodeEditorPanel> createState() => _CodeEditorPanelState();
}

class _CodeEditorPanelState extends ConsumerState<CodeEditorPanel>
    with TickerProviderStateMixin {
  bool _hasChanges = false;
  List<Issue> _issues = [];
  late CodeController _codeController;
  late AnimationController _pulseController;
  late AnimationController _saveController;
  late FocusNode codeFieldFocusNode;

  @override
  void initState() {
    super.initState();
    codeFieldFocusNode = FocusNode();
    _codeController = CodeController(
      analyzer: const DefaultLocalAnalyzer(),
      analysisResult: const AnalysisResult(issues: []), // Fixed: Empty issues initially
      language: builtinLanguages["dart"],
      namedSectionParser: const BracketsStartEndNamedSectionParser(),
      text: '', // Fixed: Initial empty text to avoid circular ref
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _saveController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _codeController.addListener(() {
      if (!_hasChanges) {
        setState(() => _hasChanges = true);
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _pulseController.dispose();
    _saveController.dispose();
    codeFieldFocusNode.dispose();
    super.dispose();
  }

  void _saveFile() {
    if (_hasChanges) {
      ref.read(workspaceProvider.notifier).saveFile(_codeController.text);
      setState(() => _hasChanges = false);
      _saveController.forward().then((_) => _saveController.reverse());
    }
  }

  double _getResponsiveValue(double small, double large, {double? medium}) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < kSmallScreenThreshold) return small;
    if (screenWidth < kMediumScreenThreshold) return medium ?? (small + large) / 2;
    return large;
  }

  bool get isSmallScreen => MediaQuery.of(context).size.width < kSmallScreenThreshold;

  IconData _getFileIcon(String? extension) {
    if (extension == null) return Icons.insert_drive_file;
    switch (extension.toLowerCase()) {
      case '.dart':
        return Icons.code;
      case '.yaml':
      case '.yml':
        return Icons.inventory_2;
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

  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceProvider);
    final selectedFile = workspaceState.selectedFile;
    final fileContent = workspaceState.fileContent;
    final padding = _getResponsiveValue(4.0, 12.0);
    final fontSize = _getResponsiveValue(12.0, kBaseFontSize).clamp(12.0, 16.0);
    final iconSize = _getResponsiveValue(16.0, kBaseIconSize);

    // Update controller when file content changes (unchanged logic)
    if (fileContent != null && _codeController.text != fileContent) {
      _codeController.text = fileContent;
      _hasChanges = false;
    }

    return Container(
      color: kBackgroundColor,
      child: Column(
        children: [
          // Enhanced Header (AppBar-like)
          Container(
            decoration: BoxDecoration(
              color: kHeaderColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: padding,
              vertical: _getResponsiveValue(8.0, 12.0),
            ),
            child: Row(
              children: [
                if (selectedFile != null) ...[
                  // File Icon + Name
                  Icon(
                    _getFileIcon(selectedFile.fileExtentsion),
                    color: Colors.grey[400],
                    size: iconSize,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedFile.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontSize: fontSize,
                                fontWeight: FontWeight.w500,
                              ) ??
                              TextStyle(
                                color: Colors.white,
                                fontSize: fontSize,
                                fontWeight: FontWeight.w500,
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (!isSmallScreen)
                          Text(
                            selectedFile.path.split('/').last,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: fontSize - 2,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                      ],
                    ),
                  ),
                  // Changes Indicator (Animated Pulsing Dot)
                  if (_hasChanges)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) => Transform.scale(
                        scale: _pulseController.value,
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.orange[400],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.5 * _pulseController.value),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ] else
                  // No File State
                  Expanded(
                    child: Semantics(
                      label: 'No file selected',
                      child: Text(
                        'No file selected',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                              fontSize: fontSize,
                            ) ??
                            TextStyle(color: Colors.grey[600], fontSize: fontSize),
                      ),
                    ),
                  ),
                const Spacer(),
                // Save Button (Animated)
                if (selectedFile != null && _hasChanges)
                  AnimatedBuilder(
                    animation: _saveController,
                    builder: (context, child) => ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 0.95).animate(
                        CurvedAnimation(parent: _saveController, curve: Curves.easeInOut),
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(right: padding),
                        child: ElevatedButton.icon(
                          onPressed: _saveFile,
                          icon: Icon(Icons.save, size: iconSize - 4, color: Colors.white),
                          label: Text(
                            'Save',
                            style: TextStyle(fontSize: fontSize - 2),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: _getResponsiveValue(8.0, 12.0),
                              vertical: _getResponsiveValue(4.0, 8.0),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Subtle Divider
          Container(
            height: 1,
            color: Colors.grey[800],
            margin: EdgeInsets.symmetric(horizontal: padding),
          ),
          // Code Editor (Enhanced)
          Expanded(
            child: selectedFile != null
                ? Container(
                    margin: EdgeInsets.all(padding),
                    decoration: BoxDecoration(
                      color: kEditorBgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[800]!, width: 1),
                      boxShadow: isSmallScreen
                          ? null // No shadow on small for flat feel
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Semantics(
                        label: 'Code editor for ${selectedFile.name}',
                        excludeSemantics: true,
                        child: CodeTheme(
                          data: CodeThemeData(styles: themes["vs2015"]),
                          child: CodeField(
                            onChanged: (p0) {
                              // Fixed: Actually update state (was returning bool)
                              if (!_hasChanges) {
                                setState(() => _hasChanges = true);
                              }
                            },
                            focusNode: codeFieldFocusNode,
                            controller: _codeController,
                            textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'SourceCode',
                                  fontSize: fontSize,
                                  color: Colors.white,
                                ) ??
                                const TextStyle(
                                  fontFamily: 'SourceCode',
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                            gutterStyle: GutterStyle(
                              textStyle: TextStyle(
                                color: Colors.purple[400],
                                fontSize: fontSize - 2,
                              ),
                              showLineNumbers: true,
                              showErrors: true,
                              showFoldingHandles: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : // Enhanced Empty State
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.code_off,
                            color: Colors.grey[600],
                            size: _getResponsiveValue(48.0, 64.0),
                          ),
                          const SizedBox(height: 16),
                          Semantics(
                            label: 'Select a file to edit',
                            child: Text(
                              'Select a file to edit',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: fontSize + 2,
                                  ) ??
                                  TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (!isSmallScreen)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Open the file explorer on the left to get started.',
                                style: TextStyle(color: Colors.grey[500], fontSize: fontSize - 2),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
          ),
          // Subtle Footer (Word/Line Count - Display Only)
          if (selectedFile != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: 4),
              decoration: BoxDecoration(
                color: kHeaderColor,
                border: Border(top: BorderSide(color: Colors.grey[800]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'L: ${_codeController.text.split('\n').length} | C: ${_codeController.text.length}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: fontSize - 2,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}