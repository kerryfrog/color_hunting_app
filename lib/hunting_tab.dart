import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';

class HuntingTab extends StatelessWidget {
  final bool isHuntingActive;
  final Color targetColor;
  final List<ImageProvider?> gridImages;
  final Function(int) onTakePicture;
  final Function(int) onDownloadImage;
  final Function(int) onRemoveImage; // Remove image callback
  final VoidCallback onInitializeSession;
  final VoidCallback onSaveSession;
  final VoidCallback onPickMultipleImages; // New callback
  final VoidCallback onNavigateToTarget;

  const HuntingTab({
    super.key,
    required this.isHuntingActive,
    required this.targetColor,
    required this.gridImages,
    required this.onTakePicture,
    required this.onDownloadImage,
    required this.onRemoveImage,
    required this.onInitializeSession,
    required this.onSaveSession,
    required this.onPickMultipleImages,
    required this.onNavigateToTarget,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accentColor = Color(0xFF888888); // Neutral gray accent color
    if (!isHuntingActive) {
      return Container(
        color: Colors.white,
        child: Stack(
          children: [
            CustomPaint(size: Size.infinite, painter: DottedGridPainter()),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                  Text(
                    l10n.huntingEmptyTitle,
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
                    l10n.huntingEmptySubtitle,
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
                      l10n.huntingSetTarget,
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
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFFFFFFF),
      child: Column(
        children: [
          // Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final safeWidth = constraints.maxWidth > 0
                      ? constraints.maxWidth
                      : 1.0;
                  final safeHeight = constraints.maxHeight > 0
                      ? constraints.maxHeight
                      : 1.0;
                  final itemWidth = safeWidth / 3;
                  final itemHeight = safeHeight / 4;
                  final adaptiveChildAspectRatio = itemWidth / itemHeight;

                  return GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 12,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: adaptiveChildAspectRatio,
                      crossAxisSpacing: 0.0,
                      mainAxisSpacing: 0.0,
                    ),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          if (gridImages[index] != null) {
                            _showImageOptions(context, index);
                          } else {
                            onTakePicture(index);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: gridImages[index] == null
                                ? const Color(0xFFFAFAFA)
                                : null,
                            border: Border.all(color: Colors.white, width: 1),
                            image: gridImages[index] != null
                                ? DecorationImage(
                                    image: gridImages[index]!,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: gridImages[index] == null
                              ? Center(
                                  child: Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.black.withOpacity(0.2),
                                    size: 24,
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // Multiple images button (small icon button near grid)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: onPickMultipleImages,
                icon: Icon(
                  Icons.collections_outlined,
                  color: accentColor,
                  size: 28,
                ),
                tooltip: 'Choose Multiple Images',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ),

          // Bottom buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Row(
              children: [
                // Reset button
                Expanded(
                  child: OutlinedButton(
                    onPressed: onInitializeSession,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF888888),
                      side: const BorderSide(
                        color: Color(0xFFE0E0E0),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      l10n.huntingReset,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Save button
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: onSaveSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: targetColor.withOpacity(0.1),
                      foregroundColor: targetColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      l10n.save,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        letterSpacing: 1.2,
                        color: targetColor.computeLuminance() > 0.5
                            ? targetColor.withOpacity(0.8)
                            : targetColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImageOptions(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFE53935),
                ),
                title: Text(
                  l10n.huntingRemoveImage,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Color(0xFFE53935),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onRemoveImage(index);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.download_outlined,
                  color: Color(0xFF333333),
                ),
                title: Text(
                  l10n.huntingDownloadImage,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Color(0xFF333333),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDownloadImage(index);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: Color(0xFF333333),
                ),
                title: Text(
                  l10n.huntingTakeAnother,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Color(0xFF333333),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onTakePicture(index);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class DottedGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF0F0F0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const double dashWidth = 4;
    const double dashSpace = 4;
    final int gridColumns = 3;
    final int gridRows = 4;

    final double cellWidth = size.width / gridColumns;
    final double cellHeight = size.height / gridRows;

    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridColumns; col++) {
        final double left = col * cellWidth;
        final double top = row * cellHeight;
        final rect = Rect.fromLTWH(left, top, cellWidth, cellHeight);

        // Draw top border
        double startX = rect.left;
        while (startX < rect.right) {
          canvas.drawLine(
            Offset(startX, rect.top),
            Offset(startX + dashWidth, rect.top),
            paint,
          );
          startX += dashWidth + dashSpace;
        }

        // Draw left border
        double startY = rect.top;
        while (startY < rect.bottom) {
          canvas.drawLine(
            Offset(rect.left, startY),
            Offset(rect.left, startY + dashWidth),
            paint,
          );
          startY += dashWidth + dashSpace;
        }

        // Draw right border
        startY = rect.top;
        while (startY < rect.bottom) {
          canvas.drawLine(
            Offset(rect.right, startY),
            Offset(rect.right, startY + dashWidth),
            paint,
          );
          startY += dashWidth + dashSpace;
        }

        // Draw bottom border
        startX = rect.left;
        while (startX < rect.right) {
          canvas.drawLine(
            Offset(startX, rect.bottom),
            Offset(startX + dashWidth, rect.bottom),
            paint,
          );
          startX += dashWidth + dashSpace;
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
