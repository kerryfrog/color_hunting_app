import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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

const _kMockupAssetPaths = <String>[
  'mockup/KakaoTalk_Photo_2026-02-16-01-39-09 001.jpeg',
  'mockup/KakaoTalk_Photo_2026-02-16-01-39-10 002.jpeg',
  'mockup/KakaoTalk_Photo_2026-02-16-01-39-10 003.jpeg',
  'mockup/KakaoTalk_Photo_2026-02-16-01-39-10 004.jpeg',
  'mockup/KakaoTalk_Photo_2026-02-16-01-39-10 005.jpeg',
  'mockup/KakaoTalk_Photo_2026-02-16-01-39-10 006.jpeg',
  'mockup/KakaoTalk_Photo_2026-02-16-01-39-10 007.jpeg',
  'mockup/KakaoTalk_Photo_2026-02-16-01-39-10 008.jpeg',
  'mockup/KakaoTalk_Photo_2026-02-16-01-39-10 009.jpeg',
  'mockup/KakaoTalk_Photo_2026-02-16-01-39-10 010.jpeg',
  'mockup/KakaoTalk_Photo_2026-02-16-01-39-10 011.jpeg',
  'mockup/KakaoTalk_Photo_2026-02-16-01-39-10 012.jpeg',
];

Future<List<String>> _copyMockAssetsToDocuments() async {
  final dir = await getApplicationDocumentsDirectory();
  final files = <String>[];
  for (int i = 0; i < _kMockupAssetPaths.length; i++) {
    final assetPath = _kMockupAssetPaths[i];
    final outPath =
        '${dir.path}/save_detail_${(i + 1).toString().padLeft(2, '0')}.jpg';
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    await File(outPath).writeAsBytes(bytes, flush: true);
    files.add(outPath);
  }
  return files;
}

Future<void> _seedHuntingWith12Images() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  await prefs.setString(_kAppLanguageKey, 'ko');
  await prefs.setInt(_kTargetColorKey, const Color(0xFFFDC103).toARGB32());
  await prefs.setBool(_kIsHuntingActiveKey, true);
  await prefs.setString(
    _kHuntingStartDateKey,
    DateTime.now().toIso8601String(),
  );
  final images = await _copyMockAssetsToDocuments();
  await prefs.setStringList(_kCurrentHuntingGridKey, images);
  await prefs.setString(
    _kSavedColorBoardsKey,
    jsonEncode(<Map<String, dynamic>>[]),
  );
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

void main() {
  final binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized()
          as IntegrationTestWidgetsFlutterBinding;

  testWidgets('save 12 images then capture detail page', (tester) async {
    await _seedHuntingWith12Images();
    await _launchApp(tester);
    await _goToHuntingTab(tester);

    final saveFinder = find.text('저장');
    expect(saveFinder, findsWidgets);
    await tester.tap(saveFinder.first);
    await tester.pumpAndSettle();

    final skipKo = find.text('건너뛰기');
    final skipEn = find.text('Skip');
    if (skipKo.evaluate().isNotEmpty) {
      await tester.tap(skipKo.first);
    } else if (skipEn.evaluate().isNotEmpty) {
      await tester.tap(skipEn.first);
    }
    await tester.pumpAndSettle(const Duration(seconds: 2));

    Finder fdcFinder = find.text('#FDC103');
    if (fdcFinder.evaluate().isEmpty) {
      await tester.tap(find.byIcon(Icons.photo_library_outlined).first);
      await tester.pumpAndSettle();
      fdcFinder = find.text('#FDC103');
    }

    expect(fdcFinder, findsWidgets);
    await tester.tap(fdcFinder.first);
    await tester.pumpAndSettle();

    await binding.takeScreenshot('06_saved_12_detail');
  });
}
