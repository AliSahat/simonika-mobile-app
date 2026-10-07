import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simonika_mobile_app/services/google_auth_service.dart';

class _Authentication extends Fake implements GoogleSignInAuthentication {
  _Authentication(this.idToken);
  @override
  final String? idToken;
}

class _Account extends Fake implements GoogleSignInAccount {
  _Account(this.token);
  final String? token;
  @override
  Future<GoogleSignInAuthentication> get authentication async =>
      _Authentication(token);
}

class _GoogleSignIn extends Fake implements GoogleSignIn {
  GoogleSignInAccount? account = _Account('google-id-token');
  PlatformException? error;
  bool failSignOut = false;
  int signInCalls = 0;
  int signOutCalls = 0;

  @override
  Future<GoogleSignInAccount?> signIn() async {
    signInCalls++;
    if (error != null) throw error!;
    return account;
  }

  @override
  Future<GoogleSignInAccount?> signOut() async {
    signOutCalls++;
    if (failSignOut) throw PlatformException(code: 'sign_out_failed');
    return null;
  }
}

class _Adapter implements HttpClientAdapter {
  Object? body = {'token': 'app-session-token'};
  int status = 200;
  DioExceptionType? errorType;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    requests.add(options);
    if (errorType != null) {
      throw DioException(requestOptions: options, type: errorType!);
    }
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _GoogleSignIn google;
  late _Adapter adapter;
  late GoogleAuthService service;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues({});
    google = _GoogleSignIn();
    adapter = _Adapter();
    service = GoogleAuthService(
      client: Dio()..httpClientAdapter = adapter,
      googleSignIn: google,
      webClientId: '123-web.apps.googleusercontent.com',
    );
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('sends backend idToken contract and persists only the app token',
      () async {
    expect(await service.signIn(), isTrue);
    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.uri.path, '/api/auth/google');
    expect(request.data, {'idToken': 'google-id-token'});
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), {'token'});
    expect(prefs.getString('token'), 'app-session-token');
    expect(google.signOutCalls, 1);
  });

  test('cancellation never sends a token or changes the existing session',
      () async {
    SharedPreferences.setMockInitialValues({'token': 'existing-session'});
    google.account = null;
    expect(await service.signIn(), isFalse);
    expect(adapter.requests, isEmpty);
    expect((await SharedPreferences.getInstance()).getString('token'),
        'existing-session');
  });

  test('platform cancellation is treated as cancellation', () async {
    google.error = PlatformException(code: GoogleSignIn.kSignInCanceledError);
    expect(await service.signIn(), isFalse);
    expect(adapter.requests, isEmpty);
  });

  test('missing Google token cannot create an app session', () async {
    google.account = _Account(null);
    await expectLater(service.signIn(), throwsA(isA<GoogleLoginException>()));
    expect(adapter.requests, isEmpty);
    expect(
        (await SharedPreferences.getInstance()).containsKey('token'), isFalse);
    expect(google.signOutCalls, 1);
  });

  for (final body in [
    <String, dynamic>{},
    {'token': null},
    {'token': ''},
    {'token': '   '},
    {'token': 123},
    ['unexpected'],
    'unexpected',
  ]) {
    test('invalid backend response $body preserves the current session',
        () async {
      SharedPreferences.setMockInitialValues({'token': 'existing-session'});
      adapter.body = body;
      await expectLater(service.signIn(), throwsA(isA<GoogleLoginException>()));
      expect((await SharedPreferences.getInstance()).getString('token'),
          'existing-session');
      expect(google.signOutCalls, 1);
    });
  }

  for (final status in [401, 403, 404, 500]) {
    test('HTTP $status cannot create a session and clears the Google account',
        () async {
      adapter.status = status;
      await expectLater(service.signIn(), throwsA(isA<GoogleLoginException>()));
      expect((await SharedPreferences.getInstance()).containsKey('token'),
          isFalse);
      expect(google.signOutCalls, 1);
    });
  }

  test('network timeout gives a connection message without saving a session',
      () async {
    adapter.errorType = DioExceptionType.connectionTimeout;
    await expectLater(
        service.signIn(),
        throwsA(isA<GoogleLoginException>().having((error) => error.message,
            'message', contains('koneksi internet'))));
    expect(
        (await SharedPreferences.getInstance()).containsKey('token'), isFalse);
  });

  test('cleanup failure does not discard a successful backend session',
      () async {
    google.failSignOut = true;
    expect(await service.signIn(), isTrue);
    expect((await SharedPreferences.getInstance()).getString('token'),
        'app-session-token');
  });

  test('missing configuration fails before opening the account picker',
      () async {
    final unconfigured = GoogleAuthService(
        googleSignIn: google, webClientId: '', iosClientId: '');
    await expectLater(
        unconfigured.signIn(), throwsA(isA<GoogleLoginException>()));
    expect(google.signInCalls, 0);
  });

  test('iOS requires its own client ID in addition to the server client ID',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final iosService = GoogleAuthService(
      googleSignIn: google,
      webClientId: '123-web.apps.googleusercontent.com',
      iosClientId: '',
    );
    await expectLater(
        iosService.signIn(), throwsA(isA<GoogleLoginException>()));
    expect(google.signInCalls, 0);
  });

  test('unsupported platforms fail without invoking the plugin', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await expectLater(service.signIn(), throwsA(isA<GoogleLoginException>()));
    expect(google.signInCalls, 0);
  });
}
