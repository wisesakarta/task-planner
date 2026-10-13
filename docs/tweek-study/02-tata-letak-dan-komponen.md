# 02 — Tata letak dan komponen

Semua ukuran dalam piksel CSS, diukur di DOM. Ponsel = viewport 390×844; desktop = 1440×900.

## Kerangka halaman (ponsel)

| Elemen | Ukuran / posisi |
|---|---|
| Judul ("Oct 2026") | x 16, y 16; 31/40, bobot 700, tracking −1 px |
| Tombol bilah atas | 4 lingkaran **40×40**, jarak 6 px (pitch 46), margin kanan 16, atas 16 |
| Isi tombol | Search: isi tinta 5%; Profile: avatar `#BE9CF3` dengan inisial; ‹ dan ›: isi **hitam**, ikon putih |
| Margin daftar | 24 kiri dan kanan (lebar konten 342) |
| Latar halaman | kertas tema; tanpa kartu, tanpa bayangan |

Desktop: margin 24, judul 36/48 ("September 2026", nama bulan penuh), tombol bilah dengan pitch 46 dan margin kanan 24.

## Tampilan minggu

### Ponsel — hari bertumpuk

- Setiap hari = **header 42 px** + baris. `header`: tanggal 18/28 bold ("30 Sep") di kiri, nama hari 18/28 regular
  di kanan (kapital awal saja, **alfa 0,2**; hari ini 0,4), `padding-bottom 12`, **garis bawah 2 px tinta**.
- Jarak antar-hari **24 px**.
- Baris: tinggi **42** (teks 22 + padding 10 atas dan bawah). Hari kosong punya **1** baris kosong (tinggi total 83,7);
  hari berisi menampilkan tugasnya **ditambah satu baris kosong cadangan** (mis. 1 tugas → 125,7).
- Setiap baris berlatar garis 1 px tinta 10% di dasar (SVG); baris yang bisa diketuk berubah menjadi garis aksen 40% saat hover.
- **Hari ini**: tanggal, nama hari, dan garis 2 px berwarna aksen (garis solid, teks nama hari alfa 0,4).
- Baris kosong adalah `input`: mengetuknya langsung membuka penulisan (lihat gerak dan interaksi).

### Desktop — kolom

- **6 kolom** lebar 212, jarak 24; Sabtu dan Minggu **ditumpuk** pada kolom keenam (Minggu menempati bawahnya, dengan
  header 2 px sendiri).
- Header desktop 21/28. Kolom memanjang sampai ±10 baris.
- **Someday** di bawah: judul "Someday" 21/700, tracking −0,5, alfa 0,2, tinggi 52, dapat diganti nama; **3 atau 6
  kolom** (pengaturan), tiap kolom punya menu "…" (redup).
- Centang pada baris desktop tampil **samar** (abu muda); apakah menjadi jelas saat di-hover belum diuji.

## Baris tugas

| Bagian | Nilai |
|---|---|
| Sel | tinggi 42, `padding-right 35`, `border-bottom 1px transparent` (hover: aksen 40%) |
| Teks | 16/22 dalam `span` `inline-block`, **`padding 0 6px`, radius 11**, `max-width:100%`, elipsis, **satu baris** (`nowrap`) |
| Warna tugas | latar `span` = warna; teks putih/hitam ditetapkan per warna; pil sepanjang teks |
| Ikon di pil | Font Awesome 12 px, `margin-right 4` (mis. ikon ulang) |
| Toggle | absolut di kanan, lebar 22 (ikon 22×22, stroke 1,684), `padding-left 8 / right 5` |
| Selesai | `line-through`, teks **alfa 0,3**, ikon alfa 0,3, lingkaran menjadi **cakram terisi** dengan centang |
| Diseret | pseudo-elemen `::before` `left/right −8`, radius 4, latar kertas alfa 0,6 |

Catatan: `padding 0 6px` ada pada **setiap** teks tugas, berwarna atau tidak. Karena itu teks tidak bergeser saat sebuah
tugas diberi warna.

## Kartu tugas (dialog)

Membuka dari baris. Ponsel: kartu **melayang di atas**, tidak menempel ke bawah.

| Bagian | Nilai |
|---|---|
| Wadah | `.dialog`: `max-width 512`, margin atas 64, lebar 366 pada ponsel (overlay `padding 0 12`), **radius 24**, **padding 24** |
| Warna | warna dialog tema (Tweek: `#DDE1FB`); **tidak** memakai warna tugas |
| Latar belakang | `dialog-backdrop` gelap `#0006` (tinta 40%); versi terang `#FFFC` |
| Baris atas | kiri: ikon kalender 12×13 + tanggal "Wed, 30 Sep 2026" (12/18). Kanan: ikon **22 px berpitch 32** |
| Ikon (kiri→kanan) | hapus (tempat sampah) · ulang · **warna** · lonceng · tambah orang (hanya bila ada kolaborasi) · "…" |
| Ikon aktif | **lingkaran hitam 32 px** di belakang ikon (putih); ikon warna menjadi **titik terisi berwarna pilihan** |
| Judul | `textarea` 24/28 regular; garis bawah 1 px tinta ±25%; centang selesai di kanan judul |
| Toolbar catatan | 6 tombol **24×24** (radius 6, pitch 32): Heading, Bold, Italic, daftar, rata, tautan (Font Awesome 14) |
| Catatan | editor Draft.js 16/21,3; placeholder "Add some extra notes here…" |
| Subtask | lingkaran 20 + input 16/24 "Add subtask…"; klip kertas 18×19 di kanan (lampiran) |
| Tinggi total | ±292 dengan isi kosong (jarak ±70 antara baris atas dan judul) |

### Popover (Repeat / Color / Reminder)

Muncul **di bawah ikon**, terpusat pada ikon, jarak ±12. Wadah: **latar sama dengan kartu**, **radius 12**,
**bingkai 0,67 px hitam**, z 20 (palet warna z 1400).

- **Repeat**: lebar 243, `padding 8 0`; butir 36 tinggi, `padding 0 8 0 20`, 15/22 bobot 450; butir terpilih diberi
  centang di kiri; **pemisah 1 px tinta 5%** setelah "Never"; "Custom" berpanah ›. Isi: Never, Daily, Weekly, Weekdays,
  Biweekly, Monthly, Annually, Custom.
- **Color**: lebar 113, 3 kolom titik **20 px** pitch 34; titik = warna dengan bingkai 0,67 px sewarna; "tanpa warna"
  berbingkai tinta 15%; "+" isi tinta 5%.
- **Reminder**: kartu kecil dengan panah tanggal ‹ "30 Sep 2026" ›, dua stepper jam dan menit (angka 24/30 bergaris bawah,
  panah naik/turun), dan pil hitam **"Set reminder"**.

### Dialog konfirmasi

Untuk tugas berulang (lihat perilaku). Wadah: **`#F8E9E2`**, radius 24, padding 24; judul `h4` 21/28 bold, tracking −0,5;
isi 16/21,3; pilihan radio 16 dengan indentasi 32; **tombol pil 40 px, radius 22**, jarak 16: utama = hitam berteks putih 17
bold; sekunder = bingkai 0,67 px hitam.

## Menu profil (panel bento)

Panel tetap di (16, 72), lebar 358, **radius 24**, `padding 20 20 0`, isi `#E5D8FA`, `gap 16`, masuk dengan `translateY(−8→0)`
+ fade 0,2 detik.

- Baris nama: nama 21/24 bold (−0,5) + lencana "Premium" (pil berbingkai 0,67 px tinta 75%, 15/20, `padding 0 7`).
- **Ubin** setinggi 84, radius 16, `padding 12 16`, isi tinta 5%, jarak 16: ikon di atas, label 17/22 di bawah kiri.
  Tata letak: baris 1 = Share | Settings (dua kolom setara); baris 2 = Contact us (lebar 206,7) | About (95,3);
  baris 3 = "Connect AI apps via MCP" (penuh). Transisi warna ubin 0,2 detik.

## Pengaturan (panel penuh)

Panel yang sama meluas ke tinggi penuh (`max-height: 100dvh − atas − 24`). Bilah judul: tombol ‹ dan × **32 px** (isi tinta 5%),
judul terpusat 17/22 bold. Sub-halaman bergeser horizontal ±24 px + fade.

| Komponen | Nilai |
|---|---|
| Grup | isi tinta 5%, radius 16; sel tinggi 52 (padding 12 di sekitar label 28), pemisah tipis antar-sel |
| Label baris | 17/22; nilai di kanan tinta 40% dengan panah bawah (pilihan) atau › (navigasi) atau ↗ (tautan luar) |
| Judul seksi | 17/22, tinta 40% |
| Segmented | akar **hitam**, radius 12, `padding 3`, tinggi 44; segmen terpilih berisi **warna panel** (radius 9, padding 8, 15/20, transisi 0,1 dtk); segmen bisa berikon di atas label |
| Toggle | jalur tinta 25% (mati) / 75% (nyala), kenop `#F8E9E2` |
| Banner paket | kotak berbingkai tebal hitam berlatar sinar (ilustrasi); tombol "Add calendar" berupa pil isi tinta 5% |
| Log out | ubin dengan teks merah (`danger`) |

Halaman: **Your plan**, **My calendar › Calendar settings** (desktop layout: Classic/Side view; Someday columns 3/6;
Move uncompleted tasks to Today; Sort completed tasks; Hide completed tasks; sinkronisasi Google/Outlook/Linear),
**General** (Language, Date format, Week starts on, Week numbers, catatan zona waktu otomatis), **Appearance** (Color mode:
System/Light/Dark; Preset themes; Custom themes), Account, Notifications, Help & Support, About us, Log out.

Appearance: daftar tema berupa **baris teks polos** (tema aktif tebal + centang); tidak ada pratinjau warna.

## Tampilan Month

- Judul tahun ("2026"); inisial hari M T W T F S S (11/14, bobot 500) melekat di atas dengan **pudar gradien** (kertas alfa 0,9).
- Minggu bergulir vertikal tanpa henti; **tiap minggu setinggi 168** dan lebar 358; nomor hari **24×24**, 14/14 bold,
  bulat; label bulan ("Oct") 17/22 bold berada di titik pergantian bulan, sejajar kolom hari pertama.
- Hari ini = nomor putih di dalam **lingkaran aksen**; akhir pekan lebih redup; tugas = pil kecil berisi tinta 5%.
- Mengetuk sebuah hari kembali ke tampilan minggu berisi hari itu.

## Search

Kartu **putih** (latar dialog pencarian tema) melayang seperti kartu tugas: judul "Search" 21 bold, input dengan garis bawah,
dan baris **titik warna 20 px** (semua warna tugas, termasuk "tanpa warna") sebagai filter.
