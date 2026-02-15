import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

import 'package:color_hunting_app/main.dart' as app;

const _kSavedColorBoardsKey = 'savedColorBoards';
const _kCurrentHuntingGridKey = 'currentHuntingGridImagePaths';
const _kTargetColorKey = 'targetColor';
const _kIsHuntingActiveKey = 'isHuntingActive';
const _kHuntingStartDateKey = 'huntingStartDate';
const _kAppLanguageKey = 'appLanguage';

Map<String, dynamic> _boardJson({
  required int colorValue,
  required List<String?> imagePaths,
  String? memo,
  DateTime? created,
  DateTime? completed,
}) {
  return {
    'targetColor': colorValue,
    'gridImagePaths': imagePaths,
    'memo': memo,
    'createdDate': created?.toIso8601String(),
    'completedDate': completed?.toIso8601String(),
  };
}

Future<List<String>> _createMockImages() async {
  final dir = await getApplicationDocumentsDirectory();
  final existing = <String>[];
  for (int i = 1; i <= 12; i++) {
    final p = '${dir.path}/scenario_${i.toString().padLeft(2, '0')}.jpg';
    if (File(p).existsSync()) {
      existing.add(p);
    }
  }
  if (existing.length == 12) {
    return existing;
  }

  final random = Random(42);
  final files = <String>[];

  for (int i = 0; i < 12; i++) {
    final image = img.Image(width: 720, height: 720);
    final r = 80 + random.nextInt(176);
    final g = 80 + random.nextInt(176);
    final b = 80 + random.nextInt(176);
    img.fill(image, color: img.ColorRgb8(r, g, b));

    final path = '${dir.path}/mockup_$i.jpg';
    final file = File(path);
    await file.writeAsBytes(img.encodeJpg(image, quality: 92));
    files.add(path);
  }

  return files;
}

Future<void> _seedStep1() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  await prefs.setString(_kAppLanguageKey, 'ko');
  await prefs.setInt(_kTargetColorKey, const Color(0xFFFDC103).toARGB32());
  await prefs.setBool(_kIsHuntingActiveKey, false);
  await prefs.setStringList(_kCurrentHuntingGridKey, List.filled(12, ''));
  await prefs.setString(_kSavedColorBoardsKey, jsonEncode(<Map<String, dynamic>>[]));
}

Future<void> _seedStep2(List<String> images) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  await prefs.setString(_kAppLanguageKey, 'ko');
  await prefs.setInt(_kTargetColorKey, const Color(0xFFFDC103).toARGB32());
  await prefs.setBool(_kIsHuntingActiveKey, true);
  await prefs.setString(_kHuntingStartDateKey, DateTime.now().toIso8601String());

  final slots = List<String>.filled(12, '');
  final indices = List<int>.generate(12, (i) => i)..shuffle(Random(7));
  for (int i = 0; i < 9; i++) {
    slots[indices[i]] = images[i];
  }
  await prefs.setStringList(_kCurrentHuntingGridKey, slots);
  await prefs.setString(_kSavedColorBoardsKey, jsonEncode(<Map<String, dynamic>>[]));
}

Future<void> _seedStep45(List<String> images) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  await prefs.setString(_kAppLanguageKey, 'ko');
  await prefs.setInt(_kTargetColorKey, Colors.transparent.toARGB32());
  await prefs.setBool(_kIsHuntingActiveKey, false);
  await prefs.setStringList(_kCurrentHuntingGridKey, List.filled(12, ''));

  final now = DateTime.now();
  final boards = <Map<String, dynamic>>[
    _boardJson(
      colorValue: const Color(0xFFFDC103).toARGB32(),
      imagePaths: images,
      memo: '나의 첫 여행 기록',
      created: now.subtract(const Duration(days: 1)),
      completed: now,
    ),
    _boardJson(
      colorValue: const Color(0xFF7AA37A).toARGB32(),
      imagePaths: images,
      memo: '숲 산책',
      created: now.subtract(const Duration(days: 7)),
      completed: now.subtract(const Duration(days: 7)),
    ),
    _boardJson(
      colorValue: const Color(0xFF6D8FCF).toARGB32(),
      imagePaths: images,
      memo: '비 오는 날',
      created: now.subtract(const Duration(days: 14)),
      completed: now.subtract(const Duration(days: 14)),
    ),
    _boardJson(
      colorValue: const Color(0xFFD48484).toARGB32(),
      imagePaths: images,
      memo: '저녁 산책',
      created: now.subtract(const Duration(days: 21)),
      completed: now.subtract(const Duration(days: 21)),
    ),
  ];

  await prefs.setString(_kSavedColorBoardsKey, jsonEncode(boards));
}

Future<void> _launchApp(WidgetTester tester) async {
  await app.main();
  await tester.pumpAndSettle(const Duration(seconds: 2));
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _goToHuntingTab(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.grid_3x3).first);
  await tester.pumpAndSettle();
}

Future<void> _goToCollectionTab(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.photo_library_outlined).first);
  await tester.pumpAndSettle();
}

void main() {
  final binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized()
          as IntegrationTestWidgetsFlutterBinding;

  testWidgets('01 target tab fdc103', (tester) async {
    await _seedStep1();
    await _launchApp(tester);
    await binding.takeScreenshot('01_target_fdc103');
  });

  testWidgets('02 hunting tab with 9 random images', (tester) async {
    final images = await _createMockImages();
    await _seedStep2(images);
    await _launchApp(tester);
    await _goToHuntingTab(tester);
    await binding.takeScreenshot('02_hunting_9_random');
  });

  testWidgets('03 camera screen', (tester) async {
    final images = await _createMockImages();
    await _seedStep2(images);
    await _launchApp(tester);
    await _goToHuntingTab(tester);

    final emptyCell = find.byIcon(Icons.camera_alt_outlined).first;
    await tester.tap(emptyCell);
    await tester.pumpAndSettle();

    final cameraOption = find.byIcon(Icons.camera_alt).first;
    if (cameraOption.evaluate().isNotEmpty) {
      await tester.tap(cameraOption);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    await binding.takeScreenshot('03_camera_screen');
  });

  testWidgets('04 collection tab with 4 records including fdc103', (tester) async {
    final images = await _createMockImages();
    await _seedStep45(images);
    await _launchApp(tester);
    await _goToCollectionTab(tester);
    await binding.takeScreenshot('04_collection_tab');
  });

  testWidgets('05 fdc103 detail page', (tester) async {
    final images = await _createMockImages();
    await _seedStep45(images);
    await _launchApp(tester);
    await _goToCollectionTab(tester);

    final fdcText = find.text('#FDC103');
    if (fdcText.evaluate().isNotEmpty) {
      await tester.tap(fdcText.first);
      await tester.pumpAndSettle();
    }

    await binding.takeScreenshot('05_fdc103_detail');
  });
}
