import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studio_packet/utils/telegram_reporter.dart';
import 'package:studio_packet/services/workspace_service.dart';

import '../models/editor_tab.dart';

/// State class for the editor
class EditorState {
  final List<EditorTab> openTabs;
  final int activeTabIndex;

  EditorState({
    this.openTabs = const [],
    this.activeTabIndex = -1,
  });

  /// The currently active tab, or null if none are open.
  EditorTab? get activeTab => (activeTabIndex != -1 && openTabs.isNotEmpty)
      ? openTabs[activeTabIndex]
      : null;

  EditorState copyWith({
    List<EditorTab>? openTabs,
    int? activeTabIndex,
  }) {
    return EditorState(
      openTabs: openTabs ?? this.openTabs,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
    );
  }
}

/// Riverpod provider for the editor
final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier();
});

/// Manages the state of the code editor, including all open tabs
/// and the currently active tab.
class EditorNotifier extends StateNotifier<EditorState> {
  final WorkspaceService _workspaceService = WorkspaceService();

  EditorNotifier() : super(EditorState());

  /// Opens a file in a new tab.
  /// If the file is already open, it just switches to that tab.
  Future<void> openFile(String filePath, String fileName) async {
    // 1. Check if file is already open
    final existingTabIndex = state.openTabs.indexWhere((tab) => tab.filePath == filePath);

    if (existingTabIndex != -1) {
      // 2. If open, just switch to it
      setActiveTab(existingTabIndex);
    } else {
      // 3. If not open, read file and create new tab
      try {
        // Use WorkspaceService to read the file
        String content = await _workspaceService.readFile(filePath);
        
        final newTab = EditorTab(
          filePath: filePath,
          fileName: fileName,
          initialContent: content,
        );
        
        final updatedTabs = List<EditorTab>.from(state.openTabs)..add(newTab);
        state = state.copyWith(
          openTabs: updatedTabs,
          activeTabIndex: updatedTabs.length - 1,
        );
      } catch (e, s) {
        // TODO: Show an error dialog
        TelegramReporter.reportError(e, s, null, 'Error opening file $filePath', false);
      }
    }
  }

  /// Closes a tab at a given index.
  Future<void> closeTab(int index) async {
    if (index < 0 || index >= state.openTabs.length) return;

    final tab = state.openTabs[index];

    if (tab.isDirty) {
      // TODO: Show a "Save changes?" dialog.
      // For this example, we'll just discard changes.
      TelegramReporter.sendLog("Closing tab with unsaved changes. (Discarding for now)");
    }

    // Clean up resources
    tab.dispose(); 
    
    final updatedTabs = List<EditorTab>.from(state.openTabs)..removeAt(index);

    // Adjust active tab index
    int newActiveIndex = state.activeTabIndex;
    if (newActiveIndex >= index) {
      newActiveIndex = updatedTabs.isEmpty ? -1 : (index - 1).clamp(0, updatedTabs.length - 1);
    }
    
    state = state.copyWith(
      openTabs: updatedTabs,
      activeTabIndex: newActiveIndex,
    );
  }

  /// Saves the currently active tab.
  Future<void> saveActiveFile() async {
    final activeTab = state.activeTab;
    if (activeTab == null) return;
    
    try {
      // Use WorkspaceService to write the file
      await _workspaceService.writeFile(
        activeTab.filePath,
        activeTab.currentContent,
      );
      
      // Mark the tab as no longer 'dirty'
      activeTab.markAsSaved();
      
      // Trigger a rebuild to update the tab UI (e.g., remove '*')
      state = state.copyWith(openTabs: List<EditorTab>.from(state.openTabs));
    } catch (e, s) {
      // TODO: Show error dialog
      TelegramReporter.reportError(e, s, null, 'Error saving file ${activeTab.filePath}', false);
    }
  }

  /// Sets the new active tab index.
  void setActiveTab(int index) {
    if (index != state.activeTabIndex && index >= 0 && index < state.openTabs.length) {
      state = state.copyWith(activeTabIndex: index);
    }
  }

  /// Dispose all tab controllers when needed
  void disposeAllTabs() {
    for (var tab in state.openTabs) {
      tab.dispose();
    }
  }
}