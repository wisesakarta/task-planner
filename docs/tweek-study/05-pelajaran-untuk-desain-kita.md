# 05 — Pelajaran untuk desain kita

Dokumen ini menjawab masukan pemilik: *katalog komponen yang dibangun terasa sangat jelek*. Setelah mempelajari aplikasi
Tweek secara langsung, diagnosisnya cukup jelas. Bagian akhir mengusulkan arah **orisinal** yang tidak menyalin Tweek.

## 1. Diagnosis: mengapa katalog kita terasa jelek

| # | Tweek (yang dipelajari) | Katalog kita | Dampak |
|---|---|---|---|
| 1 | **Tiga ukuran teks** (31, 18, 16) + dua bobot; hierarki dari ukuran dan alfa | Delapan gaya, judul hari 40/900 huruf kapital, label kapital kecil, banyak bobot | terlalu berisik, tidak ada yang "tenang" |
| 2 | **Struktur dari garis**: garis 2 px tinta di bawah setiap header hari, garis 1 px tinta 10% tiap 42 px | garis rambut tipis satu warna beige; struktur nyaris tak terlihat | halaman terasa mengambang, tidak "berbaris" |
| 3 | **Satu aksen**, dipakai hemat: hari ini, hover, avatar. Selebihnya tinta dan kertas | oranye dipakai di chip, slider, segmented, switch, tombol utama, pil pengganti tampilan, hari ini | beban warna besar, tidak ada tempat untuk mata beristirahat |
| 4 | **Netral = tinta beralfa** (5/10/15/20/25/40/50/60/75/90 %) | abu-abu tetap per tema (`inkMuted`, `inkFaint`, `hairline`, `surfaceMuted` beige) | abu tidak selaras dengan kertas; tidak otomatis benar di gelap |
| 5 | **Permukaan bertinta**: dialog berlatar lavender/jingga muda, ubin tinta 5%; bayangan hanya satu (menu) | kartu putih dan beige atas beige, bayangan kabur di pil | permukaan tidak berbeda cukup jelas dan tidak punya karakter |
| 6 | **Satu bahasa bentuk**: lingkaran 40 px, pil (radius penuh), kartu 24, ubin 16, popover 12 | radius campur 28/16/8/5, stripe berujung 5 | bentuk tidak bersatu |
| 7 | **Ritme tetap**: margin 24, baris 42, header 42, jarak hari 24, kontrol 32/40/48 | gutter 20, baris 56+, header berbeda-beda | tidak ada irama vertikal |
| 8 | **Komposisi nyata**: layar utuh (minggu, kartu, menu) dengan data yang bermakna | katalog = daftar komponen lepas dengan **kontrol Material bawaan** (ChoiceChip, SegmentedButton, Slider) | kontrol bawaan merusak bahasa desain; tidak terlihat sebagai produk |
| 9 | **Detail kecil bermakna**: baris cadangan selalu ada; padding 6 px konsisten; ikon aktif lingkaran hitam; entri beruntun dengan Enter | tidak ada; stabilo geser teks; tidak ada baris cadangan | terasa "dirakit", bukan "dirancang" |
| 10 | **Tipografi berkarakter**: grotesque dengan tracking −1 px pada judul | Inter Tight default tanpa penyetelan (tracking, bobot 450) | judul terlihat biasa |

Akar masalahnya: kita membangun **komponen lepas dulu**, dengan bahan Material dan skala yang terlalu banyak, lalu
memajangnya sebagai daftar. Tweek dirancang sebaliknya: **satu layar utama yang sangat terkendali**, dengan sedikit token
yang dipakai berulang.

## 2. Prinsip yang dipelajari (teknik, bukan tampilan)

1. **Batasi kosakata.** Sedikit ukuran, sedikit bobot, sedikit radius, satu bayangan, satu aksen.
2. **Netral dari tinta beralfa**, sehingga tema dan mode gelap bekerja hanya dengan mengganti tinta dan kertas.
3. **Struktur dari garis dan ritme**, bukan dari kotak dan bayangan.
4. **Warna adalah data.** Antarmuka monokrom; warna muncul hanya untuk sesuatu yang bermakna (warna tugas, hari ini).
5. **Sesuatu yang berubah = tidak bergerak (instan); sesuatu yang muncul = bergerak singkat.** 0,1 dan 0,2 detik.
6. **Kartu, bukan halaman.** Menyunting terjadi dalam kartu melayang yang ringan; menu adalah popover kecil di tempat.
7. **Pintasan alur utama.** Menambah tugas = ketuk baris, ketik, Enter; tidak ada tombol tambah.
8. **Konfirmasi yang menjelaskan akibat** dan menawarkan cakupan (hanya ini / seterusnya / semua).
9. **Konsistensi ukuran sentuh**: 32/40/48 di semua tempat.
10. **Detail yang dijaga**: baris cadangan, padding konstan agar teks tidak bergeser, ikon aktif, kata-kata yang tenang.

## 3. Yang tidak boleh kita ikuti

Bukan sekadar kehati-hatian hak cipta; ini soal identitas.

- Font Suisse Int'l (komersial), nama tema (Tweek, Jay, Tody, Finch, Sora, Weka, Ruff), maskot, dan ilustrasi sinar.
- Palet persis (`#5167F4`, `#DDE1FB`, `#E5D8FA`, `#F8E9E2`, …) dan kombinasi kertas+aksen bertema yang sama.
- **Tata letak persis**: header "tanggal kiri, nama hari kanan" dengan garis 2 px; ubin bento menu; kartu lavender; struktur
  6 kolom + Sabtu/Minggu bertumpuk; tampilan Month yang sama.
- Kata-kata dan nama fitur yang identik.

## 4. Arah orisinal yang diusulkan (untuk dibahas dengan pemilik)

Identitas yang sudah kita miliki dan patut dijaga: **aksen oranye**, **nama hari huruf kapital yang tegas** (warisan pilihan
pemilik), **stabilo** sebagai penanda warna, **Inter Tight**.

| Sumbu | Usulan orisinal (bukan salinan) | Yang dipelajari dari Tweek |
|---|---|---|
| Tipografi | Inter Tight disetel: judul bobot 900 dengan tracking rapat; **tiga ukuran** inti (mis. 28 / 17 / 14) + bobot 400/500/900 | batasi kosakata |
| Nama hari | tetap **KAPITAL tegas** tetapi pada ukuran yang tenang (±26–28), tanggal kecil di sebelahnya sebagai angka besar-ringan; bukan "tanggal kiri, hari kanan" | hierarki dari ukuran dan alfa |
| Struktur | garis **tebal di kiri (tab tinta)** atau **angka tanggal sebagai jangkar**, bukan garis 2 px penuh; garis berbaris tinta beralfa dengan ritme kita sendiri (mis. 44 px) | struktur dari garis dan ritme |
| Warna | tinta + kertas + **oranye hanya untuk "hari ini" dan aksi utama**; semua abu dari tinta beralfa | satu aksen, netral tinta |
| Penanda warna | **stabilo** (garis penanda di bawah teks) yang menjadi tanda tangan kita, bukan pil penuh | warna adalah data |
| Permukaan | kertas + **tinta beralfa 5%** untuk kelompok; dialog menandai fungsinya dengan tint yang **diturunkan dari aksen** kita | permukaan bertinta |
| Bentuk | tiga radius saja (mis. 10 / 20 / pil) dan tombol bulat 40 | satu bahasa bentuk |
| Gerak | 100 dan 200 ms, geser 12–24 px; perubahan status instan; satu kurva | gerak hemat |
| Interaksi | ketuk baris → ketik → Enter beruntun; kartu melayang; popover; konfirmasi bercakupan | alur utama tanpa tombol tambah |

## 5. Rencana perbaikan (Fase D dibuka kembali)

1. **Token baru**: tangga alfa tinta; kertas + tinta + satu aksen; radius, ukuran kontrol, ritme (margin/baris/jarak),
   tiga ukuran teks. Hapus token abu tetap.
2. **Bangun layar, bukan daftar komponen**: prototipe **layar Minggu** yang utuh (data nyata: hari ini, tugas berwarna,
   selesai, berulang, Someday), lalu **kartu tugas**, **popover Repeat/Warna/Pengingat**, **menu profil/pengaturan**.
3. **Buang kontrol Material bawaan** dari katalog; setiap kontrol milik kita (segmented, toggle, slider tema, chip).
4. **Rapikan komponen** terhadap token baru: baris tugas (padding konstan, baris cadangan), stabilo, header hari, tombol
   bulat 40, kartu 24, popover.
5. **Tinjau di emulator berdampingan dengan tangkapan layar Tweek** (pribadi) hanya untuk *kualitas* (ritme, hierarki,
   ketenangan), lalu bandingkan dengan prinsip "tidak meniru".
6. **Persetujuan pemilik** atas layar Minggu sebelum Fase 2.

Catatan: pengujian otomatis yang ada (kontras WCAG, semantik, sentuh ≥ 48, teks 200%, reduce motion, gerak) tetap
berlaku dan tidak berubah; yang berubah adalah token dan susunan komponen.
