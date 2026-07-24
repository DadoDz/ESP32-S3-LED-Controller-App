import 'package:flutter/material.dart';

class RgbSlider extends StatelessWidget {
  final String label;
  final int value;
  final Color trackColor;
  final ValueChanged<int> onChanged;
  final ValueChanged<int>? onChangeEnd;

  const RgbSlider({
    super.key,
    required this.label,
    required this.value,
    required this.trackColor,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              '$value',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            activeTrackColor: trackColor,
            inactiveTrackColor: trackColor.withOpacity(0.15),
            thumbColor: trackColor,
            overlayColor: trackColor.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            onChanged: (v) => onChanged(v.round()),
            onChangeEnd: onChangeEnd == null ? null : (v) => onChangeEnd!(v.round()),
          ),
        ),
      ],
    );
  }
}
