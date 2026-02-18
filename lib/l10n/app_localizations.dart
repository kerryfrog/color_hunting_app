import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Color Hunting App'**
  String get appTitle;

  /// No description provided for @appbarTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get appbarTarget;

  /// No description provided for @appbarHunting.
  ///
  /// In en, this message translates to:
  /// **'Hunting'**
  String get appbarHunting;

  /// No description provided for @appbarCollection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get appbarCollection;

  /// No description provided for @navTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get navTarget;

  /// No description provided for @navHunting.
  ///
  /// In en, this message translates to:
  /// **'Hunting'**
  String get navHunting;

  /// No description provided for @navCollection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get navCollection;

  /// No description provided for @archiveHeader.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get archiveHeader;

  /// No description provided for @archiveEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No colors collected yet'**
  String get archiveEmptyTitle;

  /// No description provided for @archiveEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find today\'s color and capture your day'**
  String get archiveEmptySubtitle;

  /// No description provided for @archiveStartHunting.
  ///
  /// In en, this message translates to:
  /// **'Start Hunting'**
  String get archiveStartHunting;

  /// No description provided for @fillAllSlots.
  ///
  /// In en, this message translates to:
  /// **'Please fill all grid slots before saving!'**
  String get fillAllSlots;

  /// No description provided for @huntingEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No target color yet'**
  String get huntingEmptyTitle;

  /// No description provided for @huntingEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick today\'s color in the Target tab first'**
  String get huntingEmptySubtitle;

  /// No description provided for @huntingSetTarget.
  ///
  /// In en, this message translates to:
  /// **'Choose Target Color'**
  String get huntingSetTarget;

  /// No description provided for @huntingReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get huntingReset;

  /// No description provided for @huntingRemoveImage.
  ///
  /// In en, this message translates to:
  /// **'Remove Image'**
  String get huntingRemoveImage;

  /// No description provided for @huntingDownloadImage.
  ///
  /// In en, this message translates to:
  /// **'Download Image'**
  String get huntingDownloadImage;

  /// No description provided for @huntingTakeAnother.
  ///
  /// In en, this message translates to:
  /// **'Take Another Photo'**
  String get huntingTakeAnother;

  /// No description provided for @targetTapToPick.
  ///
  /// In en, this message translates to:
  /// **'Tap to\npick color'**
  String get targetTapToPick;

  /// No description provided for @targetPickAgain.
  ///
  /// In en, this message translates to:
  /// **'Pick Again'**
  String get targetPickAgain;

  /// No description provided for @targetStartHunting.
  ///
  /// In en, this message translates to:
  /// **'Start Hunting'**
  String get targetStartHunting;

  /// No description provided for @memoTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Note'**
  String get memoTitle;

  /// No description provided for @memoHint.
  ///
  /// In en, this message translates to:
  /// **'Capture special moments of this day.'**
  String get memoHint;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @huntingSavedArchived.
  ///
  /// In en, this message translates to:
  /// **'Hunting session saved and archived!'**
  String get huntingSavedArchived;

  /// No description provided for @collageSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving collage to gallery...'**
  String get collageSaving;

  /// No description provided for @collageSaved.
  ///
  /// In en, this message translates to:
  /// **'Collage saved to gallery.'**
  String get collageSaved;

  /// No description provided for @collageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create collage.'**
  String get collageFailed;

  /// No description provided for @collageSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save collage: {error}'**
  String collageSaveError(Object error);

  /// No description provided for @collectionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Collection deleted'**
  String get collectionDeleted;

  /// No description provided for @changeTargetTitle.
  ///
  /// In en, this message translates to:
  /// **'Change target color'**
  String get changeTargetTitle;

  /// No description provided for @changeTargetBody.
  ///
  /// In en, this message translates to:
  /// **'A hunt is in progress. Changing the target color will reset all photos.\n\nDo you want to continue?'**
  String get changeTargetBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @targetChanged.
  ///
  /// In en, this message translates to:
  /// **'Target color changed. Start a new hunt.'**
  String get targetChanged;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseGallery;

  /// No description provided for @languageKorean.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get languageKorean;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageJapanese.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get languageJapanese;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @languageSelectedEn.
  ///
  /// In en, this message translates to:
  /// **'English selected'**
  String get languageSelectedEn;

  /// No description provided for @languageSelectedKo.
  ///
  /// In en, this message translates to:
  /// **'한국어 선택됨'**
  String get languageSelectedKo;

  /// No description provided for @languageSelectedJa.
  ///
  /// In en, this message translates to:
  /// **'日本語を選択しました'**
  String get languageSelectedJa;

  /// No description provided for @languageSelectedZh.
  ///
  /// In en, this message translates to:
  /// **'已选择中文'**
  String get languageSelectedZh;

  /// No description provided for @downloadCollageLabel.
  ///
  /// In en, this message translates to:
  /// **'Collage'**
  String get downloadCollageLabel;

  /// No description provided for @downloadCardLabel.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get downloadCardLabel;

  /// No description provided for @chooseMultipleImages.
  ///
  /// In en, this message translates to:
  /// **'Choose Multiple Images'**
  String get chooseMultipleImages;

  /// No description provided for @noCamerasFound.
  ///
  /// In en, this message translates to:
  /// **'No cameras found'**
  String get noCamerasFound;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
