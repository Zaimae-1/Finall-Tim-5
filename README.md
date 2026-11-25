# Finall-Tim-5 — Duolingo Clone

Final project sekolah Tim 5 menggunakan Flutter. Tujuannya membuat ulang tampilan, alur, dan fitur utama aplikasi Duolingo untuk latihan pengembangan aplikasi. Proyek ini tidak berafiliasi dengan Duolingo.

## Status saat ini

**LingoShark** sudah punya layar sambutan, masuk, dan onboarding untuk profil demo. Setelah masuk, buka jalur **Belajar** untuk memainkan tiga lesson Bahasa Inggris. Setiap lesson berisi lima soal pilihan ganda, susun kata, atau pasangan kata. Quest, Toko, dan Profil memakai progres akun yang sama. Peringkat memakai contoh peserta dan XP kamu.

Untuk demo, pilih **Mulai belajar**, isi level dan target harian, lalu daftar dengan data contoh seperti `nama@example.com`. Coba selesaikan satu lesson, keluar dari Profil, lalu masuk lagi dengan data yang sama. Profil dan progres disimpan di perangkat atau browser yang dipakai. Sesi berakhir saat aplikasi ditutup. Gerakan hiu bisa dimatikan dari Profil dan mengikuti preferensi pengurangan animasi perangkat.

Android adalah target utama tugas karena aplikasi referensinya dari Play Store. Web disediakan untuk memudahkan preview di laptop. iOS hanya bisa dibangun menggunakan macOS dan Xcode.

## Cakupan yang dikerjakan

Fokus awal: satu kursus **bahasa Inggris untuk pengguna berbahasa Indonesia**, minimal 1 unit berisi 3 lesson, masing-masing minimal 5 soal. Angka ini adalah usulan batas minimum tim, bukan ketentuan resmi guru; sesuaikan jika ada rubrik sekolah.

| Halaman | Perilaku yang harus berfungsi |
| --- | --- |
| Welcome dan onboarding | Mulai, pilih kursus, tujuan harian, dan level awal; pilihan tersimpan |
| Masuk / daftar | Profil demo lokal; tidak mengklaim autentikasi online |
| Home / Learn | Jalur lesson; tampilkan status selesai, aktif, dan terkunci; lesson berikutnya terbuka setelah selesai |
| Lesson | Pilihan ganda, susun kata, dan pasangan kata; cek jawaban, feedback benar/salah, progress bar, serta konfirmasi keluar |
| Hasil lesson | Tampilkan akurasi dan XP; simpan progres dan kembali ke Home |
| Quests | Target harian mengikuti aktivitas belajar; hadiah hanya dapat diklaim sekali |
| Leaderboard | Peringkat demo dengan data contoh; posisi pengguna mengikuti XP, diberi label demo |
| Profil / pengaturan | Edit nama, lihat XP dan streak, ubah preferensi sederhana |
| Shop | Saldo gems, pembelian Streak Freeze dengan gems; saldo tidak boleh negatif |

Alur demo: **Welcome → onboarding → profil → Home → lesson → hasil → progres/XP/quest diperbarui → lesson berikutnya terbuka**.

## Aturan perilaku dan batasan

- Semua navigasi dan tombol yang ditampilkan harus memiliki fungsi jelas. Fitur belum tersedia ditandai, bukan tombol kosong.
- Profil, progres lesson, XP, gems, dan quest tersimpan secara lokal per akun demo.
- Streak bertambah sekali per hari saat minimal satu lesson selesai, bukan setiap menyelesaikan soal atau mengulang lesson di hari yang sama.
- XP dan gems penyelesaian pertama diberikan sekali per lesson. Latihan ulang tetap bisa dihitung untuk quest harian.
- Lesson dimulai dengan lima hati. Jawaban salah mengurangi satu hati. Jika hati habis, pemain bisa ulang dari awal atau kembali ke jalur belajar.
- Gunakan tema biru LingoShark dan maskot hiu buatan proyek. Gunakan Duolingo sebagai referensi alur dan fitur, lalu sesuaikan susunan layar dan komponen dengan identitas LingoShark.
- Buat layout aman di layar ponsel kecil, teks terbaca, dan halaman bisa di-scroll bila perlu.
- Gunakan soal dan kalimat buatan tim. Catat sumber/lisensi aset yang dipakai; jangan mengunggah data akun pribadi atau menganggap aset merek sebagai milik tim.
- Tidak termasuk tahap awal: backend, login Google asli, multiplayer realtime, pembayaran, iklan, AI conversation, penilaian suara, serta kursus musik/catur. Listening bisa ditambahkan setelah fitur inti selesai.
- Ketentuan di README ini adalah kesepakatan awal proyek. Rubrik dan instruksi guru tetap menjadi acuan utama.

## Peralatan setiap anggota

1. Install Git: https://git-scm.com/downloads
2. Install Flutter SDK stable dan masukkan folder `flutter/bin` ke PATH: https://docs.flutter.dev/install
3. Gunakan versi dasar yang sama dengan setup ini: **Flutter 3.44.8 / Dart 3.12.2**. Dart sudah disertakan dalam Flutter. SDK lama dapat diambil dari https://docs.flutter.dev/install/archive. Jika tim meng-upgrade, sepakati dan perbarui README serta lockfile bersama.
4. Install VS Code dengan extension Flutter (beserta Dart), atau Android Studio.
5. Untuk Android: install Android SDK, Command-line Tools, dan emulator melalui Android Studio. Bisa juga memakai HP Android dengan USB debugging.
6. Untuk preview web: install Chrome.

Periksa instalasi dari terminal baru:

```sh
flutter --version
flutter doctor
```

Jika ada lisensi Android yang belum diterima, jalankan perintah berikut dan baca serta terima sendiri persyaratannya:

```sh
flutter doctor --android-licenses
```

## Cara teman clone ke laptop masing-masing

Pemilik repo perlu mengundang anggota sebagai collaborator melalui GitHub **Settings → Collaborators**, lalu anggota menerima undangannya supaya bisa push branch. Repo publik dapat di-clone tanpa izin tulis, tetapi push tetap memerlukan akses dan login GitHub.

Buka terminal di folder tempat menyimpan proyek:

```sh
git clone https://github.com/Zaimae-1/Finall-Tim-5.git
cd Finall-Tim-5
flutter pub get
flutter devices
flutter run -d chrome
```

Untuk Android, nyalakan emulator atau hubungkan HP, lalu gunakan ID yang muncul di `flutter devices`:

```sh
flutter run -d <device-id>
```

Ganti `<device-id>` dengan ID sebenarnya, tanpa tanda kurung sudut. Jangan menjalankan `flutter create` lagi setelah clone. Folder Flutter SDK dan Android SDK tidak perlu disalin dari laptop anggota lain.

Alternatif GitHub Desktop: **File → Clone repository → URL**, masukkan URL repo di atas, pilih folder lokal, lalu buka folder hasil clone di VS Code dan jalankan `flutter pub get`.

## Aturan kerja tim

- Satu tugas dikerjakan pada satu branch. Jangan push pekerjaan harian langsung ke `main`.
- Sepakati pemilik fitur/file sebelum bekerja agar tidak saling menimpa. Perubahan `main.dart`, tema bersama, dan `pubspec.yaml` harus dikoordinasikan.
- Ambil pembaruan `main` sebelum membuat branch:

```sh
git switch main
git pull --ff-only origin main
git switch -c feat/nama-fitur
```

- Setelah selesai, cek hasil dan kirim branch:

```sh
dart format lib test
flutter analyze
flutter test
git status
git add lib test
# Tambahkan file lain yang memang terkait tugas dengan git add <path>.
git commit -m "feat: tambah halaman onboarding"
git push -u origin feat/nama-fitur
```

- Buka Pull Request di GitHub menuju `main`, jelaskan perubahan dan cara tes, lalu minta anggota lain review sebelum merge.
- Setelah PR di-merge: pindah ke `main` dan `git pull --ff-only origin main`. Untuk memperbarui branch aktif dari main, commit pekerjaan sendiri dulu lalu `git fetch origin` dan `git merge origin/main`.
- Jika konflik, bicarakan dengan pemilik file dan periksa kedua perubahan. Jangan asal memilih seluruh versi sendiri, memakai force push, atau menghapus pekerjaan teman.
- Commit `pubspec.lock` supaya versi dependency konsisten. Jangan upgrade dependency tanpa koordinasi.
- Jangan commit `.dart_tool/`, `build/`, `android/local.properties`, password, token, `.env`, atau signing key. Gitignore sudah mencakup file hasil build dan konfigurasi lokal utama.

## Struktur proyek

```text
lib/main.dart          Entry point dan tema aplikasi
lib/features/auth/     Layar akun dan penyimpanan profil demo
lib/features/learn/    Jalur belajar, latihan, dan progres lokal
lib/shared/            Widget animasi maskot
assets/images/         Ilustrasi maskot hiu
test/widget_test.dart  Tes form dan profil demo
android/               Project runner Android
ios/                   Project runner iOS
web/                   Project runner web
pubspec.yaml           Metadata dan dependency
pubspec.lock           Versi dependency yang dipakai bersama
analysis_options.yaml  Aturan lint
```

Saat fitur mulai dibuat, susun di `lib/features/<nama_fitur>/` dan letakkan komponen yang dipakai beberapa fitur di `lib/shared/`. Folder itu belum dibuat karena belum ada implementasi fiturnya.

## Pengecekan dan build

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```

APK debug untuk demonstrasi ada di `build/app/outputs/flutter-apk/app-debug.apk`. Itu bukan build rilis Play Store. Build Android membutuhkan toolchain dan lisensi Android yang siap.

Checklist sebelum presentasi:

- [ ] Alur onboarding sampai menyelesaikan lesson bisa dijalankan.
- [ ] Jawaban benar/salah, hati habis, lesson terkunci, dan keluar lesson tertangani.
- [ ] XP, quest, gems, dan streak konsisten serta tidak mendapat hadiah ganda.
- [ ] Progres tetap tersimpan setelah restart.
- [ ] Semua halaman dalam cakupan dapat diakses dan tombol berfungsi.
- [ ] Tampilan tidak overflow di ponsel yang digunakan demo.
- [ ] Analyze dan test lolos; APK diuji di perangkat Android.

## Kendala umum

- `flutter` tidak dikenali: periksa PATH lalu buka ulang terminal/VS Code.
- SDK tidak cocok: samakan Flutter dengan versi tim, lalu `flutter pub get`.
- Device tidak ditemukan: jalankan emulator atau aktifkan USB debugging dan izinkan koneksi HP; cek `flutter devices`.
- Push ditolak: periksa undangan collaborator, akun GitHub yang login, dan nama branch. Gunakan login Git Credential Manager, bukan password/token di file proyek.
- `git pull --ff-only` gagal: riwayat lokal berbeda; simpan pekerjaan dan koordinasikan merge, jangan force push.

## Referensi

- Aplikasi: https://play.google.com/store/apps/details?id=com.duolingo
- Alur dan fitur: https://blog.duolingo.com/duolingo-101-how-to-learn-a-language-on-duolingo/
- Perbedaan Energy: https://blog.duolingo.com/duolingo-energy/
- Instalasi Flutter: https://docs.flutter.dev/install
- Perintah Flutter: https://docs.flutter.dev/reference/flutter-cli
