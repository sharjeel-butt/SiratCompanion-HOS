# Sirat Companion

**Your Daily Islamic Companion** — a lightweight, offline-first Islamic app for HarmonyOS.

Prayer times, Qibla compass, Tasbih, and Hijri calendar — all in one calm, modern app that respects your settings and your battery.

**Version 1.3.0** &nbsp;·&nbsp; **HarmonyOS 5+ (API 22+)** &nbsp;·&nbsp; **English · 中文 · العربية**

---

## Table of Contents

1. [Features](#features)
2. [Getting Started](#getting-started)
3. [Configuration](#configuration)
4. [Permissions](#permissions)
5. [Localization](#localization)
6. [Project Structure](#project-structure)
7. [Notification Setup](#notification-setup)
8. [Testing Notifications](#testing-notifications)
9. [Timezone Handling](#timezone-handling)
10. [Roadmap](#roadmap)
11. [Contributing](#contributing)
12. [Known Limitations](#known-limitations)
13. [License](#license)

---

## Features

### Prayer Times

- Five daily prayers: Fajr, Dhuhr, Asr, Maghrib, Isha
- Four calculation conventions
- Two Asr shadow rules: Standard and Hanafi
- Extra timings: Imsak, Sunrise, Sunset, First Third, Midnight, Last Third
- Per-prayer minute offsets
- Timeline-aware **Next** — after Isha shows First Third, Midnight, Last Third, Imsak, then tomorrow's Fajr
- Time-based **Current / Next** header that never lies about the active prayer

#### Calculation Conventions

| Convention | Fajr angle | Isha angle |
|---|---|---|
| Karachi (Univ. of Islamic Sciences) | 18° | 18° |
| ISNA (North America) | 15° | 15° |
| MWL (Muslim World League) | 18° | 17° |
| Jafari (Leva Institute, Qum) | 16° | 14° |

### Prayer Notifications

- Two reminders per prayer: one at a configurable lead time (5–60 min), one at exact time
- Per-prayer toggles — enable or silence Fajr, Dhuhr, Asr, Maghrib, Isha individually
- Master toggle for all reminders
- System-level scheduling — reminders fire even when the app is closed
- Localized content in all three languages

### Qibla Compass

- Live direction to the Kaaba using the device's orientation sensor
- Low-pass filter for smooth, jitter-free readings
- Unwrapped angle math — no more 360° spins at north
- Distance to Makkah displayed live
- Magnetometer fallback when the orientation sensor is unavailable

### Tasbih

- Vertical bead string with visible string line and 3D gradient beads
- Swipe up to count, swipe down to undo
- LIFO animation — new beads drop in from above on increment
- Pulse-on-cap — visual feedback even when the string is saturated
- Auto-advance to the next dhikr when one completes
- Lifetime counter per tasbih — persisted forever
- Multiple Tasbihs, unlimited Dhikr items
- Haptic feedback on every flick

### Hijri Calendar

- Gregorian and Hijri dates side by side
- Upcoming Islamic events highlighted in the grid
- ±3 day offset for local moon-sighting differences
- Offset applies everywhere — top pill, prayer-list header, and calendar
- Localized month names in all three languages

### Design

- Dark mode with Light / Dark / Use System Settings
- Three languages: English, 中文, العربية
- Full RTL support for Arabic
- First-launch wizard for quick setup
- Swipe to refresh on the home screen
- Everything works offline

---

## Getting Started

### Prerequisites

- DevEco Studio 5.0 or later
- HarmonyOS SDK API 22+
- A HarmonyOS device or emulator (see [Known Limitations](#known-limitations))
- Node.js 18+ and `ohpm` (installed with DevEco Studio)

### Install and Run

**1. Clone the repository**

```bash
git clone https://github.com/your-org/sirat-companion.git
cd sirat-companion
```

**2. Open in DevEco Studio**

File → Open → select the `sirat-companion` folder.

**3. Sync dependencies**

File → Sync and Refresh Project.

**4. Select a device**

- Physical device: connect via USB, enable Developer Options and USB Debugging
- Emulator: Device Manager → Create Emulator → API 22+ → Start

**5. Build and run**

Press `Shift + F10` or use Build → Build Hap(s).

### Building a Release HAP

1. Sign the app in DevEco Studio: Build → Generate Key and CSR
2. Build: Build → Build Hap(s) / App(s) → Build Hap(s)

The signed HAP appears under `entry/build/default/outputs/default/`.

---

## Configuration

### Calculation Method

**Default:** Karachi

**Location:** Settings → Prayer Times → Convention

### Asr Rule

**Default:** Standard

**Location:** Settings → Prayer Times → Madhab

### Location Mode

- **GPS** — fetches location on launch and when the 📡 button is tapped
- **Manual** — enter coordinates; reverse-geocoded to a city name

### Hijri Offset

**Location:** Settings → Hijri Calendar → Hijri Date & Calendar Offset

Shifts all Islamic dates by ±3 days.

### Theme Mode

**Location:** Settings → Customize → Appearance → Dark Mode

**Options:** Light, Dark, Use System Settings

### Language

**Location:** Settings → Customize → UI Customization → Language

Instantly switches between English, 中文, and العربية.

### Notifications

**Location:** Settings → Notifications

Master toggle, lead-time stepper, and per-prayer switches.

---

## Permissions

Declared in `entry/src/main/module.json5`.

| Permission | Purpose | Requested |
|---|---|---|
| `ohos.permission.APPROXIMATELY_LOCATION` | Approximate location for prayer times | On first GPS request |
| `ohos.permission.LOCATION` | Precise location for prayer times | On first GPS request |
| `ohos.permission.ACCELEROMETER` | Compass and Qibla direction | On Compass open |
| `ohos.permission.PUBLISH_AGENT_REMINDER` | Prayer notifications | On first notification enable |

All permissions can be denied without affecting other features.

---

## Localization

The app is fully localized in three languages.

| Language | Code | RTL |
|---|---|---|
| English | `en` | No |
| 中文 (Chinese, Simplified) | `zh` | No |
| العربية (Arabic) | `ar` | Yes |

Localization strings live in `helper/LocalizationHelper.ets` as `Map<string, string>` tables built once at class init.

### Adding a New Language

1. Add the language code to the `AppLanguage` enum
2. Add a new `buildXx()` method returning a `Map<string, string>`
3. Register it in `tableFor()`, `get()`, and `getArray()`
4. Add the `Xx` static table reference
5. Add the language to `LanguageOption` in `WizardPage.ets`

---

## Project Structure

```
entry/src/main/ets/
├── common/
│   ├── PageTheme.ets              # Shared theme orchestration
│   ├── StorageKeys.ets            # All preference keys
│   └── Theme.ets                  # ThemeColors + Theme.getColors
├── models/
│   ├── DateModels.ets             # IslamicEvent, UpcomingImportantDate
│   ├── HijriCalendarModels.ets    # CalendarDay, HijriDate
│   ├── PrayerModel.ets            # Prayer, ExtraTiming
│   ├── SettingsModels.ets         # PickerItem, CalculationSource, LocationMode
│   └── TasbihModels.ets           # Tasbih, Dhikr, BeadView
├── data/
│   └── IslamicEvents.ets          # Static event table
├── helper/
│   ├── HapticHelper.ets
│   ├── HijriCalendarHelper.ets
│   ├── LocalizationHelper.ets
│   ├── NavHelper.ets
│   ├── NotificationHelper.ets
│   ├── PrayerOffsetsHelper.ets
│   ├── PreferencesHelper.ets
│   ├── QiblaSensorHelper.ets
│   └── SettingsHelper.ets
├── utils/
│   ├── DateUtils.ets
│   ├── HomeController.ets
│   ├── LocationCache.ets
│   ├── LocationUtils.ets
│   ├── OfflineCityLookup.ets
│   ├── PrayerManager.ets
│   ├── PrayerTimeCalculator.ets
│   ├── QiblaCalculator.ets
│   ├── TasbihManager.ets
│   ├── TasbihStorage.ets
│   └── TimezoneResolver.ets
├── pages/
│   ├── CustomizePage.ets
│   ├── HijriCalendarPage.ets
│   ├── Index.ets
│   ├── QiblaPage.ets
│   ├── SettingsPage.ets
│   ├── TasbihPage.ets
│   └── WizardPage.ets
└── entryability/
    └── EntryAbility.ets
```

### Layering

The codebase follows a three-layer architecture.

**Pages** are `@Entry` components holding `@State`, `@Builder`, and event handlers. They render and delegate — no business logic.

**Helpers** are stateless façades: `SettingsHelper`, `NotificationHelper`, `HomeController`, `PrayerManager`, `LocalizationHelper`, `NavHelper`. They orchestrate and contain pure logic where possible.

**Core** is the bottom layer: `PrayerTimeCalculator`, `PreferencesHelper`, `TimezoneResolver`, `QiblaCalculator`. Astronomy math, persistence, and DST rules.

> **Rule of thumb:** pages never touch `@ohos.data.preferences` directly. All persistence goes through `PreferencesHelper` via `SettingsHelper`.

---

## Notification Setup

Notifications use `reminderAgentManager` from `@kit.BackgroundTasksKit`.

### How It Works

1. User enables notifications in Settings → Notifications
2. App requests `PUBLISH_AGENT_REMINDER` permission
3. On every app open, `NotificationHelper.rescheduleAll()` runs:
   - Cancels all existing reminders (clean slate)
   - Reads location, method, Asr rule, offsets, and notification settings
   - Calculates prayer times for the next 3 days
   - Publishes two reminders per enabled prayer (before + exact)

### Reliability

- Reminders fire even when the app is closed
- Reminders survive device restarts
- Reminders renew every time the user opens the app
- Language changes reschedule all reminders with new localized content

---

## Testing Notifications

| Emulator API | `reminderAgentManager` support |
|---|---|
| API 9 – 19 | Not supported |
| API 20+ | Supported |

**On API 20+ emulator** you can verify the permission dialog, `publishReminder()` return values, notification display in the shade, and localization.

**On any emulator** use `notificationManager.publish()` directly to verify content without waiting for the scheduler.

**On a real device** you get full validation including the exact timed trigger. Cloud debugging via AppGallery Connect is a good alternative.

---

## Timezone Handling

Prayer times are calculated for the location's timezone, not the device's.

`TimezoneResolver.effectiveOffsetForLocation()` does the following:

1. Checks `OfflineCityLookup` for the nearest known city (60+ cities with standard offset and DST rule)
2. Applies US / EU / AU DST rules based on the date
3. If the device's own offset is within 30 minutes of the location estimate, prefers the device's offset (the OS knows DST transitions more precisely)

This means viewing NYC prayer times from Pakistan shows NYC local times, with correct EDT / EST transitions.

---

## Roadmap

- [ ] Online (API) prayer times provider
- [ ] Home screen widgets
- [ ] Qibla calibration UX (figure-8 flow)
- [ ] Adhan audio playback
- [ ] Hijri date manual override (± 1 day globally)
- [ ] Additional languages — Turkish, Urdu, Indonesian
- [ ] Tablet and foldable layouts
- [ ] Prayer streak statistics

---

## Contributing

Contributions are welcome.

**1. Fork the repository**

**2. Create a feature branch**

```bash
git checkout -b feature/your-feature-name
```

**3. Commit your changes** following the convention below

**4. Push and open a Pull Request**

### Commit Convention

This project uses [Conventional Commits](https://www.conventionalcommits.org/).

```
feat: add Hanafi Asr shadow rule
fix: correct equation-of-time wrap in PrayerTimeCalculator
docs: add architecture guide
refactor: split Tasbih logic into TasbihManager
chore: bump target API to 22
```

### Code Style

- ArkTS strict mode is required — no `any`, no untyped object literals
- Object literals must be assigned to named interfaces
- Do not use `Record<K, V>` in types — use `Map<K, V>` instead
- Keep pages free of business logic — delegate to helpers
- Every page follows the `tr()` pattern for localization

---

## Known Limitations

- **Online (API) prayer times** are stubbed. Selecting it shows a "Coming Soon" card.
- **Compass** requires a real device. Emulators without a magnetometer show "sensor unavailable".
- **Reverse geocoding** returns `"Unknown location"` for some regions. The offline city lookup and manual city name field are fallbacks.
- **Timed notifications** may drift on emulators with API < 20.
- **High-latitude prayer times** clamp the hour angle to `[-1, 1]`. Proper one-seventh-of-the-night rules are out of scope.
- **Multiple persistence backends** coexist: `PreferencesHelper`, `AppStorage`, `PersistentStorage`, and Tasbih's private store. Consolidation is on the roadmap.

---

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

You are free to use, modify, and distribute this software, including for commercial purposes, provided the original copyright notice is retained.

---

## Acknowledgements

- **Jean Meeus** — *Astronomical Algorithms* — source of the solar position math
- **PrayTimes.org** — reference for the four calculation conventions
- **HarmonyOS Developer Docs** — for `@kit.ArkUI`, `@kit.ArkData`, and `@kit.BackgroundTasksKit`
- **Every beta tester** who reported bugs and suggested features

---

## Contact

- **Issues** — [github.com/sharjeel-butt/SiratCompanion-HOS/issues](https://github.com/sharjeel-butt/SiratCompanion-HOS/issues).
- **Telegram** — [t.me/siratcompanionhos](https://t.me/siratcompanionhos)

---

**May it be of benefit.** 🤲

*If Sirat Companion helps you with your daily worship, consider starring the repository.*
