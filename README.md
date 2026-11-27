# Sirat Companion

**Sirat Companion** is an offline-first Islamic companion application built natively for HarmonyOS.

The application combines prayer times, Quran, Hadith, Duas, Qibla, Tasbih, Hijri calendar, Islamic events, widgets,
reminders, and multilingual Islamic content into a single integrated experience designed for phones, tablets, foldables,
and HarmonyOS 2‑in‑1 devices.

Unlike most Islamic applications, Sirat Companion does not rely on continuous internet connectivity. Core features,
calculations, Islamic content, translations, prayer schedules, and supporting metadata operate entirely offline.

---

## Highlights

### Prayer Times Engine

- 24 calculation methods
- Standard and Hanafi Asr rules
- Advanced high-latitude handling
- Polar region support
- Per-prayer offsets
- Diyanet, Umm al-Qura, Jafari, ISNA, MWL, Egypt, Qatar, Indonesia and many additional conventions
- Advanced calculation controls
- Timezone-aware calculations
- Offline operation

### Quran Platform

- Integrated Quran reader with Quran.com-sourced content
- Quran collections, exploration, and Surah detail views
- Quranic Duas
- Multiple translation support with independent language selection
- Configurable Arabic and translation typography
- Offline content delivery

### Hadith Platform

- Fully offline, multilingual Hadith database
- Canonical database architecture and metadata-driven content delivery
- Independent translation selection
- Browse by books and topics, with local filtering
- Context-aware topic search with full-text fallback
- Hadith grading presentation, Sanad timeline, and authenticity-resource links where available

### Dua Platform

- Built-in Dua library, including Quranic Duas
- Independent translation language selection
- Offline access and multilingual support
- Custom-event keyword support and improved Dua presentation

### Tasbih System

- Multiple Tasbih collections
- Prayer-linked Tasbih tracking
- Independent prayer progress
- Statistics and streaks
- Daily targets
- Lifetime tracking

### Qibla System

- Real-time Qibla compass
- Magnetic declination support
- Distance-to-Makkah calculations
- Calibration guidance
- Sensor-fusion improvements

### Hijri Calendar

- Umm al-Qura engine
- Tabular engine
- Islamic event support
- Event tradition filtering
- Adjustable Hijri offset
- Localized month names

### Widgets

- Prayer, Hijri date, daily Adhkar, upcoming event, Ramadan, and faith-tracker widgets
- Multiple widget sizes and responsive layouts
- Deep links from widgets into relevant app screens
- Cold-start and warm-start navigation support
- Shared widget data-building and localization pipeline

### Offline Mosque Finder

- Offline mosque discovery and lookup
- Integrated Islamic location support

### Backup & Restore

- HarmonyOS system backup and restore integration
- Preservation of settings, prayer progress, Tasbih data, custom mosque data, and related user content
- Version-aware backup migration and restore handling

---

## Independent Translation System

Sirat Companion supports independent content languages.

Users may select separate languages for:

- Quran translations
- Hadith translations
- Dua translations

This allows combinations such as:

| UI Language | Quran   | Hadith | Duas    |
|-------------|---------|--------|---------|
| Urdu        | English | Arabic | Urdu    |
| Arabic      | Turkish | Arabic | Arabic  |
| English     | Bengali | Urdu   | English |

Content language selection is completely independent from the application's user interface language.

---

## Supported Content Languages

Current supported content languages include:

- Arabic
- English
- Urdu
- Bengali
- Indonesian
- Turkish
- Chinese

Additional languages can be added through the translation pipeline and canonical database generation process.

---

## Canonical Islamic Content Platform

Beginning with the v4.x series, Sirat Companion migrated from static content resources to a unified canonical data
platform.

The platform provides:

- Canonical database generation
- Metadata generation
- Localization generation
- Translation validation
- Translation publication workflow
- Language-specific database generation
- HarmonyOS asset packaging
- Offline deployment bundles

This architecture allows future expansion without requiring application redesign.

---

## Recent Major Releases

### v4.1.5

**Notification Reliability, Theme Fixes & Prayer UI Refinements**

- Fixed the themes selector page
- Applied minor Prayer UI refinements
- Made Prayer and Ramadan notifications non-dismissable

### v4.1.4

**Configurable Themes, Languages & Home Experience**

- Moved application and Tasbih theme definitions to JSON-based configuration
- Moved language configuration out of hardcoded definitions
- Redesigned the Home page
- Added Home notifications for missed and upcoming achievements and daily activities
- Fixed Tasbih-to-prayer navigation and updated Dua translations
- Reorganized code and cleaned up raw resources

### v4.1.3

**Quranic Duas, Typography & Hadith Improvements**

- Added Quranic Duas
- Added Arabic font and translation font settings
- Improved Hadith grading presentation and authenticity-resource navigation
- Updated Dua usability and Recitations layout
- Fixed HarmonyOS PC exit behavior

### v4.1.2

**Quran Content Source & Calculation Fixes**

- Changed the Quran content source from QUL to Quran.com
- Fixed World Magnetic Model and prayer-time calculation issues

### v4.1.1

**Calculation Accuracy Maintenance**

- Fixed World Magnetic Model and prayer-time calculation issues

### v4.1.0

**Data Platform Migration, Sanad UI & Independent Translations**

- Canonical Islamic data platform
- Independent translation architecture
- Multi-language Hadith platform
- Translation review workflow
- Enhanced localization system
- Database-driven content delivery

### v4.0.8

**Maintenance and Stability Release**

- Platform refinements
- Stability improvements
- Bug fixes

### v4.0.7

**Database Compression & Reliability**

- GZip database compression
- Prayer timestamp improvements
- Backup hygiene fixes
- Widget enhancements

### v4.0.6

**Offline Hadith Engine**

- New offline Hadith architecture
- Widget upgrades
- Critical fixes

### v4.0.4

**Offline Mosque Finder**

- Mosque Finder
- Expanded widget ecosystem
- Core platform improvements

### v4.0.0

**Quran Reader & Global Timezone Engine**

- New Quran reader
- Global timezone engine
- Widget stability improvements

### v3.8.x

**Widget Ecosystem Era**

- Complete widget ecosystem
- AI intents
- Domain reorganization
- Navigation improvements

---

## Design Philosophy

Sirat Companion is built around five principles:

1. **Offline First**
    - Essential Islamic functionality should work without internet access.

2. **Privacy First**
    - User data remains on the device.

3. **Localization First**
    - Islamic content should be available in the user's preferred language.

4. **Accuracy First**
    - Prayer calculations, Hijri conversions, and Qibla direction should prioritize correctness.

5. **HarmonyOS Native**
    - The application follows HarmonyOS design patterns and platform capabilities rather than acting as a cross-platform
      port.

---

## Current Version

**Version:** 4.1.5  
**Platform:** HarmonyOS  
**Architecture:** Offline-first, modular HarmonyOS application with a canonical Islamic content platform  
**Content Delivery:** Local databases, JSON configuration, and packaged offline resources

---

## Table of Contents

- [Highlights](#highlights)
- [Independent Translation System](#independent-translation-system)
- [Supported Content Languages](#supported-content-languages)
- [Canonical Islamic Content Platform](#canonical-islamic-content-platform)
- [Recent Major Releases](#recent-major-releases)
- [Design Philosophy](#design-philosophy)
- [Current Version](#current-version)
- [Features](#features-supports-phone-tablet-foldable-and-2-in-1)
- [Getting Started](#getting-started)
- [Permissions](#permissions)
- [Localization](#localization)
- [Project Structure](#project-structure)
- [Navigation Architecture](#navigation-architecture)
- [Theming](#theming)
- [Immersive Material (HarmonyOS 7)](#immersive-material-harmonyos-7)
- [Prayer Reminders](#prayer-reminders)
- [Testing Reminders](#testing-reminders)
- [Timezone Handling](#timezone-handling)
- [Backup and Restore](#backup-and-restore)
- [Version History](#version-history)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [Known Limitations](#known-limitations)
- [License](#license)
- [Acknowledgements](#acknowledgements)
- [Contact](#contact)

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

- **Independent Translation Languages**: Customize the translation language for Quran, Hadith, and Duas independently
  from the app's main UI language. For example, you can keep the app UI in Urdu while reading the English translation of
  the Quran.

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

| Permission                             | Purpose                                               | Requested                                   |
|----------------------------------------|-------------------------------------------------------|---------------------------------------------|
| ohos.permission.APPROXIMATELY_LOCATION | Approximate location for prayer times                 | On first GPS request                        |
| ohos.permission.LOCATION               | Precise location for prayer times                     | On first GPS request                        |
| ohos.permission.ACCELEROMETER          | Compass and Qibla direction                           | On Compass open                             |
| ohos.permission.VIBRATE                | Haptic feedback on Tasbih counts                      | Declared only, no runtime request           |
| ohos.permission.READ_CALENDAR          | Read the app's own calendar events for cleanup        | On first reminder enable (Calendar backend) |
| ohos.permission.WRITE_CALENDAR         | Write prayer reminder events to the app calendar      | On first reminder enable (Calendar backend) |
| ohos.permission.PUBLISH_AGENT_REMINDER | Prayer notifications                                  | **Commented out — pending AGC approval**    |
| ohos.permission.INTERNET               | Downloading country-specific offline mosque databases | When the mosque database is downloaded      |

The app is **offline-first**, not internet-dependent for its core Islamic features. An internet connection is used when
downloading a country-specific mosque database; the downloaded database is then available for offline mosque lookup. See
the in-app privacy policy for the app's data and network disclosures.

---

## Localization

The app is fully localized in three languages.

| Language                 | Code | RTL |
|--------------------------|------|-----|
| English                  | en   | No  |
| 中文 (Chinese, Simplified) | zh   | No  |
| العربية (Arabic)         | ar   | Yes |

Localization and language configuration are managed under `entry/src/main/ets/i18n/`.

---

## Project Structure

The following tree reflects the directory listing supplied for `entry/src/main/`, including the ArkTS source,
application resources, localization files, bundled data, databases, fonts, and media assets.

```text
entry/src/main/
├── ets/
│   ├── backup/
│   │   └── UserBackupService.ets
│   ├── bootstrap/
│   │   └── BundleBootstrap.ets
│   ├── components/
│   │   ├── CategoryHeader.ets
│   │   └── SubsectionHeader.ets
│   ├── core/
│   │   ├── app/
│   │   │   ├── AppInfoHelper.ets
│   │   │   ├── AppLogger.ets
│   │   │   └── AppRestartHelper.ets
│   │   ├── common/
│   │   │   ├── FeatureFlags.ets
│   │   │   ├── FontPaths.ets
│   │   │   ├── RawPaths.ets
│   │   │   └── StorageKeys.ets
│   │   ├── layout/
│   │   │   ├── Breakpoints.ets
│   │   │   └── LayoutHelper.ets
│   │   ├── notifications/
│   │   │   ├── NotificationHelper.ets
│   │   │   ├── NotificationModels.ets
│   │   │   └── NotificationService.ets
│   │   ├── ui/
│   │   │   ├── themes/
│   │   │   │   ├── GradeThemeHelper.ets
│   │   │   │   ├── Theme.ets
│   │   │   │   ├── ThemeModels.ets
│   │   │   │   ├── ThemeService.ets
│   │   │   │   └── TypographyHelper.ets
│   │   │   ├── MaterialHelper.ets
│   │   │   └── PageTheme.ets
│   │   └── util/
│   │       ├── ClockFormat.ets
│   │       ├── HapticHelper.ets
│   │       ├── NavHelper.ets
│   │       ├── PdfExportHelper.ets
│   │       ├── PreferencesHelper.ets
│   │       └── SystemFeedbackHelper.ets
│   ├── duas/
│   │   ├── CustomEventKeywordHelper.ets
│   │   ├── DuaCard.ets
│   │   ├── DuaIndicator.ets
│   │   ├── DuaModels.ets
│   │   └── DuaService.ets
│   ├── entryability/
│   │   └── EntryAbility.ets
│   ├── entrybackupability/
│   │   └── EntryBackupAbility.ets
│   ├── entryformability/
│   │   ├── EntryFormAbility.ets
│   │   └── SiratIntentExecutor.ets
│   ├── hadith/
│   │   ├── GradeBadge.ets
│   │   ├── HadithCoreDbHelper.ets
│   │   ├── HadithDbHelper.ets
│   │   ├── HadithModels.ets
│   │   ├── HadithSearchService.ets
│   │   └── SanadTimeline.ets
│   ├── hijricalendar/
│   │   ├── CalendarReminderHelper.ets
│   │   ├── CustomEventModels.ets
│   │   ├── CustomEventNotifier.ets
│   │   ├── CustomEventStorage.ets
│   │   ├── DateModels.ets
│   │   ├── DateUtils.ets
│   │   ├── EventPerspectiveNotifier.ets
│   │   ├── HijriCalendarEngine.ets
│   │   ├── HijriCalendarHelper.ets
│   │   ├── HijriCalendarModels.ets
│   │   ├── HijriCalendarPage.ets
│   │   ├── HijriCalendarType.ets
│   │   ├── HijriEngineResolver.ets
│   │   ├── IslamicEventService.ets
│   │   ├── TabularHijriEngine.ets
│   │   └── UmmAlQuraEngine.ets
│   ├── i18n/
│   │   ├── LanguageModels.ets
│   │   ├── LanguageService.ets
│   │   ├── LocalizationHelper.ets
│   │   └── SourceParser.ets
│   ├── legal/
│   │   └── PrivacyPolicy.ets
│   ├── location/
│   │   ├── CountryTimezoneTable.ets
│   │   ├── LocationCache.ets
│   │   ├── LocationUtils.ets
│   │   ├── OfflineCityLookup.ets
│   │   ├── TimezoneResolver.ets
│   │   └── WmmCalculator.ets
│   ├── mosques/
│   │   ├── MosqueDbHelper.ets
│   │   ├── MosqueModels.ets
│   │   ├── MosqueService.ets
│   │   └── MosqueStorage.ets
│   ├── pages/
│   │   ├── AdvancedCalcPage.ets
│   │   ├── CustomizePage.ets
│   │   ├── DuaDetailsPage.ets
│   │   ├── DuasPage.ets
│   │   ├── HadithBrowsePage.ets
│   │   ├── HadithDetailsPage.ets
│   │   ├── HadithHomePage.ets
│   │   ├── HomePage.ets
│   │   ├── LicensesPage.ets
│   │   ├── MainTabs.ets
│   │   ├── MosqueFinderPage.ets
│   │   ├── NotificationCenterPage.ets
│   │   ├── PrayerProgressPage.ets
│   │   ├── PrivacyPolicyPage.ets
│   │   ├── QuranCollectionPage.ets
│   │   ├── QuranExplorerPage.ets
│   │   ├── QuranPage.ets
│   │   ├── RamadanDetailsPage.ets
│   │   ├── RecitationsPage.ets
│   │   ├── SettingsPage.ets
│   │   ├── SurahDetailsPage.ets
│   │   ├── TasbihProgressPage.ets
│   │   └── WizardPage.ets
│   ├── prayer/
│   │   ├── AdvancedCalcModels.ets
│   │   ├── ExtraTimingToggleRow.ets
│   │   ├── HomeController.ets
│   │   ├── PageHeader.ets
│   │   ├── Prayer.ets
│   │   ├── PrayerManager.ets
│   │   ├── PrayerModel.ets
│   │   ├── PrayerOffsetsHelper.ets
│   │   ├── PrayerSunPath.ets
│   │   └── PrayerTimeCalculator.ets
│   ├── progress/
│   │   └── ProgressHelper.ets
│   ├── qibla/
│   │   ├── QiblaCalculator.ets
│   │   ├── QiblaCalibrationOverlay.ets
│   │   ├── QiblaPage.ets
│   │   └── QiblaSensorHelper.ets
│   ├── quran/
│   │   ├── QuranGraphModels.ets
│   │   ├── QuranGraphService.ets
│   │   ├── QuranService.ets
│   │   └── QuranSurahModels.ets
│   ├── ramadan/
│   │   ├── RamadanHelper.ets
│   │   ├── RamadanModels.ets
│   │   └── RamadanStorage.ets
│   ├── settings/
│   │   ├── SettingsHelper.ets
│   │   ├── SettingsModels.ets
│   │   └── SettingsRow.ets
│   ├── tasbih/
│   │   ├── SoundHelper.ets
│   │   ├── SoundOptions.ets
│   │   ├── TasbihCanvasRenderer.ets
│   │   ├── TasbihIndicator.ets
│   │   ├── TasbihManager.ets
│   │   ├── TasbihModels.ets
│   │   ├── TasbihPage.ets
│   │   ├── TasbihStorage.ets
│   │   └── TasbihThemes.ets
│   └── widgets/
│       ├── AdhkarWidget.ets
│       ├── EventWidget.ets
│       ├── HijriDateWidget.ets
│       ├── PrayerWidget.ets
│       ├── RamadanWidget.ets
│       ├── TrackerWidget.ets
│       ├── WidgetDataBuilder.ets
│       └── WidgetHelper.ets
├── resources/
│   ├── ar/
│   │   └── element/
│   │       ├── strarray.json
│   │       └── string.json
│   ├── base/
│   │   ├── element/
│   │   │   ├── color.json
│   │   │   ├── float.json
│   │   │   ├── strarray.json
│   │   │   └── string.json
│   │   ├── media/
│   │   │   ├── background.png
│   │   │   ├── foreground.png
│   │   │   ├── ic_add.svg
│   │   │   ├── ic_arrow_up.svg
│   │   │   ├── ic_ashra.svg
│   │   │   ├── ic_asr.svg
│   │   │   ├── ic_asr_rule.svg
│   │   │   ├── ic_bell.svg
│   │   │   ├── ic_book.svg
│   │   │   ├── ic_celebration.svg
│   │   │   ├── ic_chart.svg
│   │   │   ├── ic_check.svg
│   │   │   ├── ic_chevron_down.svg
│   │   │   ├── ic_chevron_left.svg
│   │   │   ├── ic_chevron_right.svg
│   │   │   ├── ic_chevron_up.svg
│   │   │   ├── ic_clock.svg
│   │   │   ├── ic_close.svg
│   │   │   ├── ic_compass.svg
│   │   │   ├── ic_custom_event.svg
│   │   │   ├── ic_daily_prayers.svg
│   │   │   ├── ic_delete.svg
│   │   │   ├── ic_dhuhr.svg
│   │   │   ├── ic_dua.svg
│   │   │   ├── ic_edit.svg
│   │   │   ├── ic_fajr.svg
│   │   │   ├── ic_fast.svg
│   │   │   ├── ic_features_bugs.svg
│   │   │   ├── ic_flat_device.svg
│   │   │   ├── ic_globe.svg
│   │   │   ├── ic_hadith_book.svg
│   │   │   ├── ic_heart.svg
│   │   │   ├── ic_hijri_type.svg
│   │   │   ├── ic_iftaar.svg
│   │   │   ├── ic_imsak.svg
│   │   │   ├── ic_info.svg
│   │   │   ├── ic_insights.svg
│   │   │   ├── ic_isha.svg
│   │   │   ├── ic_kaaba.svg
│   │   │   ├── ic_language.svg
│   │   │   ├── ic_licenses.svg
│   │   │   ├── ic_link.svg
│   │   │   ├── ic_log.svg
│   │   │   ├── ic_maghrib.svg
│   │   │   ├── ic_menu.svg
│   │   │   ├── ic_menu_customize.svg
│   │   │   ├── ic_menu_exit.svg
│   │   │   ├── ic_menu_settings.svg
│   │   │   ├── ic_midnight.svg
│   │   │   ├── ic_nav_calendar.svg
│   │   │   ├── ic_nav_home.svg
│   │   │   ├── ic_nav_mosque.svg
│   │   │   ├── ic_nav_tasbih.svg
│   │   │   ├── ic_night_first_third.svg
│   │   │   ├── ic_night_last_third.svg
│   │   │   ├── ic_palette.svg
│   │   │   ├── ic_phone.svg
│   │   │   ├── ic_pin.svg
│   │   │   ├── ic_play.svg
│   │   │   ├── ic_polar_lat.svg
│   │   │   ├── ic_prayer_sajdah.svg
│   │   │   ├── ic_printer.svg
│   │   │   ├── ic_privacy.svg
│   │   │   ├── ic_prophetic_dua.svg
│   │   │   ├── ic_quran.svg
│   │   │   ├── ic_ramadan_moon.svg
│   │   │   ├── ic_refresh.svg
│   │   │   ├── ic_sahur.svg
│   │   │   ├── ic_save.svg
│   │   │   ├── ic_settings.svg
│   │   │   ├── ic_sound.svg
│   │   │   ├── ic_star.svg
│   │   │   ├── ic_streak_fire.svg
│   │   │   ├── ic_sunrise.svg
│   │   │   ├── ic_sunset.svg
│   │   │   ├── ic_taraweeh.svg
│   │   │   ├── ic_telegram.svg
│   │   │   ├── ic_today.svg
│   │   │   ├── ic_trophy.svg
│   │   │   ├── ic_ui_appearance.svg
│   │   │   ├── ic_ui_customize.svg
│   │   │   ├── ic_warning.svg
│   │   │   ├── ic_weekly_stats.svg
│   │   │   ├── ic_worship.svg
│   │   │   ├── layered_image.json
│   │   │   ├── tab_calendar.svg
│   │   │   ├── tab_compass.svg
│   │   │   ├── tab_home.svg
│   │   │   ├── tab_prayers.svg
│   │   │   └── tab_tasbih.svg
│   │   └── profile/
│   │       ├── backup_config.json
│   │       ├── easy_go.json
│   │       ├── form_config.json
│   │       ├── intent_config.json
│   │       └── main_pages.json
│   ├── bn/
│   │   └── element/
│   │       ├── strarray.json
│   │       └── string.json
│   ├── dark/
│   │   ├── element/
│   │   │   └── color.json
│   │   └── media/
│   │       ├── background.png
│   │       ├── foreground.png
│   │       └── layered_image.json
│   ├── id/
│   │   └── element/
│   │       ├── strarray.json
│   │       └── string.json
│   ├── phone-ldpi/
│   │   └── media/
│   │       ├── icon.png
│   │       ├── icon_startwindow.png
│   │       ├── spash_dark.png
│   │       ├── spash_dark_startwindow.png
│   │       ├── splash_light.png
│   │       └── splash_light_startwindow.png
│   ├── phone-mdpi/
│   │   └── media/
│   │       ├── icon.png
│   │       ├── icon_startwindow.png
│   │       ├── spash_dark.png
│   │       ├── spash_dark_startwindow.png
│   │       ├── splash_light.png
│   │       └── splash_light_startwindow.png
│   ├── phone-sdpi/
│   │   └── media/
│   │       ├── icon.png
│   │       ├── icon_startwindow.png
│   │       ├── spash_dark.png
│   │       ├── spash_dark_startwindow.png
│   │       ├── splash_light.png
│   │       └── splash_light_startwindow.png
│   ├── phone-xldpi/
│   │   └── media/
│   │       ├── icon.png
│   │       ├── icon_startwindow.png
│   │       ├── spash_dark.png
│   │       ├── spash_dark_startwindow.png
│   │       ├── splash_light.png
│   │       └── splash_light_startwindow.png
│   ├── phone-xxldpi/
│   │   └── media/
│   │       ├── icon.png
│   │       ├── icon_startwindow.png
│   │       ├── spash_dark.png
│   │       ├── spash_dark_startwindow.png
│   │       ├── splash_light.png
│   │       └── splash_light_startwindow.png
│   ├── phone-xxxldpi/
│   │   └── media/
│   │       ├── icon.png
│   │       ├── icon_startwindow.png
│   │       ├── spash_dark.png
│   │       ├── spash_dark_startwindow.png
│   │       ├── splash_light.png
│   │       └── splash_light_startwindow.png
│   ├── rawfile/
│   │   ├── app/
│   │   │   ├── languages/
│   │   │   │   └── app_languages.json
│   │   │   ├── lookup/
│   │   │   │   └── catalog.json
│   │   │   ├── manifest/
│   │   │   │   ├── bundle_manifest.json
│   │   │   │   └── featured.json
│   │   │   ├── routing/
│   │   │   │   └── query_router.json
│   │   │   └── themes/
│   │   │       └── app_themes.json
│   │   ├── assets/
│   │   │   ├── fonts/
│   │   │   │   ├── arabic/
│   │   │   │   │   ├── Amiri-Bold.ttf
│   │   │   │   │   ├── Amiri-Regular.ttf
│   │   │   │   │   ├── AmiriQuran-Regular.ttf
│   │   │   │   │   ├── HafsArabic-Regular.ttf
│   │   │   │   │   ├── KFGQPC-Regular.ttf
│   │   │   │   │   ├── LPMQ-Regular.ttf
│   │   │   │   │   ├── NotoNaskhArabic-Regular.ttf
│   │   │   │   │   ├── QPC-Hafs.ttf
│   │   │   │   │   └── ScheherazadeNew-Regular.ttf
│   │   │   │   ├── bengali/
│   │   │   │   │   └── NotoSansBengali-Regular.ttf
│   │   │   │   ├── chinese/
│   │   │   │   │   └── NotoSansSC-Regular.ttf
│   │   │   │   ├── latin/
│   │   │   │   │   ├── Outfit-Bold.ttf
│   │   │   │   │   └── Outfit-Regular.ttf
│   │   │   │   └── urdu/
│   │   │   │       ├── JameelNooriNastaleeq.ttf
│   │   │   │       └── NotoNastaliqUrdu-Regular.ttf
│   │   │   └── sounds/
│   │   │       └── tasbih/
│   │   │           ├── tasbih_glass_tap.ogg
│   │   │           ├── tasbih_light_chime.ogg
│   │   │           ├── tasbih_muted_bead.ogg
│   │   │           ├── tasbih_soft_click.ogg
│   │   │           └── tasbih_warm_knock.ogg
│   │   ├── core/
│   │   │   ├── core.db
│   │   │   ├── core.db.gz
│   │   │   └── VERSION
│   │   ├── duas/
│   │   │   ├── catalog/
│   │   │   │   ├── categories.json
│   │   │   │   └── dua_keyword_map.json
│   │   │   └── content/
│   │   │       ├── duas_ar.json
│   │   │       ├── duas_base.json
│   │   │       ├── duas_bn.json
│   │   │       ├── duas_en.json
│   │   │       ├── duas_id.json
│   │   │       ├── duas_tr.json
│   │   │       ├── duas_ur.json
│   │   │       └── duas_zh.json
│   │   ├── events/
│   │   │   └── islamic_events.json
│   │   ├── hadith/
│   │   │   ├── contexts/
│   │   │   │   ├── aqiqah.json
│   │   │   │   ├── before_salah.json
│   │   │   │   ├── business_decision.json
│   │   │   │   ├── career_growth.json
│   │   │   │   ├── character_building.json
│   │   │   │   ├── charity.json
│   │   │   │   ├── community_service.json
│   │   │   │   ├── daily_life.json
│   │   │   │   ├── daily_prayer.json
│   │   │   │   ├── death_in_family.json
│   │   │   │   ├── dhikr.json
│   │   │   │   ├── eid_al_adha.json
│   │   │   │   ├── eid_al_fitr.json
│   │   │   │   ├── end_times.json
│   │   │   │   ├── family_conflict.json
│   │   │   │   ├── family_time.json
│   │   │   │   ├── financial_decisions.json
│   │   │   │   ├── financial_stress.json
│   │   │   │   ├── friday.json
│   │   │   │   ├── governance.json
│   │   │   │   ├── grief.json
│   │   │   │   ├── hajj.json
│   │   │   │   ├── illness.json
│   │   │   │   ├── islamic_law.json
│   │   │   │   ├── itikaf.json
│   │   │   │   ├── jamaah.json
│   │   │   │   ├── justice.json
│   │   │   │   ├── last_ten_nights.json
│   │   │   │   ├── laylat_al_qadr.json
│   │   │   │   ├── leadership.json
│   │   │   │   ├── learning.json
│   │   │   │   ├── marriage.json
│   │   │   │   ├── nikah.json
│   │   │   │   ├── parenting.json
│   │   │   │   ├── pledges.json
│   │   │   │   ├── prayer.json
│   │   │   │   ├── quran.json
│   │   │   │   ├── raising_children.json
│   │   │   │   ├── ramadan.json
│   │   │   │   ├── relationships.json
│   │   │   │   ├── repentance.json
│   │   │   │   ├── seeking_knowledge.json
│   │   │   │   ├── self_improvement.json
│   │   │   │   ├── social_etiquette.json
│   │   │   │   ├── social_interactions.json
│   │   │   │   ├── spiritual_growth.json
│   │   │   │   ├── tahajjud.json
│   │   │   │   ├── taraweeh.json
│   │   │   │   ├── tawbah.json
│   │   │   │   ├── times_of_trials.json
│   │   │   │   ├── travel.json
│   │   │   │   ├── witr.json
│   │   │   │   └── work.json
│   │   │   ├── database/
│   │   │   │   ├── ar/
│   │   │   │   │   └── hadith.db.gz
│   │   │   │   ├── bn/
│   │   │   │   │   └── hadith.db.gz
│   │   │   │   ├── en/
│   │   │   │   │   └── hadith.db.gz
│   │   │   │   ├── id/
│   │   │   │   │   └── hadith.db.gz
│   │   │   │   ├── tr/
│   │   │   │   │   └── hadith.db.gz
│   │   │   │   ├── ur/
│   │   │   │   │   └── hadith.db.gz
│   │   │   │   └── VERSION
│   │   │   └── topics/
│   │   │       ├── agriculture.json
│   │   │       ├── akhirah.json
│   │   │       ├── appearance.json
│   │   │       ├── aqidah.json
│   │   │       ├── business.json
│   │   │       ├── character.json
│   │   │       ├── charity.json
│   │   │       ├── children.json
│   │   │       ├── companions.json
│   │   │       ├── creation.json
│   │   │       ├── daily_life.json
│   │   │       ├── death.json
│   │   │       ├── divorce.json
│   │   │       ├── dreams.json
│   │   │       ├── drinks.json
│   │   │       ├── dua.json
│   │   │       ├── eclipse_prayer.json
│   │   │       ├── eid.json
│   │   │       ├── ethics.json
│   │   │       ├── etiquette.json
│   │   │       ├── family_law.json
│   │   │       ├── fasting.json
│   │   │       ├── finance.json
│   │   │       ├── fiqh.json
│   │   │       ├── fitan.json
│   │   │       ├── gift_giving.json
│   │   │       ├── governance.json
│   │   │       ├── hadith_qudsi.json
│   │   │       ├── hajj.json
│   │   │       ├── halal_food.json
│   │   │       ├── health.json
│   │   │       ├── hunting.json
│   │   │       ├── iman.json
│   │   │       ├── inheritance.json
│   │   │       ├── istisqa.json
│   │   │       ├── jihad.json
│   │   │       ├── justice.json
│   │   │       ├── kaffarah.json
│   │   │       ├── kindness.json
│   │   │       ├── knowledge.json
│   │   │       ├── li_an.json
│   │   │       ├── literature.json
│   │   │       ├── marriage.json
│   │   │       ├── mosque.json
│   │   │       ├── oaths_vows.json
│   │   │       ├── parents.json
│   │   │       ├── property_law.json
│   │   │       ├── prophets.json
│   │   │       ├── protection.json
│   │   │       ├── purification.json
│   │   │       ├── qadr.json
│   │   │       ├── qiblah.json
│   │   │       ├── quran.json
│   │   │       ├── qurbani.json
│   │   │       ├── ramadan.json
│   │   │       ├── reconciliation.json
│   │   │       ├── revelation.json
│   │   │       ├── salah.json
│   │   │       ├── seerah.json
│   │   │       ├── social_justice.json
│   │   │       ├── sports.json
│   │   │       ├── sunnah.json
│   │   │       ├── tawbah.json
│   │   │       ├── tawhid.json
│   │   │       ├── trade.json
│   │   │       ├── travel.json
│   │   │       ├── virtues.json
│   │   │       ├── wills.json
│   │   │       ├── women.json
│   │   │       ├── wudu.json
│   │   │       ├── zakat.json
│   │   │       └── zuhd.json
│   │   ├── i18n/
│   │   │   ├── ar.json
│   │   │   ├── bn.json
│   │   │   ├── en.json
│   │   │   ├── id.json
│   │   │   ├── tr.json
│   │   │   ├── ur.json
│   │   │   └── zh.json
│   │   ├── legal/
│   │   │   ├── licenses/
│   │   │   │   ├── hadith_licenses.json
│   │   │   │   └── quran_licenses.json
│   │   │   └── privacy/
│   │   │       ├── privacy_ar.json
│   │   │       ├── privacy_bn.json
│   │   │       ├── privacy_en.json
│   │   │       ├── privacy_id.json
│   │   │       ├── privacy_tr.json
│   │   │       ├── privacy_ur.json
│   │   │       └── privacy_zh.json
│   │   ├── locations/
│   │   │   ├── city_translations.json
│   │   │   └── offline-cities.json
│   │   ├── metadata/
│   │   │   ├── ar_sections.json
│   │   │   ├── bn_sections.json
│   │   │   ├── en_sections.json
│   │   │   ├── id_sections.json
│   │   │   ├── master_sections.json
│   │   │   ├── section_aliases_v2.json
│   │   │   ├── tr_sections.json
│   │   │   └── ur_sections.json
│   │   └── quran/
│   │       ├── i18n/
│   │       │   ├── quran_graph_ar.json
│   │       │   ├── quran_graph_bn.json
│   │       │   ├── quran_graph_en.json
│   │       │   ├── quran_graph_id.json
│   │       │   ├── quran_graph_tr.json
│   │       │   ├── quran_graph_ur.json
│   │       │   └── quran_graph_zh.json
│   │       ├── manifest.json
│   │       ├── quran.db
│   │       ├── quran.db.gz
│   │       ├── quranic_collection_graph.json
│   │       ├── quranic_collection_index.json
│   │       ├── quranic_duas_catalog.json
│   │       ├── quranic_entity_graph.json
│   │       ├── quranic_prophet_graph.json
│   │       ├── quranic_reverse_index.json
│   │       ├── recitations_ar.json
│   │       ├── recitations_bn.json
│   │       ├── recitations_en.json
│   │       ├── recitations_id.json
│   │       ├── recitations_raw.json
│   │       ├── recitations_tr.json
│   │       ├── recitations_ur.json
│   │       ├── recitations_zh.json
│   │       └── VERSION
│   ├── tr/
│   │   └── element/
│   │       ├── strarray.json
│   │       └── string.json
│   ├── ur/
│   │   └── element/
│   │       ├── strarray.json
│   │       └── string.json
│   └── zh/
│       └── element/
│           ├── strarray.json
│           └── string.json
└── module.json5
```

### Layering

The codebase separates presentation, application services, and core functionality:

- **Pages and components** render screens and reusable UI.
- **Feature services and helpers** coordinate domain operations such as prayer calculations, content access,
  notifications, and persistence.
- **Core utilities** provide shared platform integrations, storage, localization, layout, and theme infrastructure.

> **Rule of thumb:** keep feature and platform logic out of page rendering code; route shared operations through the
> appropriate service or helper.

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

| Version   | Highlights                                                                                  |
|-----------|---------------------------------------------------------------------------------------------|
| **4.1.5** | Theme selector fix, Prayer UI refinements, non-dismissable Prayer and Ramadan notifications |
| 4.1.4     | JSON-driven themes and language configuration, redesigned Home page, activity notifications |
| 4.1.3     | Quranic Duas, font settings, Hadith grading and authenticity-link improvements              |
| 4.1.2     | Quran.com content source, WMM and prayer calculation fixes                                  |
| 4.1.1     | WMM and prayer calculation fixes                                                            |
| 4.1.0     | Canonical Islamic data platform, independent translations, multilingual Hadith              |
| 4.0.8     | Maintenance and stability improvements                                                      |
| 4.0.7     | GZip database compression, prayer timestamp and backup fixes                                |
| 4.0.6     | Offline Hadith engine and widget upgrades                                                   |
| 4.0.4     | Offline Mosque Finder and expanded widget ecosystem                                         |
| 4.0.0     | Quran reader and global timezone engine                                                     |
| 3.8.x     | Widget ecosystem, AI intents, domain reorganization and navigation improvements             |
| 3.4.3     | Diyanet temkin offsets, Jafari Maghrib, AppGallery 2-in-1 exit fix                          |
| 3.3.x     | Prayer and Tasbih detail pages, daily Tasbih mechanics and progress views                   |
| 3.2.x     | Hijri engines, 24-method prayer calculations, backup and restore                            |
| 3.0.x     | Adaptive layouts, localization, event tradition filter and settings propagation             |
| 2.x       | Home dashboard, Ramadan card, themes, Tasbih sounds and widget foundations                  |

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
- [x] Home-screen widget ecosystem
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