import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/led_state.dart';
import '../services/led_service.dart';
import '../widgets/color_preview.dart';
import '../widgets/power_toggle.dart';
import '../widgets/random_color_button.dart';
import '../widgets/rgb_slider.dart';
import '../widgets/brightness_slider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LedService _service = LedService();
  final Random _random = Random();

  LedState _state = const LedState();
  StreamSubscription<LedState>? _subscription;
  bool _loading = true;
  String? _error;
  bool _offline = false;

  bool _suppressRemoteWhileDragging = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
      _offline = false;
    });
    try {
      debugPrint('[LED] Connecting to Firebase Realtime Database...');
      await _service.ensureInitialized();
      debugPrint('[LED] ensureInitialized() done, fetching current state...');
      final initial = await _service.fetchOnce();
      debugPrint('[LED] fetchOnce() done: ${initial.toMap()}');
      if (mounted) {
        setState(() {
          _state = initial;
          _loading = false;
        });
      }

      _subscription?.cancel();
      _subscription = _service.watch().listen(
        (remoteState) {
          if (!mounted || _suppressRemoteWhileDragging) return;
          setState(() => _state = remoteState);
        },
        onError: (e) {
          debugPrint('[LED] realtime stream error: $e');
        },
      );
    } on SocketException catch (e) {
      debugPrint('[LED] no network connection: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _offline = true;
        });
      }
    } catch (e, st) {
      debugPrint('[LED] init failed: $e\n$st');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }

  void _setPower(bool value) {
    setState(() => _state = _state.copyWith(power: value));
    _service.updateImmediate({'power': value});
  }

  void _onRandomColor() {
    final newState = _state.copyWith(
      red: _random.nextInt(256),
      green: _random.nextInt(256),
      blue: _random.nextInt(256),
    );
    setState(() => _state = newState);
    _service.updateImmediate({
      'red': newState.red,
      'green': newState.green,
      'blue': newState.blue,
    });
  }

  void _onChannelDrag(String key, int value) {
    _suppressRemoteWhileDragging = true;
    setState(() {
      _state = switch (key) {
        'red' => _state.copyWith(red: value),
        'green' => _state.copyWith(green: value),
        'blue' => _state.copyWith(blue: value),
        _ => _state,
      };
    });
    _service.updateDebounced({key: value});
  }

  void _onChannelDragEnd(int _) {
    _suppressRemoteWhileDragging = false;
    _service.flushPending();
  }

  void _onBrightnessDrag(int value) {
    _suppressRemoteWhileDragging = true;
    setState(() => _state = _state.copyWith(brightness: value));
    _service.updateDebounced({'brightness': value});
  }

  void _onBrightnessDragEnd(int _) {
    _suppressRemoteWhileDragging = false;
    _service.flushPending();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white54))
            : _offline
                ? _buildOfflineState()
                : _error != null
                    ? _buildErrorState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          try {
                            final fresh = await _service.fetchOnce();
                            setState(() {
                              _state = fresh;
                              _offline = false;
                            });
                          } on SocketException {
                            setState(() => _offline = true);
                          }
                        },
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 24),
                            PowerToggle(power: _state.power, onChanged: _setPower),
                            const SizedBox(height: 16),
                            ColorPreview(state: _state),
                            const SizedBox(height: 16),
                            RandomColorButton(onPressed: _onRandomColor),
                            const SizedBox(height: 24),
                            _buildRgbSection(),
                            const SizedBox(height: 16),
                            _buildBrightnessSection(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildOfflineState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D24),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Internet Connection',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Turn on WiFi or mobile data to control your LED.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _init,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            const Text(
              "Couldn't reach Firebase",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _init,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D24),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.developer_board_rounded, color: Color(0xFF6366F1)),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ESP32-S3 LED',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Text(
              'Realtime Database control',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRgbSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RGB Controls',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          RgbSlider(
            label: 'Red',
            value: _state.red,
            trackColor: const Color(0xFFEF4444),
            onChanged: (v) => _onChannelDrag('red', v),
            onChangeEnd: _onChannelDragEnd,
          ),
          RgbSlider(
            label: 'Green',
            value: _state.green,
            trackColor: const Color(0xFF22C55E),
            onChanged: (v) => _onChannelDrag('green', v),
            onChangeEnd: _onChannelDragEnd,
          ),
          RgbSlider(
            label: 'Blue',
            value: _state.blue,
            trackColor: const Color(0xFF3B82F6),
            onChanged: (v) => _onChannelDrag('blue', v),
            onChangeEnd: _onChannelDragEnd,
          ),
        ],
      ),
    );
  }

  Widget _buildBrightnessSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: BrightnessSlider(
        value: _state.brightness,
        onChanged: _onBrightnessDrag,
        onChangeEnd: _onBrightnessDragEnd,
      ),
    );
  }
}
