# Privacy Policy — Sirat Companion

Last updated: November 2, 2026
Effective date: November 2, 2026
Applies to: Sirat Companion version 3.5.6 and later

## INTRODUCTION

Sirat Companion ("the App", "we", "us", or "our") is an Islamic companion application for HarmonyOS, developed by
Sharjeel Idris ("the Developer"). This Privacy Policy explains what information the App accesses, how that information
is used, and your rights regarding that information.

We have designed Sirat Companion to work entirely on your device. The App does not require an account, does not connect
to any server we operate, and does not transmit your personal data to us or to any third party.

By installing and using the App, you agree to the practices described in this Privacy Policy.

## INFORMATION WE ACCESS AND USE

Sirat Companion accesses the following information solely on your device to provide its features. None of this
information is transmitted to us, to Huawei, or to any third party by the App.

### Location Information

- **What we access:** Your device's GPS coordinates (latitude and longitude), and — when you choose Manual Location —
  the coordinates you type in.
- **Why we access it:** Location is required to calculate accurate prayer times and the Qibla direction for your city.
- **How it is stored:** The last successful location (coordinates and city name) is cached on your device so the App can
  load quickly. You can clear this at any time by switching to Manual Location or by uninstalling the App.
- **Transmission:** The App does not send your location to any server. If reverse geocoding is enabled (to convert
  coordinates into a city name), the request is handled by your device's operating system geocoder — that is, by
  HarmonyOS, not by us, and is subject to Huawei's own privacy policy.

### Sensor Information

- **What we access:** The device's orientation sensor and magnetometer.
- **Why we access it:** Required for the Qibla compass to determine which direction is true north and where the Kaaba is
  relative to your device.
- **Transmission:** Sensor readings are processed entirely on your device and are never stored or transmitted.

### Prayer Completion History

- **What we access:** The prayers you mark as prayed each day (Fajr, Dhuhr, Asr, Maghrib, Isha), stored per calendar
  date.
- **Why we access it:** To power the Home dashboard and the Prayer Details page — today's progress, streaks, weekly and
  monthly summaries, and lifetime statistics — and to skip creating reminders for prayers you have already performed.
- **How it is stored:** Stored locally on your device using the HarmonyOS Preferences API. It never leaves your device
  unless you have enabled system backup, in which case it participates in the backup described in the "Backup and
  Restore" section below.

### Prayer Times and Settings

- **What we access:** Your calculation preferences (convention, Asr rule, prayer offsets, high-latitude rule, rounding,
  midnight method, polar resolution, Shafaq), app theme, dark mode, language preference, time format, Hijri date offset,
  Hijri calendar type, location mode, manual coordinates, event tradition preference, per-timing visibility toggles,
  vibration preference, Tasbih theme preferences, Tasbih sound preference, and notification preferences.
- **Why we access it:** To remember your choices across app restarts.
- **How it is stored:** All preferences are stored locally on your device using the HarmonyOS Preferences API. They
  never leave your device unless you have enabled system backup.

### Tasbih Data

- **What we access:** The Tasbih sessions you create, the dhikr items within them, your current counts, your daily
  totals, a rolling 90-day history of daily counts per dhikr, and the theme chosen for each Tasbih. You can optionally
  associate Tasbihs with specific prayers, which links your Tasbih progress to your prayer completion history on your
  device.
- **Why we access it:** To display and persist your Tasbih progress on the Tasbih tab and on the Tasbih Details page,
  and to show contextual Tasbih reminders alongside your daily prayers.
- **How it is stored:** Tasbih data is stored locally on your device using the HarmonyOS Preferences API. Daily counts
  are automatically rolled into history each night; days beyond the most recent 90 are dropped from the rolling window.
  Nothing is transmitted unless you have enabled system backup.

### System Feedback State

- **What we access:** The device's current ringer mode (ring / vibrate / silent) and the system haptics toggle.
- **Why we access it:** So that the App's own sound and vibration respect your system-level settings. When the phone is
  on silent, the App stays silent. When system haptics are off, the App does not attempt to vibrate.
- **How it is stored:** These values are read from the operating system on demand and immediately discarded. They are
  never stored and never transmitted. No personal data is involved.

### Haptic Feedback (Vibration)

- **What we access:** The device's vibration capability.
- **Why we access it:** To provide a short vibration each time you count a Tasbih bead, confirming your tap. This can be
  turned off at any time from the App's Settings → UI Customization → Vibration.
- **Transmission:** Vibration is controlled entirely on your device. No data is generated, stored, or transmitted.

### Sound

- **What we access:** The device's audio playback capability.
- **Why we access it:** To play a short click when you count a Tasbih bead, if you have enabled it. This can be turned
  off at any time from the App's Settings → UI Customization → Sound. The App also respects your system ringer mode — if
  the phone is on silent, the App stays silent regardless of the in-app setting.
- **Transmission:** All click sounds are bundled with the App and played locally. No audio is recorded, no audio is
  streamed, and no data is transmitted.

### Calendar (Prayer Reminders)

- **What we access:** A dedicated calendar account named "Sirat Companion" in your device's system calendar. When you
  enable prayer reminders in Settings → Notifications, the App writes one calendar event per pending prayer for the next
  three days. Each event carries a system reminder set to fire at the prayer time and, optionally, at your configured
  lead time. The event description carries a short Hadith associated with that prayer, along with its source citation.
- **Why we access it:** To deliver prayer-time reminders through the system calendar, which fires reliably even when the
  App is not running.
- **How it is stored:** The events are stored by the system Calendar app under the App's own calendar account. The App
  reads events only from its own account, and only to remove stale events before rescheduling. No other calendar data is
  read, and no calendar data is transmitted anywhere.
- **Prayers already performed:** When you mark a prayer as prayed for a given date, the App removes that prayer's
  reminder for that date on the next reschedule. Marking the last prayer of the day triggers an immediate reschedule so
  the next day's reminders are queued before you leave the App.
- **Removal:** You can remove all of these events at any time by turning off the master reminder toggle in Settings →
  Notifications, or by deleting the "Sirat Companion" calendar account from the system Calendar app.

### Notification Features (Not Currently Active)

The App includes a native notification backend for prayer reminders. This backend is currently disabled while the
Agent-Powered Reminder capability is pending approval by AppGallery Connect. While disabled:

- The App does not request the PUBLISH_AGENT_REMINDER permission.
- The App does not publish any notifications.
- No notification-related data is created, stored, or transmitted.

The active reminder mechanism is the Calendar backend described above. When the Agent-Powered Reminder capability is
approved, this Privacy Policy will be updated to disclose the notification backend, and the PUBLISH_AGENT_REMINDER
permission will be requested at that time.

### Diagnostic Log

- **What we access:** A plain-text log file written by the app's own code, recording lifecycle events, errors, and
  warnings generated locally.
- **Why we access it:** To help diagnose issues reported by users. You can inspect, copy, or clear this file at any time
  from Settings → Diagnostic Logs.
- **How it is stored:** Stored locally on your device, inside the app's private sandbox. It is never transmitted to us
  or to any third party.
- **Backup:** The log is explicitly excluded from the system backup, so it regenerates fresh on each install and cannot
  be recovered from a previous device.

## BACKUP AND RESTORE

Sirat Companion supports HarmonyOS's system-level backup framework. When backup is enabled on your device, the App's
locally stored data is included in the system backup so it can be restored if you migrate to a new device or reinstall
the App.

- **What is included:** All App settings and preferences (language, theme, prayer calculation settings, location mode
  and manual coordinates, Hijri offset and calendar type, notification settings, sound and vibration preferences, time
  format, event tradition, per-timing visibility toggles), all Tasbih data (custom tasbihs, dhikr items, current counts,
  daily totals, rolling 90-day history, lifetime totals, and prayer associations), and the cached GPS location.
- **What is excluded:** The diagnostic log file is deliberately excluded from backup so it regenerates fresh on each
  install.
- **How it works:** The backup is performed entirely by HarmonyOS. It is not transmitted to us, and we do not operate
  the backup service. Whether a backup is created, where it is stored, and whether it is restored are controlled by your
  device's system settings and your Huawei account. Please refer to Huawei's privacy policy for details.
- **Your control:** You can disable backup for this app from your device's system Settings, and you can delete any
  existing backup through the same settings.

## WHAT WE DO NOT COLLECT

Sirat Companion does not collect, store, or transmit:
- Your name, email address, phone number, or any account information
- Device identifiers (IMEI, MAC address, Advertising ID, or similar)
- Analytics or usage statistics
- App run logs transmitted off-device — a diagnostic log is written locally in the app's private sandbox for
  troubleshooting, but it is never transmitted to us or any third party and is excluded from system backup
- Browsing history, contacts, photos, or files
- Financial or payment information
- Advertising identifiers

We do not use any third-party analytics SDKs, advertising SDKs, or tracking libraries.

## HOW WE USE THE INFORMATION

All information accessed by the App is used only on your device and only to provide the App's features:

- **Location** — Calculate prayer times and Qibla direction
- **Sensors** — Determine device orientation for the compass
- **Prayer history** — Track daily prayers, streaks, progress; skip reminders for prayers already performed
- **Preferences** — Remember your settings
- **Tasbih data** — Persist your dhikr progress, daily totals, history, and optional prayer associations
- **System feedback** — Respect system sound and haptics settings
- **Vibration** — Provide haptic feedback while counting Tasbih
- **Sound** — Play a click when counting Tasbih
- **Calendar** — Add prayer-time reminders to a dedicated calendar account
- **Diagnostic Log** — Record local events to help troubleshoot issues

We do not use your information for advertising, profiling, or any purpose unrelated to the App's core functionality.

## SHARING OF INFORMATION

We do not share your information with anyone, because we never receive it in the first place.

The App does interact with the following components of the HarmonyOS operating system, which operate under Huawei's own
privacy policy:

- System geocoder — for reverse geocoding your coordinates into a city name (only when you choose to view a city name).
- Location services — to obtain your GPS coordinates when you grant permission.
- Audio service — to read the system ringer mode and play local sounds.
- Vibration service — to produce tactile feedback when counting Tasbih.
- Calendar service — to write prayer reminder events into the App's own calendar account.
- System backup service — to include the App's local data in your device's system backup, if you have enabled it.

Please refer to Huawei's privacy policy for details on how the operating system handles these services.

## DATA STORAGE AND RETENTION

All App data is stored locally on your device and is retained until you:

- Clear it from within the App (e.g. by resetting Tasbih counts, unchecking individual prayers, or switching to a
  different location)
- Uninstall the App

If system backup is enabled, a copy of the App's data may also be retained in your system backup until you delete it
through the system settings or uninstall the App on all devices associated with your account.

Calendar events created for prayer reminders are stored by the system Calendar app and can be deleted at any time by
turning off the reminder master toggle, by deleting the "Sirat Companion" calendar account, or by uninstalling the App.
Uninstalling Sirat Companion permanently removes all data the App has stored on your device.

## PERMISSIONS REQUESTED

The App requests the following HarmonyOS permissions. You can deny any permission without losing access to the rest of
the App's features.

- **ohos.permission.VIBRATE** — Haptic feedback while counting Tasbih
- **ohos.permission.APPROXIMATELY_LOCATION** — Approximate location for prayer times
- **ohos.permission.LOCATION** — Precise location for prayer times
- **ohos.permission.ACCELEROMETER** — Compass and Qibla direction
- **ohos.permission.READ_CALENDAR** — Read the App's own calendar events to remove stale reminders before rescheduling
- **ohos.permission.WRITE_CALENDAR** — Create prayer reminder events in the App's dedicated calendar account

Permissions are requested only when you first use a feature that requires them. They can be revoked at any time in your
device's Settings.

The PUBLISH_AGENT_REMINDER permission is not currently requested. See the "Notification Features" section above for
details.

### Vibration — Detailed Explanation

The VIBRATE permission allows the App to produce a short vibration each time you tap to count a Tasbih bead, confirming
your tap. It is used only for this local haptic feedback and can be disabled at any time from the App's Settings → UI
Customization → Vibration. No data is generated, stored, or transmitted by this permission.

### Calendar — Detailed Explanation

The READ_CALENDAR and WRITE_CALENDAR permissions allow the App to create a dedicated "Sirat Companion" calendar account
and to write prayer reminder events into it. The App only reads events from its own account, and only to remove stale
ones before writing new ones. The App does not read any other calendar on your device. No calendar data is transmitted
off your device. You can disable the feature at any time from Settings → Notifications, which removes all events the App
has created.

## SECURITY

Because Sirat Companion does not transmit any personal data off your device, there is no server-side risk of data
exposure. Your local data is protected by the HarmonyOS app sandbox, which prevents other apps from reading Sirat
Companion's stored preferences. When system backup is enabled, its security is governed by HarmonyOS and your Huawei
account settings.

## CHILDREN'S PRIVACY

Sirat Companion is intended for general audiences and is suitable for users of all ages. The App does not knowingly
collect any personal information from anyone, including children, because it does not collect personal information at
all.

## YOUR RIGHTS

Because the App does not collect or transmit your data, there is no data for us to disclose, correct, or delete on our
side. You have full control over your data at all times:
- **Access:** All data is visible within the App.
- **Deletion:** Uninstalling the App removes all stored data. Prayer completion history can also be cleared by
  unchecking individual prayers. Calendar reminder events can be removed by turning off the reminder master toggle.
  Backup copies can be deleted through the system backup settings.
- **Portability:** Data can be viewed and re-entered at any time.
- **Withdrawal of consent:** Revoke permissions in your device Settings.

## THIRD-PARTY SERVICES

Sirat Companion does not integrate any third-party analytics, advertising, or tracking services.

## CHANGES TO THIS PRIVACY POLICY

We may update this Privacy Policy from time to time to reflect changes in the App or applicable law. When we make
material changes, we will update the "Last updated" date at the top of this page. Continued use of the App after changes
take effect constitutes acceptance of the revised policy.

## CONTACT US

If you have questions, concerns, or requests regarding this Privacy Policy, please contact us at:

Email: sharjeel.butt@gmail.com
Developer: Sharjeel Idris