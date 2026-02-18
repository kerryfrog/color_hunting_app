// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Color Hunting';

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
  String get archiveEmptyTitle => '아직 수집된 컬러가 없네요';

  @override
  String get archiveEmptySubtitle => '오늘의 색을 찾아 일상을 기록해보세요';

  @override
  String get archiveStartHunting => '사냥 시작하기';

  @override
  String get fillAllSlots => '모든 칸을 채운 후 저장해주세요!';

  @override
  String get huntingEmptyTitle => '아직 타겟 컬러가 없어요';

  @override
  String get huntingEmptySubtitle => 'Target 탭에서 오늘의 색상을 먼저 골라보세요';

  @override
  String get huntingSetTarget => '타겟 컬러 정하기';

  @override
  String get huntingReset => '초기화';

  @override
  String get huntingImagesCleared => '이미지만 초기화되었습니다';

  @override
  String get huntingRemoveImage => '이미지 제거';

  @override
  String get huntingDownloadImage => '이미지 다운로드';

  @override
  String get huntingTakeAnother => '다른 사진 찍기';

  @override
  String get targetTapToPick => '탭해서\n색상 정하기';

  @override
  String get targetPickAgain => '다시 고르기';

  @override
  String get targetStartHunting => 'Hunting 시작';

  @override
  String get memoTitle => '오늘의 기록';

  @override
  String get memoHint => '이날의 특별한 순간들을 기록해보세요.';

  @override
  String get skip => '건너뛰기';

  @override
  String get save => '저장';

  @override
  String get huntingSavedArchived => '콜라주가 저장되었습니다!';

  @override
  String get collageSaving => '콜라주 이미지를 갤러리에 저장 중입니다...';

  @override
  String get collageSaved => '콜라주 이미지를 갤러리에 저장했습니다.';

  @override
  String get collageFailed => '콜라주 이미지 생성에 실패했습니다.';

  @override
  String collageSaveError(Object error) {
    return '콜라주 이미지 저장 실패: $error';
  }

  @override
  String get collectionDeleted => '컬렉션이 삭제되었습니다';

  @override
  String get changeTargetTitle => '타겟 컬러 변경';

  @override
  String get changeTargetBody =>
      '진행 중인 헌팅이 있습니다.\n타겟 컬러를 변경하면 현재 촬영한 사진들이 모두 초기화됩니다.\n\n정말 변경하시겠습니까?';

  @override
  String get cancel => '취소';

  @override
  String get change => '변경';

  @override
  String get targetChanged => '타겟 컬러가 변경되었습니다. 새로운 헌팅을 시작해주세요.';

  @override
  String get takePhoto => '사진 촬영';

  @override
  String get chooseGallery => '갤러리에서 선택';

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
  String get languageSelectedJa => '일본어 선택됨';

  @override
  String get languageSelectedZh => '중국어 선택됨';

  @override
  String get downloadCollageLabel => '콜라주';

  @override
  String get downloadCardLabel => '카드';

  @override
  String get chooseMultipleImages => '여러 장 선택';

  @override
  String get noCamerasFound => '카메라를 찾을 수 없습니다';
}
