# Todo App — Rencana & Progres

Dokumen ini adalah sumber kebenaran untuk pengembangan aplikasi Todo di `lib/features/todo`.
Centang item saat selesai. Setiap fase punya **kriteria selesai** yang harus lulus sebelum lanjut.

Legenda: `[x]` selesai · `[~]` sebagian / belum terverifikasi · `[ ]` belum dikerjakan

## Status saat ini (diperbarui 2026-10-02 — perbarui blok ini di setiap langkah)

**Acuan visual tunggal: Tweek** (keputusan pemilik 2026-10-01; referensi sekunder dihapus). Konsep: minimalis fungsional.
Penelitian Tweek: [`docs/tweek-study/`](docs/tweek-study/README.md) (01–09; **08 = aplikasi Android native, acuan untuk ponsel**; **09 = fokus hari ini, CRUD, tipografi terukur**). Spesifikasi komponen: [`docs/design-system.md`](docs/design-system.md).

| Bagian | Status |
|---|---|
| Model & data: tugas, berulang, subtask, warna, pengingat, pengaturan; penyimpanan `SharedPreferences` + migrasi | selesai, teruji |
| `TodoController`: simpan bertahap, tugas berulang, roll-over, refresh hari, pengingat | selesai, teruji |
| UI Week (hari berlajur, tulis di baris, cek, warna, Someday), kartu tugas (tanggal, Repeat, warna, pengingat, more, subtask), Search, menu (Appearance, Calendar, Notifications, About), 6 tema × terang/gelap | selesai, teruji, ditinjau di emulator |
| **Month view** + judul bulan dua peran (aksen bila bukan minggu ini) | selesai, teruji, ditinjau di emulator |
| **Fokus hari ini di baris atas** (seperti Tweek): dibuka → hari ini; ‹ › / judul kembali ke minggu ini → hari ini; minggu lain → Senin; Month → tanggal dipilih di atas; Back dari Month → posisi gulir lama | selesai 2026-10-02, 11 test, diverifikasi di ponsel ([`09`](docs/tweek-study/09-fokus-hari-ini-dan-tipografi.md)) |
| **Pengingat tidak muncul di ponsel pemilik** (2026-10-02): pemilih waktu lampau sudah diperbaiki. **Buzzkill** juga terbukti sebelumnya memblokir/menutup notifikasi aplikasi; aplikasi kini diizinkan di Buzzkill. Kontribusi HiOS "Hiber" terhadap alarm saat layar mati belum dapat dipisahkan dari faktor tersebut sampai uji ulang | pemilih waktu selesai, teruji; Buzzkill diperbaiki oleh pemilik; **uji layar-mati pada perangkat fisik masih wajib** — lihat Fase 5 |
| **Tipografi disamakan skala/bobotnya dengan Tweek** (diukur piksel di ponsel): judul 32/800, tanggal hari 22/800, nama hari 22/500, Someday 22/800 tinta, tugas 17/500, judul kartu 24/800, Month 17·14/800; Inter Tight ExtraBold ditambahkan | selesai 2026-10-02, diverifikasi di ponsel |
| **Pengingat nyata** (notifikasi lokal Android, tombol Done / In 1 hour / Tomorrow, pengaturan Notifications) | selesai di kode dan test; diverifikasi di emulator (lihat Fase 5) |
| **Seret-lepas** (pindah hari, ubah urutan, ke/dari Someday, auto-scroll, aksi pembaca layar) | selesai, teruji (22 test gestur + 4 alur aplikasi + 14 controller), diverifikasi di emulator; riset [`07`](docs/tweek-study/07-daftar-notifikasi-dan-seret.md) |
| Daftar Someday ("Add column", ganti nama, urutan, 3 atau 6 kolom) | **belum**; riset selesai (`07`) |
| Day view | ditunda (Tweek tidak punya di ponsel) |
| Rilis (`applicationId`, penandatanganan, ikon), performa perangkat fisik, test integrasi | Fase 6–7, belum |
| Sync, akun, kolaborasi | Fase 8–9, belum |

Kualitas: `flutter analyze` bersih; seluruh test unit/widget lulus (818, jalankan `flutter test`). Sejak 2026-10-02 test memakai **font Inter Tight asli** (`test/flutter_test_config.dart`); sebelumnya test diam-diam memakai font kotak bawaan. Belum ada yang di-commit.

**Perangkat uji (keputusan pemilik 2026-10-01): pengembangan dan pengujian kini di PERANGKAT FISIK** (Android 15, arm64; jalankan `adb devices` untuk memilih target; build `flutter build apk --debug --target-platform android-arm64` lalu `adb install -r`). Emulator tidak dipakai lagi. Perangkat uji juga memuat aplikasi Tweek milik pemilik: hanya dilihat, tidak mengubah datanya kecuali pemilik memintanya (2026-10-02: CRUD uji diizinkan, tugas uji dihapus lagi); tekan Back hanya satu kali per lapisan (dua kali keluar dari aplikasi kita dan membuka Tweek). Izin notifikasi kini diberikan (2026-10-02). Kabel USB perangkat tidak stabil; gunakan koneksi adb yang tersedia.

**Keputusan pemilik: acuan visual tetap Tweek web (disukai), tetapi rincian yang tampak "rusak"/"AI generated" di ponsel diperbaiki dengan membandingkan ke aplikasi Tweek Android** ([`08`](docs/tweek-study/08-aplikasi-mobile-android.md)). Sudah (lihat "Revisi setelah ulasan ponsel" di `docs/design-system.md`): panel kartu tugas menempel dan menumbuhkan kartu, menu "…" tanpa lorong kosong, grid warna 5 kolom, composer rata tanpa bayangan, cincin centang di margin kanan, Month (baris 138, nama bulan penuh di tengah kolom tanggal 1, hari ini = wash aksen, angka tebal), menu hanya empat ubin, kontrol segmen dipusatkan, ikon Calendar, tombol *Open phone settings*.

**Urutan pengerjaan berikutnya:** (1) bila pemilik masih menilai ada yang rusak/generik: minta layar dan elemen yang dimaksud lalu perbaiki (ulasan di ponsel, bukan emulator). Selisih tata letak terukur yang **menunggu keputusan pemilik** (tidak diubah tanpa persetujuan): margin 24 vs Tweek 16 dp, baris 42 vs 50 dp, jarak hari 24 vs 30 dp, garis rambut berona aksen, (2) daftar Someday (di Tweek mobile: 3 kolom bertumpuk, judul bisa diganti), (3) Fase 6–7.

## Prinsip: insanely great dari awal (bukan MVP)

Kami tidak membangun MVP. Tidak ada fitur yang dipotong demi "cukup untuk rilis pertama", dan tidak ada tahap
"nanti dipercantik". **Fase di bawah adalah urutan pengerjaan, bukan rilis.** Aplikasi baru dianggap siap ketika semua
fase inti (0–7) selesai pada standar kualitas berikut. Fitur yang bergantung pada sync tidak dibuang: ia dijadwalkan
di Fase 8–9 dan tetap bagian dari visi.

**Gerbang kualitas untuk setiap fase (Definition of Excellence):**

1. **Kesetiaan desain** — hasil dibandingkan berdampingan dengan spesifikasi di [`docs/tweek-visual-analysis.md`](docs/tweek-visual-analysis.md)
   dan tangkapan layar emulator. Selisih kecil (jarak, bobot font, warna, garis) dianggap cacat, bukan detail.
2. **Semua keadaan dirancang**: kosong, memuat, galat, offline, teks sangat panjang, angka besar, mode gelap, font 200%.
3. **Gerak dirancang**: setiap perubahan status punya transisi yang disengaja (durasi/kurva tercatat di spesifikasi gerak);
   60 fps di perangkat menengah; hormati *reduce motion*.
4. **Aksesibilitas**: label `Semantics`, target sentuh ≥ 48dp, kontras WCAG AA, bisa dipakai dengan TalkBack.
5. **Ketahanan data**: tidak pernah kehilangan tugas pengguna (penulisan berurutan, backup saat korup, rollback).
6. **Teruji**: unit test logika, widget test alur, dan verifikasi manual di emulator dengan tangkapan layar.
7. **Tanpa utang tersembunyi**: `flutter analyze` bersih; tidak ada TODO/hack tanpa entri di dokumen ini.

## Prinsip: orisinal dan autentik

Aplikasi ini dibuat oleh seorang *design engineer*, dan meniru aplikasi lain — sebagian maupun seluruhnya — tidak etis
dan bukan tujuan kami. Tweek dan referensi visual lain (dikumpulkan di [`docs/references/`](docs/references/README.md))
hanyalah **inspirasi**: kami belajar mengapa sesuatu terasa baik, lalu merancang jawaban kami sendiri.

- Tidak ada nama, maskot, palet warna persis, tata letak yang disalin, atau aset pihak lain di dalam aplikasi.
- Setiap keputusan meniru-atau-tidak dicatat (tabel pemetaan di bawah), termasuk apa yang **sengaja tidak** diikuti.
- Identitas kami: aksen oranye, judul hari huruf kapital yang tegas, stabilo warna, kertas berbaris, dan sistem desain
  sendiri (`docs/design-system.md`). Bila sebuah komponen terlalu mirip sumbernya, ia dirancang ulang.
- Repositori ini awalnya berisi template pihak ketiga; seluruh isinya sudah dihapus dari pohon kerja (masih ada di riwayat
  git dan di cabang `backup/template-before-cleanup`).

## North star: Tweek

Acuan produk adalah [Tweek](https://tweek.so) — planner mingguan minimalis yang "terasa alami seperti pena dan kertas".
Kami mengambil **prinsip dan kualitas eksekusinya**; bahasa visual, nama, dan aset tetap milik kami.

Analisis lengkap (dengan metode dan batasannya): **[`docs/tweek-visual-analysis.md`](docs/tweek-visual-analysis.md)**.
Ringkasnya, dasar analisis adalah 11 gambar produk resmi dan teks help center. Yang belum tercakup: aplikasi hidup
(butuh akun), gerak/animasi/haptics, dan ukuran presisi; spesifikasi gerak dan token dirancang sendiri di Fase D.

Prinsip yang diadopsi:

1. **Satu tampilan minggu adalah rumah aplikasi.** Tanpa tab, tanpa jadwal per jam.
2. **Hari adalah wadah utama**; **pandangan burung** atas minggu selalu tersedia.
3. **Tugas tanpa tanggal punya rumah sendiri** ("Someday").
4. **Warna adalah label utama** — tampil sebagai "stabilo" di teks tugas dan menintingkan kartu tugas.
5. **Kartu tugas satu bidang dengan lima mode** (bukan formulir panjang).
6. **Yang belum selesai tidak hilang dari pandangan** (roll-over yang bisa diatur).
7. **Kertas berbaris (*ruled paper*)** — baris kosong tetap digaris.
8. **Zoom lewat Day dan Month** dengan pil pengganti tampilan mengambang, bukan tab bawah.

Pemetaan (Tweek → kami). Kolom "Fase" menunjukkan kapan dikerjakan; tidak ada yang "opsional".

| Tweek | Keputusan | Fase |
|---|---|---|
| Week view sebagai beranda; hari bertumpuk di ponsel | **Adopsi.** Kami mempertahankan **akordeon hari** (pilihan pemilik) dan menambah pratinjau di header hari yang tertutup (jumlah tugas + titik warna) agar pandangan burung tetap ada | 3 |
| Someday | **Adopsi** | 3 |
| Warna tugas (palet + kustom hex), stabilo, tinting kartu | **Adopsi** | 1, 3, D |
| Kartu tugas dengan 5 mode (assign, repeat, warna, pengingat, lainnya) | **Adopsi**; mode *assign* menunggu sync (tampil setelah Fase 9) | 3 |
| Subtask 2 tingkat + sub-judul, catatan | **Adopsi** | 1, 3 |
| Repeat kaya (setiap N hari/minggu/bulan/tahun, tanggal dalam bulan, "Jumat ke-N", berakhir) | **Adopsi penuh** | 1, 3 |
| Pengingat dengan tanggal + jam sendiri | **Adopsi, gratis** | 1, 5 |
| Roll-over + "Sort down" + "Hide after complete" | **Adopsi** sebagai setting | 2, 4 |
| Pencarian + filter warna | **Adopsi** | 4 |
| Day dan Month + pil pengganti tampilan | **Adopsi** | 4 |
| Tema seluruh aplikasi dengan aksen "hari ini" sendiri | **Adopsi**, palet tema milik kami | D, 4 |
| Drag & drop antar hari | **Adopsi** | 6 |
| 7 kolom di layar lebar | **Adopsi** | 6 |
| Lampiran file/gambar | **Adopsi**, penyimpanan lokal dulu | 9 |
| Kalender ganda, berbagi, assign, tautan publik | **Adopsi** setelah sync | 9 |
| Sinkron Google/Apple/Outlook, cetak, widget layar utama, integrasi AI | **Adopsi bertahap** setelah sync | 9 |
| Paywall / Premium | **Tidak ditiru** (aplikasi pribadi) | — |
| Nama, maskot, palet krem+merah persis | **Tidak ditiru** — identitas sendiri (oranye + tipografi tegas) | D |

## Platform

Satu kode Dart yang sama berjalan di semua platform Flutter. Yang berbeda hanya konfigurasi native.

| Platform | Ada di repo? | Bisa dibuild dari mesin ini (Windows)? | Catatan |
|---|---|---|---|
| Android | ya (`android/`) | ya, target utama | Pengingat lokal dikonfigurasi; lihat status build di Fase 0 |
| iOS | ya (`ios/`) | **tidak** — butuh macOS + Xcode | Pakai Mac, atau CI macOS (GitHub Actions / Codemagic). Perlu setup notifikasi di `AppDelegate` dan izin di `Info.plist` |
| Web | ya (`web/`) | ya | Pengingat tidak andal di web; penyimpanan pakai localStorage |
| Windows / macOS / Linux | tidak ada foldernya | Windows: ya, setelah `flutter create --platforms=windows .` | Di luar target awal |

Semua paket yang dipakai (`shared_preferences`, `flutter_local_notifications`, `timezone`,
`flutter_timezone`, `intl`) mendukung Android dan iOS. Kode aplikasi tidak memakai API khusus Android.

## Keputusan desain

- **Offline-first**, tanpa backend. `TodoRepository` adalah batas ke storage/sync; UI tidak tahu `SharedPreferences`.
- **Navigasi**: tanpa bottom navigation. Beranda = Week (7 hari bertumpuk + Someday, seperti Tweek). Search dan menu/Settings dari bilah atas; Month/Day view menyusul (Fase 4).
- **Kartu tugas**: kartu mengambang (bukan bottom sheet) berwarna *sheet* tema; lima aksi membuka popover (repeat, warna, pengingat, more) dan tanggal membuka kalender bulan. Simpan otomatis.
- **Warna**: nilai warna ARGB (16 swatch; kustom menyusul), ditampilkan sebagai pil di belakang judul pada baris minggu.
- **Model** (Fase 1, selesai): aturan ulang `RecurrenceRule`, `reminderAt`, warna sebagai nilai, subtask 2 tingkat dengan sub-judul. `priority` dan `tags` dihapus.
- **Interaksi tugas**: ketuk lingkaran = selesai/batal; ketuk baris = buka kartu; hapus lewat kartu (tugas berulang: pilih cakupan). Tanpa geser.
- **State**: satu `TodoController` (`ChangeNotifier`), tanpa paket state-management tambahan.
- **Update optimistis tanpa rollback**: perubahan langsung tampil; bila penyimpanan gagal pengguna diberi tahu (banner) dan teks yang diketik tidak hilang. Edit dari kartu ditulis bertahap (jeda 400 ms).
- **Tugas berulang**: menyelesaikan tugas berulang menandainya selesai dan membuat instance berikutnya (id baru). Membatalkan penyelesaian menghapus instance yang dibuat.
- **Roll-over**: operasi eksplisit di controller (mengubah `dueDate` + `updatedAt`), berjalan saat aplikasi dibuka / lewat tengah malam hanya bila setting aktif. Default: mati.
- **Awal minggu**: Senin (setting Senin/Minggu di Fase 4).
- **Pengingat**: alarm *exact* yang tetap berbunyi saat Doze (`USE_EXACT_ALARM`, Android 13+; `SCHEDULE_EXACT_ALARM` untuk 12), jatuh kembali ke *inexact* bila tidak diizinkan; dijadwal ulang setiap aplikasi dibuka dan setelah reboot. Catatan Play Store: `USE_EXACT_ALARM` hanya untuk aplikasi kalender/alarm/pengingat — tinjau lagi di Fase 7.
- **Font**: **Inter Tight** (Regular 400, Medium 500, Bold 700, ExtraBold 800) dibundel sebagai aset Flutter di
  `assets/fonts/inter_tight/`; lisensi **SIL Open Font License 1.1** ada di `OFL.txt`. Tidak ada
  pengunduhan font saat runtime. Fitur Todo tidak memakai `flutter_screenutil`.
- **Pohon kerja hanya berisi aplikasi Todo**: template awal (10 fitur contoh, 15 MB aset, galeri, `lib/core`) sudah dihapus; `main.dart` menjalankan `TodoApp`. `flutter_screenutil` dan layar Todo lama sudah dibuang.
- **Bahasa UI**: Inggris (disetujui). Lokalisasi Indonesia di Fase 7.
- **`applicationId`** sengaja ditunda (disetujui) — lihat Fase 7. Wajib sebelum rilis atau sebelum memakai layanan yang terikat ID aplikasi (Firebase, Google Sign-In) di Fase 8.
- Storage tetap blob JSON di `SharedPreferences` (cukup untuk ribuan tugas). Bila tidak cukup, ganti implementasi `TodoRepository` ke SQLite tanpa menyentuh UI.
- Gambar referensi Tweek **tidak** dimasukkan ke repo (hak cipta pihak lain); hanya tautan dan deskripsi.

## Fase 0 — Fondasi (selesai)

- [x] `TodoRepository` + `SharedPreferencesTodoRepository`
- [x] `TodoTask` sync-ready: `id`, `createdAt`, `updatedAt`, `syncState`, tombstone `deletedAt`
- [x] Todo menjadi layar default
- [x] Perbaikan: write diserialkan (tidak ada lost update), entri korup dilewati, backup sebelum menimpa data korup
- [x] Perbaikan: teks input tidak hilang saat simpan gagal; dispose controller dialog edit
- [x] Test: model, repository, widget
- [x] Dependency ditambahkan: `flutter_local_notifications`, `timezone`, `flutter_timezone`, `intl`
- [x] Android: desugaring, izin `POST_NOTIFICATIONS`/`RECEIVE_BOOT_COMPLETED`, receiver, label "Todo" — **`flutter build apk --debug` sukses** dan aplikasi berjalan di emulator (data lama tetap terbaca). Notifikasi sungguhan diuji di Fase 5
- [ ] Toolchain: Flutter memperingatkan Gradle 8.14 / AGP 8.11.1 / Kotlin 2.2.20 "akan segera tidak didukung" (minimum baru: Gradle 9.1.0, AGP 9.0.1, Kotlin 2.3.20). Naikkan sebelum Fase 5 dan uji ulang build

## Fase 0.5 — Pembersihan pohon kerja (selesai)

- [x] Cabang cadangan lokal `backup/template-before-cleanup` (keadaan sebelum dihapus; pulihkan file mana pun dengan `git checkout backup/template-before-cleanup -- <path>`)
- [x] Hapus 10 fitur template (`lib/features/*` selain `todo`), 15 MB aset template, galeri `lib/app`, dan `lib/core`
- [x] Buang dependency yang hanya dipakai template (`flutter_svg`, `cupertino_icons`)
- [x] Paket Dart `flutter_ui` → `todo_app` (semua impor diperbarui); deskripsi, judul web, dan nama tampilan iOS → "Todo"
- [x] `TodoApp` sebagai akar aplikasi; README baru; `docs/references/` untuk referensi visual (gambar desain Todo template dipindah ke sana)
- [x] Terverifikasi: `flutter analyze` seluruh proyek bersih (sebelumnya 4 catatan di modul template), 348 test lulus
- [ ] **Keputusan pemilik:** asal-usul repositori (lihat bagian Catatan lingkungan): `origin` masih menunjuk repo template, dan `LICENSE` masih atas nama pembuat template
- [x] `flutter_screenutil` + layar Todo lama dibuang (Fase D.2). Masih ditunda: `applicationId`/ID bundle (Fase 7)

## Fase 1 — Model & data (selesai)

- [x] `TodoSubtask` (item / sub-judul, 2 tingkat), `TodoTask` diperluas (catatan, tanggal opsional, warna, subtask, penyelesaian, tombstone)
- [x] **`RecurrenceRule`** menggantikan enum: setiap N hari/minggu/bulan/tahun, hari dalam minggu, tanggal dalam bulan, "hari ke-N" (Jumat kedua / terakhir), bulan (tahunan), tanggal berakhir; `nextAfter`, `nextDue` (melewati kejadian yang sudah lampau), ringkasan teks ("Every 2 weeks on Mon, Wed")
- [x] **`reminderAt`** menggantikan `dueMinutes` + `remind`; pengingat boleh di tanggal berbeda dari tenggat
- [x] **Warna sebagai nilai** (`color: int?` ARGB)
- [x] `TodoTask.nextOccurrence`: instance berikutnya tugas berulang (checklist di-reset, pengingat digeser sebanyak hari yang sama)
- [x] **`priority` dan `tags` dihapus dari model** (keputusan: Tweek tidak memilikinya, warna menggantikan keduanya; data lama yang berisi kedua field itu tetap terbaca dan field tersebut diabaikan). Bisa ditambahkan lagi bila kelak diperlukan
- [x] `TodoSettings`: tema, `moveToNextDay`, `sortCompletedDown`, `hideAfterComplete`, awal minggu; disimpan terpisah dari data tugas
- [x] Migrasi data: format pertama (tanpa field baru) dan format kedua (`dueMinutes`, enum ulang, `priority`/`tags`) terbaca dan diuji; pengaturan tema versi pertama dipertahankan
- [x] `TodoRepository.upsertAll`

**Selesai bila**: unit test model, aturan ulang, migrasi, dan repository lulus. ✔ 66 test lulus, `flutter analyze` bersih.

## Fase D — Sistem desain v1 (DIBUANG: dinilai "sangat jelek" oleh pemilik)

Sistem v1 (kartu tersinari, stabilo di dalam teks, roda pemilih, katalog komponen) dibuang seluruhnya. Cadangan:
salinan cadangan di luar snapshot dan cabang git `backup/template-before-cleanup`. Pelajaran yang tetap berlaku:
kontras diuji otomatis di semua palet, `ThemeExtension` tidak boleh punya field bernama `type`, `AnimatedSize` melempar
assertion bila durasi nol (reduce motion), aksen oranye `#FF5A0A` hanya 2.92 : 1 → `#FF5000`.

## Fase D.2 — Desain ulang mengikuti Tweek (SELESAI di kode dan test; menunggu tinjauan visual pemilik)

Keputusan pemilik: karena belum ada konsep sendiri, semua pertanyaan konkret dijawab **"mengikuti Tweek"** (struktur,
tata letak, interaksi), dengan identitas tetap milik sendiri (Inter Tight, palet/nama tema/salinan sendiri, tanpa aset Tweek).
Riset: [`docs/tweek-study/`](docs/tweek-study/README.md). Spesifikasi: [`docs/design-system.md`](docs/design-system.md).

- [x] **Token & tema** v2: tangga tinta, 4 tema × terang/gelap, 16 warna tugas, tipografi, gerak, radius/ukuran (`theme/`)
- [x] **Kontrol**: `RoundButton`, `PillButton`, `TodoToggle`, `SegmentedControl`, `CheckToggle` (overshoot 300 ms)
- [x] **Overlay**: kartu mengambang, popover berjangkar, dialog konfirmasi (nada alert; pilihan cakupan tugas berulang)
- [x] **Week**: `WeekScreen`, `TopBar`, `DaySection` (header + garis 2 px, hari ini beraksen), `TaskRow` 42 pt, `InlineComposer`
  (ketik di baris kosong, Enter melanjutkan), Someday
- [x] **Kartu tugas**: tanggal (kalender bulan / Someday), 5 aksi (hapus, repeat, warna, pengingat, more), judul + centang,
  catatan, subtask (Enter menambah, kosongkan = hapus, indent/heading/hapus lewat menu), simpan otomatis
- [x] **Repeat**: Daily/Weekly/Weekdays/Biweekly/Monthly/Annually + Custom (interval + satuan + ringkasan);
  konfirmasi "Change recurrence?" bila mengubah aturan yang sudah ada; hapus tugas berulang → pilih cakupan
- [x] **Menu**: panel bento → Appearance (mode + tema), Calendar (awal minggu + 3 opsi tugas), About
- [x] **Search**: kartu dengan kolom teks + filter warna (`searchTasks`)
- [x] Layar lama (`TodoView`), komponen v1, `flutter_screenutil`, dan katalog **dihapus**
- [x] Pengujian: 555 test unit/widget (tema, kontrol, overlay, popover, kartu, menu, week, controller, aplikasi utuh)
- [x] Ditinjau di emulator (Android 15, x86_64) dengan tangkapan layar: minggu, tambah tugas, kartu, kalender, menu, Appearance, tema gelap/Sage — cacat yang ditemukan (chip tanggal terpotong "Wed, 3…") diperbaiki dan dikunci dengan test
- [ ] **Persetujuan pemilik** atas tampilan — belum diberikan
- [ ] Test integrasi/perf di emulator dihapus bersama katalog lama; dibuat ulang untuk UI baru di Fase 6 (perlu applicationIdSuffix debug agar data tidak terhapus)

## Keputusan desain tambahan (setelah D.2)

- **Satu-satunya acuan visual adalah Tweek** (keputusan pemilik 2026-10-01). Referensi sekunder (are.na) **dihapus** dari
  repo dan tidak dipakai lagi; semua pembelajaran desain berikutnya dari Tweek langsung melalui aplikasi/web yang diamati.
- Konsep: **minimalis fungsional** — setiap elemen harus punya fungsi. Ringkasan hari di bawah judul dicoba lalu dibuang.
- **Tanpa serif**; font Inter Tight. Nama aplikasi **dibekukan sampai pemilik menentukan nama yang sesuai** (`appName` di `lib/features/todo/app_info.dart`).
- Bahasa alami di baris tulis: ditunda.
- Tombol profil diganti tombol **menu** (aplikasi tanpa akun); tema **Sand** dan **Charcoal** ditambahkan (6 tema, 12 palet,
  lulus uji kontras); radius konsentris pada kontrol bersarang.

## Fase 2 — Controller (SELESAI)

- [x] `TodoController` (`ChangeNotifier`): load, add, setDone, update (dari kartu), delete(scope), duplicate, pengaturan,
  navigasi minggu, `refreshToday`
- [x] Simpan **bertahap**: edit dari kartu dikumpulkan dan ditulis setelah jeda 400 ms (atau `flush`), tindakan diskret
  ditulis langsung; edit tertunda ikut tertulis bersama tindakan berikutnya; `dispose` menulis sisanya
- [x] Tugas berulang: menyelesaikan membuat instance berikutnya dalam **satu** penulisan; membuka lagi mencabut instance
  yang belum disentuh; salinan kartu yang basi tidak bisa menghapus tautan ke instance berikutnya
- [x] Hapus tugas berulang per cakupan: *only this* (seri berlanjut), *this and future*, *all linked* (rantai mundur+maju)
- [x] Roll-over hanya untuk tugas sekali-jalan yang belum selesai, saat pengaturan aktif (saat dibuka, saat pengaturan
  dinyalakan, saat ganti hari)
- [x] Jam bisa disuntik (`clock`) dan pembuat id (`newId`) sehingga test tidak bergantung waktu asli
- [x] Kegagalan simpan/baca dilaporkan lewat `problem` (banner "Dismiss"), teks yang diketik tidak hilang
- [ ] Rollback bila penyimpanan gagal — **sengaja tidak**: perubahan tetap di layar dan pengguna diberi tahu, karena rollback
  akan melawan pengguna yang sedang mengetik
- [ ] Pengingat tidak pernah menggagalkan operasi tugas — menunggu Fase 5

**Selesai bila**: test controller lulus (45 test: load, add, selesai, edit bertahap, hapus per cakupan, duplikat, roll-over,
pengaturan). ✔

## Fase 3 — Beranda Week & kartu tugas (SELESAI di kode; tinjauan emulator berjalan)

- [x] `TodoApp` (tema dari settings, tanpa transisi tema), `main.dart` memuat controller sebelum frame pertama
- [x] Beranda = Week: 7 hari bertumpuk + Someday; judul bulan mengetuk = kembali ke minggu ini
- [x] Kartu tugas, repeat, warna, tanggal, pengingat (pengaturan waktu; **notifikasi belum dijadwalkan**, Fase 5)
- [x] Refresh otomatis saat lewat tengah malam dan saat aplikasi kembali dibuka; simpan saat aplikasi ke latar
- [x] Keadaan: memuat, galat simpan; minggu kosong tetap punya baris tulis
- [ ] Geser = hapus dengan Undo (Tweek tidak punya; ditunda — hapus lewat kartu dengan konfirmasi untuk tugas berulang)
- [ ] Penanda overdue bila roll-over mati

## Fase 4 — Tampilan pelengkap, tema & Settings

- [x] **Search** (teks + filter warna), **Settings** (Appearance, Calendar, About), pemilih tema
- [x] **Month view** mengikuti Tweek (riset Pixel 8, `docs/tweek-study/06-...`): satu daftar gulir menerus semua bulan, minggu dipotong di batas
  bulan, nama bulan di atas kolom tanggal 1, sel (lebar − 32) ÷ 7 × 168, angka 24 px (hari ini = lingkaran aksen, akhir pekan lebih pudar),
  tugas = pil 16 px (warna tugas atau tinta 5%), "+N more" bila penuh; ketuk hari → minggu itu, ketuk tugas → kartu; ‹ › = satu bulan; Back = kembali ke minggu
- [x] **Judul bulan** seperti Tweek: aksen bila bukan minggu ini (ketuk = kembali ke minggu ini); di minggu ini ketuk = Month view
- [ ] **Day view** (Tweek tidak punya di ponsel; ditunda)
- [ ] Pemilih warna kustom (gradien + hex) — sementara 16 swatch
- [ ] Settings: notifikasi, "Clear completed", versi aplikasi

**Selesai bila**: tugas dari minggu/bulan lain bisa dilihat dan diedit; semua tema terbaca.

## Fase 5 — Pengingat (SELESAI di kode dan test; diverifikasi di emulator)

Riset: [`docs/tweek-study/07-daftar-notifikasi-dan-seret.md`](docs/tweek-study/07-daftar-notifikasi-dan-seret.md).

- [x] `ReminderService` (antarmuka) + `NoopReminderService` (test/platform tanpa dukungan) — `lib/features/todo/reminders/`
- [x] `LocalNotificationReminderService` (Android): zona waktu lokal via `flutter_timezone`, alarm **inexact** (tanpa izin alarm
  tepat; bisa terlambat beberapa menit saat *doze*), ikon kecil `ic_stat_reminder`, kanal "Task reminders"
- [x] **Tombol pada notifikasi** (jalan tanpa membuka aplikasi, lewat isolate latar belakang): **Done** (selesaikan; tugas
  berulang membuat yang berikutnya), **In 1 hour**, **Tomorrow** (jam yang sama). `ActionBroadcastReceiver` di manifest
- [x] Mengetuk notifikasi membuka kartu tugasnya (juga saat aplikasi dibuka dari keadaan tertutup)
- [x] Perencana murni (`planReminders`, `applyReminderAction`, `reminderNotificationId` = FNV-1a stabil) dan `completionChanges`
  dipakai bersama aplikasi dan isolate latar belakang
- [x] Controller: jadwalkan/batalkan saat tugas dibuat, diubah, selesai, dibuka lagi, dihapus, diduplikasi; jadwal ulang semua saat
  aplikasi dibuka; kegagalan pengingat **tidak pernah** menggagalkan operasi tugas
- [x] Izin notifikasi diminta **saat dibutuhkan** (ada pengingat yang akan ditampilkan, atau pengguna menyalakan pengaturan), sekali;
  bila ditolak, pengguna diberi tahu sekali dan halaman Notifications menampilkan penjelasan
- [x] Pengaturan **Notifications** (hidup/mati) di menu; mati = semua pengingat dibatalkan
- [x] Penyimpanan membaca ulang dari disk (`reload`) karena isolate latar belakang dapat menulis; aplikasi yang berjalan mendapat sinyal
  `dataChanged` dan membaca ulang
- [x] Diuji: 16 test perencana, 21 test controller+pengingat, test halaman Notifications dan alur aplikasi; di emulator: izin,
  alarm terjadwal (`dumpsys alarm`), notifikasi muncul dengan judul + tanggal + tiga tombol
- [x] Verifikasi akhir tombol notifikasi di emulator: "In 1 hour" memindahkan alarm ke jam berikutnya dan tersimpan (2026-10-01).
  Catatan: kartu yang *sedang terbuka* saat tombol ditekan tidak ikut menyegarkan salinannya (kasus tepi, diterima)
- [ ] iOS: `AppDelegate` + izin (dikerjakan bila ada akses Mac/CI)
- [x] Alarm tepat (`USE_EXACT_ALARM`) dengan fallback inexact (2026-10-02, alasan: lihat bawah)
- [x] Pemilih waktu: mulai dari 5 menit berikutnya (Tweek: jam sekarang), waktu lampau ditolak, tak bisa mundur sebelum hari ini, tahan ↑↓ untuk mengulang; jam disuntik (`clock`) untuk test
- [ ] **Uji ulang alarm layar-mati pada HiOS (Infinix/Tecno/itel), setelah aplikasi diizinkan di Buzzkill.** Uji 2026-10-02 pernah mencatat `Hiber … proxy alarm (uid=10606)` dan notifikasi baru muncul saat aplikasi dibuka; tetapi Buzzkill kini dikonfirmasi ikut memblokir/menutup notifikasi. Jalankan ulang dengan alarm *exact*, aplikasi di latar, layar mati, dan catat waktu alarm, waktu *broadcast*, serta waktu notifikasi. Jangan simpulkan Hiber, layanan *foreground*, FCM, atau ID paket adalah penyebab/solusi sebelum hasilnya terpisah. Riset: [`09`](docs/tweek-study/09-fokus-hari-ini-dan-tipografi.md) §5

**Selesai bila**: `flutter build apk --debug` sukses dan notifikasi muncul di emulator. ✔

## Fase 6 — Kualitas, gerak & aksesibilitas

- [x] **Drag & drop** (riset `07`), selesai 2026-10-01:
  - model: `sortKey`/`order` (urutan = posisi bilangan pecahan; jatuh di antara dua tetangga = titik tengah, jadi satu seretan hanya mengubah satu tugas — cocok untuk sync; bila ruang habis, daftar tujuan dirapikan ulang) — `TodoController.move`
  - UI: tekan-tahan 120 ms → baris terangkat (panel kertas 92% — Tweek memakai 60% tetapi teks di bawahnya tembus —, radius 4, melebar 8 px), baris asli redup, garis sisip aksen + titik di tempat jatuh, getar saat angkat/pindah/lepas
  - posisi dihitung dari jari + tata letak *saat itu* (bukan DragTarget), jadi tetap benar saat daftar bergulir; auto-scroll saat jari ≤ 64 dp dari tepi atas/bawah; daftar minggu bukan `ListView` malas supaya baris yang diseret tidak dibuang saat keluar layar
  - tugas berulang yang dijatuhkan di Someday → konfirmasi "Change recurrence?" (berulang berakhir); selain itu tanggal/pengingat tidak berubah (pengingat memegang tanggalnya sendiri, sama seperti kartu)
  - pembaca layar: aksi khusus "Move up / Move down / Move to the next day / previous day"
  - belum: seret ke minggu lain (pindah minggu dulu lewat ‹ ›), seret di Month view, alternatif papan ketik di web/desktop
- [ ] **Daftar Someday** (riset `07`): judul bisa diganti nama, menu … (Move up/down, Add column, Delete dengan konfirmasi), pengaturan jumlah 3 | 6
- [ ] Layar lebar (tablet/web): 7 kolom seperti Tweek web
- [ ] Edit tugas berulang: "hanya yang ini / yang ini dan seterusnya / semua"
- [ ] Label `Semantics`, target sentuh ≥ 48dp, kontras cukup di semua tema
- [ ] Skala font besar (200%) tidak overflow
- [ ] Animasi sesuai spesifikasi gerak; hormati `reduce motion`
- [ ] Profil performa mutlak (60 fps) pada **perangkat fisik** dalam mode profile: jalankan `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/perf_test.dart --profile -d <perangkat>`; emulator hanya bisa memberi angka relatif
- [ ] Penanganan error global (`FlutterError.onError`, `PlatformDispatcher.onError`) dengan hook untuk crash reporting

## Fase 7 — Siap rilis

- [ ] `applicationId` / bundle id sendiri (sekarang `com.example.flutter_ui`, warisan proyek awal; paket Dart sudah bernama `todo_app`) — **ditunda sampai nama produk diputuskan oleh pemilik**. Jangan memilih ID yang mengandung `calendar` semata-mata sebagai workaround vendor: pengecualian HiOS belum direproduksi dan bisa berubah. Wajib sebelum Play Store/App Store dan sebelum Fase 8 bila memakai Firebase/Google Sign-In.
- [ ] **Pisahkan build debug/uji dari aplikasi yang dipakai sehari-hari** (`applicationIdSuffix ".debug"` atau *flavor*): `flutter test integration_test` dan `flutter drive` memasang lalu menghapus aplikasi ber-ID sama, sehingga **data lokal ikut terhapus** (terjadi pada tugas uji di emulator). Wajib sebelum aplikasi dipakai untuk data sungguhan
- [ ] Nama aplikasi, ikon, splash
- [ ] Signing release (keystore) dan `minifyEnabled`
- [ ] Tinjau izin manifest (`INTERNET` masih ada dari proyek awal)
- [ ] Versi & changelog
- [ ] CI: `flutter analyze` + `flutter test` di setiap push
- [ ] Ekspor/impor backup JSON
- [ ] Lokalisasi (Indonesia)
- [ ] Kebijakan privasi (data hanya lokal)

## Fase 8 — Sync

- [ ] Pilih backend + autentikasi
- [ ] Antrean sync, retry/backoff
- [ ] Jam server/hybrid logical clock (jam perangkat bisa meleset)
- [ ] Resolusi konflik (`updatedAt` + tombstone; `syncState.conflict`)
- [ ] Pembersihan tombstone yang sudah tersinkron

## Fase 9 — Kolaborasi & integrasi (paritas dengan north star)

- [ ] Kalender ganda
- [ ] Berbagi kalender/tugas, *assign*, tautan publik
- [ ] Lampiran file dan gambar
- [ ] Sinkron Google/Apple/Outlook Calendar
- [ ] Widget layar utama
- [ ] Cetak/ekspor planner
- [ ] Integrasi AI (bila masih relevan)

## Protokol verifikasi tiap fase

1. `flutter analyze` — tanpa masalah baru di `lib/features/todo` dan `test`
2. `flutter test` — semua lulus
3. Jalankan di emulator (`flutter run -d emulator-5554`, restart penuh setelah menambah plugin), tangkap layar, bandingkan dengan spesifikasi
4. Lulus gerbang kualitas (bagian atas dokumen)
5. Centang item di dokumen ini, lalu commit satu fase per commit

## Catatan lingkungan

- Disk D: sempat penuh (0.02 GB bebas) sehingga build Gradle gagal (`No space left on device`). `build/app` (2,3 GB) dihapus dan build debug memakai `--target-platform android-x64` (emulator) agar jauh lebih kecil.

- `flutter` harus tersedia di PATH terminal; buka ulang terminal setelah PATH berubah.
- Build lama di emulator tetap terpasang sampai `flutter run` penuh dijalankan ulang.
- **Menjalankan `integration_test`/`flutter drive` menghapus data aplikasi** di perangkat yang sama (ID sama). Jangan menjalankannya pada perangkat yang berisi data yang ingin dipertahankan sampai build uji dipisahkan (Fase 7).
- **Asal-usul repositori.** `git remote -v` masih menunjuk ke repositori template pihak ketiga (`junaidjamel/Best-Flutter-UI-Templates`), dan `LICENSE` (MIT) atas nama pembuatnya. Sebelum `git push`: buat repositori baru milikmu dan arahkan `origin` ke sana (`git remote set-url origin <url>`), atau mulai riwayat baru bila tidak ingin membawa riwayat template. Lisensi untuk kode Todo yang baru adalah keputusanmu; berkas `LICENSE` sengaja belum diubah.
- Semua pekerjaan Todo (Fase 0–D) masih **belum di-commit**: `git add -A` lalu commit per fase.

> 2026-10-01: desain alternatif "Margin" (tanggal di margin kiri, pil minggu, lembar bawah) dicoba dan **dibatalkan atas
> permintaan pemilik** ("semakin buruk"); kode dikembalikan ke desain D.2. Ide baru harus diusulkan dan disetujui dulu
> sebelum dibangun di atas UI yang berjalan.
