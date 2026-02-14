import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';
import 'dart:math';

class TargetTab extends StatefulWidget {
  final Color targetColor;
  final Function(Color) onColorSelected;
  final bool isHuntingActive;
  final VoidCallback onStartHunting;
  final Future<bool> Function()? onRequestColorPickerAccess;

  const TargetTab({
    super.key,
    required this.targetColor,
    required this.onColorSelected,
    required this.isHuntingActive,
    required this.onStartHunting,
    this.onRequestColorPickerAccess,
  });

  @override
  State<TargetTab> createState() => _TargetTabState();
}

class _TargetTabState extends State<TargetTab> {
  final Random _random = Random();

  String _text(
    BuildContext context, {
    required String ko,
    required String en,
    required String ja,
    required String zh,
  }) {
    return switch (Localizations.localeOf(context).languageCode) {
      'en' => en,
      'ja' => ja,
      'zh' => zh,
      _ => ko,
    };
  }

  Future<void> _openColorPickerWithAdGate(BuildContext context) async {
    final allow = await widget.onRequestColorPickerAccess?.call() ?? true;
    if (!allow || !context.mounted) return;
    await _showColorPickerSheet(context);
  }

  Color? _parseHexToColor(String input, double opacity) {
    final normalized = input.replaceAll('#', '').trim();
    if (normalized.length != 6) return null;
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return null;
    final r = (value >> 16) & 0xFF;
    final g = (value >> 8) & 0xFF;
    final b = value & 0xFF;
    return Color.fromARGB((opacity * 255).round(), r, g, b);
  }

  Future<String?> _showHexInputDialog(BuildContext context, String initialHex) {
    final controller = TextEditingController(text: initialHex);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            _text(
              context,
              ko: '컬러코드 직접 입력',
              en: 'Enter Hex Code',
              ja: '16進コード入力',
              zh: '输入十六进制代码',
            ),
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F#]')),
              LengthLimitingTextInputFormatter(7),
            ],
            decoration: InputDecoration(
              prefixText: '#',
              hintText: 'FFFFFF',
              filled: true,
              fillColor: const Color(0xFFF3F3F3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                _text(
                  context,
                  ko: '취소',
                  en: 'Cancel',
                  ja: 'キャンセル',
                  zh: '取消',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF333333),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: Text(
                _text(
                  context,
                  ko: '확인',
                  en: 'OK',
                  ja: '確認',
                  zh: '确认',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showColorPickerSheet(BuildContext context) async {
    final initialColor = widget.targetColor == Colors.transparent
        ? const Color(0xFF888888)
        : widget.targetColor;
    final initialHsv = HSVColor.fromColor(initialColor);
    double hue = initialHsv.hue;
    double saturation = initialHsv.saturation;
    double value = initialHsv.value;
    double opacity = 1.0;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final previewColor = HSVColor.fromAHSV(
              opacity,
              hue,
              saturation,
              value,
            ).toColor();
            final hex = previewColor
                .toARGB32()
                .toRadixString(16)
                .substring(2)
                .toUpperCase();

            void updatePalettePosition(Offset localPosition, double size) {
              final clampedSaturation = (localPosition.dx / size).clamp(
                0.0,
                1.0,
              );
              final clampedValue = (1 - (localPosition.dy / size)).clamp(
                0.0,
                1.0,
              );

              setSheetState(() {
                saturation = clampedSaturation;
                value = clampedValue;
              });
            }

            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.86,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final paletteSize = min(constraints.maxWidth, 330.0);
                      final thumbX = saturation * paletteSize;
                      final thumbY = (1 - value) * paletteSize;

                      return Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDADADA),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: paletteSize,
                              height: paletteSize,
                              child: GestureDetector(
                                onPanDown: (details) => updatePalettePosition(
                                  details.localPosition,
                                  paletteSize,
                                ),
                                onPanUpdate: (details) => updatePalettePosition(
                                  details.localPosition,
                                  paletteSize,
                                ),
                                onTapDown: (details) => updatePalettePosition(
                                  details.localPosition,
                                  paletteSize,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Stack(
                                    children: [
                                      Container(
                                        color: HSVColor.fromAHSV(
                                          1,
                                          hue,
                                          1,
                                          1,
                                        ).toColor(),
                                      ),
                                      Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              Colors.white,
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                      Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black,
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: thumbX - 9,
                                        top: thumbY - 9,
                                        child: Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  height: 14,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF0000),
                                        Color(0xFFFFFF00),
                                        Color(0xFF00FF00),
                                        Color(0xFF00FFFF),
                                        Color(0xFF0000FF),
                                        Color(0xFFFF00FF),
                                        Color(0xFFFF0000),
                                      ],
                                    ),
                                  ),
                                ),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 14,
                                    activeTrackColor: Colors.transparent,
                                    inactiveTrackColor: Colors.transparent,
                                    thumbColor: Colors.white,
                                    overlayColor: Colors.transparent,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 9,
                                    ),
                                  ),
                                  child: Slider(
                                    value: hue,
                                    min: 0,
                                    max: 360,
                                    onChanged: (newHue) {
                                      setSheetState(() {
                                        hue = newHue;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  height: 14,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.grey.shade300,
                                        Colors.white,
                                        HSVColor.fromAHSV(
                                          1,
                                          hue,
                                          saturation,
                                          value,
                                        ).toColor(),
                                      ],
                                    ),
                                  ),
                                ),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 14,
                                    activeTrackColor: Colors.transparent,
                                    inactiveTrackColor: Colors.transparent,
                                    thumbColor: Colors.white,
                                    overlayColor: Colors.transparent,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 9,
                                    ),
                                  ),
                                  child: Slider(
                                    value: opacity,
                                    min: 0,
                                    max: 1,
                                    onChanged: (newOpacity) {
                                      setSheetState(() {
                                        opacity = newOpacity;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F3F3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: previewColor,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.black12,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _text(
                                                context,
                                                ko: '선택 색상',
                                                en: 'Selected',
                                                ja: '選択色',
                                                zh: '已选颜色',
                                              ),
                                              style: const TextStyle(
                                                fontFamily: 'Pretendard',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF666666),
                                              ),
                                            ),
                                            Text(
                                              '#$hex',
                                              style: const TextStyle(
                                                fontFamily: 'Pretendard',
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () async {
                                    final input = await _showHexInputDialog(
                                      context,
                                      hex,
                                    );
                                    if (input == null) return;

                                    final parsed = _parseHexToColor(
                                      input,
                                      opacity,
                                    );
                                    if (parsed == null) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _text(
                                              context,
                                              ko: '올바른 HEX 코드(6자리)를 입력하세요',
                                              en: 'Enter a valid 6-digit hex code',
                                              ja: '有効な6桁の16進コードを入力してください',
                                              zh: '请输入有效的6位十六进制代码',
                                            ),
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      return;
                                    }

                                    final hsv = HSVColor.fromColor(parsed);
                                    setSheetState(() {
                                      hue = hsv.hue;
                                      saturation = hsv.saturation;
                                      value = hsv.value;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFFD0D0D0),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                    backgroundColor: const Color(0xFFF8F8F8),
                                  ),
                                  child: Text(
                                    _text(
                                      context,
                                      ko: '직접 입력',
                                      en: 'Manual',
                                      ja: '手動入力',
                                      zh: '手动输入',
                                    ),
                                    style: const TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF444444),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                widget.onColorSelected(previewColor.withAlpha(255));
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF333333),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                _text(
                                  context,
                                  ko: '이 색상 선택',
                                  en: 'Use This Color',
                                  ja: 'この色を使用',
                                  zh: '使用此颜色',
                                ),
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accentColor = widget.targetColor == Colors.transparent
        ? Color(0xFF888888)
        : widget.targetColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 18,
            right: 20,
            child: InkWell(
              onTap: () => _openColorPickerWithAdGate(context),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 15,
                      color: Color(0xFF555555),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _text(
                        context,
                        ko: '컬러 피커 (광고)',
                        en: 'Color Picker (Ad)',
                        ja: 'カラーピッカー (広告)',
                        zh: '取色器（广告）',
                      ),
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Column(
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
                          final newColor =
                              Colors.primaries[_random.nextInt(
                                Colors.primaries.length,
                              )];
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
                          '#${widget.targetColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
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
                            side: BorderSide(
                              color: Color(0xFF888888),
                              width: 1.5,
                            ),
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
        ],
      ),
    );
  }
}
