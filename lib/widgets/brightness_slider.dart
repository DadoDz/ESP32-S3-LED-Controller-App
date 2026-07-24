import 'package:flutter/material.dart';

class BrightnessSlider extends StatelessWidget {
  final int value; // 0-100
  final ValueChanged<int> onChanged;
  final ValueChanged<int>? onChangeEnd;

  const BrightnessSlider({
    super.key,
    required this.value,
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
            const Row(
              children: [
                Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 18),
                SizedBox(width: 8),
                Text(
                  'Brightness',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Text(
              '$value%',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            activeTrackColor: Colors.amber,
            inactiveTrackColor: Colors.amber.withOpacity(0.15),
            thumbColor: Colors.amber,
            overlayColor: Colors.amber.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 100,
            onChanged: (v) => onChanged(v.round()),
            onChangeEnd: onChangeEnd == null ? null : (v) => onChangeEnd!(v.round()),
          ),
        ),
      ],
    );
  }
}
