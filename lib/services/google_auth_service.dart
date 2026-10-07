import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api.dart';

class GoogleLoginException implements Exception {
  const GoogleLoginException(this.message);

  final String message;
}

/// Exchanges Google's identity token for the same app session as password login.
class GoogleAuthService {
  GoogleAuthService({
    Dio? client,
    GoogleSignIn? googleSignIn,
    this.webClientId = const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
    this.iosClientId = const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
  })  : _client = client ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            )),
        _googleSignIn = googleSignIn;

  final Dio _client;
  final String webClientId;
  final String iosClientId;
  GoogleSignIn? _googleSignIn;

  static bool _validClientId(String value) =>
      RegExp(r'^[a-zA-Z0-9-]+\.apps\.googleusercontent\.com$').hasMatch(value);

  void _checkConfiguration() {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      throw const GoogleLoginException(
          'Login Google tersedia di aplikasi Android dan iOS.');
    }
    if (!_validClientId(webClientId) ||
        (defaultTargetPlatform == TargetPlatform.iOS &&
            !_validClientId(iosClientId))) {
      throw const GoogleLoginException(
          'Login Google belum dikonfigurasi. Silakan gunakan username dan password.');
    }
  }

  /// Returns false when the user dismisses the Google account picker.
  Future<bool> signIn() async {
    _checkConfiguration();
    final google = _googleSignIn ??= GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: webClientId,
      clientId:
          defaultTargetPlatform == TargetPlatform.iOS ? iosClientId : null,
    );

    try {
      final account = await google.signIn();
      if (account == null) return false;

      final idToken = (await account.authentication).idToken;
      if (idToken == null || idToken.trim().isEmpty) {
        throw const GoogleLoginException(
            'Identitas Google belum dapat diverifikasi. Silakan coba lagi.');
      }

      final response = await _client.post<dynamic>(
        '$baseUrl/api/auth/google',
        data: {'idToken': idToken},
      );
      final data = response.data;
      final token = data is Map ? data['token'] : null;
      if (token is! String || token.trim().isEmpty) {
        throw const GoogleLoginException(
            'Respons login dari server tidak valid. Silakan coba lagi.');
      }

      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString('token', token)) {
        throw const GoogleLoginException(
            'Sesi login belum dapat disimpan. Silakan coba lagi.');
      }
      return true;
    } on PlatformException catch (error) {
      if (error.code == GoogleSignIn.kSignInCanceledError) return false;
      // Do not log credentials or the HTTP request containing Google's token.
      developer.log('Google sign-in failed: ${error.code}',
          name: 'GoogleAuthService');
      throw GoogleLoginException(
        error.code == GoogleSignIn.kNetworkError
            ? 'Tidak dapat terhubung ke Google. Periksa koneksi internet Anda.'
            : 'Tidak dapat masuk dengan Google. Silakan coba lagi atau gunakan username dan password.',
      );
    } on DioException catch (error) {
      developer.log(
          'Google token exchange failed: ${error.type.name}, status ${error.response?.statusCode}',
          name: 'GoogleAuthService');
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) {
        throw const GoogleLoginException(
            'Akun Google belum dapat diverifikasi. Silakan masuk kembali.');
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        throw const GoogleLoginException(
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
      }
      throw const GoogleLoginException(
          'Layanan login Google belum tersedia. Silakan coba lagi nanti.');
    } finally {
      // The backend JWT owns the app session. Clear the SDK account so a later
      // login (including after logout) lets the user choose another account.
      try {
        await google.signOut();
      } catch (_) {
        developer.log('Could not clear Google SDK session',
            name: 'GoogleAuthService');
      }
    }
  }
}
