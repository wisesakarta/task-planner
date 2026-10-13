# 06 — Penelitian lanjutan (Pixel 8, 412×915 @2.625) — 1 Oktober 2026

Metode: browser Chrome lewat MCP, akun Tweek Premium milik pemilik yang sudah login, emulasi viewport Pixel 8 (412×915,
DPR 2.625, sentuh). Hanya membaca dan membuka tampilan; tidak ada tugas yang dibuat atau diubah. Tangkapan layar ada di
`docs/references/_private/tweek/r2_*.png` (tidak ikut git).

Satu-satunya acuan visual proyek ini adalah Tweek (keputusan pemilik 2026-10-01).

## Temuan baru (belum ada di dokumen 01–05)

### 1. Judul bulan adalah tombol dengan dua peran

| Keadaan | Warna judul | Ketuk judul |
|---|---|---|
| Sedang di **minggu ini** | tinta (hitam) | membuka **Month view** |
| Sedang di **minggu lain** | **aksen** (mis. "Jan 2026" berwarna biru) | **kembali ke minggu ini** |

Jadi warna judul adalah isyarat "kamu tidak di minggu ini", dan tidak ada tombol "Today" tersendiri. Judul tidak memiliki
label tombol di pohon aksesibilitas Tweek (kekurangan yang tidak kita tiru: kita memberinya label).

### 2. Month view (ponsel)

- **Satu daftar gulir vertikal menerus** semua bulan (bukan halaman per bulan). Membuka Month view menempatkan bulan ini di
  dekat atas.
- **Bilah atas** hanya judul **tahun** ("2026") dan dua tombol bulat hitam ‹ › (tanpa cari/profil). Di bawahnya baris huruf
  hari **M T W T F S S** (11 px / 500), bilah atas + huruf total 94.7 px, menempel di atas daftar.
- **Baris minggu** setinggi **168 px**, dengan **7 kolom** selebar (412 − 2×16)/7 = **54.3 px**; margin layar 16.
- **Minggu dipotong di batas bulan**: minggu 28 Sep – 4 Okt tampil sebagai dua baris — "28 29 30" (rata kiri, milik
  September) lalu "1 2 3 4" (rata kanan, milik Oktober).
- **Label bulan** ("Oct", 17/700, tinggi 38) muncul **di atas baris pertama bulan itu**, sejajar kolom tanggal 1
  (bukan di kiri). Baris pertama bulan = 38 + 168 = **206 px**. Garis 1 px tipis memisahkan baris.
- **Angka hari**: lingkaran 24 px, 14/700, tengah kolom, di bagian atas sel. **Hari ini** = lingkaran aksen dengan angka
  putih. **Sabtu dan Minggu** angkanya memudar (abu terang).
- **Tugas** = pil **16 px** tinggi, radius 4, latar tinta 6%, teks **11/500**, satu baris, margin bawah 2 px, selebar kolom.
- **Ketuk sebuah hari** → membuka **Week view** minggu itu. (Ketuk tugas membuka kartu tugas.)
- Tombol ‹ › menggulir daftar.

### 3. Someday adalah sebuah daftar ("kolom") yang bisa diatur

- Di bawah hari Minggu ada judul **Someday** (±28 px / 700, warna tinta pudar ~25%) dengan tombol **…** di kanan.
- Judulnya adalah **kolom teks** (bisa diganti nama); di pohon aksesibilitas ada kolom teks tambahan di bawahnya.
- Menu "…" (popover lavender, garis 1 px, radius 8): **Move down** dan **Add column** — pengguna dapat menambah daftar
  khusus lain di bawah minggu dan mengurutkannya.
- Fitur ini belum kita miliki; dicatat sebagai pekerjaan lanjutan (Fase 4+).

### 4. Drag and drop

Setiap tugas adalah elemen yang bisa diseret (pustaka dnd-kit: spasi untuk mulai, panah untuk memindah, Esc untuk batal;
ada region langsung `aria-live="assertive"` yang mengumumkan hasil). Memindah tugas antar hari = mengubah tanggalnya.
Aksesibilitas papan-ketik disediakan. (Fase 6 di rencana kita.)

### 5. Yang sama dengan temuan sebelumnya (dikonfirmasi)

Header hari "tanggal tebal kiri / nama hari pudar kanan" + garis 2 px (hari ini: aksen), baris 42 px dengan garis 1 px,
cek bulat di kanan, tombol bulat 40 (cari abu, profil berisi inisial warna lavender, ‹ › hitam), tanpa tombol "tambah".

## Yang kita terapkan dari temuan ini

1. Judul bulan berwarna **aksen** saat bukan minggu ini; ketuk = kembali ke minggu ini; ketuk di minggu ini = Month view.
2. **Month view** mengikuti spesifikasi di atas (dengan identitas kita: Inter Tight, palet kita, label semantik).
3. Ketuk hari di Month view → minggu itu; ketuk tugas → kartu tugas.

Di luar cakupan sekarang: daftar khusus (Add column / Move down), drag and drop.
