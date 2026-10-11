enum WaterAlertKind { low, high, stale }

class WaterAlert {
  const WaterAlert({
    required this.id,
    required this.poolId,
    required this.poolName,
    required this.kind,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String poolId;
  final String poolName;
  final WaterAlertKind kind;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  String get title => switch (kind) {
        WaterAlertKind.low => 'Level air rendah',
        WaterAlertKind.high => 'Level air tinggi',
        WaterAlertKind.stale => 'Data sensor terlambat',
      };

  WaterAlert read() => WaterAlert(
      id: id,
      poolId: poolId,
      poolName: poolName,
      kind: kind,
      message: message,
      createdAt: createdAt,
      isRead: true);

  Map<String, dynamic> toJson() => {
        'id': id,
        'poolId': poolId,
        'poolName': poolName,
        'kind': kind.name,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
      };

  factory WaterAlert.fromJson(Map<String, dynamic> json) => WaterAlert(
      id: json['id'] as String,
      poolId: json['poolId'] as String,
      poolName: json['poolName'] as String,
      kind: WaterAlertKind.values.byName(json['kind'] as String),
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] == true);
}

/// State persists between polls so one condition produces one notification.
class WaterAlertDetector {
  static const staleAfter = Duration(minutes: 5);
  final Map<String, Map<String, dynamic>> states = {};

  List<WaterAlert> evaluate(
      Map<String, dynamic> pool, Map<String, dynamic>? reading, DateTime now) {
    final id = pool['_id']?.toString();
    if (id == null || id.isEmpty || pool['isActive'] == false) return [];
    final state = states.putIfAbsent(id, () => {});
    final name = pool['namaWadah']?.toString() ?? 'Wadah air';
    final time = DateTime.tryParse('${reading?['createdAt']}');
    final origin = time ??
        (reading == null ? DateTime.tryParse('${pool['createdAt']}') : null);
    if (origin == null || origin.isAfter(now.add(const Duration(minutes: 1)))) {
      return [];
    }
    final previousTime = DateTime.tryParse('${state['readingAt']}');
    if (time != null && previousTime != null && time.isBefore(previousTime)) {
      return [];
    }
    final alerts = <WaterAlert>[];
    void emit(WaterAlertKind kind, String message) {
      alerts.add(WaterAlert(
          id: '$id-${kind.name}-${now.microsecondsSinceEpoch}',
          poolId: id,
          poolName: name,
          kind: kind,
          message: message,
          createdAt: now));
    }

    final stale = now.difference(origin) >= staleAfter;
    if (stale && state['stale'] != true) {
      emit(
          WaterAlertKind.stale,
          reading == null
              ? 'Belum ada pembacaan sensor selama 5 menit. Periksa perangkat dan koneksinya.'
              : 'Tidak ada data sensor baru selama 5 menit. Periksa perangkat dan koneksinya.');
    }
    state['stale'] = stale;
    if (stale || time == null) return alerts;

    final level = _number(reading?['waterLevel']);
    final low = _number(pool['batasIsiMulai']);
    final high = _number(pool['batasBuangMulai']);
    final depth = _number(pool['kedalaman']);
    if (level == null ||
        low == null ||
        high == null ||
        depth == null ||
        depth <= 0 ||
        low < 0 ||
        high <= low ||
        high > depth ||
        level < 0) {
      return alerts;
    }
    state['readingAt'] = time.toIso8601String();
    final previous = state['water'];
    // A small recovery margin prevents sensor noise from repeatedly alerting.
    final margin =
        (depth * 0.02).clamp(0.5, double.infinity).clamp(0, (high - low) / 2);
    final String condition;
    if (level <= low) {
      condition = 'low';
    } else if (level >= high) {
      condition = 'high';
    } else if (previous == 'low' && level <= low + margin) {
      condition = 'low';
    } else if (previous == 'high' && level >= high - margin) {
      condition = 'high';
    } else {
      condition = 'normal';
    }
    if (condition != previous) {
      if (condition == 'low') {
        emit(WaterAlertKind.low,
            'Level air ${level.toStringAsFixed(1)} cm mencapai batas rendah ${low.toStringAsFixed(1)} cm. Periksa pengisian wadah.');
      } else if (condition == 'high') {
        emit(WaterAlertKind.high,
            'Level air ${level.toStringAsFixed(1)} cm mencapai batas tinggi ${high.toStringAsFixed(1)} cm. Periksa kondisi wadah.');
      }
    }
    state['water'] = condition;
    return alerts;
  }

  static double? _number(dynamic value) {
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    return number?.isFinite == true ? number : null;
  }
}
