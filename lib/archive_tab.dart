import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

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

  Widget _buildBlurredBlob({
    required double width,
    required double height,
    required List<Color> colors,
    required List<double> stops,
    double sigma = 14,
  }) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(width),
          gradient: RadialGradient(
            center: const Alignment(0, -0.14),
            radius: 1.0,
            colors: colors,
            stops: stops,
          ),
        ),
      ),
    );
  }

  Widget _buildPosterTile({
    required BuildContext context,
    required ColorBoard colorBoard,
    required int order,
  }) {
    final baseColor = colorBoard.targetColor;
    final date = _formatDate(colorBoard);
    final hex = _getHexString(baseColor).toUpperCase();
    final collectionOrderLabel = '${_getOrdinal(order)} COLLECTION'.toUpperCase();
    final dateLabel = date.toUpperCase();
    final coreColor = _tone(
      baseColor,
      saturation: 1.2,
      lightness: 0.6,
      alpha: 1.0,
    );
    final hazeColor = _tone(
      baseColor,
      saturation: 0.72,
      lightness: 1.15,
      alpha: 1.0,
    );
    const textSize = 12.0;
    const titleSize = 13.0;

    return GestureDetector(
      onTap: () => _openDetail(context, colorBoard),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7F3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E2D9), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              Align(
                alignment: const Alignment(0.28, 0),
                child: IgnorePointer(
                  child: SizedBox(
                    width: 216,
                    height: 252,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -64),
                          child: _buildBlurredBlob(
                            width: 170,
                            height: 182,
                            sigma: 18,
                            colors: [
                              coreColor.withValues(alpha: 0.72),
                              hazeColor.withValues(alpha: 0.22),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.62, 1.0],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collectionOrderLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.balthazar(
                                fontWeight: FontWeight.w400,
                                fontSize: titleSize,
                                height: 1.08,
                                color: const Color(0xFF333333),
                                letterSpacing: 0.2,
                                fontFeatures: const [
                                  FontFeature.enable('lnum'),
                                  FontFeature.enable('tnum'),
                                ],
                              ),
                            ),
                    const SizedBox(height: 3),
                    Text(
                      dateLabel,
                              style: GoogleFonts.balthazar(
                                fontWeight: FontWeight.w400,
                                fontSize: textSize,
                                height: 1.08,
                                color: const Color(0xFF777777),
                                letterSpacing: 0.2,
                                fontFeatures: const [
                                  FontFeature.enable('lnum'),
                                  FontFeature.enable('tnum'),
                                ],
                              ),
                            ),
                    const Spacer(),
                    Text(
                      hex,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spectral(
                                fontWeight: FontWeight.w400,
                                fontSize: 11,
                                height: 1.0,
                                color: baseColor,
                                letterSpacing: 0.2,
                                fontFeatures: const [
                                  FontFeature.enable('lnum'),
                                  FontFeature.enable('tnum'),
                                ],
                              ),
                            ),
                  ],
                ),
              ),
            ],
          ),
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
      backgroundColor: const Color(0xFFFCFCFA),
      body: sortedBoards.isEmpty
          ? _buildEmptyState(l10n)
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: sortedBoards.length,
              itemBuilder: (context, index) {
                final board = sortedBoards[index];
                return _buildPosterTile(
                  context: context,
                  colorBoard: board,
                  order: board.collectionNumber,
                );
              },
            ),
    );
  }
}
