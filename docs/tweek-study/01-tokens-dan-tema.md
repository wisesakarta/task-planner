# 01 — Token dan tema

Sumber: `.ds-v2` dan `:root` pada CSS, objek tema pada JS. Semua nilai diverifikasi terhadap DOM langsung.
Satuan piksel CSS.

## Pola terpenting: netral berasal dari tinta

Tweek tidak punya "abu-abu". Semua netral adalah **tinta pada alfa tertentu**:

| Token | Nilai | Dipakai untuk |
|---|---|---|
| `--ds-black-5` | tinta 5% | isi tombol sekunder, ubin, grup pengaturan, pil tugas di Month |
| `--ds-black-10` | tinta 10% | garis berbaris (SVG latar), pemisah |
| `--ds-black-15` | tinta 15% | garis bawah bidang teks |
| `--ds-black-20` | tinta 20% | nama hari (`opacity .2`), judul Someday |
| `--ds-black-25` | tinta 25% | jalur toggle (mati), garis kutipan editor |
| `--ds-black-40` | tinta 40% | judul seksi pengaturan, nama hari hari-ini (`.4`) |
| `--ds-black-50`/`60`/`75`/`90` | tinta 50–90% | teks sekunder, jalur toggle (nyala 75%), lencana |

Mode gelap **membalik token, bukan komponen**: `--ds-black` menjadi `#FFFFFF` dan `--ds-white` menjadi `#000000`;
`black-5/10/15` menjadi putih 12/15/20%. Akibatnya setiap komponen otomatis benar di gelap tanpa aturan tambahan, dan
setiap tema baru hanya perlu mengganti kertas + satu aksen.

## Warna

| Token | Nilai | Peran |
|---|---|---|
| `--ds-blue` / `cornflower` | `#5167F4` | aksen tema Tweek (hari ini, hover) |
| `--ds-purple` | `#BE9CF3` | avatar, tombol menu |
| `--ds-lightpurple` | `#E5D8FA` | panel menu profil dan pengaturan |
| `--ds-lightblue` / `lavender` | `#DCE1FD` / `#DDE1FB` | kartu tugas (tema Tweek) |
| `--ds-lightorange` | `#F8E9E2` | dialog konfirmasi, kenop toggle |
| `--ds-red` / `dangerred` | `#CD2C54` / `#DF525F` | warna tugas merah / aksi berbahaya ("Log out") |
| `--ds-yellow`, `green`, `cyan` | `#FEEE5D`, `#23FFA1`, `#98F4F9` | warna tugas / dekorasi |

### Warna tugas (pemilih, 9 + kustom)

Tanpa warna (lingkaran kosong berbingkai tinta 15%), `#CD2C54` merah, `#FDEF5D` kuning, `#000000` hitam, `#C2C2C2` abu,
`#5167F4` biru, `#FFAF23` jingga, `#21FFA1` hijau, `#D95CFE` ungu, dan **"+"** (warna kustom, isi tinta 5%, tanpa bingkai).

Warna teks di atas pil **ditetapkan per warna**, bukan dihitung: putih untuk biru, hitam, merah; hitam untuk abu, hijau,
ungu, jingga, kuning.

## Tema (objek JS, `light` dan `dark`)

| Tema | Terang: kertas / aksen | Gelap: kertas / aksen |
|---|---|---|
| **tweek** (bawaan) | `#FFFFFF` / `#5167F4` | `#000000` / `#5167F4` |
| **jay** | `#E4EAFF` / `#185856` | `#112827` / `#ACD2FF` |
| **tody** | `#FFE5E2` / `#001A9D` | `#131A3C` / `#FF9084` |
| **finch** | `#ECEAE3` / `#FF0601` | `#000000` / `#FF4541` |
| **sora** | `#FFEEC2` / `#0F5F5B` | `#0A2C2A` / `#FFD467` |
| **weka** | `#E8E2D1` / `#714E1D` | `#322A1F` / `#FFDD7B` |
| **ruff** | `#FFFFFF` / `#000000` (monokrom) | `#000000` / `#FFFFFF` |

Tinta terang selalu `#000`, tinta gelap selalu `#FFF`. Satu tema mendefinisikan: `accent`, `foreground`, `background`,
`calendar.taskHoverBorder` (aksen 40%), `header.{monthAccent, avatarBackground, avatarForeground, menuButton…,
roundButton…, dialogBackground}`, latar dialog per jenis (`taskDialog`, `secondaryDialog`, `searchTodoDialog`,
`calendarsListDialog`, `monthlyViewDialog`, `welcomeDialog`), `textField.border` (tinta 15%),
`richTextEditor.{link, blockquote.borderColor, activeButton.background}`.
Ada juga **tema kustom** (pengguna memilih aksen dan latar untuk terang dan gelap; tersinkron ke semua perangkat).

Contoh penerapan yang diamati: Finch = kertas krem + hari ini dan avatar merah; Tody gelap = kertas navy, tinta putih,
aksen koral, tombol navigasi berbalik menjadi **putih** berikon gelap. Struktur tidak berubah sama sekali.

## Bentuk dan ukuran

| Token | Nilai |
|---|---|
| Radius | `s 6` · `m 12` · `l 16` · `xl 24` · `menu 20` · `pill 256` |
| Tinggi kontrol | small 32 · medium 40 · large 48 |
| Ikon | 16 / 20 / 24 (di lapangan: ikon kartu 22) |
| Sel | token 52; **sel minggu 42** |
| Z-index | menu 1001 · popup 1003 · overlay dialog 1000 · modal 1300 · palet warna 1400 · konfirmasi palet 1500 |
| Bayangan | hanya satu, untuk menu: `0 8px 16px rgba(0,0,0,.10)`. Selebihnya **tanpa bayangan** |

## Tipografi

Font: **Suisse Int'l** (`@font-face` Book 400 dan Bold 700; bobot menengah 450 dipakai pada butir menu). Ikon kecil dalam
pil memakai Font Awesome Pro (light).

| Token | Ukuran / tinggi baris | Dipakai |
|---|---|---|
| `text-36` | 36 / 48 (bobot 700, tracking −1) | judul bulan (desktop) |
| `text-31` | 31 / 40 (700, −1) | judul bulan/tahun (ponsel) |
| `text-24` | 24 / 28 (400) | judul tugas di kartu |
| `text-21` | 21 / 24–28 (700, −0.5) | nama pengguna, judul dialog, header hari desktop, "Someday" |
| `text-body` | 17 / 22 | label baris pengaturan, judul bilah |
| baris tugas | 16 / 22 | judul tugas (ponsel dan desktop) |
| `text-15` | 15 / 20 | butir menu (450), lencana, segmen |
| `text-captions` | 14 / 20 | — |
| kecil | 12 / 18, 11 / 14 (500) | tanggal di kartu, inisial hari Month |

Header hari ponsel 18 / 28 (bold untuk tanggal, regular untuk nama hari). Hanya dua bobot inti (400 dan 700) di seluruh
aplikasi; hierarki datang dari **ukuran, bobot, dan alfa**.

## Garis berbaris

Latar tiap hari adalah gambar SVG, bukan elemen:

```
480 × 42 · <line y1="41.5" x2="480" y2="41.5" stroke="black" stroke-opacity="0.1"/>
```

Satu garis 1 px tinta 10% di dasar setiap sel 42 px, diulang. Hover pada sel yang bisa diketuk mengubah garis bawahnya
menjadi aksen 40% (`taskHoverBorder`).
