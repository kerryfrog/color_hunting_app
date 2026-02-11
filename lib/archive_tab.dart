import 'package:flutter/material.dart';
import 'main.dart'; // Import ColorBoard class

class ArchiveTab extends StatelessWidget {
  final List<ColorBoard> savedColorBoards;
  final Function(ColorBoard) onSaveImagesToGallery; // New callback

  const ArchiveTab({
    super.key,
    required this.savedColorBoards,
    required this.onSaveImagesToGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 컬렉션'),
      ),
      body: savedColorBoards.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    '아직 저장된 컬러 보드가 없습니다.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
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
                                  Navigator.pop(context); // Close the bottom sheet
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
                            physics: const NeverScrollableScrollPhysics(), // Disable scrolling of inner grid
                            shrinkWrap: true,
                                                      itemCount: colorBoard.gridImagePaths.length,
                                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                                        crossAxisCount: 3,
                                                        childAspectRatio: 1.0,
                                                        crossAxisSpacing: 2.0,
                                                        mainAxisSpacing: 2.0,
                                                      ),
                                                      itemBuilder: (context, imgIndex) {
                                                        final imagePath = colorBoard.gridImagePaths[imgIndex];
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
                                                        );                            },
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
