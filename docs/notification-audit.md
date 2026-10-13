# Notification System Audit — Tweek, TickTick, dan Todo Planner

**Status:** read-only audit
**Tanggal:** 13 Oktober 2026
**Device:** physical Android test device
**Scope:** installed APK manifest, compiled components, JADX output, dan runtime state Android. Tidak ada task, reminder, account, atau setting pada Tweek/TickTick yang diubah.

## 1. Kesimpulan langsung

Tweek dan TickTick menyelesaikan masalah notification dengan dua model yang berbeda:

| Produk | Model reminder utama | Bukti compiled/runtime | Implikasi |
|---|---|---|---|
| Tweek | **Remote/server-driven push** melalui Firebase Cloud Messaging | `TweekMessagingService`, `PushNotifier`, `PushActionReceiver`; tidak ada `USE_EXACT_ALARM` atau `SCHEDULE_EXACT_ALARM`; tidak terlihat sebagai owner alarm reminder pada snapshot device | Cocok untuk akun/cloud-centric; delivery reminder bergantung pada backend dan push transport |
| TickTick | **Local exact alarm + repair/sync pipeline**, ditambah FCM untuk remote events | Exact-alarm permissions, `TaskAlertReceiver`, `AlertService`, `TaskAlertJobService`, boot/timezone rescheduling, FCM `PushMessagingService`; runtime memiliki `TASK_ALERT_SCHEDULE` dan `CALENDAR_ALERT_SCHEDULE` | Cocok untuk reminder lokal yang tahan offline, reboot, dan perubahan kalender |
| Todo Planner | **Local-first exact alarm** dengan fallback inexact dan background action isolate | `flutter_local_notifications`, `USE_EXACT_ALARM`, scheduled/action/boot receivers; runtime memiliki `RTC_WAKEUP` untuk `com.example.flutter_ui` | Arah saat ini benar untuk offline-first, tetapi acceptance layar mati HiOS masih belum terbukti |

**Keputusan PRD:** jangan mengganti local alarm kita dengan FCM hanya karena Tweek memakai FCM. Tweek adalah pembanding model cloud delivery; TickTick adalah pembanding reliability dan recovery. Arsitektur target kita sebaiknya local alarm sebagai source of truth, lalu push/sync ditambahkan nanti untuk invalidation atau multi-device event.

## 2. Artefak dan metode

APK yang sedang terpasang dipull secara read-only ke:

```text
docs/references/_private/apk-analysis/tweek/
docs/references/_private/apk-analysis/ticktick/
docs/references/_private/apk-analysis/ours/base/
docs/references/_private/apk-analysis/ours/calendar/
```

Tool yang digunakan:

- `apkanalyzer` untuk package identity, permission, dan component manifest.
- `jadx` v1.5.6 untuk source inspection; decompile penuh TickTick memproses 15.577 class dan selesai dengan 138 error akibat obfuscation/unsupported bytecode.
- `adb` untuk `dumpsys alarm`, `dumpsys notification`, `dumpsys package`, dan `cmd appops`.

Hasil decompile dan APK sengaja tidak dimasukkan ke tracked docs karena mengandung binary dan source hasil reverse engineering. Report ini hanya menyimpan temuan yang diperlukan untuk desain produk.

## 3. Tweek — notification ingress melalui FCM

### 3.1 Manifest

Observed package: `so.tweek.android`, version `2.30.97`, target SDK 36.

Permission notification yang relevan:

- `POST_NOTIFICATIONS`
- `RECEIVE_BOOT_COMPLETED`
- `WAKE_LOCK`, `VIBRATE`, `FOREGROUND_SERVICE`
- Firebase Cloud Messaging receive permission

Manifest **tidak** mendeklarasikan `USE_EXACT_ALARM` atau `SCHEDULE_EXACT_ALARM`. Komponen notification yang terlihat adalah `so.tweek.push.TweekMessagingService` dan `so.tweek.push.PushActionReceiver`, bukan scheduled-notification receiver lokal.

### 3.2 Hasil source inspection

JADX berhasil membaca class berikut:

- `TweekMessagingService`: membaca title/body dari notification payload atau data payload, mengambil `kind`, lalu meneruskannya ke `PushNotifier`.
- `PushTokenProvider`: mengambil Firebase registration token dan menyimpannya ke koleksi cloud `messaging` untuk user yang login.
- `PushNotifier`: membuat channel `reminder`, `universalLink`, dan `general`; reminder menampilkan tiga action: mark completed, remind in hour, dan remind tomorrow.
- `PushActionReceiver`: menulis perubahan task ke Firestore (`done` atau `notifyAt` baru), kemudian membatalkan notification memakai notification ID.
- `NotificationPermission`: meminta `POST_NOTIFICATIONS` pada Android 13+ jika user Firebase sudah tersedia; request dijaga agar tidak berulang dalam process tersebut.

Tweek juga memiliki in-app toast untuk notification general ketika app sedang foreground. Tap notification membuka `MainActivity` dengan task ID atau universal link.

### 3.3 Batas bukti

Compiled app membuktikan **notification ingress dan action path**, bukan implementasi backend scheduler. Kita tidak dapat menyimpulkan detail kapan backend mengirim push atau SLA delivery tanpa akses server Tweek. Namun, gabungan manifest, source, dan runtime cukup kuat untuk menyimpulkan bahwa Tweek bukan referensi local exact-alarm delivery.

## 4. TickTick — local alarm dengan repair dan action pipeline

### 4.1 Manifest dan runtime

Observed package: `com.ticktick.task`, version `8.2.2.0`, target SDK 37.

Permission relevan:

- `POST_NOTIFICATIONS`
- `USE_EXACT_ALARM`
- `SCHEDULE_EXACT_ALARM` dengan batas SDK lama
- `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`, `VIBRATE`
- `USE_FULL_SCREEN_INTENT` dan foreground service permissions untuk popup/focus/audio paths
- calendar read/write untuk subscribed calendar reminders

Komponen notification yang terdaftar meliputi:

- `TaskAlertReceiver` → `TaskAlertJobService` / `AlertService`
- `CalendarAlertReceiver` → `CalendarAlertJobService` / `AlertCalendarReminderService`
- `DailyScheduleReceiver`, `DailyReminderReceiver`
- `BootCompletedReceive`
- `AlertActionService`, `AlertActionDispatchActivity`, `ReminderPopupActivity`, `SnoozePopupActivity`
- `ReminderPopupDispatcherService`, `ReminderPlayJobService`, `PushMessagingService`

Runtime device memperlihatkan alarm aktif milik TickTick dengan tag:

```text
com.ticktick.task.action.TASK_ALERT_SCHEDULE
com.ticktick.task.action.CALENDAR_ALERT_SCHEDULE
com.ticktick.task.action.DailyScheduleAction
com.ticktick.task.action.DailyScheduleZeroClockAction
com.ticktick.task.action.notificaitonDailySummary
```

Runtime juga memperlihatkan channel `task_reminder_notification_channel` dan notification task reminder dengan action `View` serta `Plan Now`; habit reminder memiliki `Complete` dan `Snooze`.

### 4.2 Hasil source inspection

Class decompiled yang paling informatif:

- `jd.d` (`AlertServiceHandler`): memilih handler reminder, memproses `TASK_ALERT_SCHEDULE`, menjalankan schedule handler, dan menjadwalkan ulang pemeriksaan berikutnya. Ia memakai `AlarmManagerUtils.setAndAllowWhileIdle` dan menyimpan `lastAlertScheduleTime`.
- `TaskAlertReceiver`: memvalidasi action reminder, meneruskan pekerjaan ke `AlertService`, dan menggunakan `TaskAlertJobService` sebagai jalur job.
- `CalendarAlertReceiver`: memisahkan calendar event reminders dari task reminders dan memakai service/job pipeline sendiri.
- `BootCompletedReceive`: menerjemahkan `BOOT_COMPLETED` menjadi internal boot action.
- `DailyScheduleReceiver`: melakukan reschedule pada boot, time set, timezone changed, dan daily actions; memakai `AlarmManagerUtils.setAndAllowWhileIdle`.
- `jd.a` (`AlertActionServiceHandler`): memetakan action notification ke open, delete/cancel, mark done, snooze, calendar open/delete/archive, habit action, dan daily planning.
- `PushMessagingService`: menerima FCM, mendelegasikan payload ke `PushIntentJobService`, dan mengirim token/push parameters ke server.

Modelnya bukan satu alarm sederhana. TickTick memiliki **alarm trigger → receiver → job/service → notification builder → action dispatcher**, dengan jalur terpisah untuk task, calendar, habit, daily summary, popup, dan remote push.

## 5. Todo Planner kita — baseline dan gap

### 5.1 Compiled APK

Kedua package terpasang:

| Variant | Package | Notification components |
|---|---|---|
| Base | `com.example.flutter_ui` | `ScheduledNotificationReceiver`, `ActionBroadcastReceiver`, `ScheduledNotificationBootReceiver` |
| Debug calendar | `com.example.flutter_ui.calendar` | Komponen sama |

Keduanya mendeklarasikan `POST_NOTIFICATIONS`, `USE_EXACT_ALARM`, `SCHEDULE_EXACT_ALARM`, dan `RECEIVE_BOOT_COMPLETED`. Runtime permission untuk notification dan exact alarm terbaca granted pada kedua package.

`com.example.flutter_ui.calendar` hanya berbeda pada package identity dan dynamic receiver permission. Tidak ada bukti bahwa suffix `.calendar` mengubah notification behavior, channel, planner, receiver, atau alarm mode. Mekanisme build variant/identity perlu difinalisasi sebelum release karena source `android/app/build.gradle.kts` saat ini masih menetapkan `applicationId = "com.example.flutter_ui"`.

### 5.2 Source implementation

`LocalNotificationReminderService` saat ini:

- menginisialisasi timezone dan `flutter_local_notifications`;
- memakai `exactAllowWhileIdle` jika exact scheduling tersedia, fallback ke `inexactAllowWhileIdle` jika tidak;
- memakai stable FNV-1a notification ID dari task ID;
- menyediakan `Done`, `In 1 hour`, dan `Tomorrow`;
- menjalankan action pada background isolate, membaca ulang SharedPreferences, mengubah task, lalu menjadwalkan/cancel reminder baru;
- menerima sinyal perubahan kembali ke isolate UI.

`AndroidManifest.xml` menambahkan scheduled receiver, action receiver, dan boot receiver untuk `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, serta vendor quick-boot actions.

### 5.3 Runtime evidence

Snapshot `dumpsys alarm` pada device memperlihatkan:

```text
RTC_WAKEUP ... com.example.flutter_ui
*walarm*:com.example.flutter_ui/com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver
```

Ini membuktikan alarm telah didaftarkan oleh app. Ini **belum** membuktikan notification terlihat ketika layar mati, device masuk Doze, atau HiOS battery manager membatasi app. Acceptance tetap harus berupa bukti fisik layar mati, disertai logcat dan snapshot alarm/notification sebelum dan sesudah trigger.

## 6. Keputusan implementasi untuk PRD

1. Pertahankan **local exact alarm** sebagai jalur P0 untuk offline-first.
2. Pertahankan tiga action inti Tweek/Todo Planner: **Done**, **In 1 hour**, **Tomorrow**.
3. Tambahkan behavior TickTick secara bertahap: reschedule setelah boot/timezone/time change, job fallback bila receiver dibatasi, dan status delivery yang dapat didiagnosis.
4. Pisahkan task reminders dan calendar-event reminders secara domain; jangan membuat `.calendar` package suffix menjadi solusi arsitektural.
5. Jika sync/FCM ditambahkan, gunakan push untuk invalidation, remote changes, atau account events. Jangan menjadikan FCM satu-satunya sumber reminder lokal.
6. Sediakan halaman notification diagnostics: permission, exact-alarm capability, channel importance, next scheduled reminder, last reschedule, dan tombol membuka system settings.

## 7. Verifikasi berikutnya sebelum klaim selesai

- Buat satu task reminder test pada base package dan satu pada `.calendar` package; verifikasi keduanya melalui `dumpsys alarm` dan `dumpsys notification`.
- Uji app process killed, screen off, Doze, reboot, timezone change, dan package update.
- Tekan ketiga action dari notification ketika app foreground, background, dan force-stopped; verifikasi data disk serta notification reschedule.
- Catat perbedaan HiOS battery manager/Hiber/Buzzkill sebagai environment condition, bukan langsung sebagai defect kode.
- Jika fallback inexact terpakai, tampilkan state itu secara eksplisit; jangan menyebutnya exact delivery.

## 8. Evidence index

- Source: `TODO.md`, `docs/PRD.md`
- Current implementation: `lib/features/todo/reminders/local_notification_reminder_service.dart`, `lib/features/todo/reminders/reminder_planner.dart`, `android/app/src/main/AndroidManifest.xml`
- Private APK/decompile workspace: `docs/references/_private/apk-analysis/`
- Private live captures/XML: `docs/references/_private/tweek-mobile/`
- Device serial: omitted from the project snapshot
