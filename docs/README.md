# Sirat Companion

> Your daily Islamic companion for HarmonyOS — prayer times, Qibla, Tasbih, and Hijri calendar, all in one offline-first
> app.

Sirat Companion is a HarmonyOS application written in ArkTS / ArkUI. It runs entirely on-device: no accounts, no
servers, no analytics, no ads.

---

## Table of Contents

- [Features](#features)
- [Screens](#screens)
- [Requirements](#requirements)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Localization](#localization)
- [Data & Storage](#data--storage)
- [Permissions](#permissions)
- [Privacy](#privacy)
- [Versioning](#versioning)
- [Roadmap](#roadmap)
- [License](#license)
- [Contact](#contact)

---

## Features

### 🕌 Prayer Times

- All five daily prayers — Fajr, Dhuhr, Asr, Maghrib, Isha — calculated with the Meeus sun-position algorithm
- Four calculation conventions: **Karachi**, **Jafari**, **ISNA**, **MWL**
- Two Asr shadow rules: **Standard** (Shafi'i / Maliki / Hanbali) and **Hanafi**
- Four high-latitude fallback rules for Fajr/Isha when the sun doesn't reach the required angle
- Per-prayer manual offsets (−60 to +60 minutes) with a reset option
- Extra timings combined into the same timeline: Imsak, Sunrise, Sunset, First Third, Midnight, Last Third
- Offline timezone resolution via a 60+ city lookup with DST rules for US, EU, and AU

### 🧭 Qibla Compass

- Great-circle bearing to the Kaaba from your location
- Orientation sensor with magnetometer fallback
- Magnetic declination correction from an offline per-city table
- Low-pass filtered heading and unwrapped rotation for smooth animation
- Distance to the Kaaba

### 📿 Tasbih

- Custom tasbihs with multiple dhikr items each
- Vertical bead-string animation with LIFO rolling-window entry
- Fisheye loupe that magnifies beads under your finger while counting
- Two render styles — **Premium (3D canvas)** and **Classic (declarative)**
- Five theme presets (Amber, Charcoal, Emerald, Pearl, Gold), each with two finishes (Matte / Metallic)
- Per-tasbih themes — each tasbih remembers its own colour
- Lifetime counter per tasbih, and two reset levels (current dhikr / whole tasbih)
- Adjustable haptic feedback on each count

### 📅 Hijri Calendar

- Month grid with today, Friday, and Islamic event highlighting
- ±3 day Hijri offset that shifts every Hijri date in the app
- Nine built-in Islamic events — Islamic New Year, Ashura, Mawlid, Isra & Mi'raj, Mid-Sha'ban, Ramadan, Eid al-Fitr,
  Arafah, Eid al-Adha
- Localized month and event names

### 🏠 Home Dashboard

- **Upcoming event countdown** — days until the next Islamic event, honouring the Hijri offset
- **Ramadan card** (visible within 60 days of Ramadan) with:
    - Today's fasting window (Imsak → Maghrib) during Ramadan, or a first-day preview during countdown
    - Three Ashras with their significance (Mercy / Forgiveness / Freedom from Hellfire)
    - Laylat al-Qadr candidate nights (odd nights of the last ten days)
    - Jummah tul Widah (last Friday of Ramadan)
- **Live countdown** to Imsak and Maghrib — starts 15 minutes before the event, holds for 5 minutes after, with the
  corresponding Dua displayed at zero
- **Today's prayer progress** — 0–5 counter, ring, and per-prayer dots
- **Streaks** — current and best consecutive all-five days
- **Weekly grid** — last 7 days at a glance
- **Monthly heatmap** — every day of the current Gregorian month, colour-coded by completion
- **Tasbih statistics** — lifetime count, tasbih count, total dhikr

### ⚙️ Settings & Customization

- Theme: Light / Dark / Follow System, applied instantly across every screen
- Language: English / 中文 / العربية, with full RTL support for Arabic
- Location: GPS with reverse geocoding fallback chain, or manual coordinates with optional city override
- Vibration toggle
- Diagnostic log viewer (view, copy, clear) for troubleshooting on-device

### ✨ Polish

- Frobenius-glass floating navigation bar
- Tap-to-navigate between Home / Prayers / Calendar / Compass / Tasbih
- Full localization with an on-demand language picker
- First-launch wizard with explicit privacy consent
- Pull-to-refresh on Home and Prayers
- Auto-refresh of every screen when the app returns from the background

---

## Screens

| Home                               | Prayers                        | Tasbih                    | Compass         | Calendar         |
|------------------------------------|--------------------------------|---------------------------|-----------------|------------------|
| Dashboard, streak, monthly heatmap | Timeline of prayers and extras | Bead counting with themes | Qibla direction | Hijri month view |

*(Add screenshots here once available.)*

---

## Requirements

- **DevEco Studio** 5.0 or later
- **HarmonyOS SDK** API 12 (5.0.0) or later — target API 22+
- A device or emulator running **HarmonyOS 5.0+**

---

## Getting Started

### Clone

```bash
git clone https://github.com/<your-username>/SiratCompanion-HOS.git
cd SiratCompanion-HOS

Build
Open the project in DevEco Studio and let it sync oh-package.json5. Then:

Build → Clean Project

Build → Build Hap(s) / App(s)

Run on a connected device or emulator

Run from CLI
bash
hvigorw assembleHap --mode module -p product=default
hdc install entry/build/default/outputs/default/entry-default-signed.hap
Signing
The project uses manual signing with a release keystore and a .p7b profile generated in AppGallery Connect. Update File → Project Structure → Signing Configs with your own credentials before building a release HAP.

SiratCompanion-HOS/
├── AppScope/
│   ├── app.json5                        # bundle name, version, icon, label
│   └── resources/
│       └── base/element/string.json     # app_name (source of truth for the brand name)
│
└── entry/src/main/
    ├── module.json5                     # permissions, abilities, extension abilities
    ├── resources/
    │   ├── base/profile/main_pages.json # every page must be listed here
    │   └── base/element/                # strings, colours, floats
    │
    └── ets/
        ├── common/
        │   ├── FeatureFlags.ets         # compile-time toggles
        │   ├── PageTheme.ets            # system dark-mode listener + compute()
        │   ├── StorageKeys.ets          # every AppStorage / Preferences key
        │   ├── TasbihThemes.ets         # tasbih colour presets + finishes
        │   └── Theme.ets                # ThemeColors tokens, radii, padding
        │
        ├── components/
        │   ├── DuaCard.ets              # reusable Dua renderer (Arabic + transliteration + translation)
        │   ├── FloatingNavBar.ets       # glass-effect bottom navigation
        │   └── PageHeader.ets           # shared header for Home + Prayers
        │
        ├── data/
        │   ├── Duas.ets                 # Dua registry (Iftar, Suhoor, extensible)
        │   ├── IslamicEvents.ets        # the nine important events
        │   └── PrivacyPolicy.ets        # full policy text in EN / ZH / AR
        │
        ├── entryability/
        │   └── EntryAbility.ets         # app entry point + foreground tick
        ├── entrybackupability/
        │   └── EntryBackupAbility.ets   # backup extension stub
        │
        ├── helper/
        │   ├── AppInfoHelper.ets        # version + app name from the bundle
        │   ├── AppLogger.ets            # rotating file logger
        │   ├── HapticHelper.ets         # vibrator wrapper
        │   ├── HijriCalendarHelper.ets  # Gregorian ↔ Hijri conversion
        │   ├── LocalizationHelper.ets   # all strings for EN / ZH / AR
        │   ├── NavHelper.ets            # tab order + slide-direction
        │   ├── NotificationHelper.ets   # (disabled pending AGC approval)
        │   ├── PreferencesHelper.ets    # async Preferences wrapper
        │   ├── QiblaSensorHelper.ets    # orientation + magnetometer
        │   ├── RamadanHelper.ets        # Ramadan timeline, ashras, Laylat al-Qadr
        │   └── SettingsHelper.ets       # typed settings access
        │
        ├── models/
        │   ├── DateModels.ets
        │   ├── HijriCalendarModels.ets
        │   ├── PrayerModel.ets
        │   ├── SettingsModels.ets
        │   └── TasbihModels.ets
        │
        ├── pages/
        │   ├── WizardPage.ets           # first-launch wizard
        │   ├── HomePage.ets             # dashboard
        │   ├── Prayer.ets               # prayers timeline
        │   ├── HijriCalendarPage.ets
        │   ├── QiblaPage.ets
        │   ├── TasbihPage.ets
        │   ├── SettingsPage.ets
        │   └── CustomizePage.ets
        │
        └── utils/
            ├── DateUtils.ets            # Gregorian ↔ Hijri helpers
            ├── HomeController.ets       # timeline + header snapshots
            ├── LocationCache.ets        # last known GPS fix
            ├── LocationUtils.ets        # permissions + reverse geocoding
            ├── OfflineCityLookup.ets    # 60+ cities with timezone + declination
            ├── PrayerManager.ets        # state, offsets, status computation, storage
            ├── PrayerTimeCalculator.ets # Meeus algorithm + high-latitude rules
            ├── ProgressHelper.ets       # streaks, weekly grid, monthly heatmap
            ├── QiblaCalculator.ets      # great-circle bearing + distance
            ├── TasbihManager.ets        # pure data operations
            ├── TasbihStorage.ets        # preferences-backed persistence
            └── TimezoneResolver.ets     # DST rules + device-vs-location offset

Architecture
Data flow

User interaction → Page (@State) → Helper / Manager → PreferencesHelper → Disk
                                          │
                                          ├→ AppStorage (for watchers)
                                          └→ Indexed maps (for instant reads)

AppStorage carries reactive state across pages: theme mode, language, Hijri offset, foreground tick.

PreferencesHelper is the single async persistence layer — everything ultimately lands here.

Module statics (like PrayerManager.stateMap) hold hot state in memory so reads are synchronous. Persistence happens in the background.

Reactivity rules followed throughout the project
Every page mirrors appLanguage into a local @State currentLanguage and passes it explicitly — never relies on @Watch firing for a self-assigned @StorageLink.

Parameterized @Builder methods are avoided for anything that must re-render when a value changes. Values are read directly from @State inside the render tree instead.

ForEach keys always include every field whose change should force a rebuild — including checked on prayer rows and the theme colour on bead rows.

Storage keys
All AppStorage and Preferences keys are declared in common/StorageKeys.ets. Do not hard-code key strings anywhere else.

Feature flags
common/FeatureFlags.ets holds NOTIFICATIONS_ENABLED. When false, notification UI, permissions, and scheduling paths are all skipped at runtime.

Localization
Three languages are supported out of the box: English (en), Chinese (zh), and Arabic (ar).

All UI strings live in helper/LocalizationHelper.ets

L.get(key, lang) returns the string for the given language, falling back to English and then to the key itself

L.isRtlLang(lang) drives .direction(Direction.Rtl : Direction.Ltr) on each page root

Arabic layouts mirror the whole page except for compass rose, coordinate inputs, and the calendar grid (kept LTR for correctness)

A future language can be added by appending a new Map<string, string> builder to LocalizationHelper

Adding a new string
Add m.set('my_key', 'My String') in buildEn(), buildZh(), and buildAr()

Reference it in code as this.tr('my_key')

Data & Storage
Everything is stored on-device. No accounts, no servers, no telemetry.

Data	Where	Survives uninstall?
Settings (theme, language, offsets…)	Preferences (sirat_settings)	❌
Tasbihs + dhikrs + counts + themes	Preferences (tasbih_prefs)	❌
Prayer completion history	Preferences (prayer_state_map)	❌
Last known GPS location	Preferences (gps_*)	❌
Diagnostic log file	<filesDir>/sirat_log.txt (200 KB rotating)	❌
Uninstalling the app deletes everything. There is no cloud backup enabled by the app itself (system-level backup is a user opt-in governed by Huawei's policy).

Permissions
Permission	When requested	Purpose
ohos.permission.VIBRATE	On Tasbih use	Haptic feedback per count
ohos.permission.APPROXIMATELY_LOCATION	First location use	Coarse prayer time calculation
ohos.permission.LOCATION	First location use	Precise prayer time calculation
ohos.permission.ACCELEROMETER	First Qibla use	Compass heading
ohos.permission.PUBLISH_AGENT_REMINDER	Currently disabled	Prayer time notifications (pending AGC capability approval)
Every permission is optional — the app degrades gracefully if the user denies it.

Privacy
Sirat Companion does not collect, transmit, or share any personal data. All data is local.

Full privacy policy: sharjeel-butt.github.io/SiratCompanion-HOS

In-app policy: data/PrivacyPolicy.ets (available in EN / ZH / AR)

The first-launch wizard requires explicit consent before proceeding

Versioning
Field	Value
versionName	2.1.0
versionCode	2001000
buildVersion	210
Version is read from AppScope/app.json5 at build time. The Settings → About screen pulls it at runtime via bundleManager, so there is never a mismatch between the manifest and what the user sees.

History
Version	Highlights
1.2.0	i18n, RTL, first-launch wizard, Hijri calendar, high-latitude rules, prayer accuracy fixes
1.3.0	Notifications, timeline-aware next prayer
1.4.0	Premium Tasbih beads, fisheye loupe, LIFO rolling window, diagnostic logger
1.4.1	Bug fixes, log viewer improvements
2.0.0	Home dashboard, Ramadan card, monthly heatmap, progress streaks, per-tasbih themes, live Duas countdown, foreground refresh, glass floating bar
2.1.0  Four app-wide themes (Sirat Classic, Noor, Sahar, Bahar), theme step in the wizard, Tasbih click sounds with five selectable styles, system sound & haptics integration, sun-path canvas redesign with moving time ticker, Tasbih fly-and-pop animation, heavier glass floating bar

## Roadmap

### In progress

- [ ] **Re-enable prayer notifications** — code is complete in `NotificationHelper.ets` and gated behind `FeatureFlags.NOTIFICATIONS_ENABLED`. Blocked on **Agent-Powered Reminder** capability approval in AppGallery Connect (~8 working days from submission). Re-enabling is a four-line change once approved: flip the flag, uncomment the `PUBLISH_AGENT_REMINDER` permission in `module.json5`, restore the notification disclosures in the privacy policy, and regenerate the signing profile.

### Next up

- [ ] **Dedicated Duas tab** — the infrastructure is ready. `data/Duas.ets` holds the registry (`DUA_REGISTRY`, `Duas.byKey()`) and `components/DuaCard.ets` renders any entry with Arabic, transliteration, and translation. Needs a new `pages/DuasPage.ets` (~30 lines), a `main_pages.json` entry, and a slot in the floating nav bar. Adding new Duas afterwards requires just one registry entry and two localization keys per language.

- [ ] **Qibla calibration UX (figure-8 flow)** — surface the sensor's `accuracy` field from `QiblaSensorHelper`, and present an animated figure-8 overlay in `QiblaPage` whenever accuracy drops below a threshold. Clears once the user traces the pattern and the compass stabilises.

- [ ] **Additional languages — Urdu first** — the localization structure is ready. `LocalizationHelper` needs a new `Map<string, string>` builder (~150 keys), and the language pickers in `CustomizePage` and `WizardPage` need their option lists expanded. Urdu is the natural first addition — closest cousin to Arabic and the largest unserved Muslim-language audience.

### Later

- [ ] **Online (API) prayer times provider** — currently a stub. The `CalculationSource.API` enum value exists, and both the Settings and Wizard pickers block selection with a "coming soon" toast. Implementation requires a network client, a provider contract (e.g. AlAdhan), response caching, error handling, and an `INTERNET` permission. Also requires a privacy-policy update since the app would begin making network requests for the first time.

- [ ] **Adhan audio playback** — plays the full call to prayer at each prayer time. Needs `AVPlayer` (not `SoundPool`), a bundled or streamed Adhan file, and — ideally — the same Agent-Powered Reminder capability that notifications are pending on, so playback can fire independently of the app being open.

- [ ] **Tablet and foldable layouts** — `module.json5` currently declares `"deviceTypes": ["phone"]`. Tablet support starts with expanding that list and then adding responsive layouts using `GridRow`/`GridCol` or `mediaquery` breakpoints. Every page has fixed-width elements (floating bar at 92%, hardcoded pill sizes) that would need to adapt.

- [ ] **Home screen widgets** — no widget service exists. Needs a `form_config` extension ability, a `FormAbility`, and a separate widget UI. The data sources (`CalculationSource`, `LocationCache`, `ProgressHelper`) already expose everything a widget needs.

- [ ] **Full HarmonyOS 7 glass-effect styling** — the frosted-glass floating bar now delivers most of the visual language on API 22+. What still requires **API 26 SDK** is the animated-blur transition between tabs, depth-based shadow scaling, and adaptive colour extraction from background content.

- [ ] **Cloud sync (opt-in)** — no account system, no network code, no cloud storage SDK. Would require an explicit consent flow and a privacy-policy revision before any work begins. Deliberately deferred to protect the current "everything is local" guarantee.

### Completed

- [x] **Hijri date manual override** — shipped with a ±3 day offset (exceeds the original ±1 day target), applied globally across the Home header, Prayer page, Hijri calendar, and Next Event countdown.
- [x] **Prayer streak statistics** — Home dashboard delivers today's progress ring, current and best streaks, a 7-day grid, a monthly heatmap, perfect-day count, and a lifetime total over the last 365 days.
- [x] **Multiple app themes** — Sirat Classic, Noor, Sahar, and Bahar, each with matched light and dark palettes, selectable in Customize → Appearance and in the first-launch wizard.
- [x] **Tasbih sound system** — five selectable click styles with SoundPool playback, respecting the system ringer mode and haptics toggle.

Contributing
Issues and pull requests are welcome.

Before opening a PR
Follow the existing reactivity rules — in particular, do not rely on @Watch firing for self-assigned @StorageLink values

Add localization keys to all three languages

Test on a real device, not just the emulator

Keep the codebase free of third-party analytics, ads, or tracking libraries

License
This project is licensed under the MIT License. See LICENSE for the full text.

Contact
Developer: Sharjeel Butt
Email: sharjeel.butt@gmail.com
Issues: GitHub Issues

Built with 🤲 for the Ummah.


---

## What's included and why

| Section | Purpose |
|---|---|
| **Features** | Grouped by user-facing area so a newcomer immediately sees what the app does |
| **Screens** | Placeholder table — drop in screenshots later |
| **Requirements** | API 22+ target matching `build-profile.json5` |
| **Getting Started** | Both DevEco GUI and CLI paths, plus a signing note |
| **Project Structure** | Annotated tree — every file has a one-line purpose |
| **Architecture** | The three reactivity rules that keep the app stable; new contributors need these |
| **Localization** | How to add a string and a language |
| **Data & Storage** | Explicit table so users and reviewers can see nothing leaves the device |
| **Permissions** | Honest about the currently-disabled reminder permission |
| **Privacy** | Links to the hosted policy |
| **Versioning** | Ties to `app.json5` and shows the release history |
| **Roadmap** | Communicates intent without over-promising |
| **Contributing** | Reiterates the rules that matter most |

## Placeholders to fill in

Only two things need your attention before committing:

1. **Repository URL** — replace `<your-username>` in the clone command and the Issues link
2. **Screenshots** — once you have them, replace the `*(Add screenshots here…)*` line with real images

## Commit

```bash
git add README.md
git commit -m "docs: add README covering features, architecture, and setup"
git push origin main