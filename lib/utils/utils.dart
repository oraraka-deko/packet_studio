import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;



Future<String> getSandboxesPath() async {
  final appSupportDir = await getApplicationSupportDirectory();
  return path.join(appSupportDir.path, 'sandboxes');
}