// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Color Hunting App';

  @override
  String get appbarTarget => 'Target';

  @override
  String get appbarHunting => 'Hunting';

  @override
  String get appbarCollection => 'Collection';

  @override
  String get navTarget => 'Target';

  @override
  String get navHunting => 'Hunting';

  @override
  String get navCollection => 'Collection';

  @override
  String get archiveHeader => 'Collection';

  @override
  String get archiveEmptyTitle => 'No colors collected yet';

  @override
  String get archiveEmptySubtitle => 'Find today\'s color and capture your day';

  @override
  String get archiveStartHunting => 'Start Hunting';

  @override
  String get fillAllSlots => 'Please fill all grid slots before saving!';

  @override
  String get huntingEmptyTitle => 'No target color yet';

  @override
  String get huntingEmptySubtitle =>
      'Pick today\'s color in the Target tab first';

  @override
  String get huntingSetTarget => 'Choose Target Color';

  @override
  String get huntingReset => 'Reset';

  @override
  String get huntingRemoveImage => 'Remove Image';

  @override
  String get huntingDownloadImage => 'Download Image';

  @override
  String get huntingTakeAnother => 'Take Another Photo';

  @override
  String get targetTapToPick => 'Tap to\npick color';

  @override
  String get targetPickAgain => 'Pick Again';

  @override
  String get targetStartHunting => 'Start Hunting';

  @override
  String get memoTitle => 'Today\'s Note';

  @override
  String get memoHint => 'Capture special moments of this day.';

  @override
  String get skip => 'Skip';

  @override
  String get save => 'Save';

  @override
  String get huntingSavedArchived => 'Hunting session saved and archived!';

  @override
  String get collageSaving => 'Saving collage to gallery...';

  @override
  String get collageSaved => 'Collage saved to gallery.';

  @override
  String get collageFailed => 'Failed to create collage.';

  @override
  String collageSaveError(Object error) {
    return 'Failed to save collage: $error';
  }

  @override
  String get collectionDeleted => 'Collection deleted';

  @override
  String get changeTargetTitle => 'Change target color';

  @override
  String get changeTargetBody =>
      'A hunt is in progress. Changing the target color will reset all photos.\n\nDo you want to continue?';

  @override
  String get cancel => 'Cancel';

  @override
  String get change => 'Change';

  @override
  String get targetChanged => 'Target color changed. Start a new hunt.';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseGallery => 'Choose from Gallery';

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
  String get downloadCollageLabel => 'Collage';

  @override
  String get downloadCardLabel => 'Card';

  @override
  String get chooseMultipleImages => 'Choose Multiple Images';

  @override
  String get noCamerasFound => 'No cameras found';
}
