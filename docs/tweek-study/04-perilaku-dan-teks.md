# 04 — Perilaku, kebijakan, dan teks

## Model konten

| Konsep | Perilaku |
|---|---|
| Kalender | akun punya beberapa kalender ("My calendar", "Family", "Work"…); dapat dibagikan; tiap kalender punya pengaturan sendiri |
| Hari | tiap hari = daftar tugas berurut; **tidak ada jam**; jam hanya ada pada pengingat |
| Someday | daftar tanpa tanggal di dasar minggu; 3 atau 6 kolom; kolom bisa diganti nama, disembunyikan, digeser maju/mundur, diberi indentasi, dijadikan **heading** |
| Tugas | judul, catatan (rich text: heading, bold, italic, daftar, rata, tautan), subtask (bisa bercabang/bersub-judul), lampiran (Premium), warna, ulang, pengingat, penugasan (kolaborasi) |
| Warna | 9 preset + kustom; juga filter pencarian |
| Berbagi | tugas tunggal atau seluruh kalender; peran (pemilik, bisa edit); tautan publik; "Leave task/calendar" |

## Tugas berulang (bagian yang sebelumnya tidak terdokumentasi)

### Preset
`Never`, `Daily`, `Weekly`, `Weekdays`, `Biweekly`, `Monthly`, `Annually`, `Custom ›`. Preset terpilih diberi centang;
"Custom" membuka halaman dengan interval dan satuan (hari/minggu/bulan/tahun), pemilih bulan/tanggal, opsi seperti
"On the same day" / "Every second Friday", dan **Ending** (Never atau tanggal).
*(Bagian Custom diambil dari gambar pemasaran; halaman ini belum dibuka langsung pada sesi studi, jadi rincian tepatnya perlu dikonfirmasi.)*

### Instansi virtual
Tugas berulang tampil pada setiap tanggal (mis. muncul di 1, 2, 3 Oct…) dengan **ikon ulang di depan judul** (Font Awesome
12 px). Instansi masa depan tidak disimpan satu per satu: mereka dihitung dari aturan.

### Mengubah aturan → dialog konfirmasi
Judul **"Change recurrence?"**. Isi: *"Are you sure you want to change task's recurrent settings? This will end the
current cycle and some future tasks may become inaccessible."* Tombol: **Apply** (utama) dan **Cancel**.
Memilih "Never" pada tugas berulang memicu dialog ini; **Apply** menghentikan siklus dan mengembalikan tugas menjadi
tunggal (semua salinan masa depan hilang).

### Menghapus → dialog tiga pilihan
Judul **"Delete reccurent task?"** (ejaan asli ada salah ketik). Isi: *"This item is linked with other recurrent entries.
Editing or deleting one will affect other."* Pilihan (radio, bawaan terpilih pertama):
1. **Only this item**
2. **This and all future items**
3. **All linked items**

Tombol **Ok** (hitam) dan **Cancel** (bingkai). Ini menjawab pertanyaan lama "hanya yang ini / semua": Tweek menawarkan
*tiga* cakupan, dengan **hanya yang ini** sebagai bawaan yang paling aman.

### Memindahkan
Ada modal khusus "Move recurring task?" saat tugas berulang dipindah (seret) ke hari lain.

### Pengingat
Tidak dapat dipasang pada tugas berulang yang tanggalnya sudah lewat (popup penjelasan). Di web, pengingat dipilih lewat
popover (tanggal ‹ ›, jam dan menit); di aplikasi native lewat roda.

## Pengaturan kalender

| Pengaturan | Efek |
|---|---|
| **Move uncompleted tasks to Today** | dengan konfirmasi ("Move to Today" — *By activating this feature all uncompleted tasks will be moved to the current day's section.*). Default mati. Menonaktifkan diri sendiri setelah 21 hari tanpa suntingan (dokumentasi bantuan) |
| **Sort completed tasks** | tugas selesai turun ke bawah hari |
| **Hide completed tasks** | tugas selesai tidak ditampilkan |
| **Someday columns** | 3 atau 6 |
| **Desktop layout** | *Classic* (minggu di atas, Someday di bawah) atau *Side view* (Someday di samping) |
| **Week starts on**, **Week numbers**, **Date format**, **Language** | pengaturan umum |
| **Time zone** | terdeteksi otomatis; hanya dinyatakan sebagai catatan di dasar halaman |
| **Synchronization** | Google Calendar, Outlook Calendar, Linear (toggle) |

## Menu konteks tugas (klik kanan / tekan lama)

Dari tabel teks: **Tomorrow**, **Next week** (pindah cepat), **Duplicate**, **Attach**, **Leave task** (bila dibagikan).
Perpindahan cepat ke besok dan pekan depan tersedia tanpa membuka kartu.

## Penyimpanan dan kerja sama

- Backend Google Cloud Firestore; sinkron waktu nyata antar perangkat; kalender bersama **gratis untuk jumlah pengguna tak
  terbatas** (Premium menambah integrasi dan fitur, bukan kolaborasi).
- API terbuka (kunci dan OAuth dengan lingkup "See your tasks" / "Add and update tasks"), integrasi AI melalui **MCP**
  ("Connect AI apps via MCP" pada menu profil), ekspor tugas berformat ICS dengan rentang tanggal.
- Kesalahan simpan dijelaskan dengan bahasa jelas dan solusi: *"Could not save Someday columns. Check your connection and
  try again."*

## Fitur Premium (yang terlihat)

Sinkron kalender Google/Apple/Outlook, subtask dan lampiran, tugas berulang dan pengingat (di paket gratis dibatasi),
banyak kolom Someday dan kalender, tampilan Month, tema kustom, sembunyikan tugas selesai. Harga: $5,99/bulan atau
$49,99/tahun; paket keluarga $9,99/$89,99.

## Nada teks (microcopy)

- Pendek, kalimat aktif, tanpa tanda seru: "Add subtask…", "Add some extra notes here…", "Set reminder", "Apply", "Ok".
- Placeholder memakai **elipsis tipografis** (…) dan berbentuk ajakan.
- Dialog menjelaskan **akibatnya**, bukan hanya menanyakan ("…this will end the current cycle and some future tasks may
  become inaccessible").
- Nama tema pendek dan bernama diri (Tweek, Jay, Tody, Finch, Sora, Weka, Ruff), tanpa deskripsi.
- Aksi berbahaya berwarna merah tanpa ikon ("Log out").
