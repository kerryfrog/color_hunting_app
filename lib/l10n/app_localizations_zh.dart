// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Color Hunting App';

  @override
  String get appbarTarget => '选择目标';

  @override
  String get appbarHunting => '颜色狩猎';

  @override
  String get appbarCollection => '收藏';

  @override
  String get navTarget => '目标';

  @override
  String get navHunting => '狩猎';

  @override
  String get navCollection => '收藏';

  @override
  String get archiveHeader => '收藏';

  @override
  String get archiveEmptyTitle => '还没有收集到颜色';

  @override
  String get archiveEmptySubtitle => '寻找今天的颜色，记录你的一天';

  @override
  String get archiveStartHunting => '开始狩猎';

  @override
  String get fillAllSlots => '请先填满所有格子后再保存！';

  @override
  String get huntingEmptyTitle => '还没有目标颜色';

  @override
  String get huntingEmptySubtitle => '请先在 Target 页面选择今天的颜色';

  @override
  String get huntingSetTarget => '选择目标颜色';

  @override
  String get huntingReset => '重置';

  @override
  String get huntingImagesCleared => '仅图片已重置';

  @override
  String get huntingRemoveImage => '删除图片';

  @override
  String get huntingDownloadImage => '下载图片';

  @override
  String get huntingTakeAnother => '再拍一张';

  @override
  String get targetTapToPick => '点击\n选择颜色';

  @override
  String get targetPickAgain => '重新选择';

  @override
  String get targetStartHunting => '开始狩猎';

  @override
  String get memoTitle => '今日记录';

  @override
  String get memoHint => '记录这一天的特别瞬间。';

  @override
  String get skip => '跳过';

  @override
  String get save => '保存';

  @override
  String get huntingSavedArchived => '狩猎已保存并归档！';

  @override
  String get collageSaving => '正在将拼贴图保存到相册...';

  @override
  String get collageSaved => '拼贴图已保存到相册。';

  @override
  String get collageFailed => '生成拼贴图失败。';

  @override
  String collageSaveError(Object error) {
    return '保存拼贴图失败: $error';
  }

  @override
  String get collectionDeleted => '收藏已删除';

  @override
  String get changeTargetTitle => '更改目标颜色';

  @override
  String get changeTargetBody => '当前有进行中的狩猎。\n更改目标颜色会重置当前拍摄的所有照片。\n\n确定要继续吗？';

  @override
  String get cancel => '取消';

  @override
  String get change => '更改';

  @override
  String get targetChanged => '目标颜色已更改。请开始新的狩猎。';

  @override
  String get takePhoto => '拍照';

  @override
  String get chooseGallery => '从相册选择';

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
  String get downloadCollageLabel => '拼贴';

  @override
  String get downloadCardLabel => '卡片';

  @override
  String get chooseMultipleImages => '选择多张图片';

  @override
  String get noCamerasFound => '未找到相机';
}
