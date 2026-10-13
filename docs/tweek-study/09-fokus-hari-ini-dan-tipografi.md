# 09 — Fokus "hari ini" di Week view, CRUD, dan tipografi terukur

Diteliti 2026-10-02 (Jumat) pada perangkat fisik Android, `so.tweek.android`, akun uji. Posisi diambil dari
`uiautomator dump` (piksel; 1 dp = 2,744 px), gerak dari `screenrecord` 20 fps. Tangkapan layar, rekaman dan dump ada di
`docs/references/_private/tweek-mobile/autofocus/` (git-ignored). Atas izin pemilik, tugas uji dibuat, diubah, lalu dihapus;
keadaan akhir Tweek sama dengan keadaan awal (minggu kosong).

## 1. Hari mana yang ada di baris atas

Week view Tweek adalah satu daftar Senin–Minggu + Someday. "Fokus" berarti **satu hari diletakkan persis di tempat Senin
berada saat daftar digulir ke paling atas** (teks tanggal di y = 338 px dalam kedua kasus); hari-hari sebelumnya tetap ada di
atasnya dan bisa digulir. Tidak ada animasi gulir: minggu langsung tampil sudah pada posisinya (rekaman: satu potongan frame).

| Aksi | Baris atas sesudahnya |
|---|---|
| Aplikasi dibuka (cold start) | **hari ini** (2 Okt) |
| › ke minggu lain / ‹ ke minggu lain | hari pertama minggu itu (Senin) |
| ‹ / › kembali ke minggu ini | **hari ini** lagi (bukan posisi gulir lama) |
| Ketuk judul "Oct 2026" di minggu lain | **hari ini** (Help Center: *"hit the Month Year … it'll bring you to the current day or week"*) |
| Month view → ketuk tanggal (15 Okt) | **tanggal itu** (15 Okt), juga bila di minggu lain |
| Month view → tombol Back | posisi gulir **sebelum** Month dibuka (tidak difokus ulang) |
| Aplikasi ke latar lalu dibuka lagi | posisi gulir dipertahankan |

### Penerapan kita

`WeekScreen` memakai `CustomScrollView` dengan **sliver tengah (`center`) pada hari fokus** dan `anchor = margin ÷ tinggi
viewport`. Offset 0 = hari fokus di baris atas sejak frame pertama (tanpa lompatan pasca-frame), hari sebelumnya tumbuh ke atas,
dan menambah tugas di hari sebelumnya tidak mendorong hari fokus turun. Padding margin di atas Senin ikut sliver atas, jadi saat
digulir ke puncak Senin berada di tempat yang sama dengan hari fokus. Hari Minggu pun tetap bisa di baris atas (ruang kosong
di bawah Someday).

`TodoHome` menyimpan `focusDay` (tanggal dari Month) dan `visit` (bertambah pada ‹ ›, judul, dan pilihan tanggal Month).
Kunci gulir = `PageStorageKey((minggu, visit))`: kunjungan baru membuka minggu pada hari fokusnya, sedangkan Back dari Month
(visit sama) memulihkan posisi gulir dari `PageStorage`. Diverifikasi di ponsel dengan alur yang sama seperti tabel di atas, dan
dikunci 11 test (7 widget, 4 aplikasi).

## 2. CRUD dan perilaku tugas (Tweek)

- **Create**: ketuk baris kosong hari ini, ketik, Enter → tugas tersimpan dan kursor turun ke baris kosong berikutnya.
- **Read**: ketuk tugas → bottom sheet: chip tanggal, ✕, judul ExtraBold + centang, catatan, "Add subtask…" + klip, toolbar 5 ikon.
  Mengetuk kolom teks membesarkan sheet ke tinggi penuh.
- **Update**: judul, catatan, subtask (Enter = subtask berikutnya; centang subtask = lingkaran terisi + coret), warna
  (seluruh sheet ikut berwarna tugas, mis. *mango*), lalu ✕ (pertama mengecil, kedua menutup) → baris menampilkan judul baru
  dengan stabilo warna. **Temuan: Options → Tomorrow membuang semua edit yang dibuat di sesi kartu yang sama** (judul, catatan,
  subtask, warna hilang; hanya tanggal yang berubah). Aplikasi kita tidak boleh begitu: controller menulis edit bertahap dulu
  sebelum aksi diskret (lihat Fase 2), dan kartu memindah tanggal dari salinan yang sudah memuat semua edit; dikunci test
  *Tomorrow keeps the edits made before it*.
- **Selesai**: ketuk ikon centang → teks dicoret, pil warna memudar, ikon menjadi lingkaran abu terisi; ketuk lagi = batal.
- **Delete**: Options → Delete (merah) → langsung hilang, **tanpa konfirmasi dan tanpa Undo** (tugas tidak berulang).
- Options lain: Tomorrow, Next week, Someday, Duplicate, Add file.
- Pull-down di puncak daftar membuka Search (kolom pil + Cancel + 9 lingkaran filter warna).
- Help & Support membuka Help Center di browser (`help.tweek.so`, 82 artikel; yang relevan: *How do I get back to today?*,
  *Can I move the task to the next day or week…*, *How does Tweek sort tasks?*, *How to switch to Day View* — Day view tertulis
  "only available on iOS", meski header hari di Android juga membukanya, lihat `08`).

## 3. Tipografi terukur

Font Tweek tidak ditiru (lisensi komersial); yang disamakan adalah **skala dan bobot**. Metode: tinggi tinta huruf kapital/angka
dan lebar batang vertikal (kuartil bawah panjang jalur gelap horizontal) diukur dari tangkapan 1080 px, lalu Inter Tight
dirender pada beberapa ukuran/bobot dengan cara yang sama dan dipilih yang paling dekat (tinggi + lebar teks).

| Elemen | Tweek (tinggi/batang px) | Kita sebelumnya | Kita sekarang | Hasil di ponsel |
|---|---|---|---|---|
| Judul "Oct 2026" | 64 / 15 | 31 sp, 700 | **32 sp, 800** | 67 / 15 |
| Tanggal hari "2 Oct" | 43 / 10 | 18 sp, 700 | **22 sp, 800** | 45 / 10 |
| Nama hari "Fri" | 42 / 5–6 | 18 sp, 400 | **22 sp, 500** | 45 / 6 |
| "Someday" | 44 / 12, hitam | 21 sp, 700, abu | **22 sp, 800, tinta** | 45 / 12 |
| Teks tugas | 34 / 5 | 16 sp, 400 | **17 sp, 500** | 34 / 5 |
| Judul kartu | 50 / 12 | 24 sp, 400 | **24 sp, 800** | — |
| Month: nama bulan / angka / huruf hari | 34 / 8 · 28 / 7 · 22 / 3 | 20·700 / 16·700 / 13·500 | **17·800 / 14·800 / 11·500** | — |

Inter Tight ExtraBold (800) ditambahkan sebagai berkas statis. Selisih yang **belum** disamakan (bukan tipografi, perlu
persetujuan pemilik karena mengubah tata letak): margin samping 24 vs 16 dp, baris 42 vs 50 dp, jarak hari 24 vs 30 dp,
garis rambut berona aksen, tombol atas (Search + Menu vs avatar).

## 5. Pengingat yang tidak muncul (aplikasi kita, bukan Tweek)

Pada 2 Okt pemilik melaporkan notifikasi tidak bekerja. Diselidiki di ponsel yang sama:

1. **Data**: tugas uji pemilik tersimpan dengan `reminderAt = 04:10 WIB` (kemungkinan dimaksud 16:10). Pemilih jam dimulai di 09:00,
   langkah ±1 jam/±5 menit, dan menerima waktu lampau; perencana membuang pengingat lampau tanpa tanda. Diperbaiki (lihat TODO, Fase 5).
   Tweek: kolom hari mulai dari *Today*, jam dan menit = sekarang (17:16 saat dibuka 17:15), menit per 1.
2. **Pengiriman**: setelah izin diberikan pun alarm kita tidak berbunyi saat aplikasi di latar. Log sistem:
   `Hiber/stateManager: freeze uid: 10606 com.example.flutter_ui` lalu `Hiber/hiber: proxy alarm (uid=10606 …)`; alarm dilepas
   hanya saat aplikasi dicairkan (`unfreeze … reason:activity`).

| Percobaan (aplikasi di latar) | Hasil |
|---|---|
| Inexact (cara lama) | ditahan; tidak keluar dalam jendela 17:20–17:24 |
| Exact `exactAllowWhileIdle` (`USE_EXACT_ALARM`, `window=0`, sama seperti TickTick) | ditahan |
| + pengecualian Doze (`deviceidle whitelist`, = "Unrestricted") | ditahan |
| *Alarm clock* (`setAlarmClock`, `flags=0x3`) | ditahan; 18:00 keluar 18:05:34 saat aplikasi dibuka |
| Proses dimatikan (`am kill`) lalu alarm 18:10 | tetap menggantung di antrean (`Next wake from idle … 18:10`) |
| Phone Master → App Launch | aplikasi kita sudah *Allowed*; tidak berpengaruh |

Hiber juga membekukan WhatsApp/Instagram dan mencairkannya karena paket jaringan (push) atau binder. Aplikasi kita kini memakai alarm
exact (lebih tepat di ponsel lain), tetapi di HiOS masalahnya belum terselesaikan — pilihan ada di TODO Fase 5.

## 4. Catatan pengujian

`flutter test` ternyata menggambar teks dengan **font kotak bawaan** (lebar "iiii" = "MMMM"), karena `useBundledFonts()` kosong.
`test/flutter_test_config.dart` kini memuat Inter Tight asli untuk semua test, sehingga lebar, pemotongan, dan luapan diukur
dengan glyph sebenarnya (test chip tanggal "never cut short" sebelumnya gagal karena ini). 811 test lulus.
