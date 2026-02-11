import 'package:flutter/material.dart';

class MainHuntScreen extends StatefulWidget {
  const MainHuntScreen({super.key});

  @override
  State<MainHuntScreen> createState() => _MainHuntScreenState();
}

class _MainHuntScreenState extends State<MainHuntScreen> with SingleTickerProviderStateMixin {
  Color _targetColor = const Color(0xFF4A90E2); // Example target color
  bool _isHuntingActive = false;
  late AnimationController _controller;
  late Animation<Color?> _bgColorAnim;
  List<Color?> _slotColors = List.filled(12, null);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bgColorAnim = ColorTween(
      begin: Colors.white,
      end: _targetColor.withOpacity(0.12),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void _startHunting() {
    setState(() {
      _isHuntingActive = true;
      _slotColors = List.filled(12, _targetColor.withOpacity(0.12));
    });
    _controller.forward();
  }

  String _colorToHex(Color color) => '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

  String _getColorName(Color color) {
    // You can expand this map for more color names
    const colorNames = {
      0xFF4A90E2: 'Blue',
      0xFFFF5252: 'Red',
      0xFF4CAF50: 'Green',
      0xFFFFC107: 'Amber',
      0xFF9C27B0: 'Purple',
    };
    return colorNames[color.value] ?? 'Custom Color';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _bgColorAnim.value ?? Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: _targetColor, width: 2),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _colorToHex(_targetColor),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _targetColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getColorName(_targetColor),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GridView.builder(
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, idx) {
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: _targetColor, width: 1.2),
                  ),
                  color: _slotColors[idx] ?? Colors.white,
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
          floatingActionButton: !_isHuntingActive
              ? FloatingActionButton.extended(
                  onPressed: _startHunting,
                  backgroundColor: _targetColor,
                  label: const Text(
                    'Start',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  icon: const Icon(Icons.play_arrow),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }
}
