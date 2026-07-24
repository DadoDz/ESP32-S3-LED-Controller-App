import 'package:flutter/material.dart';
import '../models/led_state.dart';

class ColorPreview extends StatelessWidget {
  final LedState state;

  const ColorPreview({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final color = state.power ? state.displayColor : Colors.grey.shade800;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'CURRENT COLOR',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: state.power
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.55),
                        blurRadius: 40,
                        spreadRadius: 6,
                      ),
                    ]
                  : [],
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'RGB: ${state.red}, ${state.green}, ${state.blue}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Brightness: ${state.brightness}%',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
