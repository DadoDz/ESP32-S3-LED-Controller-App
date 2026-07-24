import 'package:flutter/material.dart';

// Represents the full state of the RGB LED as stored in Firebase
// under the `/led` path.
@immutable
class LedState {
  final bool power;
  final int red;
  final int green;
  final int blue;
  final int brightness; // 0 - 100

  const LedState({
    this.power = false,
    this.red = 255,
    this.green = 0,
    this.blue = 0,
    this.brightness = 100,
  });

  // Build a LedState from a Firebase snapshot map.
  factory LedState.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const LedState();
    return LedState(
      power: map['power'] is bool ? map['power'] as bool : (map['power'] == 1),
      red: _asInt(map['red'], 255),
      green: _asInt(map['green'], 0),
      blue: _asInt(map['blue'], 0),
      brightness: _asInt(map['brightness'], 100),
    );
  }

  static int _asInt(dynamic value, int fallback) {
    if (value is int) return value.clamp(0, 255);
    if (value is double) return value.round().clamp(0, 255);
    return fallback;
  }

  Map<String, dynamic> toMap() => {
        'power': power,
        'red': red,
        'green': green,
        'blue': blue,
        'brightness': brightness,
      };

  // The raw RGB color, ignoring brightness.
  Color get rawColor => Color.fromARGB(255, red, green, blue);

  Color get displayColor {
    final factor = brightness / 100.0;
    return Color.fromARGB(
      255,
      (red * factor).round(),
      (green * factor).round(),
      (blue * factor).round(),
    );
  }

  LedState copyWith({
    bool? power,
    int? red,
    int? green,
    int? blue,
    int? brightness,
  }) {
    return LedState(
      power: power ?? this.power,
      red: red ?? this.red,
      green: green ?? this.green,
      blue: blue ?? this.blue,
      brightness: brightness ?? this.brightness,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedState &&
          power == other.power &&
          red == other.red &&
          green == other.green &&
          blue == other.blue &&
          brightness == other.brightness;

  @override
  int get hashCode => Object.hash(power, red, green, blue, brightness);
}
