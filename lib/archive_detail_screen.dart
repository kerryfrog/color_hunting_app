import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'l10n/app_localizations.dart';
import 'main.dart';

class ArchiveDetailScreen extends StatefulWidget {
  final ColorBoard colorBoard;
  final Locale locale;
  final DateTime huntingDate;
  final String? memo;
  final VoidCallback? onDelete;
  final VoidCallback? onSaveCollage;

  const ArchiveDetailScreen({
    super.key,
    required this.colorBoard,
    required this.locale,
    required this.huntingDate,
    this.memo,
    this.onDelete,
    this.onSaveCollage,
  });

  @override
  State<ArchiveDetailScreen> createState() => _ArchiveDetailScreenState();
}

class _ArchiveDetailScreenState extends State<ArchiveDetailScreen> {
  final GlobalKey _cardKey = GlobalKey();
  late final AppLocalizations _l10n = lookupAppLocalizations(widget.locale);
  late final List<ImageProvider?> _gridImageProviders;
  Future<void>? _precacheFuture;
  bool _didInitImageCache = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitImageCache) return;
    _didInitImageCache = true;
    _gridImageProviders = widget.colorBoard.gridImagePaths.map((path) {
      if (path == null || path.isEmpty) return null;
      final file = File(path);
      if (!file.existsSync()) return null;
      return FileImage(file);
    }).toList(growable: false);
    _precacheFuture = _precacheGridImages();
  }

  Future<void> _precacheGridImages() async {
    final futures = <Future<void>>[];
    for (final provider in _gridImageProviders) {
      if (provider == null) continue;
      futures.add(
        precacheImage(provider, context).catchError((_) {
          return;
        }),
      );
    }
    await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      locale: widget.locale,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCFCFA),
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),

                      RepaintBoundary(
                        key: _cardKey,
                        child: _buildCollageGrid(context),
                      ),

                      if (widget.memo != null && widget.memo!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildMemoSection(context),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              _buildBottomActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFFCFCFA)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTopIconButton(
              onPressed: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(0xFF333333),
              ),
            ),
            _buildTopIconButton(
              onPressed: () => _showDeleteDialog(context),
              child: SvgPicture.asset(
                'assets/images/trash-can.svg',
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF333333),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopIconButton({
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return Material(
      color: const Color(0xFFF8F7F3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E2D9), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Center(child: child),
        ),
      ),
    );
  }

  Color _tone(
    Color color, {
    double saturation = 1.0,
    double lightness = 1.0,
    double alpha = 1.0,
  }) {
    final hsl = HSLColor.fromColor(color);
    final tuned = hsl
        .withSaturation((hsl.saturation * saturation).clamp(0.05, 1.0))
        .withLightness((hsl.lightness * lightness).clamp(0.05, 0.92))
        .toColor();
    return tuned.withValues(alpha: alpha);
  }

  Widget _buildTopLeftBlurAccent({
    required Color baseColor,
  }) {
    final core = _tone(baseColor, saturation: 1.16, lightness: 0.66, alpha: 1.0);
    final haze = _tone(baseColor, saturation: 0.74, lightness: 1.12, alpha: 1.0);

    return Positioned(
      left: -34,
      top: -46,
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 192,
            height: 176,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(200),
              gradient: RadialGradient(
                center: const Alignment(-0.24, -0.24),
                radius: 1.0,
                colors: [
                  core.withValues(alpha: 0.74),
                  haze.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.62, 1.0],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomRightBlurAccent({
    required Color baseColor,
  }) {
    final core = _tone(baseColor, saturation: 1.08, lightness: 0.7, alpha: 1.0);
    final haze = _tone(baseColor, saturation: 0.7, lightness: 1.1, alpha: 1.0);

    return Positioned(
      right: -38,
      bottom: -52,
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 178,
            height: 164,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(190),
              gradient: RadialGradient(
                center: const Alignment(0.28, 0.28),
                radius: 1.0,
                colors: [
                  core.withValues(alpha: 0.56),
                  haze.withValues(alpha: 0.16),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.58, 1.0],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getOrdinal(int number) {
    final mod100 = number % 100;
    if (mod100 >= 11 && mod100 <= 13) {
      return '${number}th';
    }
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }

  String get _shareLabel => switch (widget.locale.languageCode) {
    'ko' => '공유',
    'ja' => '共有',
    'zh' => '分享',
    _ => 'Share',
  };

  Widget _buildCollageGrid(BuildContext context) {
    final baseColor = widget.colorBoard.targetColor;
    final dateString = DateFormat('yyyy.MM.dd').format(widget.huntingDate);
    final hexColor =
        '#${baseColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    final collectionLabel =
        '${_getOrdinal(widget.colorBoard.collectionNumber).toUpperCase()} COLLECTION';
    const titleColor = Color(0xFF2F2F2F);
    const subtitleColor = Color(0xFF4A4A4A);
    final datePillBackground = Colors.white.withValues(alpha: 0.44);
    const datePillBorder = Color(0xFFE6E3D9);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E2D9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          children: [
            _buildTopLeftBlurAccent(baseColor: baseColor),
            _buildBottomRightBlurAccent(baseColor: baseColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              collectionLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.balthazar(
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                height: 1.08,
                                color: subtitleColor,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hexColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spectral(
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                                height: 1.0,
                                color: titleColor,
                                letterSpacing: 0.4,
                                fontFeatures: const [
                                  FontFeature.enable('lnum'),
                                  FontFeature.enable('tnum'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: datePillBackground,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: datePillBorder,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          dateString,
                          style: GoogleFonts.lora(
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: subtitleColor,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F5F0),
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                        color: const Color(0xFFE3E0D6),
                        width: 1,
                      ),
                    ),
                    child: FutureBuilder<void>(
                      future: _precacheFuture,
                      builder: (context, snapshot) {
                        final ready =
                            _precacheFuture == null ||
                            snapshot.connectionState == ConnectionState.done ||
                            snapshot.hasError;
                        return _buildImageGrid(context, ready: ready);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTile({
    required Widget child,
    VoidCallback? onTap,
  }) {
    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }

  Widget _buildImageGrid(BuildContext context, {required bool ready}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final imagePath = widget.colorBoard.gridImagePaths[index];
        final imageProvider = index < _gridImageProviders.length
            ? _gridImageProviders[index]
            : null;

        if (imageProvider == null) {
          return _buildImageTile(
            child: Container(
              color: const Color(0xFFECEAE3),
              child: Center(
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  color: const Color(0xFFBBB8AF).withValues(alpha: 0.9),
                  size: 28,
                ),
              ),
            ),
          );
        }

        if (!ready) {
          return _buildImageTile(
            child: Container(color: const Color(0xFFE5E3DC)),
          );
        }

        return _buildImageTile(
          onTap: imagePath == null
              ? null
              : () => _showImageFullScreen(context, imagePath),
          child: Image(
            image: imageProvider,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          ),
        );
      },
    );
  }

  Widget _buildMemoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _l10n.memoTitle,
          style: GoogleFonts.balthazar(
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: const Color(0xFF444444),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F7F3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E2D9), width: 1),
          ),
          child: Text(
            widget.memo!,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Color(0xFF3A3A3A),
              height: 1.55,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    bool emphasize = false,
  }) {
    final accent = widget.colorBoard.targetColor;
    final foreground = emphasize ? const Color(0xFF2F2F2F) : const Color(0xFF3A3A3A);
    final background = emphasize
        ? accent.withValues(alpha: 0.16)
        : const Color(0xFFF8F7F3);
    final borderColor = emphasize
        ? accent.withValues(alpha: 0.38)
        : const Color(0xFFE5E2D9);

    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: foreground,
        backgroundColor: background,
        side: BorderSide(color: borderColor, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      ),
      icon: Icon(icon, size: 18, color: foreground),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w500,
          fontSize: 14,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFA).withValues(alpha: 0.94),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE5E2D9).withValues(alpha: 0.7),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(
              onPressed: () => _shareToInstagram(context),
              icon: Icons.share_outlined,
              label: _shareLabel,
              emphasize: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  onPressed: () => _saveCollage(context),
                  icon: Icons.download_outlined,
                  label: _l10n.downloadCollageLabel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  onPressed: () => _saveCardAsImage(context),
                  icon: Icons.download_outlined,
                  label: _l10n.downloadCardLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '컬렉션 삭제',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF333333),
            ),
          ),
          content: const Text(
            '이 컬렉션을 삭제하시겠습니까?\n삭제된 컬렉션은 복구할 수 없습니다.',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                '취소',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
                Navigator.pop(context); // Close detail screen
                widget.onDelete?.call(); // Call delete callback
              },
              child: const Text(
                '삭제',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFFE53935),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showImageFullScreen(BuildContext context, String imagePath) {
    // 모든 이미지 경로를 가져오기 (존재하는 파일만)
    final List<String> validImagePaths = widget.colorBoard.gridImagePaths
        .whereType<String>()
        .where((path) => path.isNotEmpty && File(path).existsSync())
        .toList();

    if (validImagePaths.isEmpty) return;

    // 선택된 이미지의 인덱스 찾기
    final int initialIndex = validImagePaths.indexOf(imagePath);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ImageGalleryViewer(
          imagePaths: validImagePaths,
          initialIndex: initialIndex >= 0 ? initialIndex : 0,
        ),
      ),
    );
  }

  void _saveCollage(BuildContext context) {
    // 실제 콜라주 저장 로직 호출
    widget.onSaveCollage?.call();
  }

  Future<void> _saveCardAsImage(BuildContext context) async {
    try {
      // RepaintBoundary로 감싼 위젯을 이미지로 변환
      RenderRepaintBoundary boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // 이미지 생성 (2배 해상도)
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) return;

      // 임시 파일로 저장
      final buffer = byteData.buffer.asUint8List();
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/card_$timestamp.png';
      final file = File(filePath);
      await file.writeAsBytes(buffer);

      // 갤러리에 저장
      await Gal.putImage(filePath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '카드가 갤러리에 저장되었습니다',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFF333333),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '저장 실패: $e',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _shareToInstagram(BuildContext context) async {
    try {
      // RepaintBoundary로 감싼 위젯을 이미지로 변환
      RenderRepaintBoundary boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // 이미지 생성 (2배 해상도)
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) return;

      // 임시 파일로 저장
      final buffer = byteData.buffer.asUint8List();
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/card_share_$timestamp.png';
      final file = File(filePath);
      await file.writeAsBytes(buffer);

      // 공유
      final dateString = DateFormat('yyyy.MM.dd').format(widget.huntingDate);
      await Share.shareXFiles([
        XFile(filePath),
      ], text: 'Color Hunting - $dateString');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '공유 실패: $e',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}

// 이미지 갤러리 뷰어 위젯
class _ImageGalleryViewer extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;

  const _ImageGalleryViewer({
    required this.imagePaths,
    required this.initialIndex,
  });

  @override
  State<_ImageGalleryViewer> createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<_ImageGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.imagePaths.length}',
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.imagePaths.length,
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(
                File(widget.imagePaths[index]),
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
