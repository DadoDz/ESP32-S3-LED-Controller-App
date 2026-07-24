import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/led_state.dart';

class LedService {
  LedService({
    String databaseUrl = '', // The base URL of the Firebase Realtime Database (e.g. https://my-project.firebaseio.com)
    this.debounceDuration = const Duration(milliseconds: 250),
  }) : _base = databaseUrl.endsWith('/') ? '${databaseUrl}led' : '$databaseUrl/led';

  final String _base;
  final Duration debounceDuration;

  Timer? _debounceTimer;
  Map<String, dynamic>? _pendingWrite;

  http.Client? _streamClient;
  StreamController<LedState>? _controller;
  Map<String, dynamic> _liveState = const LedState().toMap();

  Uri get _jsonUri => Uri.parse('$_base.json');
  static const _headers = {'Content-Type': 'application/json'};

  // Live stream of the LED state via Firebase's SSE connection. Emits
  Stream<LedState> watch() {
    _controller?.close();
    _controller = StreamController<LedState>.broadcast(
      onListen: _connectStream,
      onCancel: () => _streamClient?.close(),
    );
    return _controller!.stream;
  }

  Future<void> _connectStream() async {
    _streamClient?.close();
    _streamClient = http.Client();

    try {
      final request = http.Request('GET', _jsonUri)
        ..headers['Accept'] = 'text/event-stream';
      final response = await _streamClient!.send(request);

      if (response.statusCode != 200) {
        _controller?.addError(
          Exception('Realtime stream failed (${response.statusCode})'),
        );
        return;
      }

      String? eventType;
      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (line.startsWith('event: ')) {
          eventType = line.substring(7).trim();
        } else if (line.startsWith('data: ')) {
          _handleSseData(eventType, line.substring(6).trim());
        }
      }
    } catch (e) {
      _controller?.addError(e);
    }
  }

  void _handleSseData(String? eventType, String dataStr) {
    if (eventType != 'put' && eventType != 'patch') return;

    try {
      final decoded = jsonDecode(dataStr);

      if (decoded is! Map<String, dynamic>) return;

      final path = decoded['path'] as String? ?? '/';
      final data = decoded['data'];

      // PUT at root = complete replacement.
      if (eventType == 'put' && path == '/') {
        _liveState = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

        _controller?.add(LedState.fromMap(_liveState));
        return;
      }

      // PATCH at root = merge only changed fields.
      if (eventType == 'patch' && path == '/') {
        if (data is Map) {
          _liveState.addAll(Map<String, dynamic>.from(data));
        }

        _controller?.add(LedState.fromMap(_liveState));
        return;
      }

      // Updates to a specific child, for example:
      // path: "/red"
      // data: 200
      final key = path.replaceFirst('/', '');

      if (data == null) {
        _liveState.remove(key);
      } else {
        _liveState[key] = data;
      }

      _controller?.add(LedState.fromMap(_liveState));
    } catch (e) {
      _controller?.addError(
        Exception('Failed to process Firebase SSE event: $e'),
      );
    }
  }

  // One-shot read, used for the initial load before the stream connects.
  Future<LedState> fetchOnce() async {
    final response = await http.get(_jsonUri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Failed to read /led (${response.statusCode}): ${response.body}');
    }
    final data = response.body == 'null' ? null : jsonDecode(response.body);
    if (data is Map) {
      _liveState = Map<String, dynamic>.from(data);
    }
    return LedState.fromMap(data is Map ? data : null);
  }

  // Ensures the `/led` node exists with sane defaults the first time the
  // app runs against a fresh database.
  Future<void> ensureInitialized() async {
    final response = await http.get(_jsonUri).timeout(const Duration(seconds: 10));
    if (response.body == 'null' || response.body.isEmpty) {
      final defaults = const LedState().toMap();
      await http.put(_jsonUri, headers: _headers, body: jsonEncode(defaults));
      _liveState = defaults;
    }
  }

  // Writes immediately, bypassing any pending debounce.
  Future<void> updateImmediate(Map<String, dynamic> values) async {
    _debounceTimer?.cancel();
    _pendingWrite = null;
    final response =
        await http.patch(_jsonUri, headers: _headers, body: jsonEncode(values));
    if (response.statusCode != 200) {
      throw Exception('Failed to update /led (${response.statusCode}): ${response.body}');
    }
  }

  void updateDebounced(Map<String, dynamic> values) {
    _pendingWrite = {...?_pendingWrite, ...values};
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      final toSend = _pendingWrite;
      _pendingWrite = null;
      if (toSend != null) {
        http.patch(_jsonUri, headers: _headers, body: jsonEncode(toSend));
      }
    });
  }

  Future<void> flushPending() async {
    _debounceTimer?.cancel();
    final toSend = _pendingWrite;
    _pendingWrite = null;
    if (toSend != null) {
      await http.patch(_jsonUri, headers: _headers, body: jsonEncode(toSend));
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
    _streamClient?.close();
    _controller?.close();
  }
}
