# Sirat Companion

**Your Daily Islamic Companion** — a lightweight, offline-first Islamic app for HarmonyOS.

Prayer times, Qibla compass, Tasbih, and Hijri calendar — all in one calm, modern app that respects your settings and
your battery.

**Version 2.3.0** &nbsp;·&nbsp; **HarmonyOS 6+ (API 20+)** &nbsp;·&nbsp; **English · 中文 · العربية**

> On HarmonyOS 7 (API 26+) the bottom navigation bar uses the native immersive system material. On earlier releases it
> falls back to a translucent blurred bar with identical behaviour.

> Prayer reminders currently ship via the **Calendar Kit** backend (calendar events with system reminders) while the
> Agent-Powered Reminder capability is pending AGC approval. The two backends are switchable at compile time.

---

## Table of Contents

1. [Features](#features)
2. [Getting Started](#getting-started)
3. [Configuration](#configuration)
4. [Permissions](#permissions)
5. [Localization](#localization)
6. [Project Structure](#project-structure)
7. [Navigation Architecture](#navigation-architecture)
8. [Theming](#theming)
9. [Immersive Material (HarmonyOS 7)](#immersive-material-harmonyos-7)
10. [Prayer Reminders](#prayer-reminders)
11. [Testing Reminders](#testing-reminders)
12. [Timezone Handling](#timezone-handling)
13. [Roadmap](#roadmap)
14. [Contributing](#contributing)
15. [Known Limitations](#known-limitations)
16. [License](#license)

---

## Features (Supports Phone, Tablet, Foldable, and 2-in-1)

### Prayer Times

- Five daily prayers: Fajr, Dhuhr, Asr, Maghrib, Isha
- Four calculation conventions
- Two Asr shadow rules: Standard and Hanafi
- Extra timings: Imsak, Sunrise, Sunset, First Third, Midnight, Last Third
- Per-prayer minute offsets (±60)
- High-latitude rules: None, Middle of Night, One Seventh, Angle Based
- Timeline-aware **Next** — after Isha shows First Third, Midnight, Last Third, Imsak, then tomorrow's Fajr
- Time-based **Current / Next** header that never lies about the active prayer
- Custom sun-path visualization with per-prayer dotted leaders, sunrise/sunset markers, and a live "We are here" ticker
  that continues cycling through the night
- Jummah rename on Fridays, applied consistently to the header and the timeline
- "Today" shortcut in the day navigator to return to the current date

#### Calculation Conventions

| Convention                          | Fajr angle | Isha angle |
|-------------------------------------|------------|------------|
| Karachi (Univ. of Islamic Sciences) | 18°        | 18°        |
| ISNA (North America)                | 15°        | 15°        |
| MWL (Muslim World League)           | 18°        | 17°        |
| Jafari (Leva Institute, Qum)        | 16°        | 14°        |

### Home Dashboard

- Today's progress ring with per-prayer completion dots
- Current and best streaks
- Weekly grid and monthly heatmap
- Lifetime Tasbih statistics
- Upcoming Islamic event countdown honoring the Hijri offset
- Ramadan card with fasting window, three Ashras, Laylat al-Qadr nights, and Jummah tul Widah
- Live countdown to Imsak and Maghrib (opens 15 min before, holds 5 min after with the appropriate Dua displayed)
- Pull-to-refresh
- Cross-tab state sync — checking a prayer on the Prayers tab immediately updates the Home dashboard

### Prayer Reminders

Prayer reminders are delivered through one of two interchangeable backends. Both fire even when the app is closed.

| Backend                    | Status               | Mechanism                                                                           | Requires                                           |
|----------------------------|----------------------|-------------------------------------------------------------------------------------|----------------------------------------------------|
| **Calendar Kit**           | **Active**           | Writes prayer events into a dedicated system calendar account with reminder offsets | `READ_CALENDAR` + `WRITE_CALENDAR` (user-granted)  |
| **Agent-Powered Reminder** | Pending AGC approval | Uses `reminderAgentManager.publishReminder()`                                       | `PUBLISH_AGENT_REMINDER` (AGC capability approval) |

- Two reminders per prayer: one at a configurable lead time (5–60 min), one at exact time
- Per-prayer toggles
- Master toggle
- Fully localized content in all three languages
- Scheduled for the next 3 days, renewed on every app open
- Switchable at compile time — see [Prayer Reminders](#prayer-reminders) for the re-enable procedure

### Qibla Compass

- Live direction to the Kaaba using the device's orientation sensor
- Low-pass filter for smooth, jitter-free readings
- Unwrapped angle math — no 360° spins at north
- Magnetic declination correction from an offline city table
- Distance to Makkah displayed live
- Figure-8 calibration overlay that auto-opens on poor sensor accuracy and auto-dismisses on improvement
- Magnetometer fallback when the orientation sensor is unavailable

### Tasbih

- Vertical bead string with visible string line
- Two render styles: **Premium** (canvas-rendered 3D beads with fisheye effect) and **Classic** (lightweight
  linear-gradient beads)
- Nine bead themes: Amber, Charcoal, Emerald, Pearl, Gold, White, Sapphire, Rose, Silver
- Per-tasbih theme selection
- Swipe up to count, swipe down to undo
- Fly-and-pop animation when the top stack fills, with amber halo
- Sound system with five selectable click styles
- Lifetime counter per tasbih — persisted forever
- Multiple Tasbihs, unlimited Dhikr items
- Auto-advance to the next dhikr when one completes
- Haptic feedback on every flick

### Hijri Calendar

- Gregorian and Hijri dates side by side
- Upcoming Islamic events highlighted in the grid
- ±3 day offset for local moon-sighting differences
- Offset applies everywhere — top pill, prayer-list header, calendar, event countdown, Ramadan card
- Localized month names in all three languages

### Design

- Four app-wide themes: **Sirat Classic**, **Noor**, **Sahar**, **Bahar**
- Each theme with matched light and dark palettes
- Dark mode with Light / Dark / Use System Settings
- Three languages: English, 中文, العربية
- Full RTL support for Arabic
- Responsive layout for phones, tablets, foldables, and 2-in-1 devices
- First-launch wizard for quick setup
- HarmonyOS 7 immersive material for the bottom navigation bar (with a translucent fallback for older releases)
- Respects the system's ringer mode and haptics toggle
- Everything works offline

---

## Getting Started

### Prerequisites

- DevEco Studio 5.0 or later
- HarmonyOS SDK API 20+
- For immersive material features: HarmonyOS 7 device (API 26+)
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
- Emulator: Device Manager → Create Emulator → API 20+ → Start

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

### High-Latitude Rule

**Default:** None
**Location:** Settings → Prayer Times → High Latitude

### Location Mode

- **GPS** — fetches location on launch and when the 📡 button is tapped
- **Manual** — enter coordinates; reverse-geocoded to a city name

### Hijri Offset

**Location:** Settings → Hijri Calendar → Hijri Date & Calendar Offset
Shifts all Islamic dates by ±3 days.

### Theme Mode

**Location:** Customize → Appearance → Dark Mode
**Options:** Light, Dark, Use System Settings

### App Theme

**Location:** Customize → Appearance → App Theme
**Options:** Sirat Classic, Noor, Sahar, Bahar

### Language

**Location:** Customize → UI Customization → Language
Instantly switches between English, 中文, and العربية.

### Tasbih Theme

**Location:** Tasbih → tap the tasbih name pill → edit
Per-tasbih colour preset, from nine options.

### Sound and Haptics

**Location:** Customize → UI Customization
Respects the system's ringer mode and haptics toggle. Both toggles grey out when the system overrides them.

### Prayer Reminders

**Location:** Settings → Notifications
Master toggle, lead-time stepper, and per-prayer switches. The active backend (Calendar or Agent) is selected at
compile time — see [Prayer Reminders](#prayer-reminders).

---

## Permissions

Declared in `entry/src/main/module.json5`.

| Permission                               | Purpose                                          | Requested                                   |
|------------------------------------------|--------------------------------------------------|---------------------------------------------|
| `ohos.permission.APPROXIMATELY_LOCATION` | Approximate location for prayer times            | On first GPS request                        |
| `ohos.permission.LOCATION`               | Precise location for prayer times                | On first GPS request                        |
| `ohos.permission.ACCELEROMETER`          | Compass and Qibla direction                      | On Compass open                             |
| `ohos.permission.VIBRATE`                | Haptic feedback on Tasbih counts                 | Declared only, no runtime request           |
| `ohos.permission.READ_CALENDAR`          | Read the app's own calendar events for cleanup   | On first reminder enable (Calendar backend) |
| `ohos.permission.WRITE_CALENDAR`         | Write prayer reminder events to the app calendar | On first reminder enable (Calendar backend) |
| `ohos.permission.PUBLISH_AGENT_REMINDER` | Prayer notifications                             | **Commented out — pending AGC approval**    |

All permissions can be denied without affecting other features. The `PUBLISH_AGENT_REMINDER` declaration is present in
`module.json5` but commented out; it will be un-commented when the AGC capability is approved.

---

## Localization

The app is fully localized in three languages.

| Language                 | Code | RTL |
|--------------------------|------|-----|
| English                  | `en` | No  |
| 中文 (Chinese, Simplified) | `zh` | No  |
| العربية (Arabic)         | `ar` | Yes |

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
│   ├── Breakpoints.ets              # xs / sm / md / lg width classes
│   ├── FeatureFlags.ets             # Compile-time feature flags
│   ├── PageTheme.ets                # Theme orchestration + isDarkFor()
│   ├── SoundOptions.ets             # Tasbih click sound registry
│   ├── StorageKeys.ets              # All preference keys
│   ├── TasbihThemes.ets             # Bead colour palettes and presets
│   └── Theme.ets                    # ThemeColors, ThemePreset, palettes
├── components/
│   ├── DuaCard.ets                  # Reusable Dua renderer
│   ├── FloatingNavBar.ets           # Legacy — superseded by MainTabs
│   ├── PageHeader.ets               # Shared Hijri / location / prayer header
│   ├── PrayerSunPath.ets            # Canvas sun-path visualization
│   └── QiblaCalibrationOverlay.ets  # Figure-8 compass calibration
├── data/
│   ├── Duas.ets                     # Iftar / Suhoor Dua registry
│   ├── IslamicEvents.ets            # Static event table
│   └── PrivacyPolicy.ets            # EN / ZH / AR privacy text
├── models/
│   ├── DateModels.ets               # IslamicEvent, UpcomingImportantDate
│   ├── HijriCalendarModels.ets      # CalendarDay, HijriDate
│   ├── PrayerModel.ets              # PrayerModel, ExtraTiming
│   ├── SettingsModels.ets           # PickerItem, CalculationSource, LocationMode
│   └── TasbihModels.ets             # Tasbih, Dhikr, BeadView
├── helper/
│   ├── AppInfoHelper.ets            # Version + bundle identity
│   ├── AppLogger.ets                # Sandboxed file logger
│   ├── CalendarReminderHelper.ets   # Calendar Kit reminder backend
│   ├── HapticHelper.ets             # Vibration wrapper with two gates
│   ├── HijriCalendarHelper.ets      # Hijri month math
│   ├── LayoutHelper.ets             # Responsive breakpoint tracking
│   ├── LocalizationHelper.ets       # All translations
│   ├── MaterialHelper.ets           # HOS7 immersive material capability
│   ├── NavHelper.ets                # Route direction hints
│   ├── NotificationHelper.ets       # Reminder scheduler (backend dispatcher)
│   ├── PrayerOffsetsHelper.ets      # Offset get / set / clamp / format
│   ├── PreferencesHelper.ets        # @ohos.data.preferences wrapper
│   ├── QiblaSensorHelper.ets        # Orientation sensor with fallback
│   ├── RamadanHelper.ets            # Ramadan window, Ashras, Laylat al-Qadr
│   ├── SettingsHelper.ets           # Typed settings façade
│   ├── SoundHelper.ets              # SoundPool for Tasbih clicks
│   ├── SystemFeedbackHelper.ets     # Reads ringer mode + haptics toggle
│   └── TasbihCanvasRenderer.ets     # Premium bead canvas renderer
├── utils/
│   ├── DateUtils.ets
│   ├── HomeController.ets
│   ├── LocationCache.ets
│   ├── LocationUtils.ets
│   ├── OfflineCityLookup.ets
│   ├── PrayerManager.ets
│   ├── PrayerTimeCalculator.ets
│   ├── ProgressHelper.ets
│   ├── QiblaCalculator.ets
│   ├── TasbihManager.ets
│   ├── TasbihStorage.ets
│   └── TimezoneResolver.ets
├── pages/
│   ├── CustomizePage.ets
│   ├── HijriCalendarPage.ets
│   ├── HomePage.ets
│   ├── MainTabs.ets                 # Root page hosting the five primary screens
│   ├── Prayer.ets
│   ├── QiblaPage.ets
│   ├── SettingsPage.ets
│   ├── TasbihPage.ets
│   └── WizardPage.ets
└── entryability/
    ├── EntryAbility.ets
    └── EntryBackupAbility.ets
```

### Layering

The codebase follows a three-layer architecture.

**Pages** are `@Entry` components holding `@State`, `@Builder`, and event handlers. They render and delegate — no
business logic.

**Helpers** are stateless façades: `SettingsHelper`, `NotificationHelper`, `CalendarReminderHelper`, `HomeController`,
`PrayerManager`, `LocalizationHelper`, `NavHelper`, `MaterialHelper`. They orchestrate and contain pure logic where
possible.

**Core** is the bottom layer: `PrayerTimeCalculator`, `PreferencesHelper`, `TimezoneResolver`, `QiblaCalculator`.
Astronomy math, persistence, and DST rules.

> **Rule of thumb:** pages never touch `@ohos.data.preferences` directly. All persistence goes through
`PreferencesHelper` via `SettingsHelper`.

---

## Navigation Architecture

The app uses a single root page — `MainTabs.ets` — that hosts five primary screens inside a native `Tabs` container:

```
Home → Prayers → Calendar → Compass → Tasbih
```

`MainTabs` is a **routable page** (declared in `main_pages.json`). The five screen components inside it are plain
`@Component export struct` files with **no** `@Entry` decorator, **no** `pageTransition()`, and **no** `FloatingNavBar`.

Secondary pages — `WizardPage`, `CustomizePage`, `SettingsPage` — remain routable and use `router.pushUrl()` /
`router.back()` for navigation.

### Why a single root page?

HarmonyOS 7 grants the immersive system material only to specific host components. The bottom TabBar of a horizontal
`Tabs(barPosition.End)` qualifies. A free-floating Row does not. Consolidating the five primary screens inside
`MainTabs` is what makes the material possible.

### Adding a new tab

1. Create the screen as `@Component export struct MyNewPage` (no `@Entry`)
2. Import it in `MainTabs.ets`
3. Add a `TabContent() { MyNewPage() }` block inside `TabContents()` with a `.tabBar(...)`
4. Add its label key to `LocalizationHelper.ets`

---

## Theming

Four app-wide theme presets, each with a matched light and dark palette:

| Preset        | Palette                                |
|---------------|----------------------------------------|
| Sirat Classic | Warm cream + deep green                |
| Noor          | Radiant violet — serene and modern     |
| Sahar         | Golden amber — the calm of first light |
| Bahar         | Cool teal — vast, fresh, and clear     |

Selected from **Customize → Appearance → App Theme** or during the wizard.

### Light / Dark / System

Orthogonal to the preset. Selected from **Customize → Appearance → Dark Mode**.

When resolving which palette is in effect, always use `PageTheme.isDarkFor(themeMode)` — never
`PageTheme.isSystemDark()` alone. `isSystemDark()` reports the OS setting; `isDarkFor()` honours the user's choice,
falling back to the OS only when the mode is `System`.

---

## Immersive Material (HarmonyOS 7)

On HarmonyOS 7 (API 26+) the bottom navigation bar uses the native system immersive material. On API 20–25 it falls
back to a translucent blurred bar with identical interaction.

### How it works

`MainTabs.ets` branches at runtime on `deviceInfo.sdkApiVersion`:

| Device              | `sdkApiVersion` | Bar path                                                |
|---------------------|-----------------|---------------------------------------------------------|
| HarmonyOS 7         | 26+             | `barFloatingStyle` + `ImmersiveMaterial(THIN)`          |
| HarmonyOS 6.1 / 6.0 | 20–25           | `barOverlap` + `barBackgroundBlurStyle(BlurStyle.Thin)` |

Both branches share the same `TabContents()` builder, so the tab set stays in sync.

### Requirements

Three preconditions for `systemMaterial` to take effect:

1. `module.json5` metadata `ohos.arkui.UIMaterial.state` = `enable`
2. Device supports `uiMaterial.isImmersiveMaterialSupported()`
3. Host is a horizontal `Tabs(barPosition.End)` with `barOverlap(true)`

If any is missing, `systemMaterial` is silently ignored and the bar renders normally.

### Diagnostics

`MaterialHelper.logCapability()` writes a line to the in-app log at startup:

```
[INFO] [MaterialHelper] SDK=26, distOS=26, immersiveMaterialSupported=true,
                        globalMaterialLevel=EXQUISITE, materialPath=barFloatingStyle
```

View it from **Settings → Diagnostic Logs**.

### Safe-area note

In a page that hosts `Tabs(barPosition.End)` with `barFloatingStyle`, call `expandSafeArea` with **at most**
`SafeAreaEdge.TOP`. Never include `SafeAreaEdge.BOTTOM`. The floating bar handles its own bottom spacing via
`barBottomMargin`; expanding into the bottom gesture area pushes the bar into the system navigation indicator.

`MainTabs.ets` currently does not call `expandSafeArea` at all — this is intentional.

---

## Prayer Reminders

The app supports two reminder backends, selected at compile time by flags in `common/FeatureFlags.ets`. Only one is
active at a time; if both flags are true, the Calendar backend wins because it requires no external approval.

### Backend 1 — Calendar Kit (active)

Prayer reminders are written as events into a dedicated "Sirat Companion" calendar account in the system calendar.
Each event carries a system reminder set to fire at the prayer time and, optionally, at the configured lead time.

**Advantages**

- No AppGallery Connect capability approval required
- The user grants two standard permissions (`READ_CALENDAR`, `WRITE_CALENDAR`)
- Precise timing — the system calendar fires reminders exactly on time
- Works when the app is closed or killed

**Trade-offs**

- Reminders appear as calendar events, not app-branded notifications
- The user can see, edit, or delete the events from the system Calendar app
- Requires calendar permissions to be granted

**How it works**

1. User enables reminders in Settings → Notifications
2. App requests `READ_CALENDAR` and `WRITE_CALENDAR`
3. On grant, `CalendarReminderHelper.init()` creates (or re-uses) the app's calendar account
4. On every app open, `NotificationHelper.rescheduleAll()` runs:
    - Cancels all existing Sirat events
    - Reads location, method, Asr rule, offsets, and reminder settings
    - Calculates prayer times for the next 3 days
    - Writes one calendar event per enabled prayer, with `reminderTime: [0, leadMinutes]`

### Backend 2 — Agent-Powered Reminder (pending AGC approval)

Uses `reminderAgentManager.publishReminder()` from `@kit.BackgroundTasksKit`. Produces standard app notifications
rather than calendar events.

**Requires**

- The `PUBLISH_AGENT_REMINDER` capability approved in AppGallery Connect
- The permission un-commented in `module.json5`
- A signing profile regenerated after approval
- `NOTIFICATIONS_ENABLED = true` in `FeatureFlags.ets`

### Switching between backends

The switch is entirely compile-time. No runtime logic differs between the two.

**To activate the Calendar backend** (current state):

```ts
// FeatureFlags.ets
export const NOTIFICATIONS_ENABLED = false;
export const CALENDAR_REMINDERS_ENABLED = true;
```

**To switch to the Agent-Powered Reminder backend** after AGC approval:

1. `FeatureFlags.ets` → `NOTIFICATIONS_ENABLED = true`; `CALENDAR_REMINDERS_ENABLED = false`
2. `module.json5` → un-comment `PUBLISH_AGENT_REMINDER`; comment out `READ_CALENDAR` / `WRITE_CALENDAR`
3. `data/PrivacyPolicy.ets` + hosted `index.md` → swap the calendar disclosure for a notification disclosure
4. Regenerate the signing Profile and re-sign the app
5. (Optional) Call `CalendarReminderHelper.cancelAll()` once on the first launch after the switch to clear leftover
   calendar events

No other source file changes. `NotificationHelper.resolveBackend()` picks the correct backend automatically based on
the flags.

---

## Testing Reminders

### Calendar backend

| Check                                       | Expected                                                                                    |
|---------------------------------------------|---------------------------------------------------------------------------------------------|
| Settings → Notifications → toggle master on | Calendar permission dialog appears                                                          |
| Grant both permissions                      | Toggle stays on; test button becomes enabled                                                |
| Tap Test Notification                       | A "Sirat · Test Reminder" event appears in the system Calendar app with a 5-second reminder |
| Open the system Calendar app                | A "Sirat Companion" calendar account is visible                                             |
| Enable per-prayer toggles                   | Calendar events appear for the next 3 days, one per enabled prayer                          |
| Disable master toggle                       | All Sirat events are removed from the calendar                                              |

The Calendar backend can be tested on **any** HarmonyOS 6+ device or emulator. No AGC approval is needed.

### Agent-Powered Reminder backend

| Emulator API | `reminderAgentManager` support |
|--------------|--------------------------------|
| API 9 – 19   | Not supported                  |
| API 20+      | Supported                      |

**On API 20+ emulator** you can verify the permission dialog, `publishReminder()` return values, notification display
in the shade, and localization — once the AGC capability is approved and the flag is flipped.

**On any emulator** use `notificationManager.publish()` directly to verify notification content without waiting for
the scheduler.

**On a real device** you get full validation including the exact timed trigger. Cloud debugging via AppGallery Connect
is a good alternative.

---

## Timezone Handling

Prayer times are calculated for the location's timezone, not the device's.

`TimezoneResolver.effectiveOffsetForLocation()` does the following:

1. Checks `OfflineCityLookup` for the nearest known city (60+ cities with standard offset and DST rule)
2. Applies US / EU / AU DST rules based on the date
3. If the device's own offset is within 30 minutes of the location estimate, prefers the device's offset (the OS knows
   DST transitions more precisely)

This means viewing NYC prayer times from Pakistan shows NYC local times, with correct EDT / EST transitions.

---

## Roadmap

### Completed

- [x] Home dashboard — progress, streaks, weekly grid, monthly heatmap
- [x] Ramadan card — Ashras, Laylat al-Qadr, Jummah tul Widah
- [x] Four app-wide themes with matched light/dark palettes
- [x] Tasbih sounds — five selectable click styles
- [x] Per-tasbih bead themes — nine presets
- [x] Qibla calibration overlay
- [x] Tablet / foldable / 2-in-1 responsive layouts
- [x] System feedback integration — respects ringer mode and haptics toggle
- [x] HarmonyOS 7 immersive material with API 20 fallback
- [x] Calendar Kit reminder backend (workaround for AGC-pending capability)
- [x] Switchable reminder backend architecture

### In Progress

- [ ] Agent-Powered Reminder capability approval (AGC)
- [ ] Re-sign and re-apply to AppGallery
- [ ] Investigate Tasbih animation performance on Mate 80 RS Ultimate

### Next Up

- [ ] Online (API) prayer times provider
- [ ] Home screen widgets
- [ ] Adhan audio playback

### Later

- [ ] Additional languages — Turkish, Urdu, Indonesian
- [ ] Consolidate persistence backends

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
chore: bump target API to 26
```

### Code Style

- ArkTS strict mode is required — no `any`, no untyped object literals
- Object literals must be assigned to named interfaces
- Do not use `Record<K, V>` in types — use `Map<K, V>` instead
- Namespaces imported from `@kit.*` must not be used as values (`arkts-no-ns-as-obj`) — guard with
  `deviceInfo.sdkApiVersion`, never `uiModule !== undefined`
- Keep pages free of business logic — delegate to helpers
- Every page follows the `tr()` pattern for localization
- Resolve dark-mode state via `PageTheme.isDarkFor(themeMode)`, not `PageTheme.isSystemDark()`
- Tab-hosted pages must be `@Component export struct` with no `@Entry`, no `pageTransition()`, and no `FloatingNavBar`
- Reminder backends are selected by feature flags only — never branch on `NOTIFICATIONS_ENABLED` or
  `CALENDAR_REMINDERS_ENABLED` outside `NotificationHelper.resolveBackend()`

---

## Known Limitations

- **Prayer reminders use the Calendar backend.** This is a workaround pending Agent-Powered Reminder capability
  approval. Reminders appear as calendar events rather than app notifications. The two backends are switchable at
  compile time.
- **Online (API) prayer times** are stubbed. Selecting it shows a "Coming Soon" card.
- **Compass** requires a real device. Emulators without a magnetometer show "sensor unavailable".
- **Reverse geocoding** returns `"Unknown location"` for some regions. The offline city lookup and manual city name
  field are fallbacks.
- **High-latitude prayer times** clamp the hour angle to `[-1, 1]`. The four fallback rules are implemented, but the
  angle-based rule uses a simplified formula.
- **Multiple persistence backends** coexist: `PreferencesHelper`, `AppStorage`, and Tasbih's private store.
  Consolidation is on the roadmap.
- **Tasbih canvas animation** may stutter on a small number of high-refresh-rate devices. Under investigation.
- **Immersive material** requires HarmonyOS 7 (API 26+) and a supporting device. On older releases, the bar falls back
  to a translucent blur.
- **Calendar reminders are user-visible and user-editable.** Users can delete the app's calendar events at any time
  from the system Calendar app; the app will recreate them on next open if the master toggle is still on.

---

## License

This project is licensed under the **MIT License**.

You are free to use, modify, and distribute this software, including for commercial purposes, provided the original
copyright notice is retained.

---

## Acknowledgements

- **Jean Meeus** — *Astronomical Algorithms* — source of the solar position math
- **PrayTimes.org** — reference for the four calculation conventions
- **HarmonyOS Developer Docs** — for `@kit.ArkUI`, `@kit.ArkData`, `@kit.BackgroundTasksKit`, `@kit.CalendarKit`, and
  the immersive material API
- **Every beta tester** who reported bugs and suggested features

---

## Contact

- **Issues
  ** — [github.com/sharjeel-butt/SiratCompanion-HOS/issues](https://github.com/sharjeel-butt/SiratCompanion-HOS/issues)
- **Telegram** — [t.me/siratcompanionhos](https://t.me/siratcompanionhos)

---

**May it be of benefit.** 🤲

*If Sirat Companion helps you with your daily worship, consider starring the repository.*

---

## Summary of changes from the previous README

| Section                          | Change                                                                                                                                                        |
|----------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Header                           | Added note that reminders currently ship via Calendar Kit                                                                                                     |
| Features → Prayer Reminders      | Renamed from "Prayer Notifications"; added backend comparison table; removed the "Currently disabled" warning                                                 |
| Features → Prayer Times          | Added the "Today" shortcut and the ticker continuity note                                                                                                     |
| Features → Home Dashboard        | Added cross-tab state sync note                                                                                                                               |
| Configuration → Notifications    | Renamed to "Prayer Reminders"; points at the new Reminders section                                                                                            |
| Permissions                      | Added `READ_CALENDAR` and `WRITE_CALENDAR`; reworded `PUBLISH_AGENT_REMINDER` row                                                                             |
| Project Structure                | Added `CalendarReminderHelper.ets`; updated `NotificationHelper.ets` description to "backend dispatcher"                                                      |
| Layering                         | Added `CalendarReminderHelper` to the helpers list                                                                                                            |
| Immersive Material → Diagnostics | Path updated to Settings → Diagnostic Logs (Notifications section may be hidden)                                                                              |
| **Prayer Reminders**             | Completely rewritten — replaced the old "Notifications" section with a two-backend overview, per-backend how-it-works, and a step-by-step switch procedure    |
| **Testing Reminders**            | Rewritten — split into Calendar backend tests (testable on any device) and Agent backend tests (requires AGC approval)                                        |
| Roadmap                          | Moved "Calendar Kit reminder backend" and "Switchable reminder backend architecture" to Completed; removed the "Notifications disabled" note from In Progress |
| Code Style                       | Added the rule that reminder backends are selected by feature flags only, never by direct flag checks outside `NotificationHelper.resolveBackend()`           |
| Known Limitations                | Replaced the "notifications disabled" bullet with a Calendar-backend workaround bullet; added a note that calendar events are user-visible and user-editable  |
| Acknowledgements                 | Added `@kit.CalendarKit` to the HarmonyOS docs citation                                                                                                       |