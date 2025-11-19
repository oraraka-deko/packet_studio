import 'package:hive_ce/hive.dart';
import 'package:studio_packet/aidata/data/model/chat/config.dart';
import 'package:studio_packet/aidata/data/model/chat/folder.dart';
import 'package:studio_packet/aidata/data/model/chat/history/history.dart';
import 'package:studio_packet/aidata/data/model/chat/type.dart';
import 'package:openai_dart/openai_dart.dart';

@GenerateAdapters([
  AdapterSpec<ChatHistoryItem>(),
  AdapterSpec<ChatContentType>(),
  AdapterSpec<ChatContent>(),
  AdapterSpec<ChatRole>(),
  AdapterSpec<ChatHistory>(),
  AdapterSpec<ChatConfig>(),
  AdapterSpec<ChatType>(),
  AdapterSpec<ChatSettings>(),
  AdapterSpec<ChatFolder>(),
])
part 'hive_adapters.g.dart';
