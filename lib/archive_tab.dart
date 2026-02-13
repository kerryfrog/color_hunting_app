import 'package:flutter/material.dart';
import 'main.dart'; // Import ColorBoard class
import 'archive_detail_screen.dart';

class ArchiveTab extends StatelessWidget {
  final List<ColorBoard> savedColorBoards;
  final Function(ColorBoard) onSaveImagesToGallery; // New callback
  final Function(ColorBoard) onDeleteColorBoard; // Delete callback
  final VoidCallback? onNavigateToTarget; // New callback for navigation

  const ArchiveTab({
    super.key,
    required this.savedColorBoards,
    required this.onSaveImagesToGallery,
    required this.onDeleteColorBoard,
    this.onNavigateToTarget,
  });

  @override
  Widget build(BuildContext context) {
    // 가장 최근에 추가된 순서대로 정렬 (completedDate 기준 내림차순)
    final sortedBoards = List<ColorBoard>.from(savedColorBoards)
      ..sort((a, b) {
        final dateA = a.completedDate ?? DateTime(1970);
        final dateB = b.completedDate ?? DateTime(1970);
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
                  const Text(
                    '아직 수집된 컬러가 없네요',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Color(0xFF333333),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  const Text(
                    '오늘의 색을 찾아 일상을 기록해보세요',
                    style: TextStyle(
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
                    child: const Text(
                      '사냥 시작하기',
                      style: TextStyle(
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
                // 상단 헤더
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Text(
                    '나의 컬렉션',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      color: Color(0xFF333333),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                // 리스트
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
                      final dateString = colorBoard.completedDate != null
                          ? '${colorBoard.completedDate!.year}. ${colorBoard.completedDate!.month.toString().padLeft(2, '0')}. ${colorBoard.completedDate!.day.toString().padLeft(2, '0')}'
                          : '';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ArchiveDetailScreen(
                                  colorBoard: colorBoard,
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
                                  // 왼쪽 절반 - 색상 영역
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

                                  // 오른쪽 절반 - 텍스트 영역 (오른쪽 정렬)
                                  Expanded(
                                    flex: 1,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 20,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
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
