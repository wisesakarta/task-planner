# Todo

Sebuah planner mingguan dan daftar tugas untuk dipakai setiap hari. **Offline-first** (semua data ada di perangkat) dan
dirancang agar nanti bisa sinkron antar perangkat.

Aplikasi ini sedang dibangun secara bertahap dengan standar "insanely great dari awal", bukan MVP. Rencana, keputusan,
dan progres ada di [`TODO.md`](TODO.md).

## Jalankan

```
flutter pub get
flutter run -d <perangkat>                                        # aplikasi
flutter run -t lib/features/todo/design/catalog_main.dart         # katalog komponen desain
```

Android adalah target utama. iOS memerlukan macOS + Xcode (atau CI macOS); web berjalan tetapi pengingat tidak andal di sana.

## Uji

```
flutter analyze
flutter test                                                       # unit + widget
flutter test integration_test/catalog_test.dart -d <perangkat>     # end-to-end di perangkat
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/perf_test.dart --profile -d <perangkat> # performa
```

## Struktur

| Lokasi | Isi |
|---|---|
| `lib/app/` | akar aplikasi (`TodoApp`) |
| `lib/features/todo/model/` | model data: tugas, aturan ulang, subtask, pengaturan |
| `lib/features/todo/data/` | penyimpanan lokal (`TodoRepository` adalah satu-satunya pintu ke data) |
| `lib/features/todo/theme/` | token desain: palet, tipografi, gerak |
| `lib/features/todo/widget/` | komponen desain |
| `lib/features/todo/design/` | katalog komponen (alat tinjau, tidak dimuat aplikasi) |
| `docs/` | analisis visual, spesifikasi sistem desain, folder referensi |
| `test/`, `integration_test/`, `test_driver/` | pengujian |

## Dokumentasi

- [`TODO.md`](TODO.md) — rencana, keputusan desain, dan progres per fase
- [`docs/design-system.md`](docs/design-system.md) — token, komponen, gerak, aksesibilitas
- [`docs/tweek-visual-analysis.md`](docs/tweek-visual-analysis.md) — analisis referensi (inspirasi, bukan untuk ditiru)
- [`docs/references/`](docs/references/README.md) — referensi visual

## Lisensi

Lihat [`LICENSE`](LICENSE). Repositori ini bermula dari sebuah template pihak ketiga; template itu sudah dihapus dari
pohon kerja, tetapi masih ada di riwayat git.
