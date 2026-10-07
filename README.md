# SIMONIKA Mobile

Aplikasi Flutter untuk memantau dan mengelola wadah air.

## Login Google (Android dan iOS)

Login Google menukar Google ID token dengan JWT SIMONIKA melalui
`POST /api/auth/google`. Akun baru dibuat oleh backend; aplikasi menyimpan JWT
SIMONIKA dengan kunci `token`, sama seperti login username/password.

Konfigurasi OAuth dan endpoint backend yang sudah di-deploy diperlukan untuk
menguji akun asli. Template konfigurasi sengaja kosong. Tanpa konfigurasi,
aplikasi menampilkan pesan bahwa login Google belum dikonfigurasi.

### 1. Buat OAuth Client ID

Di [Google Cloud Console](https://console.cloud.google.com/auth/clients), pilih
proyek yang sama dengan backend dan lengkapi OAuth consent screen. Tambahkan
akun penguji jika aplikasi masih dalam mode Testing.

- Buat client **Web application**. Gunakan ID ini sebagai `GOOGLE_WEB_CLIENT_ID`
  di aplikasi dan `GOOGLE_CLIENT_ID` di backend; keduanya harus sama.
- Buat client **Android** dengan package `com.example.simonika_mobile_app` dan
  SHA-1 sertifikat yang menandatangani APK. Client ID Android tidak dimasukkan
  ke `serverClientId`; di sana aplikasi memakai Client ID Web.
- Untuk iOS, buat client **iOS** dengan Bundle ID target Runner di Xcode.

Untuk melihat SHA-1 debug:

```bash
cd android
./gradlew signingReport
```

Daftarkan juga sertifikat release/Play App Signing saat mendistribusikan aplikasi.
Jika package Android diubah, perbarui registrasi OAuth-nya.

### 2. Konfigurasi aplikasi

Salin `config/google-auth.example.json` menjadi `config/google-auth.json`, lalu isi:

```json
{
  "GOOGLE_WEB_CLIENT_ID": "123456789-webclient.apps.googleusercontent.com",
  "GOOGLE_IOS_CLIENT_ID": "123456789-iosclient.apps.googleusercontent.com"
}
```

Nilai di atas hanya contoh. `GOOGLE_IOS_CLIENT_ID` boleh kosong untuk Android.
Jangan memasukkan Client Secret, JWT secret, atau kredensial server ke aplikasi.
File konfigurasi lokal diabaikan Git, tetapi Client ID tetap masuk ke build.

```bash
flutter pub get
flutter run --dart-define-from-file=config/google-auth.json
flutter build apk --release --dart-define-from-file=config/google-auth.json
```

Android menggunakan `serverClientId` secara langsung sehingga tidak memerlukan
Firebase atau `google-services.json` untuk alur ini.

Untuk iOS, salin `ios/Flutter/GoogleSignIn.example.xcconfig` menjadi
`ios/Flutter/GoogleSignIn.xcconfig` dan isi reversed Client ID iOS:

```text
GOOGLE_REVERSED_CLIENT_ID = com.googleusercontent.apps.123456789-iosclient
```

Gunakan nilai `REVERSED_CLIENT_ID` milik client iOS Anda, bukan client Web.
`Info.plist` sudah merujuk nilai ini untuk callback Google. Konfigurasi Debug,
Profile, dan Release memakai file tersebut. Jalankan/build iOS di macOS dengan
`--dart-define-from-file=config/google-auth.json` yang sama.

Alur tombol ini ditujukan untuk Android/iOS. Web dan desktop menampilkan pesan
platform belum didukung. Flutter web memerlukan tombol Google Identity Services
khusus agar memperoleh ID token, bukan pemanggilan mobile `signIn()`.

### 3. Kontrak backend

Backend SIMONIKA harus menyediakan:

```http
POST /api/auth/google
Content-Type: application/json

{"idToken":"<google-id-token>"}
```

Respons sukses:

```json
{"token":"<jwt-simonika>","user":{"id":"...","name":"...","username":"..."}}
```

Nama field permintaan adalah **`idToken`**, sesuai endpoint backend, bukan
`id_token`. Backend harus memverifikasi tanda tangan, masa berlaku, audience
(`GOOGLE_CLIENT_ID`), dan email terverifikasi sebelum membuat sesi. JWT backend
itulah yang dipakai endpoint profil dan wadah air.

Implementasi endpoint ditemukan di proyek lokal
`simonika-mqtt-backend-api-service/pages/api/auth/google/index.ts`. Pastikan
perubahan tersebut di-deploy ke URL di `lib/constants/api.dart`, dengan
`GOOGLE_CLIENT_ID`, `JWT_SECRET`, dan `MONGODB_URI` yang benar.

### 4. Verifikasi

```bash
flutter test test/google_auth_service_test.dart test/google_login_screen_test.dart test/login_layout_check_test.dart
flutter analyze lib/services/google_auth_service.dart lib/screens/auth/login_screen.dart
```

Pada perangkat Android dengan Google Play Services atau iPhone: tekan
**Lanjutkan dengan Google**, pilih akun, dan pastikan halaman utama serta profil
bisa dibuka. Coba juga membatalkan pemilihan, memutus jaringan, serta keluar dan
masuk kembali dengan akun berbeda. Pembatalan tidak menampilkan error; sesi
aplikasi hanya disimpan setelah respons backend berisi token yang valid.

Jika Android melaporkan `sign_in_failed`/API exception 10, cocokkan package,
SHA-1 sertifikat APK, proyek OAuth, dan Client ID Web. Jika backend menolak token,
cocokkan `GOOGLE_CLIENT_ID` backend dengan `GOOGLE_WEB_CLIENT_ID` aplikasi.

Referensi: [plugin Google Sign-In 6.3.0](https://pub.dev/packages/google_sign_in/versions/6.3.0),
[konfigurasi Google Sign-In iOS](https://developers.google.com/identity/sign-in/ios/start-integrating).
