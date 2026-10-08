import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api.dart';

class PoolScreen extends StatefulWidget {
  const PoolScreen({super.key, this.client});

  final Dio? client;

  @override
  State<PoolScreen> createState() => _PoolScreenState();
}

class _PoolScreenState extends State<PoolScreen> {
  List<dynamic> pools = [];
  bool isLoading = true;
  bool _isFetching = false;
  String? _error;
  String _query = '';
  late final Dio _dio;

  @override
  void initState() {
    super.initState();
    _dio = widget.client ??
        Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ));
    fetchPools();
  }

  Future<void> fetchPools() async {
    if (!mounted || _isFetching) return;
    setState(() {
      _isFetching = true;
      isLoading = pools.isEmpty;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        if (mounted)
          setState(() {
            _error = 'Silakan masuk kembali untuk melihat wadah Anda.';
          });
        return;
      }
      final response = await _dio.get(
        '$baseUrl/api/pool',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (mounted)
        setState(() {
          pools = response.data['data'];
        });
    } catch (e) {
      debugPrint('Error fetch pool: $e');
      if (mounted)
        setState(() {
          _error =
              'Wadah belum dapat dimuat. Periksa koneksi Anda dan coba lagi.';
        });
    } finally {
      if (mounted)
        setState(() {
          isLoading = false;
          _isFetching = false;
        });
    }
  }

  Future<void> _createPool() async {
    final result = await Navigator.pushNamed(context, '/create-pool');
    if (result == true && mounted) await fetchPools();
  }

  void goToDetail(String poolId) {
    Navigator.pushNamed(context, '/detail-pool', arguments: poolId);
  }

  Future<void> deletePool(String poolId, String poolName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Konfirmasi Hapus",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text("Apakah Anda yakin ingin menghapus wadah '$poolName'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                "Batal",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Hapus", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      await _dio.delete(
        "$baseUrl/api/pool/$poolId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text("Wadah berhasil dihapus")),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        fetchPools();
      }
    } catch (e) {
      debugPrint("Error delete pool: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text("Gagal menghapus wadah")),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> retryPublish(String poolId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;
      
      final response = await _dio.post('$baseUrl/api/mqtt/publish',
          data: {'poolId': poolId},
          options: Options(headers: {'Authorization': 'Bearer $token'}));
          
      if (response.data is Map && response.data['success'] != true) {
        throw StateError('Publish ditolak');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Konfigurasi berhasil dikirim ke broker. Penerapan oleh perangkat belum terkonfirmasi.')));
    } catch (error) {
      debugPrint('[MQTT DEBUG] Error retry publish: $error');
      if (error is DioException) {
        debugPrint('[MQTT DEBUG] URL: ${error.requestOptions.uri}');
        debugPrint('[MQTT DEBUG] HTTP Status: ${error.response?.statusCode}');
        debugPrint('[MQTT DEBUG] Response Body: ${error.response?.data}');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Konfigurasi sudah tersimpan, tetapi belum berhasil dikirim. Anda dapat mencoba lagi.'),
        action: SnackBarAction(
            label: 'Kirim ulang', onPressed: () => retryPublish(poolId)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = ColorScheme.fromSeed(
        seedColor: const Color(0xFF0878DE),
        brightness: dark ? Brightness.dark : Brightness.light);
    final filtered = pools
        .where((pool) => '${pool['namaWadah'] ?? ''} ${pool['serial'] ?? ''}'
            .toLowerCase()
            .contains(_query.toLowerCase()))
        .toList();
    final active = pools.where((pool) => pool['isActive'] == true).length;
    return Theme(
      data: Theme.of(context).copyWith(colorScheme: colors),
      child: Scaffold(
        backgroundColor: dark ? colors.surface : const Color(0xFFF5F9FE),
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: LayoutBuilder(builder: (context, viewport) {
                final compact = viewport.maxHeight < 640 ||
                    MediaQuery.textScalerOf(context).scale(14) > 22;
                return Column(children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, compact ? 8 : 12, 20, 0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!compact) ...[
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: colors.primaryContainer,
                                    borderRadius: BorderRadius.circular(14)),
                                child: Icon(Icons.water_drop_outlined,
                                    color: colors.onPrimaryContainer, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text('SIMONIKA',
                                        style: TextStyle(
                                            color: colors.primary,
                                            fontSize: 10,
                                            letterSpacing: 1.5,
                                            fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 4),
                                    Semantics(
                                        header: true,
                                        child: Text('Wadah air Anda',
                                            style: TextStyle(
                                                color: colors.onSurface,
                                                fontSize: 22,
                                                letterSpacing: -0.7,
                                                fontWeight: FontWeight.w800))),
                                  ])),
                            ]),
                            const SizedBox(height: 8),
                            Text('Pantau dan kelola wadah air Anda.',
                                style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 13,
                                    height: 1.4)),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF168EED),
                                      Color(0xFF0865B5),
                                      Color(0xFF154675)
                                    ]),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                      color: colors.primary
                                          .withValues(alpha: 0.16),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8))
                                ],
                              ),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(children: [
                                      Icon(Icons.waves_outlined,
                                          color: Colors.white, size: 20),
                                      SizedBox(width: 10),
                                      Expanded(
                                          child: Text('Ringkasan wadah',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600)))
                                    ]),
                                    const SizedBox(height: 10),
                                    LayoutBuilder(
                                        builder: (context, constraints) {
                                      final entries = [
                                        ('Total wadah', pools.length),
                                        ('Aktif', active),
                                        ('Nonaktif', pools.length - active),
                                      ];
                                      final stacked =
                                          MediaQuery.textScalerOf(context)
                                                  .scale(14) >
                                              22;
                                      final items = entries
                                          .map((entry) => Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        isLoading ||
                                                                _error != null
                                                            ? '—'
                                                            : '${entry.$2}',
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 24,
                                                            height: 1.1,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w800)),
                                                    const SizedBox(height: 4),
                                                    Text(entry.$1,
                                                        style: const TextStyle(
                                                            color: Color(
                                                                0xFFE4F2FF),
                                                            fontSize: 12,
                                                            height: 1.5)),
                                                  ]))
                                          .toList();
                                      return stacked
                                          ? Wrap(
                                              spacing: 32,
                                              runSpacing: 20,
                                              children: items)
                                          : Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: items
                                                  .map((item) =>
                                                      Expanded(child: item))
                                                  .toList());
                                    }),
                                  ]),
                            ),
                            const SizedBox(height: 12),
                          ] else ...[
                            Text('Wadah air Anda',
                                style: TextStyle(
                                    color: colors.onSurface,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Text(
                                isLoading || _error != null
                                    ? 'Ringkasan wadah: —'
                                    : '${pools.length} wadah • $active aktif • ${pools.length - active} nonaktif',
                                style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 12,
                                    height: 1.4)),
                            const SizedBox(height: 8),
                          ],
                          LayoutBuilder(builder: (context, constraints) {
                            final title = Semantics(
                                header: true,
                                child: Text('Daftar wadah',
                                    style: TextStyle(
                                        color: colors.onSurface,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)));
                            final heading = Row(children: [
                              Expanded(child: title),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: _isFetching
                                    ? 'Memperbarui wadah'
                                    : 'Perbarui daftar wadah',
                                onPressed: _isFetching ? null : fetchPools,
                                style: IconButton.styleFrom(
                                    minimumSize: const Size(48, 48),
                                    foregroundColor: colors.primary),
                                icon: _isFetching
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: colors.primary))
                                    : const Icon(Icons.refresh_rounded,
                                        size: 22),
                              ),
                            ]);
                            final button = FilledButton.icon(
                              onPressed: _createPool,
                              icon: const Icon(Icons.add_rounded, size: 20),
                              label: const Text('Tambah wadah',
                                  style: TextStyle(fontSize: 12)),
                              style: FilledButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14))),
                            );
                            if (compact) {
                              return Row(children: [
                                Expanded(child: heading),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  tooltip: 'Tambah wadah',
                                  onPressed: _createPool,
                                  icon: const Icon(Icons.add_rounded),
                                  style: IconButton.styleFrom(
                                      minimumSize: const Size(48, 48)),
                                ),
                              ]);
                            }
                            if (constraints.maxWidth < 320 ||
                                MediaQuery.textScalerOf(context).scale(14) >
                                    22) {
                              return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    heading,
                                    const SizedBox(height: 8),
                                    button
                                  ]);
                            }
                            return Row(children: [
                              Expanded(child: heading),
                              const SizedBox(width: 12),
                              button
                            ]);
                          }),
                        ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: TextField(
                      onChanged: (value) =>
                          setState(() => _query = value.trim()),
                      decoration: InputDecoration(
                        labelText: 'Cari wadah',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        hintText: 'Nama wadah atau serial',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: colors.surfaceContainerLowest,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: colors.outlineVariant)),
                      ),
                    ),
                  ),
                  Expanded(
                      child: CustomScrollView(
                    key: const PageStorageKey('pool-list'),
                    slivers: [
                      if (isLoading)
                        SliverToBoxAdapter(
                            child: _stateCard(colors,
                                icon: Icons.water_drop_outlined,
                                title: 'Memuat wadah…',
                                description: 'Menyiapkan data wadah Anda.',
                                loading: true))
                      else if (_error != null)
                        SliverToBoxAdapter(
                            child: _stateCard(colors,
                                icon: Icons.cloud_off_outlined,
                                title: 'Belum dapat menampilkan wadah',
                                description: _error!,
                                action: FilledButton.tonalIcon(
                                    onPressed: fetchPools,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Coba lagi'))))
                      else if (pools.isEmpty)
                        SliverToBoxAdapter(
                            child: _stateCard(colors,
                                icon: Icons.water_drop_outlined,
                                title: 'Mulai dengan wadah pertama',
                                description:
                                    'Tambahkan wadah untuk memantau air dan mengatur kendalinya.'))
                      else if (filtered.isEmpty)
                        SliverToBoxAdapter(
                            child: _stateCard(colors,
                                icon: Icons.search_off_rounded,
                                title: 'Wadah tidak ditemukan',
                                description:
                                    'Coba nama wadah atau serial yang berbeda.'))
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _poolCard(filtered[index], colors)),
                            childCount: filtered.length,
                          )),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  )),
                ]);
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stateCard(ColorScheme colors,
      {required IconData icon,
      required String title,
      required String description,
      bool loading = false,
      Widget? action}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.outlineVariant)),
      child: Column(children: [
        if (loading)
          SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                  color: colors.primary, strokeWidth: 3))
        else
          Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(20)),
              child: Icon(icon, color: colors.onPrimaryContainer, size: 32)),
        const SizedBox(height: 20),
        Text(title,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: colors.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(description,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: colors.onSurfaceVariant, fontSize: 15, height: 1.5)),
        if (action != null) ...[const SizedBox(height: 20), action],
      ]),
    );
  }

  Widget _poolCard(dynamic pool, ColorScheme colors) {
    final active = pool['isActive'] == true;
    final id = '${pool['_id'] ?? ''}';
    final name = '${pool['namaWadah'] ?? 'Wadah air'}';
    final metrics = [
      ('Kedalaman', pool['kedalaman'], Icons.straighten_rounded),
      (
        'Sensor ke dasar',
        pool['jarakSensorDasar'],
        Icons.vertical_align_bottom_rounded
      ),
      ('Mulai isi', pool['batasIsiMulai'], Icons.play_arrow_rounded),
      ('Berhenti isi', pool['batasIsiBerhenti'], Icons.stop_rounded),
      ('Mulai buang', pool['batasBuangMulai'], Icons.upload_rounded),
      ('Berhenti buang', pool['batasBuangBerhenti'], Icons.download_rounded),
    ];
    final configurationComplete = [
      'kedalaman',
      'jarakSensorDasar',
      'batasIsiMulai',
      'batasIsiBerhenti',
      'batasBuangMulai',
      'batasBuangBerhenti',
      'modeAuto',
    ].every((key) => pool[key] != null);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: colors.outlineVariant.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
                color: colors.shadow.withValues(alpha: 0.035),
                blurRadius: 20,
                offset: const Offset(0, 6))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.water_drop_outlined,
                  color: colors.onPrimaryContainer, size: 24)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(name,
                    style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        height: 1.3)),
                const SizedBox(height: 6),
                Text('Serial: ${pool['serial'] ?? '—'}',
                    style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.5)),
              ])),
          PopupMenuButton<String>(
            tooltip: 'Opsi wadah $name',
            onSelected: (value) async {
              if (value == 'delete') {
                await deletePool(id, name);
              } else {
                final result = await Navigator.pushNamed(context, '/update-pool', arguments: id);
                if (mounted) {
                  await fetchPools();
                  if (result is Map && result['retryPublish'] == true) {
                    final currentPoolId = result['poolId'] as String;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Konfigurasi sudah tersimpan, tetapi belum berhasil dikirim. Anda dapat mencoba lagi.'),
                      action: SnackBarAction(
                          label: 'Kirim ulang', onPressed: () => retryPublish(currentPoolId)),
                    ));
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit wadah'))),
              PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.delete_outline_rounded,
                          color: colors.error),
                      title: Text('Hapus wadah',
                          style: TextStyle(color: colors.error)))),
            ],
            icon:
                Icon(Icons.more_horiz_rounded, color: colors.onSurfaceVariant),
          ),
        ]),
        const SizedBox(height: 16),
        if (!configurationComplete) ...[
          Material(
            color: colors.errorContainer,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Konfigurasi belum lengkap • buka Edit wadah',
                  style: TextStyle(color: colors.onErrorContainer)),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: active
                      ? colors.primaryContainer
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                    active
                        ? Icons.check_circle_outline_rounded
                        : Icons.pause_circle_outline_rounded,
                    size: 16,
                    color: active
                        ? colors.onPrimaryContainer
                        : colors.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(active ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(
                        color: active
                            ? colors.onPrimaryContainer
                            : colors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]),
            )),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (context, constraints) {
          final single = constraints.maxWidth < 260 ||
              MediaQuery.textScalerOf(context).scale(14) > 22;
          final width =
              single ? constraints.maxWidth : (constraints.maxWidth - 12) / 2;
          return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: metrics
                  .map((metric) => SizedBox(
                      width: width,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: colors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(metric.$3, color: colors.primary, size: 20),
                              const SizedBox(height: 10),
                              Text(metric.$1,
                                  style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                  '${metric.$2 ?? '—'}${metric.$2 == null ? '' : ' cm'}',
                                  style: TextStyle(
                                      color: colors.onSurface,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                            ]),
                      )))
                  .toList());
        }),
        const SizedBox(height: 16),
        FilledButton.tonal(
          onPressed: () => goToDetail(id),
          style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14))),
          child: const Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              children: [
                Icon(Icons.insights_outlined, size: 20),
                Text('Monitor wadah',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                Icon(Icons.arrow_forward_rounded, size: 18)
              ]),
        ),
      ]),
    );
  }
}
