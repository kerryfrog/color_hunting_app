import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      locale: widget.locale,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // 상단바
              _buildAppBar(context),

              // 스크롤 가능한 메인 콘텐츠
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),

                      // 메인 콜라주 (카드 전체 캡처를 위한 RepaintBoundary)
                      RepaintBoundary(
                        key: _cardKey,
                        child: _buildCollageGrid(context),
                      ),

                      // 메모 섹션 (메모가 있을 때만 표시)
                      if (widget.memo != null && widget.memo!.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildMemoSection(context),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // 하단 버튼 영역
              _buildBottomActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 뒤로가기 버튼
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              color: const Color(0xFF333333),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),

            // 삭제 버튼
            IconButton(
              onPressed: () => _showDeleteDialog(context),
              icon: SvgPicture.asset(
                'assets/images/trash-can.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF333333),
                  BlendMode.srcIn,
                ),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollageGrid(BuildContext context) {
    final dateString = DateFormat('yyyy.MM.dd').format(widget.huntingDate);
    final hexColor =
        '#${widget.colorBoard.targetColor.value.toRadixString(16).substring(2).toUpperCase()}';

    // 틴팅된 배경색
    final cardBackgroundColor = Color.lerp(
      Colors.white,
      widget.colorBoard.targetColor,
      0.07,
    )!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardBackgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 색상 알약 + 날짜
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: widget.colorBoard.targetColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hexColor,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color:
                        widget.colorBoard.targetColor.computeLuminance() > 0.5
                        ? const Color(0xFF333333)
                        : Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Text(
                dateString,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w300,
                  fontSize: 13,
                  color: Color(0xFF999999),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 콜라주 그리드
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.0,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final imagePath = widget.colorBoard.gridImagePaths[index];

              return GestureDetector(
                onTap: () {
                  if (imagePath != null) {
                    _showImageFullScreen(context, imagePath);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: imagePath == null
                        ? Colors.grey.withOpacity(0.15)
                        : null,
                    image: imagePath != null
                        ? DecorationImage(
                            image: FileImage(File(imagePath)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imagePath == null
                      ? Center(
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Colors.grey.withOpacity(0.3),
                            size: 32,
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMemoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 타이틀
        Text(
          _l10n.memoTitle,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF333333),
            letterSpacing: -0.3,
          ),
        ),

        const SizedBox(height: 12),

        // 메모 박스
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            widget.memo!,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w300,
              fontSize: 14,
              color: Color(0xFF333333),
              height: 1.6,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          // 공유 아이콘 버튼
          OutlinedButton(
            onPressed: () {
              _shareToInstagram(context);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF333333),
              side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            child: const Icon(
              Icons.share_outlined,
              size: 20,
              color: Color(0xFF333333),
            ),
          ),

          const SizedBox(width: 12),

          // 콜라주만 저장 버튼
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                _saveCollage(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF333333),
                side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(
                Icons.download_outlined,
                size: 18,
                color: Color(0xFF333333),
              ),
              label: Text(
                _l10n.downloadCollageLabel,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: Color(0xFF333333),
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 카드 전체 저장 버튼
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                _saveCardAsImage(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF333333),
                side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(
                Icons.download_outlined,
                size: 18,
                color: Color(0xFF333333),
              ),
              label: Text(
                _l10n.downloadCardLabel,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: Color(0xFF333333),
                  letterSpacing: -0.2,
                ),
              ),
            ),
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
    // 모든 이미지 경로를 가져오기 (null이 아닌 것만)
    final List<String> validImagePaths = widget.colorBoard.gridImagePaths
        .whereType<String>()
        .toList();

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
