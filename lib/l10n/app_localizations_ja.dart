// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Color Hunting App';

  @override
  String get appbarTarget => 'ターゲット選択';

  @override
  String get appbarHunting => 'カラーハンティング';

  @override
  String get appbarCollection => 'コレクション';

  @override
  String get navTarget => 'ターゲット';

  @override
  String get navHunting => 'ハンティング';

  @override
  String get navCollection => 'コレクション';

  @override
  String get archiveHeader => 'コレクション';

  @override
  String get archiveEmptyTitle => 'まだ収集されたカラーがありません';

  @override
  String get archiveEmptySubtitle => '今日の色を見つけて一日を記録しましょう';

  @override
  String get archiveStartHunting => 'ハンティングを始める';

  @override
  String get fillAllSlots => '保存する前にすべてのマスを埋めてください！';

  @override
  String get huntingEmptyTitle => 'まだターゲットカラーがありません';

  @override
  String get huntingEmptySubtitle => 'まずTargetタブで今日の色を選んでください';

  @override
  String get huntingSetTarget => 'ターゲットカラーを選ぶ';

  @override
  String get huntingReset => 'リセット';

  @override
  String get huntingRemoveImage => '画像を削除';

  @override
  String get huntingTakeAnother => '別の写真を撮る';

  @override
  String get targetTapToPick => 'タップして\n色を選択';

  @override
  String get targetPickAgain => 'もう一度選ぶ';

  @override
  String get targetStartHunting => 'ハンティング開始';

  @override
  String get memoTitle => '今日の記録';

  @override
  String get memoHint => 'この日の特別な瞬間を記録してみましょう。';

  @override
  String get skip => 'スキップ';

  @override
  String get save => '保存';

  @override
  String get huntingSavedArchived => 'ハンティングが保存され、アーカイブされました！';

  @override
  String get collageSaving => 'コラージュ画像をギャラリーに保存中...';

  @override
  String get collageSaved => 'コラージュ画像をギャラリーに保存しました。';

  @override
  String get collageFailed => 'コラージュ画像の作成に失敗しました。';

  @override
  String collageSaveError(Object error) {
    return 'コラージュ画像の保存に失敗しました: $error';
  }

  @override
  String get collectionDeleted => 'コレクションが削除されました';

  @override
  String get changeTargetTitle => 'ターゲットカラーを変更';

  @override
  String get changeTargetBody =>
      '進行中のハンティングがあります。\nターゲットカラーを変更すると、現在撮影した写真がすべて初期化されます。\n\n本当に変更しますか？';

  @override
  String get cancel => 'キャンセル';

  @override
  String get change => '変更';

  @override
  String get targetChanged => 'ターゲットカラーが変更されました。新しいハンティングを開始してください。';

  @override
  String get takePhoto => '写真を撮る';

  @override
  String get chooseGallery => 'ギャラリーから選択';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageChinese => '中文';

  @override
  String get languageSelectedEn => 'English selected';

  @override
  String get languageSelectedKo => '한국어 선택됨';

  @override
  String get languageSelectedJa => '日本語を選択しました';

  @override
  String get languageSelectedZh => '已选择中文';

  @override
  String get downloadCollageLabel => 'コラージュ';

  @override
  String get downloadCardLabel => 'カード';

  @override
  String get chooseMultipleImages => '複数の画像を選択';

  @override
  String get noCamerasFound => 'カメラが見つかりません';
}
