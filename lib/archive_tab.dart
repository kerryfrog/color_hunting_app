import 'package:flutter/material.dart';
import 'dart:io'; // Add this import
import 'main.dart'; // Import ColorBoard class

class ArchiveTab extends StatelessWidget {
  final List<ColorBoard> savedColorBoards;
  final Function(ColorBoard) onSaveImagesToGallery; // New callback
  final VoidCallback? onNavigateToTarget; // New callback for navigation

  const ArchiveTab({
    super.key,
    required this.savedColorBoards,
    required this.onSaveImagesToGallery,
    this.onNavigateToTarget,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // Pure white background
      body: savedColorBoards.isEmpty
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
          : GridView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: savedColorBoards.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Display 2 boards per row
                childAspectRatio: 0.8, // Adjust as needed for aspect ratio
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemBuilder: (context, index) {
                final colorBoard = savedColorBoards[index];
                return GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ListTile(
                                leading: const Icon(Icons.download),
                                title: const Text('갤러리에 저장'),
                                onTap: () {
                                  Navigator.pop(
                                    context,
                                  ); // Close the bottom sheet
                                  onSaveImagesToGallery(colorBoard);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Target Color Display
                        Container(
                          height: 40,
                          color: colorBoard.targetColor,
                          child: Center(
                            child: Text(
                              '#${colorBoard.targetColor.value.toRadixString(16).substring(2).toUpperCase()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Image Grid Preview
                        Expanded(
                          child: GridView.builder(
                            physics:
                                const NeverScrollableScrollPhysics(), // Disable scrolling of inner grid
                            shrinkWrap: true,
                            itemCount: colorBoard.gridImagePaths.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 1.0,
                                  crossAxisSpacing: 2.0,
                                  mainAxisSpacing: 2.0,
                                ),
                            itemBuilder: (context, imgIndex) {
                              final imagePath =
                                  colorBoard.gridImagePaths[imgIndex];
                              return Container(
                                decoration: BoxDecoration(
                                  color: imagePath == null
                                      ? Colors.grey.withOpacity(0.2)
                                      : null,
                                  image: imagePath != null
                                      ? DecorationImage(
                                          image: FileImage(File(imagePath)),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
