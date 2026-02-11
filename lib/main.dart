import 'dart:io';
import 'dart:convert'; // For JSON encoding/decoding
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

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

  ColorBoard({
    required this.targetColor,
    required this.gridImagePaths,
  });

  // Convert ColorBoard to JSON
  Map<String, dynamic> toJson() => {
        'targetColor': targetColor.value, // Store color as int
        'gridImagePaths': gridImagePaths,
      };

  // Create ColorBoard from JSON
  factory ColorBoard.fromJson(Map<String, dynamic> json) {
    return ColorBoard(
      targetColor: Color(json['targetColor']),
      gridImagePaths: List<String?>.from(json['gridImagePaths']),
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

  static const String _kSavedColorBoardsKey = 'savedColorBoards';

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
          onInitializeSession: _resetHuntingSession,
          onSaveSession: _saveHuntingSession,
          onPickMultipleImages: _pickMultipleImages,
        ),
        ArchiveTab(
          savedColorBoards: _savedColorBoards,
          onSaveImagesToGallery: _saveColorBoardImagesToGallery,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _loadSavedColorBoards(); // Load boards on app start
    _initHuntingSession();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _loadSavedColorBoards() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedBoardsJson = prefs.getString(_kSavedColorBoardsKey);

    if (savedBoardsJson != null) {
      final List<dynamic> decodedList = jsonDecode(savedBoardsJson);
      setState(() {
        _savedColorBoards = decodedList.map((item) => ColorBoard.fromJson(item)).toList();
      });
    }
  }

  Future<void> _saveColorBoards() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList = _savedColorBoards.map((board) => board.toJson()).toList();
    await prefs.setString(_kSavedColorBoardsKey, jsonEncode(jsonList));
  }

  void _initHuntingSession() {
    setState(() {
      _isHuntingActive = false;
      _targetColor = Colors.transparent;
      _gridImages = List.filled(12, null);
    });
  }

  void _resetHuntingSession() {
    setState(() {
      _isHuntingActive = false;
      _targetColor = Colors.transparent;
      _gridImages = List.filled(12, null);
      _selectedIndex = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hunting session reset!')),
    );
  }

  void _saveHuntingSession() {
    if (_gridImages.any((image) => image == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all grid slots before saving!')),
      );
      return;
    }

    // Convert ImageProvider to file paths for serialization
    final List<String?> imagePaths = _gridImages.map((imageProvider) {
      if (imageProvider is FileImage) {
        return imageProvider.file.path;
      }
      return null;
    }).toList();

    setState(() {
      _savedColorBoards.add(ColorBoard(
        targetColor: _targetColor,
        gridImagePaths: imagePaths,
      ));
      _isHuntingActive = false;
      _targetColor = Colors.transparent;
      _gridImages = List.filled(12, null);
      _selectedIndex = 2;
    });
    _saveColorBoards(); // Persist the updated list
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hunting session saved and archived!')),
    );
  }

  Future<void> _saveColorBoardImagesToGallery(ColorBoard colorBoard) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이미지를 갤러리에 저장 중입니다...')),
    );

    try {
      int savedCount = 0;
      for (final imagePath in colorBoard.gridImagePaths) {
        if (imagePath != null && await File(imagePath).exists()) {
          try {
            await Gal.putImage(imagePath);
            savedCount++;
          } catch (galError) {
            print('Gal.putImage failed for $imagePath: $galError');
          }
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$savedCount개의 이미지를 갤러리에 저장했습니다.')),
      );
    } catch (e) {
      print('An unexpected error occurred while saving images to gallery: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 저장 실패: $e')),
      );
    }
  }

  void _updateTargetColor(Color newColor) {
    setState(() {
      _targetColor = newColor;
    });
  }

  void _startHunting() {
    setState(() {
      _isHuntingActive = true;
      _selectedIndex = 1;
    });
  }

  Future<void> _pickImageForGridCell(int index) async {
    final ImageSelectionType? selectionType = await showModalBottomSheet<ImageSelectionType>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSelectionType.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSelectionType.gallerySingle),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No cameras found')),
        );
        return;
      }
      imagePath = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(
            camera: cameras.first,
            targetColor: _targetColor,
          ),
        ),
      );
    } else if (selectionType == ImageSelectionType.gallerySingle) {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      imagePath = pickedFile?.path;
    }

    if (imagePath != null) {
      setState(() {
        _gridImages[index] = FileImage(File(imagePath!));
      });
    }
  }

  Future<void> _pickMultipleImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        int currentGridIndex = 0;
        for (final XFile file in pickedFiles) {
          while (currentGridIndex < _gridImages.length && _gridImages[currentGridIndex] != null) {
            currentGridIndex++;
          }
          if (currentGridIndex < _gridImages.length) {
            _gridImages[currentGridIndex] = FileImage(File(file.path));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No more empty slots to add images!')),
            );
            break;
          }
        }
      });
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
        appBarColor = _targetColor;
        appBarForegroundColor = Colors.white;
        titleWidget = const Text('Hunting Color');
        break;
      case 2: // Archive Tab
        titleWidget = const Text('나의 컬렉션');
        break;
      default: // Target Tab
        titleWidget = const Text('Color Hunting');
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: titleWidget,
        centerTitle: true,
        backgroundColor: appBarColor,
        foregroundColor: appBarForegroundColor,
        elevation: 0,
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.circle_outlined, color: _selectedIndex == 0 ? accentColor : Color(0xFF2D2D2D), size: 28, weight: 0.5),
            label: 'Target',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_3x3, color: _selectedIndex == 1 ? accentColor : Color(0xFF2D2D2D), size: 28, weight: 0.5),
            label: 'Hunting',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library_outlined, color: _selectedIndex == 2 ? accentColor : Color(0xFF2D2D2D), size: 28, weight: 0.5),
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
