# Panduan dan Prompt Frontend Flutter SIMONIKA

Dokumen ini digunakan untuk menyesuaikan aplikasi Flutter SIMONIKA dengan backend kendali level air terbaru. Implementasi backend dilaporkan sudah lulus TypeScript, test, dan build; integrasi dengan Flutter dan perangkat masih perlu diuji.

## A. Langkah penggunaan

### 1. Buka project Flutter

Buka folder aplikasi Flutter SIMONIKA di editor. Pastikan folder tersebut berisi `pubspec.yaml`.

Letakkan file ini di folder utama project Flutter, sejajar dengan `pubspec.yaml`.

### 2. Siapkan branch Flutter

Jalankan di terminal project Flutter, bukan project backend:

```bash
git status
git switch -c feat/flexible-water-control-ui
```

Jika branch tersebut sudah ada, gunakan `git switch feat/flexible-water-control-ui` setelah memeriksa kondisi repository. Jangan membuang perubahan yang belum di-commit atau menimpa pekerjaan lain.

Backend tetap menggunakan branch `feat/flexible-water-control` selama pengerjaan ini. Pekerjaan Flutter tidak memerlukan merge backend ke produksi terlebih dahulu.

### 3. Berikan referensi backend kepada agent

Lampirkan file berikut dari backend versi terbaru, atau berikan akses baca ke folder backend lokal pada branch yang sesuai:

```text
pages/api/pool/index.ts
pages/api/pool/[id]/index.ts
pages/api/water/level/index.ts
pages/api/mqtt/publish/index.ts
lib/waterControl.ts
```

Jika diperlukan, sertakan juga model Pool, model WaterLevel, dan dokumentasi API. Jangan melampirkan `.env`, JWT, password MQTT, atau URI database yang mengandung kredensial.

### 4. Kirim perintah singkat ke agent

> Baca file `Prompt-Frontend-Flutter-SIMONIKA.md` sampai selesai. Kerjakan instruksi pada bagian B menggunakan kontrak dari file backend yang saya berikan. Langsung implementasikan pada project Flutter existing, pertahankan perubahan saya yang sudah ada, kemudian jalankan pemeriksaan dan laporkan hasilnya.

## B. Prompt implementasi untuk agent Flutter

Sesuaikan aplikasi Flutter SIMONIKA yang sudah ada dengan backend terbaru. Langsung implementasikan perubahan kode setelah membaca struktur project dan file API backend yang saya berikan.

### 1. Pelajari project dan kontrak API

- Pelajari model, API service, penyimpanan token, state management, navigasi, halaman wadah, serta monitoring existing.
- Baca kontrak request dan response dari kode backend. Jangan menebak bentuk JSON, endpoint tambahan, atau field yang belum tersedia.
- Gunakan implementasi backend terbaru sebagai sumber kebenaran, termasuk envelope response, nama ID, nullable fields, urutan data, tipe timestamp, whitelist field, serta pesan error.
- Jika file backend tidak dapat diakses, kerjakan pemeriksaan struktur Flutter dahulu lalu sebutkan file kontrak yang masih dibutuhkan. Jangan mengklaim integrasi sudah selesai berdasarkan asumsi.
- Pertahankan pola arsitektur dan dependency existing. Hindari refactor besar yang tidak terkait.

### 2. Perbarui model dan form wadah

Perbarui model, API service, serta halaman tambah/edit wadah untuk memakai:

```text
namaWadah
serial
kedalaman
jarakSensorDasar
batasIsiMulai
batasIsiBerhenti
batasBuangMulai
batasBuangBerhenti
modeAuto
```

Tangani `isActive` sesuai kontrak API. Jangan mengirim field internal seperti `userId` dari form.

Semua ukuran menggunakan cm. Jangan hardcode ukuran wadah atau angka ambang contoh.

Kelompokkan form dengan jelas:

- Identitas: nama wadah dan serial perangkat.
- Ukuran dan sensor: kedalaman wadah serta jarak sensor ke dasar.
- Pengisian: mulai isi dan berhenti isi.
- Pembuangan: mulai buang dan berhenti buang.
- Mode otomatis.

Jelaskan secara singkat bahwa jarak sensor ke dasar dapat lebih besar daripada kedalaman wadah jika sensor dipasang di atas bibir wadah.

### 3. Validasi konfigurasi

Terapkan validasi sesuai `lib/waterControl.ts` backend dan tampilkan pesan yang mudah dipahami di dekat input terkait.

Aturan yang dilaporkan backend:

```text
0 <= batasIsiMulai
batasIsiMulai < batasBuangBerhenti
batasBuangBerhenti < batasIsiBerhenti
batasIsiBerhenti < batasBuangMulai
batasBuangMulai <= kedalaman
```

Periksa aturan ukuran, angka finite, nilai kosong, serta tipe boolean pada implementasi aktual. Jangan memperlakukan nilai kosong sebagai nol. Jangan membatasi `jarakSensorDasar` agar selalu lebih kecil daripada kedalaman.

### 4. Monitoring berdasarkan wadah

Gunakan request berikut sesuai kontrak response backend:

```http
GET /api/water/level?poolId=ID_WADAH&limit=30
Authorization: Bearer TOKEN_LOGIN
```

`poolId` adalah ID wadah di database, bukan serial ESP.

- Pastikan data tidak tercampur saat berpindah wadah.
- Cegah response request wadah lama menimpa tampilan wadah yang baru dipilih.
- Tampilkan tinggi air dalam cm dan persentase terhadap kedalaman.
- Jika diperlukan untuk gambar tangki, batasi hanya proporsi visual ke rentang 0–100%; jangan menyembunyikan nilai pengukuran asli yang berada di luar rentang.
- Status valve dan `controlState` berasal dari telemetry, bukan dihitung sendiri oleh Flutter.
- Jangan menyebut posisi fisik kran telah terverifikasi jika data hanya melaporkan keluaran kendali ESP tanpa sensor umpan balik.
- Jika memakai polling, hindari request bertumpuk dan hentikan sesuai lifecycle halaman/aplikasi.

### 5. Simpan dan kirim konfigurasi

Pengiriman konfigurasi menggunakan:

```http
POST /api/mqtt/publish
Authorization: Bearer TOKEN_LOGIN
Content-Type: application/json
```

Body:

```json
{
  "poolId": "ID_WADAH"
}
```

Simpan perubahan konfigurasi dahulu sebelum mengirimnya. Periksa apakah backend sudah otomatis publish saat create/update agar tidak mengirim dua kali.

Jangan mengirim `topic`, credential MQTT, atau payload konfigurasi bebas dari Flutter.

Bedakan hasil berikut:

1. Konfigurasi tersimpan di backend.
2. Konfigurasi berhasil dikirim ke broker.
3. Konfigurasi diterapkan perangkat.

Jangan menyatakan perangkat sudah menerapkan konfigurasi tanpa konfirmasi yang didukung backend. Jika penyimpanan berhasil tetapi publish gagal, pertahankan hasil simpan dan berikan opsi mengirim ulang tanpa membuat wadah duplikat.

Jika kontrol manual existing tidak memiliki kontrak backend yang sesuai, jangan mengarang endpoint atau memakai endpoint konfigurasi untuk perintah manual. Laporkan kebutuhan tersebut secara eksplisit.

### 6. Tangani kondisi data dan error

Tangani loading, error, data kosong, sensor tidak valid, dan data kedaluwarsa.

- Jangan mengubah data yang tidak tersedia menjadi angka nol atau status kran tertutup.
- Tampilkan status belum diketahui ketika field telemetry belum tersedia.
- Data lama harus diberi keterangan waktu pembaruan; jangan tampilkan sebagai kondisi perangkat saat ini.
- Dasarkan pemeriksaan waktu pada timestamp yang maknanya telah diverifikasi. Jangan memperlakukan `uptimeMs` sebagai waktu kalender.
- Tangani sesi login kedaluwarsa menggunakan alur autentikasi existing.
- Tampilkan pesan backend yang sesuai untuk validasi, konflik serial, dan resource tidak ditemukan.
- Cegah pengiriman form berulang saat request masih berjalan.

### 7. Wadah lama

Wadah dengan konfigurasi baru yang belum lengkap harus diarahkan untuk melengkapi pengaturan, bukan diberi ambang otomatis.

Jangan mengasumsikan mapping field lama `keranBuka`, `keranNormal`, atau `keranTutup` tanpa kontrak migrasi backend yang jelas. Jangan menampilkan nilai contoh seolah-olah merupakan konfigurasi tersimpan.

### 8. Tampilan dan batas pekerjaan

- Pertahankan gaya desain aplikasi, autentikasi existing, serta fitur lain yang tidak terkait.
- Gunakan UI yang rapi, mudah dipahami, dan konsisten dengan aplikasi.
- Jangan menambahkan kredensial MQTT, MongoDB, atau JWT secret ke Flutter.
- Pertahankan mekanisme konfigurasi base URL dan sediakan cara memilih backend pengujian sesuai pola project.
- Jangan mengganti URL produksi secara diam-diam.
- Jangan mengubah backend, firmware Arduino, database produksi, atau melakukan deployment.

### 9. Pemeriksaan dan hasil akhir

Jalankan:

```bash
flutter analyze
```

Jalankan test yang relevan menggunakan setup project yang tersedia. Prioritaskan validasi form, parsing response aktual, isolasi data saat berpindah wadah, serta hasil simpan/publish yang berbeda.

Perbaiki masalah akibat perubahan ini. Jangan mengklaim integrasi berhasil jika belum diuji dengan backend.

Berikan laporan:

1. File baru dan file yang diubah.
2. Kontrak API yang dipakai dan sumbernya.
3. Perubahan pada form wadah serta monitoring.
4. Cara memilih base URL backend pengujian.
5. Hasil analyze/test dan pemeriksaan yang belum dapat dijalankan.
6. Kendala atau fitur yang belum didukung backend.
7. Langkah uji integrasi yang masih diperlukan.

## C. Tahap setelah Flutter selesai

Kirim laporan agent untuk diperiksa. Selanjutnya cocokkan firmware Arduino/ESP8266 dengan payload konfigurasi dan telemetry terbaru.

Uji alur lengkap:

1. Simpan konfigurasi wadah dari Flutter.
2. Kirim konfigurasi melalui backend.
3. Pastikan ESP menerima dan menerapkan konfigurasi.
4. Pastikan telemetry tersimpan dan tampil untuk wadah yang benar.
5. Uji pengisian sampai ambang berhenti dan pembuangan sampai ambang berhenti.
6. Uji kondisi sensor tidak valid dan koneksi terputus sesuai perilaku firmware yang disepakati.

Gabungkan perubahan ke produksi setelah kompatibilitas Flutter, backend, data, dan firmware telah diperiksa.
