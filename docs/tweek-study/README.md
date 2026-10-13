# Studi Tweek — dokumentasi lapangan

Dipelajari langsung dari aplikasi web Tweek yang sudah login (akun Premium bulanan), pada 30 September 2026.
Tujuannya **belajar**: mengapa Tweek terasa tenang dan presisi, lalu merancang jawaban kita sendiri.
Ini bukan cetak biru. Prinsip "orisinal dan autentik" di [`TODO.md`](../../TODO.md) tetap berlaku: tidak ada nama, maskot,
palet persis, tata letak, atau aset Tweek di dalam aplikasi kita.

## Isi

| Berkas | Isi |
|---|---|
| [`01-tokens-dan-tema.md`](01-tokens-dan-tema.md) | Token desain (warna, tangga alfa, radius, ukuran, tipografi, z-index, bayangan), 7 tema, aturan warna tugas |
| [`02-tata-letak-dan-komponen.md`](02-tata-letak-dan-komponen.md) | Ukuran dan struktur tiap layar dan komponen: minggu (ponsel dan desktop), baris tugas, kartu tugas, popover, dialog, menu profil, pengaturan, Month, Search |
| [`03-gerak-dan-interaksi.md`](03-gerak-dan-interaksi.md) | Semua keyframe, durasi, kurva, keadaan (hover, selesai, seret), alur (tambah cepat, selesaikan, hapus berulang) |
| [`04-perilaku-dan-teks.md`](04-perilaku-dan-teks.md) | Aturan perilaku, kebijakan tugas berulang, pengaturan, teks (microcopy), fitur berbayar |
| [`06-penelitian-lanjutan-pixel8.md`](06-penelitian-lanjutan-pixel8.md) | Penelitian ulang 1 Okt 2026 (viewport Pixel 8): judul sebagai tombol dua peran, Month view lengkap, Someday sebagai daftar ("Add column"), drag and drop |
| [`07-daftar-notifikasi-dan-seret.md`](07-daftar-notifikasi-dan-seret.md) | Daftar/kolom Someday, halaman Notifications, tombol notifikasi, mekanisme seret (web) |
| [`08-aplikasi-mobile-android.md`](08-aplikasi-mobile-android.md) | **Aplikasi Android native** (perangkat fisik): bottom sheet kartu tugas, ukuran dp asli, Day view, Month, pengaturan, warna berona aksen — acuan utama untuk ponsel |
| [`09-fokus-hari-ini-dan-tipografi.md`](09-fokus-hari-ini-dan-tipografi.md) | 2 Okt 2026, ponsel: hari ini di baris atas (kapan berlaku, kapan tidak), CRUD penuh, ukuran dan bobot font terukur, Help Center |
| [`05-pelajaran-untuk-desain-kita.md`](05-pelajaran-untuk-desain-kita.md) | Diagnosis mengapa katalog kita terasa jelek, prinsip yang dipelajari, dan arah desain orisinal yang diusulkan |

Tangkapan layar disimpan di `docs/references/_private/tweek/` (tidak ikut git; lihat `docs/references/README.md`).

## Metode

1. **CSS**: seluruh stylesheet (`index-*.css`, 139 KB) diunduh dan diurai: 121 properti khusus, 1391 aturan, semua
   `@keyframes` dan `@media`.
2. **JavaScript**: bundel aplikasi (3,9 MB) diurai untuk objek tema (7 tema × terang/gelap) dan tabel teks.
3. **DOM langsung**: ukuran, font, warna, radius, transisi, dan animasi diukur dari elemen yang tampil (`getComputedStyle`,
   `getBoundingClientRect`) pada viewport ponsel 390×844 @3x dan desktop 1440×900 @2x.
4. **Pengujian interaktif** (dengan izin pemilik): membuat, mewarnai, menyelesaikan, dan menghapus tugas uji; membuka
   menu Repeat/Color/Reminder, dialog konfirmasi tugas berulang, menu profil, Settings, Appearance, Calendar settings,
   Month, Search; mencoba tema Finch dan Tody (gelap).
5. **Pemulihan**: semua perubahan dikembalikan (tema Tweek/Light; tugas "Hello" tanpa ulang; tugas uji dihapus).

### Catatan kejujuran tentang pengujian

Dua klik tebakan pertama saya tanpa sengaja menjadikan tugas "Hello" berulang harian dan hampir memicu penghapusan tugas
berulang. Dialog konfirmasi Tweek menahan hal itu, penghapusan **tidak** dikonfirmasi, dan tugasnya dikembalikan lewat
"Change recurrence → Apply". Sesudahnya semua klik dilakukan berdasarkan teks/elemen yang terverifikasi.

## Koreksi terhadap analisis sebelumnya

Analisis awal ([`../tweek-visual-analysis.md`](../tweek-visual-analysis.md)) hanya berdasar gambar pemasaran. Aplikasi
sebenarnya berbeda pada hal-hal berikut. **Yang berlaku adalah dokumen ini.**

| Klaim awal (dari gambar pemasaran) | Kenyataan di aplikasi |
|---|---|
| Kartu tugas adalah *bottom sheet* yang **ditinting warna tugas** | Kartu **melayang di atas** (margin atas 64, samping 12), warnanya **warna dialog tema** (mis. lavender), bukan warna tugas. Warna tugas hanya tampil sebagai titik pada ikon warna |
| Ada bar 5 ikon di dasar kartu yang **mengganti isi panel** | Ikon-ikon ada di **baris atas** kartu, kanan; tiap ikon membuka **popover** (menu) di bawahnya |
| Repeat = roda pemilih angka/satuan | Repeat = **menu**: Never / Daily / Weekly / Weekdays / Biweekly / Monthly / Annually / **Custom ›**. Roda hanya pada halaman Custom (dan di aplikasi native) |
| Pengingat = tiga roda | Web: popover kecil dengan panah tanggal, dua stepper jam dan menit, dan pil "Set reminder" |
| Warna tugas = pil di teks | Benar, tapi detailnya: pil setinggi baris (22 px), radius penuh, `padding 0 6px`, **satu baris** dengan elipsis; padding 6 px ada juga pada teks polos supaya tidak bergeser |
| Tema = "putih, hitam, biru, merah muda, krem, kuning, beige" | 7 tema bernama (Tweek, Jay, Tody, Finch, Sora, Weka, Ruff), tiap tema terang+gelap; mengganti **kertas dan satu aksen**; strukturnya identik |
| Font grotesque tebal | **Suisse Int'l** (Book 400 dan Bold 700 saja), lisensi komersial |
| Tampilan minggu ponsel = tumpukan hari | Benar; tiap hari selalu menampilkan **minimal dua baris berbaris**; garis dilukis sebagai gambar latar SVG |
