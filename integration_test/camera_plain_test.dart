import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:color_hunting_app/main.dart' as app;

const _kSavedColorBoardsKey = 'savedColorBoards';
const _kCurrentHuntingGridKey = 'currentHuntingGridImagePaths';
const _kTargetColorKey = 'targetColor';
const _kIsHuntingActiveKey = 'isHuntingActive';
const _kHuntingStartDateKey = 'huntingStartDate';
const _kAppLanguageKey = 'appLanguage';

Future<void> _seedForPlainCamera() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  await prefs.setString(_kAppLanguageKey, 'ko');
  await prefs.setInt(_kTargetColorKey, const Color(0xFFFDC103).toARGB32());
  await prefs.setBool(_kIsHuntingActiveKey, true);
  await prefs.setString(_kHuntingStartDateKey, DateTime.now().toIso8601String());
  final docs = await getApplicationDocumentsDirectory();
  final seedFile = File('${docs.path}/camera_seed.jpg');
  final seedImg = img.Image(width: 64, height: 64);
  img.fill(seedImg, color: img.ColorRgb8(253, 193, 3));
  await seedFile.writeAsBytes(img.encodeJpg(seedImg, quality: 90));
  final slots = List<String>.filled(12, '');
  slots[11] = seedFile.path; // keep hunting session active, leave most cells empty
  await prefs.setStringList(_kCurrentHuntingGridKey, slots);
  await prefs.setString(_kSavedColorBoardsKey, jsonEncode(<Map<String, dynamic>>[]));
}

Future<void> _launchApp(WidgetTester tester) async {
  await app.main();
  await tester.pumpAndSettle(const Duration(seconds: 2));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  final binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized()
          as IntegrationTestWidgetsFlutterBinding;

  testWidgets('camera plain capture', (tester) async {
    await _seedForPlainCamera();
    await _launchApp(tester);

    await tester.tap(find.byIcon(Icons.grid_3x3).first);
    await tester.pumpAndSettle();

    final grid = find.byType(GridView).first;
    final gridTopLeft = tester.getTopLeft(grid);
    await tester.tapAt(gridTopLeft + const Offset(40, 40));
    await tester.pumpAndSettle();

    final cameraOption = find.byIcon(Icons.camera_alt);
    if (cameraOption.evaluate().isNotEmpty) {
      await tester.tap(cameraOption.first);
    } else {
      await tester.tap(find.byType(ListTile).first);
    }
    // Give camera transition/initialization enough time before capture.
    await tester.pumpAndSettle(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 2));

    await binding.takeScreenshot('03_camera_plain');
  });
}
