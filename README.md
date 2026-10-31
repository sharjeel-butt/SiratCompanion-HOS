# Sirat Companion

**Your Daily Islamic Companion** — a lightweight, offline-first Islamic app for HarmonyOS.

Prayer times, Qibla compass, Tasbih, and Hijri calendar — all in one calm, modern app that respects your settings and
your battery.

## Changelog

## [3.6.5] — 2026-10-31

Batch O+P — one cycle of audits and fixes covering code quality, timezone
accuracy, and rulebook compliance. All 3 HIGH, 8 MEDIUM, and 8 LOW
findings raised during the audit are closed.

### Fixed — HIGH

- **Settings** — the "notify before" `+` stepper rendered as disabled
  whenever the Hijri offset was at +3, even though the lead time could
  still be increased. The colour was reading the wrong state variable.
- **Tasbih** — `resolveActivePrayer()` was defined but never invoked.
  Opening a tasbih bound to prayers left no active prayer selected until
  the user tapped a pill manually, which suppressed per-prayer tracking.
  Wired into every load path: initial mount, tab-switch, midnight
  rollover, tasbih switch, tasbih delete.
- **Qibla / Timezone** — Mexico's Baja California peninsula inherited the
  mainland −6 offset (2 h error for Mexicali, 1 h for La Paz and Cabo
  San Lucas) whenever the location was >300 km from the Los Angeles
  city-table entry. Added `MX-BC` (−8, US DST) and `MX-BCS` (−7, no
  DST) zones ahead of the mainland `MX` box.

### Fixed — MEDIUM

- **Brazil** — Mato Grosso, Mato Grosso do Sul, Rondônia, and Roraima
  fell through the `BR-AM` box and landed on `BR` (−3 instead of −4).
  Split the UTC−4 zone into five state-level boxes.
- **Afghanistan** — the `AF` bounding box was listed *after* `PK` and
  `IN`, so Kabul, Kandahar, and every rural Afghan location resolved to
  +5 or +5.5 instead of +4.5. Reordered `AF` first. Added Jaisalmer,
  Jodhpur, Jaipur, Ahmedabad, Amritsar to the city table so
  India–Pakistan border overlaps resolve correctly.
- **Morocco** — the hard-coded Ramadan table stopped at 2029, producing
  a 1-hour error every Ramadan from 2030 onward. Dakhla (23.68°N) fell
  outside both the Morocco special-case box and the `MA` country box,
  landing on the longitude estimate (2-hour error). Introduced
  `DstRule.MOROCCO` backed by the actual Hijri conversion engine
  (honours the user's offset), extended the `MA` box south to 20.7°N.
- **Qibla declination** — `declinationFor()` returned `0` when no table
  city was within 300 km, producing a Qibla error up to 25° at extreme
  longitudes. Split into `MAX_TIMEZONE_KM = 200` and
  `MAX_DECLINATION_KM = 500`; declination matches now cover essentially
  every populated landmass.
- **Extra timings** — six emoji icons (`🌙 🌅 🌇 🌃 🌌 🌠`) rendered as
  `Text` instead of themeable SVGs. Migrated `ExtraTiming.icon` to
  `Resource | undefined` and switched `ExtraTimingRow` to `Image`.
- **UI** — hamburger menu (`☰`), dhikr picker (`▼`), and five checkbox
  indicators (`✓`) used text glyphs. Replaced with `ic_menu.svg`,
  `ic_chevron_down`, `ic_check`.

### Fixed — LOW

- **Australia** — Broken Hill (far-western NSW) observes SA time but
  fell into `AU-E` (+10 DST instead of +9:30 DST). Added `AU-BH` box.
- **`dateFromUTCHours`** — relied on `Date.setHours(h, 60, …)` implicit
  rollover. Rewrote using `totalMinutes` first so the invariant is
  explicit. No behaviour change (verified across all boundary cases).
- **`HijriCalendarPage.getLocalizedGregorianSpan`** — a `toLocaleString`
  throw would take down the entire PDF export path. Wrapped in try/catch
  with English fallback, matching `RamadanHelper.formatShort`.
- **`PrayerTimeCalculator.calculate`** — Isha interval was measured from
  pre-temkin maghrib. Latent (no shipped method combines temkin and an
  interval-based Isha), but moved the temkin block above the Isha block
  so the invariant holds for any future method.
- **`HapticHelper`** — header claimed silent-mode suppression but the
  code only checked the haptics toggle. Corrected the comment; behaviour
  matches iOS / Android convention (silent ≠ haptics-off).
- **`PrayerModel`** — dropped `'locked'` from both `status` unions. It
  had no writer and no handler in `getStatusColor` / `getStatusLabel`.
- **Dead code** — deleted `BottomNavItem.ets` and `FloatingNavBar.ets`.
  Neither is referenced anywhere; the latter still carried five emoji and
  the banned `isSystemDark()` call.

### Added

- **Tests** (`ohosTest/ets/test/TimeUtilities.test.ets`) — invariant-based
  coverage for Morocco DST, UmmAlQura toHijri/toGregorian boundaries
  (Ramadan start/end, year boundary, out-of-range fallback, invalid
  input), and `dateFromUTCHours` output format under extreme longitudes
  and polar conditions.

### Known limitations (unchanged)

- **Lebanon DST** — uses EU rule. National decrees (e.g. the 2023
  delayed start) cannot be predicted offline. Documented in
  `OfflineCityLookup.ets`.
- **Lord Howe Island** — 30-minute DST edge case for ~400 people.
  Not modelled.
- **Bounding-box timezone fallback** — borders can misclassify by a few
  km. Mitigated by the city-table lookup running first.

### Under the hood

- Rulebook compliance achieved: zero emoji in any UI, zero text-glyph
  controls, zero dead files.
- Timezone data corrected for Mexico, Brazil, Afghanistan, Morocco,
  Australia, and northwestern India.
- Version bump `3.6.4` → `3.6.5` (`versionCode: 3000650`,
  `buildVersion: "365"`).

### [v3.5.6] - 2026-11-02

#### Added

- **Tasbih-Prayer Binding:** Users can now associate Tasbihs with specific prayers (Fajr, Dhuhr, Asr, etc.). Live counts
  are tracked independently per prayer.
- **Tasbih Pill:** A contextual pill in the Home and Prayer headers displaying pending Tasbihs for the current or next
  prayer.
- **Tasbih Popup:** Tapping the pill opens a scrollable sheet showing detailed Dhikr progress (e.g., 1/33).
- **Anchor Navigation:** Tapping a Dhikr in the popup instantly navigates to the Tasbih tab with the exact Tasbih,
  Dhikr, and Prayer context pre-selected.

#### Fixed

- **Tasbih Details:** Fixed the progress bars not filling correctly.
- **2-in-1 View:** Removed forced `routerSplit` on launch; the app now opens in a clean full-screen window on
  PCs/Tablets.
- **PDF Export:** Fixed a silent failure where the success toast appeared even if the file failed to save.
- **Test Notifications:** Fixed a critical data-loss bug where sending a test notification would delete real prayer
  reminders.
- **RTL Compliance:** Replaced text-based back arrows with rotated SVGs across all pages for perfect bidirectional
  layout.

### [v3.4.3] - 2026-10-20

#### Fixed

- **Calculation Accuracy:** Implemented official Diyanet (Turkey) Temkin offsets and forced Standard Asr to exactly
  match the government calendar.
- **Calculation Accuracy:** Added Jafari/Tehran Maghrib rule (-4° below horizon) and forced Jafari Midnight method.
- **Calculation Accuracy:** Added Umm al-Qura Ramadan rule (+30 minutes to Isha during Ramadan).
- **AppGallery Fix:** Resolved an issue on 2-in-1 (PC) devices where the app would not fully close when selecting "
  Exit".
- **AppGallery Fix:** Enforced GUI constraints to prevent invalid combinations (e.g., locking the Madhab selector to
  Standard when Diyanet is selected).

> On HarmonyOS 7 (API 26+) the bottom navigation bar uses the native immersive system material. On earlier releases it
> falls back to a translucent blurred bar with identical behaviour.

> Prayer reminders currently ship via the **Calendar Kit** backend (calendar events with system reminders) while the
> Agent-Powered Reminder capability is pending AGC approval. The two backends are switchable at compile time.

---

## Table of Contents

1. [Features](#features)
2. [Screenshots](#screenshots)
3. [Getting Started](#getting-started)
4. [Configuration](#configuration)
5. [Permissions](#permissions)
6. [Localization](#localization)
7. [Project Structure](#project-structure)
8. [Navigation Architecture](#navigation-architecture)
9. [Theming](#theming)
10. [Immersive Material (HarmonyOS 7)](#immersive-material-harmonyos-7)
11. [Prayer Reminders](#prayer-reminders)
12. [Testing Reminders](#testing-reminders)
13. [Timezone Handling](#timezone-handling)
14. [Backup and Restore](#backup-and-restore)
15. [Version History](#version-history)
16. [Roadmap](#roadmap)
17. [Contributing](#contributing)
18. [Known Limitations](#known-limitations)
19. [License](#license)

---

## Features (Supports Phone, Tablet, Foldable, and 2-in-1)

### Prayer Times

- Five daily prayers: Fajr, Dhuhr, Asr, Maghrib, Isha
- **Twenty-four calculation methods** — full Adhan-library parity
- Two Asr shadow rules: Standard and Hanafi
- Extra timings: Imsak, Sunrise, Sunset, First Third, Midnight, Last Third
- Per-prayer minute offsets (±60)
- High-latitude rules: None, Middle of Night, One Seventh, Angle Based, Proportional Depression
- **Advanced Calculation page** — Rounding, Midnight Method, High-Latitude, Polar Resolution, Shafaq, Custom Angles
- Timeline-aware **Next** — after Isha shows First Third, Midnight, Last Third, Imsak, then tomorrow's Fajr
- Time-based **Current / Next** header that never lies about the active prayer
- **Pre-Fajr fallback** — before Fajr, the app shows the previous day's Isha as the current prayer
- Custom sun-path visualization
- Jummah rename on Fridays, applied consistently to the header and the timeline
- "Today" shortcut in the day navigator
- **Time format setting** — System / 12-hour / 24-hour
- **Per-timing visibility toggles** — control what shows in the list and sun path

#### Calculation Methods

| Method                 | Region                                  | Fajr angle | Isha angle |
|------------------------|-----------------------------------------|------------|------------|
| Karachi                | University of Islamic Sciences          | 18°        | 18°        |
| ISNA                   | North America                           | 15°        | 15°        |
| MWL                    | Muslim World League                     | 18°        | 17°        |
| Jafari                 | Shia Ithna Ashari (Leva Institute, Qum) | 16°        | 14°        |
| Umm al-Qura            | Makkah                                  | 18.5°      | 90 min     |
| Egyptian               | Egyptian Survey                         | 19.5°      | 17.5°      |
| Sunni Iraq             | Sunni Endowment                         | 19.5°      | 17.5°      |
| Qatar                  | Qatar Awqaf                             | 18°        | 90 min     |
| Singapore              | MUIS                                    | 20°        | 18°        |
| France                 | UOIF                                    | 12°        | 12°        |
| Turkey                 | Diyanet                                 | 18°        | 17°        |
| Russia                 | SAMR                                    | 16°        | 15°        |
| UAE                    | GIAE                                    | 18.2°      | 18.2°      |
| Moonsighting Committee | Worldwide                               | 18°        | 18°        |
| Dubai                  | Gulf Region                             | 18.2°      | 18.2°      |
| Kuwait                 | Kuwait                                  | 18°        | 17.5°      |
| France 15°             | France (alternative)                    | 15°        | 15°        |
| France 18°             | France (alternative)                    | 18°        | 18°        |
| Turkey Europe          | Diyanet Europe                          | 18°        | 17°        |
| Tehran                 | Institute of Geophysics                 | 17.7°      | 14°        |
| Indonesia              | KEMENAG                                 | 20°        | 18°        |
| Algeria                | Ministry of Religious Affairs           | 18°        | 17°        |
| Brunei                 | Kementrian Hal Ehwal Ugama              | 20°        | 18°        |
| Custom                 | User-defined                            | —          | —          |

### Home Dashboard

The Home tab shows sections in a fixed order: **Next Event**, **Daily Prayers**, and **Daily Tasbih**.

- **Next Event** — nearest upcoming Islamic event, countdown banner, and Ramadan card.
- **Daily Prayers** — today's progress ring and dots. Includes the **Current Prayer Pill** with an inline **Tasbih Pill
  **.
- **Daily Tasbih** — today's dhikr completion and lifetime totals.

Additional Home features:

- Live countdown to Imsak and Maghrib
- Pull-to-refresh
- Cross-tab state sync

### Prayer Details Page

Reached from Home → Daily Prayers → View Details.
- **Period selector** — Week / Month / Year
- **Summary card** — total prayers, percentage ring, current streak, best streak
- **Per-prayer breakdown** — five rows, one per prayer, with count and progress bar
- **Heatmaps** — Week view, Month heatmap, Year view

### Tasbih Details Page

Reached from Home → Daily Tasbih → View Details.

- **Period selector** — Week / Month / Year
- **Progress bars** tracking days completed against the target
- **Active badge** marking the current Tasbih
- **Filters** by Tasbih and Dhikr

### Prayer Reminders & Tasbih Integration

Prayer reminders are delivered through one of two interchangeable backends.

| Backend                    | Status               | Mechanism                                                                           | Requires                                         |
|----------------------------|----------------------|-------------------------------------------------------------------------------------|--------------------------------------------------|
| **Calendar Kit**           | **Active**           | Writes prayer events into a dedicated system calendar account with reminder offsets | READ_CALENDAR + WRITE_CALENDAR (user-granted)    |
| **Agent-Powered Reminder** | Pending AGC approval | Uses reminderAgentManager.publishReminder()                                         | PUBLISH_AGENT_REMINDER (AGC capability approval) |

- **Tasbih Context:** If a Tasbih is bound to a prayer, a compact pill appears next to the Current/Next prayer pill on
  Home and Prayer tabs.
- The pill shows the Tasbih name and opens a popup detailing each Dhikr's progress (e.g., `1/33`).
- Tapping a Dhikr in the popup jumps directly to the Tasbih page with the correct Tasbih, Dhikr, and Prayer context
  loaded.
- Prayed prayers are skipped in the reminder scheduling.

### Qibla Compass

- Live direction to the Kaaba using the device's orientation sensor
- Low-pass filter for smooth, jitter-free readings
- Unwrapped angle math
- Magnetic declination correction
- Distance to Makkah displayed live
- Figure-8 calibration overlay

### Tasbih

- Vertical bead string with visible string line
- Two render styles: **Premium** (3D canvas beads) and **Classic**
- Nine bead themes
- Swipe up to count, swipe down to undo
- Fly-and-pop animation
- Five selectable sound styles + Haptic feedback
- **Binding:** Associate Tasbihs with specific prayers
- **Per-Prayer Live Counts:** The count is tracked independently for each prayer bound to the Tasbih.
- Lifetime counter and 90-day rolling history

### Hijri Calendar

- **Dual engines** — Umm al-Qura and Tabular
- Gregorian and Hijri dates side by side
- Upcoming Islamic events highlighted
- ±3 day offset for local moon-sighting differences
- Localized month names

### Event Tradition

A setting under Customize → UI Customization → Home Page UI that controls which Islamic events appear.

| Value                        | Events shown                                      |
|------------------------------|---------------------------------------------------|
| **Universal only** (default) | Ten events shared by all Muslims                  |
| Sunni + universal            | Adds Laylat al-Raghaib                            |
| Shia + universal             | Adds Arbaeen, Birthday of Imam Ali, Eid al-Ghadir |
| Show all                     | All thirteen registered events                    |

### Backup and Restore

- **Full system backup support** — implements BackupExtensionAbility.onBackup() and onRestore()
- Preserves all settings, Tasbih data (including bindings and per-prayer completions), and prayer progress.
- Diagnostic log excluded from backup.

### Design

- **Five app-wide themes**: Sirat, Sirat Classic, Noor, Sahar, Bahar
- Dark mode with Light / Dark / System
- Three languages: English, 中文, العربية
- Full RTL support
- Responsive layout (Phone, Tablet, Foldable, 2-in-1) with a clean full-screen layout
- First-launch wizard
- HarmonyOS 7 immersive material
- Everything works offline

---

## Getting Started

### Prerequisites

- DevEco Studio 5.0 or later
- HarmonyOS SDK API 21+
- For immersive material features: HarmonyOS 7 device (API 26+)
- A HarmonyOS device or emulator
- Node.js 18+ and ohpm

### Install and Run

1. **Clone the repository:**
   `git clone https://github.com/sharjeel-butt/SiratCompanion-HOS.git`
2. **Open in DevEco Studio:**
   File → Open → select the SiratCompanion-HOS folder.
3. **Sync dependencies:**
   File → Sync and Refresh Project.
4. **Select a device** and press Shift + F10 to build and run.

### Building a Release HAP

1. Sign the app in DevEco Studio: Build → Generate Key and CSR.
2. Build: Build → Build Hap(s) / App(s) → Build Hap(s).

The signed HAP appears under `entry/build/default/outputs/default/`.

---

## Permissions

Declared in `entry/src/main/module.json5`.

| Permission                             | Purpose                                          | Requested                                   |
|----------------------------------------|--------------------------------------------------|---------------------------------------------|
| ohos.permission.APPROXIMATELY_LOCATION | Approximate location for prayer times            | On first GPS request                        |
| ohos.permission.LOCATION               | Precise location for prayer times                | On first GPS request                        |
| ohos.permission.ACCELEROMETER          | Compass and Qibla direction                      | On Compass open                             |
| ohos.permission.VIBRATE                | Haptic feedback on Tasbih counts                 | Declared only, no runtime request           |
| ohos.permission.READ_CALENDAR          | Read the app's own calendar events for cleanup   | On first reminder enable (Calendar backend) |
| ohos.permission.WRITE_CALENDAR         | Write prayer reminder events to the app calendar | On first reminder enable (Calendar backend) |
| ohos.permission.PUBLISH_AGENT_REMINDER | Prayer notifications                             | **Commented out — pending AGC approval**    |

The app declares **no INTERNET permission** — it is fully offline and does not transmit any data.

---

## Localization

The app is fully localized in three languages.

| Language                 | Code | RTL |
|--------------------------|------|-----|
| English                  | en   | No  |
| 中文 (Chinese, Simplified) | zh   | No  |
| العربية (Arabic)         | ar   | Yes |

Localization strings live in `helper/LocalizationHelper.ets`.

---

## Project Structure

```text
entry/src/main/ets/
├── common/
│   ├── Breakpoints.ets              # xs / sm / md / lg width classes
│   ├── ClockFormat.ets              # System / 12h / 24h time formatting
│   ├── FeatureFlags.ets             # Compile-time feature flags
│   ├── PageTheme.ets                # Theme orchestration + isDarkFor()
│   ├── SoundOptions.ets             # Tasbih click sound registry
│   ├── StorageKeys.ets              # All preference keys
│   ├── TasbihThemes.ets             # Bead colour palettes and presets
│   └── Theme.ets                    # ThemeColors, ThemePreset, palettes
├── components/
│   ├── CalendarDayCell.ets          # One day cell in the Hijri grid
│   ├── CategoryHeader.ets           # Settings category header
│   ├── DuaCard.ets                  # Reusable Dua renderer
│   ├── ExtraTimingToggleRow.ets     # One toggle for one timing on one surface
│   ├── FloatingNavBar.ets           # Legacy — superseded by MainTabs
│   ├── PageHeader.ets               # Shared Hijri / location / prayer header
│   ├── PrayerSunPath.ets            # Full 24-hour arc + ticker
│   ├── QiblaCalibrationOverlay.ets  # Figure-8 compass calibration
│   ├── SettingsRow.ets              # Tappable settings row
│   ├── SubsectionHeader.ets         # Gold section label in Customize
│   └── TasbihPill.ets               # Contextual prayer-bound Tasbih dropdown
├── data/
│   ├── Duas.ets                     # Iftar / Suhoor Dua registry
│   ├── IslamicEvents.ets            # Static event table with sect metadata
│   └── PrivacyPolicy.ets            # EN / ZH / AR privacy text
├── models/
│   ├── AdvancedCalcModels.ets       # RoundingMethod, MidnightMethod, etc.
│   ├── DateModels.ets               # IslamicEvent, EventSect, UpcomingImportantDate
│   ├── HijriCalendarModels.ets      # CalendarDay, HijriDate
│   ├── PrayerModel.ets              # PrayerModel, ExtraTiming
│   ├── SettingsModels.ets           # PickerItem, CalculationSource, LocationMode
│   └── TasbihModels.ets             # Tasbih, Dhikr, BeadView, TasbihDayLog
├── helper/
│   ├── AppInfoHelper.ets            # Version + bundle identity
│   ├── AppLogger.ets                # Sandboxed file logger
│   ├── CalendarReminderHelper.ets   # Calendar Kit reminder backend
│   ├── HapticHelper.ets             # Vibration wrapper with two gates
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
├── hijricalendar/
│   ├── HijriCalendarHelper.ets      # Month math + event lookup
│   ├── HijriCalendarType.ets        # Umm al-Qura / Tabular enum
│   └── HijriEngineResolver.ets      # Engine selection by setting
├── utils/
│   ├── CountryTimezoneTable.ets     # Country bounding boxes with offsets
│   ├── DateUtils.ets                # Next-event lookup + formatted dates
│   ├── EventPerspectiveNotifier.ets # Cross-page event filter fan-out
│   ├── HijriCalendarEngine.ets      # Engine interface
│   ├── HomeController.ets           # Prayer-time snapshot builder
│   ├── LocationCache.ets            # Cached GPS location
│   ├── LocationUtils.ets            # GPS fetch + reverse geocode
│   ├── OfflineCityLookup.ets        # City table with timezone + declination
│   ├── PrayerManager.ets            # Prayer state + status
│   ├── PrayerTimeCalculator.ets     # Astronomy math
│   ├── ProgressHelper.ets           # Prayer and Tasbih progress stats
│   ├── QiblaCalculator.ets          # Bearing + distance to Kaaba
│   ├── TabularHijriEngine.ets       # Arithmetical Hijri engine
│   ├── TasbihManager.ets            # Tasbih CRUD + counting + history
│   ├── TasbihStorage.ets            # Tasbih persistence
│   ├── TimezoneResolver.ets         # Offset + DST resolution
│   └── UmmAlQuraEngine.ets          # KACST table Hijri engine
├── pages/
│   ├── AdvancedCalcPage.ets
│   ├── CustomizePage.ets
│   ├── HijriCalendarPage.ets
│   ├── HomePage.ets
│   ├── MainTabs.ets                 # Root page hosting the five primary screens
│   ├── Prayer.ets
│   ├── PrayerDetailsPage.ets        # Week / Month / Year prayer progress
│   ├── QiblaPage.ets
│   ├── SettingsPage.ets
│   ├── TasbihDetailsPage.ets        # Week / Month / Year tasbih progress
│   ├── TasbihPage.ets
│   └── WizardPage.ets
└── entryability/
    ├── EntryAbility.ets
    └── EntryBackupAbility.ets
```

### Layering

The codebase follows a three-layer architecture:

- **Pages** are @Entry or @Component components holding @State, @Builder, and event handlers. They render and delegate.
- **Helpers** are stateless façades: SettingsHelper, NotificationHelper, etc.
- **Core** is the bottom layer: PrayerTimeCalculator, PreferencesHelper, TimezoneResolver, etc.

> **Rule of thumb:** pages never touch @ohos.data.preferences directly.

---

## Navigation Architecture

The app uses a single root page — `MainTabs.ets` — that hosts five primary screens inside a native Tabs container:
Home → Prayers → Calendar → Compass → Tasbih.

Secondary pages — WizardPage, CustomizePage, SettingsPage, etc. — remain routable and use `router.pushUrl()` /
`router.back()` for navigation.

### Why a single root page?

HarmonyOS 7 grants the immersive system material only to specific host components. The bottom TabBar of a horizontal
Tabs(barPosition.End) qualifies.

---

## Theming

Five app-wide theme presets, each with a matched light and dark palette.

| Preset        | Palette                                                     |
|---------------|-------------------------------------------------------------|
| **Sirat**     | HarmonyOS 7 blue — bright accent, minimal, modern (default) |
| Sirat Classic | Warm cream + deep green                                     |
| Noor          | Radiant violet — serene and modern                          |
| Sahar         | Golden amber — the calm of first light                      |
| Bahar         | Cool teal — vast, fresh, and clear                          |

### Light / Dark / System

Orthogonal to the preset. Selected from **Customize → Appearance → Dark Mode**.

When resolving which palette is in effect, always use `PageTheme.isDarkFor(themeMode)`.

### Live propagation

Every page observes both `STORAGE_KEY_THEME_MODE` and `STORAGE_KEY_APP_THEME` via `@StorageLink` and recomputes its
colors on change.

---

## Immersive Material (HarmonyOS 7)

On HarmonyOS 7 (API 26+) the bottom navigation bar uses the native system immersive material. On API 21–25 it falls back
to a translucent blurred bar with identical interaction.

### Requirements

1. module.json5 metadata `ohos.arkui.UIMaterial.state = enable`
2. Device supports the HDS material tier (API 23+)
3. Host is a horizontal HdsTabs with barFloatingStyle

---

## Prayer Reminders

The app supports two reminder backends, selected at compile time by flags in `common/FeatureFlags.ets`.

### Backend 1 — Calendar Kit (active)

Prayer reminders are written as events into a dedicated "Sirat Companion" calendar account in the system calendar.

**Cleanup safety**

`CalendarReminderHelper.cancelAll()` applies three independent layers of scoping:

1. **Account scoping** — the calendar object is the app's own account.
2. **Title filter** — `EventFilter.filterByTitle('Sirat · ')` restricts the result set.
3. **Per-event re-check** — each event is verified to carry the prefix before its delete call.

### Backend 2 — Agent-Powered Reminder (pending AGC approval)

Uses `reminderAgentManager.publishReminder()` from `@kit.BackgroundTasksKit`.

### Switching between backends

The switch is entirely compile-time. No runtime logic differs between the two. See `FeatureFlags.ets`.

---

## Testing Reminders

### Calendar backend

| Check                                       | Expected                                                              |
|---------------------------------------------|-----------------------------------------------------------------------|
| Settings → Notifications → toggle master on | Calendar permission dialog appears                                    |
| Grant both permissions                      | Toggle stays on; test button becomes enabled                          |
| Tap Test Notification                       | A test event appears; **existing real prayer events are NOT deleted** |
| Mark a prayer as prayed                     | That prayer's reminder is removed on the next reschedule              |

---

## Timezone Handling

Prayer times are calculated for the location's timezone, not the device's.

`TimezoneResolver.effectiveOffsetForLocation()` does the following:

1. **Nearest city** — checks `OfflineCityLookup` for the nearest known city within 300 km.
2. **Country fallback** — tests the location against a table of country bounding boxes.
3. **Longitude estimate** — only if both lookups miss (open ocean).
4. Applies US / EU / AU / NZ / Egypt DST rules based on the date.

---

## Backup and Restore

The app implements HarmonyOS's system backup framework via `EntryBackupAbility`.

### What is preserved

- All settings — language, theme mode, app theme preset, Hijri offset, etc.
- All Tasbih data — every custom Tasbih, every Dhikr, current counts, daily totals, 90-day history, **prayer bindings**,
  and **per-prayer completion dates**.
- Cached GPS location.

### What is excluded

- The diagnostic log — regenerates fresh on the new device.

---

## Version History

| Version   | Highlights                                                                              |
|-----------|-----------------------------------------------------------------------------------------|
| 2.6.0     | RTL sun path, MainTabs HOS7 material, sunrise/sunset fix, vendor rename                 |
| 2.7.0     | Adhan-parity methods, Advanced Calculation page                                         |
| 2.8.0     | Location as top-level category, sun path 24-hour arc                                    |
| 2.9.0     | Umm al-Qura and Tabular engines, time format                                            |
| 2.9.1     | Material on sheets and overlays, EasyGo, HDS migration                                  |
| 2.9.2     | API 21 log viewer crash fix                                                             |
| 3.0.0     | Consolidated material, adaptive layouts, localization                                   |
| 3.0.1     | AGC feedback round: events, timezone, AR/ZH missing keys, progress dots, tab bar labels |
| 3.1.0     | Event Tradition filter, Hijri reactivity, settings propagation                          |
| 3.2.0     | Hijri engines wired, full 24-method set, backup and restore                             |
| 3.2.1     | Patch release                                                                           |
| 3.2.3     | Splash color, localization timing on Customize subsections                              |
| 3.2.4     | Per-surface extra-timing toggles, Imsak on sun path                                     |
| 3.3.0     | Prayer and Tasbih detail pages, daily Tasbih mechanics, Home restructure                |
| 3.3.1     | Themed flying bead and halo in the Tasbih renderer                                      |
| 3.3.2     | Period-specific views, shorter Home card labels                                         |
| 3.3.3     | Country timezone fallback, Tasbih reset semantics, daily total tracking                 |
| 3.4.3     | Diyanet temkin offsets, Jafari Maghrib, AppGallery 2-in-1 exit fix                      |
| 3.5.5     | Ramadan tracker (Fasting, Qada, Taraweeh, Duas), UI/Qada enhancements                   |
| **3.5.6** | **Tasbih-Prayer binding, Tasbih pill, 2-in-1 full-screen fix, PDF/RTL fixes**           |

---

## Roadmap

### Completed

- [x] Home dashboard — progress, streaks, weekly grid, monthly heatmap
- [x] Ramadan card — Ashras, Laylat al-Qadr, Jummah tul Widah
- [x] Five app-wide themes with matched light/dark palettes; Sirat as default
- [x] Tasbih sounds — five selectable click styles
- [x] Per-tasbih bead themes — nine presets
- [x] Qibla calibration overlay
- [x] Tablet / foldable / 2-in-1 responsive layouts
- [x] System feedback integration — respects ringer mode and haptics toggle
- [x] HarmonyOS 7 immersive material with API 21 fallback
- [x] Calendar Kit reminder backend
- [x] Full 24-hour sun-path arc with continuous ticker and midnight slide
- [x] Skip-if-prayed reminder behaviour
- [x] Dual Hijri calendar engines
- [x] Prayer Details & Tasbih Details pages
- [x] **Tasbih-Prayer binding with independent per-prayer live counts**
- [x] **Contextual Tasbih Pill with popup and anchor navigation**

### In Progress

- [ ] Agent-Powered Reminder capability approval (AGC)
- [ ] Re-sign and re-apply to AppGallery

### Next Up

- [ ] Online (API) prayer times provider
- [ ] Home screen widgets
- [ ] Adhan audio playback

---

## Contributing

Contributions are welcome.

### Commit Convention

This project uses Conventional Commits (e.g., `feat:`, `fix:`, `docs:`).

### Code Style

- ArkTS strict mode is required — no `any`, no untyped object literals.
- Keep pages free of business logic — delegate to helpers.
- Resolve dark-mode state via `PageTheme.isDarkFor(themeMode)`, not `PageTheme.isSystemDark()`.
- Parameterless `@Builder`s for anything that reads state to ensure UI reactivity.

---

## Known Limitations

- **Prayer reminders use the Calendar backend** (workaround pending AGC approval).
- **Online (API) prayer times** are stubbed.
- **Compass** requires a real device. Emulators without a magnetometer show "sensor unavailable".
- **High-latitude prayer times** clamp the hour angle to [-1, 1].
- **Tasbih history** is retained for 90 days.
- **PDF exports** are saved to a file location of the user's choice via the
  HarmonyOS document picker. Third-party apps cannot request the system-level
  `ohos.permission.PRINT`, so direct printing is not supported; users can open
  the saved PDF in any viewer and print from there.

---

## License

This project is licensed under the **MIT License**.

---

## Acknowledgements

- **Jean Meeus** — *Astronomical Algorithms* — source of the solar position math
- **PrayTimes.org** — reference for the calculation conventions
- **Adhan library** — reference for the extended calculation-method set
- **HarmonyOS Developer Docs** — for `@kit.ArkUI`, `@kit.ArkData`, `@kit.BackgroundTasksKit`, `@kit.CalendarKit`, and
  the immersive material API

---

## Contact

- **Issues** — github.com/sharjeel-butt/SiratCompanion-HOS/issues
- **Telegram** — t.me/siratcompanionhos

---

**May it be of benefit.** 🤲

*If Sirat Companion helps you with your daily worship, consider starring the repository.*