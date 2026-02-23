import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'archive_detail_screen.dart';
import 'l10n/app_localizations.dart';
import 'main.dart';

class ArchiveTab extends StatelessWidget {
  final List<ColorBoard> savedColorBoards;
  final Locale currentLocale;
  final Function(ColorBoard) onSaveImagesToGallery;
  final Function(ColorBoard) onDeleteColorBoard;
  final VoidCallback? onNavigateToTarget;

  const ArchiveTab({
    super.key,
    required this.savedColorBoards,
    required this.currentLocale,
    required this.onSaveImagesToGallery,
    required this.onDeleteColorBoard,
    this.onNavigateToTarget,
  });

  Color _getContrastingTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  String _getHexString(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  String _formatDate(ColorBoard colorBoard) {
    final date = colorBoard.completedDate ?? colorBoard.createdDate;
    if (date == null) return '';
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
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

  Color _getInnerSwatchColor(Color color) {
    final luminance = color.computeLuminance();
    return Color.lerp(color, Colors.white, luminance > 0.5 ? 0.35 : 0.22)!;
  }

  void _openDetail(BuildContext context, ColorBoard colorBoard) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArchiveDetailScreen(
          colorBoard: colorBoard,
          locale: currentLocale,
          huntingDate: colorBoard.completedDate ?? DateTime.now(),
          memo: colorBoard.memo,
          onDelete: () => onDeleteColorBoard(colorBoard),
          onSaveCollage: () => onSaveImagesToGallery(colorBoard),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF5F5F7).withValues(alpha: 0.3),
            ),
            child: Center(
              child: Icon(
                Icons.palette_outlined,
                size: 60,
                color: const Color(0xFFCCCCCC).withValues(alpha: 0.5),
                weight: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
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
          OutlinedButton(
            onPressed: onNavigateToTarget,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF333333),
              side: const BorderSide(color: Color(0xFF333333), width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
    );
  }

  Widget _buildPosterTile({
    required BuildContext context,
    required ColorBoard colorBoard,
    required int order,
    required bool isTallTile,
    required double width,
    required double height,
  }) {
    final baseColor = colorBoard.targetColor;
    final textColor = _getContrastingTextColor(baseColor);
    final innerSwatch = _getInnerSwatchColor(baseColor);
    final date = _formatDate(colorBoard);
    final hex = _getHexString(baseColor).toUpperCase();
    final collectionOrderLabel = '${_getOrdinal(order)} COLLECTION'.toUpperCase();
    final dateLabel = date.toUpperCase();
    final swatchSize = (width * 0.31).clamp(62.0, 96.0);
    const textSize = 12.0;

    return GestureDetector(
      onTap: () => _openDetail(context, colorBoard),
      child: Container(
        width: width,
        height: height,
        color: baseColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(flex: 8),
            Container(
              width: swatchSize,
              height: swatchSize,
              decoration: BoxDecoration(
                color: innerSwatch,
                border: Border.all(
                  color: textColor.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
            SizedBox(height: isTallTile ? 8 : 16),
            Text(
              hex,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.balthazar(
                fontWeight: FontWeight.w400,
                fontSize: textSize,
                height: 1.08,
                color: textColor,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              collectionOrderLabel,
              style: GoogleFonts.balthazar(
                fontWeight: FontWeight.w400,
                fontSize: textSize,
                height: 1.08,
                color: textColor.withValues(alpha: 0.92),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              dateLabel,
              style: GoogleFonts.balthazar(
                fontWeight: FontWeight.w400,
                fontSize: textSize,
                height: 1.08,
                color: textColor.withValues(alpha: 0.85),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppLocalizations(currentLocale);
    final sortedBoards = List<ColorBoard>.from(savedColorBoards)
      ..sort((a, b) {
        final dateA = a.completedDate ?? a.createdDate ?? DateTime(1970);
        final dateB = b.completedDate ?? b.createdDate ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });

    return Scaffold(
      backgroundColor: Colors.white,
      body: sortedBoards.isEmpty
          ? _buildEmptyState(l10n)
          : LayoutBuilder(
              builder: (context, constraints) {
                final columnWidth = constraints.maxWidth / 2;
                const bigRatio = 1.5;
                const smallRatio = 1.0;

                final leftColumn = <Widget>[];
                final rightColumn = <Widget>[];

                for (int i = 0; i < sortedBoards.length; i++) {
                  final board = sortedBoards[i];
                  final group = i ~/ 5;
                  final positionInGroup = i % 5;
                  final isReversedGroup = group.isOdd;

                  final placeLeft = isReversedGroup
                      ? (positionInGroup == 0 ||
                            positionInGroup == 2 ||
                            positionInGroup == 4)
                      : (positionInGroup == 0 || positionInGroup == 3);

                  final leftRatio = isReversedGroup ? smallRatio : bigRatio;
                  final rightRatio = isReversedGroup ? bigRatio : smallRatio;
                  final ratio = placeLeft ? leftRatio : rightRatio;

                  if (placeLeft) {
                    leftColumn.add(
                      _buildPosterTile(
                        context: context,
                        colorBoard: board,
                        order: board.collectionNumber,
                        isTallTile: ratio > 1.2,
                        width: columnWidth,
                        height: columnWidth * ratio,
                      ),
                    );
                  } else {
                    rightColumn.add(
                      _buildPosterTile(
                        context: context,
                        colorBoard: board,
                        order: board.collectionNumber,
                        isTallTile: ratio > 1.2,
                        width: columnWidth,
                        height: columnWidth * ratio,
                      ),
                    );
                  }
                }

                return SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: columnWidth,
                        child: Column(children: leftColumn),
                      ),
                      SizedBox(
                        width: columnWidth,
                        child: Column(children: rightColumn),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
