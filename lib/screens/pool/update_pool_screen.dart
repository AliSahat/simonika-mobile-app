import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api.dart';
import '../../models/pool_configuration.dart';
import 'widgets/pool_configuration_form.dart';

class UpdatePoolScreen extends StatefulWidget {
  const UpdatePoolScreen({super.key, this.client});
  final Dio? client;

  @override
  State<UpdatePoolScreen> createState() => _UpdatePoolScreenState();
}

class _UpdatePoolScreenState extends State<UpdatePoolScreen> {
  final _formKey = GlobalKey<FormState>();
  final fields = PoolConfigurationControllers();
  late final Dio _dio = widget.client ?? Dio();
  String? poolId;
  String? _loadError;
  bool _initialized = false;
  bool _loadingData = true;
  bool _saving = false;
  bool _publishing = false;
  bool _saved = false;
  bool _publishFailed = false;
  bool _configurationIncomplete = false;
  bool isActive = false;
  bool? modeAuto;
  final _cancelToken = CancelToken();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final argument = ModalRoute.of(context)?.settings.arguments;
    if (argument is String && argument.isNotEmpty) {
      poolId = argument;
      _fetchPoolData();
    } else {
      _loadingData = false;
      _loadError = 'ID wadah tidak ditemukan.';
    }
  }

  @override
  void dispose() {
    _cancelToken.cancel();
    fields.dispose();
    super.dispose();
  }

  Future<String> _token() async {
    final token = (await SharedPreferences.getInstance()).getString('token');
    if (token == null) throw StateError('Sesi berakhir');
    return token;
  }

  Future<void> _fetchPoolData() async {
    setState(() {
      _loadingData = true;
      _loadError = null;
    });
    try {
      final response = await _dio.get('$baseUrl/api/pool/$poolId',
          cancelToken: _cancelToken,
          options:
              Options(headers: {'Authorization': 'Bearer ${await _token()}'}));
      if (response.data is! Map || response.data['data'] is! Map) {
        throw const FormatException('Envelope detail wadah tidak dikenali');
      }
      final data = Map<String, dynamic>.from(response.data['data']);
      if (!mounted) return;
      fields.load(data);
      setState(() {
        isActive = data['isActive'] == true;
        modeAuto = data['modeAuto'] is bool ? data['modeAuto'] as bool : null;
        _configurationIncomplete =
            !fields.isComplete || data['modeAuto'] is! bool;
        _loadingData = false;
      });
    } catch (error) {
      if (error is DioException && error.type == DioExceptionType.cancel) return;
      debugPrint('Error fetch pool data: $error');
      if (mounted) {
        setState(() {
          _loadingData = false;
          _loadError = 'Data wadah belum dapat dimuat. Silakan coba lagi.';
        });
      }
    }
  }

  Future<void> updatePool() async {
    if (_saving ||
        _publishing ||
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (modeAuto == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pilih status mode otomatis sebelum menyimpan.')));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final response = await _dio.put('$baseUrl/api/pool/$poolId',
          data: fields.payload(modeAuto: modeAuto!, isActive: isActive),
          cancelToken: _cancelToken,
          options:
              Options(headers: {'Authorization': 'Bearer ${await _token()}'}));
      if (response.data is Map && response.data['success'] != true) {
        throw StateError('Penyimpanan ditolak');
      }
      if (!mounted) return;
      setState(() {
        _saved = true;
        _publishFailed = false; // Reset failure state on new save
        _configurationIncomplete = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Konfigurasi tersimpan. Belum diklaim diterapkan perangkat.')));
    } catch (error) {
      if (error is DioException && error.type == DioExceptionType.cancel) return;
      debugPrint('Error update pool: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Konfigurasi belum dapat disimpan. Silakan coba lagi.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> sendConfiguration() async {
    if (!_saved || _saving || _publishing || poolId == null) return;
    setState(() {
      _publishing = true;
      _publishFailed = false;
    });
    try {
      final response = await _dio.post('$baseUrl/api/mqtt/publish',
          data: {'poolId': poolId},
          cancelToken: _cancelToken,
          options:
              Options(headers: {'Authorization': 'Bearer ${await _token()}'}));
      if (response.data is Map && response.data['success'] != true) {
        throw StateError('Publish ditolak');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Konfigurasi berhasil dikirim ke broker. Penerapan oleh perangkat belum terkonfirmasi.')));
    } catch (error) {
      if (error is DioException && error.type == DioExceptionType.cancel) return;
      debugPrint('[MQTT DEBUG] Error publish configuration: $error');
      if (error is DioException) {
        debugPrint('[MQTT DEBUG] URL: ${error.requestOptions.uri}');
        debugPrint('[MQTT DEBUG] HTTP Status: ${error.response?.statusCode}');
        debugPrint('[MQTT DEBUG] Response Body: ${error.response?.data}');
      }
      if (mounted) {
        setState(() => _publishFailed = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text(
              'Konfigurasi sudah tersimpan, tetapi belum berhasil dikirim. Anda dapat mencoba lagi.'),
          action: SnackBarAction(
              label: 'Kirim ulang', onPressed: sendConfiguration),
        ));
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = ColorScheme.fromSeed(
        seedColor: const Color(0xFF0878DE),
        brightness: dark ? Brightness.dark : Brightness.light);
    return Theme(
      data: Theme.of(context).copyWith(colorScheme: colors),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
          Navigator.of(context).pop(_publishFailed ? {'retryPublish': true, 'poolId': poolId} : null);
        },
        child: Scaffold(
          backgroundColor: dark ? colors.surface : const Color(0xFFF5F9FE),
          appBar: AppBar(
            title: const Text('Edit wadah',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            backgroundColor: dark ? colors.surface : const Color(0xFFF5F9FE),
            surfaceTintColor: Colors.transparent,
          ),
          body: _body(colors),
          bottomNavigationBar:
              _loadingData || _loadError != null ? null : _actions(),
        ),
      ),
    );
  }

  Widget _body(ColorScheme colors) {
    if (_loadingData) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_loadError!),
          const SizedBox(height: 12),
          FilledButton.tonal(
              onPressed: _fetchPoolData, child: const Text('Coba lagi')),
        ]),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Form(
          key: _formKey,
          onChanged: () {
            if (_saved) setState(() => _saved = false);
          },
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              if (_configurationIncomplete) ...[
                Material(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                        'Konfigurasi wadah lama belum lengkap. Lengkapi semua nilai; aplikasi tidak mengisi ambang otomatis.',
                        style: TextStyle(color: colors.onErrorContainer)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              PoolConfigurationForm(
                fields: fields,
                enabled: !_saving && !_publishing,
                modeAuto: modeAuto,
                onModeAutoChanged: (value) => setState(() {
                  modeAuto = value;
                  _saved = false;
                }),
              ),
              const SizedBox(height: 16),
              Card(
                child: SwitchListTile.adaptive(
                  title: Text(isActive ? 'Wadah aktif' : 'Wadah nonaktif'),
                  value: isActive,
                  onChanged: _saving || _publishing
                      ? null
                      : (value) => setState(() {
                            isActive = value;
                            _saved = false;
                          }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions() => SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Row(children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving || _publishing ? null : updatePool,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Menyimpan…' : 'Simpan'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saved && !_publishing ? sendConfiguration : null,
                  icon: _publishing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_outlined),
                  label: Text(_publishing ? 'Mengirim…' : 'Kirim ke broker'),
                ),
              ),
            ]),
          ),
        ),
      );
}
