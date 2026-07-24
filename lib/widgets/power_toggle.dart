import 'package:flutter/material.dart';

class PowerToggle extends StatelessWidget {
  final bool power;
  final ValueChanged<bool> onChanged;

  const PowerToggle({super.key, required this.power, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final color = power ? const Color(0xFF34D399) : Colors.white24;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: power
                  ? [BoxShadow(color: color.withOpacity(0.7), blurRadius: 10, spreadRadius: 2)]
                  : [],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LED Power',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  power ? 'ON' : 'OFF',
                  style: TextStyle(
                    color: power ? const Color(0xFF34D399) : Colors.white38,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: power,
            onChanged: onChanged,
            activeColor: const Color(0xFF34D399),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }
}
