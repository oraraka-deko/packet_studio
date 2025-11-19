import 'package:fl_lib/fl_lib.dart';
import 'package:studio_packet/aidata/data/store/config.dart';
import 'package:studio_packet/aidata/data/store/folder.dart';
import 'package:studio_packet/aidata/data/store/history.dart';
import 'package:studio_packet/aidata/data/store/setting.dart';
import 'package:studio_packet/aidata/data/store/tool.dart';
import 'package:studio_packet/aidata/data/store/trash.dart';

abstract final class Stores {
  static final history = HistoryStore.instance;
  static final setting = SettingStore.instance;
  static final config = ConfigStore.instance;
  static final mcp = McpStore.instance;
  static final trash = TrashStore.instance;
  static final folder = FolderStore.instance;
  static final List<HiveStore> all = [
    setting,
    history,
    config,
    mcp,
    trash,
    folder,
  ];

  static Future<void> init() async {
    await Future.wait(all.map((e) => e.init()));
  }

  static int get lastModTime {
    var lastModTime = DateTime.now().millisecondsSinceEpoch;
    for (final store in all) {
      final last = store.lastUpdateTs ?? {};
      if (last.isEmpty) continue;
      final modTime = last.values.reduce((a, b) => a > b ? a : b);
      if (modTime > lastModTime) {
        lastModTime = modTime;
      }
    }
    return lastModTime;
  }
}
