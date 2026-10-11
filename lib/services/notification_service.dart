import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api.dart';
import '../models/water_alert.dart';

class NotificationService extends ChangeNotifier {
  NotificationService({Dio? client, DateTime Function()? clock})
      : _client = client ??
            Dio(BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10))),
        _clock = clock ?? DateTime.now;

  static final instance = NotificationService();
  final Dio _client;
  final DateTime Function() _clock;
  final WaterAlertDetector _detector = WaterAlertDetector();
  final List<WaterAlert> _items = [];
  final Set<WaterAlertKind> _enabled = WaterAlertKind.values.toSet();
  Timer? _timer;
  CancelToken? _cancelToken;
  Future<void>? _refreshing;
  Future<void>? _writes;
  String? _token;
  String? _owner;
  int _generation = 0;
  bool _disposed = false;
  String? error;
  DateTime? lastChecked;
  WaterAlert? latestAlert;

  List<WaterAlert> get items => List.unmodifiable(_items);
  int get unreadCount => _items.where((item) => !item.isRead).length;
  bool get loading => _refreshing != null;
  bool enabled(WaterAlertKind kind) => _enabled.contains(kind);

  Future<void> start() async {
    _timer?.cancel();
    final generation = _generation;
    await refresh();
    if (_current(generation) && _token != null) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    }
  }

  void pause() {
    _cancelRefresh();
    _notify();
  }

  void _cancelRefresh() {
    _timer?.cancel();
    _timer = null;
    _generation++;
    _cancelToken?.cancel();
    _refreshing = null;
  }

  void stop() {
    _cancelRefresh();
    _clearSession();
    _notify();
  }

  void _clearSession() {
    _items.clear();
    _detector.states.clear();
    _enabled
      ..clear()
      ..addAll(WaterAlertKind.values);
    _token = null;
    _owner = null;
    lastChecked = null;
    latestAlert = null;
    error = null;
  }

  Future<void> refresh() {
    if (_disposed) return Future.value();
    if (_refreshing != null) return _refreshing!;
    final generation = _generation;
    final future = _fetch(generation);
    _refreshing = future;
    _notify();
    return future.whenComplete(() {
      if (_generation == generation && !_disposed) {
        _refreshing = null;
        _notify();
      }
    });
  }

  Future<void> _fetch(int generation) async {
    final cancel = CancelToken();
    _cancelToken = cancel;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!_current(generation)) return;
      final token = prefs.getString('token');
      if (token != _token) {
        _clearSession();
        _notify();
      }
      if (token == null) {
        error = 'Silakan masuk untuk melihat notifikasi.';
        return;
      }
      _token = token;
      final options = Options(headers: {'Authorization': 'Bearer $token'});
      bool valid() => _current(generation) && prefs.getString('token') == token;
      if (_owner == null) {
        final profile = await _client.get('$baseUrl/api/auth/profile',
            options: options, cancelToken: cancel);
        if (!valid()) return;
        final owner = profile.data['user']['id']?.toString();
        if (owner == null || owner.isEmpty) throw StateError('Missing user ID');
        // Only use a server-authenticated user ID to isolate local history.
        if (_writes != null) await _writes;
        if (!valid()) return;
        _owner = owner;
        _restore(prefs.getString('water-alerts-v1-$owner'));
      }
      final response = await _client.get('$baseUrl/api/pool',
          options: options, cancelToken: cancel);
      if (!valid()) return;
      if (response.data['success'] != true || response.data['data'] is! List) {
        throw StateError('Invalid pool response');
      }
      final pools = (response.data['data'] as List)
          .map((pool) => Map<String, dynamic>.from(pool as Map))
          .toList();
      final readingsByPool =
          <({Map<String, dynamic> pool, Map<String, dynamic>? reading})>[];
      var failures = 0;
      // Bound concurrency to avoid one request per pool flooding the server.
      for (var offset = 0; offset < pools.length; offset += 4) {
        await Future.wait(pools.skip(offset).take(4).map((pool) async {
          if (pool['isActive'] == false) return;
          try {
            final water = await _client.get('$baseUrl/api/water/level',
                queryParameters: {'poolId': pool['_id'], 'limit': 1},
                options: options,
                cancelToken: cancel);
            if (!valid()) return;
            if (water.data['success'] != true || water.data['data'] is! List) {
              throw StateError('Invalid sensor response');
            }
            final readings = water.data['data'] as List;
            final reading = readings.isEmpty
                ? null
                : Map<String, dynamic>.from(readings.first as Map);
            readingsByPool.add((pool: pool, reading: reading));
          } on DioException catch (exception) {
            if (exception.response?.statusCode == 401) rethrow;
            failures++;
          } catch (_) {
            failures++;
          }
        }));
        if (!valid()) return;
      }
      if (!valid()) return;
      // Commit only after all requests finish. A cancelled poll must not consume
      // condition transitions that would suppress alerts on the next poll.
      final ids = pools
          .where((pool) => pool['isActive'] != false)
          .map((pool) => '${pool['_id']}')
          .toSet();
      _detector.states.removeWhere((id, _) => !ids.contains(id));
      final checkedAt = _clock();
      for (final result in readingsByPool) {
        final alerts =
            _detector.evaluate(result.pool, result.reading, checkedAt);
        final newAlerts = alerts.where((alert) => enabled(alert.kind)).toList();
        _items.insertAll(0, newAlerts);
        if (newAlerts.isNotEmpty) latestAlert = newAlerts.last;
      }
      _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (_items.length > 100) _items.removeRange(100, _items.length);
      error = failures == 0
          ? null
          : '$failures wadah belum dapat diperiksa. Periksa koneksi dan coba lagi.';
      if (failures == 0) lastChecked = _clock();
      await _save();
    } on DioException catch (exception) {
      if (!_current(generation) || CancelToken.isCancel(exception)) return;
      if (exception.response?.statusCode == 401) {
        _clearSession();
        error = 'Sesi berakhir. Silakan masuk kembali.';
      } else {
        error =
            'Notifikasi belum dapat diperbarui. Periksa koneksi dan coba lagi.';
      }
    } catch (_) {
      if (_current(generation)) {
        error = 'Notifikasi belum dapat diperbarui. Silakan coba lagi.';
      }
    }
  }

  bool _current(int generation) => !_disposed && generation == _generation;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _restore(String? raw) {
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map;
      final items = (data['items'] as List)
          .map((item) =>
              WaterAlert.fromJson(Map<String, dynamic>.from(item as Map)))
          .take(100)
          .toList();
      final states = Map<String, dynamic>.from(data['states'] as Map);
      final enabled = (data['enabled'] as List)
          .map((name) => WaterAlertKind.values.byName(name as String))
          .toSet();
      _items.addAll(items);
      _detector.states.addAll(states.map((key, value) =>
          MapEntry(key, Map<String, dynamic>.from(value as Map))));
      _enabled
        ..clear()
        ..addAll(enabled);
    } catch (_) {
      // A corrupt cache must not prevent fresh alerts from being evaluated.
      _items.clear();
      _detector.states.clear();
    }
  }

  Future<void> _save() {
    final owner = _owner;
    if (owner == null) return Future.value();
    final snapshot = jsonEncode({
      'items': _items.map((item) => item.toJson()).toList(),
      'states': _detector.states,
      'enabled': _enabled.map((kind) => kind.name).toList(),
    });
    _writes = (_writes ?? Future<void>.value()).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString('water-alerts-v1-$owner', snapshot)) {
        throw StateError('Storage write failed');
      }
    }).catchError((Object _) {
      if (_owner == owner && !_disposed) {
        error = 'Perubahan belum tersimpan di perangkat. Coba lagi.';
        _notify();
      }
    });
    return _writes!;
  }

  Future<void> markRead(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0 || _items[index].isRead) return;
    _items[index] = _items[index].read();
    _notify();
    await _save();
  }

  Future<void> markAllRead() async {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].read();
    }
    _notify();
    await _save();
  }

  Future<void> setEnabled(WaterAlertKind kind, bool value) async {
    value ? _enabled.add(kind) : _enabled.remove(kind);
    _notify();
    await _save();
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    super.dispose();
  }
}
