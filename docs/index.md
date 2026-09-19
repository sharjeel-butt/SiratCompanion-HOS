# Privacy Policy — Sirat Companion

**Last updated:** September 19, 2026
**Effective date:** September 19, 2026

[English](#english) · [中文](#chinese) · [العربية](#arabic)

---

<a name="english"></a>

# English

## Introduction

Sirat Companion ("the App", "we", "us", or "our") is an Islamic companion application for HarmonyOS, developed by *
*Sharjeel Butt** ("the Developer"). This Privacy Policy explains what information the App accesses, how that information
is used, and your rights regarding that information.

We have designed Sirat Companion to work entirely on your device. The App does not require an account, does not connect
to any server we operate, and does not transmit your personal data to us or to any third party.

By installing and using the App, you agree to the practices described in this Privacy Policy.

## Information We Access and Use

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

### Prayer Times and Settings

- **What we access:** Your calculation preferences (convention, Asr rule, prayer offsets, high-latitude rule), theme
  preference, language preference, Hijri date offset, notification settings, vibration preference, and home-screen
  toggles.
- **Why we access it:** To remember your choices across app restarts.
- **How it is stored:** All preferences are stored locally on your device using the HarmonyOS Preferences API. They
  never leave your device.

### Tasbih Data

- **What we access:** The Tasbih sessions you create, the dhikr items within them, and your counts.
- **Why we access it:** To display and persist your Tasbih progress.
- **How it is stored:** Tasbih data is stored locally on your device using the HarmonyOS Preferences API. It never
  leaves your device.

### Notification Permission

- **What we access:** If you enable prayer notifications, the App schedules local reminders through the HarmonyOS
  reminder agent.
- **Why we access it:** To deliver the prayer time reminders you requested.
- **Transmission:** Reminders are scheduled and delivered entirely on your device. No notification content is sent to
  any server.

## What We Do Not Collect

Sirat Companion does **not** collect, store, or transmit:

- Your name, email address, phone number, or any account information
- Device identifiers (IMEI, MAC address, Advertising ID, or similar)
- Analytics, crash logs, or usage statistics
- Browsing history, contacts, photos, or files
- Financial or payment information
- Advertising identifiers

We do not use any third-party analytics SDKs, advertising SDKs, or tracking libraries.

## How We Use the Information

All information accessed by the App is used only on your device and only to provide the App's features:

| Information   | Purpose                                      |
|---------------|----------------------------------------------|
| Location      | Calculate prayer times and Qibla direction   |
| Sensors       | Determine device orientation for the compass |
| Preferences   | Remember your settings                       |
| Tasbih data   | Persist your dhikr progress                  |
| Notifications | Deliver prayer time reminders you requested  |

We do not use your information for advertising, profiling, or any purpose unrelated to the App's core functionality.

## Sharing of Information

We do not share your information with anyone, because we never receive it in the first place.

The App does interact with the following components of the HarmonyOS operating system, which operate under Huawei's own
privacy policy:

- **System geocoder** — for reverse geocoding your coordinates into a city name (only when you choose to view a city
  name).
- **Location services** — to obtain your GPS coordinates when you grant permission.
- **Reminder agent** — to schedule local prayer reminders.

Please refer to Huawei's privacy policy for details on how the operating system handles these services.

## Data Storage and Retention

All App data is stored locally on your device and is retained until you:

- Clear it from within the App (e.g. by resetting Tasbih counts or switching to a different location)
- Uninstall the App

Uninstalling Sirat Companion permanently removes all data the App has stored on your device.

## Permissions Requested

The App requests the following HarmonyOS permissions. You can deny any permission without losing access to the rest of
the App's features.

| Permission                               | Purpose                               |
|------------------------------------------|---------------------------------------|
| `ohos.permission.APPROXIMATELY_LOCATION` | Approximate location for prayer times |
| `ohos.permission.LOCATION`               | Precise location for prayer times     |
| `ohos.permission.ACCELEROMETER`          | Compass and Qibla direction           |
| `ohos.permission.PUBLISH_AGENT_REMINDER` | Prayer time notifications             |

Permissions are requested only when you first use a feature that requires them. They can be revoked at any time in your
device's Settings.

### Agent-Powered Reminder — Detailed Explanation

The `PUBLISH_AGENT_REMINDER` permission allows the App to schedule local reminders using the HarmonyOS reminder agent.
These reminders are used exclusively for prayer time notifications, which fire at the time of each prayer and optionally
a few minutes before. The reminders are scheduled entirely on the device and carry no personal data. You can disable
them at any time from the App's **Settings → Notifications** section.

## Security

Because Sirat Companion does not transmit any personal data off your device, there is no server-side risk of data
exposure. Your local data is protected by the HarmonyOS app sandbox, which prevents other apps from reading Sirat
Companion's stored preferences.

## Children's Privacy

Sirat Companion is intended for general audiences and is suitable for users of all ages. The App does not knowingly
collect any personal information from anyone, including children, because it does not collect personal information at
all.

## Your Rights

Because the App does not collect or transmit your data, there is no data for us to disclose, correct, or delete on our
side. You have full control over your data at all times:

- **Access:** All data is visible within the App.
- **Deletion:** Uninstalling the App removes all stored data.
- **Portability:** Data can be viewed and re-entered at any time.
- **Withdrawal of consent:** Revoke permissions in your device Settings.

## Third-Party Services

Sirat Companion does **not** integrate any third-party analytics, advertising, or tracking services.

## Changes to This Privacy Policy

We may update this Privacy Policy from time to time to reflect changes in the App or applicable law. When we make
material changes, we will update the "Last updated" date at the top of this page. Continued use of the App after changes
take effect constitutes acceptance of the revised policy.

## Contact Us

If you have questions, concerns, or requests regarding this Privacy Policy, please contact us at:

**Email:** sharjeel.butt@example.com
**Developer:** Sharjeel Butt

---

[Back to top](#privacy-policy--sirat-companion)

---

<a name="chinese"></a>

# 中文

## 引言

Sirat 伴侣（以下简称"本应用"、"我们"）是由 **Sharjeel Butt** 开发的 HarmonyOS
伊斯兰伴侣应用。本隐私政策说明了本应用访问哪些信息、如何使用这些信息，以及您对这些信息享有的权利。

我们设计的 Sirat 伴侣完全在您的设备上运行。本应用无需创建账户，不连接我们运营的任何服务器，也不会将您的个人数据传输给我们或任何第三方。

安装并使用本应用即表示您同意本隐私政策中所述的做法。

## 我们访问和使用的信息

Sirat 伴侣仅在您的设备上访问以下信息，用于提供其功能。本应用不会将这些信息传输给我们、华为或任何第三方。

### 位置信息

- **我们访问的内容：** 您设备的 GPS 坐标（纬度和经度），以及您在选择手动位置时输入的坐标。
- **我们为何访问：** 位置用于为您所在城市准确计算礼拜时间和天房方向。
- **存储方式：** 最近一次成功获取的位置（坐标和城市名称）会缓存在您的设备上，以便应用快速加载。您可以随时通过切换到手动位置或卸载应用来清除。
- **传输：** 本应用不会将您的位置发送到任何服务器。如果启用反向地理编码（将坐标转换为城市名称），该请求由您设备操作系统的地理编码器处理——即由
  HarmonyOS 处理，而非我们，并受华为自身隐私政策的约束。

### 传感器信息

- **我们访问的内容：** 设备的方向传感器和磁力计。
- **我们为何访问：** 天房指南针需要这些信息来确定真北方向以及麦加相对于您设备的位置。
- **传输：** 传感器读数完全在您的设备上处理，绝不存储或传输。

### 礼拜时间与设置

- **我们访问的内容：** 您的计算偏好（计算方式、晡礼规则、礼拜时间偏移、高纬度规则）、主题偏好、语言偏好、回历日期偏移、通知设置、振动偏好以及主屏幕开关。
- **我们为何访问：** 用于在应用重启后记住您的选择。
- **存储方式：** 所有偏好设置均通过 HarmonyOS Preferences API 存储在您的设备本地。它们从不离开您的设备。

### 念珠数据

- **我们访问的内容：** 您创建的念珠、其中的念词项目以及您的计数。
- **我们为何访问：** 用于显示和保存您的念珠进度。
- **存储方式：** 念珠数据通过 HarmonyOS Preferences API 存储在您的设备本地。它从不离开您的设备。

### 通知权限

- **我们访问的内容：** 如果您启用礼拜通知，本应用将通过 HarmonyOS 提醒代理安排本地提醒。
- **我们为何访问：** 用于发送您请求的礼拜时间提醒。
- **传输：** 提醒完全在您的设备上安排和发送。任何通知内容都不会发送到任何服务器。

## 我们不收集的内容

Sirat 伴侣**不**收集、存储或传输：

- 您的姓名、电子邮件地址、电话号码或任何账户信息
- 设备标识符（IMEI、MAC 地址、广告 ID 或类似信息）
- 分析、崩溃日志或使用统计
- 浏览历史、联系人、照片或文件
- 财务或支付信息
- 广告标识符

我们不使用任何第三方分析 SDK、广告 SDK 或追踪库。

## 我们如何使用信息

本应用访问的所有信息仅在您的设备上使用，且仅用于提供本应用的功能：

| 信息   | 用途            |
|------|---------------|
| 位置   | 计算礼拜时间和天房方向   |
| 传感器  | 确定设备方向以供指南针使用 |
| 偏好设置 | 记住您的设置        |
| 念珠数据 | 保存您的念词进度      |
| 通知   | 发送您请求的礼拜时间提醒  |

我们不会将您的信息用于广告、画像或与本应用核心功能无关的任何目的。

## 信息共享

我们不与任何人共享您的信息，因为我们从一开始就不会收到这些信息。

本应用确实会与以下 HarmonyOS 操作系统组件交互，这些组件受华为自身隐私政策约束：

- **系统地理编码器** —— 用于将您的坐标反向地理编码为城市名称（仅当您选择查看城市名称时）。
- **位置服务** —— 用于在您授予权限时获取您的 GPS 坐标。
- **提醒代理** —— 用于安排本地礼拜提醒。

有关操作系统如何处理这些服务的详细信息，请参阅华为隐私政策。

## 数据存储与保留

所有应用数据都存储在您的设备本地，并保留至您：

- 在应用内清除（例如重置念珠计数或切换到其他位置）
- 卸载本应用

卸载 Sirat 伴侣会永久删除本应用在您设备上存储的所有数据。

## 请求的权限

本应用请求以下 HarmonyOS 权限。您可以拒绝任何权限，而不影响应用其他功能的使用。

| 权限                                       | 用途          |
|------------------------------------------|-------------|
| `ohos.permission.APPROXIMATELY_LOCATION` | 用于礼拜时间的粗略位置 |
| `ohos.permission.LOCATION`               | 用于礼拜时间的精确位置 |
| `ohos.permission.ACCELEROMETER`          | 指南针和天房方向    |
| `ohos.permission.PUBLISH_AGENT_REMINDER` | 礼拜时间通知      |

权限仅在您首次使用需要该权限的功能时请求。您可以随时在设备设置中撤销这些权限。

### 代理提醒 —— 详细说明

`PUBLISH_AGENT_REMINDER` 权限允许本应用使用 HarmonyOS
提醒代理安排本地提醒。这些提醒仅用于礼拜时间通知，在每次礼拜时以及可选择地提前几分钟触发。提醒完全在设备上安排，不携带任何个人数据。您可以随时在应用的
**设置 → 通知**部分禁用它们。

## 安全

由于 Sirat 伴侣不会将任何个人数据传输到您的设备之外，因此不存在服务器端数据泄露的风险。您的本地数据受 HarmonyOS
应用沙箱保护，可防止其他应用读取 Sirat 伴侣存储的偏好设置。

## 儿童隐私

Sirat 伴侣面向普通受众，适合所有年龄段的用户。本应用不会有意收集任何人的个人信息，包括儿童，因为它根本不收集个人信息。

## 您的权利

由于本应用不收集或传输您的数据，我们这边没有可供披露、更正或删除的数据。您始终完全掌控自己的数据：

- **访问：** 所有数据均可在应用内查看。
- **删除：** 卸载应用会删除所有存储的数据。
- **可移植性：** 数据可随时查看和重新输入。
- **撤回同意：** 在设备设置中撤销权限。

## 第三方服务

Sirat 伴侣**不**集成任何第三方分析、广告或追踪服务。

## 本隐私政策的变更

我们可能会不时更新本隐私政策，以反映应用或适用法律的变化。当我们做出重大更改时，我们会更新本页顶部的"最后更新"
日期。更改生效后继续使用本应用即表示接受修订后的政策。

## 联系我们

如果您对本隐私政策有任何疑问、疑虑或请求，请通过以下方式与我们联系：

**电子邮件：** sharjeel.butt@example.com
**开发者：** Sharjeel Butt

---

[返回顶部](#privacy-policy--sirat-companion)

---

<a name="arabic"></a>

# العربية

## مقدمة

رفيق الصراط (يُشار إليه فيما يلي بـ"التطبيق" أو "نحن") هو تطبيق إسلامي مرافق لمنصة HarmonyOS، طوّره **Sharjeel Butt**.
توضح سياسة الخصوصية هذه المعلومات التي يصل إليها التطبيق، وكيفية استخدام هذه المعلومات، وحقوقك فيما يتعلق بها.

لقد صممنا رفيق الصراط ليعمل بالكامل على جهازك. لا يتطلب التطبيق إنشاء حساب، ولا يتصل بأي خادم نشغّله، ولا ينقل بياناتك
الشخصية إلينا أو إلى أي طرف ثالث.

بتثبيت التطبيق واستخدامه، فإنك توافق على الممارسات الموضحة في سياسة الخصوصية هذه.

## المعلومات التي نصل إليها ونستخدمها

يصل رفيق الصراط إلى المعلومات التالية على جهازك فقط، وذلك لتقديم ميزاته. لا يتم نقل أي من هذه المعلومات إلينا أو إلى
Huawei أو إلى أي طرف ثالث بواسطة التطبيق.

### معلومات الموقع

- **ما نصل إليه:** إحداثيات GPS لجهازك (خط العرض وخط الطول)، وعند اختيارك للموقع اليدوي، الإحداثيات التي تُدخلها.
- **لماذا نصل إليها:** الموقع مطلوب لحساب أوقات الصلاة بدقة واتجاه القبلة لمدينتك.
- **كيفية التخزين:** يتم تخزين آخر موقع ناجح (الإحداثيات واسم المدينة) مؤقتاً على جهازك حتى يتمكن التطبيق من التحميل
  بسرعة. يمكنك مسح ذلك في أي وقت عن طريق التبديل إلى الموقع اليدوي أو إلغاء تثبيت التطبيق.
- **النقل:** لا يرسل التطبيق موقعك إلى أي خادم. إذا تم تمكين الترميز الجغرافي العكسي (لتحويل الإحداثيات إلى اسم مدينة)،
  تتم معالجة الطلب بواسطة نظام تحديد المواقع في نظام تشغيل جهازك — أي بواسطة HarmonyOS، وليس من قبلنا، ويخضع لسياسة
  الخصوصية الخاصة بـ Huawei.

### معلومات المستشعرات

- **ما نصل إليه:** مستشعر التوجيه والمستشعر المغناطيسي في الجهاز.
- **لماذا نصل إليها:** مطلوبة لبوصلة القبلة لتحديد اتجاه الشمال الحقيقي وموقع الكعبة بالنسبة لجهازك.
- **النقل:** تُعالج قراءات المستشعرات بالكامل على جهازك ولا يتم تخزينها أو نقلها أبداً.

### أوقات الصلاة والإعدادات

- **ما نصل إليه:** تفضيلات الحساب (طريقة الحساب، وقاعدة العصر، وتعديلات أوقات الصلاة، وقاعدة خطوط العرض العليا)، وتفضيل
  المظهر، وتفضيل اللغة، وإزاحة التقويم الهجري، وإعدادات الإشعارات، وتفضيل الاهتزاز، ومفاتيح الشاشة الرئيسية.
- **لماذا نصل إليها:** لتذكر خياراتك عبر إعادة تشغيل التطبيق.
- **كيفية التخزين:** تُخزَّن جميع التفضيلات محلياً على جهازك باستخدام واجهة HarmonyOS Preferences. لا تغادر جهازك أبداً.

### بيانات التسبيح

- **ما نصل إليه:** جلسات التسبيح التي تنشئها، وعناصر الأذكار داخلها، وأعدادها.
- **لماذا نصل إليها:** لعرض تقدمك في التسبيح وحفظه.
- **كيفية التخزين:** تُخزَّن بيانات التسبيح محلياً على جهازك باستخدام واجهة HarmonyOS Preferences. لا تغادر جهازك أبداً.

### إذن الإشعارات

- **ما نصل إليه:** إذا مكّنت إشعارات الصلاة، يجدول التطبيق تذكيرات محلية عبر وكيل التذكير في HarmonyOS.
- **لماذا نصل إليها:** لإيصال تذكيرات أوقات الصلاة التي طلبتها.
- **النقل:** تُجدول التذكيرات وتُسلَّم بالكامل على جهازك. لا يُرسَل أي محتوى إشعار إلى أي خادم.

## ما لا نجمعه

رفيق الصراط **لا** يجمع أو يخزّن أو ينقل:

- اسمك أو بريدك الإلكتروني أو رقم هاتفك أو أي معلومات حساب
- معرفات الجهاز (IMEI، عنوان MAC، معرف الإعلان، أو ما شابه)
- التحليلات أو سجلات الأعطال أو إحصاءات الاستخدام
- سجل التصفح أو جهات الاتصال أو الصور أو الملفات
- المعلومات المالية أو معلومات الدفع
- معرفات الإعلانات

نحن لا نستخدم أي تحليلات أو حزم SDK إعلانية أو مكتبات تتبع تابعة لأطراف ثالثة.

## كيف نستخدم المعلومات

تُستخدم جميع المعلومات التي يصل إليها التطبيق على جهازك فقط، ولتقديم ميزات التطبيق حصراً:

| المعلومات      | الغرض                                  |
|----------------|----------------------------------------|
| الموقع         | حساب أوقات الصلاة واتجاه القبلة        |
| المستشعرات     | تحديد اتجاه الجهاز للبوصلة             |
| التفضيلات      | تذكر إعداداتك                          |
| بيانات التسبيح | حفظ تقدم الأذكار                       |
| الإشعارات      | إيصال تذكيرات أوقات الصلاة التي طلبتها |

لا نستخدم معلوماتك للإعلانات أو التنميط أو أي غرض لا يتصل بالوظائف الأساسية للتطبيق.

## مشاركة المعلومات

نحن لا نشارك معلوماتك مع أي شخص، لأننا لا نتلقاها أصلاً.

يتفاعل التطبيق مع المكونات التالية من نظام تشغيل HarmonyOS، والتي تخضع لسياسة الخصوصية الخاصة بـ Huawei:

- **المُرمِّز الجغرافي للنظام** — للترميز الجغرافي العكسي لإحداثياتك إلى اسم مدينة (فقط عندما تختار عرض اسم المدينة).
- **خدمات الموقع** — للحصول على إحداثيات GPS عند منحك الإذن.
- **وكيل التذكير** — لجدولة تذكيرات الصلاة المحلية.

يرجى الرجوع إلى سياسة الخصوصية الخاصة بـ Huawei للحصول على تفاصيل حول كيفية تعامل نظام التشغيل مع هذه الخدمات.

## تخزين البيانات والاحتفاظ بها

تُخزَّن جميع بيانات التطبيق محلياً على جهازك وتُحفظ حتى:

- تمسحها من داخل التطبيق (مثلاً، بإعادة تعيين أعداد التسبيح أو التبديل إلى موقع آخر)
- تلغي تثبيت التطبيق

يؤدي إلغاء تثبيت رفيق الصراط إلى حذف جميع البيانات التي خزّنها التطبيق على جهازك نهائياً.

## الأذونات المطلوبة

يطلب التطبيق أذونات HarmonyOS التالية. يمكنك رفض أي إذن دون فقدان الوصول إلى بقية ميزات التطبيق.

| الإذن                                    | الغرض                     |
|------------------------------------------|---------------------------|
| `ohos.permission.APPROXIMATELY_LOCATION` | موقع تقريبي لأوقات الصلاة |
| `ohos.permission.LOCATION`               | موقع دقيق لأوقات الصلاة   |
| `ohos.permission.ACCELEROMETER`          | البوصلة واتجاه القبلة     |
| `ohos.permission.PUBLISH_AGENT_REMINDER` | إشعارات أوقات الصلاة      |

تُطلب الأذونات فقط عند أول استخدامك لميزة تتطلبها. يمكن سحبها في أي وقت من إعدادات جهازك.

### وكيل التذكير — شرح مفصل

يسمح إذن `PUBLISH_AGENT_REMINDER` للتطبيق بجدولة تذكيرات محلية باستخدام وكيل التذكير في HarmonyOS. تُستخدم هذه التذكيرات
حصرياً لإشعارات أوقات الصلاة، والتي تنطلق في وقت كل صلاة، واختياريًا قبلها بدقائق قليلة. تُجدول التذكيرات بالكامل على
الجهاز ولا تحمل أي بيانات شخصية. يمكنك تعطيلها في أي وقت من قسم **الإعدادات ← الإشعارات** في التطبيق.

## الأمان

نظراً لأن رفيق الصراط لا ينقل أي بيانات شخصية خارج جهازك، فلا توجد مخاطر تسرب بيانات على جانب الخادم. بياناتك المحلية
محمية بواسطة صندوق تطبيقات HarmonyOS، الذي يمنع التطبيقات الأخرى من قراءة التفضيلات المخزنة لرفيق الصراط.

## خصوصية الأطفال

رفيق الصراط مخصص لجمهور عام ومناسب للمستخدمين من جميع الأعمار. لا يجمع التطبيق أي معلومات شخصية من أي شخص، بما في ذلك
الأطفال، لأنه لا يجمع المعلومات الشخصية على الإطلاق.

## حقوقك

نظراً لأن التطبيق لا يجمع بياناتك أو ينقلها، فلا توجد بيانات علينا الإفصاح عنها أو تصحيحها أو حذفها من جانبنا. لديك
السيطرة الكاملة على بياناتك في جميع الأوقات:

- **الوصول:** جميع البيانات مرئية داخل التطبيق.
- **الحذف:** يؤدي إلغاء تثبيت التطبيق إلى إزالة جميع البيانات المخزنة.
- **القابلية للنقل:** يمكن عرض البيانات وإعادة إدخالها في أي وقت.
- **سحب الموافقة:** اسحب الأذونات من إعدادات جهازك.

## خدمات الأطراف الثالثة

رفيق الصراط **لا** يدمج أي تحليلات أو إعلانات أو خدمات تتبع تابعة لأطراف ثالثة.

## التغييرات في سياسة الخصوصية هذه

قد نحدّث سياسة الخصوصية هذه من وقت لآخر لتعكس التغييرات في التطبيق أو القوانين المعمول بها. عندما نجري تغييرات جوهرية،
سنقوم بتحديث تاريخ "آخر تحديث" في أعلى هذه الصفحة. يشكّل استمرار استخدام التطبيق بعد سريان التغييرات قبولاً للسياسة
المنقّحة.

## اتصل بنا

إذا كانت لديك أي أسئلة أو مخاوف أو طلبات بشأن سياسة الخصوصية هذه، يرجى الاتصال بنا على:

**البريد الإلكتروني:** sharjeel.butt@example.com
**المطوّر:** Sharjeel Butt

---

[العودة إلى الأعلى](#privacy-policy--sirat-companion)