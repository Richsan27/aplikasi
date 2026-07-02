import 'dart:io';

void saveFile(String content, String fileName) {
  String? path;
  if (Platform.isWindows) {
    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile != null) {
      path = "$userProfile\\Downloads\\$fileName";
    }
  }
  path ??= fileName;
  final file = File(path);
  file.writeAsStringSync(content);
}
