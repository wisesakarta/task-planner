> **Sebagian isi dokumen ini keliru.** Analisis ini dibuat dari gambar pemasaran. Setelah aplikasi Tweek dipelajari langsung,
> kartu tugas, Repeat, pengingat, dan warna ternyata berbeda. **Rujukan yang berlaku:** [`tweek-study/`](tweek-study/README.md)
> (lihat tabel "Koreksi terhadap analisis sebelumnya").

# Analisis visual Tweek — acuan desain Todo

Dokumen ini adalah acuan desain untuk aplikasi Todo. Tweek adalah **north star**: kita belajar dari
prinsip dan kualitas eksekusinya, lalu membangun bahasa visual **milik kita sendiri**. Kita tidak menyalin
nama, maskot, palet persis, atau aset Tweek.

> **Hanya inspirasi.** Dokumen ini mencatat apa yang dipelajari dari sebuah referensi. Aplikasi kita orisinal: tidak meniru
> tampilan, nama, maskot, atau aset siapa pun (lihat "Prinsip: orisinal dan autentik" di `TODO.md`). Referensi visual
> tambahan dikumpulkan di [`references/`](references/README.md).

## Metode dan batasan (baca dulu)

**Dasar analisis:** 11 gambar produk resmi dari [tweek.so/calendar/features](https://tweek.so/calendar/features)
(tampilan week di iPad, month, day, kartu tugas, repeat, reminder, pemilih warna, tema, pencarian, pengaturan,
berbagi), dilihat langsung, ditambah teks help center dan halaman fitur.

**Yang belum tercakup:**

- **Aplikasi hidup.** Aplikasi web/mobile Tweek butuh akun; saya tidak membuatkan akun atas namamu. Semua yang
  di bawah berasal dari gambar pemasaran, yang bisa sedikit berbeda dari aplikasi sebenarnya.
- **Gerak.** Animasi, transisi, haptics, dan perasaan drag & drop tidak terlihat di gambar statis. Spesifikasi gerak
  kita harus dirancang sendiri (Fase Desain), bukan disimpulkan dari Tweek.
- **Ukuran presisi.** Angka di bawah adalah perkiraan dari gambar (±), bukan token resmi.
- **Mobbin** (galeri layar aplikasi) tidak bisa dipakai: butuh paket berbayar.

Gambar sumber **tidak disimpan di repo** (hak cipta pihak lain); tautan sumber ada di akhir dokumen.

## 1. Bahasa visual

| Aspek | Pengamatan |
|---|---|
| Kanvas | Kertas krem hangat (≈ `#EDEAE3`), tinta hitam pekat. Nyaris monokrom; warna hanya muncul sebagai *data* (warna tugas) dan satu aksen "hari ini" |
| Aksen | Satu warna untuk "hari ini": merah pada tema default. Ikut berganti bersama tema |
| Tipografi | Grotesque tebal, tracking rapat. Judul sangat besar dan berbobot (mis. "2025", "23 Apr"). Nama hari ditulis ringan abu-abu di sisi kanan (`19 May ……… Mon`) |
| Garis | *Ruled paper*: garis rambut memisahkan baris. **Baris kosong tetap digaris**, sehingga halaman terasa seperti kertas dan kapasitas hari kelihatan |
| Bentuk | Sheet bawah bersudut besar (≈ 28), kartu pengelompokan bersudut sedang (≈ 16) berisi abu transparan, tombol utama berbentuk pil hitam penuh dengan teks putih tebal |
| Ikon | Garis tipis monokrom (1.5–2). Hanya sedikit ikon: centang lingkaran, lonceng, panah putar (ulang), kalender, titik tiga |
| Kontrol navigasi | Dua lingkaran hitam kecil (‹ ›) dan satu lingkaran berwarna (avatar) di kanan atas |
| Kepadatan | Tenang. Tidak ada bayangan berat, gradasi, atau dekorasi. Hierarki hanya dari ukuran, bobot, dan abu-abu |

## 2. Tampilan-tampilan

**Week — tablet.** Enam kolom sejajar; Sabtu dan Minggu ditumpuk di kolom terakhir. Header kolom: tanggal tebal di kiri, nama
hari abu di kanan, garis 2 px di bawahnya (merah untuk hari ini). Tiap baris punya centang lingkaran outline di kanan.
Di bawah minggu ada **Someday**: judul besar abu-abu, lalu kolom yang sejajar dengan kolom hari.

**Week — ponsel.** Hari bertumpuk vertikal dalam satu daftar yang di-scroll (bukan dipisah per layar), header sama seperti tablet.
Alasan yang disebut ulasan: dengan begitu drag & drop antar hari tidak canggung, dan pengguna memiliki *pandangan burung*
atas minggunya.

**Day.** Daftar polos, tanpa header hari, baris kosong tetap digaris sampai bawah layar.

**Month.** Grid 7 kolom. Setiap sel: nomor hari + pil mini tugas yang terpotong + "3 more". Hari ini = lingkaran merah di
nomor. Akhir pekan dan hari lampau dibuat redup. **Pil mengambang di dasar layar** berisi 3 ikon untuk berpindah
Month / Week / Day.

**Pencarian.** Kolom cari abu membulat + "Cancel"; di bawahnya baris titik warna sebagai filter (titik outline = tanpa warna);
hasil = daftar bergaris dengan pil warna.

**Pengaturan.** Kartu abu bersudut membulat dengan judul seksi tebal (Account, Calendars, Completed tasks), toggle hitam,
tombol pil hitam ("Add calendar"). Grup **Completed tasks** berisi tiga toggle: *Move to next day*, *Sort down*,
*Hide after complete*.

## 3. Baris tugas

- Tugas tanpa warna: teks polos di atas garis.
- Tugas berwarna: teks diberi **latar pil warna** (efek stabilo), bukan strip atau titik di pinggir.
- Ada awalan ikon **di dalam pil**: lonceng = punya pengingat, panah putar = berulang. Contoh: `🔔 13:00 Marketing sync`.
- Waktu tampil sebagai teks (`9:00`, `16:00`) di depan judul. Tidak jelas dari gambar apakah ini otomatis dari pengingat atau
  diketik pengguna (ada `14:00 Cooking class` tanpa lonceng), jadi **kita rancang sendiri**.
- Selesai: teks dicoret dan abu-abu, centang berubah menjadi lingkaran terisi abu.
- Pill hitam dengan teks putih adalah salah satu warna palet, bukan status khusus.

## 4. Kartu tugas (sheet bawah) — bagian paling khas

- Sheet modal dengan sudut besar, latar aplikasi meredup.
- **Seluruh sheet ditinting warna tugas** (tugas kuning → sheet kuning). Warna terasa sebagai "kertas tempel".
- Urutan isi: chip tanggal (ikon kalender + `Mon, 18 Mar`) → **judul besar tebal** dengan centang selesai di kanan →
  catatan (teks biasa) → **subtask** (lingkaran + teks; ada gagang di kanan; ada sub-judul dan indentasi 2 tingkat, mis.
  "Product launch 🚀" dengan anak "Friendly X post") → **lampiran** (kartu file PDF/XLSX, pratinjau gambar).
- Baris pilihan warna (titik-titik dengan centang pada yang aktif) tampil di dalam sheet.
- **Bar aksi bawah dengan 5 ikon**: *assign*, *repeat*, *warna*, *pengingat*, *lainnya (…)*. Ikon aktif ditandai **lingkaran
  hitam**, dan konten di atasnya **berganti sesuai mode**. Editor tugas bukan formulir panjang, melainkan satu kartu
  dengan lima mode.

## 5. Repeat

Halaman "Repeat" (sheet dengan tombol kembali):

1. **Pemilih roda** dua kolom: angka (1, 2, 3…) dan satuan (`day`, `week`, `month`, `year`).
2. Sub-pemilih menyesuaikan satuan:
   - year → grid 12 bulan (Jan…Dec);
   - month → grid tanggal 1–31, plus dua pilihan: *On the same day* / *Every second Friday*;
   - (week → tentu hari-hari dalam minggu; tidak terlihat di gambar, diperkirakan).
3. Baris **Ending — Never** (ke tanggal berakhir).
4. Kalimat ringkasan: "Repeat every year in January".
5. Tombol hitam **Apply**.

Konsekuensi: aturan seperti "setiap 2 minggu", "setiap Jumat kedua", "setiap 12 bulan Januari", dan tanggal berakhir tidak bisa
direpresentasikan enum sederhana. Perlu model aturan (mirip RRULE).

## 6. Pengingat

Pemilih roda **tiga kolom**: tanggal relatif (`Today`, `Tue 20 Feb` …), jam, menit; tombol **Set Reminder**. Notifikasi ditampilkan
sebagai pil hitam berisi nama aplikasi dan judul tugas. Pengingat memilih **tanggal sendiri**, jadi tidak harus sama dengan
tanggal jatuh tempo.

## 7. Warna dan tema

- Palet ±15 warna (putih, merah tua, kuning, hitam, abu, biru, oranye, hijau neon, ungu, teal, hijau, koral, lime, merah, abu
  gelap) + tombol **+** untuk warna kustom (pemilih gradien + input hex + Save).
- **Tema** mengubah seluruh aplikasi: putih, hitam, biru pucat, merah muda, krem, kuning, beige. Masing-masing punya **warna aksen
  hari ini** sendiri (biru, merah, hijau-teal, biru tua, coklat…).
- Warna tugas beradaptasi dengan tema (mis. pil kuning tetap terbaca di tema gelap).

## 8. Apa yang dikatakan pengguna tentang prinsipnya

Dari halaman *About* (testimoni): "If it's on the days list, I must do it… I don't allow myself to let things sit on the todo
list without getting done", "gives a bird-eye view of stuff to focus on", "a to-do list and a calendar mashed together".
Artinya produk ini dipakai sebagai **disiplin mingguan**, bukan gudang tugas. Ini memengaruhi keputusan seperti roll-over dan
Someday.

## 9. Implikasi bagi rencana kita

Temuan yang **mengubah** `TODO.md` (dibanding riset teks sebelumnya):

| # | Temuan | Dampak |
|---|---|---|
| 1 | Editor = kartu bawah dengan 5 mode + tinting warna | Editor dirancang ulang; bukan halaman formulir |
| 2 | Aturan ulang kaya (setiap N, tanggal dalam bulan, "Jumat ke-N", berakhir) | **Model `TodoRecurrence` (enum) dari Fase 1 tidak cukup**; ganti dengan `RecurrenceRule` |
| 3 | Pengingat memilih tanggal + jam sendiri | Ganti `dueMinutes` + `remind` dengan `reminderAt` |
| 4 | Warna kustom (hex) + palet | `colorId` (indeks) tidak cukup; simpan nilai warna |
| 5 | Subtask punya sub-judul dan 2 tingkat | Model subtask perlu `level` dan jenis (item / judul) |
| 6 | Tiga opsi "Completed tasks" | Tambah setting `sortCompletedDown`, `hideAfterComplete`, `moveToNextDay` |
| 7 | Tema seluruh aplikasi dengan aksen sendiri | Butuh sistem tema (bukan hanya terang/gelap) |
| 8 | Pil mengambang Month/Week/Day | Pola untuk pindah tampilan (bukan tab bawah) |
| 9 | Baris kosong tetap digaris | Detail identitas; masuk spesifikasi komponen |
| 10 | Font tebal khas | Bundel satu font grotesque (lisensi terbuka) supaya tanpa jaringan |

## 10. Yang dibedakan dari Tweek (identitas kita)

Kita mempertahankan warisan template: **aksen oranye**, **judul hari besar huruf kapital**, dan nada tegas. Kertas krem dan
maskot hitam adalah identitas Tweek, jadi kita pilih nada kertas dan aksen sendiri, dan menyimpannya sebagai token tema.

## Sumber

- [tweek.so/calendar](https://tweek.so/calendar) dan [halaman fitur](https://tweek.so/calendar/features) (gambar produk)
- [Bantuan: tugas berulang](https://help.tweek.so/article/143-how-to-set-up-recurring-tasks)
- [Bantuan: roll-over](https://help.tweek.so/article/113-is-it-possible-to-automatically-move-uncompleted-tasks-to-the-next-day-so-i-dont-forget-to-complete-them)
- [App Store](https://apps.apple.com/us/app/tweek-minimal-weekly-planner/id1535438855)
- [Harga](https://tweek.so/calendar/pricing)
