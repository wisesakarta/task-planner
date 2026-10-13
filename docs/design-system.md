# Sistem desain — versi 2 (mengikuti struktur Tweek, identitas milik sendiri)

Kode: `lib/features/todo/theme/` (token, palet, tipografi, gerak) dan `lib/features/todo/ui/` (komponen).
Riset dasar: [`docs/tweek-study/`](tweek-study/README.md). Keputusan pemilik: seluruh pertanyaan konkret
dijawab **"mengikuti Tweek"** — struktur, tata letak, dan interaksi mengikuti north star; **identitas
tetap milik kita** (lihat "Yang sengaja berbeda").

> Versi 1 (kartu tersinari, stabilo di dalam teks, roda pemilih, katalog komponen) dibuang karena dinilai
> jelek oleh pemilik. Salinan cadangan berada di luar snapshot publik.

## Prinsip

1. **Kertas dan tinta.** Satu warna kertas, satu warna tinta, satu aksen. Segala hal lain adalah tinta dengan
   transparansi berbeda (tangga `ink5 … ink90`).
2. **Struktur = isi.** Hari dipisah garis, bukan kotak. Tugas = satu baris 42 pt. Tidak ada kartu di dalam kartu.
3. **Gerak sedikit.** Perubahan *keadaan* terjadi seketika; hanya hal yang *muncul/pergi* yang bergerak.
4. **Aksesibel dari awal.** Target sentuh 48 pt, kontras WCAG diuji otomatis, skala teks 200%, *reduce motion*.

## Token

| Token | Nilai |
|---|---|
| Jarak (grid 4) | 4 · 8 · 12 · 16 · 20 · 24 · 32 · 48 |
| Radius | 6 (tombol kecil) · 12 (popover) · 16 (kartu grup, ubin) · 24 (kartu/panel/dialog) · pil 256 |
| Kontrol | 32 · 40 · 48 (lingkaran, pil, segmen) — target sentuh minimum 48 |
| Ritme minggu | margin 24 · baris 42 (garis 1 px di dalamnya) · header hari 42 (garis 2 px) · jarak antar hari 24 |
| Kartu | lebar maks 512 · 12 dari sisi · 64 dari atas · padding 24 |
| Ikon | 22 (kartu, baris) · 16 (kecil) |

## Warna

Tangga tinta: `ink5, ink10, ink15, ink20, ink25, ink40, ink50, ink65, ink75, ink90`. Fungsi:
`rule = ink10` (garis baris), `fill = ink5` (isian tenang), `textSecondary = ink65` (teks sekunder; 60% gagal 4.5 : 1
di atas permukaan bertinta), `scrim = 40% hitam`.

Enam keluarga tema × terang/gelap = 12 palet. Semua pasangan teks/latar diuji ≥ 4.5 : 1 (teks) dan ≥ 3 : 1 (kontrol)
di `test/features/todo/theme/theme_test.dart`.

| Tema | Kertas (terang) | Tinta | Aksen | Teks aksen* | Sheet (kartu) | Alert |
|---|---|---|---|---|---|---|
| **Paper** (default) | `#FFFFFF` | `#0B0B0C` | `#FF5000` | `#B83700` | `#FFE9DC` | `#FFF3EA` |
| Mist | `#F3F6FB` | `#0F1A26` | `#2A64F0` | `#1F4FCC` | `#DCE6FB` | `#E9F0FD` |
| Blush | `#FFF4F2` | `#2A1216` | `#D6336C` | `#B0245A` | `#FFDDE1` | `#FFEAEC` |
| Sage | `#F4F8F2` | `#122016` | `#2E7D4F` | `#1F6A40` | `#DCEBD8` | `#E9F3E6` |
| Sand (kertas krem hangat) | `#F7F1E6` | `#241B14` | `#B4530F` | `#96410A` | `#EEE4D1` | `#F1E8D8` |
| Charcoal (abu netral + teal) | `#F4F4F2` | `#161616` | `#0E7490` | `#0B6076` | `#E4E4E1` | `#EBEBE8` |

\* aksen yang dipakai sebagai warna *teks* (mis. tanggal hari ini) — versi lebih gelap agar lolos 4.5 : 1.
Varian gelap memiliki kertas ≈ hitam, tinta ≈ putih, dan aksen yang lebih terang.

**Warna tugas** (`todo_task_colors.dart`): delapan warna utama — Tomato, Lemon, Ink, Stone, Ocean, Amber, Mint,
Orchid — dan delapan tambahan (tombol "+") — Rose, Peach, Sand, Lime, Sky, Lavender, Forest, Plum.
Setiap warna dipetakan ke isian + teks di atasnya per palet sehingga teks selalu ≥ 4.5 : 1 (diuji dengan warna acak).

## Tipografi (Inter Tight, dibundel)

Diukur ulang terhadap Tweek di ponsel pada 2 Okt 2026 (tinggi huruf kapital + tebal batang, lihat
[`tweek-study/09`](tweek-study/09-fokus-hari-ini-dan-tipografi.md)). Kontrasnya sengaja curam: judul ExtraBold, teks baca Medium.

| Gaya | Ukuran/tinggi baris | Bobot | Dipakai untuk |
|---|---|---|---|
| `title` | 32/40 | 800, −0.2 | "Oct 2026", tahun di Month |
| `dayDate` | 22/28 | 800 | "30 Sep" (hari ini: aksen) |
| `dayName` | 22/28 | 500, ink65 | "Wed" (sebaris dengan tanggal) |
| `heading` | 22/28 | 800 | judul dialog/panel, "Someday" (tinta penuh) |
| `cardTitle` | 24/30 | 800 | judul di kartu tugas, angka stepper |
| `taskText` | 17/22 | 500 | tugas, catatan, isi |
| `rowLabel` / `sectionLabel` | 17/22 | 400 | baris/judul seksi pengaturan |
| `menuItem` | 15/22 | 500 | item popover, ubin, chip tanggal |
| `button` | 17/21 | 700 | tombol pil |
| `caption` / `small` | 14/20 · 12/18 | 400 | petunjuk, nilai |

Month: nama bulan 17/800, angka hari 14/800, huruf hari 11/500.
Berkas font: Regular, Medium, Bold, dan **ExtraBold** (instans statis wght=800 dari font variabel resmi v3.004, OFL tanpa
*Reserved Font Name*). Test memuat font asli lewat `test/flutter_test_config.dart`.

## Gerak

100 ms (`fast`) untuk umpan balik tekan; 200 ms (`medium`) untuk yang muncul/pergi; 300 ms hanya untuk centang
subtask dengan kurva *overshoot* `cubic(.68, −.55, .27, 1.55)`. Dialog naik 40 px sambil memudar, panel menu turun 8 px,
halaman pengaturan bergeser 24 px ke samping, ganti minggu = *cross-fade*. Dengan *reduce motion* semua durasi = 0.

## Komponen

`ui/controls/` — `RoundButton` (ink / soft / accent, 40 atau 32 di dalam target 48), `PillButton` (primary /
outlined / soft, destruktif), `TodoToggle` (40×24), `SegmentedControl` (jalur tinta, segmen terpilih = warna sheet),
`CheckToggle` (cincin+centang, overshoot 300 ms).

`ui/overlay/` — `showTodoDialog` (kartu mengambang), `showTodoPopover` (jangkar, balik bila tak muat, 12 dari tepi),
`showConfirm` / `showChoiceConfirm` (nada *alert*, tombol bertumpuk, pilihan radio).

`ui/week/` — `WeekScreen`, `WeekTopBar`, `DaySection`, `DayHeader`, `TaskRow`, `InlineComposer`.

`ui/card/` — `TaskCard` (tanggal, lima aksi, judul, catatan, subtask), `showRepeatMenu` (+ panel Custom),
`showColorPopover`, `showDatePopover`, `showReminderPopover`, `showMoreMenu`.

`ui/month/` — `MonthScreen` (Month view: daftar gulir menerus, baris 168, sel `(lebar−32)/7`, angka 24, pil 16/radius 4/11 pt, nama bulan 17/700 di atas kolom tanggal 1, minggu dipotong di batas bulan), `buildMonthRows`, `MonthMetrics`.

`ui/menu/` — `showMenuPanel` (bento → Appearance / Calendar / About), `showSearchCard`.

## Radius konsentris, tombol menu, dan prinsip "minimalis fungsional"

- **Radius konsentris** (terinspirasi aturan "radius luar = radius dalam + jarak"): segmen 9 di dalam jalur 12 dengan
  inset 3; kontrol Monday/Sunday (12) di dalam grup (16) dengan jarak 4. Dikunci di `controls_test` dan `menu_test`.
- **Tidak ada informasi dekoratif.** Ringkasan "2 left today · Next: …" di bawah judul pernah dicoba dan dibuang atas
  keberatan pemilik: konsepnya minimalis fungsional, jadi setiap elemen harus melakukan pekerjaan.
- Tombol menu (ikon tiga garis, aksen) menggantikan tombol "profil": aplikasi ini tidak punya akun. Nama aplikasi belum
  ditentukan; semua teks memakai konstanta `appName` (`lib/features/todo/app_info.dart`).

## Yang sengaja berbeda dari Tweek

- **Font**: Inter Tight (SIL Open Font License 1.1, disertakan di
  `assets/fonts/inter_tight/OFL.txt`), bukan Suisse Int'l.
- **Palet, nama tema, salinan teks, ikon**: milik kita (Paper/Mist/Blush/Sage, aksen oranye untuk Paper). Tidak ada
  maskot, ilustrasi, atau aset Tweek.
- **Target sentuh 48 pt** di setiap kontrol (Tweek memakai lingkaran 32/40 tanpa perluasan).
- **Judul bulan** yang beraksen (bukan minggu ini) memakai `accentInk`, bukan aksen murni, agar teksnya ≥ 4.5 : 1. Angka akhir pekan di Month view memakai `ink65` (Tweek ±25%).
- **Teks hari kerja** memakai `ink65` (bukan 60%) agar lolos kontras.
- **Selesai = opasitas 50% + coret** (dan cincin terisi); dijaga ≥ 3 : 1 untuk kontrol.
- **Menu Kalender/Tampilan** kita: Appearance, Calendar, About — sesuai fitur yang ada, bukan salinan menu Tweek.

## Pengujian

`theme_test` (kontras semua palet, tangga tinta, token), `controls_test`, `overlay_test`, `popovers_test`
(konfirmasi, repeat, warna, tanggal, pengingat, more, centang), `task_card_test`, `menu_test` (panel + pencarian),
`week_test`, `todo_app_test` (aplikasi utuh dengan penyimpanan tiruan). Semua komponen diuji di 12 palet, lebar
320–1200, skala teks 200%, dan *reduce motion*.

## Dragging a task

`ui/week/task_drag.dart`. Press and hold a row for 120 ms, then move.

- The carried copy sits on a panel of the page colour at **92%** (Tweek: 60%, but the line underneath then shows through the text), radius 4, 8 px wider than the row on each side, no bottom rule.
- The original row stays in place at 30%.
- Where it will land: a 2 px accent line with a 6 px dot at its start, between two rows (or under a day's header / above its spare line). No rows shift while carrying, so the target never flickers.
- Any y inside a day, including the 24 px gap under it, counts as that day. Letting go outside every day cancels.
- Haptics: medium on lift, selection click when the target changes, light on drop.
- Within 64 dp of the top or bottom edge of the list it scrolls.
- Screen readers get the actions "Move up", "Move down", "Move to the next day", "Move to the previous day" instead.

## Panels, composer, month, menu — revision after the phone review (2026-10-01)

Reviewed on a physical Android test device against Tweek's own Android app.

- **Panels from the task card** (date, repeat, colour, reminder, "…"): no longer small floating popovers. Opened from inside a card they are *attached*: as wide as the card (12 pt in from each side), 8 pt under the button row that opened them, on a surface one shade darker than the card (`ink5` over `sheet`), radius 16, **no outline**. A panel taller than what is left of the card makes the card grow (its colour and rounded bottom corners are painted down to 12 pt under the panel). Menus (`fill: true`) use the whole width; fixed-width content (calendar, time) stays centred. Popovers opened outside a card (and the subtask menu, `attached: false`) are still small floating menus.
- **"…" menu**: no empty check gutter (text starts 16 pt in); an icon ends each row (→, ⏩, ↓, copy). Only lists that show a current choice (Repeat) reserve a check slot.
- **Colour panel**: five dots to a row, each in a fifth of the panel.
- **Composer** (spare line of a day): completely flat while focused. No card, no shadow; the caret is the only sign (Tweek's phone app is flat too).
- **Row toggle**: the ring sits on the right margin under the end of the rule; the 48 pt target reaches out to its left.
- **Month** (measured from Tweek's Android app, 1 dp = 2.74 px): week row 138, first row of a month 202 (name block 64), numbers 16 bold in a 28 circle, weekend numbers quiet, **today = pale wash of the accent (18%) with ink number**, pills 18 high (3 gap), radius 5, 12 pt text, four pills then "+N more", weekday letters 13, the month's **full name** (20 bold) centred on the column of the 1st by its centre (it is wider than one column).
- **Menu**: just the four tiles (no logo, name or blurb: every element does work). Calendar icon is a plain calendar. Segmented controls centre their icon and label. "Week starts on" sits straight on the sheet, not in a second tinted box.
- **Notifications** page: when the phone blocks notifications, an alert with an **Open phone settings** button (Android `ACTION_APP_NOTIFICATION_SETTINGS` through a method channel `todo/system`, `MainActivity.kt` + `reminders/system_settings.dart`). The explanatory paragraph is gone.
