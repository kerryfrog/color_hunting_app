import 'package:flutter/material.dart';

class HuntingTab extends StatelessWidget {
  final bool isHuntingActive;
  final Color targetColor;
  final List<ImageProvider?> gridImages;
  final Function(int) onTakePicture;
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
    required this.onInitializeSession,
    required this.onSaveSession,
    required this.onPickMultipleImages,
    required this.onNavigateToTarget,
  });

  @override
  Widget build(BuildContext context) {
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
                  const Icon(
                    Icons.palette_outlined,
                    color: Color(0xFFE0E0E0),
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '아직 타겟 컬러가 없어요',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Target 탭에서 오늘의 색상을 먼저 골라보세요',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w300,
                      fontSize: 14,
                      color: Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(height: 32),
                  OutlinedButton(
                    onPressed: onNavigateToTarget,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF333333),
                      side: const BorderSide(color: Color(0xFF333333)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      '타겟 컬러 정하기',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
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
              child: GridView.builder(
                padding: EdgeInsets.zero,
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 0.0,
                  mainAxisSpacing: 0.0,
                ),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => onTakePicture(index),
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
                    child: const Text(
                      '초기화',
                      style: TextStyle(
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
                      'Save',
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
