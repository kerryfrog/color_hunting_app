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
      _controller.setFlashMode(_currentFlashMode);
      setState(() {
        _currentZoomLevel = 1.0;
        _baseZoomLevel = 1.0;
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

  Future<void> _captureImage() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      if (!mounted) return;
      Navigator.pop(context, image.path);
    } catch (e) {
      // Keep camera screen alive if capture fails.
      debugPrint('Failed to take picture: $e');
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
                final previewAspectRatio = _controller.value.aspectRatio;
                final screenAspectRatio =
                    constraints.maxWidth / constraints.maxHeight;
                final scale = previewAspectRatio / screenAspectRatio;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      onTapUp: _handleTapToFocus,
                      onScaleStart: (details) {
                        _baseZoomLevel = _currentZoomLevel;
                      },
                      onScaleUpdate: (details) {
                        _currentZoomLevel = (_baseZoomLevel * details.scale)
                            .clamp(_minZoomLevel, _maxZoomLevel);
                        _controller.setZoomLevel(_currentZoomLevel);
                      },
                      child: Transform.scale(
                        scale: scale < 1 ? 1 / scale : scale,
                        alignment: Alignment.center,
                        child: Center(child: CameraPreview(_controller)),
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
                    CustomPaint(size: Size.infinite, painter: _GridPainter()),
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
