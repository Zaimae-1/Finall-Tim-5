# Finall-Tim-5 — Duolingo Clone

Final project sekolah Tim 5 menggunakan Flutter. Tujuannya membuat ulang tampilan, alur, dan fitur utama aplikasi Duolingo untuk latihan pengembangan aplikasi. Proyek ini tidak berafiliasi dengan Duolingo.

## Status saat ini

**LingoShark** sudah punya layar sambutan, masuk, dan onboarding untuk profil demo dengan tema laut, ombak dan gelembung bergerak, tombol dengan respons sentuh, serta kartu pilihan yang menyorot opsi aktif. Halaman **Belajar** sekarang berupa peta laut penuh berisi **100 level** Bahasa Inggris, masing-masing lima soal, tanpa banner dan kartu quest di bawah peta. Lima level pertama ditulis khusus; level 6–100 memakai kuis kosakata dari 20 topik dengan variasi urutan soal. Peta dimulai dari level 1 di bawah dan naik menuju level 100, dengan pintasan ke level aktif dan setiap pulau. Kapal bergerak mengikuti ombak; setiap level kelipatan 5 adalah quest **Treasure** dengan pulau, pohon kelapa bergoyang, dan peti harta karun. Hiu animasi memberi petunjuk di level aktif dan maju setelah level selesai. Quest harian tetap tersedia di tab **Quest**.

Header utama berbentuk kapsul melayang berisi streak, logo hiu, nama aplikasi, dan saldo Gems. Tab Quest menampilkan tiga misi harian dan empat peti pencapaian dengan hadiah yang dapat diklaim sekali. Profil memiliki kartu identitas bertema laut dan kartu rank futuristik; daftar semua rank berupa kartu tier berwarna yang bisa diketuk untuk melihat syarat XP. Saat XP baru menaikkan tier, pop-up perayaan tampil setelah kembali ke peta. Toko menampilkan lima skin hiu dalam kartu pratinjau yang lebih lapang.

Untuk demo, pilih **Mulai belajar**, isi level dan target harian, lalu daftar dengan data contoh seperti `nama@example.com`. Coba selesaikan satu lesson, keluar dari Profil, lalu masuk lagi dengan data yang sama. Profil dan progres disimpan di perangkat atau browser yang dipakai. Sesi berakhir saat aplikasi ditutup. Gerakan hiu mengikuti preferensi pengurangan animasi perangkat.

Android adalah target utama tugas karena aplikasi referensinya dari Play Store. Web disediakan untuk memudahkan preview di laptop. iOS hanya bisa dibangun menggunakan macOS dan Xcode.

## Cakupan yang dikerjakan

Fokus saat ini: satu kursus **bahasa Inggris untuk pengguna berbahasa Indonesia**, dengan 100 level aktif, masing-masing 5 soal. Angka ini adalah cakupan proyek tim, bukan ketentuan resmi guru; sesuaikan jika ada rubrik sekolah.

| Halaman | Perilaku yang harus berfungsi |
| --- | --- |
| Welcome dan onboarding | Mulai, pilih kursus, tujuan harian, dan level awal; pilihan tersimpan |
| Masuk / daftar | Profil demo lokal; tidak mengklaim autentikasi online |
| Home / Learn | Peta laut penuh 100 level; kapal reguler dan pulau Treasure setiap kelipatan 5; hiu dan gelembung petunjuk di level aktif; level berikutnya terbuka setelah selesai |
| Lesson | Pilihan ganda, susun kata, dan pasangan kata; cek jawaban, feedback benar/salah, progress bar, serta konfirmasi keluar |
| Hasil lesson | Tampilkan akurasi, XP, Gems, dan perubahan streak; simpan progres dan kembali ke Home |
| Quests | Tiga misi harian dan empat peti pencapaian; hadiah Gems masing-masing hanya dapat diklaim sekali |
| Leaderboard | Peringkat demo dengan data contoh; posisi dan lencana rank setiap peserta mengikuti XP, diberi label demo |
| Profil | Avatar aktif, nama, email, statistik, kartu rank dengan progres ke rank berikutnya, daftar semua rank, dan edit profil |
| Shop | Saldo Gems, pelindung streak, booster XP 5%/7%/10%, lima art profil, dan lima kostum hiu; saldo tidak boleh negatif |

Alur demo: **Welcome → onboarding → profil → Home → lesson → hasil → progres/XP/quest diperbarui → lesson berikutnya terbuka**.

## Aturan perilaku dan batasan

- Semua navigasi dan tombol yang ditampilkan harus memiliki fungsi jelas. Fitur belum tersedia ditandai, bukan tombol kosong.
- Profil, progres lesson, XP, gems, dan quest tersimpan secara lokal per akun demo.
- Streak bertambah sekali per hari saat minimal satu quiz selesai. Jika satu hari penuh terlewat, streak aktif menjadi 0 saat hari berikutnya dimulai, kecuali ada Pelindung Streak yang menutup satu hari yang terlewat. Nilai di layar diperbarui saat pergantian hari tanpa membuka ulang aplikasi.
- Hadiah penyelesaian pertama diberikan sekali per level: reguler **25 XP + 5 Gems**, Treasure (5, 10, ..., 100) **250 XP + 15 Gems**. Treasure bukan tambahan di atas hadiah reguler. Latihan ulang tetap bisa dihitung untuk quest harian dan streak harian, tetapi tidak mendapat XP/Gems level lagi.
- Misi harian: satu latihan **+5 Gems**, target harian **+15 Gems**, dan tiga latihan **+10 Gems**. Peti pencapaian terbuka setelah 5/20/50/100 level selesai dengan hadiah 10/25/50/100 Gems. Masing-masing hadiah hanya bisa diklaim sekali per periode atau pencapaian.
- Booster 5%, 7%, dan 10% masing-masing berharga 10, 15, dan 20 Gems. Booster yang dipakai menambah XP dasar pada penyelesaian level baru berikutnya (dibulatkan ke bilangan bulat terdekat), lalu stoknya berkurang satu. Latihan ulang tidak menghabiskan booster. Hanya satu booster aktif pada satu waktu.
- Terdapat lima art profil eksklusif seharga 15 Gems dan lima kostum hiu seharga 25 Gems per item. Pembelian membuka item untuk akun demo tersebut, kemudian item dapat dipilih tanpa membayar lagi. Art yang belum dibeli tidak dapat dipasang; kostum yang dipasang tampil di peta dan layar quiz. Avatar dasar tersedia sebelum ada art yang dibeli.
- Rank dihitung dari total XP: Bronze 0–29, Silver 30–59, Gold 60–99, Platinum 100–199, Diamond 200–299, Ascendant 300–399, Immortal 400–999, dan Radiant mulai 1000 XP. Batas yang beririsan masuk ke rank baru; 0 XP ditampilkan Bronze sebagai rank awal. Lencana dibuat khusus untuk LingoShark dengan referensi gaya geometris dari gambar tugas.
- Saat hadiah kuis baru membuat rank naik, modal perayaan menunjukkan tier lama dan tier baru setelah pemain kembali ke peta. Latihan ulang tanpa tambahan XP tidak memicu modal.
- Progres lama tetap tersimpan. XP dari lesson yang diselesaikan sebelum perubahan aturan hadiah tidak dihitung ulang; aturan baru berlaku pada penyelesaian level berikutnya.
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
