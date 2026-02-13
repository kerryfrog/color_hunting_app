import 'dart:io';
import 'dart:convert'; // For JSON encoding/decoding
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img; // Import as img to avoid conflicts
import 'package:path_provider/path_provider.dart'; // Import for temporary directory
import 'dart:typed_data'; // Import for Uint8List

import 'camera_screen.dart';
import 'target_tab.dart';
import 'hunting_tab.dart';
import 'archive_tab.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: ${e.code}\nError Message: ${e.description}');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Hunting App',
      theme: ThemeData(
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF2D2D2D),
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Pretendard',
            color: Color(0xFF2D2D2D),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF2D2D2D)),
          bodyLarge: TextStyle(color: Color(0xFF2D2D2D)),
          titleLarge: TextStyle(color: Color(0xFF2D2D2D)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.transparent, // Will override in widget
          unselectedItemColor: Color(0xFF2D2D2D),
          elevation: 0,
        ),
      ),
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

enum ImageSelectionType { camera, gallerySingle, galleryMultiple }

class ColorBoard {
  final Color targetColor;
  final List<String?> gridImagePaths; // Store paths for serialization
  final String? memo; // User's note about this hunting session
  final DateTime? createdDate; // When hunting started
  final DateTime? completedDate; // When hunting was completed

  ColorBoard({
    required this.targetColor,
    required this.gridImagePaths,
    this.memo,
    this.createdDate,
    this.completedDate,
  });

  // Convert ColorBoard to JSON
  Map<String, dynamic> toJson() => {
    'targetColor': targetColor.value, // Store color as int
    'gridImagePaths': gridImagePaths,
    'memo': memo,
    'createdDate': createdDate?.toIso8601String(),
    'completedDate': completedDate?.toIso8601String(),
  };

  // Create ColorBoard from JSON
  factory ColorBoard.fromJson(Map<String, dynamic> json) {
    return ColorBoard(
      targetColor: Color(json['targetColor']),
      gridImagePaths: List<String?>.from(json['gridImagePaths']),
      memo: json['memo'],
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'])
          : null,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'])
          : null,
    );
  }
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;
  Color _targetColor = Colors.transparent;
  bool _isHuntingActive = false;
  List<ImageProvider?> _gridImages = List.filled(12, null);
  final ImagePicker _picker = ImagePicker();
  List<ColorBoard> _savedColorBoards = []; // Will be loaded from prefs
  DateTime? _huntingStartDate; // Track when hunting started

  static const String _kSavedColorBoardsKey = 'savedColorBoards';
  static const String _kCurrentHuntingGridKey = 'currentHuntingGridImagePaths';
  static const String _kTargetColorKey = 'targetColor';
  static const String _kIsHuntingActiveKey = 'isHuntingActive';
  static const String _kHuntingStartDateKey = 'huntingStartDate';

  @override
  void initState() {
    super.initState();
    _loadHuntingSession(); // Load both boards and current hunting session on app start
  }

  // Define _widgetOptions here, after methods are defined, or as a getter
  // which references the methods
  List<Widget> get _widgetOptions => <Widget>[
    TargetTab(
      targetColor: _targetColor,
      onColorSelected: _updateTargetColor,
      isHuntingActive: _isHuntingActive,
      onStartHunting: _startHunting,
    ),
    HuntingTab(
      isHuntingActive: _isHuntingActive,
      targetColor: _targetColor,
      gridImages: _gridImages,
      onTakePicture: _pickImageForGridCell,
      onRemoveImage: _removeImageFromGridCell,
      onInitializeSession: _resetHuntingSession,
      onSaveSession: _saveHuntingSession,
      onPickMultipleImages: _pickMultipleImages,
      onNavigateToTarget: () => _onItemTapped(0),
    ),
    ArchiveTab(
      savedColorBoards: _savedColorBoards,
      onSaveImagesToGallery: _saveColorBoardImagesToGallery,
      onDeleteColorBoard: _deleteColorBoard,
      onNavigateToTarget: () {
        setState(() {
          _selectedIndex = 0; // Navigate to Target tab
        });
      },
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _loadHuntingSession() async {
    final prefs = await SharedPreferences.getInstance();

    // Load saved color boards
    final String? savedBoardsJson = prefs.getString(_kSavedColorBoardsKey);
    if (savedBoardsJson != null) {
      final List<dynamic> decodedList = jsonDecode(savedBoardsJson);
      setState(() {
        _savedColorBoards = decodedList
            .map((item) => ColorBoard.fromJson(item))
            .toList();
      });
    }

    // Load target color
    final int? savedTargetColorValue = prefs.getInt(_kTargetColorKey);
    final bool savedIsHuntingActive =
        prefs.getBool(_kIsHuntingActiveKey) ?? false;
    final String? savedStartDateString = prefs.getString(_kHuntingStartDateKey);
    final DateTime? savedStartDate = savedStartDateString != null
        ? DateTime.parse(savedStartDateString)
        : null;

    // Load current hunting grid images
    final List<String>? currentGridImagePaths = prefs.getStringList(
      _kCurrentHuntingGridKey,
    );
    if (currentGridImagePaths != null && currentGridImagePaths.isNotEmpty) {
      final List<ImageProvider?> loadedImages = List.filled(12, null);
      bool hasImages = false;
      for (int i = 0; i < currentGridImagePaths.length; i++) {
        final path = currentGridImagePaths[i];
        if (path != null && await File(path).exists()) {
          loadedImages[i] = FileImage(File(path));
          hasImages = true;
        }
      }
      setState(() {
        _gridImages = loadedImages;
        _isHuntingActive = savedIsHuntingActive && hasImages;
        _huntingStartDate = savedStartDate;
        _targetColor = savedTargetColorValue != null
            ? Color(savedTargetColorValue)
            : Colors.transparent;
      });
    } else {
      // If no saved grid images, ensure hunting session is not active and grid is empty
      setState(() {
        _isHuntingActive = false;
        _gridImages = List.filled(12, null);
        _targetColor = Colors.transparent;
        _huntingStartDate = null;
      });
    }
  }

  Future<void> _saveColorBoards() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList = _savedColorBoards
        .map((board) => board.toJson())
        .toList();
    await prefs.setString(_kSavedColorBoardsKey, jsonEncode(jsonList));
  }

  Future<void> _saveHuntingGridImages() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> imagePaths = _gridImages.map((imageProvider) {
      if (imageProvider is FileImage) {
        return imageProvider.file.path;
      }
      return ''; // Use an empty string for null images to maintain list length
    }).toList();
    await prefs.setStringList(_kCurrentHuntingGridKey, imagePaths);
  }

  Future<void> _saveHuntingState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTargetColorKey, _targetColor.value);
    await prefs.setBool(_kIsHuntingActiveKey, _isHuntingActive);
    if (_huntingStartDate != null) {
      await prefs.setString(
        _kHuntingStartDateKey,
        _huntingStartDate!.toIso8601String(),
      );
    } else {
      await prefs.remove(_kHuntingStartDateKey);
    }
    await _saveHuntingGridImages();
  }

  void _initHuntingSession() {
    setState(() {
      _isHuntingActive = false;
      _targetColor = Colors.transparent;
      _gridImages = List.filled(12, null);
    });
    _saveHuntingGridImages(); // Persist the empty grid state
  }

  void _resetHuntingSession() {
    setState(() {
      _isHuntingActive = false;
      _targetColor = Colors.transparent;
      _gridImages = List.filled(12, null);
      _selectedIndex = 0;
    });
    _saveHuntingState(); // Persist the empty grid state and hunting state
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Hunting session reset!')));
  }

  // Function to create an image collage from a list of image paths
  Future<File?> _createImageCollage(
    List<String?> imagePaths,
    Color targetColor,
  ) async {
    const int numColumns = 3;
    const int numRows = 4;
    const int imageSize = 300; // Size of each individual image in the collage
    const int padding = 3; // Slight padding between images

    final int collageWidth =
        (imageSize * numColumns) + (padding * (numColumns - 1));
    final int collageHeight = (imageSize * numRows) + (padding * (numRows - 1));

    // Create a new image for the collage with white background
    final img.Image collage = img.Image(
      width: collageWidth,
      height: collageHeight,
    );
    // Fill the background with white
    img.fill(collage, color: img.ColorRgb8(255, 255, 255));

    int currentImageIndex = 0;
    for (int row = 0; row < numRows; row++) {
      for (int col = 0; col < numColumns; col++) {
        if (currentImageIndex < imagePaths.length &&
            imagePaths[currentImageIndex] != null) {
          final String? path = imagePaths[currentImageIndex];
          if (path != null && await File(path).exists()) {
            final File imageFile = File(path);
            final List<int> bytes = await imageFile.readAsBytes();
            img.Image? originalImage = img.decodeImage(
              Uint8List.fromList(bytes),
            ); // Convert List<int> to Uint8List

            if (originalImage != null) {
              // Resize image to fit the grid cell
              originalImage = img.copyResize(
                originalImage,
                width: imageSize,
                height: imageSize,
              );

              final int xOffset = col * (imageSize + padding);
              final int yOffset = row * (imageSize + padding);
              img.compositeImage(
                collage,
                originalImage,
                dstX: xOffset,
                dstY: yOffset,
              );
            }
          }
        }
        currentImageIndex++;
      }
    }

    final directory = await getTemporaryDirectory();
    final String collagePath =
        '${directory.path}/collage_${DateTime.now().millisecondsSinceEpoch}.png';
    final File collageFile = File(collagePath);
    await collageFile.writeAsBytes(img.encodePng(collage));

    return collageFile;
  }

  void _saveHuntingSession() async {
    if (_gridImages.any((image) => image == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all grid slots before saving!'),
        ),
      );
      return;
    }

    // Show memo input dialog
    final String? memo = await _showMemoDialog();

    // Convert ImageProvider to file paths for serialization
    final List<String?> imagePaths = _gridImages.map((imageProvider) {
      if (imageProvider is FileImage) {
        return imageProvider.file.path;
      }
      return null;
    }).toList();

    final completedDate = DateTime.now();

    setState(() {
      _savedColorBoards.add(
        ColorBoard(
          targetColor: _targetColor,
          gridImagePaths: imagePaths,
          memo: memo,
          createdDate: _huntingStartDate,
          completedDate: completedDate,
        ),
      );
      _isHuntingActive = false;
      _targetColor = Colors.transparent;
      _gridImages = List.filled(12, null);
      _huntingStartDate = null;
      _selectedIndex = 2;
    });
    _saveColorBoards(); // Persist the updated list
    _saveHuntingState(); // Persist the empty grid state after archiving
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hunting session saved and archived!')),
    );
  }

  Future<void> _saveColorBoardImagesToGallery(ColorBoard colorBoard) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('콜라주 이미지를 갤러리에 저장 중입니다...')));

    try {
      final File? collageFile = await _createImageCollage(
        colorBoard.gridImagePaths,
        colorBoard.targetColor,
      );

      if (collageFile != null && await collageFile.exists()) {
        await Gal.putImage(collageFile.path);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('콜라주 이미지를 갤러리에 저장했습니다.')));
        // Clean up the temporary collage file
        await collageFile.delete();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('콜라주 이미지 생성에 실패했습니다.')));
      }
    } catch (e) {
      print(
        'An unexpected error occurred while saving collage to gallery: $e',
      ); // Debugging
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('콜라주 이미지 저장 실패: $e')));
    }
  }

  Future<void> _deleteColorBoard(ColorBoard colorBoard) async {
    setState(() {
      _savedColorBoards.remove(colorBoard);
    });
    await _saveColorBoards();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '컬렉션이 삭제되었습니다',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<String?> _showMemoDialog() async {
    final TextEditingController memoController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '오늘의 기록',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF333333),
            ),
          ),
          content: TextField(
            controller: memoController,
            maxLines: 5,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: '이날의 특별한 순간들을 기록해보세요.',
              hintStyle: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w300,
                fontSize: 14,
                color: Color(0xFF999999),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF333333)),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Color(0xFF333333),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text(
                '건너뛰기',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Color(0xFF888888),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  memoController.text.trim().isEmpty
                      ? null
                      : memoController.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF333333),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                '저장',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateTargetColor(Color newColor) async {
    // Show warning if hunting is already active
    if (_isHuntingActive) {
      final bool? shouldChange = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              '타겟 컬러 변경',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
              ),
            ),
            content: const Text(
              '진행 중인 헌팅이 있습니다.\n타겟 컬러를 변경하면 현재 촬영한 사진들이 모두 초기화됩니다.\n\n정말 변경하시겠습니까?',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  '취소',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    color: Color(0xFF888888),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  '변경',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    color: Color(0xFF2D2D2D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (shouldChange != true) {
        return; // User cancelled, don't change color
      }

      // Reset hunting session if user confirmed
      setState(() {
        _targetColor = newColor;
        _gridImages = List.filled(12, null);
        _isHuntingActive = false;
      });
      _saveHuntingState();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('타겟 컬러가 변경되었습니다. 새로운 헌팅을 시작해주세요.')),
      );
    } else {
      // No active hunting, just change the color
      setState(() {
        _targetColor = newColor;
      });
      _saveHuntingState();
    }
  }

  void _startHunting() {
    setState(() {
      _isHuntingActive = true;
      _huntingStartDate = DateTime.now(); // Record start date
      _selectedIndex = 1;
    });
    _saveHuntingState();
  }

  // Save image to permanent app directory
  Future<String?> _saveImagePermanently(String sourcePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'hunting_img_${DateTime.now().millisecondsSinceEpoch}_${sourcePath.split('/').last}';
      final permanentPath = '${directory.path}/$fileName';

      final File sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(permanentPath);
        return permanentPath;
      }
      return null;
    } catch (e) {
      print('Error saving image permanently: $e');
      return null;
    }
  }

  Future<void> _pickImageForGridCell(int index) async {
    final ImageSelectionType? selectionType =
        await showModalBottomSheet<ImageSelectionType>(
          context: context,
          builder: (BuildContext context) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Take Photo'),
                    onTap: () =>
                        Navigator.pop(context, ImageSelectionType.camera),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Choose from Gallery'),
                    onTap: () => Navigator.pop(
                      context,
                      ImageSelectionType.gallerySingle,
                    ),
                  ),
                ],
              ),
            );
          },
        );

    if (selectionType == null) return;

    String? imagePath;

    if (selectionType == ImageSelectionType.camera) {
      if (cameras.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No cameras found')));
        return;
      }
      imagePath = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CameraScreen(cameras: cameras, targetColor: _targetColor),
        ),
      );
    } else if (selectionType == ImageSelectionType.gallerySingle) {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      imagePath = pickedFile?.path;
    }

    if (imagePath != null) {
      // Save image to permanent directory
      final String? permanentPath = await _saveImagePermanently(imagePath);
      if (permanentPath != null) {
        setState(() {
          _gridImages[index] = FileImage(File(permanentPath));
        });
        _saveHuntingState(); // Persist the updated grid and hunting state
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save image')));
      }
    }
  }

  void _removeImageFromGridCell(int index) {
    setState(() {
      _gridImages[index] = null;
    });
    _saveHuntingState(); // Persist the updated grid state

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '이미지가 제거되었습니다',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _pickMultipleImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      int currentGridIndex = 0;
      for (final XFile file in pickedFiles) {
        while (currentGridIndex < _gridImages.length &&
            _gridImages[currentGridIndex] != null) {
          currentGridIndex++;
        }
        if (currentGridIndex < _gridImages.length) {
          // Save image to permanent directory
          final String? permanentPath = await _saveImagePermanently(file.path);
          if (permanentPath != null) {
            setState(() {
              _gridImages[currentGridIndex] = FileImage(File(permanentPath));
            });
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No more empty slots to add images!')),
          );
          break;
        }
      }
      _saveHuntingState(); // Persist the updated grid and hunting state after all images are added
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(0xFF888888);

    Widget titleWidget;
    Color appBarColor = Colors.white;
    Color appBarForegroundColor = Color(0xFF2D2D2D);

    switch (_selectedIndex) {
      case 1: // Hunting Tab
        if (_isHuntingActive) {
          appBarColor = _targetColor;
          appBarForegroundColor = Colors.white;
        } else {
          appBarColor = Colors.white;
          appBarForegroundColor = Color(0xFF2D2D2D);
        }
        titleWidget = Text(
          'Color Hunting',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        );
        break;
      case 2: // Archive Tab
        titleWidget = Text(
          '나의 컬렉션',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        );
        break;
      default: // Target Tab
        titleWidget = Text(
          'Color Hunting',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: titleWidget,
        centerTitle: true,
        backgroundColor: appBarColor,
        foregroundColor: appBarForegroundColor,
        elevation: 0,
        toolbarHeight: 56,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            height: 0.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  (_selectedIndex == 1 && _isHuntingActive)
                      ? appBarForegroundColor.withOpacity(0.1)
                      : Color(0xFFF0F0F0),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.circle_outlined,
              color: _selectedIndex == 0 ? accentColor : Color(0xFF2D2D2D),
              size: 28,
              weight: 0.5,
            ),
            label: 'Target',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.grid_3x3,
              color: _selectedIndex == 1 ? accentColor : Color(0xFF2D2D2D),
              size: 28,
              weight: 0.5,
            ),
            label: 'Hunting',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.photo_library_outlined,
              color: _selectedIndex == 2 ? accentColor : Color(0xFF2D2D2D),
              size: 28,
              weight: 0.5,
            ),
            label: 'Archive',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: accentColor,
        unselectedItemColor: Color(0xFF2D2D2D),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}
