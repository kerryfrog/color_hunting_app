import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final outPath = Platform.environment['MOCKUP_CAPTURE_DIR'] ?? 'mockup/captures';
  final outDir = Directory(outPath);
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final file = File('${outDir.path}/$name.png');
      file.writeAsBytesSync(bytes);
      return true;
    },
  );
}
