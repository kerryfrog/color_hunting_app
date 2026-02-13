import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Color targetColor;

  const CameraScreen({
    super.key,
    required this.cameras,
    required this.targetColor,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  int _selectedCameraIndex = 0;
  FlashMode _currentFlashMode = FlashMode.off;
  double _currentExposureOffset = 0.0;
  double _minExposureOffset = 0.0;
  double _maxExposureOffset = 0.0;
  double _currentZoomLevel = 1.0;
  double _baseZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  Offset? _focusPoint;
  bool _showFocusCircle = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera(_selectedCameraIndex);
  }

  void _initializeCamera(int cameraIndex) {
    _controller = CameraController(
      widget.cameras[cameraIndex],
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize().then((_) {
      _controller.getMinZoomLevel().then((min) => _minZoomLevel = min);
      _controller.getMaxZoomLevel().then((max) => _maxZoomLevel = max);
      _controller.getMinExposureOffset().then(
        (min) => _minExposureOffset = min,
      );
      _controller.getMaxExposureOffset().then(
        (max) => _maxExposureOffset = max,
      );
      _controller.setFlashMode(_currentFlashMode);
      setState(() {
        _currentZoomLevel = 1.0;
        _baseZoomLevel = 1.0;
        _currentExposureOffset = 0.0;
      });
    });

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapToFocus(TapUpDetails details) {
    if (_controller.value.isInitialized) {
      final screenSize = MediaQuery.of(context).size;
      final x = details.localPosition.dx / screenSize.width;
      final y = details.localPosition.dy / screenSize.height;

      _controller.setFocusPoint(Offset(x, y));
      _controller.setFocusMode(FocusMode.auto);

      setState(() {
        _focusPoint = details.localPosition;
        _showFocusCircle = true;
      });

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _showFocusCircle = false;
          });
        }
      });
    }
  }

  void _onSwitchCamera() {
    if (widget.cameras.length > 1) {
      _controller.dispose();
      _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
      _initializeCamera(_selectedCameraIndex);
    }
  }

  void _onFlashModeButtonPressed() {
    setState(() {
      if (_currentFlashMode == FlashMode.off) {
        _currentFlashMode = FlashMode.auto;
      } else if (_currentFlashMode == FlashMode.auto) {
        _currentFlashMode = FlashMode.always;
      } else {
        _currentFlashMode = FlashMode.off;
      }
    });
    _controller.setFlashMode(_currentFlashMode);
  }

  IconData _getFlashIcon() {
    switch (_currentFlashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.highlight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take a picture'),
        actions: [
          IconButton(
            icon: Icon(_getFlashIcon()),
            onPressed: _onFlashModeButtonPressed,
          ),
          if (widget.cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.switch_camera),
              onPressed: _onSwitchCamera,
            ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final mediaSize = MediaQuery.of(context).size;
            final scale =
                1 / (_controller.value.aspectRatio * mediaSize.aspectRatio);
            return ClipRect(
              clipper: _MediaSizeClipper(mediaSize),
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.center,
                child: GestureDetector(
                  onTapUp: _handleTapToFocus,
                  onScaleStart: (details) {
                    _baseZoomLevel = _currentZoomLevel;
                  },
                  onScaleUpdate: (details) {
                    _currentZoomLevel = (_baseZoomLevel * details.scale).clamp(
                      _minZoomLevel,
                      _maxZoomLevel,
                    );
                    _controller.setZoomLevel(_currentZoomLevel);
                  },
                  child: Stack(
                    children: [
                      CameraPreview(_controller),
                      CustomPaint(size: Size.infinite, painter: _GridPainter()),
                      if (_showFocusCircle && _focusPoint != null)
                        Positioned(
                          top: _focusPoint!.dy - 30,
                          left: _focusPoint!.dx - 30,
                          child: Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 100,
                        left: 16,
                        right: 16,
                        child: Column(
                          children: [
                            Text(
                              "Exposure: ${_currentExposureOffset.toStringAsFixed(1)}",
                              style: TextStyle(color: Colors.white),
                            ),
                            Slider(
                              value: _currentExposureOffset,
                              min: _minExposureOffset,
                              max: _maxExposureOffset,
                              divisions:
                                  ((_maxExposureOffset - _minExposureOffset) /
                                          0.1)
                                      .round()
                                      .clamp(1, 1000),
                              onChanged: (value) {
                                setState(() {
                                  _currentExposureOffset = value;
                                });
                                _controller.setExposureOffset(value);
                              },
                              activeColor: Colors.white,
                              inactiveColor: Colors.white.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: FloatingActionButton(
                            onPressed: () async {
                              try {
                                await _initializeControllerFuture;
                                final image = await _controller.takePicture();
                                if (!mounted) return;
                                Navigator.pop(context, image.path);
                              } catch (e) {
                                print(e);
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: widget.targetColor,
                                  width: 5.0,
                                ),
                              ),
                              child: const Icon(Icons.camera_alt, size: 40),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class _MediaSizeClipper extends CustomClipper<Rect> {
  final Size mediaSize;
  const _MediaSizeClipper(this.mediaSize);
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, mediaSize.width, mediaSize.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.0;

    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(size.width * i / 3, 0),
        Offset(size.width * i / 3, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, size.height * i / 3),
        Offset(size.width, size.height * i / 3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
