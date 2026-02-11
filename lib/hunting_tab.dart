import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';

class HuntingTab extends StatelessWidget {
  final bool isHuntingActive;
  final Color targetColor;
  final List<ImageProvider?> gridImages;
  final Function(int) onTakePicture;
  final VoidCallback onInitializeSession;
  final VoidCallback onSaveSession;
  final VoidCallback onPickMultipleImages; // New callback

  const HuntingTab({
    super.key,
    required this.isHuntingActive,
    required this.targetColor,
    required this.gridImages,
    required this.onTakePicture,
    required this.onInitializeSession,
    required this.onSaveSession,
    required this.onPickMultipleImages,
  });



  @override
  Widget build(BuildContext context) {
    final accentColor = Color(0xFF888888); // Neutral gray accent color
    if (!isHuntingActive) {
      return const Center(
        child: Text(
          '색상을 먼저 선택해주세요',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D)),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        Expanded(
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
                        ? accentColor.withOpacity(0.05)
                        : null,
                    borderRadius: BorderRadius.circular(0),
                    border: Border.all(
                      color: Colors.white,
                      width: 1,
                    ),
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
                            color: accentColor,
                            size: 32,
                            weight: 0.5,
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: OutlinedButton.icon(
            onPressed: onPickMultipleImages,
            icon: Icon(Icons.collections, color: accentColor, size: 22, weight: 0.5),
            label: Text(
              'Choose Multiple Images',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: accentColor, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.white,
              overlayColor: accentColor.withOpacity(0.12),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onInitializeSession,
                  icon: Icon(Icons.refresh, color: accentColor, size: 22, weight: 0.5),
                  label: Text(
                    '초기화',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: accentColor, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.white,
                    overlayColor: accentColor.withOpacity(0.12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSaveSession,
                  icon: Icon(Icons.save_outlined, color: accentColor, size: 22, weight: 0.5),
                  label: Text(
                    'Save',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: accentColor, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.white,
                    overlayColor: accentColor.withOpacity(0.12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
