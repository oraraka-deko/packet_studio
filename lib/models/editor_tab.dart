import 'package:flutter/material.dart';

/// Represents a single open tab in the code editor.
/// It holds the state for a file being edited.
class EditorTab {
  final String filePath; // Unique ID and path to the file
  final String fileName;
  
  /// The content of the file as it is on disk (or when it was last saved).
  String _savedContent;

  /// The text controller holding the *current*, in-memory text.
  final TextEditingController controller;

  /// A stream controller to notify the tab UI to rebuild (e.g., to show/hide the 'dirty' asterisk).
  // Note: A more robust solution would use a ValueNotifier or integrate with your Provider.
  final ValueNotifier<bool> isDirtyNotifier = ValueNotifier(false);

  EditorTab({
    required this.filePath,
    required this.fileName,
    required String initialContent,
  }) : _savedContent = initialContent,
       controller = TextEditingController(text: initialContent) {
    
    // Listen for changes in the text controller
    controller.addListener(_onTextChanged);
  }

  /// The original content of the file.
  String get savedContent => _savedContent;

  /// The current, possibly modified, content in the editor.
  String get currentContent => controller.text;

  /// Check if the file has been modified.
  bool get isDirty => _savedContent != currentContent;

  /// Listener that updates the dirty state.
  void _onTextChanged() {
    isDirtyNotifier.value = isDirty;
  }

  /// Call this when the file is saved to update the baseline.
  void markAsSaved() {
    _savedContent = currentContent;
    isDirtyNotifier.value = false;
  }

  /// Cleans up the controller when the tab is closed.
  void dispose() {
    controller.removeListener(_onTextChanged);
    controller.dispose();
    isDirtyNotifier.dispose();
  }
}