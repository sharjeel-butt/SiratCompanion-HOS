// entry/src/main/ets/data/PrivacyPolicy.ets

/**
 * Privacy policy text for Sirat Companion, in each supported language.
 *
 * The full hosted version is also available at:
 *   https://sharjeel-butt.github.io/SiratCompanion-HOS/
 *
 * IMPORTANT: This in-app version and the hosted index.md must stay in
 * sync. Both carry the same "Last updated" date and the same section
 * structure. When you change one, change the other.
 *
 * Section layout (all three languages):
 *   1. INTRODUCTION
 *   2. INFORMATION WE ACCESS
 *   3. WHAT WE DO NOT COLLECT
 *   4. HOW WE USE INFORMATION
 *   5. SHARING
 *   6. DATA STORAGE AND RETENTION
 *   7. PERMISSIONS
 *   8. SECURITY
 *   9. CHILDREN'S PRIVACY
 *   10. YOUR RIGHTS
 *   11. THIRD-PARTY SERVICES
 *   12. CHANGES
 *   13. CONTACT
 *
 * ## Reminder backend note (October 2026)
 *
 * As of this version, prayer-time reminders are delivered through the
 * Calendar Kit backend (calendar events with system reminders). The
 * Agent-Powered Reminder backend is implemented but disabled while
 * its capability is pending AppGallery Connect approval. When that
 * approval arrives, the notification sections below will be updated
 * to describe the notification backend instead of the calendar
 * backend.
 */
export class PrivacyPolicyProvider {
  static readonly FULL_URL: string =
    'https://sharjeel-butt.github.io/SiratCompanion-HOS/';

  // ============================================================
  // ENGLISH
  // ============================================================
  private static readonly EN: string = `PRIVACY POLICY — SIRAT COMPANION

Last updated: October 7, 2026

Applies to Sirat Companion version 2.3.0 and later.

1. INTRODUCTION

Sirat Companion ("the App") is an Islamic companion application for HarmonyOS, developed by Sharjeel Butt. This Privacy Policy explains what information the App accesses, how that information is used, and your rights regarding that information.

We have designed Sirat Companion to work entirely on your device. The App does not require an account, does not connect to any server we operate, and does not transmit your personal data to us or to any third party.

By installing and using the App, you agree to the practices described in this Privacy Policy.

2. INFORMATION WE ACCESS

Sirat Companion accesses the following information solely on your device to provide its features. None of this information is transmitted to us, to Huawei, or to any third party by the App.

• LOCATION — Your device's GPS coordinates, and — when you choose Manual Location — the coordinates you type in. Used to calculate prayer times and the Qibla direction for your city. The last successful location is cached on your device for faster loading. You can clear this at any time by switching to Manual Location or by uninstalling the App. If reverse geocoding is enabled, the request is handled by your device's operating system geocoder (HarmonyOS), not by us.

• SENSORS — The device's orientation sensor and magnetometer. Used for the Qibla compass to determine true north and the direction of the Kaaba. Readings are processed entirely on your device and are never stored or transmitted.

• PRAYER COMPLETION HISTORY — The prayers you mark as prayed each day (Fajr, Dhuhr, Asr, Maghrib, Isha), stored per calendar date. Used to power the Home dashboard: today's progress, streaks, weekly grid, monthly heatmap, and lifetime statistics. Stored locally on your device and never leaves it.

• SETTINGS — Calculation method, Asr rule, prayer offsets, high-latitude rule, app theme, dark mode, language, Hijri offset, vibration preference, Tasbih themes, Tasbih sound preference, notification preferences, and home-screen toggles. Stored locally on your device using the HarmonyOS Preferences API.

• TASBIH DATA — Your Tasbih sessions, dhikr items, counts, and per-tasbih themes. Stored locally on your device and never leaves it.

• SYSTEM FEEDBACK STATE — The device's ringer mode (ring / vibrate / silent) and the system haptics toggle. Read so that the App's own sound and vibration respect your system-level settings. These values are read from the operating system on demand and immediately discarded. They are never stored and never transmitted. No personal data is involved.

• HAPTIC FEEDBACK (VIBRATION) — The device's vibration capability. Used only to provide a short vibration when you count a Tasbih bead, confirming your tap. Vibration can be turned off at any time from Settings → UI Customization → Vibration. No data is generated, stored, or transmitted by this feature.

• SOUND — The device's audio playback capability. Used only to play a short click when you count a Tasbih bead, if you have enabled it. Can be turned off at any time from Settings → UI Customization → Sound. The App also respects your system ringer mode. All click sounds are bundled with the App and played locally. No audio is recorded, no audio is streamed, and no data is transmitted.

• CALENDAR (PRAYER REMINDERS) — When you enable prayer reminders in Settings → Notifications, the App creates a dedicated calendar account named "Sirat Companion" in your device's system calendar. For each enabled prayer over the next three days, one calendar event is created with a system reminder set to fire at the prayer time and, optionally, at your configured lead time. The App reads calendar events only from its own account, and only to remove stale events before rescheduling. No other calendar data is read, and no calendar data is transmitted anywhere. You can remove all of these events at any time by turning off the master reminder toggle, or by deleting the "Sirat Companion" calendar account from the system Calendar app.

• NOTIFICATION FEATURES (NOT CURRENTLY ACTIVE) — The App includes a native notification backend for prayer reminders. This backend is currently disabled while the Agent-Powered Reminder capability is pending approval by AppGallery Connect. While disabled, the App does NOT request the PUBLISH_AGENT_REMINDER permission, does NOT publish any notifications, and does NOT create, store, or transmit any notification-related data. The active reminder mechanism is the Calendar backend described above.

3. WHAT WE DO NOT COLLECT

We do not collect, store, or transmit:
• Your name, email, phone number, or account information
• Device identifiers (IMEI, MAC address, Advertising ID)
• Analytics, crash logs, or usage statistics
• Browsing history, contacts, photos, or files
• Financial or payment information
• Advertising identifiers

We do not use any third-party analytics SDKs, advertising SDKs, or tracking libraries.

4. HOW WE USE INFORMATION

All information accessed by the App is used only on your device and only to provide the App's features:
• Location — Calculate prayer times and Qibla direction
• Sensors — Determine device orientation for the compass
• Prayer completion history — Track your daily prayers, streaks, and progress statistics
• Preferences — Remember your settings
• Tasbih data — Persist your dhikr progress and preferences
• System feedback — Respect system sound and haptics settings
• Vibration — Provide haptic feedback while counting Tasbih
• Sound — Play a click when counting Tasbih
• Calendar — Add prayer-time reminders to a dedicated calendar account

We do not use your information for advertising, profiling, or any purpose unrelated to the App's core functionality.

5. SHARING

We do not share your information with anyone because we never receive it in the first place. The App interacts with the following HarmonyOS system components, which operate under Huawei's own privacy policy:
• System geocoder — for reverse geocoding coordinates into a city name
• Location services — to obtain GPS coordinates when you grant permission
• Audio service — to read the system ringer mode and play local sounds
• Vibration service — to produce tactile feedback when counting Tasbih
• Calendar service — to write prayer reminder events into the App's own calendar account

6. DATA STORAGE AND RETENTION

All App data is stored locally on your device. It is retained until you clear it from within the App or uninstall the App. Calendar events created for prayer reminders are stored by the system Calendar app and can be deleted at any time by turning off the reminder master toggle, by deleting the "Sirat Companion" calendar account, or by uninstalling the App. Uninstalling Sirat Companion permanently removes all data the App has stored on your device.

7. PERMISSIONS

• ohos.permission.VIBRATE — Haptic feedback while counting Tasbih
• ohos.permission.APPROXIMATELY_LOCATION — Approximate location for prayer times
• ohos.permission.LOCATION — Precise location for prayer times
• ohos.permission.ACCELEROMETER — Compass and Qibla direction
• ohos.permission.READ_CALENDAR — Read the App's own calendar events to remove stale reminders before rescheduling
• ohos.permission.WRITE_CALENDAR — Create prayer reminder events in the App's dedicated calendar account

Permissions are requested only when you first use a feature that requires them. They can be revoked at any time in your device's Settings.

The PUBLISH_AGENT_REMINDER permission is NOT currently requested. See Section 2 for details.

VIBRATION — DETAILED EXPLANATION

The VIBRATE permission allows the App to produce a short vibration each time you tap to count a Tasbih bead, confirming your tap. It is used only for this local haptic feedback and can be disabled at any time from Settings → UI Customization → Vibration. No data is generated, stored, or transmitted by this permission.

CALENDAR — DETAILED EXPLANATION

The READ_CALENDAR and WRITE_CALENDAR permissions allow the App to create a dedicated "Sirat Companion" calendar account and to write prayer reminder events into it. The App only reads events from its own account, and only to remove stale ones before writing new ones. The App does not read any other calendar on your device. No calendar data is transmitted off your device. You can disable the feature at any time from Settings → Notifications, which removes all events the App has created.

8. SECURITY

Because Sirat Companion does not transmit any personal data off your device, there is no server-side risk of data exposure. Your local data is protected by the HarmonyOS app sandbox, which prevents other apps from reading Sirat Companion's stored preferences.

9. CHILDREN'S PRIVACY

Sirat Companion is intended for general audiences and is suitable for users of all ages. The App does not knowingly collect any personal information from anyone, including children, because it does not collect personal information at all.

10. YOUR RIGHTS

You have full control over your data at all times:
• Access — All data is visible within the App.
• Deletion — Uninstalling the App removes all stored data. Prayer completion history can also be cleared by unchecking individual prayers. Calendar reminder events can be removed by turning off the reminder master toggle.
• Portability — Data can be viewed and re-entered at any time.
• Withdrawal of consent — Revoke permissions in your device Settings.

11. THIRD-PARTY SERVICES

Sirat Companion does not integrate any third-party analytics, advertising, or tracking services.

12. CHANGES

We may update this Privacy Policy from time to time to reflect changes in the App or applicable law. When we make material changes, we will update the "Last updated" date. Continued use of the App after changes take effect constitutes acceptance of the revised policy.

13. CONTACT

Email: sharjeel.butt@gmail.com
Developer: Sharjeel Butt`;

  // ============================================================
  // CHINESE (SIMPLIFIED)
  // ============================================================
  private static readonly ZH: string = `隐私政策 — SIRAT 伴侣

最后更新：2026 年 10 月 7 日

适用于 Sirat 伴侣 2.3.0 及更高版本。

1. 引言

Sirat 伴侣（以下简称"本应用"）是由 Sharjeel Butt 开发的 HarmonyOS 伊斯兰伴侣应用。本隐私政策说明了本应用访问哪些信息、如何使用这些信息，以及您对这些信息享有的权利。

我们设计的 Sirat 伴侣完全在您的设备上运行。本应用无需创建账户，不连接我们运营的任何服务器，也不会将您的个人数据传输给我们或任何第三方。

安装并使用本应用即表示您同意本隐私政策中所述的做法。

2. 我们访问的信息

Sirat 伴侣仅在您的设备上访问以下信息，用于提供其功能。本应用不会将这些信息传输给我们、华为或任何第三方。

• 位置 — 您设备的 GPS 坐标，以及您在选择手动位置时输入的坐标。用于为您所在城市计算礼拜时间和天房方向。最近一次成功获取的位置会缓存在您的设备上，以便快速加载。您可以随时通过切换到手动位置或卸载应用来清除。如果启用反向地理编码，请求由您设备操作系统的地理编码器（HarmonyOS）处理，而非我们。

• 传感器 — 设备的方向传感器和磁力计。用于天房指南针，以确定真北方向和麦加相对于您设备的位置。传感器读数完全在您的设备上处理，绝不存储或传输。

• 礼拜完成记录 — 您每天标记为已礼的礼拜（晨礼、晌礼、晡礼、昏礼、宵礼），按日历日期存储。用于驱动首页的今日进度、连续天数、每周网格、每月热力图以及累计统计。存储在您的设备本地，从不离开设备。

• 设置 — 计算方式、晡礼规则、礼拜时间偏移、高纬度规则、应用主题、深色模式、语言、回历偏移、振动偏好、念珠主题、念珠音效偏好、通知偏好以及主屏幕开关。通过 HarmonyOS Preferences API 存储在您的设备本地。

• 念珠数据 — 您创建的念珠、念词项目、计数以及每串念珠的主题。存储在您的设备本地，从不离开设备。

• 系统反馈状态 — 设备当前的铃声模式（响铃 / 振动 / 静音）和系统触感反馈开关。读取这些值是为了让本应用自身的声音和振动遵循您的系统级设置。这些值按需从操作系统读取并立即丢弃，从不存储，也从不传输。不涉及任何个人数据。

• 触觉反馈（振动）— 设备的振动功能。仅用于在您每次点击念珠计数时提供一次短振动，以确认您的操作。您可以随时在 设置 → 界面自定义 → 振动 中关闭。此功能不会产生、存储或传输任何数据。

• 声音 — 设备的音频播放功能。仅用于在您启用时，播放念珠计数的短提示音。您可以随时在 设置 → 界面自定义 → 声音 中关闭。本应用也会遵循您的系统铃声模式。所有提示音均随应用打包并在本地播放。不录制音频，不传输音频流，也不传输任何数据。

• 日历（礼拜提醒）— 当您在 设置 → 通知 中启用礼拜提醒后，本应用会在您设备的系统日历中创建一个名为"Sirat 伴侣"的专用日历账户。对于未来三天内每个已启用的礼拜，应用会创建一个日历事件，并设置系统提醒在礼拜时间触发，以及（可选）在您配置的提前时间触发。本应用仅读取自己账户中的日历事件，并且仅用于在重新排程前清除过期事件。不会读取其他日历数据，也不会向任何地方传输日历数据。您可以随时关闭提醒总开关，或在系统日历应用中删除"Sirat 伴侣"日历账户，从而移除所有相关事件。

• 通知功能（当前未启用）— 本应用包含用于礼拜提醒的原生通知后端。该后端目前处于停用状态，因为 Agent-Powered Reminder 能力正在等待 AppGallery Connect 审批。停用期间，本应用不会请求 PUBLISH_AGENT_REMINDER 权限，不会发布任何通知，也不会创建、存储或传输任何与通知相关的数据。当前生效的提醒机制为上述日历后端。

3. 我们不收集的内容

我们不收集、存储或传输：
• 您的姓名、电子邮件地址、电话号码或账户信息
• 设备标识符（IMEI、MAC 地址、广告 ID）
• 分析、崩溃日志或使用统计
• 浏览历史、联系人、照片或文件
• 财务或支付信息
• 广告标识符

我们不使用任何第三方分析 SDK、广告 SDK 或追踪库。

4. 我们如何使用信息

本应用访问的所有信息仅在您的设备上使用，且仅用于提供本应用的功能：
• 位置 — 计算礼拜时间和天房方向
• 传感器 — 确定设备方向以供指南针使用
• 礼拜完成记录 — 记录您的每日礼拜、连续天数以及进度统计
• 偏好设置 — 记住您的设置
• 念珠数据 — 保存您的念词进度和偏好
• 系统反馈 — 遵循系统声音和触感设置
• 振动 — 念珠计数时提供触觉反馈
• 声音 — 念珠计数时播放提示音
• 日历 — 将礼拜提醒添加到专用日历账户

我们不会将您的信息用于广告、画像或与本应用核心功能无关的任何目的。

5. 信息共享

我们不与任何人共享您的信息，因为我们从一开始就不会收到这些信息。本应用会与以下 HarmonyOS 系统组件交互，这些组件受华为自身隐私政策约束：
• 系统地理编码器 — 用于将坐标反向地理编码为城市名称
• 位置服务 — 用于在您授予权限时获取 GPS 坐标
• 音频服务 — 用于读取系统铃声模式并播放本地音效
• 振动服务 — 用于念珠计数时产生触觉反馈
• 日历服务 — 用于将礼拜提醒事件写入本应用自己的日历账户

6. 数据存储与保留

所有应用数据都存储在您的设备本地。数据保留至您在应用内清除或卸载本应用。为礼拜提醒创建的日历事件由系统日历应用保存，您可以随时关闭提醒总开关、删除"Sirat 伴侣"日历账户或卸载本应用以移除这些事件。卸载 Sirat 伴侣会永久删除本应用在您设备上存储的所有数据。

7. 权限

• ohos.permission.VIBRATE — 念珠计数时的触觉反馈
• ohos.permission.APPROXIMATELY_LOCATION — 用于礼拜时间的粗略位置
• ohos.permission.LOCATION — 用于礼拜时间的精确位置
• ohos.permission.ACCELEROMETER — 指南针和天房方向
• ohos.permission.READ_CALENDAR — 读取本应用自己的日历事件，在重新排程前清除过期提醒
• ohos.permission.WRITE_CALENDAR — 在专用日历账户中创建礼拜提醒事件

权限仅在您首次使用需要该权限的功能时请求。您可以随时在设备设置中撤销这些权限。

目前不请求 PUBLISH_AGENT_REMINDER 权限。详情请参阅第 2 节。

振动 — 详细说明

VIBRATE 权限允许本应用在您每次点击念珠计数时产生一次短振动，以确认您的操作。它仅用于此本地触觉反馈，您可以随时在 设置 → 界面自定义 → 振动 中禁用。此权限不会产生、存储或传输任何数据。

日历 — 详细说明

READ_CALENDAR 和 WRITE_CALENDAR 权限允许本应用创建专用的"Sirat 伴侣"日历账户，并将礼拜提醒事件写入其中。本应用仅读取自己账户中的事件，并且仅用于在写入新事件前清除过期事件。本应用不会读取您设备上的其他日历。日历数据不会被传输到您的设备之外。您可以随时在 设置 → 通知 中关闭此功能，这将移除本应用创建的所有事件。

8. 安全

由于 Sirat 伴侣不会将任何个人数据传输到您的设备之外，因此不存在服务器端数据泄露的风险。您的本地数据受 HarmonyOS 应用沙箱保护，可防止其他应用读取 Sirat 伴侣存储的偏好设置。

9. 儿童隐私

Sirat 伴侣面向普通受众，适合所有年龄段的用户。本应用不会有意收集任何人的个人信息，包括儿童，因为它根本不收集个人信息。

10. 您的权利

您始终完全掌控自己的数据：
• 访问 — 所有数据均可在应用内查看。
• 删除 — 卸载应用会删除所有存储的数据。礼拜完成记录也可以通过取消勾选单次礼拜来清除。日历提醒事件可以通过关闭提醒总开关来移除。
• 可移植性 — 数据可随时查看和重新输入。
• 撤回同意 — 在设备设置中撤销权限。

11. 第三方服务

Sirat 伴侣不集成任何第三方分析、广告或追踪服务。

12. 变更

我们可能会不时更新本隐私政策，以反映应用或适用法律的变化。当我们做出重大更改时，我们会更新"最后更新"日期。更改生效后继续使用本应用即表示接受修订后的政策。

13. 联系我们

电子邮件：sharjeel.butt@gmail.com
开发者：Sharjeel Butt`;

  // ============================================================
  // ARABIC
  // ============================================================
  private static readonly AR: string = `سياسة الخصوصية — رفيق الصراط

آخر تحديث: 7 أكتوبر 2026

ينطبق على رفيق الصراط الإصدار 2.3.0 وما بعده.

1. مقدمة

رفيق الصراط ("التطبيق") هو تطبيق إسلامي مرافق لمنصة HarmonyOS، طوّره Sharjeel Butt. توضح سياسة الخصوصية هذه المعلومات التي يصل إليها التطبيق، وكيفية استخدامها، وحقوقك فيما يتعلق بها.

لقد صممنا رفيق الصراط ليعمل بالكامل على جهازك. لا يتطلب التطبيق إنشاء حساب، ولا يتصل بأي خادم نشغّله، ولا ينقل بياناتك الشخصية إلينا أو إلى أي طرف ثالث.

بتثبيت التطبيق واستخدامه، فإنك توافق على الممارسات الموضحة في سياسة الخصوصية هذه.

2. المعلومات التي نصل إليها

يصل رفيق الصراط إلى المعلومات التالية على جهازك فقط، وذلك لتقديم ميزاته. لا يتم نقل أي من هذه المعلومات إلينا أو إلى Huawei أو إلى أي طرف ثالث.

• الموقع — إحداثيات GPS لجهازك، وعند اختيارك للموقع اليدوي، الإحداثيات التي تُدخلها. تُستخدم لحساب أوقات الصلاة واتجاه القبلة لمدينتك. يتم تخزين آخر موقع ناجح على جهازك مؤقتاً لتحميل أسرع. يمكنك مسح ذلك في أي وقت عن طريق التبديل إلى الموقع اليدوي أو إلغاء تثبيت التطبيق. إذا تم تمكين الترميز الجغرافي العكسي، تتم معالجة الطلب بواسطة نظام تحديد المواقع في نظام التشغيل (HarmonyOS)، وليس من قبلنا.

• المستشعرات — مستشعر التوجيه والمستشعر المغناطيسي في الجهاز. تُستخدم لبوصلة القبلة لتحديد الشمال الحقيقي واتجاه الكعبة. تُعالج القراءات بالكامل على جهازك ولا يتم تخزينها أو نقلها.

• سجل الصلوات المكتملة — الصلوات التي تُعلّمها كمُصلَّاة كل يوم (الفجر، الظهر، العصر، المغرب، العشاء)، محفوظة حسب التاريخ. تُستخدم لعرض تقدم اليوم، والأيام المتتالية، والشبكة الأسبوعية، والخريطة الشهرية، والإحصاءات الإجمالية على الشاشة الرئيسية. تُخزَّن محلياً على جهازك ولا تغادره أبداً.

• الإعدادات — طريقة الحساب، وقاعدة العصر، وتعديلات أوقات الصلاة، وقاعدة خطوط العرض العليا، ومظهر التطبيق، والوضع الداكن، واللغة، وإزاحة التقويم الهجري، وتفضيل الاهتزاز، ومظهر المسبحة، وتفضيل صوت المسبحة، وتفضيلات الإشعارات، ومفاتيح الشاشة الرئيسية. تُخزَّن محلياً على جهازك باستخدام واجهة HarmonyOS Preferences.

• بيانات التسبيح — جلسات التسبيح والأذكار والأعداد والمظهر المختار لكل مسبحة. تُخزَّن محلياً على جهازك ولا تغادره أبداً.

• حالة التغذية الراجعة للنظام — وضع الرنين في الجهاز (رنين / اهتزاز / صامت) ومفتاح التغذية اللمسية في النظام. تُقرأ هذه القيم ليتوافق صوت التطبيق واهتزازه مع إعداداتك على مستوى النظام. تُقرأ من نظام التشغيل عند الطلب وتُهمل فوراً. لا تُخزَّن أبداً ولا تُنقل. لا تتضمن أي بيانات شخصية.

• التغذية اللمسية (الاهتزاز) — وظيفة الاهتزاز في الجهاز. تُستخدم فقط لتوفير اهتزاز قصير عند عدّ خرزة التسبيح، مما يؤكد لك الضغطة. يمكن إيقاف الاهتزاز في أي وقت من الإعدادات ← تخصيص الواجهة ← الاهتزاز. لا تُنشئ هذه الميزة أو تخزّن أو تنقل أي بيانات.

• الصوت — وظيفة تشغيل الصوت في الجهاز. تُستخدم فقط لتشغيل نقرة قصيرة عند عدّ خرزة التسبيح، إذا كنت قد مكّنتها. يمكن إيقاف ذلك في أي وقت من الإعدادات ← تخصيص الواجهة ← الصوت. يحترم التطبيق أيضاً وضع الرنين في النظام. جميع أصوات النقر مُضمَّنة مع التطبيق وتُشغَّل محلياً. لا يُسجَّل صوت، ولا يُبثّ صوت، ولا تُنقل أي بيانات.

• التقويم (تذكيرات الصلاة) — عند تمكين تذكيرات الصلاة من الإعدادات ← الإشعارات، يُنشئ التطبيق حساب تقويم مخصّصاً باسم "رفيق الصراط" في تقويم النظام على جهازك. لكل صلاة مُفعَّلة خلال الأيام الثلاثة القادمة، يُنشأ حدث تقويم واحد مع تذكير نظام مضبوط للتشغيل في وقت الصلاة، واختيارياً في الوقت المسبق الذي قمت بتكوينه. يقرأ التطبيق أحداث التقويم من حسابه الخاص فقط، وذلك فقط لإزالة الأحداث القديمة قبل إعادة الجدولة. لا يُقرأ أي بيانات تقويم أخرى، ولا تُنقل أي بيانات تقويم إلى أي مكان. يمكنك إزالة كل هذه الأحداث في أي وقت عن طريق إيقاف المفتاح الرئيسي للتذكيرات، أو حذف حساب تقويم "رفيق الصراط" من تطبيق التقويم في النظام.

• ميزات الإشعارات (غير مُفعَّلة حالياً) — يتضمن التطبيق خلفية إشعارات أصلية لتذكيرات الصلاة. هذه الخلفية معطّلة حالياً في انتظار موافقة AppGallery Connect على قدرة Agent-Powered Reminder. أثناء التعطيل، لا يطلب التطبيق إذن PUBLISH_AGENT_REMINDER، ولا ينشر أي إشعارات، ولا يُنشئ أو يخزّن أو ينقل أي بيانات متعلقة بالإشعارات. آلية التذكير الفعّالة حالياً هي خلفية التقويم الموصوفة أعلاه.

3. ما لا نجمعه

نحن لا نجمع أو نخزّن أو ننقل:
• اسمك أو بريدك الإلكتروني أو رقم هاتفك أو معلومات الحساب
• معرفات الجهاز (IMEI، عنوان MAC، معرف الإعلان)
• التحليلات أو سجلات الأعطال أو إحصاءات الاستخدام
• سجل التصفح أو جهات الاتصال أو الصور أو الملفات
• المعلومات المالية أو معلومات الدفع
• معرفات الإعلانات

نحن لا نستخدم أي تحليلات أو حزم SDK إعلانية أو مكتبات تتبع تابعة لأطراف ثالثة.

4. كيف نستخدم المعلومات

تُستخدم جميع المعلومات التي يصل إليها التطبيق على جهازك فقط، ولتقديم ميزات التطبيق حصراً:
• الموقع — حساب أوقات الصلاة واتجاه القبلة
• المستشعرات — تحديد اتجاه الجهاز للبوصلة
• سجل الصلوات المكتملة — تتبع صلواتك اليومية والأيام المتتالية وإحصاءات التقدم
• التفضيلات — تذكر إعداداتك
• بيانات التسبيح — حفظ تقدم الأذكار والتفضيلات
• حالة النظام — احترام إعدادات الصوت والاهتزاز في النظام
• الاهتزاز — توفير تغذية لمسية أثناء عدّ التسبيح
• الصوت — تشغيل نقرة عند عدّ التسبيح
• التقويم — إضافة تذكيرات الصلاة إلى حساب تقويم مخصّص

لا نستخدم معلوماتك للإعلانات أو التنميط أو أي غرض لا يتصل بالوظائف الأساسية للتطبيق.

5. المشاركة

نحن لا نشارك معلوماتك مع أي شخص، لأننا لا نتلقاها أصلاً. يتفاعل التطبيق مع المكونات التالية من HarmonyOS، والتي تخضع لسياسة الخصوصية الخاصة بـ Huawei:
• المُرمِّز الجغرافي للنظام — للترميز الجغرافي العكسي للإحداثيات إلى اسم مدينة
• خدمات الموقع — للحصول على إحداثيات GPS عند منحك الإذن
• خدمة الصوت — لقراءة وضع الرنين في النظام وتشغيل الأصوات المحلية
• خدمة الاهتزاز — لإنتاج تغذية لمسية عند عدّ التسبيح
• خدمة التقويم — لكتابة أحداث تذكير الصلاة في حساب التقويم الخاص بالتطبيق

6. تخزين البيانات والاحتفاظ بها

تُخزَّن جميع بيانات التطبيق محلياً على جهازك. تُحفظ حتى تمسحها من داخل التطبيق أو تلغي تثبيت التطبيق. تُخزَّن أحداث التقويم المنشأة لتذكيرات الصلاة بواسطة تطبيق التقويم في النظام، ويمكن حذفها في أي وقت عن طريق إيقاف المفتاح الرئيسي للتذكيرات، أو حذف حساب تقويم "رفيق الصراط"، أو إلغاء تثبيت التطبيق. يؤدي إلغاء تثبيت رفيق الصراط إلى حذف جميع البيانات نهائياً.

7. الأذونات

• ohos.permission.VIBRATE — التغذية اللمسية عند عدّ التسبيح
• ohos.permission.APPROXIMATELY_LOCATION — موقع تقريبي لأوقات الصلاة
• ohos.permission.LOCATION — موقع دقيق لأوقات الصلاة
• ohos.permission.ACCELEROMETER — البوصلة واتجاه القبلة
• ohos.permission.READ_CALENDAR — قراءة أحداث التقويم الخاصة بالتطبيق لإزالة التذكيرات القديمة قبل إعادة الجدولة
• ohos.permission.WRITE_CALENDAR — إنشاء أحداث تذكير الصلاة في حساب التقويم المخصّص للتطبيق

تُطلب الأذونات فقط عند أول استخدامك لميزة تتطلبها. يمكن سحبها في أي وقت من إعدادات جهازك.

لا يُطلب حالياً إذن PUBLISH_AGENT_REMINDER. راجع القسم 2 للتفاصيل.

الاهتزاز — شرح مفصل

يسمح إذن VIBRATE للتطبيق بإنتاج اهتزاز قصير في كل مرة تضغط فيها لعدّ خرزة التسبيح، مما يؤكد لك الضغطة. يُستخدم هذا الإذن فقط لهذه التغذية اللمسية المحلية، ويمكن تعطيله في أي وقت من الإعدادات ← تخصيص الواجهة ← الاهتزاز. لا تُنشئ هذه الصلاحية أو تخزّن أو تنقل أي بيانات.

التقويم — شرح مفصل

تسمح أذونات READ_CALENDAR و WRITE_CALENDAR للتطبيق بإنشاء حساب تقويم مخصّص باسم "رفيق الصراط" وكتابة أحداث تذكير الصلاة فيه. يقرأ التطبيق الأحداث من حسابه الخاص فقط، وذلك فقط لإزالة الأحداث القديمة قبل كتابة أحداث جديدة. لا يقرأ التطبيق أي تقويم آخر على جهازك. لا تُنقل أي بيانات تقويم خارج جهازك. يمكنك تعطيل الميزة في أي وقت من الإعدادات ← الإشعارات، مما يؤدي إلى إزالة جميع الأحداث التي أنشأها التطبيق.

8. الأمان

نظراً لأن رفيق الصراط لا ينقل أي بيانات شخصية خارج جهازك، فلا توجد مخاطر تسرب بيانات على جانب الخادم. بياناتك المحلية محمية بواسطة صندوق تطبيقات HarmonyOS، الذي يمنع التطبيقات الأخرى من قراءة التفضيلات المخزنة لرفيق الصراط.

9. خصوصية الأطفال

رفيق الصراط مخصص لجمهور عام ومناسب للمستخدمين من جميع الأعمار. لا يجمع التطبيق أي معلومات شخصية من أي شخص، بما في ذلك الأطفال، لأنه لا يجمع المعلومات الشخصية على الإطلاق.

10. حقوقك

لديك السيطرة الكاملة على بياناتك في جميع الأوقات:
• الوصول — جميع البيانات مرئية داخل التطبيق.
• الحذف — يؤدي إلغاء تثبيت التطبيق إلى إزالة جميع البيانات المخزنة. يمكن أيضاً مسح سجل الصلوات المكتملة بإلغاء تحديد الصلوات الفردية. يمكن إزالة أحداث تذكير التقويم عن طريق إيقاف المفتاح الرئيسي للتذكيرات.
• القابلية للنقل — يمكن عرض البيانات وإعادة إدخالها في أي وقت.
• سحب الموافقة — اسحب الأذونات من إعدادات جهازك.

11. خدمات الأطراف الثالثة

رفيق الصراط لا يدمج أي تحليلات أو إعلانات أو خدمات تتبع تابعة لأطراف ثالثة.

12. التغييرات

قد نحدّث سياسة الخصوصية هذه من وقت لآخر لتعكس التغييرات في التطبيق أو القوانين المعمول بها. عندما نجري تغييرات جوهرية، سنقوم بتحديث تاريخ "آخر تحديث". يشكّل استمرار استخدام التطبيق بعد سريان التغييرات قبولاً للسياسة المنقّحة.

13. اتصل بنا

البريد الإلكتروني: sharjeel.butt@gmail.com
المطوّر: Sharjeel Butt`;

  // ============================================================
  // LOOKUP
  // ============================================================

  static get(lang: string): string {
    if (lang === 'zh') {
      return PrivacyPolicyProvider.ZH;
    }
    if (lang === 'ar') {
      return PrivacyPolicyProvider.AR;
    }
    return PrivacyPolicyProvider.EN;
  }
}