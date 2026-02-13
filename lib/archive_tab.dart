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
      backgroundColor: const Color(0xFFF8F9FA), // 아주 연한 회색 배경
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
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    itemCount: sortedBoards.length,
                    itemBuilder: (context, index) {
                      final colorBoard = sortedBoards[index];
                      final hexColor =
                          '#${colorBoard.targetColor.value.toRadixString(16).substring(2).toUpperCase()}';

                      // Format date range
                      String dateString = '';
                      if (colorBoard.createdDate != null &&
                          colorBoard.completedDate != null) {
                        final startDate = colorBoard.createdDate!;
                        final endDate = colorBoard.completedDate!;

                        // Check if same day
                        if (startDate.year == endDate.year &&
                            startDate.month == endDate.month &&
                            startDate.day == endDate.day) {
                          // Same day - show only once
                          dateString =
                              '${startDate.year}. ${startDate.month.toString().padLeft(2, '0')}. ${startDate.day.toString().padLeft(2, '0')}';
                        } else {
                          // Different days - show range
                          dateString =
                              '${startDate.year}. ${startDate.month.toString().padLeft(2, '0')}. ${startDate.day.toString().padLeft(2, '0')} ~ ${endDate.year}. ${endDate.month.toString().padLeft(2, '0')}. ${endDate.day.toString().padLeft(2, '0')}';
                        }
                      } else if (colorBoard.completedDate != null) {
                        dateString =
                            '${colorBoard.completedDate!.year}. ${colorBoard.completedDate!.month.toString().padLeft(2, '0')}. ${colorBoard.completedDate!.day.toString().padLeft(2, '0')}';
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ArchiveDetailScreen(
                                  colorBoard: colorBoard,
                                  locale: currentLocale,
                                  huntingDate:
                                      colorBoard.completedDate ??
                                      DateTime.now(),
                                  memo: colorBoard.memo,
                                  onDelete: () =>
                                      onDeleteColorBoard(colorBoard),
                                  onSaveCollage: () =>
                                      onSaveImagesToGallery(colorBoard),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF), // 완전한 화이트
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  // 왼쪽 1/3 - 색상 영역
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: colorBoard.targetColor,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          bottomLeft: Radius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 오른쪽 2/3 - 텍스트 영역 (왼쪽 정렬)
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        top: 16,
                                        bottom: 16,
                                        right: 16,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // 날짜 (Primary)
                                          Text(
                                            dateString,
                                            style: const TextStyle(
                                              fontFamily: 'Pretendard',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: Color(0xFF333333),
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          // HEX 코드 (Secondary)
                                          Text(
                                            hexColor,
                                            style: const TextStyle(
                                              fontFamily: 'Pretendard',
                                              fontWeight: FontWeight.w300,
                                              fontSize: 12,
                                              color: Color(0xFF999999),
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
