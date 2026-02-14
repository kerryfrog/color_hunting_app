import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'main.dart'; // Import ColorBoard class
import 'archive_detail_screen.dart';

class ArchiveTab extends StatelessWidget {
  final List<ColorBoard> savedColorBoards;
  final Locale currentLocale;
  final Function(ColorBoard) onSaveImagesToGallery; // New callback
  final Function(ColorBoard) onDeleteColorBoard; // Delete callback
  final VoidCallback? onNavigateToTarget; // New callback for navigation

  const ArchiveTab({
    super.key,
    required this.savedColorBoards,
    required this.currentLocale,
    required this.onSaveImagesToGallery,
    required this.onDeleteColorBoard,
    this.onNavigateToTarget,
  });

  // 배경색과 대비되는 텍스트 색상 자동 선택
  Color _getContrastingTextColor(Color backgroundColor) {
    // Calculate relative luminance
    final luminance = backgroundColor.computeLuminance();
    // Return white for dark colors, black for light colors
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  // 수집된 사진 개수를 기반으로 블록 높이 계산
  double _getBlockHeight(ColorBoard board) {
    final photoCount = board.gridImagePaths
        .where((path) => path != null)
        .length;

    // 사진이 많을수록 더 큰 블록
    if (photoCount >= 10) return 240.0;
    if (photoCount >= 7) return 200.0;
    if (photoCount >= 4) return 160.0;
    return 140.0;
  }

  // RGB 값 추출
  String _getRgbString(Color color) {
    return 'RGB ${color.red}, ${color.green}, ${color.blue}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppLocalizations(currentLocale);
    // 종료일 기준 최신순 정렬 (없으면 생성일로 fallback)
    final sortedBoards = List<ColorBoard>.from(savedColorBoards)
      ..sort((a, b) {
        final dateA = a.completedDate ?? a.createdDate ?? DateTime(1970);
        final dateB = b.completedDate ?? b.createdDate ?? DateTime(1970);
        return dateB.compareTo(dateA); // 내림차순 (최신순)
      });

    return Scaffold(
      backgroundColor: Colors.white, // 순백 배경으로 컬러칩 강조
      body: sortedBoards.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Minimalist palette icon with thin lines
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF5F5F7).withOpacity(0.3),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.palette_outlined,
                        size: 60,
                        color: const Color(0xFFCCCCCC).withOpacity(0.5),
                        weight: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Main message
                  Text(
                    l10n.archiveEmptyTitle,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Color(0xFF333333),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  Text(
                    l10n.archiveEmptySubtitle,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w300,
                      fontSize: 14,
                      color: Color(0xFF888888),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // CTA Button
                  OutlinedButton(
                    onPressed: onNavigateToTarget,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF333333),
                      side: const BorderSide(
                        color: Color(0xFF333333),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      l10n.archiveStartHunting,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columnWidth = (width - 1) / 2; // 1px gap

                // 2개 컬럼으로 분리
                final leftColumn = <Widget>[];
                final rightColumn = <Widget>[];

                for (int i = 0; i < sortedBoards.length; i++) {
                  final colorBoard = sortedBoards[i];
                  final hexColor =
                      '#${colorBoard.targetColor.value.toRadixString(16).substring(2).toUpperCase()}';
                  final rgbColor = _getRgbString(colorBoard.targetColor);
                  final textColor = _getContrastingTextColor(
                    colorBoard.targetColor,
                  );

                  // 사진 개수 계산
                  final photoCount = colorBoard.gridImagePaths
                      .where((path) => path != null)
                      .length;

                  // 블록 높이 (세로로 긴 직사각형)
                  final blockHeight = columnWidth * 1.4;

                  // 날짜 포맷팅
                  String dateString = '';
                  if (colorBoard.completedDate != null) {
                    final date = colorBoard.completedDate!;
                    dateString =
                        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
                  }

                  final colorBlock = GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArchiveDetailScreen(
                            colorBoard: colorBoard,
                            locale: currentLocale,
                            huntingDate:
                                colorBoard.completedDate ?? DateTime.now(),
                            memo: colorBoard.memo,
                            onDelete: () => onDeleteColorBoard(colorBoard),
                            onSaveCollage: () =>
                                onSaveImagesToGallery(colorBoard),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: columnWidth,
                      height: blockHeight,
                      decoration: BoxDecoration(
                        color: colorBoard.targetColor, // 타겟 컬러 100% 농도
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 상단: 날짜 (색상 이름 역할)
                            if (dateString.isNotEmpty)
                              Text(
                                dateString,
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                  color: textColor,
                                  letterSpacing: -0.5,
                                  height: 1.2,
                                ),
                              ),

                            // 하단: HEX & RGB
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hexColor,
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w300,
                                    fontSize: 13,
                                    color: textColor.withOpacity(0.9),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  rgbColor,
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w300,
                                    fontSize: 11,
                                    color: textColor.withOpacity(0.7),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  // 교대로 왼쪽/오른쪽 컬럼에 배치
                  if (i % 2 == 0) {
                    leftColumn.add(colorBlock);
                    if (i < sortedBoards.length - 1) {
                      leftColumn.add(const SizedBox(height: 1));
                    }
                  } else {
                    rightColumn.add(colorBlock);
                    if (i < sortedBoards.length - 1) {
                      rightColumn.add(const SizedBox(height: 1));
                    }
                  }
                }

                return SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Column(children: leftColumn)),
                      const SizedBox(width: 1),
                      Expanded(child: Column(children: rightColumn)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
