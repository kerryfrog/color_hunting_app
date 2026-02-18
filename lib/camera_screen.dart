import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image/image.dart' as img;

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
  static const double _kMaxAllowedZoom = 10.0;

  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  int _selectedCameraIndex = 0;
  FlashMode _currentFlashMode = FlashMode.off;
  double _currentZoomLevel = 1.0;
  double _baseZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  Offset? _focusPoint;
  bool _showFocusCircle = false;
  int _pointerCount = 0;
  double _previewViewportAspectRatio = 9 / 16;

  Future<void> _configureAutoFocusDefaults() async {
    try {
      await _controller.setFocusMode(FocusMode.auto);
    } catch (_) {}
    try {
      await _controller.setExposureMode(ExposureMode.auto);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera(_selectedCameraIndex);
  }

  void _initializeCamera(int cameraIndex) {
    _controller = CameraController(
      widget.cameras[cameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller.initialize().then((_) async {
      final min = await _controller.getMinZoomLevel();
      final deviceMax = await _controller.getMaxZoomLevel();
      final max = deviceMax.clamp(min, _kMaxAllowedZoom);
      await _controller.setFlashMode(_currentFlashMode);
      await _configureAutoFocusDefaults();

      final initialZoom = min.clamp(1.0, max);
      await _controller.setZoomLevel(initialZoom);
      if (!mounted) return;
      setState(() {
        _minZoomLevel = min;
        _maxZoomLevel = max;
        _currentZoomLevel = initialZoom;
        _baseZoomLevel = initialZoom;
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

  Future<void> _handleTapToFocus(TapDownDetails details, Size previewSize) async {
    if (!_controller.value.isInitialized) return;

    final x = (details.localPosition.dx / previewSize.width).clamp(0.0, 1.0);
    final y = (details.localPosition.dy / previewSize.height).clamp(0.0, 1.0);
    final point = Offset(x, y);

    setState(() {
      _focusPoint = details.localPosition;
      _showFocusCircle = true;
    });

    try {
      await _controller.setFocusMode(FocusMode.auto);
      await _controller.setExposureMode(ExposureMode.auto);
      await _controller.setFocusPoint(point);
      await _controller.setExposurePoint(point);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이 기기에서는 탭 초점이 제한될 수 있습니다'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _showFocusCircle = false;
      });
    });
  }

  void _onSwitchCamera() {
    if (widget.cameras.length > 1) {
      _controller.dispose();
      _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
      _initializeCamera(_selectedCameraIndex);
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (_pointerCount < 2) return;
    _baseZoomLevel = _currentZoomLevel;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_pointerCount < 2 || !_controller.value.isInitialized) return;

    final nextZoom = (_baseZoomLevel * details.scale).clamp(
      _minZoomLevel,
      _maxZoomLevel,
    );

    if ((nextZoom - _currentZoomLevel).abs() < 0.01) return;

    setState(() {
      _currentZoomLevel = nextZoom;
    });
    _controller.setZoomLevel(nextZoom);
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

  Future<void> _captureImage() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      final processedPath = await _cropCapturedImageToPreview(image.path);
      if (!mounted) return;
      Navigator.pop(context, processedPath);
    } catch (e) {
      // Keep camera screen alive if capture fails.
      debugPrint('Failed to take picture: $e');
    }
  }

  Future<String> _cropCapturedImageToPreview(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return imagePath;

      final targetAspectRatio = _previewViewportAspectRatio;
      final imageAspectRatio = decoded.width / decoded.height;

      int cropX = 0;
      int cropY = 0;
      int cropWidth = decoded.width;
      int cropHeight = decoded.height;

      if (imageAspectRatio > targetAspectRatio) {
        cropWidth = (decoded.height * targetAspectRatio).round();
        cropX = ((decoded.width - cropWidth) / 2).round();
      } else if (imageAspectRatio < targetAspectRatio) {
        cropHeight = (decoded.width / targetAspectRatio).round();
        cropY = ((decoded.height - cropHeight) / 2).round();
      }

      final cropped = img.copyCrop(
        decoded,
        x: cropX.clamp(0, decoded.width - 1),
        y: cropY.clamp(0, decoded.height - 1),
        width: cropWidth.clamp(1, decoded.width),
        height: cropHeight.clamp(1, decoded.height),
      );

      await file.writeAsBytes(img.encodeJpg(cropped, quality: 95), flush: true);
      return imagePath;
    } catch (_) {
      return imagePath;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final screenAspectRatio =
                    constraints.maxWidth / constraints.maxHeight;
                final rawPreviewSize = _controller.value.previewSize;
                final textureAspectRatio = rawPreviewSize == null
                    ? _controller.value.aspectRatio
                    : rawPreviewSize.height / rawPreviewSize.width;
                final fittedWidth = constraints.maxHeight * textureAspectRatio;
                final previewSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                _previewViewportAspectRatio = screenAspectRatio;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      onTapDown: (details) =>
                          _handleTapToFocus(details, previewSize),
                      onScaleStart: _onScaleStart,
                      onScaleUpdate: _onScaleUpdate,
                      child: Listener(
                        onPointerDown: (_) => _pointerCount++,
                        onPointerUp: (_) {
                          if (_pointerCount > 0) _pointerCount--;
                        },
                        onPointerCancel: (_) {
                          if (_pointerCount > 0) _pointerCount--;
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRect(
                              child: OverflowBox(
                                alignment: Alignment.center,
                                minWidth: 0,
                                minHeight: 0,
                                maxWidth: double.infinity,
                                maxHeight: double.infinity,
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: fittedWidth,
                                    height: constraints.maxHeight,
                                    child: CameraPreview(_controller),
                                  ),
                                ),
                              ),
                            ),
                            CustomPaint(
                              size: Size.infinite,
                              painter: _GridPainter(),
                            ),
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
                          ],
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.35),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.45),
                          ],
                          stops: const [0.0, 0.2, 0.7, 1.0],
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 18, top: 96),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: widget.targetColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                            child: Row(
                              children: [
                                _CameraControlButton(
                                  icon: Icons.close,
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const Spacer(),
                                _CameraControlButton(
                                  icon: _getFlashIcon(),
                                  onPressed: _onFlashModeButtonPressed,
                                ),
                                const SizedBox(width: 10),
                                _CameraControlButton(
                                  icon: Icons.cameraswitch_outlined,
                                  onPressed: widget.cameras.length > 1
                                      ? _onSwitchCamera
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: widget.targetColor.withOpacity(0.95),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: widget.targetColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _colorToHex(widget.targetColor),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                Text(
                                  '${_currentZoomLevel.toStringAsFixed(1)}x',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 2.2,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 7,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                        overlayRadius: 12,
                                      ),
                                    ),
                                    child: Slider(
                                      value: _currentZoomLevel.clamp(
                                        _minZoomLevel,
                                        _maxZoomLevel,
                                      ),
                                      min: _minZoomLevel,
                                      max: _maxZoomLevel,
                                      onChanged: (value) {
                                        setState(() {
                                          _currentZoomLevel = value;
                                        });
                                        _controller.setZoomLevel(value);
                                      },
                                      activeColor: Colors.white,
                                      inactiveColor: Colors.white.withOpacity(
                                        0.35,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 12, 0, 20),
                            child: GestureDetector(
                              onTap: _captureImage,
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: widget.targetColor,
                                    width: 5,
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 66,
                                    height: 66,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.22)
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

class _CameraControlButton extends StatelessWidget {
  const _CameraControlButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: Colors.white,
      ),
    );
  }
}

class CameraMockScreen extends StatelessWidget {
  final Color targetColor;

  const CameraMockScreen({super.key, required this.targetColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),
          CustomPaint(size: Size.infinite, painter: _GridPainter()),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.35),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.45),
                ],
                stops: const [0.0, 0.2, 0.7, 1.0],
              ),
            ),
          ),
          Center(
            child: Text(
              'Simulator Camera Preview',
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
          IgnorePointer(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 18, top: 96),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: targetColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Row(
                    children: [
                      _CameraControlButton(
                        icon: Icons.close,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      _CameraControlButton(icon: Icons.flash_off, onPressed: null),
                      const SizedBox(width: 10),
                      _CameraControlButton(
                        icon: Icons.cameraswitch_outlined,
                        onPressed: null,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 20),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: targetColor, width: 5),
                      ),
                      child: Center(
                        child: Container(
                          width: 66,
                          height: 66,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
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
