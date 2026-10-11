import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simonika_mobile_app/models/water_alert.dart';
import 'package:simonika_mobile_app/services/notification_service.dart';

class AlertAdapter implements HttpClientAdapter {
  final now = DateTime.utc(2026, 10, 10, 12);
  double level = 10;
  bool fail = false;
  bool unauthorized = false;
  bool failPools = false;
  String owner = 'user-a';
  Completer<void>? pending;
  int requests = 0;
  int poolCount = 1;
  bool active = true;
  Completer<void>? lastPoolPending;
  final lastPoolStarted = Completer<void>();
  final started = Completer<void>();

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    requests++;
    if (!started.isCompleted) started.complete();
    if (pending != null) await pending!.future;
    dynamic data;
    var status = unauthorized ? 401 : 200;
    if (options.path.endsWith('/auth/profile')) {
      data = {
        'user': {'id': owner}
      };
    } else if (options.path.endsWith('/api/pool')) {
      if (failPools) status = 500;
      data = {
        'success': true,
        'data': [
          for (var i = 0; i < poolCount; i++)
            {
              '_id': i == 0 ? 'pool-$owner' : 'pool-$owner-$i',
              'namaWadah': 'Tangki utama',
              'isActive': active,
              'kedalaman': 100,
              'batasIsiMulai': 20,
              'batasBuangMulai': 90
            },
        ]
      };
    } else {
      expect(options.queryParameters['limit'], 1);
      expect(options.queryParameters['poolId'], startsWith('pool-$owner'));
      if (options.queryParameters['poolId'] == 'pool-$owner-${poolCount - 1}' &&
          lastPoolPending != null) {
        if (!lastPoolStarted.isCompleted) lastPoolStarted.complete();
        await lastPoolPending!.future;
      }
      if (fail) status = 500;
      data = {
        'success': true,
        'data': [
          {'waterLevel': level, 'createdAt': now.toIso8601String()},
        ]
      };
    }
    return ResponseBody.fromString(jsonEncode(data), status, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late AlertAdapter adapter;
  late NotificationService service;
  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 'token-a'});
    adapter = AlertAdapter();
    service = NotificationService(
        client: Dio()..httpClientAdapter = adapter, clock: () => adapter.now);
  });
  tearDown(() => service.dispose());

  test('Persists read state and deduplication across restarts', () async {
    await service.refresh();
    expect(service.unreadCount, 1);
    await service.markAllRead();
    service.stop();
    await service.refresh();
    expect(service.items, hasLength(1));
    expect(service.unreadCount, 0);
    adapter.level = 50;
    await service.refresh();
    adapter.level = 95;
    await service.refresh();
    expect(service.items, hasLength(2));
    expect(service.unreadCount, 1);
  });

  test('History and preferences are isolated per authenticated account',
      () async {
    await service.refresh();
    await service.setEnabled(WaterAlertKind.high, false);
    adapter.owner = 'user-b';
    adapter.level = 50;
    await (await SharedPreferences.getInstance()).setString('token', 'token-b');
    await service.refresh();
    expect(service.items, isEmpty);
    expect(service.enabled(WaterAlertKind.high), isTrue);
    adapter.owner = 'user-a';
    await (await SharedPreferences.getInstance()).setString('token', 'token-a');
    await service.refresh();
    expect(service.items.single.poolId, 'pool-user-a');
    expect(service.enabled(WaterAlertKind.high), isFalse);
  });

  test('Failed requests are errors, never sensor-offline notifications',
      () async {
    adapter.fail = true;
    await service.refresh();
    expect(service.items, isEmpty);
    expect(service.error, isNotNull);
    expect(service.lastChecked, isNull);
    adapter.fail = false;
    await service.refresh();
    expect(service.error, isNull);
    expect(service.unreadCount, 1);
    adapter.unauthorized = true;
    await service.refresh();
    expect(service.items, isEmpty);
    expect(service.error, contains('Sesi berakhir'));
  });

  test('Disabled categories do not produce notifications and persist',
      () async {
    adapter.level = 50;
    await service.refresh();
    await service.setEnabled(WaterAlertKind.low, false);
    adapter.level = 10;
    await service.refresh();
    expect(service.items, isEmpty);
    service.stop();
    await service.refresh();
    expect(service.enabled(WaterAlertKind.low), isFalse);
    expect(service.items, isEmpty);
  });

  test('Concurrent refreshes share requests; logout discards late responses',
      () async {
    adapter.pending = Completer<void>();
    final first = service.refresh();
    final second = service.refresh();
    await adapter.started.future;
    expect(adapter.requests, 1);
    service.stop();
    await (await SharedPreferences.getInstance()).remove('token');
    adapter.pending!.complete();
    await Future.wait([first, second]);
    expect(service.items, isEmpty);
    expect(service.lastChecked, isNull);
  });

  test('Pause stops periodic requests; resume checks again', () async {
    await service.start();
    final count = adapter.requests;
    service.pause();
    expect(service.loading, isFalse);
    await service.start();
    expect(adapter.requests, greaterThan(count));
    expect(service.items, hasLength(1));
    service.stop();
  });

  test('Cancelled multi-batch checks do not publish or consume alerts',
      () async {
    adapter.poolCount = 5;
    adapter.lastPoolPending = Completer<void>();
    final refresh = service.refresh();
    await adapter.lastPoolStarted.future;
    expect(service.items, isEmpty);
    expect(service.latestAlert, isNull);
    service.pause();
    adapter.lastPoolPending!.complete();
    await refresh;
    expect(service.items, isEmpty);
    adapter.lastPoolPending = null;
    await service.refresh();
    expect(service.unreadCount, 5);
    service.stop();
    await service.refresh();
    expect(service.unreadCount, 5);
  });

  test('Stopping publishes the cleared badge and loading state', () async {
    await service.refresh();
    final counts = <int>[];
    service.addListener(() => counts.add(service.unreadCount));
    service.stop();
    expect(counts, [0]);
    expect(service.loading, isFalse);
    expect(service.latestAlert, isNull);
  });

  test('Reactivated pools can alert again after an inactive check', () async {
    await service.refresh();
    await service.markAllRead();
    adapter.active = false;
    await service.refresh();
    expect(service.unreadCount, 0);
    adapter.active = true;
    await service.refresh();
    expect(service.unreadCount, 1);
  });
}
