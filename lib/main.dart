import 'dart:io';
import 'dart:convert'; // For JSON encoding/decoding
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img; // Import as img to avoid conflicts
import 'package:path_provider/path_provider.dart'; // Import for temporary directory
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'camera_screen.dart';
import 'target_tab.dart';
import 'hunting_tab.dart';
import 'archive_tab.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Hunting App',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF2D2D2D),
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Pretendard',
            color: Color(0xFF2D2D2D),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF2D2D2D)),
          bodyLarge: TextStyle(color: Color(0xFF2D2D2D)),
          titleLarge: TextStyle(color: Color(0xFF2D2D2D)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.transparent, // Will override in widget
          unselectedItemColor: Color(0xFF2D2D2D),
          elevation: 0,
          selectedLabelStyle: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w400,
            fontSize: 11,
          ),
        ),
      ),
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

enum ImageSelectionType { camera, gallerySingle, galleryMultiple }

enum AppLanguage { ko, en, ja, zh }

class ColorBoard {
  final Color targetColor;
  final List<String?> gridImagePaths; // Store paths for serialization
  final String? memo; // User's note about this hunting session
  final DateTime? createdDate; // When hunting started
  final DateTime? completedDate; // When hunting was completed
  final int collectionNumber; // Sequential collection number (1..N)

  ColorBoard({
    required this.targetColor,
    required this.gridImagePaths,
    this.memo,
    this.createdDate,
    this.completedDate,
    required this.collectionNumber,
  });

  ColorBoard copyWith({int? collectionNumber}) {
    return ColorBoard(
      targetColor: targetColor,
      gridImagePaths: gridImagePaths,
      memo: memo,
      createdDate: createdDate,
      completedDate: completedDate,
      collectionNumber: collectionNumber ?? this.collectionNumber,
    );
  }

  // Convert ColorBoard to JSON
  Map<String, dynamic> toJson() => {
    'targetColor': targetColor.value, // Store color as int
    'gridImagePaths': gridImagePaths,
    'memo': memo,
    'createdDate': createdDate?.toIso8601String(),
    'completedDate': completedDate?.toIso8601String(),
    'collectionNumber': collectionNumber,
  };

  // Create ColorBoard from JSON
  factory ColorBoard.fromJson(Map<String, dynamic> json) {
    final targetColorValue = json['targetColor'];
    final createdDateRaw = json['createdDate'];
    final completedDateRaw = json['completedDate'];
    final gridImagePathsRaw = json['gridImagePaths'];
    final collectionNumberRaw = json['collectionNumber'];
    final int collectionNumber = switch (collectionNumberRaw) {
      int value => value,
      String value => int.tryParse(value) ?? 0,
      _ => 0,
    };

    return ColorBoard(
      targetColor: Color(
        targetColorValue is int ? targetColorValue : Colors.transparent.value,
      ),
      gridImagePaths: gridImagePathsRaw is List
          ? gridImagePathsRaw
                .map<String?>((path) => path == null ? null : path.toString())
                .toList()
          : List<String?>.filled(12, null),
      memo: json['memo']?.toString(),
      createdDate: createdDateRaw is String
          ? DateTime.tryParse(createdDateRaw)
          : null,
      completedDate: completedDateRaw is String
          ? DateTime.tryParse(completedDateRaw)
          : null,
      collectionNumber: collectionNumber,
    );
  }
}

class _MemoDialogResult {
  final bool shouldSave;
  final String? memo;

  const _MemoDialogResult({required this.shouldSave, this.memo});
}

class _CollectionNumberNormalizationResult {
  final List<ColorBoard> boards;
  final bool didChange;

  const _CollectionNumberNormalizationResult({
    required this.boards,
    required this.didChange,
  });
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;
  Color _targetColor = Colors.transparent;
  bool _isHuntingActive = false;
  List<ImageProvider?> _gridImages = List.filled(12, null);
  final ImagePicker _picker = ImagePicker();
  List<ColorBoard> _savedColorBoards = []; // Will be loaded from prefs
  DateTime? _huntingStartDate; // Track when hunting started
  AppLanguage _appLanguage = AppLanguage.ko;

  static const String _kSavedColorBoardsKey = 'savedColorBoards';
  static const String _kCurrentHuntingGridKey = 'currentHuntingGridImagePaths';
  static const String _kTargetColorKey = 'targetColor';
  static const String _kIsHuntingActiveKey = 'isHuntingActive';
  static const String _kHuntingStartDateKey = 'huntingStartDate';
  static const String _kAppLanguageKey = 'appLanguage';
  static const String _kIosRewardedAdUnitId =
      'ca-app-pub-2881048601217100/8080604602';
  static const String _kTestRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _kIosExitModalAdUnitId =
      'ca-app-pub-2881048601217100/1963802712';
  static const String _kAndroidExitModalAdUnitId =
      'ca-app-pub-2881048601217100/3332724700';
  static const String _kTestExitModalBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  String get _rewardedAdUnitId =>
      Platform.isIOS ? _kIosRewardedAdUnitId : _kTestRewardedAdUnitId;
  String get _exitModalBannerAdUnitId {
    if (Platform.isIOS) return _kIosExitModalAdUnitId;
    if (Platform.isAndroid) return _kAndroidExitModalAdUnitId;
    return _kTestExitModalBannerAdUnitId;
  }

  Future<void>? _mobileAdsInitializeFuture;
  bool _isHandlingExitRequest = false;
  int? _iosEdgeSwipePointer;
  Offset? _iosEdgeSwipeStart;
  bool _iosEdgeSwipeTriggered = false;

  Locale get _currentLocale => switch (_appLanguage) {
    AppLanguage.ko => const Locale('ko'),
    AppLanguage.en => const Locale('en'),
    AppLanguage.ja => const Locale('ja'),
    AppLanguage.zh => const Locale('zh'),
  };

  AppLocalizations get _currentL10n => lookupAppLocalizations(_currentLocale);

  Future<bool> _ensureMobileAdsInitialized() async {
    _mobileAdsInitializeFuture ??= MobileAds.instance.initialize().then((_) {});
    try {
      await _mobileAdsInitializeFuture;
      return true;
    } catch (e) {
      debugPrint('MobileAds initialize failed: $e');
      _mobileAdsInitializeFuture = null;
      return false;
    }
  }

  Future<void> _ensureCamerasLoaded() async {
    if (cameras.isNotEmpty) return;
    try {
      cameras = await availableCameras();
    } on CameraException catch (e) {
      debugPrint('Error: ${e.code}\nError Message: ${e.description}');
      cameras = [];
    } catch (e) {
      debugPrint('availableCameras failed: $e');
      cameras = [];
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHuntingSession(); // Load both boards and current hunting session on app start
  }

  // Define _widgetOptions here, after methods are defined, or as a getter
  // which references the methods
  List<Widget> get _widgetOptions => <Widget>[
    TargetTab(
      targetColor: _targetColor,
      onColorSelected: _updateTargetColor,
      isHuntingActive: _isHuntingActive,
      onStartHunting: _startHunting,
      onRequestColorPickerAccess: () => _showRewardedAdGate(),
    ),
    HuntingTab(
      isHuntingActive: _isHuntingActive,
      targetColor: _targetColor,
      gridImages: _gridImages,
      onTakePicture: _pickImageForGridCell,
      onDownloadImage: _downloadImageFromGridCell,
      onRemoveImage: _removeImageFromGridCell,
      onInitializeSession: _resetHuntingSession,
      onSaveSession: _saveHuntingSession,
      onPickMultipleImages: _pickMultipleImages,
      onNavigateToTarget: () => _onItemTapped(0),
    ),
    ArchiveTab(
      savedColorBoards: _savedColorBoards,
      currentLocale: _currentLocale,
      onSaveImagesToGallery: _saveColorBoardImagesToGallery,
      onDeleteColorBoard: _deleteColorBoard,
      onNavigateToTarget: () {
        setState(() {
          _selectedIndex = 0; // Navigate to Target tab
        });
      },
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _setAppLanguage(
    AppLanguage language,
    BuildContext l10nContext,
  ) async {
    setState(() {
      _appLanguage = language;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAppLanguageKey, switch (language) {
      AppLanguage.ko => 'ko',
      AppLanguage.en => 'en',
      AppLanguage.ja => 'ja',
      AppLanguage.zh => 'zh',
    });

    if (!mounted) return;
    final l10n = AppLocalizations.of(l10nContext)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          switch (language) {
            AppLanguage.ko => l10n.languageSelectedKo,
            AppLanguage.en => l10n.languageSelectedEn,
            AppLanguage.ja => l10n.languageSelectedJa,
            AppLanguage.zh => l10n.languageSelectedZh,
          },
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showLanguageSheet(BuildContext l10nContext) {
    showModalBottomSheet(
      context: l10nContext,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.languageKorean),
                trailing: _appLanguage == AppLanguage.ko
                    ? const Icon(Icons.check, size: 20)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _setAppLanguage(AppLanguage.ko, l10nContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.languageEnglish),
                trailing: _appLanguage == AppLanguage.en
                    ? const Icon(Icons.check, size: 20)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _setAppLanguage(AppLanguage.en, l10nContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.languageJapanese),
                trailing: _appLanguage == AppLanguage.ja
                    ? const Icon(Icons.check, size: 20)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _setAppLanguage(AppLanguage.ja, l10nContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.languageChinese),
                trailing: _appLanguage == AppLanguage.zh
                    ? const Icon(Icons.check, size: 20)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _setAppLanguage(AppLanguage.zh, l10nContext);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _showRewardedAdGate() async {
    final localeCode = _currentLocale.languageCode;
    final title = switch (localeCode) {
      'en' => 'Unlock Color Picker',
      'ja' => 'カラーピッカーを解除',
      'zh' => '解锁取色器',
      _ => '컬러 피커 잠금 해제',
    };
    final body = switch (localeCode) {
      'en' => 'Watch a short ad to use the color picker.',
      'ja' => 'カラーピッカーを使うには短い広告をご視聴ください。',
      'zh' => '观看一段短广告后即可使用取色器。',
      _ => '컬러 피커를 사용하려면 짧은 광고를 시청해주세요.',
    };
    final cancelText = switch (localeCode) {
      'en' => 'Cancel',
      'ja' => 'キャンセル',
      'zh' => '取消',
      _ => '취소',
    };
    final watchText = switch (localeCode) {
      'en' => 'Watch Ad',
      'ja' => '広告 보기',
      'zh' => '观看广告',
      _ => '광고 보기',
    };
    final doneText = switch (localeCode) {
      'en' => 'Ad completed. Color picker unlocked.',
      'ja' => '広告視聴が完了しました。カラーピッカーが解除されました。',
      'zh' => '广告播放完成，取色器已解锁。',
      _ => '광고 시청이 완료되어 컬러 피커가 열렸습니다.',
    };
    final failedText = switch (localeCode) {
      'en' => 'Ad failed to load. Please try again.',
      'ja' => '広告の読み込みに失敗しました。もう一度お試しください。',
      'zh' => '广告加载失败，请重试。',
      _ => '광고를 불러오지 못했습니다. 다시 시도해주세요.',
    };
    final notRewardedText = switch (localeCode) {
      'en' => 'Reward was not granted. Please watch the full ad.',
      'ja' => '報酬が付与されませんでした。広告を最後までご視聴ください。',
      'zh' => '未获得奖励，请完整观看广告。',
      _ => '보상을 받지 못했습니다. 광고를 끝까지 시청해주세요.',
    };

    final shouldWatch = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          content: Text(
            body,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Color(0xFF444444),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                cancelText,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF333333),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: Text(
                watchText,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldWatch != true || !mounted) {
      return false;
    }

    final bool isAdsReady = await _ensureMobileAdsInitialized();
    if (!isAdsReady) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failedText),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return false;
    }

    final completer = Completer<bool>();
    bool didEarnReward = false;
    bool didFailToLoad = false;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) {
                completer.complete(didEarnReward);
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (!completer.isCompleted) {
                completer.complete(false);
              }
            },
          );

          ad.show(
            onUserEarnedReward: (adWithoutView, rewardItem) {
              didEarnReward = true;
            },
          );
        },
        onAdFailedToLoad: (_) {
          didFailToLoad = true;
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      ),
    );

    final bool unlocked = await completer.future;
    if (!mounted) return unlocked;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            unlocked
                ? doneText
                : (didFailToLoad ? failedText : notRewardedText),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    return unlocked;
  }

  Future<void> _handleExitRequest() async {
    if (_isHandlingExitRequest) return;
    _isHandlingExitRequest = true;
    try {
      final shouldExit = await _showExitConfirmDialog();
      if (shouldExit != true) return;
      await _closeApp();
    } finally {
      _isHandlingExitRequest = false;
    }
  }

  Future<void> _closeApp() async {
    if (!Platform.isIOS) {
      await SystemNavigator.pop();
      return;
    }

    // iOS may ignore SystemNavigator.pop on a root Flutter view.
    try {
      await SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 120));
    exit(0);
  }

  void _resetIosEdgeSwipeTracking() {
    _iosEdgeSwipePointer = null;
    _iosEdgeSwipeStart = null;
    _iosEdgeSwipeTriggered = false;
  }

  void _onIosEdgeSwipePointerDown(PointerDownEvent event) {
    if (!Platform.isIOS) return;
    if (_iosEdgeSwipePointer != null) return;
    if (event.position.dx > 24) return;
    _iosEdgeSwipePointer = event.pointer;
    _iosEdgeSwipeStart = event.position;
    _iosEdgeSwipeTriggered = false;
  }

  void _onIosEdgeSwipePointerMove(PointerMoveEvent event) {
    if (!Platform.isIOS) return;
    if (_iosEdgeSwipePointer != event.pointer) return;
    if (_iosEdgeSwipeTriggered) return;
    final start = _iosEdgeSwipeStart;
    if (start == null) return;

    final delta = event.position - start;
    if (delta.dx > 72 && delta.dy.abs() < 48) {
      final navigator = Navigator.maybeOf(context);
      if ((navigator?.canPop() ?? false) || _isHandlingExitRequest) {
        _resetIosEdgeSwipeTracking();
        return;
      }
      _iosEdgeSwipeTriggered = true;
      _handleExitRequest();
    }
  }

  Future<bool?> _showExitConfirmDialog() async {
    final bool isAdsReady = await _ensureMobileAdsInitialized();
    if (!mounted) return false;

    BannerAd? exitModalBanner;
    final isBannerLoaded = ValueNotifier<bool>(false);
    final isBannerFailed = ValueNotifier<bool>(false);
    bool dialogActive = true;

    if (isAdsReady) {
      exitModalBanner = BannerAd(
        adUnitId: _exitModalBannerAdUnitId,
        size: AdSize.mediumRectangle,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (!dialogActive) return;
            isBannerLoaded.value = true;
            isBannerFailed.value = false;
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            if (!dialogActive) return;
            isBannerFailed.value = true;
          },
        ),
      )..load();

      // Prevent endless spinner in case ad load hangs on some devices/networks.
      Future.delayed(const Duration(seconds: 4), () {
        if (!dialogActive) return;
        if (!isBannerLoaded.value) {
          isBannerFailed.value = true;
        }
      });
    }

    final localeCode = _currentLocale.languageCode;
    final title = switch (localeCode) {
      'en' => 'Exit App',
      'ja' => 'アプリを終了',
      'zh' => '退出应用',
      _ => '앱 종료',
    };
    final cancelText = switch (localeCode) {
      'en' => 'Cancel',
      'ja' => 'キャンセル',
      'zh' => '取消',
      _ => '취소',
    };
    final exitText = switch (localeCode) {
      'en' => 'Exit',
      'ja' => '終了',
      'zh' => '退出',
      _ => '종료',
    };
    final adFailedText = switch (localeCode) {
      'en' => 'Failed to load ad.',
      'ja' => '広告を読み込めませんでした。',
      'zh' => '广告加载失败。',
      _ => '광고를 불러오지 못했습니다.',
    };
    final adUnavailableText = switch (localeCode) {
      'en' => 'Ad unavailable',
      'ja' => '広告を利用できません',
      'zh' => '广告不可用',
      _ => '광고를 사용할 수 없습니다.',
    };

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (exitModalBanner != null)
                ValueListenableBuilder<bool>(
                  valueListenable: isBannerFailed,
                  builder: (context, failed, _) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: isBannerLoaded,
                      builder: (context, loaded, _) {
                        if (loaded) {
                          return SizedBox(
                            width: 300,
                            height: 250,
                            child: AdWidget(ad: exitModalBanner!),
                          );
                        }
                        return Container(
                          width: 300,
                          height: 250,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: failed
                              ? Text(
                                  adFailedText,
                                  style: const TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 12,
                                    color: Color(0xFF888888),
                                  ),
                                )
                              : const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                        );
                      },
                    );
                  },
                )
              else
                Container(
                  width: 300,
                  height: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    adUnavailableText,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      color: Color(0xFF888888),
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                cancelText,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF333333),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: Text(
                exitText,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
    dialogActive = false;
    exitModalBanner?.dispose();
    isBannerLoaded.dispose();
    isBannerFailed.dispose();
    return result;
  }

  Future<void> _loadHuntingSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final String? savedLanguage = prefs.getString(_kAppLanguageKey);
      if (savedLanguage != null) {
        setState(() {
          _appLanguage = switch (savedLanguage) {
            'en' => AppLanguage.en,
            'ja' => AppLanguage.ja,
            'zh' => AppLanguage.zh,
            _ => AppLanguage.ko,
          };
        });
      }

      // Load saved color boards
      final String? savedBoardsJson = prefs.getString(_kSavedColorBoardsKey);
      List<ColorBoard> loadedBoards = [];
      bool shouldPersistBoards = false;

      if (savedBoardsJson != null) {
        final dynamic decoded = jsonDecode(savedBoardsJson);
        final List<dynamic> decodedList = decoded is List ? decoded : [];
        loadedBoards = decodedList
            .whereType<Map<String, dynamic>>()
            .map((item) => ColorBoard.fromJson(item))
            .toList();
        final List<ColorBoard> filteredBoards = loadedBoards
            .where((board) => !_isLegacyDummyBoard(board))
            .toList();
        loadedBoards = filteredBoards;

        if (filteredBoards.length != decodedList.length) {
          shouldPersistBoards = true;
        }
      }

      final normalization = _normalizeCollectionNumbers(loadedBoards);
      loadedBoards = normalization.boards;
      if (normalization.didChange) {
        shouldPersistBoards = true;
      }

      setState(() {
        _savedColorBoards = loadedBoards;
      });
      if (shouldPersistBoards) {
        await _saveColorBoards();
      }

      // Load target color
      final int? savedTargetColorValue = prefs.getInt(_kTargetColorKey);
      final bool savedIsHuntingActive =
          prefs.getBool(_kIsHuntingActiveKey) ?? false;
      final String? savedStartDateString = prefs.getString(
        _kHuntingStartDateKey,
      );
      final DateTime? savedStartDate = savedStartDateString != null
          ? DateTime.tryParse(savedStartDateString)
          : null;

      // Load current hunting grid images
      final List<String>? currentGridImagePaths = prefs.getStringList(
        _kCurrentHuntingGridKey,
      );
      if (currentGridImagePaths != null && currentGridImagePaths.isNotEmpty) {
        final List<ImageProvider?> loadedImages = List.filled(12, null);
        bool hasImages = false;
        for (int i = 0; i < currentGridImagePaths.length; i++) {
          final path = currentGridImagePaths[i];
          if (path.isNotEmpty && await File(path).exists()) {
            loadedImages[i] = FileImage(File(path));
            hasImages = true;
          }
        }
        setState(() {
          _gridImages = loadedImages;
          _isHuntingActive = savedIsHuntingActive && hasImages;
          _huntingStartDate = savedStartDate;
          _targetColor = savedTargetColorValue != null
              ? Color(savedTargetColorValue)
              : Colors.transparent;
        });
      } else {
        // If no saved grid images, ensure hunting session is not active and grid is empty
        setState(() {
          _isHuntingActive = false;
          _gridImages = List.filled(12, null);
          _targetColor = Colors.transparent;
          _huntingStartDate = null;
        });
      }
    } catch (e) {
      debugPrint('Failed to load hunting session, resetting local session: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kSavedColorBoardsKey);
      await prefs.remove(_kCurrentHuntingGridKey);
      await prefs.remove(_kTargetColorKey);
      await prefs.remove(_kIsHuntingActiveKey);
      await prefs.remove(_kHuntingStartDateKey);
      if (!mounted) return;
      setState(() {
        _savedColorBoards = [];
        _isHuntingActive = false;
        _gridImages = List.filled(12, null);
        _targetColor = Colors.transparent;
        _huntingStartDate = null;
      });
    }
  }

  bool _isLegacyDummyBoard(ColorBoard board) {
    const Set<int> legacyDummyColors = {0xFFFF6B6B, 0xFF4ECDC4, 0xFFFFA07A};
    const Set<String> legacyDummyMemos = {
      '데모용 컬러 헌팅',
      '여러 날에 걸친 헌팅',
      '2월 첫 헌팅',
    };

    final bool hasOnlyEmptyImagePaths = board.gridImagePaths.every(
      (path) => path == null || path.isEmpty,
    );

    return legacyDummyColors.contains(board.targetColor.value) &&
        legacyDummyMemos.contains(board.memo) &&
        hasOnlyEmptyImagePaths;
  }

  DateTime _collectionSortDate(ColorBoard board) {
    return board.completedDate ??
        board.createdDate ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  _CollectionNumberNormalizationResult _normalizeCollectionNumbers(
    List<ColorBoard> boards,
  ) {
    final normalizedBoards = List<ColorBoard>.from(boards);
    final indexedBoards = normalizedBoards.asMap().entries.toList()
      ..sort((a, b) {
        final dateCompare = _collectionSortDate(
          a.value,
        ).compareTo(_collectionSortDate(b.value));
        if (dateCompare != 0) return dateCompare;
        return a.key.compareTo(b.key);
      });

    bool didChange = false;
    int collectionNumber = 1;

    for (final entry in indexedBoards) {
      final board = normalizedBoards[entry.key];
      if (board.collectionNumber != collectionNumber) {
        normalizedBoards[entry.key] = board.copyWith(
          collectionNumber: collectionNumber,
        );
        didChange = true;
      }
      collectionNumber++;
    }

    return _CollectionNumberNormalizationResult(
      boards: normalizedBoards,
      didChange: didChange,
    );
  }

  Future<void> _saveColorBoards() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList = _savedColorBoards
        .map((board) => board.toJson())
        .toList();
    await prefs.setString(_kSavedColorBoardsKey, jsonEncode(jsonList));
  }

  Future<void> _saveHuntingGridImages() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> imagePaths = _gridImages.map((imageProvider) {
      if (imageProvider is FileImage) {
        return imageProvider.file.path;
      }
      return ''; // Use an empty string for null images to maintain list length
    }).toList();
    await prefs.setStringList(_kCurrentHuntingGridKey, imagePaths);
  }

  Future<void> _saveHuntingState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTargetColorKey, _targetColor.value);
    await prefs.setBool(_kIsHuntingActiveKey, _isHuntingActive);
    if (_huntingStartDate != null) {
      await prefs.setString(
        _kHuntingStartDateKey,
        _huntingStartDate!.toIso8601String(),
      );
    } else {
      await prefs.remove(_kHuntingStartDateKey);
    }
    await _saveHuntingGridImages();
  }

  void _initHuntingSession() {
    setState(() {
      _isHuntingActive = false;
      _targetColor = Colors.transparent;
      _gridImages = List.filled(12, null);
    });
    _saveHuntingGridImages(); // Persist the empty grid state
  }

  void _resetHuntingSession() {
    final l10n = _currentL10n;
    setState(() {
      _gridImages = List.filled(12, null);
    });
    _saveHuntingState(); // Persist cleared grid while keeping current hunting color/session
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.huntingImagesCleared)));
  }

  // Function to create an image collage from a list of image paths
  Future<File?> _createImageCollage(
    List<String?> imagePaths,
    Color targetColor,
  ) async {
    const int numColumns = 3;
    const int numRows = 4;
    const int imageSize = 300; // Size of each individual image in the collage
    const int padding = 3; // Slight padding between images

    final int collageWidth =
        (imageSize * numColumns) + (padding * (numColumns - 1));
    final int collageHeight = (imageSize * numRows) + (padding * (numRows - 1));

    // Create a new image for the collage with white background
    final img.Image collage = img.Image(
      width: collageWidth,
      height: collageHeight,
    );
    // Fill the background with white
    img.fill(collage, color: img.ColorRgb8(255, 255, 255));

    int currentImageIndex = 0;
    for (int row = 0; row < numRows; row++) {
      for (int col = 0; col < numColumns; col++) {
        if (currentImageIndex < imagePaths.length &&
            imagePaths[currentImageIndex] != null) {
          final String? path = imagePaths[currentImageIndex];
          if (path != null && await File(path).exists()) {
            final File imageFile = File(path);
            final List<int> bytes = await imageFile.readAsBytes();
            img.Image? originalImage = img.decodeImage(
              Uint8List.fromList(bytes),
            ); // Convert List<int> to Uint8List

            if (originalImage != null) {
              // Resize image to fit the grid cell
              originalImage = img.copyResize(
                originalImage,
                width: imageSize,
                height: imageSize,
              );

              final int xOffset = col * (imageSize + padding);
              final int yOffset = row * (imageSize + padding);
              img.compositeImage(
                collage,
                originalImage,
                dstX: xOffset,
                dstY: yOffset,
              );
            }
          }
        }
        currentImageIndex++;
      }
    }

    final directory = await getTemporaryDirectory();
    final String collagePath =
        '${directory.path}/collage_${DateTime.now().millisecondsSinceEpoch}.png';
    final File collageFile = File(collagePath);
    await collageFile.writeAsBytes(img.encodePng(collage));

    return collageFile;
  }

  void _saveHuntingSession() async {
    final l10n = _currentL10n;
    if (_gridImages.any((image) => image == null)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.fillAllSlots)));
      return;
    }

    // Show memo input dialog
    final _MemoDialogResult? memoResult = await _showMemoDialog();
    if (memoResult == null || !memoResult.shouldSave) {
      return;
    }
    final String? memo = memoResult.memo;

    // Convert ImageProvider to file paths for serialization
    final List<String?> imagePaths = _gridImages.map((imageProvider) {
      if (imageProvider is FileImage) {
        return imageProvider.file.path;
      }
      return null;
    }).toList();

    final completedDate = DateTime.now();

    setState(() {
      final updatedBoards = List<ColorBoard>.from(_savedColorBoards)
        ..add(
          ColorBoard(
            targetColor: _targetColor,
            gridImagePaths: imagePaths,
            memo: memo,
            createdDate: _huntingStartDate,
            completedDate: completedDate,
            collectionNumber: 0,
          ),
        );
      _savedColorBoards = _normalizeCollectionNumbers(updatedBoards).boards;
      _isHuntingActive = false;
      _targetColor = Colors.transparent;
      _gridImages = List.filled(12, null);
      _huntingStartDate = null;
      _selectedIndex = 2;
    });
    await _saveColorBoards(); // Persist the updated list
    await _saveHuntingState(); // Persist the empty grid state after archiving
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.huntingSavedArchived)));
  }

  Future<void> _saveColorBoardImagesToGallery(ColorBoard colorBoard) async {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.collageSaving)));

    try {
      final File? collageFile = await _createImageCollage(
        colorBoard.gridImagePaths,
        colorBoard.targetColor,
      );

      if (collageFile != null && await collageFile.exists()) {
        await Gal.putImage(collageFile.path);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.collageSaved)));
        // Clean up the temporary collage file
        await collageFile.delete();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.collageFailed)));
      }
    } catch (e) {
      print(
        'An unexpected error occurred while saving collage to gallery: $e',
      ); // Debugging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.collageSaveError(e.toString()))),
      );
    }
  }

  Future<void> _deleteColorBoard(ColorBoard colorBoard) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      final updatedBoards = List<ColorBoard>.from(_savedColorBoards)
        ..remove(colorBoard);
      _savedColorBoards = _normalizeCollectionNumbers(updatedBoards).boards;
    });
    await _saveColorBoards();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.collectionDeleted,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<_MemoDialogResult?> _showMemoDialog() async {
    final TextEditingController memoController = TextEditingController();
    final l10n = _currentL10n;

    return showDialog<_MemoDialogResult>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Text(
            l10n.memoTitle,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF333333),
            ),
          ),
          content: TextField(
            controller: memoController,
            maxLines: 5,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: l10n.memoHint,
              hintStyle: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w300,
                fontSize: 14,
                color: Color(0xFF999999),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF333333)),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Color(0xFF333333),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                const _MemoDialogResult(shouldSave: true),
              ),
              child: Text(
                l10n.skip,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Color(0xFF888888),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final trimmedMemo = memoController.text.trim();
                Navigator.pop(
                  context,
                  _MemoDialogResult(
                    shouldSave: true,
                    memo: trimmedMemo.isEmpty ? null : trimmedMemo,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF333333),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                l10n.save,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateTargetColor(Color newColor) async {
    // Show warning if hunting is already active
    if (_isHuntingActive) {
      final l10n = AppLocalizations.of(context)!;
      final bool? shouldChange = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              l10n.changeTargetTitle,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              l10n.changeTargetBody,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  l10n.cancel,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    color: Color(0xFF888888),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  l10n.change,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    color: Color(0xFF2D2D2D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (shouldChange != true) {
        return; // User cancelled, don't change color
      }

      // Reset hunting session if user confirmed
      setState(() {
        _targetColor = newColor;
        _gridImages = List.filled(12, null);
        _isHuntingActive = false;
      });
      _saveHuntingState();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.targetChanged)));
    } else {
      // No active hunting, just change the color
      setState(() {
        _targetColor = newColor;
      });
      _saveHuntingState();
    }
  }

  void _startHunting() {
    setState(() {
      _isHuntingActive = true;
      _huntingStartDate = DateTime.now(); // Record start date
      _selectedIndex = 1;
    });
    _saveHuntingState();
  }

  // Save image to permanent app directory
  Future<String?> _saveImagePermanently(String sourcePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'hunting_img_${DateTime.now().millisecondsSinceEpoch}_${sourcePath.split('/').last}';
      final permanentPath = '${directory.path}/$fileName';

      final File sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(permanentPath);
        return permanentPath;
      }
      return null;
    } catch (e) {
      print('Error saving image permanently: $e');
      return null;
    }
  }

  Future<void> _pickImageForGridCell(int index) async {
    final l10n = _currentL10n;
    final ImageSelectionType? selectionType =
        await showModalBottomSheet<ImageSelectionType>(
          context: context,
          builder: (BuildContext context) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: Text(l10n.takePhoto),
                    onTap: () =>
                        Navigator.pop(context, ImageSelectionType.camera),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: Text(l10n.chooseGallery),
                    onTap: () => Navigator.pop(
                      context,
                      ImageSelectionType.gallerySingle,
                    ),
                  ),
                ],
              ),
            );
          },
        );

    if (selectionType == null) return;

    String? imagePath;

    if (selectionType == ImageSelectionType.camera) {
      await _ensureCamerasLoaded();
      if (cameras.isEmpty) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CameraMockScreen(targetColor: _targetColor),
          ),
        );
        return;
      }
      imagePath = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CameraScreen(cameras: cameras, targetColor: _targetColor),
        ),
      );
    } else if (selectionType == ImageSelectionType.gallerySingle) {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      imagePath = pickedFile?.path;
    }

    if (imagePath != null) {
      // Save image to permanent directory
      final String? permanentPath = await _saveImagePermanently(imagePath);
      if (permanentPath != null) {
        setState(() {
          _gridImages[index] = FileImage(File(permanentPath));
        });
        _saveHuntingState(); // Persist the updated grid and hunting state
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save image')));
      }
    }
  }

  void _removeImageFromGridCell(int index) {
    setState(() {
      _gridImages[index] = null;
    });
    _saveHuntingState(); // Persist the updated grid state

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '이미지가 제거되었습니다',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _downloadImageFromGridCell(int index) async {
    final l10n = _currentL10n;
    final imageProvider = _gridImages[index];
    if (imageProvider is! FileImage) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장할 이미지가 없습니다')));
      return;
    }

    try {
      final path = imageProvider.file.path;
      if (!await imageProvider.file.exists()) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('이미지 파일을 찾을 수 없습니다')));
        return;
      }
      await Gal.putImage(path);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미지를 갤러리에 저장했습니다.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.collageSaveError(e.toString()))),
      );
    }
  }

  Future<void> _pickMultipleImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      int currentGridIndex = 0;
      for (final XFile file in pickedFiles) {
        while (currentGridIndex < _gridImages.length &&
            _gridImages[currentGridIndex] != null) {
          currentGridIndex++;
        }
        if (currentGridIndex < _gridImages.length) {
          // Save image to permanent directory
          final String? permanentPath = await _saveImagePermanently(file.path);
          if (permanentPath != null) {
            setState(() {
              _gridImages[currentGridIndex] = FileImage(File(permanentPath));
            });
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No more empty slots to add images!')),
          );
          break;
        }
      }
      _saveHuntingState(); // Persist the updated grid and hunting state after all images are added
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = _currentLocale;

    return Localizations.override(
      context: context,
      locale: locale,
      child: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          final accentColor = const Color(0xFF888888);

          Widget titleWidget;
          Color appBarColor = Colors.white;
          Color appBarForegroundColor = const Color(0xFF2D2D2D);

          switch (_selectedIndex) {
            case 1: // Hunting Tab
              if (_isHuntingActive) {
                appBarColor = _targetColor;
                // 배경색 밝기에 따라 텍스트 색상 자동 결정
                appBarForegroundColor = _targetColor.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white;
              } else {
                appBarColor = Colors.white;
                appBarForegroundColor = const Color(0xFF2D2D2D);
              }
              titleWidget = Text(
                l10n.appbarHunting,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  color: appBarForegroundColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: -0.8,
                ),
              );
              break;
            case 2: // Archive Tab
              titleWidget = Text(
                l10n.appbarCollection,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: -0.8,
                ),
              );
              break;
            default: // Target Tab
              titleWidget = Text(
                l10n.appbarTarget,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: -0.8,
                ),
              );
          }

          return Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _onIosEdgeSwipePointerDown,
            onPointerMove: _onIosEdgeSwipePointerMove,
            onPointerUp: (_) => _resetIosEdgeSwipeTracking(),
            onPointerCancel: (_) => _resetIosEdgeSwipeTracking(),
            child: PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                _handleExitRequest();
              },
              child: Scaffold(
                backgroundColor: Colors.white,
                appBar: AppBar(
                  title: titleWidget,
                  centerTitle: false,
                  backgroundColor: appBarColor,
                  foregroundColor: appBarForegroundColor,
                  elevation: 0,
                  toolbarHeight: 56,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.language),
                      onPressed: () => _showLanguageSheet(context),
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(
                      height: 0.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            (_selectedIndex == 1 && _isHuntingActive)
                                ? appBarForegroundColor.withOpacity(0.1)
                                : const Color(0xFFF0F0F0),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                body: _widgetOptions.elementAt(_selectedIndex),
                bottomNavigationBar: BottomNavigationBar(
                  items: [
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.circle_outlined,
                        color: _selectedIndex == 0
                            ? accentColor
                            : const Color(0xFF2D2D2D),
                        size: 28,
                        weight: 0.5,
                      ),
                      label: l10n.navTarget,
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.grid_3x3,
                        color: _selectedIndex == 1
                            ? accentColor
                            : const Color(0xFF2D2D2D),
                        size: 28,
                        weight: 0.5,
                      ),
                      label: l10n.navHunting,
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.photo_library_outlined,
                        color: _selectedIndex == 2
                            ? accentColor
                            : const Color(0xFF2D2D2D),
                        size: 28,
                        weight: 0.5,
                      ),
                      label: l10n.navCollection,
                    ),
                  ],
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                  selectedItemColor: accentColor,
                  unselectedItemColor: const Color(0xFF2D2D2D),
                  showSelectedLabels: true,
                  showUnselectedLabels: true,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
