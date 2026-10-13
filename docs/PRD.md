# PRD — Todo Planner

**Status:** Draft v1.0 · 13 Oktober 2026
**Repository:** Todo Planner project snapshot
**Target awal:** Android pada perangkat fisik (Android 15)

## 1. Keputusan produk

Produk ini adalah **Todo Planner offline-first** yang menggabungkan:

- **Ketenangan dan orientasi waktu Tweek:** Week sebagai rumah aplikasi, hari sebagai wadah, input langsung di baris, Someday, warna sebagai penanda, dan navigasi kalender yang ringan.
- **Kedalaman eksekusi TickTick:** detail tugas bertahap, subtasks, notes, reminder, recurrence, search, prioritas/metadata opsional, kalender, dan focus support.
- **Identitas sendiri:** nama, palet, font, ikon, microcopy, aset, dan keputusan layout tidak menyalin produk referensi.

Produk tidak mengejar paritas jumlah fitur. **Maturity** berarti setiap fitur inti dapat dipercaya, dapat ditemukan, aman terhadap kehilangan data, dan tetap tenang ketika detailnya banyak.

## 2. Masalah yang diselesaikan

Pengguna memiliki dua kebutuhan yang sering bertabrakan:

1. Melihat minggu secara utuh tanpa tenggelam dalam daftar dan menu.
2. Mengelola tugas nyata yang memiliki tanggal, pengulangan, subtasks, notes, reminder, konteks, dan status.

Planner yang terlalu minimal kehilangan kemampuan eksekusi. Task manager yang terlalu padat membuat pengguna menghabiskan perhatian untuk mengelola alatnya sendiri.

**Solusi:** tampilkan struktur waktu yang tenang sebagai default, lalu buka kedalaman hanya ketika pengguna memilih sebuah tugas.

## 3. Visi dan prinsip

### 3.1 Visi

Dalam lima detik setelah membuka aplikasi, pengguna dapat menjawab:

- Apa yang harus saya kerjakan sekarang?
- Apa yang menunggu pada hari-hari berikutnya?
- Apa yang belum memiliki tanggal?
- Apa tindakan berikutnya untuk sebuah tugas?

### 3.2 Prinsip desain

1. **Week adalah rumah.** Tidak ada bottom navigation yang memecah orientasi pada core flow.
2. **Struktur adalah isi.** Hari dipisahkan ritme dan garis, bukan dashboard penuh kartu.
3. **Progressive disclosure.** Baris tugas hanya menunjukkan judul dan sinyal penting; detail berada pada Task Card.
4. **Capture harus murah.** Menambah tugas tidak boleh mengharuskan pengguna membuka form panjang.
5. **Metadata membantu keputusan.** Reminder, repeat, warna, prioritas, dan tag tidak boleh tampil sebagai dekorasi.
6. **Tidak ada kehilangan data.** Autosave, write serialization, backup saat korup, dan ekspor/impor adalah bagian produk.
7. **Offline-first.** Core task flow harus bekerja tanpa network dan tanpa akun.
8. **Aksesibel sejak awal.** Semua kontrol memiliki label, target sentuh minimum 48dp, kontras WCAG AA, dan dukungan TalkBack.
9. **Belajar, bukan menyalin.** Tweek dan TickTick menjadi sumber pembelajaran perilaku; identitas dan implementasi tetap orisinal.

## 4. Bukti riset

### 4.1 TODO dan repository

`TODO.md` menetapkan Week sebagai beranda, Someday, recurrence kaya, reminder, Month, search, drag-and-drop, offline-first, dan standar kualitas tinggi. Model, controller, Week UI, Month UI, reminder planner, dan sebagian besar test sudah tersedia.

Keadaan yang masih penting untuk PRD:

- **Someday columns** belum selesai.
- **Accessibility, 200% text scale, physical-device performance, dan integration test** masih menjadi gerbang kualitas.
- **Application ID, release identity, export/import, localization, sync, dan collaboration** belum selesai.
- **Reminder pada HiOS dengan layar mati** belum tervalidasi end-to-end.
- Perbedaan layout yang masih menunggu keputusan pemilik: margin, tinggi baris, jarak antarday, dan beberapa kontrol top bar.

### 4.2 Tweek — observasi live

**Package:** `so.tweek.android`
**Version observed:** `2.30.97`
**Device:** physical Android test device
**Method:** membuka aplikasi, membaca layar, accessibility dump, dan capture pada 13 Oktober 2026. Studi terdahulu di `docs/tweek-study/` mencakup CRUD, repeat, reminder, search, Month, Day, drag, dan settings.

Temuan live yang relevan:

- Layar utama menampilkan **bulan besar**, tombol avatar/akun, previous/next week, lalu daftar hari dengan ruang kosong yang tetap terarah.
- Saat data akun dimuat, hari dapat berisi tugas nyata dengan **checkbox di ujung kanan**, judul satu baris, dan elipsis untuk teks panjang.
- Avatar membuka menu ringkas empat ubin: **Share, Settings, Contact us, About**.
- Settings adalah halaman penuh dengan **Family, My Calendar, General, Appearance, Account, Notifications, Help & Support, About us**, dan Log out.
- Task Card mobile memakai bottom sheet, tanggal, notes, subtasks, toolbar Share/Repeat/Color/Reminder/Options, serta panel detail yang menempel pada card.
- Repeat, Color, Reminder, Options, Search, Month, Day, dan Someday sudah didokumentasikan di `docs/tweek-study/08...` dan `09...`.

### 4.3 TickTick — observasi live

**Package:** `com.ticktick.task`
**Version observed:** `8.2.2.0`
**Device:** physical Android test device
**Method:** membuka Inbox, task detail, task menu, drawer, Today, Calendar, Habit, dan Focus/Stopwatch pada 13 Oktober 2026. Data pengguna tidak diubah.

Temuan live yang relevan:

- **Inbox** memberi capture destination yang jelas, dengan count, task cards, tag, due date, dan subtasks.
- Drawer menyediakan **Today, Next 7 Days, Inbox, Subscribed Calendars, Tags, lists, Completed, Trash**, serta account/settings entry points.
- **Today** mengelompokkan task berdasarkan **High Priority** dan **No Priority**, menampilkan description, tag, due date, list, dan progress subtask.
- Task detail menyediakan title, overdue status, description, tag, subtasks, due date, dan action menu.
- Action menu menyediakan **Pin, Share, Won't Do, Delete, Add Subtask, Link Parent Task, Start Focus, Convert to Note, Attachment, Tags, Task Activities, More**.
- **Calendar** menampilkan minggu tanggal, all-day timeline, event/task cards, dan navigasi kalender.
- **Habit** dan **Focus/Stopwatch** menunjukkan ekosistem produktivitas yang matang, tetapi bukan bagian dari core Todo Planner.
- Kepadatan, warna status, list hierarchy, priority grouping, dan banyaknya entry point menunjukkan kemampuan eksekusi; sekaligus menjadi risiko distraksi jika dipindahkan mentah-mentah ke Week.

### 4.4 Kesimpulan kompetitif

| Area | Pelajaran dari Tweek | Pelajaran dari TickTick | Keputusan produk |
|---|---|---|---|
| Beranda | Week yang tenang dan mudah dipindai | Today/Inbox yang berorientasi kerja | **Week sebagai home**, Today sebagai fokus/shortcut |
| Capture | Ketik langsung pada spare row | Inbox dan quick add | Inline composer + Someday; Inbox tidak menjadi layar kedua yang wajib |
| Detail | Task Card dengan lima mode inti | Detail kaya, subtasks, tags, activities, attachments | Task Card progressive; detail lanjutan melalui More |
| Status | Warna dan checkbox | Priority, overdue, list, tag, progress | Warna sebagai sinyal primer; priority/status tambahan bersifat opsional |
| Waktu | Week, Month, Day, repeat, reminder | Today, Next 7 Days, Calendar, all-day timeline | Week + Month + Day + reminder; kalender eksternal fase berikutnya |
| Navigasi | Sedikit entry point | Drawer dan bottom navigation yang luas | Core tanpa bottom nav; Search dan Menu selalu tersedia |
| Ekosistem | Family/share/settings | Habit, focus, AI, calendar, attachments | Fokus pada Todo; integrasi dan focus menjadi fase lanjutan |

### 4.5 Notification architecture — decompile dan runtime

Audit read-only APK pada 13 Oktober 2026 memperjelas bahwa Tweek dan TickTick bukan implementasi yang sama. Tweek memakai Firebase Cloud Messaging sebagai notification ingress dan tidak mendeklarasikan exact-alarm permission; TickTick memakai local exact alarm dengan receiver, job/service, boot/timezone repair, action dispatcher, calendar reminder path, dan FCM untuk remote events. App kita sudah berada di jalur local-first yang tepat untuk offline-first, tetapi bukti `RTC_WAKEUP` hanya membuktikan alarm terdaftar, bukan notification terlihat pada layar mati HiOS.

Keputusan teknis: **pertahankan local exact alarm sebagai P0**, tambahkan repair/diagnostics seperti TickTick, dan simpan FCM sebagai lapisan sync/invalidation masa depan—bukan pengganti reminder lokal. Detail evidence, limitations, dan test matrix ada di [`docs/notification-audit.md`](notification-audit.md).

## 5. Target pengguna dan jobs-to-be-done

### Persona utama — individual planner

Orang yang mengelola pekerjaan, rumah, belajar, dan kebiasaan sederhana sendiri. Ia membutuhkan pandangan minggu, tetapi sering harus menyimpan detail operasional di balik tugas.

### Jobs-to-be-done

1. **Saat ide muncul**, saya ingin menulisnya langsung pada hari yang tepat atau Someday agar tidak kehilangan konteks.
2. **Saat merencanakan minggu**, saya ingin melihat kepadatan dan tugas tertunda tanpa membuka banyak layar.
3. **Saat mengerjakan tugas**, saya ingin membuka detail, subtasks, notes, reminder, dan repeat tanpa kehilangan judul yang sedang diedit.
4. **Saat hari berganti**, saya ingin tugas yang belum selesai tetap terlihat atau dipindahkan sesuai setting yang saya pilih.
5. **Saat menerima reminder**, saya ingin menyelesaikan, menunda satu jam, atau memindahkan ke besok dari notifikasi.
6. **Saat mencari kembali**, saya ingin menemukan tugas berdasarkan teks, tanggal, warna, dan metadata yang tersedia.

## 6. Arsitektur informasi

```text
Todo Planner
├── Week (home)
│   ├── Day sections
│   ├── Inline composer
│   └── Someday columns
├── Task Card
│   ├── Title / done
│   ├── Date / Month picker
│   ├── Repeat
│   ├── Color
│   ├── Reminder
│   ├── Notes
│   ├── Subtasks
│   └── More
├── Month
├── Day
├── Search
└── Menu / Settings
    ├── Appearance
    ├── Calendar
    ├── Notifications
    ├── Data
    └── About
```

**Aturan navigasi:**

- Week dibuka pada **hari ini**, bukan selalu Senin.
- Previous/next week membuka minggu baru dengan fokus pada Senin; kembali ke minggu berjalan mengembalikan fokus hari ini.
- Month memilih tanggal dan membuka Week pada tanggal tersebut.
- Back dari Month mengembalikan posisi scroll sebelumnya.
- Task Card dapat ditutup tanpa kehilangan edit yang sudah masuk.
- Search dan Settings tidak mengubah konteks week yang sedang dibuka.

## 7. Requirement fungsional

Prioritas: **P0** wajib untuk core quality gate, **P1** penting untuk maturity, **P2** fase lanjutan.

### 7.1 Week dan capture

| ID | Pri | Requirement | Acceptance criteria |
|---|---:|---|---|
| WK-01 | P0 | Week menjadi home | Cold start menampilkan minggu berjalan dan hari ini di posisi atas tanpa lompatan visual. |
| WK-02 | P0 | Day section | Setiap hari memiliki header, garis, task rows, dan spare row untuk mengetik. |
| WK-03 | P0 | Inline composer | Tap spare row → keyboard; Enter menyimpan task dan memindahkan caret ke row berikutnya. |
| WK-04 | P0 | Someday | Task tanpa due date memiliki tempat tetap dan tidak bercampur dengan hari. |
| WK-05 | P1 | Someday columns | Pengguna dapat rename, reorder, add, dan delete column dengan konfirmasi. |
| WK-06 | P0 | Completion | Tap toggle mengubah done/undone tanpa membuka card; state disimpan segera. |
| WK-07 | P0 | Drag and drop | Task dapat dipindah antarhari, diurutkan, dan dipindah ke/dari Someday; ada haptic, insertion marker, cancel, dan screen-reader actions. |
| WK-08 | P1 | Closed-day preview | Hari yang tertutup tetap memberi jumlah task dan titik warna agar bird's-eye view tidak hilang. |

### 7.2 Task Card dan detail

| ID | Pri | Requirement | Acceptance criteria |
|---|---:|---|---|
| TK-01 | P0 | Open task card | Tap body membuka card; tap checkbox tetap menjadi completion action. |
| TK-02 | P0 | Autosave | Title, notes, subtasks, date, color, repeat, dan reminder tersimpan bertahap; aksi diskret selalu flush edit sebelumnya. |
| TK-03 | P0 | Date | Task dapat dipindah ke tanggal lain atau Someday melalui Month/date picker. |
| TK-04 | P0 | Recurrence | Mendukung daily, weekly, weekdays, biweekly, monthly, annually, custom interval, end date, dan scope saat menghapus. |
| TK-05 | P0 | Reminder | Reminder memiliki tanggal/jam sendiri, tidak menggagalkan operasi task, dan dapat dijadwal ulang saat app start/reboot. |
| TK-06 | P0 | Color | Task dapat memakai palette color; warna menjadi highlight/signal, bukan satu-satunya arti task. |
| TK-07 | P0 | Subtasks | Subtask dapat ditambah, diselesaikan, diurutkan, diberi subtitle, di-indent sesuai batas, dan dihapus. |
| TK-08 | P0 | Notes | Notes mendukung teks panjang, empty state, dan autosave tanpa memaksa form terpisah. |
| TK-09 | P0 | Delete safety | Task biasa dihapus dengan konfirmasi/undo yang sesuai; recurring task meminta scope: this, this and future, atau all linked. |
| TK-10 | P1 | Metadata | Priority dan tags dapat ditambahkan di More tanpa memenuhi Week; tidak menggantikan warna sebagai sinyal utama. |
| TK-11 | P1 | Attachments | File/gambar disimpan lokal terlebih dahulu; metadata dan kegagalan storage terlihat jelas. |
| TK-12 | P1 | Activity/history | Perubahan penting dapat ditelusuri setelah sync atau audit trail tersedia; bukan alasan untuk membuat card penuh log. |

### 7.3 Views, search, dan settings

| ID | Pri | Requirement | Acceptance criteria |
|---|---:|---|---|
| VW-01 | P0 | Month view | Daftar bulan kontinu; task terlihat sebagai pill; tap tanggal membuka Week; tap task membuka card. |
| VW-02 | P1 | Day view | Day view menjadi zoom terarah dengan ruled rows dan navigasi per hari. |
| VW-03 | P0 | Search | Search teks menemukan title, notes, dan subtasks; filter warna tersedia; empty/error state dirancang. |
| VW-04 | P0 | Appearance | System/Light/Dark, tema orisinal, kontras, dan font scaling bekerja konsisten. |
| VW-05 | P0 | Calendar settings | Week starts Monday/Sunday; roll-over, sort completed, hide completed, dan week number memiliki label jelas. |
| VW-06 | P0 | Notifications | Pengguna dapat melihat status permission, membuka phone settings, enable/disable reminder, dan memahami keterbatasan vendor. |
| VW-07 | P1 | Data | Export/import JSON, backup sebelum replace, validasi schema, dan recovery dari data korup. |
| VW-08 | P2 | External calendars | Google/Apple/Outlook calendar read/write setelah sync dan privacy contract tersedia. |

### 7.4 Reliability dan platform

| ID | Pri | Requirement | Acceptance criteria |
|---|---:|---|---|
| RL-01 | P0 | Offline-first | Create/read/update/delete core bekerja tanpa network. |
| RL-02 | P0 | Serialized writes | Concurrent edits tidak menghapus perubahan terakhir dan tidak membuat lost update. |
| RL-03 | P0 | Corruption recovery | Entry rusak dilewati, backup dibuat, dan pengguna mendapat problem banner tanpa kehilangan draft. |
| RL-04 | P0 | Reminder isolation | Kegagalan scheduler tidak menggagalkan task mutation. |
| RL-05 | P0 | Physical validation | Android diuji pada device fisik; emulator hanya menjadi smoke/reference, bukan bukti alarm HiOS. |
| RL-06 | P1 | Test separation | Debug/integration build memakai application ID atau flavor terpisah dari data harian. |
| RL-07 | P1 | Accessibility | TalkBack, Semantics, keyboard/web navigation, 48dp targets, 200% text, dan reduce motion diuji. |
| RL-08 | P1 | Performance | Profile build mempertahankan 60fps pada device menengah dengan task list besar. |

## 8. Produk yang sengaja tidak dipindahkan mentah-mentah

### Dari Tweek

- **Tidak menyalin** nama, maskot, Suisse Int'l, palet, ilustrasi, dan aset.
- **Tidak menyalin** batasan bahwa task deletion tidak memiliki recovery; produk kita memprioritaskan data safety.
- **Tidak menyalin** akun/premium/paywall untuk aplikasi personal offline-first.
- Struktur Week, Someday, task card modes, recurrence, reminder, dan calendar navigation dipakai sebagai pembelajaran dan dirancang ulang dengan identitas sendiri.

### Dari TickTick

- **Tidak menjadikan** drawer besar, bottom navigation lima produk, Habit, AI, dan Focus sebagai core Todo surface.
- **Tidak memaksa** priority, tags, attachments, activity, dan list hierarchy tampil pada setiap row.
- Fitur maturity masuk melalui **More**, Search, Settings, atau fase terpisah agar Week tetap tenang.
- Tidak mengimpor data, akun, token, atau konten aplikasi pihak ketiga ke repository.

## 9. Data model dan technical direction

### 9.1 Local domain model

Entity minimum:

- `TodoTask`: `id`, `title`, `notes`, `dueDate`, `createdAt`, `updatedAt`, `completedAt`, `color`, `sortKey`, `reminderAt`, `recurrence`, `subtasks`, `deletedAt`, `syncState`.
- `TodoSubtask`: `id`, `title`, `subtitle`, `done`, `sortKey`, `indentLevel`.
- `TodoSettings`: theme, color mode, week start, roll-over, sort completed, hide completed, notification preference, Someday columns.
- Fase berikutnya: `priority`, `tags`, `attachments`, `activity`, `calendarBindings`.

### 9.2 Storage

- `TodoRepository` tetap menjadi boundary antara UI dan persistence.
- `SharedPreferences` JSON cukup untuk local phase; migrasi ke SQLite tidak boleh mengubah UI contract.
- Semua write penting diserialkan.
- Backup dibuat sebelum mengganti blob yang korup atau melakukan import.
- Tombstone dipertahankan untuk sync phase.

### 9.3 Sync dan account

Sync adalah **P2 product phase**, bukan syarat core offline app. Sebelum implementasi harus diputuskan:

- backend dan auth;
- conflict resolution;
- server/hybrid clock;
- tombstone retention;
- encryption/privacy policy;
- attachment storage dan quota.

Tidak boleh menambahkan account hanya untuk meniru TickTick atau Tweek.

## 10. Notification contract

Reminder harus memenuhi kontrak berikut:

1. Pengguna memilih tanggal dan waktu yang valid.
2. Aplikasi menunjukkan state permission secara jujur.
3. Notifikasi memiliki action **Done**, **In 1 hour**, dan **Tomorrow** jika platform mendukung.
4. Action dari background isolate membaca data terbaru dari disk.
5. Reminder tidak menghapus atau menggagalkan edit task.
6. Android vendor restriction, Doze, battery manager, Buzzkill, dan HiOS harus dicatat sebagai runtime limitation, bukan disamarkan sebagai bug yang sudah selesai.
7. Keberhasilan alarm dibuktikan dengan **notifikasi terlihat pada layar-mati device fisik**, bukan hanya `dumpsys alarm`.
8. `com.example.flutter_ui.calendar` harus diperlakukan sebagai identity/debug variant saja sampai mekanisme build-nya difinalisasi; suffix package tidak boleh menjadi workaround notification.
9. Diagnostics minimal menampilkan notification permission, exact-alarm capability, channel importance, next scheduled reminder, dan waktu reschedule terakhir.

## 11. UX quality bar

### Empty, loading, error

- Week kosong tetap memiliki spare rows dan Someday.
- Search kosong menjelaskan apa yang dapat dicari.
- Storage error mempertahankan teks yang sedang diketik dan memberi tindakan recovery.
- Permission denied memberi tombol **Open phone settings**.
- Import rusak tidak menimpa data lama.

### Visual dan motion

- Hirarki utama: title/day header **ExtraBold**, task text **Medium**, metadata lebih ringan.
- Tidak ada card nesting yang tidak memiliki fungsi.
- Surfaces dan rules boleh memiliki tint tema, tetapi kontras teks tetap diuji.
- Motion hanya digunakan untuk state transition; reduce motion mematikan durasi non-esensial.

### Accessibility

- Semua icon button memiliki `Semantics` label dan state.
- Target sentuh visual boleh 32–40dp, tetapi hit target minimum 48dp.
- Drag-and-drop selalu memiliki action alternatif untuk screen reader.
- Warna tidak boleh menjadi satu-satunya pembeda.
- Text scale 200% tidak boleh memotong title, date, menu, atau dialog.

## 12. Measurement plan

### Core success metrics

| Metric | Target | Cara verifikasi |
|---|---:|---|
| Time to first task | ≤ 5 detik | cold start → task tersimpan pada Week |
| Time to open detail | ≤ 1 detik setelah tap | physical device trace |
| Edit durability | 0 lost edits | test edit + action diskret + reload |
| Reminder action durability | 100% state consistent | notification action → disk reload → UI |
| Search usefulness | task ditemukan dengan title/notes/subtask | deterministic fixture test |
| Accessibility | 0 critical finding pada core flow | TalkBack/manual + semantics audit |
| Performance | 60fps target | profile build, large fixture, physical device |

### Evidence levels

- **PROVEN:** terlihat pada device atau lulus test yang relevan.
- **LIKELY:** konsisten dengan dokumentasi dan implementasi, tetapi belum diuji pada semua device.
- **POSSIBLE:** hipotesis desain/engineering yang masih perlu eksperimen.
- **UNKNOWN:** tidak boleh dipresentasikan sebagai fitur selesai.

## 13. Roadmap yang selaras dengan repository

### Phase A — Core quality gate

- selesaikan Someday columns;
- putuskan dan implementasikan layout deltas yang masih menunggu pemilik;
- Semantics, 48dp targets, 200% text, reduce motion;
- physical performance dan integration test pada flavor terpisah;
- uji ulang reminder dengan layar mati pada Infinix/HiOS;
- application ID, app name, icon, signing, privacy, dan export/import.

### Phase B — Maturity layer

- optional priority dan tags pada More/Search;
- richer task detail dan attachment contract;
- undo/recovery yang konsisten;
- Day view bila hasil uji Week + Month menunjukkan kebutuhan nyata;
- keyboard/web navigation dan seven-column wide layout.

### Phase C — Sync and integrations

- account/auth yang eksplisit;
- sync queue, retry/backoff, conflict resolution, server clock;
- calendar integrations, sharing, assignment, public links;
- widgets, print/export, dan attachments remote.

### Phase D — Optional productivity extensions

- Focus timer yang terhubung ke task;
- habit tracking terpisah dari Todo model;
- AI hanya bila privacy, cost, dan user value sudah terbukti.

## 14. Open decisions

1. **Nama produk dan application ID** belum dibekukan.
2. Apakah **priority/tags** masuk Phase B atau tetap ditiadakan untuk personal planner.
3. Bentuk final **Task Card**: floating card existing atau attached bottom-sheet pattern yang lebih dekat ke Tweek mobile.
4. Apakah **Day view** benar-benar dibutuhkan pada Android setelah Week + Month selesai.
5. Kebijakan **export/import**: plain JSON, encrypted backup, atau keduanya.
6. Backend dan auth untuk Phase C.
7. Batas attachment lokal: ukuran, tipe, backup, dan permission.

## 15. Definition of Done untuk PRD ini

PRD dianggap siap menjadi backlog ketika:

- setiap P0 memiliki acceptance criteria;
- setiap P1/P2 memiliki fase dan alasan;
- keputusan yang berasal dari Tweek/TickTick dibedakan dari keputusan orisinal;
- tidak ada klaim decompile atau network behavior yang belum dibuktikan;
- semua screenshot/device evidence berada di `docs/references/_private/tweek-mobile/`;
- `TODO.md`, `docs/design-system.md`, dan implementasi aktual tidak memiliki konflik tanpa dicatat sebagai open decision.

## 16. Evidence index

### Live device captures — 13 Oktober 2026

- Tweek home: `docs/references/_private/tweek-mobile/prd-tweek-home-20261013.png`
- Tweek menu: `docs/references/_private/tweek-mobile/prd-tweek-menu-20261013.png`
- Tweek settings: `docs/references/_private/tweek-mobile/prd-tweek-settings-20261013.png`
- TickTick Inbox: `docs/references/_private/tweek-mobile/prd-ticktick-home-20261013.png`
- TickTick task detail: `docs/references/_private/tweek-mobile/prd-ticktick-task-20261013.png`
- TickTick task menu: `docs/references/_private/tweek-mobile/prd-ticktick-task-menu-20261013.png`
- TickTick drawer: `docs/references/_private/tweek-mobile/prd-ticktick-drawer-20261013.png`
- TickTick Today: `docs/references/_private/tweek-mobile/prd-ticktick-today-20261013.png`
- TickTick Calendar: `docs/references/_private/tweek-mobile/prd-ticktick-calendar-20261013.png`
- TickTick Habit: `docs/references/_private/tweek-mobile/prd-ticktick-focus-20261013.png`
- TickTick Focus/Stopwatch: `docs/references/_private/tweek-mobile/prd-ticktick-focus-mode-20261013.png`

Accessibility XML dumps untuk state yang berhasil diambil berada di folder yang sama dan bersifat **private/ignored**. Capture Settings Tweek hanya memiliki screenshot karena `uiautomator` tidak mendapatkan idle state pada halaman tersebut.

### Repository sources

- `TODO.md`
- `docs/tweek-study/README.md`
- `docs/tweek-study/08-aplikasi-mobile-android.md`
- `docs/tweek-study/09-fokus-hari-ini-dan-tipografi.md`
- `docs/design-system.md`
- `docs/tweek-visual-analysis.md` sebagai konteks historis; bila bertentangan, studi live `08` dan `09` yang berlaku.
- `docs/notification-audit.md` untuk hasil decompile, manifest, dan runtime notification audit Tweek/TickTick/Todo Planner.
