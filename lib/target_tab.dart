import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final accentColor = widget.targetColor == Colors.transparent
        ? Color(0xFF888888)
        : widget.targetColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Spacer to push content to center
          const Spacer(),

          // Glassmorphism card with color circle
          Center(
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Color circle
                  GestureDetector(
                    onTap: () {
                      final newColor = Colors
                          .primaries[_random.nextInt(Colors.primaries.length)];
                      widget.onColorSelected(newColor);
                    },
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: widget.targetColor == Colors.transparent
                            ? Colors.grey.shade200
                            : widget.targetColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.targetColor == Colors.transparent
                              ? Colors.grey.shade300
                              : Colors.white,
                          width: 3,
                        ),
                      ),
                      child: widget.targetColor == Colors.transparent
                          ? Center(
                              child: Text(
                                l10n.targetTapToPick,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w300,
                                  height: 1.4,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),

                  // HEX code
                  if (widget.targetColor != Colors.transparent) ...[
                    const SizedBox(height: 24),
                    Text(
                      '#${widget.targetColor.value.toRadixString(16).substring(2).toUpperCase()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2.0,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const Spacer(),

          // Bottom buttons
          if (!widget.isHuntingActive &&
              widget.targetColor != Colors.transparent)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        final newColor =
                            Colors.primaries[_random.nextInt(
                              Colors.primaries.length,
                            )];
                        widget.onColorSelected(newColor);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Color(0xFF888888), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Colors.white,
                      ),
                      child: Text(
                        l10n.targetPickAgain,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF888888),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onStartHunting,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accentColor, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: accentColor,
                      ),
                      child: Text(
                        l10n.targetStartHunting,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 40),
        ],
      ),
    );
  }
}
