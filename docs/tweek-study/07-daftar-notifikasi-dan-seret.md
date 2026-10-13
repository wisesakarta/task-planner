# 07 — Daftar ("Someday columns"), notifikasi, dan seret-lepas (1 Oktober 2026)

Lanjutan [`06`](06-penelitian-lanjutan-pixel8.md): browser Chrome via MCP, akun Tweek Premium milik pemilik, viewport Pixel 8.
Hanya dibaca dan dibuka; tidak ada data yang diubah. Sumber tambahan: bundel JS/CSS aplikasi (tabel teks, aturan gaya).

## 1. Daftar di bawah minggu ("Someday columns")

- Di bawah hari Minggu ada **tiga daftar** bertumpuk. Daftar pertama berjudul **Someday**; dua lainnya tanpa judul (judul
  kosong tidak menampilkan petunjuk). Setiap daftar = judul (kolom teks, bisa diganti nama) + tombol **…** di kanan + baris
  berbaris seperti hari (minimal dua baris).
- Judul daftar: ±28 px / 700, **warna pudar** (tinta ~25%), garis 1 px di bawahnya.
- Menu **…** (popover tinta-tint, garis 1 px): pada daftar pertama **Move down · Add column**; pada daftar tengah **Move down ·
  Move up · Add column**. Di desktop ada juga "Move left / Move right". Hapus kolom meminta konfirmasi: *"Are you sure you want
  to delete this column?"* (Leave / Delete).
- **Pengaturan kalender → "Someday columns": 3 | 6** — jumlah kolom yang dipakai (pilihan segmented). Gagal menyimpan
  menampilkan: *"Could not save Someday columns. Check your connection and try again."*
- Di Month view daftar ini tidak muncul (hanya tugas bertanggal).

## 2. Halaman pengaturan (ponsel)

Panel hampir selayar penuh (margin 16, radius 24, warna dialog tema) dengan baris judul: tombol **‹** (kiri), judul di tengah,
tombol **✕** (kanan), keduanya bulat 40. Halaman-halaman: Your plan · **My calendar** · Add calendar · General · Appearance ·
Account · **Notifications** · Help & Support · About us · Log out.

**Calendar settings** (My calendar): Desktop layout (Classic | Side view) · Someday columns (3 | 6) · Move uncompleted tasks to
Today · Sort completed tasks · Hide completed tasks · Synchronization · Export tasks · Share calendar · Calendar ID.
Teks konfirmasi "Move to Today": *"By activating this feature all uncompleted tasks will be moved to the current day's section."*

**Notifications**: daftar pilihan bergaris-cek — *Push and email* (dipilih) · *Push notification* · *Email*; keterangan:
*"At least one notification method is required for task reminders."*

## 3. Notifikasi pengingat

Aksi pada notifikasi (tabel teks `notifications.actions.*`):

| Aksi | Teks |
|---|---|
| Selesaikan | **Mark as Completed** |
| Tunda 1 jam | **Remind Me in an Hour** |
| Tunda nanti | **Remind Me Later** |
| Tunda besok | **Remind Me Tomorrow** |

Yang kita ambil untuk aplikasi lokal: notifikasi berisi judul tugas dengan aksi **Mark as completed**, **Remind me in an
hour**, dan **Remind me tomorrow**; satu pengaturan "Notifications" (hidup/mati) menggantikan pilihan push/email karena kita
tanpa server.

## 4. Seret-lepas (drag and drop)

- Pustaka **@hello-pangea/dnd** (penerus react-beautiful-dnd): setiap tugas adalah `Draggable`; hari, daftar, dan sel bulan adalah
  `Droppable`. Sentuh: **tekan-tahan ±120 ms** lalu seret; papan ketik: spasi mulai, panah memindah, Esc batal; ada region
  `aria-live="assertive"` yang mengumumkan hasil.
- **Gaya baris yang terangkat** (`_dragging`): garis bawah hilang; di belakang baris muncul panel **kertas opasitas 60%**, radius 4,
  melebar **8 px** ke kiri dan kanan. Baris lain bergeser (±0,2 dtk) memberi ruang di tempat jatuh.
- Menjatuhkan di hari lain = mengubah **tanggal** tugas; di daftar = memindahkannya ke daftar itu (tanpa tanggal);
  di dalam satu hari/daftar = mengubah **urutan**.
- Di pengaturan, baris kalender juga dapat diseret (`_calendarRowDragging`: radius 16, latar tinta 5%).

## Yang kita terapkan

1. **Pengingat nyata** (Fase 5) dengan tiga aksi notifikasi dan pengaturan Notifications.
2. **Seret-lepas**: tekan-tahan lalu seret; pindah hari, pindah daftar, ubah urutan (perlu urutan tersimpan di model).
3. **Daftar Someday**: judul bisa diganti nama, menu … (Move up/down, Add column, Delete dengan konfirmasi), pengaturan jumlah
   (3 | 6).
