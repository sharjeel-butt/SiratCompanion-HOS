// entry/src/main/ets/data/PrivacyPolicy.ets

/**
 * In-app privacy policy text, in all three supported languages.
 *
 * This file is the source of truth for the policy shown on the
 * Wizard's Privacy step and from Settings → About → Privacy Policy.
 * The hosted version at PrivacyPolicyProvider.FULL_URL carries
 * identical content, so the two stay in sync — update both when
 * the policy changes.
 *
 * Last updated: 2026-10-16
 * Applies to: Sirat Companion 3.3.3 and later
 */
export class PrivacyPolicyProvider {
  static readonly FULL_URL: string =
    'https://sharjeel-butt.github.io/SiratCompanion-HOS/';
  /** Update this date to today */
  static readonly LAST_UPDATED: string = 'October 26, 2026';
  /** Update this to the new version */
  static readonly APPLIES_TO: string = '3.5.0 and later';

  /** Returns the policy text for the given language code. */
  static get(lang: string): string {
    if (lang === 'zh') {
      return PrivacyPolicyProvider.ZH;
    }
    if (lang === 'ar') {
      return PrivacyPolicyProvider.AR;
    }
    return PrivacyPolicyProvider.EN;
  }

  // ============================================================
  // ENGLISH
  // ============================================================

  private static readonly EN: string = `Privacy Policy — Sirat Companion

Last updated: October 26, 2026
Effective date: October 26, 2026
Applies to: Sirat Companion version 3.3.3 and later

INTRODUCTION

Sirat Companion ("the App", "we", "us", or "our") is an Islamic companion application for HarmonyOS, developed by Sharjeel Idris ("the Developer"). This Privacy Policy explains what information the App accesses, how that information is used, and your rights regarding that information.

We have designed Sirat Companion to work entirely on your device. The App does not require an account, does not connect to any server we operate, and does not transmit your personal data to us or to any third party.

By installing and using the App, you agree to the practices described in this Privacy Policy.

INFORMATION WE ACCESS AND USE

Sirat Companion accesses the following information solely on your device to provide its features. None of this information is transmitted to us, to Huawei, or to any third party by the App.

Location Information
- What we access: Your device's GPS coordinates (latitude and longitude), and — when you choose Manual Location — the coordinates you type in.
- Why we access it: Location is required to calculate accurate prayer times and the Qibla direction for your city.
- How it is stored: The last successful location (coordinates and city name) is cached on your device so the App can load quickly. You can clear this at any time by switching to Manual Location or by uninstalling the App.
- Transmission: The App does not send your location to any server. If reverse geocoding is enabled (to convert coordinates into a city name), the request is handled by your device's operating system geocoder — that is, by HarmonyOS, not by us, and is subject to Huawei's own privacy policy.

Sensor Information
- What we access: The device's orientation sensor and magnetometer.
- Why we access it: Required for the Qibla compass to determine which direction is true north and where the Kaaba is relative to your device.
- Transmission: Sensor readings are processed entirely on your device and are never stored or transmitted.

Prayer Completion History
- What we access: The prayers you mark as prayed each day (Fajr, Dhuhr, Asr, Maghrib, Isha), stored per calendar date.
- Why we access it: To power the Home dashboard and the Prayer Details page — today's progress, streaks, weekly and monthly summaries, and lifetime statistics — and to skip creating reminders for prayers you have already performed.
- How it is stored: Stored locally on your device using the HarmonyOS Preferences API. It never leaves your device unless you have enabled system backup, in which case it participates in the backup described in the "Backup and Restore" section below.

Prayer Times and Settings
- What we access: Your calculation preferences (convention, Asr rule, prayer offsets, high-latitude rule, rounding, midnight method, polar resolution, Shafaq), app theme, dark mode, language preference, time format, Hijri date offset, Hijri calendar type, location mode, manual coordinates, event tradition preference, per-timing visibility toggles, vibration preference, Tasbih theme preferences, Tasbih sound preference, and notification preferences.
- Why we access it: To remember your choices across app restarts.
- How it is stored: All preferences are stored locally on your device using the HarmonyOS Preferences API. They never leave your device unless you have enabled system backup.

Tasbih Data
- What we access: The Tasbih sessions you create, the dhikr items within them, your current counts, your daily totals, a rolling 90-day history of daily counts per dhikr, and the theme chosen for each Tasbih.
- Why we access it: To display and persist your Tasbih progress on the Tasbih tab and on the Tasbih Details page, which shows weekly, monthly, and yearly views per tasbih and per dhikr.
- How it is stored: Tasbih data is stored locally on your device using the HarmonyOS Preferences API. Daily counts are automatically rolled into history each night; days beyond the most recent 90 are dropped from the rolling window. Nothing is transmitted unless you have enabled system backup.

System Feedback State
- What we access: The device's current ringer mode (ring / vibrate / silent) and the system haptics toggle.
- Why we access it: So that the App's own sound and vibration respect your system-level settings. When the phone is on silent, the App stays silent. When system haptics are off, the App does not attempt to vibrate.
- How it is stored: These values are read from the operating system on demand and immediately discarded. They are never stored and never transmitted. No personal data is involved.

Haptic Feedback (Vibration)
- What we access: The device's vibration capability.
- Why we access it: To provide a short vibration each time you count a Tasbih bead, confirming your tap. This can be turned off at any time from the App's Settings → UI Customization → Vibration.
- Transmission: Vibration is controlled entirely on your device. No data is generated, stored, or transmitted.

Sound
- What we access: The device's audio playback capability.
- Why we access it: To play a short click when you count a Tasbih bead, if you have enabled it. This can be turned off at any time from the App's Settings → UI Customization → Sound. The App also respects your system ringer mode — if the phone is on silent, the App stays silent regardless of the in-app setting.
- Transmission: All click sounds are bundled with the App and played locally. No audio is recorded, no audio is streamed, and no data is transmitted.

Calendar (Prayer Reminders)
- What we access: A dedicated calendar account named "Sirat Companion" in your device's system calendar. When you enable prayer reminders in Settings → Notifications, the App writes one calendar event per pending prayer for the next three days. Each event carries a system reminder set to fire at the prayer time and, optionally, at your configured lead time. The event description carries a short Hadith associated with that prayer, along with its source citation.
- Why we access it: To deliver prayer-time reminders through the system calendar, which fires reliably even when the App is not running.
- How it is stored: The events are stored by the system Calendar app under the App's own calendar account. The App reads events only from its own account, and only to remove stale events before rescheduling. No other calendar data is read, and no calendar data is transmitted anywhere.
- Prayers already performed: When you mark a prayer as prayed for a given date, the App removes that prayer's reminder for that date on the next reschedule. Marking the last prayer of the day triggers an immediate reschedule so the next day's reminders are queued before you leave the App.
- Removal: You can remove all of these events at any time by turning off the master reminder toggle in Settings → Notifications, or by deleting the "Sirat Companion" calendar account from the system Calendar app.

Notification Features (Not Currently Active)
The App includes a native notification backend for prayer reminders. This backend is currently disabled while the Agent-Powered Reminder capability is pending approval by AppGallery Connect. While disabled:
- The App does not request the PUBLISH_AGENT_REMINDER permission.
- The App does not publish any notifications.
- No notification-related data is created, stored, or transmitted.

Diagnostic Log
- What we access: A plain-text log file written by the app's own code, recording lifecycle events, errors, and warnings generated locally.
- Why we access it: To help diagnose issues reported by users. You can inspect, copy, or clear this file at any time from Settings → Diagnostic Logs.
- How it is stored: Stored locally on your device, inside the app's private sandbox. It is never transmitted to us or to any third party.
- Backup: The log is explicitly excluded from the system backup, so it regenerates fresh on each install and cannot be recovered from a previous device.

The active reminder mechanism is the Calendar backend described above. When the Agent-Powered Reminder capability is approved, this Privacy Policy will be updated to disclose the notification backend, and the PUBLISH_AGENT_REMINDER permission will be requested at that time.

BACKUP AND RESTORE

Sirat Companion supports HarmonyOS's system-level backup framework. When backup is enabled on your device, the App's locally stored data is included in the system backup so it can be restored if you migrate to a new device or reinstall the App.

- What is included: All App settings and preferences (language, theme, prayer calculation settings, location mode and manual coordinates, Hijri offset and calendar type, notification settings, sound and vibration preferences, time format, event tradition, per-timing visibility toggles), all Tasbih data (custom tasbihs, dhikr items, current counts, daily totals, rolling 90-day history, lifetime totals), and the cached GPS location.
- What is excluded: The diagnostic log file is deliberately excluded from backup so it regenerates fresh on each install.
- How it works: The backup is performed entirely by HarmonyOS. It is not transmitted to us, and we do not operate the backup service. Whether a backup is created, where it is stored, and whether it is restored are controlled by your device's system settings and your Huawei account. Please refer to Huawei's privacy policy for details.
- Your control: You can disable backup for this app from your device's system Settings, and you can delete any existing backup through the same settings.

WHAT WE DO NOT COLLECT

Sirat Companion does not collect, store, or transmit:
- Your name, email address, phone number, or any account information
- Device identifiers (IMEI, MAC address, Advertising ID, or similar)
- Analytics or usage statistics
- App run logs transmitted off-device — a diagnostic log is written locally in the app's private sandbox for troubleshooting, but it is never transmitted to us or any third party and is excluded from system backup
- Browsing history, contacts, photos, or files
- Financial or payment information
- Advertising identifiers

We do not use any third-party analytics SDKs, advertising SDKs, or tracking libraries.

HOW WE USE THE INFORMATION

All information accessed by the App is used only on your device and only to provide the App's features:

- Location — Calculate prayer times and Qibla direction
- Sensors — Determine device orientation for the compass
- Prayer history — Track daily prayers, streaks, progress; skip reminders for prayers already performed
- Preferences — Remember your settings
- Tasbih data — Persist your dhikr progress, daily totals, and history
- System feedback — Respect system sound and haptics settings
- Vibration — Provide haptic feedback while counting Tasbih
- Sound — Play a click when counting Tasbih
- Calendar — Add prayer-time reminders to a dedicated calendar account

We do not use your information for advertising, profiling, or any purpose unrelated to the App's core functionality.

SHARING OF INFORMATION

We do not share your information with anyone, because we never receive it in the first place.

The App does interact with the following components of the HarmonyOS operating system, which operate under Huawei's own privacy policy:
- System geocoder — for reverse geocoding your coordinates into a city name (only when you choose to view a city name).
- Location services — to obtain your GPS coordinates when you grant permission.
- Audio service — to read the system ringer mode and play local sounds.
- Vibration service — to produce tactile feedback when counting Tasbih.
- Calendar service — to write prayer reminder events into the App's own calendar account.
- System backup service — to include the App's local data in your device's system backup, if you have enabled it.

Please refer to Huawei's privacy policy for details on how the operating system handles these services.

DATA STORAGE AND RETENTION

All App data is stored locally on your device and is retained until you:
- Clear it from within the App (e.g. by resetting Tasbih counts, unchecking individual prayers, or switching to a different location)
- Uninstall the App

If system backup is enabled, a copy of the App's data may also be retained in your system backup until you delete it through the system settings or uninstall the App on all devices associated with your account.

Calendar events created for prayer reminders are stored by the system Calendar app and can be deleted at any time by turning off the reminder master toggle, by deleting the "Sirat Companion" calendar account, or by uninstalling the App. Uninstalling Sirat Companion permanently removes all data the App has stored on your device.

PERMISSIONS REQUESTED

The App requests the following HarmonyOS permissions. You can deny any permission without losing access to the rest of the App's features.

- ohos.permission.VIBRATE — Haptic feedback while counting Tasbih
- ohos.permission.APPROXIMATELY_LOCATION — Approximate location for prayer times
- ohos.permission.LOCATION — Precise location for prayer times
- ohos.permission.ACCELEROMETER — Compass and Qibla direction
- ohos.permission.READ_CALENDAR — Read the App's own calendar events to remove stale reminders before rescheduling
- ohos.permission.WRITE_CALENDAR — Create prayer reminder events in the App's dedicated calendar account

Permissions are requested only when you first use a feature that requires them. They can be revoked at any time in your device's Settings.

The PUBLISH_AGENT_REMINDER permission is not currently requested. See the "Notification Features" section above for details.

Vibration — Detailed Explanation
The VIBRATE permission allows the App to produce a short vibration each time you tap to count a Tasbih bead, confirming your tap. It is used only for this local haptic feedback and can be disabled at any time from the App's Settings → UI Customization → Vibration. No data is generated, stored, or transmitted by this permission.

Calendar — Detailed Explanation
The READ_CALENDAR and WRITE_CALENDAR permissions allow the App to create a dedicated "Sirat Companion" calendar account and to write prayer reminder events into it. The App only reads events from its own account, and only to remove stale ones before writing new ones. The App does not read any other calendar on your device. No calendar data is transmitted off your device. You can disable the feature at any time from Settings → Notifications, which removes all events the App has created.

SECURITY

Because Sirat Companion does not transmit any personal data off your device, there is no server-side risk of data exposure. Your local data is protected by the HarmonyOS app sandbox, which prevents other apps from reading Sirat Companion's stored preferences. When system backup is enabled, its security is governed by HarmonyOS and your Huawei account settings.

CHILDREN'S PRIVACY

Sirat Companion is intended for general audiences and is suitable for users of all ages. The App does not knowingly collect any personal information from anyone, including children, because it does not collect personal information at all.

YOUR RIGHTS

Because the App does not collect or transmit your data, there is no data for us to disclose, correct, or delete on our side. You have full control over your data at all times:
- Access: All data is visible within the App.
- Deletion: Uninstalling the App removes all stored data. Prayer completion history can also be cleared by unchecking individual prayers. Calendar reminder events can be removed by turning off the reminder master toggle. Backup copies can be deleted through the system backup settings.
- Portability: Data can be viewed and re-entered at any time.
- Withdrawal of consent: Revoke permissions in your device Settings.

THIRD-PARTY SERVICES

Sirat Companion does not integrate any third-party analytics, advertising, or tracking services.

CHANGES TO THIS PRIVACY POLICY

We may update this Privacy Policy from time to time to reflect changes in the App or applicable law. When we make material changes, we will update the "Last updated" date at the top of this page. Continued use of the App after changes take effect constitutes acceptance of the revised policy.

CONTACT US

If you have questions, concerns, or requests regarding this Privacy Policy, please contact us at:

Email: sharjeel.butt@gmail.com
Developer: Sharjeel Idris`;

  // ============================================================
  // 中文
  // ============================================================

  private static readonly ZH: string = `隐私政策 — Sirat 伴侣

最后更新：2026 年 10 月 26 日
生效日期：2026 年 10 月 26 日
适用于：Sirat 伴侣 3.3.3 及更高版本

引言

Sirat 伴侣（以下简称"本应用"、"我们"）是由 Sharjeel Idris 开发的 HarmonyOS 伊斯兰伴侣应用。本隐私政策说明了本应用访问哪些信息、如何使用这些信息，以及您对这些信息享有的权利。

我们设计的 Sirat 伴侣完全在您的设备上运行。本应用无需创建账户，不连接我们运营的任何服务器，也不会将您的个人数据传输给我们或任何第三方。

安装并使用本应用即表示您同意本隐私政策中所述的做法。

我们访问和使用的信息

Sirat 伴侣仅在您的设备上访问以下信息，用于提供其功能。本应用不会将这些信息传输给我们、华为或任何第三方。

位置信息
- 我们访问的内容：您设备的 GPS 坐标（纬度和经度），以及您在选择手动位置时输入的坐标。
- 我们为何访问：位置用于为您所在城市准确计算礼拜时间和天房方向。
- 存储方式：最近一次成功获取的位置（坐标和城市名称）会缓存在您的设备上，以便应用快速加载。您可以随时通过切换到手动位置或卸载应用来清除。
- 传输：本应用不会将您的位置发送到任何服务器。如果启用反向地理编码（将坐标转换为城市名称），该请求由您设备操作系统的地理编码器处理——即由 HarmonyOS 处理，而非我们，并受华为自身隐私政策的约束。

传感器信息
- 我们访问的内容：设备的方向传感器和磁力计。
- 我们为何访问：天房指南针需要这些信息来确定真北方向以及麦加相对于您设备的位置。
- 传输：传感器读数完全在您的设备上处理，绝不存储或传输。

礼拜完成记录
- 我们访问的内容：您每天标记为已礼的礼拜（晨礼、晌礼、晡礼、昏礼、宵礼），按日历日期存储。
- 我们为何访问：用于驱动首页和"礼拜详情"页面——今日进度、连续天数、每周和每月摘要以及累计统计，并用于跳过为已完成礼拜创建的提醒。
- 存储方式：通过 HarmonyOS Preferences API 存储在您的设备本地。除非您已启用系统备份，否则它不会离开您的设备；若启用，它将参与下文"备份与恢复"一节所述的备份。

礼拜时间与设置
- 我们访问的内容：您的计算偏好（计算方式、晡礼规则、礼拜时间偏移、高纬度规则、舍入方式、午夜方式、极地处理、霞光）、应用主题、深色模式、语言偏好、时间格式、回历日期偏移、回历类型、位置模式、手动坐标、节日传统偏好、各时段可见性开关、振动偏好、念珠主题偏好、念珠音效偏好以及通知偏好。
- 我们为何访问：用于在应用重启后记住您的选择。
- 存储方式：所有偏好设置均通过 HarmonyOS Preferences API 存储在您的设备本地。除非您已启用系统备份，否则它们不会离开您的设备。

念珠数据
- 我们访问的内容：您创建的念珠、其中的念词项目、当前计数、每日总计、每个念词的滚动 90 天历史记录，以及每串念珠所选择的主题。
- 我们为何访问：用于在念珠页面和"念珠详情"页面上显示和保存您的念珠进度；详情页面按念珠和按念词显示周、月、年视图。
- 存储方式：念珠数据通过 HarmonyOS Preferences API 存储在您的设备本地。每日计数每晚自动归档入历史记录；超过最近 90 天的日期将从滚动窗口中丢弃。除非您已启用系统备份，否则不会传输任何内容。

系统反馈状态
- 我们访问的内容：设备当前的铃声模式（响铃 / 振动 / 静音）和系统触感反馈开关。
- 我们为何访问：使本应用自身的声音和振动遵循您的系统级设置。当手机处于静音时，应用保持静音；当系统触感反馈关闭时，应用不会尝试振动。
- 存储方式：这些值按需从操作系统读取并立即丢弃。它们从不存储，也从不传输。不涉及任何个人数据。

触觉反馈（振动）
- 我们访问的内容：设备的振动功能。
- 我们为何访问：用于在您每次点击念珠计数时提供一次短振动，以确认您的操作。您可以随时在应用的 设置 → 界面自定义 → 振动 中关闭此功能。
- 传输：振动完全在您的设备上控制。不会产生、存储或传输任何数据。

声音
- 我们访问的内容：设备的音频播放功能。
- 我们为何访问：在您启用时，播放念珠计数的短提示音。您可以随时在应用的 设置 → 界面自定义 → 声音 中关闭。本应用也会遵循您的系统铃声模式——当手机处于静音时，无论应用内设置如何，应用都会保持静音。
- 传输：所有提示音均随应用打包并在本地播放。不录制音频，不传输音频流，也不传输任何数据。

日历（礼拜提醒）
- 我们访问的内容：您设备系统日历中一个名为"Sirat 伴侣"的专用日历账户。当您在 设置 → 通知 中启用礼拜提醒后，本应用会为未来三天内每个尚未完成的礼拜写入一个日历事件。每个事件都带有一个系统提醒，设置在礼拜时间触发，以及（可选）在您配置的提前时间触发。事件描述中附带与该礼拜相关的简短圣训及其出处。
- 我们为何访问：通过系统日历传递礼拜提醒，即使本应用未运行也能可靠触发。
- 存储方式：这些事件由系统日历应用保存在本应用自己的日历账户中。本应用仅从自己的账户读取事件，且仅用于在重新排程前清除过期事件。不会读取其他日历数据，也不会向任何地方传输日历数据。
- 已完成的礼拜：当您将某一天的某个礼拜标记为已礼后，本应用会在下次重新排程时移除该日期该礼拜的提醒。将当天最后一个礼拜标记为已礼会立即触发重新排程，从而在您离开应用前为第二天排好提醒。
- 删除：您可以随时在 设置 → 通知 中关闭提醒总开关，或在系统日历应用中删除"Sirat 伴侣"日历账户，从而移除所有相关事件。

通知功能（当前未启用）
本应用包含用于礼拜提醒的原生通知后端。该后端目前处于停用状态，因为 Agent-Powered Reminder 能力正在等待 AppGallery Connect 审批。停用期间：
- 本应用不会请求 PUBLISH_AGENT_REMINDER 权限。
- 本应用不会发布任何通知。
- 不会创建、存储或传输任何与通知相关的数据。

当前生效的提醒机制为上述日历后端。待 Agent-Powered Reminder 能力获批后，本隐私政策将更新以披露通知后端，届时将请求 PUBLISH_AGENT_REMINDER 权限。

诊断日志
- 我们访问的内容：应用自身代码写入的纯文本日志文件，记录本地生成的生命周期事件、错误和警告。
- 我们为何访问：用于诊断用户报告的问题。您可以随时从 设置 → 诊断日志 查看、复制或清除此文件。
- 存储方式：存储在您设备上应用的私有沙箱中。绝不传输给我们或任何第三方。
- 备份：日志被明确排除在系统备份之外，因此每次安装都会重新生成，且无法从之前的设备恢复。

备份与恢复

Sirat 伴侣支持 HarmonyOS 的系统级备份框架。当您设备上启用了备份时，本应用的本地存储数据将包含在系统备份中，以便您在迁移到新设备或重新安装应用时恢复。

- 包含的内容：所有应用设置和偏好（语言、主题、礼拜时间计算设置、位置模式和手动坐标、回历偏移与回历类型、通知设置、声音与振动偏好、时间格式、节日传统、各时段可见性开关）、所有念珠数据（自定义念珠、念词项目、当前计数、每日总计、滚动 90 天历史记录、累计总数）以及缓存的 GPS 位置。
- 排除的内容：诊断日志文件被有意排除在备份之外，以便在每次安装时重新生成。
- 工作方式：备份完全由 HarmonyOS 执行。它不会传输给我们，我们也不运营备份服务。是否创建备份、备份存储在哪里、是否恢复，均由您设备的系统设置和您的华为账户控制。详情请参阅华为隐私政策。
- 您的控制：您可以在设备的系统设置中为本应用禁用备份，也可通过同一设置删除任何现有备份。

我们不收集的内容

Sirat 伴侣不收集、存储或传输：
- 您的姓名、电子邮件地址、电话号码或任何账户信息
- 设备标识符（IMEI、MAC 地址、广告 ID 或类似信息）
- 分析或使用统计
- 传输到设备外的应用日志 —— 应用在本地私有沙箱中写入诊断日志用于排查问题，但绝不在设备外传输，且不包含在系统备份中
- 浏览历史、联系人、照片或文件
- 财务或支付信息
- 广告标识符

我们不使用任何第三方分析 SDK、广告 SDK 或追踪库。

我们如何使用信息

本应用访问的所有信息仅在您的设备上使用，且仅用于提供本应用的功能：

- 位置 —— 计算礼拜时间和天房方向
- 传感器 —— 确定设备方向以供指南针使用
- 礼拜完成记录 —— 记录每日礼拜、连续天数以及进度，并为已完成的礼拜跳过提醒
- 偏好设置 —— 记住您的设置
- 念珠数据 —— 保存您的念词进度、每日总计和历史记录
- 系统反馈 —— 遵循系统声音和触感设置
- 振动 —— 念珠计数时提供触觉反馈
- 声音 —— 念珠计数时播放提示音
- 日历 —— 将礼拜提醒添加到专用日历账户

我们不会将您的信息用于广告、画像或与本应用核心功能无关的任何目的。

信息共享

我们不与任何人共享您的信息，因为我们从一开始就不会收到这些信息。

本应用确实会与以下 HarmonyOS 操作系统组件交互，这些组件受华为自身隐私政策约束：
- 系统地理编码器 —— 用于将您的坐标反向地理编码为城市名称（仅当您选择查看城市名称时）。
- 位置服务 —— 用于在您授予权限时获取您的 GPS 坐标。
- 音频服务 —— 用于读取系统铃声模式并播放本地音效。
- 振动服务 —— 用于念珠计数时产生触觉反馈。
- 日历服务 —— 用于将礼拜提醒事件写入本应用自己的日历账户。
- 系统备份服务 —— 用于在您启用时，将本应用的本地数据包含在设备的系统备份中。

有关操作系统如何处理这些服务的详细信息，请参阅华为隐私政策。

数据存储与保留

所有应用数据都存储在您的设备本地，并保留至您：
- 在应用内清除（例如重置念珠计数、取消勾选单次礼拜或切换到其他位置）
- 卸载本应用

如果启用了系统备份，应用数据的副本也可能保留在您的系统备份中，直至您通过系统设置将其删除或在所有关联设备上卸载应用。

为礼拜提醒创建的日历事件由系统日历应用保存，您可以随时关闭提醒总开关、删除"Sirat 伴侣"日历账户或卸载本应用以移除这些事件。卸载 Sirat 伴侣会永久删除本应用在您设备上存储的所有数据。

请求的权限

本应用请求以下 HarmonyOS 权限。您可以拒绝任何权限，而不影响应用其他功能的使用。

- ohos.permission.VIBRATE —— 念珠计数时的触觉反馈
- ohos.permission.APPROXIMATELY_LOCATION —— 用于礼拜时间的粗略位置
- ohos.permission.LOCATION —— 用于礼拜时间的精确位置
- ohos.permission.ACCELEROMETER —— 指南针和天房方向
- ohos.permission.READ_CALENDAR —— 读取本应用自己的日历事件，在重新排程前清除过期提醒
- ohos.permission.WRITE_CALENDAR —— 在专用日历账户中创建礼拜提醒事件

权限仅在您首次使用需要该权限的功能时请求。您可以随时在设备设置中撤销这些权限。

目前不请求 PUBLISH_AGENT_REMINDER 权限。详情请参阅上方的"通知功能"部分。

振动 —— 详细说明
VIBRATE 权限允许本应用在您每次点击念珠计数时产生一次短振动，以确认您的操作。它仅用于此本地触觉反馈，您可以随时在应用的 设置 → 界面自定义 → 振动 中禁用。此权限不会产生、存储或传输任何数据。

日历 —— 详细说明
READ_CALENDAR 和 WRITE_CALENDAR 权限允许本应用创建专用的"Sirat 伴侣"日历账户，并将礼拜提醒事件写入其中。本应用仅读取自己账户中的事件，并且仅用于在写入新事件前清除过期事件。本应用不会读取您设备上的其他日历。日历数据不会被传输到您的设备之外。您可以随时在 设置 → 通知 中关闭此功能，这将移除本应用创建的所有事件。

安全

由于 Sirat 伴侣不会将任何个人数据传输到您的设备之外，因此不存在服务器端数据泄露的风险。您的本地数据受 HarmonyOS 应用沙箱保护，可防止其他应用读取 Sirat 伴侣存储的偏好设置。当启用系统备份时，其安全性由 HarmonyOS 和您的华为账户设置决定。

儿童隐私

Sirat 伴侣面向普通受众，适合所有年龄段的用户。本应用不会有意收集任何人的个人信息，包括儿童，因为它根本不收集个人信息。

您的权利

由于本应用不收集或传输您的数据，我们这边没有可供披露、更正或删除的数据。您始终完全掌控自己的数据：
- 访问：所有数据均可在应用内查看。
- 删除：卸载应用会删除所有存储的数据。礼拜完成记录也可以通过取消勾选单次礼拜来清除。日历提醒事件可以通过关闭提醒总开关来移除。备份副本可通过系统备份设置删除。
- 可移植性：数据可随时查看和重新输入。
- 撤回同意：在设备设置中撤销权限。

第三方服务

Sirat 伴侣不集成任何第三方分析、广告或追踪服务。

本隐私政策的变更

我们可能会不时更新本隐私政策，以反映应用或适用法律的变化。当我们做出重大更改时，我们会更新本页顶部的"最后更新"日期。更改生效后继续使用本应用即表示接受修订后的政策。

联系我们

如果您对本隐私政策有任何疑问、疑虑或请求，请通过以下方式与我们联系：

电子邮件：sharjeel.butt@gmail.com
开发者：Sharjeel Idris`;

  // ============================================================
  // العربية
  // ============================================================

  private static readonly AR: string = `سياسة الخصوصية — رفيق الصراط

آخر تحديث: 26 أكتوبر 2026
تاريخ السريان: 26 أكتوبر 2026
ينطبق على: رفيق الصراط الإصدار 3.3.3 وما بعده

مقدمة

رفيق الصراط (يُشار إليه فيما يلي بـ"التطبيق" أو "نحن") هو تطبيق إسلامي مرافق لمنصة HarmonyOS، طوّره Sharjeel Idris. توضح سياسة الخصوصية هذه المعلومات التي يصل إليها التطبيق، وكيفية استخدام هذه المعلومات، وحقوقك فيما يتعلق بها.

لقد صممنا رفيق الصراط ليعمل بالكامل على جهازك. لا يتطلب التطبيق إنشاء حساب، ولا يتصل بأي خادم نشغّله، ولا ينقل بياناتك الشخصية إلينا أو إلى أي طرف ثالث.

بتثبيت التطبيق واستخدامه، فإنك توافق على الممارسات الموضحة في سياسة الخصوصية هذه.

المعلومات التي نصل إليها ونستخدمها

يصل رفيق الصراط إلى المعلومات التالية على جهازك فقط، وذلك لتقديم ميزاته. لا يتم نقل أي من هذه المعلومات إلينا أو إلى Huawei أو إلى أي طرف ثالث بواسطة التطبيق.

معلومات الموقع
- ما نصل إليه: إحداثيات GPS لجهازك (خط العرض وخط الطول)، وعند اختيارك للموقع اليدوي، الإحداثيات التي تُدخلها.
- لماذا نصل إليها: الموقع مطلوب لحساب أوقات الصلاة بدقة واتجاه القبلة لمدينتك.
- كيفية التخزين: يتم تخزين آخر موقع ناجح (الإحداثيات واسم المدينة) مؤقتاً على جهازك حتى يتمكن التطبيق من التحميل بسرعة. يمكنك مسح ذلك في أي وقت عن طريق التبديل إلى الموقع اليدوي أو إلغاء تثبيت التطبيق.
- النقل: لا يرسل التطبيق موقعك إلى أي خادم. إذا تم تمكين الترميز الجغرافي العكسي (لتحويل الإحداثيات إلى اسم مدينة)، تتم معالجة الطلب بواسطة نظام تحديد المواقع في نظام تشغيل جهازك — أي بواسطة HarmonyOS، وليس من قبلنا، ويخضع لسياسة الخصوصية الخاصة بـ Huawei.

معلومات المستشعرات
- ما نصل إليه: مستشعر التوجيه والمستشعر المغناطيسي في الجهاز.
- لماذا نصل إليها: مطلوبة لبوصلة القبلة لتحديد اتجاه الشمال الحقيقي وموقع الكعبة بالنسبة لجهازك.
- النقل: تُعالج قراءات المستشعرات بالكامل على جهازك ولا يتم تخزينها أو نقلها أبداً.

سجل الصلوات المكتملة
- ما نصل إليه: الصلوات التي تُعلّمها كمُصلَّاة كل يوم (الفجر، الظهر، العصر، المغرب، العشاء)، محفوظة حسب التاريخ.
- لماذا نصل إليها: لعرض تقدم اليوم والأيام المتتالية والملخصات الأسبوعية والشهرية والإحصاءات الإجمالية على الشاشة الرئيسية وصفحة تفاصيل الصلاة، ولتخطي إنشاء التذكيرات للصلوات التي أدّيتها بالفعل.
- كيفية التخزين: تُخزَّن محلياً على جهازك باستخدام واجهة HarmonyOS Preferences. لا تغادر جهازك إلا إذا كنت قد مكّنت النسخ الاحتياطي للنظام، وفي هذه الحالة تشارك في النسخ الاحتياطي الموصوف في قسم سجل التشخيص
- ما نصل إليه: ملف سجل نصي يكتبه رمز التطبيق نفسه، ويُسجّل أحداث دورة الحياة والأخطاء والتحذيرات المُنشأة محلياً.
- لماذا نصل إليه: للمساعدة في تشخيص المشكلات التي يُبلّغ عنها المستخدمون. يمكنك عرض هذا الملف أو نسخه أو مسحه في أي وقت من الإعدادات → سجلات التشخيص.
- كيفية التخزين: يُخزَّن محلياً على جهازك، داخل الصندوق الرملي الخاص بالتطبيق. لا يُنقل أبداً إلينا أو إلى أي طرف ثالث.
- النسخ الاحتياطي: يُستثنى السجل صراحةً من النسخة الاحتياطية للنظام، لذا يُعاد إنشاؤه من جديد في كل تثبيت ولا يمكن استعادته من جهاز سابق. "النسخ الاحتياطي والاستعادة" أدناه.

أوقات الصلاة والإعدادات
- ما نصل إليه: تفضيلات الحساب (طريقة الحساب، وقاعدة العصر، وتعديلات أوقات الصلاة، وقاعدة خطوط العرض العليا، والتقريب، وطريقة منتصف الليل، وحلّ المناطق القطبية، والشفق)، ومظهر التطبيق، والوضع الداكن، وتفضيل اللغة، وتنسيق الوقت، وإزاحة التقويم الهجري، ونوع التقويم الهجري، ووضع الموقع، والإحداثيات اليدوية، وتفضيل تقليد المناسبات، ومفاتيح رؤية الأوقات، وتفضيل الاهتزاز، وتفضيلات مظهر المسبحة، وتفضيل صوت المسبحة، وتفضيلات الإشعارات.
- لماذا نصل إليها: لتذكر خياراتك عبر إعادة تشغيل التطبيق.
- كيفية التخزين: تُخزَّن جميع التفضيلات محلياً على جهازك باستخدام واجهة HarmonyOS Preferences. لا تغادر جهازك إلا إذا كنت قد مكّنت النسخ الاحتياطي للنظام.

بيانات التسبيح
- ما نصل إليه: جلسات التسبيح التي تنشئها، وعناصر الأذكار داخلها، وأعدادها الحالية، وإجمالياتها اليومية، وسجل متدحرج لمدة 90 يوماً للأعداد اليومية لكل ذكر، والمظهر المختار لكل مسبحة.
- لماذا نصل إليها: لعرض تقدمك في التسبيح وحفظه على صفحة التسبيح وصفحة تفاصيل التسبيح، التي تعرض عروضاً أسبوعية وشهرية وسنوية لكل مسبحة ولكل ذكر.
- كيفية التخزين: تُخزَّن بيانات التسبيح محلياً على جهازك باستخدام واجهة HarmonyOS Preferences. تُرحَّل الأعداد اليومية تلقائياً إلى السجل كل ليلة؛ وتُسقَط الأيام التي تتجاوز آخر 90 يوماً من النافذة المتدحرجة. لا يُنقل أي شيء إلا إذا كنت قد مكّنت النسخ الاحتياطي للنظام.

حالة التغذية الراجعة للنظام
- ما نصل إليه: وضع الرنين الحالي للجهاز (رنين / اهتزاز / صامت) ومفتاح التغذية اللمسية في النظام.
- لماذا نصل إليها: ليتوافق صوت التطبيق واهتزازه مع إعداداتك على مستوى النظام. عندما يكون الهاتف صامتاً، يبقى التطبيق صامتاً؛ وعندما تكون التغذية اللمسية معطّلة، لا يحاول التطبيق الاهتزاز.
- كيفية التخزين: تُقرأ هذه القيم من نظام التشغيل عند الطلب وتُهمل فوراً. لا تُخزَّن أبداً ولا تُنقل. لا تتضمن أي بيانات شخصية.

التغذية اللمسية (الاهتزاز)
- ما نصل إليه: وظيفة الاهتزاز في الجهاز.
- لماذا نصل إليها: لتوفير اهتزاز قصير في كل مرة تضغط فيها لعدّ خرزة التسبيح، مما يؤكد لك الضغطة. يمكن إيقاف ذلك في أي وقت من الإعدادات ← تخصيص الواجهة ← الاهتزاز في التطبيق.
- النقل: يتم التحكم بالاهتزاز بالكامل على جهازك. لا يتم إنشاء أو تخزين أو نقل أي بيانات.

الصوت
- ما نصل إليه: وظيفة تشغيل الصوت في الجهاز.
- لماذا نصل إليها: لتشغيل نقرة قصيرة عند عدّ خرزة التسبيح، إذا كنت قد مكّنتها. يمكن إيقاف ذلك في أي وقت من الإعدادات ← تخصيص الواجهة ← الصوت في التطبيق. يحترم التطبيق أيضاً وضع الرنين في النظام — إذا كان الهاتف صامتاً، يبقى التطبيق صامتاً بغض النظر عن الإعداد داخل التطبيق.
- النقل: جميع أصوات النقر مُضمَّنة مع التطبيق وتُشغَّل محلياً. لا يُسجَّل صوت، ولا يُبثّ صوت، ولا تُنقل أي بيانات.

التقويم (تذكيرات الصلاة)
- ما نصل إليه: حساب تقويم مخصّص باسم "رفيق الصراط" في تقويم النظام على جهازك. عند تمكين تذكيرات الصلاة من الإعدادات ← الإشعارات، يكتب التطبيق حدث تقويم واحداً لكل صلاة مُعلَّقة خلال الأيام الثلاثة القادمة. كل حدث يحمل تذكير نظام مضبوطاً للتشغيل في وقت الصلاة، واختيارياً في الوقت المسبق الذي قمت بتكوينه. يحمل وصف الحدث حديثاً قصيراً مرتبطاً بتلك الصلاة مع ذكر مصدره.
- لماذا نصل إليها: لتسليم تذكيرات الصلاة عبر تقويم النظام، الذي يعمل بشكل موثوق حتى عندما لا يكون التطبيق قيد التشغيل.
- كيفية التخزين: تُخزَّن الأحداث بواسطة تطبيق التقويم في النظام تحت حساب التقويم الخاص بالتطبيق. يقرأ التطبيق الأحداث من حسابه الخاص فقط، وذلك فقط لإزالة الأحداث القديمة قبل إعادة الجدولة. لا يُقرأ أي بيانات تقويم أخرى، ولا تُنقل أي بيانات تقويم إلى أي مكان.
- الصلوات المؤدّاة: عند تعليم صلاة كمُصلَّاة في تاريخ معيّن، يزيل التطبيق تذكير تلك الصلاة لذلك التاريخ في إعادة الجدولة التالية. تعليم آخر صلاة في اليوم كمُصلَّاة يؤدي إلى إعادة جدولة فورية، بحيث تكون تذكيرات اليوم التالي جاهزة قبل مغادرتك التطبيق.
- الإزالة: يمكنك إزالة كل هذه الأحداث في أي وقت عن طريق إيقاف المفتاح الرئيسي للتذكيرات من الإعدادات ← الإشعارات، أو حذف حساب تقويم "رفيق الصراط" من تطبيق التقويم في النظام.

ميزات الإشعارات (غير مُفعَّلة حالياً)
يتضمن التطبيق خلفية إشعارات أصلية لتذكيرات الصلاة. هذه الخلفية معطّلة حالياً في انتظار موافقة AppGallery Connect على قدرة Agent-Powered Reminder. أثناء التعطيل:
- التطبيق لا يطلب إذن PUBLISH_AGENT_REMINDER.
- التطبيق لا ينشر أي إشعارات.
- لا تُنشأ أو تُخزَّن أو تُنقل أي بيانات متعلقة بالإشعارات.

آلية التذكير الفعّالة حالياً هي خلفية التقويم الموصوفة أعلاه. عند الموافقة على قدرة Agent-Powered Reminder، سيتم تحديث سياسة الخصوصية هذه للكشف عن خلفية الإشعارات، وسيُطلب إذن PUBLISH_AGENT_REMINDER في ذلك الوقت.

النسخ الاحتياطي والاستعادة

يدعم رفيق الصراط إطار النسخ الاحتياطي على مستوى النظام في HarmonyOS. عند تمكين النسخ الاحتياطي على جهازك، تُضمَّن بيانات التطبيق المخزَّنة محلياً في نسخة النظام الاحتياطية حتى يمكن استعادتها عند الانتقال إلى جهاز جديد أو إعادة تثبيت التطبيق.

- ما يُضمَّن: جميع إعدادات التطبيق وتفضيلاته (اللغة، المظهر، إعدادات حساب أوقات الصلاة، وضع الموقع والإحداثيات اليدوية، إزاحة التقويم الهجري ونوعه، إعدادات الإشعارات، تفضيلات الصوت والاهتزاز، تنسيق الوقت، تقليد المناسبات، مفاتيح رؤية الأوقات)، وجميع بيانات التسبيح (المسبحات المخصّصة، عناصر الأذكار، الأعداد الحالية، الإجماليات اليومية، سجل متدحرج لمدة 90 يوماً، الإجماليات الكلية)، والموقع الجغرافي المخزَّن مؤقتاً.
- ما يُستثنى: يُستثنى ملف سجل التشخيص عمداً من النسخ الاحتياطي ليُعاد إنشاؤه من جديد في كل تثبيت.
- كيفية العمل: يُنفَّذ النسخ الاحتياطي بالكامل بواسطة HarmonyOS. لا يُنقل إلينا، ونحن لا نشغّل خدمة النسخ الاحتياطي. إنشاء النسخة الاحتياطية ومكان تخزينها واستعادتها كلها أمور تتحكم بها إعدادات نظام جهازك وحسابك على Huawei. يُرجى الرجوع إلى سياسة الخصوصية الخاصة بـ Huawei للتفاصيل.
- تحكّمك: يمكنك تعطيل النسخ الاحتياطي لهذا التطبيق من إعدادات نظام جهازك، كما يمكنك حذف أي نسخة احتياطية موجودة من خلال الإعدادات نفسها.

ما لا نجمعه

رفيق الصراط لا يجمع أو يخزّن أو ينقل:
- اسمك أو بريدك الإلكتروني أو رقم هاتفك أو أي معلومات حساب
- معرفات الجهاز (IMEI، عنوان MAC، معرف الإعلان، أو ما شابه)
- التحليلات أو إحصاءات الاستخدام
- سجلات تشغيل التطبيق المنقولة خارج الجهاز — يُكتَب سجل تشخيص محلي في الصندوق الرملي الخاص بالتطبيق لأغراض استكشاف الأخطاء، لكنه لا يُنقل أبداً إلينا أو إلى أي طرف ثالث ولا يُضمَّن في النسخة الاحتياطية للنظام
- سجل التصفح أو جهات الاتصال أو الصور أو الملفات
- المعلومات المالية أو معلومات الدفع
- معرفات الإعلانات

نحن لا نستخدم أي تحليلات أو حزم SDK إعلانية أو مكتبات تتبع تابعة لأطراف ثالثة.

كيف نستخدم المعلومات

تُستخدم جميع المعلومات التي يصل إليها التطبيق على جهازك فقط، ولتقديم ميزات التطبيق حصراً:

- الموقع — حساب أوقات الصلاة واتجاه القبلة
- المستشعرات — تحديد اتجاه الجهاز للبوصلة
- سجل الصلوات — تتبع الصلوات اليومية والأيام المتتالية والتقدم، وتخطي التذكيرات للصلوات المؤدّاة
- التفضيلات — تذكر إعداداتك
- بيانات التسبيح — حفظ تقدم الأذكار والإجماليات اليومية والسجل
- حالة النظام — احترام إعدادات الصوت والاهتزاز في النظام
- الاهتزاز — توفير تغذية لمسية أثناء عدّ التسبيح
- الصوت — تشغيل نقرة عند عدّ التسبيح
- التقويم — إضافة تذكيرات الصلاة إلى حساب تقويم مخصّص

لا نستخدم معلوماتك للإعلانات أو التنميط أو أي غرض لا يتصل بالوظائف الأساسية للتطبيق.

مشاركة المعلومات

نحن لا نشارك معلوماتك مع أي شخص، لأننا لا نتلقاها أصلاً.

يتفاعل التطبيق مع المكونات التالية من نظام تشغيل HarmonyOS، والتي تخضع لسياسة الخصوصية الخاصة بـ Huawei:
- المُرمِّز الجغرافي للنظام — للترميز الجغرافي العكسي لإحداثياتك إلى اسم مدينة (فقط عندما تختار عرض اسم المدينة).
- خدمات الموقع — للحصول على إحداثيات GPS عند منحك الإذن.
- خدمة الصوت — لقراءة وضع الرنين في النظام وتشغيل الأصوات المحلية.
- خدمة الاهتزاز — لإنتاج تغذية لمسية عند عدّ التسبيح.
- خدمة التقويم — لكتابة أحداث تذكير الصلاة في حساب التقويم الخاص بالتطبيق.
- خدمة النسخ الاحتياطي للنظام — لتضمين بيانات التطبيق المحلية في نسخة النظام الاحتياطية، إذا كنت قد مكّنتها.

يرجى الرجوع إلى سياسة الخصوصية الخاصة بـ Huawei للحصول على تفاصيل حول كيفية تعامل نظام التشغيل مع هذه الخدمات.

تخزين البيانات والاحتفاظ بها

تُخزَّن جميع بيانات التطبيق محلياً على جهازك وتُحفظ حتى:
- تمسحها من داخل التطبيق (مثلاً، بإعادة تعيين أعداد التسبيح، أو إلغاء تحديد صلوات فردية، أو التبديل إلى موقع آخر)
- تلغي تثبيت التطبيق

إذا كان النسخ الاحتياطي للنظام ممكّناً، فقد تبقى نسخة من بيانات التطبيق محفوظة في نسخة النظام الاحتياطية حتى تحذفها من خلال إعدادات النظام أو تلغي تثبيت التطبيق على جميع الأجهزة المرتبطة بحسابك.

تُخزَّن أحداث التقويم المنشأة لتذكيرات الصلاة بواسطة تطبيق التقويم في النظام، ويمكن حذفها في أي وقت عن طريق إيقاف المفتاح الرئيسي للتذكيرات، أو حذف حساب تقويم "رفيق الصراط"، أو إلغاء تثبيت التطبيق. يؤدي إلغاء تثبيت رفيق الصراط إلى حذف جميع البيانات نهائياً.

الأذونات المطلوبة

يطلب التطبيق أذونات HarmonyOS التالية. يمكنك رفض أي إذن دون فقدان الوصول إلى بقية ميزات التطبيق.

- ohos.permission.VIBRATE — التغذية اللمسية عند عدّ التسبيح
- ohos.permission.APPROXIMATELY_LOCATION — موقع تقريبي لأوقات الصلاة
- ohos.permission.LOCATION — موقع دقيق لأوقات الصلاة
- ohos.permission.ACCELEROMETER — البوصلة واتجاه القبلة
- ohos.permission.READ_CALENDAR — قراءة أحداث التقويم الخاصة بالتطبيق لإزالة التذكيرات القديمة قبل إعادة الجدولة
- ohos.permission.WRITE_CALENDAR — إنشاء أحداث تذكير الصلاة في حساب التقويم المخصّص للتطبيق

تُطلب الأذونات فقط عند أول استخدامك لميزة تتطلبها. يمكن سحبها في أي وقت من إعدادات جهازك.

إذن PUBLISH_AGENT_REMINDER غير مطلوب حالياً. راجع قسم "ميزات الإشعارات" أعلاه للتفاصيل.

الاهتزاز — شرح مفصل
يسمح إذن VIBRATE للتطبيق بإنتاج اهتزاز قصير في كل مرة تضغط فيها لعدّ خرزة التسبيح، مما يؤكد لك الضغطة. يُستخدم هذا الإذن فقط لهذه التغذية اللمسية المحلية، ويمكن تعطيله في أي وقت من الإعدادات ← تخصيص الواجهة ← الاهتزاز في التطبيق. لا تُنشئ هذه الصلاحية أو تخزّن أو تنقل أي بيانات.

التقويم — شرح مفصل
تسمح أذونات READ_CALENDAR و WRITE_CALENDAR للتطبيق بإنشاء حساب تقويم مخصّص باسم "رفيق الصراط" وكتابة أحداث تذكير الصلاة فيه. يقرأ التطبيق الأحداث من حسابه الخاص فقط، وذلك فقط لإزالة الأحداث القديمة قبل كتابة أحداث جديدة. لا يقرأ التطبيق أي تقويم آخر على جهازك. لا تُنقل أي بيانات تقويم خارج جهازك. يمكنك تعطيل الميزة في أي وقت من الإعدادات ← الإشعارات، مما يؤدي إلى إزالة جميع الأحداث التي أنشأها التطبيق.

الأمان

نظراً لأن رفيق الصراط لا ينقل أي بيانات شخصية خارج جهازك، فلا توجد مخاطر تسرب بيانات على جانب الخادم. بياناتك المحلية محمية بواسطة صندوق تطبيقات HarmonyOS، الذي يمنع التطبيقات الأخرى من قراءة التفضيلات المخزنة لرفيق الصراط. عندما يكون النسخ الاحتياطي للنظام ممكّناً، تخضع أمنيته لـ HarmonyOS وإعدادات حسابك على Huawei.

خصوصية الأطفال

رفيق الصراط مخصص لجمهور عام ومناسب للمستخدمين من جميع الأعمار. لا يجمع التطبيق أي معلومات شخصية من أي شخص، بما في ذلك الأطفال، لأنه لا يجمع المعلومات الشخصية على الإطلاق.

حقوقك

نظراً لأن التطبيق لا يجمع بياناتك أو ينقلها، فلا توجد بيانات علينا الإفصاح عنها أو تصحيحها أو حذفها من جانبنا. لديك السيطرة الكاملة على بياناتك في جميع الأوقات:
- الوصول: جميع البيانات مرئية داخل التطبيق.
- الحذف: يؤدي إلغاء تثبيت التطبيق إلى إزالة جميع البيانات المخزنة. يمكن أيضاً مسح سجل الصلوات المكتملة بإلغاء تحديد الصلوات الفردية. يمكن إزالة أحداث تذكير التقويم عن طريق إيقاف المفتاح الرئيسي للتذكيرات. يمكن حذف نسخ النسخ الاحتياطي من خلال إعدادات النسخ الاحتياطي في النظام.
- القابلية للنقل: يمكن عرض البيانات وإعادة إدخالها في أي وقت.
- سحب الموافقة: اسحب الأذونات من إعدادات جهازك.

خدمات الأطراف الثالثة

رفيق الصراط لا يدمج أي تحليلات أو إعلانات أو خدمات تتبع تابعة لأطراف ثالثة.

التغييرات في سياسة الخصوصية هذه

قد نحدّث سياسة الخصوصية هذه من وقت لآخر لتعكس التغييرات في التطبيق أو القوانين المعمول بها. عندما نجري تغييرات جوهرية، سنقوم بتحديث تاريخ "آخر تحديث" في أعلى هذه الصفحة. يشكّل استمرار استخدام التطبيق بعد سريان التغييرات قبولاً للسياسة المنقّحة.

اتصل بنا

إذا كانت لديك أي أسئلة أو مخاوف أو طلبات بشأن سياسة الخصوصية هذه، يرجى الاتصال بنا على:

البريد الإلكتروني: sharjeel.butt@gmail.com
المطوّر: Sharjeel Idris`;
}