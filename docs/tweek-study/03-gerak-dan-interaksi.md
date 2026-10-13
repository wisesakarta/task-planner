# 03 — Gerak dan interaksi

Sumber: `@keyframes`, `transition`, dan `animation` pada CSS; diperiksa langsung dengan `getComputedStyle`.

## Prinsip gerak Tweek

1. **Sangat sedikit gerak.** Hanya dua durasi dasar: `fast 0,1 s` dan `medium 0,2 s`, dengan kurva `ease`.
2. Hampir semua perubahan status **instan**: menyelesaikan tugas, memberi warna, berganti tampilan. Gerak dipakai hanya
   untuk *hal yang muncul atau pergi* (dialog, panel, menu).
3. Gerak masuk = geser pendek + fade; gerak keluar = fade + geser yang sama.
4. Satu-satunya "hiasan" bergerak adalah maskot (animasi `dance`, `squat` 1 dtk) dan tanda centang subtask yang melenting.
5. `prefers-reduced-motion: reduce` mematikan animasi maskot; komponen inti sudah instan.

## Token

`--ds-duration-fast .1s` · `--ds-duration-medium .2s` · `--ds-ease ease` · `--ds-duration-squat 1s`.

## Keyframes dan pemakaiannya

| Nama | Efek | Durasi | Dipakai |
|---|---|---|---|
| `slideIn` (isi dialog) | dari `translateY(40px)` + `opacity 0` ke posisi | **0,2 s** | kartu tugas, dialog, kartu Search |
| `slideOut` | ke `translateY(40px)`, `opacity 0`, `z-index −1` | 0,2 s | menutup dialog |
| `fadeIn` / `fadeOut` (backdrop) | `opacity 0↔1` | 0,2 s | latar belakang dialog |
| `panel-in` | dari `translateY(−8px)` + `opacity 0` | 0,2 s | panel menu profil |
| `tweek-menu-panel-enter-right/left` | dari `translateX(±24px)` + `opacity 0` | (view transition) | sub-halaman pengaturan (maju/mundur) |
| `tweek-menu-panel-exit-left/right` | ke `translateX(∓24px)` + `opacity 0` | (view transition) | keluar sub-halaman |
| `menu-in` | `opacity 0→1` | — | popover Repeat/Color |
| `tooltip-in` | `opacity 0→1` | — | tooltip |
| `amCheckboxIn` | `scale(0) rotate(45deg)` + `opacity 0` → `scale(1) rotate(45deg)` | **0,3 s**, `cubic-bezier(.68, −.55, .27, 1.55)` (melenting) | tanda centang subtask |
| `amCheckboxOut` | `opacity 1→0` | — | centang hilang |
| `pulseOut`, `rotate`, `syncing-dot` | denyut / putar | — | indikator sinkronisasi |

Transisi tingkat komponen:

| Elemen | Transisi |
|---|---|
| Kartu dialog | `opacity 0,3 s, transform 0,3 s` |
| Panel menu (lebar) | `width 0,2 s` |
| Ubin menu | `background-color 0,2 s` |
| Tombol bulat kecil, segmented | `background-color 0,1 s` |
| Sel tugas (hover) | garis bawah berubah ke aksen 40% (tanpa durasi eksplisit) |

## Keadaan

| Keadaan | Tampilan |
|---|---|
| Hover sel | garis bawah menjadi aksen 40% (terverifikasi dari CSS dan tangkapan layar) |
| Tugas selesai | `line-through`, teks dan ikon alfa 0,3, cakram terisi; **instan** |
| Tugas diseret | pseudo-elemen latar kertas alfa 0,6, keluar 8 px dari kiri dan kanan, radius 4; garis bawah hilang |
| Ikon kartu aktif | lingkaran hitam 32 px di belakang ikon |
| Menu terbuka | ikon pemicu tetap "aktif" (lingkaran hitam) selama popover tampil |
| Tombol nonaktif | mis. tombol tautan di editor: kelas `--disabled` (lebih redup) |

## Alur yang diamati

### Tambah cepat (sangat penting)

1. Ketuk baris kosong pada sebuah hari → baris itu menjadi bidang teks (fokus, kursor).
2. Ketik judul lalu **Enter**: tugas tersimpan, dan **baris kosong berikutnya langsung menjadi bidang teks baru**
   (kartu putih kecil melayang berbayangan halus, keluar 8 px dari margin, tinggi baris) sehingga entri beruntun tanpa
   berhenti.
3. Tidak ada tombol "tambah", tidak ada layar tambahan.

### Menyelesaikan
Ketuk lingkaran di kanan baris: **instan** (coret + pudar + cakram). Ketuk lagi: kembali. Bila "Sort completed tasks"
aktif, tugas selesai pindah ke bawah hari itu.

### Membuka kartu
Ketuk teks tugas → kartu masuk (geser 40 px + fade 0,2 s) di atas latar gelap; ketuk latar di luar kartu untuk menutup
(seluruh dialog, termasuk popover yang terbuka, tertutup **satu per satu**: popover dulu bila diketuk di dalam kartu).

### Menghapus
Ikon tempat sampah di kartu: untuk tugas **tunggal**, terhapus langsung tanpa konfirmasi (tidak terlihat toast undo).
Untuk tugas **berulang**, muncul dialog pilihan (lihat `04-perilaku-dan-teks.md`).

### Pengaturan
Ketuk avatar → panel menu masuk dari atas; ketuk "Settings" → panel meluas ke tinggi penuh; tiap halaman lanjutan
bergeser horizontal dengan tombol ‹ dan × di bilah judul.

### Berpindah waktu
Tombol ‹ › pada bilah atas menggeser satu minggu (ponsel dan desktop). Ketuk judul bulan → tampilan Month; ketuk hari di
Month → kembali ke minggu itu.

## Yang tidak dilakukan Tweek (juga pelajaran)

- Tidak ada animasi saat tugas selesai selain perubahan gaya; tidak ada konfeti, tidak ada bunyi.
- Tidak ada bayangan bertingkat atau efek kaca; hanya satu bayangan menu.
- Tidak ada perubahan tata letak yang mengejutkan: baris kosong cadangan selalu ada sehingga menambah tugas tidak
  menggeser apa pun di bawahnya lebih dari satu baris.
