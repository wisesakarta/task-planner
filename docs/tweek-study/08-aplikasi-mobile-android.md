# 08 — Aplikasi mobile Tweek (Android, native)

Diteliti 2026-10-01 pada perangkat fisik Android (Android 15, 1080×2436, 439 dpi → 1 dp = 2,744 px),
aplikasi `so.tweek.android` v2.30.94 (targetSdk 36). Hanya dibaca dan dilihat; tidak ada data yang diubah (tugas "Hello" tetap
di 30 Sep, tidak ada pengaturan yang diganti). Tangkapan layar ada di `docs/references/_private/tweek-mobile/` (git-ignored); ukuran
diambil dari `uiautomator dump` (hierarki view asli) dan dari piksel tangkapan layar.

**Temuan terbesar: ini aplikasi Android NATIVE (RecyclerView, TextView, EditText, BottomSheet), bukan WebView.** Dokumen 01–07 meneliti
versi web; perilakunya di ponsel berbeda dalam banyak hal penting. Untuk aplikasi ponsel, dokumen ini yang menjadi acuan.

## 1. Layar utama (minggu)

| Hal | Tweek mobile | Aplikasi kita sekarang |
|---|---|---|
| Posisi awal | daftar Sen–Min, **digulir sehingga hari ini di paling atas** (1 Okt tampil pertama, hari sebelumnya di atas, bisa digulir ke atas) | mulai di Senin |
| Judul "Oct 2026" | sangat tebal, ±32 sp, kotak 40 dp, **inset kiri 8 dp** (lebih ke kiri daripada isi) | Inter Tight 700, inset 24 |
| Tombol atas | 3 lingkaran 40 dp, jarak 8 dp: **avatar (huruf pertama nama, aksen, buka menu)**, ‹ ›, arang `#27282b` | Search, Menu (oranye), ‹ › hitam |
| Pencarian | **tarik turun** dari atas daftar membuka layar Search (kolom abu `#ebebeb` pil + *Cancel*, baris 9 lingkaran **filter warna**) | tombol kaca pembesar |
| Margin samping | **16 dp** (43 px) | 24 |
| Header hari | tinggi 52,8 dp: padding atas 15,7 · teks 27,3 dp (≈22 sp, 800) · bawah 8,4 · garis **1,5 dp hitam** (hari ini: aksen) | 42 dp, garis 2 |
| Baris tugas | **50 dp** (137 px), garis rambut 0,75 dp **berwarna aksen 12% (`#e5e8fd`)** — bukan abu netral | 42 dp, garis ink-alpha netral |
| Hari kosong | header + **satu baris kosong** (tekan untuk menulis langsung di baris, IME bertanda ✓) | sama |
| Jarak antar hari | **30 dp** (82 px) | 24 |
| Teks tugas | kotak 22 dp (≈16–17 sp), padding pil 7,7 dp (kiri teks 23 dp dari tepi) | Inter Tight 16 |
| Toggle | area 33,5 dp, ikon lingkaran-centang 22 dp, di ujung kanan margin | 48 dp area |
| Hari ini | tanggal+nama hari+garis **aksen `#5167f4`**; hari lain: tanggal hitam, nama hari `#999999` | sama (aksen oranye) |
| Someday | judul **hitam tebal** + garis tebal aksen-pucat; **3 kolom bertumpuk vertikal** (Someday + 2 tanpa judul), judul tiap kolom adalah EditText yang bisa diganti | judul abu, satu daftar |
| Bar atas saat digulir | latar **kabur/frosted** (blur) menutupi isi yang lewat di bawah status bar | tidak ada |
| Font | grotesk tebal berkarakter (judul/tanggal) dan grotesk sedang berjarak huruf lebar (menu/pengaturan) — **tidak boleh ditiru**; kita memakai Inter Tight | Inter Tight |

## 2. Kartu tugas = **bottom sheet**, bukan kartu mengambang

- Mengetuk tugas memunculkan **bottom sheet penuh lebar**, sudut atas ±24 dp, warna **aksen yang diredam `#dde1fb`**, tinggi awal ≈ separuh layar
  (isi di atas, ruang kosong, toolbar menempel di bawah). Latar belakang digelapkan 18%.
- Baris atas: **chip tanggal** (ikon kalender + "Wed, Sep 30, 2026", dapat diketuk) di kiri; tombol ✕ lingkaran di kanan.
- Judul besar (≈28 sp, 800) + tombol centang selesai di kanan; catatan ("Add some extra notes here…"); baris subtask
  ("◯ Add subtask…" + ikon klip lampiran).
- **Toolbar bawah 5 ikon** sama jarak (area 48 dp, pitch 69 dp): *Share task* (orang+), *Repeat*, *Color* (lingkaran), *Reminder* (lonceng), *Options* (⋯).
  Ikon aktif menjadi **lingkaran hitam penuh dengan ikon putih** (48 dp).
- Mengetuk chip tanggal / ikon toolbar **memperluas sheet ke tinggi penuh** dan membuka **panel terlampir tepat di atas toolbar**
  (warna lebih gelap `#d1d5ee`, sudut atas membulat): bukan popover melayang.
  - **Tanggal**: kalender bulanan (‹ "October 2026" ›, huruf hari Mo–Su, sel 44×41 dp, hari ini = lingkaran hitam, hari di luar bulan pudar)
    + garis + tombol teks **Apply**.
  - **Repeat**: daftar Never ✓ / Daily / Weekly / Monthly / Annually / Weekdays / Biweekly / Custom ›, baris 48 dp, pemisah tipis.
  - **Color**: satu baris lingkaran 9: putih (cincin = terpilih), merah-muda `#cd2c54`, kuning `#fdef5d`, hitam, abu `#c2c2c2`,
    biru `#5167f4`, jingga `#ffaf23`, hijau `#21ffa1`, ungu `#d95cfe`, + tombol "+" (warna kustom).
  - **Reminder**: **roda gulir tiga kolom** (hari: Today/Tomorrow/…, jam, menit) dengan dua garis menjepit baris terpilih + tombol **Set reminder**.
  - **Options**: menu putih melayang di atas ⋯ — Tomorrow →, Next week, Someday, Duplicate, Add file, **Delete (merah)**; ikon di kanan tiap baris.
  - Tombol *back* menutup seluruh sheet; ✕ mengecilkan dulu ke tinggi awal.

## 3. Day view **ada** di ponsel

Mengetuk header sebuah hari di minggu membuka **Day view**: judul "30 Sep" (**aksen**) + "Wed" (abu muda `#cccccc`), ‹ › pindah **per hari**,
seluruh halaman berupa **kertas bergaris** (baris 50 dp) dengan tugas hari itu di atas; mengetuk judul kembali ke minggu.
(Dokumen 01–06 menyebut "Tweek tidak punya Day view di ponsel": itu benar hanya untuk web.)

## 4. Month view

Mengetuk judul bulan: judul menjadi tahun ("2026"), huruf hari **M T W T F S S** tersemat di bawahnya (Sab/Min abu), latar atas frosted.
Sel 51,7 dp lebar × minggu 138 dp tinggi; angka tebal ±17 sp, **akhir pekan abu**; hari ini = **lingkaran aksen-pucat `#dce1fd`**;
tugas = **pil abu `#f0f0f0`** radius ±5 dp, teks 13 sp; nama bulan ("October") tebal, **dipusatkan di kolom tanggal 1**; garis pemisah minggu abu
netral (bukan lavender). Sama dengan spesifikasi web (dokumen 06) — Month view kita sudah sesuai.

## 5. Seret

Tekan-tahan (≤ 0,8 s; tidak diukur tepat) pada baris: baris **terangkat** — melebar ±7 dp di tiap sisi, teks sedikit lebih redup (`#333`), tanpa panel/bayangan
yang kentara, garis bawahnya ikut melebar; mengikuti jari. Jari kembali ke tempat asal lalu dilepas = tidak ada perubahan.

## 6. Pengaturan (halaman penuh, bukan panel)

- Menu avatar: kartu lilac (`#e8d9fa`) radius besar: nama akun + lencana **Premium**, ubin 2×2 (Share, Settings, **Contact us** lebar 60%, **About** 40%).
- **Settings** adalah halaman penuh berlatar lilac `#e5d8fa`, grup berwarna `#d9cded` radius ±16 dp (perkiraan dari gambar), header "‹ judul ✕" (tombol lingkaran).
  Isi: kartu paket (*Your plan*), Family, My Calendar (+ *Add calendar*), **General**, **Appearance**, **Account**, **Notifications**, Help & Support, About us, Log out (merah).
- **General**: Language, Date format (DD-MM), Week starts on, Week numbers (toggle), "Time zone: Jakarta (UTC+07:00) — Detected automatically".
- **Appearance**: Color mode (segmen hitam: System / Light / Dark), **Preset themes** (Tweek ✓, Jay, Tody, Finch, Sora, Weka, Ruff), *Custom themes*
  (berbayar), **Density: Default | Compact** (menu mengambang), Vibration (toggle). → baris 42 dp di web ≈ *Compact*; baris 50 dp adalah *Default*.
- **Notifications**: Push and email ✓ / Push notification / Email; catatan "At least one notification method is required for task reminders."

## 7. Warna & bentuk (tema Tweek terang)

Aksen `#5167f4`; sheet `#dde1fb`; panel dalam `#d1d5ee`; garis rambut `#e5e8fd` (= aksen 12%); tombol arang `#27282b`; hitam `#000`;
abu hari `#999`; pil bulan `#f0f0f0`; kolom pencarian `#ebebeb`; pengaturan `#e5d8fa` / `#d9cded`. **Hampir semua permukaan dan garis
membawa rona aksen** — itulah yang membuat tampilannya terasa utuh; di aplikasi kita garis dan permukaan netral (ink-alpha).

## 8. Selisih yang paling menjelaskan kesan "AI generated" pada aplikasi kita

1. Garis dan permukaan netral abu, bukan berona aksen (di Tweek semuanya "satu keluarga warna").
2. Kartu tugas sebagai popover tengah-layar padahal pola ponsel adalah bottom sheet + toolbar ikon + panel terlampir.
3. Ritme vertikal: baris 42 dp / margin 24 dp terasa padat-kaku; Tweek memakai baris 50 dp, margin 16 dp, jarak hari 30 dp, header dengan napas atas 16 dp.
4. Hierarki tipografi datar (Inter Tight sedang/tebal); Tweek memakai kontras berat ekstrem (judul/tanggal sangat tebal vs teks tugas ringan).
5. Bar atas: tombol Search + Menu oranye + ‹ › hitam (4 elemen berbeda gaya) vs avatar + ‹ › (3 elemen, satu keluarga).
6. Tidak ada frosted top bar, tidak ada pull-to-search, tidak ada Day view, Someday satu daftar.
7. Pengaturan: panel kecil vs halaman penuh berlatar berona.
