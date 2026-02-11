import 'package:flutter/material.dart';
import 'dart:math';

class TargetTab extends StatefulWidget {
  final Color targetColor;
  final Function(Color) onColorSelected;
  final bool isHuntingActive;
  final VoidCallback onStartHunting;

  const TargetTab({
    super.key,
    required this.targetColor,
    required this.onColorSelected,
    required this.isHuntingActive,
    required this.onStartHunting,
  });

  @override
  State<TargetTab> createState() => _TargetTabState();
}

class _TargetTabState extends State<TargetTab> {
  final Random _random = Random();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              final newColor = Colors.primaries[_random.nextInt(Colors.primaries.length)];
              widget.onColorSelected(newColor);
            },
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: widget.targetColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 2),
              ),
              child: widget.targetColor == Colors.transparent
                  ? const Center(
                      child: Text(
                        '탭해서 오늘의 색상 정하기',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          if (widget.targetColor != Colors.transparent)
            Text(
              'HEX: #${widget.targetColor.value.toRadixString(16).substring(2).toUpperCase()}',
              style: const TextStyle(fontSize: 20),
            ),
          const SizedBox(height: 20),
          if (!widget.isHuntingActive && widget.targetColor != Colors.transparent)
            SizedBox(
              width: 200, // Fixed width for capsule shape
              height: 60, // Fixed height for capsule shape
              child: ElevatedButton(
                onPressed: widget.onStartHunting,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0), // Capsule shape
                  ),
                  elevation: 10, // Shadow effect
                ),
                child: const Text(
                  'Hunting 시작하기',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
