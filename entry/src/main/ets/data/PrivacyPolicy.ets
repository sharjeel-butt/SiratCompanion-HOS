// entry/src/main/ets/data/PrivacyPolicy.ets

/**
 * Privacy policy text for Sirat Companion, in each supported language.
 *
 * The full hosted version is also available at:
 *   https://sharjeel-butt.github.io/SiratCompanion-HOS/
 */
export class PrivacyPolicyProvider {

  static readonly FULL_URL: string =
    'https://sharjeel-butt.github.io/SiratCompanion-HOS/';

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

  private static readonly EN: string = `PRIVACY POLICY — SIRAT COMPANION

Last updated: October 1, 2026

1. INTRODUCTION

Sirat Companion ("the App") is an Islamic companion application for HarmonyOS. This Privacy Policy explains what information the App accesses, how that information is used, and your rights regarding that information.

We have designed Sirat Companion to work entirely on your device. The App does not require an account, does not connect to any server we operate, and does not transmit your personal data to us or to any third party.

By installing and using the App, you agree to the practices described in this Privacy Policy.

2. INFORMATION WE ACCESS

Sirat Companion accesses the following information solely on your device to provide its features. None of this information is transmitted to us, to Huawei, or to any third party by the App.

• LOCATION — Your device's GPS coordinates. Used to calculate prayer times and the Qibla direction for your city. The last successful location is cached on your device for faster loading.

• SENSORS — Orientation sensor and magnetometer. Used for the Qibla compass. Readings are processed entirely on your device and are never stored or transmitted.

• SETTINGS — Calculation method, Asr rule, prayer offsets, high-latitude rule, app theme, dark mode, language, Hijri offset, vibration preference, Tasbih themes, Tasbih sound preference, and home-screen toggles. Stored locally on your device using the HarmonyOS Preferences API.

• SYSTEM FEEDBACK STATE — The app reads the device's ringer mode and system haptics toggle so that its own sound and vibration respect the user's system-level settings. These values are read from the operating system, never stored, and never transmitted. No personal data is involved.

• PRAYER COMPLETION HISTORY — The prayers you mark as prayed each day, stored per calendar date. Used to power the Home dashboard: today's progress, streaks, weekly grid, monthly heatmap, and lifetime statistics. Stored locally on your device and never leaves it.

• TASBIH DATA — Your Tasbih sessions, dhikr items, counts, and per-tasbih themes. Stored locally on your device and never leave it.

• HAPTIC FEEDBACK (VIBRATION) — The device's vibration capability. Used only to provide a short vibration when you count a Tasbih bead, confirming your tap. Vibration can be turned off at any time from Settings → UI Customization → Vibration. No data is generated, stored, or transmitted by this feature.

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
• Preferences — Remember your settings
• Prayer completion history — Track your daily prayers, streaks, and progress statistics
• Tasbih data — Persist your dhikr progress and preferences
• Vibration — Provide haptic feedback while counting Tasbih

We do not use your information for advertising, profiling, or any purpose unrelated to the App's core functionality.

5. SHARING

We do not share your information with anyone because we never receive it in the first place. The App interacts with the following HarmonyOS system components, which operate under Huawei's own privacy policy:
• System geocoder — for reverse geocoding coordinates into a city name
• Location services — to obtain GPS coordinates when you grant permission

6. DATA STORAGE AND RETENTION

All App data is stored locally on your device. It is retained until you clear it from within the App or uninstall the App. Uninstalling Sirat Companion permanently removes all data the App has stored on your device.

7. PERMISSIONS

• ohos.permission.VIBRATE — Haptic feedback while counting Tasbih
• ohos.permission.APPROXIMATELY_LOCATION — Approximate location for prayer times
• ohos.permission.LOCATION — Precise location for prayer times
• ohos.permission.ACCELEROMETER — Compass and Qibla direction

Permissions are requested only when you first use a feature that requires them. They can be revoked at any time in your device's Settings.

VIBRATION — DETAILED EXPLANATION

The VIBRATE permission allows the App to produce a short vibration each time you tap to count a Tasbih bead, confirming your tap. It is used only for this local haptic feedback and can be disabled at any time from Settings → UI Customization → Vibration. No data is generated, stored, or transmitted by this permission.

8. SECURITY

Because Sirat Companion does not transmit any personal data off your device, there is no server-side risk of data exposure. Your local data is protected by the HarmonyOS app sandbox.

9. CHILDREN'S PRIVACY

Sirat Companion is suitable for users of all ages. The App does not knowingly collect any personal information from anyone, because it does not collect personal information at all.

10. YOUR RIGHTS

You have full control over your data at all times:
• Access — All data is visible within the App.
• Deletion — Uninstalling the App removes all stored data. Prayer completion history can also be cleared by unchecking individual prayers.
• Withdrawal of consent — Revoke permissions in your device Settings.

11. THIRD-PARTY SERVICES

Sirat Companion does not integrate any third-party analytics, advertising, or tracking services.

12. CHANGES

We may update this Privacy Policy from time to time. When we make material changes, we will update the "Last updated" date. Continued use of the App after changes take effect constitutes acceptance of the revised policy.

13. CONTACT

Email: sharjeel.butt@gmail.com
Developer: Sharjeel Butt`;

  // ============================================================
  // CHINESE (SIMPLIFIED)
  // ============================================================

  private static readonly ZH: string = `隐私政策 — SIRAT 伴侣

最后更新：2026 年 10 月 1 日

1. 引言

Sirat 伴侣（以下简称"本应用"）是一款面向 HarmonyOS 的伊斯兰伴侣应用。本隐私政策说明了本应用访问哪些信息、如何使用这些信息，以及您对这些信息享有的权利。

我们设计的 Sirat 伴侣完全在您的设备上运行。本应用无需创建账户，不连接我们运营的任何服务器，也不会将您的个人数据传输给我们或任何第三方。

安装并使用本应用即表示您同意本隐私政策中所述的做法。

2. 我们访问的信息

Sirat 伴侣仅在您的设备上访问以下信息，用于提供其功能。本应用不会将这些信息传输给我们、华为或任何第三方。

• 位置 — 设备的 GPS 坐标。用于为您所在城市计算礼拜时间和天房方向。最近一次成功获取的位置会缓存在您的设备上。

• 传感器 — 方向传感器和磁力计。用于天房指南针。传感器读数完全在您的设备上处理，绝不存储或传输。

• 设置 — 计算方式、晡礼规则、礼拜时间偏移、高纬度规则、应用主题、深色模式、语言、回历偏移、振动偏好、念珠主题、念珠音效偏好以及主屏幕开关。通过 HarmonyOS Preferences API 存储在您的设备本地。

• 系统反馈状态 — 本应用会读取设备的铃声模式和系统触感反馈开关，使其声音和振动遵循用户的系统级设置。这些值仅从操作系统读取，不会存储，也不会传输。不涉及任何个人数据。

• 礼拜完成记录 — 您每天标记为已礼的礼拜，按日历日期存储。用于驱动首页的今日进度、连续天数、每周网格、每月热力图以及累计统计。存储在您的设备本地，从不离开设备。

• 念珠数据 — 您创建的念珠、念词项目、计数以及每串念珠的主题。存储在您的设备本地，从不离开设备。

• 触觉反馈（振动）— 设备的振动功能。仅用于在您每次点击念珠计数时提供一次短振动，以确认您的操作。您可以随时在 设置 → 界面自定义 → 振动 中关闭。此功能不会产生、存储或传输任何数据。

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
• 偏好设置 — 记住您的设置
• 礼拜完成记录 — 记录您的每日礼拜、连续天数以及进度统计
• 念珠数据 — 保存您的念词进度和偏好
• 振动 — 念珠计数时提供触觉反馈

我们不会将您的信息用于广告、画像或与本应用核心功能无关的任何目的。

5. 信息共享

我们不与任何人共享您的信息，因为我们从一开始就不会收到这些信息。本应用会与以下 HarmonyOS 系统组件交互，这些组件受华为自身隐私政策约束：
• 系统地理编码器 — 用于将坐标反向地理编码为城市名称
• 位置服务 — 用于在您授予权限时获取 GPS 坐标

6. 数据存储与保留

所有应用数据都存储在您的设备本地。数据保留至您在应用内清除或卸载本应用。卸载 Sirat 伴侣会永久删除本应用在您设备上存储的所有数据。

7. 权限

• ohos.permission.VIBRATE — 念珠计数时的触觉反馈
• ohos.permission.APPROXIMATELY_LOCATION — 用于礼拜时间的粗略位置
• ohos.permission.LOCATION — 用于礼拜时间的精确位置
• ohos.permission.ACCELEROMETER — 指南针和天房方向

权限仅在您首次使用需要该权限的功能时请求。您可以随时在设备设置中撤销这些权限。

振动 — 详细说明

VIBRATE 权限允许本应用在您每次点击念珠计数时产生一次短振动，以确认您的操作。它仅用于此本地触觉反馈，您可以随时在 设置 → 界面自定义 → 振动 中禁用。此权限不会产生、存储或传输任何数据。

8. 安全

由于 Sirat 伴侣不会将任何个人数据传输到您的设备之外，因此不存在服务器端数据泄露的风险。您的本地数据受 HarmonyOS 应用沙箱保护。

9. 儿童隐私

Sirat 伴侣适合所有年龄段的用户。本应用不会有意收集任何人的个人信息，因为它根本不收集个人信息。

10. 您的权利

您始终完全掌控自己的数据：
• 访问 — 所有数据均可在应用内查看。
• 删除 — 卸载应用会删除所有存储的数据。礼拜完成记录也可以通过取消勾选单次礼拜来清除。
• 撤回同意 — 在设备设置中撤销权限。

11. 第三方服务

Sirat 伴侣不集成任何第三方分析、广告或追踪服务。

12. 变更

我们可能会不时更新本隐私政策。当我们做出重大更改时，我们会更新"最后更新"日期。更改生效后继续使用本应用即表示接受修订后的政策。

13. 联系我们

电子邮件：sharjeel.butt@gmail.com
开发者：Sharjeel Butt`;

  // ============================================================
  // ARABIC
  // ============================================================

  private static readonly AR: string = `سياسة الخصوصية — رفيق الصراط

آخر تحديث: 1 أكتوبر 2026

1. مقدمة

رفيق الصراط ("التطبيق") هو تطبيق إسلامي مرافق لمنصة HarmonyOS. توضح سياسة الخصوصية هذه المعلومات التي يصل إليها التطبيق، وكيفية استخدامها، وحقوقك فيما يتعلق بها.

لقد صممنا رفيق الصراط ليعمل بالكامل على جهازك. لا يتطلب التطبيق إنشاء حساب، ولا يتصل بأي خادم نشغّله، ولا ينقل بياناتك الشخصية إلينا أو إلى أي طرف ثالث.

بتثبيت التطبيق واستخدامه، فإنك توافق على الممارسات الموضحة في سياسة الخصوصية هذه.

2. المعلومات التي نصل إليها

يصل رفيق الصراط إلى المعلومات التالية على جهازك فقط، وذلك لتقديم ميزاته. لا يتم نقل أي من هذه المعلومات إلينا أو إلى Huawei أو إلى أي طرف ثالث.

• الموقع — إحداثيات GPS لجهازك. تُستخدم لحساب أوقات الصلاة واتجاه القبلة لمدينتك. يتم تخزين آخر موقع ناجح على جهازك مؤقتاً.

• المستشعرات — مستشعر التوجيه والمستشعر المغناطيسي. تُستخدم لبوصلة القبلة. تُعالج القراءات بالكامل على جهازك ولا يتم تخزينها أو نقلها.

• الإعدادات — طريقة الحساب، وقاعدة العصر، وتعديلات أوقات الصلاة، وقاعدة خطوط العرض العليا، ومظهر التطبيق، والوضع الداكن، واللغة، وإزاحة التقويم الهجري، وتفضيل الاهتزاز، ومظهر المسبحة، وتفضيل صوت المسبحة، ومفاتيح الشاشة الرئيسية. تُخزَّن محلياً على جهازك باستخدام واجهة HarmonyOS Preferences.

• حالة التغذية الراجعة للنظام — يقرأ التطبيق وضع الرنين ومفتاح التغذية اللمسية في النظام ليتوافق صوته واهتزازه مع إعدادات المستخدم على مستوى النظام. تُقرأ هذه القيم من نظام التشغيل فقط، ولا تُخزَّن ولا تُنقل. لا تتضمن أي بيانات شخصية.

• سجل الصلوات المكتملة — الصلوات التي تُعلّمها كمُصلَّاة كل يوم، محفوظة حسب التاريخ. تُستخدم لعرض تقدم اليوم، والأيام المتتالية، والشبكة الأسبوعية، والخريطة الشهرية، والإحصاءات الإجمالية على الشاشة الرئيسية. تُخزَّن محلياً على جهازك ولا تغادره أبداً.

• بيانات التسبيح — جلسات التسبيح والأذكار والأعداد والمظهر المختار لكل مسبحة. تُخزَّن محلياً على جهازك ولا تغادره أبداً.

• التغذية اللمسية (الاهتزاز) — وظيفة الاهتزاز في الجهاز. تُستخدم فقط لتوفير اهتزاز قصير عند عدّ خرزة التسبيح، مما يؤكد لك الضغطة. يمكن إيقاف الاهتزاز في أي وقت من الإعدادات ← تخصيص الواجهة ← الاهتزاز. لا تُنشئ هذه الميزة أو تخزّن أو تنقل أي بيانات.

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
• التفضيلات — تذكر إعداداتك
• سجل الصلوات المكتملة — تتبع صلواتك اليومية والأيام المتتالية وإحصاءات التقدم
• بيانات التسبيح — حفظ تقدم الأذكار والتفضيلات
• الاهتزاز — توفير تغذية لمسية أثناء عدّ التسبيح

لا نستخدم معلوماتك للإعلانات أو التنميط أو أي غرض لا يتصل بالوظائف الأساسية للتطبيق.

5. المشاركة

نحن لا نشارك معلوماتك مع أي شخص، لأننا لا نتلقاها أصلاً. يتفاعل التطبيق مع المكونات التالية من HarmonyOS، والتي تخضع لسياسة الخصوصية الخاصة بـ Huawei:
• المُرمِّز الجغرافي للنظام — للترميز الجغرافي العكسي للإحداثيات إلى اسم مدينة
• خدمات الموقع — للحصول على إحداثيات GPS عند منحك الإذن

6. تخزين البيانات والاحتفاظ بها

تُخزَّن جميع بيانات التطبيق محلياً على جهازك. تُحفظ حتى تمسحها من داخل التطبيق أو تلغي تثبيت التطبيق. يؤدي إلغاء تثبيت رفيق الصراط إلى حذف جميع البيانات نهائياً.

7. الأذونات

• ohos.permission.VIBRATE — التغذية اللمسية عند عدّ التسبيح
• ohos.permission.APPROXIMATELY_LOCATION — موقع تقريبي لأوقات الصلاة
• ohos.permission.LOCATION — موقع دقيق لأوقات الصلاة
• ohos.permission.ACCELEROMETER — البوصلة واتجاه القبلة

تُطلب الأذونات فقط عند أول استخدامك لميزة تتطلبها. يمكن سحبها في أي وقت من إعدادات جهازك.

الاهتزاز — شرح مفصل

يسمح إذن VIBRATE للتطبيق بإنتاج اهتزاز قصير في كل مرة تضغط فيها لعدّ خرزة التسبيح، مما يؤكد لك الضغطة. يُستخدم هذا الإذن فقط لهذه التغذية اللمسية المحلية، ويمكن تعطيله في أي وقت من الإعدادات ← تخصيص الواجهة ← الاهتزاز. لا تُنشئ هذه الصلاحية أو تخزّن أو تنقل أي بيانات.

8. الأمان

نظراً لأن رفيق الصراط لا ينقل أي بيانات شخصية خارج جهازك، فلا توجد مخاطر تسرب بيانات على جانب الخادم. بياناتك المحلية محمية بواسطة صندوق تطبيقات HarmonyOS.

9. خصوصية الأطفال

رفيق الصراط مناسب للمستخدمين من جميع الأعمار. لا يجمع التطبيق أي معلومات شخصية من أي شخص، لأنه لا يجمع المعلومات الشخصية على الإطلاق.

10. حقوقك

لديك السيطرة الكاملة على بياناتك في جميع الأوقات:
• الوصول — جميع البيانات مرئية داخل التطبيق.
• الحذف — يؤدي إلغاء تثبيت التطبيق إلى إزالة جميع البيانات المخزنة. يمكن أيضاً مسح سجل الصلوات المكتملة بإلغاء تحديد الصلوات الفردية.
• سحب الموافقة — اسحب الأذونات من إعدادات جهازك.

11. خدمات الأطراف الثالثة

رفيق الصراط لا يدمج أي تحليلات أو إعلانات أو خدمات تتبع تابعة لأطراف ثالثة.

12. التغييرات

قد نحدّث سياسة الخصوصية هذه من وقت لآخر. عندما نجري تغييرات جوهرية، سنقوم بتحديث تاريخ "آخر تحديث". يشكّل استمرار استخدام التطبيق بعد سريان التغييرات قبولاً للسياسة المنقّحة.

13. اتصل بنا

البريد الإلكتروني: sharjeel.butt@gmail.com
المطور: Sharjeel Butt`;
}