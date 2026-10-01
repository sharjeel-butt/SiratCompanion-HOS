// entry/src/main/ets/pages/QiblaPage.ets

import { router } from '@kit.ArkUI';
import { mediaquery } from '@kit.ArkUI';
import { Theme, ThemeColors, ThemeMode } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import {
  STORAGE_KEY_THEME_MODE,
  STORAGE_KEY_NAV_DIRECTION,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_APP_FOREGROUND_TICK
} from '../common/StorageKeys';
import { QiblaCalculator } from '../utils/QiblaCalculator';
import { QiblaSensorHelper, OrientationReading } from '../helper/QiblaSensorHelper';
import { SettingsHelper } from '../helper/SettingsHelper';
import { LocationCache } from '../utils/LocationCache';
import { LocationMode } from '../models/SettingsModels';
import { NavHelper } from '../helper/NavHelper';
import { L } from '../helper/LocalizationHelper';
import { OfflineCityLookup } from '../utils/OfflineCityLookup';
import { FloatingNavBar } from '../components/FloatingNavBar';

const SENSOR_INTERVAL_MS = 100;
const ROTATION_ANIM_MS = 90;
const HEADING_SMOOTHING = 0.35;

@Entry
@Component
struct QiblaPage {

  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;

  @StorageLink(STORAGE_KEY_NAV_DIRECTION)
  navDirection: string = 'forward';

  @StorageLink(STORAGE_KEY_LANGUAGE)
  @Watch('onLanguageChanged')
  appLanguage: string = 'en';
  @StorageLink(STORAGE_KEY_APP_FOREGROUND_TICK)
  @Watch('onAppForegrounded')
  appForegroundTick: number = 0;

  @State declinationDeg: number = 0;
  @State private currentLanguage: string = 'en';
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  private systemDarkListener: mediaquery.MediaQueryListener | null = null;

  @State private rawHeading: number = 0;
  @State private smoothedHeading: number = 0;
  @State private roseAngle: number = 0;
  @State private needleAngle: number = 0;

  @State qiblaBearing: number = 0;
  @State distanceKm: number = 0;
  @State sensorReady: boolean = false;
  @State isFlat: boolean = false;
  @State latitude: number = 0;
  @State longitude: number = 0;
  @State cityName: string = '';

  private firstReading: boolean = true;

  private tr(key: string): string {
    return L.get(key, this.currentLanguage);
  }

  private isRtl(): boolean {
    return L.isRtlLang(this.currentLanguage);
  }

  private onThemeModeChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onLanguageChanged(): void {
    this.currentLanguage = this.appLanguage;
  }

  private async onAppForegrounded(): Promise<void> {
    await this.loadLocation();
    if (!this.sensorReady) {
      const ok = QiblaSensorHelper.register((r: OrientationReading) => {
        this.rawHeading = r.heading;
        this.isFlat = r.isFlat;
        this.sensorReady = true;
        this.updateAngles(r.heading);
      });
      if (!ok) {
        this.sensorReady = false;
      }
    }
  }

  pageTransition() {
    PageTransitionEnter({ type: RouteType.Push, duration: 300, curve: Curve.Friction })
      .slide(this.navDirection === 'forward' ? SlideEffect.Right : SlideEffect.Left)
    PageTransitionExit({ type: RouteType.Push, duration: 300, curve: Curve.Friction })
      .slide(this.navDirection === 'forward' ? SlideEffect.Left : SlideEffect.Right)

    PageTransitionEnter({ type: RouteType.Pop, duration: 300, curve: Curve.Friction })
      .slide(SlideEffect.Left)
    PageTransitionExit({ type: RouteType.Pop, duration: 300, curve: Curve.Friction })
      .slide(SlideEffect.Right)
  }

  aboutToAppear(): void {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
    this.systemDarkListener = PageTheme.installSystemListener(this.themeMode, (c) => {
      this.colors = c;
    });

    this.loadLocation();

    const ok = QiblaSensorHelper.register((r: OrientationReading) => {
      this.rawHeading = r.heading;
      this.isFlat = r.isFlat;
      this.sensorReady = true;
      this.updateAngles(r.heading);
    });
    if (!ok) this.sensorReady = false;
  }

  aboutToDisappear(): void {
    PageTheme.uninstallSystemListener(this.systemDarkListener);
    this.systemDarkListener = null;
    QiblaSensorHelper.unregister();
  }

  onPageShow(): void {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
    this.loadLocation();
  }

  onBackPress(): boolean {
    NavHelper.prepareBackward();
    return false;
  }

  private shortestDelta(from: number, to: number): number {
    let d = to - from;
    while (d > 180)  d -= 360;
    while (d < -180) d += 360;
    return d;
  }

  private unwrap(current: number, target: number): number {
    return current + this.shortestDelta(current, target);
  }

  private updateAngles(rawHeading: number): void {
    if (this.firstReading) {
      this.smoothedHeading = rawHeading;
      const trueHeading = rawHeading + this.declinationDeg;
      this.roseAngle = -trueHeading;
      this.needleAngle = this.qiblaBearing - trueHeading;
      this.firstReading = false;
      return;
    }

    const hDelta = this.shortestDelta(this.smoothedHeading, rawHeading);
    this.smoothedHeading = (this.smoothedHeading + hDelta * HEADING_SMOOTHING + 360) % 360;

    const trueHeading = this.smoothedHeading + this.declinationDeg;

    const targetRose = -trueHeading;
    this.roseAngle = this.unwrap(this.roseAngle, targetRose);

    const targetNeedle = this.qiblaBearing - trueHeading;
    this.needleAngle = this.unwrap(this.needleAngle, targetNeedle);
  }

  private async loadLocation(): Promise<void> {
    const mode = await SettingsHelper.getLocationMode();

    if (mode === LocationMode.MANUAL) {
      const coords = await SettingsHelper.getManualCoords();
      if (coords.lat !== 0 || coords.lng !== 0) {
        this.latitude = coords.lat;
        this.longitude = coords.lng;
        this.cityName = coords.cityName.length > 0
          ? `${coords.cityName} (${this.tr('manual_location')})`
          : this.tr('manual_location');
        this.updateQibla();
        return;
      }
    }

    const cached = await LocationCache.load();
    if (cached) {
      this.latitude = cached.latitude;
      this.longitude = cached.longitude;
      this.cityName = cached.cityName;
      this.updateQibla();
    } else {
      this.cityName = this.tr('location_unavailable');
    }
  }

  private updateQibla(): void {
    if (this.latitude === 0 && this.longitude === 0) return;
    this.qiblaBearing = QiblaCalculator.calculateBearing(this.latitude, this.longitude);
    this.distanceKm = QiblaCalculator.calculateDistance(this.latitude, this.longitude);

    this.declinationDeg = OfflineCityLookup.declinationFor(this.latitude, this.longitude);

    const trueHeading = this.smoothedHeading + this.declinationDeg;
    const targetNeedle = this.qiblaBearing - trueHeading;
    this.needleAngle = this.unwrap(this.needleAngle, targetNeedle);
  }

  private onFloatingBarTap(tabId: string): void {
    if (tabId === 'compass') return;

    if (tabId === 'home') {
      NavHelper.prepareBackward();
      router.clear();
      router.replaceUrl({ url: 'pages/HomePage' })
        .catch((e: Error) => console.error('Navigation failed:', JSON.stringify(e)));
      return;
    }
    if (tabId === 'prayers') {
      NavHelper.prepareBackward();
      router.clear();
      router.replaceUrl({ url: 'pages/Prayer' })
        .catch((e: Error) => console.error('Navigation failed:', JSON.stringify(e)));
      return;
    }
    if (tabId === 'calendar') {
      NavHelper.prepare('calendar', 'compass');
      router.pushUrl({ url: 'pages/HijriCalendarPage' })
        .catch((e: Error) => console.error('Navigation failed:', JSON.stringify(e)));
      return;
    }
    if (tabId === 'tasbih') {
      NavHelper.prepare('tasbih', 'compass');
      router.pushUrl({ url: 'pages/TasbihPage' })
        .catch((e: Error) => console.error('Navigation failed:', JSON.stringify(e)));
    }
  }

  private openLocationSettings(): void {
    NavHelper.prepareForward();
    router.pushUrl({ url: 'pages/SettingsPage' })
      .catch((err: Error) => console.error('Navigation failed:', JSON.stringify(err)));
  }

  private formatDegree(deg: number): string {
    const d = ((deg % 360) + 360) % 360;
    return `${Math.round(d)}°`;
  }

  private formatDistance(km: number): string {
    if (km < 1) return `${Math.round(km * 1000)} m`;
    return `${Math.round(km).toLocaleString()} km`;
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Text(this.tr('title_qibla'))
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
            .margin({ left: 20 })
        }
        .width('100%').height(72).backgroundColor(this.colors.cardDark)
        .alignItems(VerticalAlign.Center)

        Scroll() {
          Column() {
            Row() {
              Text('📍').fontSize(14).flexShrink(0)
              Text(this.cityName.length > 0 ? this.cityName : this.tr('loading_location'))
                .fontSize(14).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
                .margin({ left: 8 })
                .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .constraintSize({ maxWidth: 260 })
            .height(38)
            .padding({ left: 14, right: 14 })
            .backgroundColor(this.colors.cardDark)
            .borderRadius(17)
            .border({ width: 1, color: this.colors.borderSoft })
            .margin({ top: 20 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => { this.openLocationSettings(); })

            this.CompassView()

            Column() {
              Row() {
                Text(this.tr('qibla_direction'))
                  .fontSize(13).fontColor(this.colors.textMuted)
                Blank()
                Text(this.formatDegree(this.qiblaBearing))
                  .fontSize(15).fontColor(this.colors.accentGold).fontWeight(FontWeight.Bold)
                  .direction(Direction.Ltr)
              }
              .width('100%').padding({ top: 8, bottom: 8 })

              Divider().color(this.colors.borderSoft).width('100%')

              Row() {
                Text(this.tr('device_heading'))
                  .fontSize(13).fontColor(this.colors.textMuted)
                Blank()
                Text(this.formatDegree(this.smoothedHeading))
                  .fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
                  .direction(Direction.Ltr)
              }
              .width('100%').padding({ top: 8, bottom: 8 })

              Divider().color(this.colors.borderSoft).width('100%')

              Row() {
                Text(this.tr('distance_to_kaaba'))
                  .fontSize(13).fontColor(this.colors.textMuted)
                Blank()
                Text(this.formatDistance(this.distanceKm))
                  .fontSize(15).fontColor(this.colors.accentGoldLight).fontWeight(FontWeight.Medium)
                  .direction(Direction.Ltr)
              }
              .width('100%').padding({ top: 8, bottom: 8 })
            }
            .width('100%').padding(16)
            .backgroundColor(this.colors.cardDark)
            .borderRadius(Theme.radiusMedium)
            .border({ width: 1, color: this.colors.borderSoft })
            .margin({ top: 20 })

            this.StatusCard()

            Column().height(140)
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
          .alignItems(HorizontalAlign.Center)
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor(this.colors.primaryGreen)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%').height('100%')
      .backgroundColor(this.colors.primaryGreen)

      FloatingNavBar({
        activeTab: 'compass',
        colors: this.colors,
        currentLanguage: this.currentLanguage,
        onTabTap: (id: string) => {
          this.onFloatingBarTap(id);
        }
      })
    }
    .width('100%').height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  CompassView() {
    Stack() {
      Column() {
        this.CompassLabels()
      }
      .width(280).height(280)
      .rotate({ angle: this.roseAngle })
      .animation({ duration: ROTATION_ANIM_MS, curve: Curve.Linear })

      Column() {
        Column() {
          Text('🕋').fontSize(36).margin({ bottom: -8 })
          Column()
            .width(4).height(90)
            .backgroundColor(this.colors.accentGold)
            .borderRadius(2)
        }
        .margin({ bottom: 140 })
      }
      .width(280).height(280)
      .rotate({ angle: this.needleAngle })
      .animation({ duration: ROTATION_ANIM_MS, curve: Curve.Linear })

      Column()
        .width(20).height(20)
        .backgroundColor(this.colors.accentGold)
        .borderRadius(10)
        .border({ width: 3, color: this.colors.cardDark })
        .shadow({ radius: 8, color: this.colors.shadowCard, offsetX: 0, offsetY: 2 })
    }
    .width(280).height(280)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(140)
    .border({ width: 2, color: this.colors.borderSoft })
    .shadow({ radius: 16, color: this.colors.shadowCard, offsetX: 0, offsetY: 4 })
    .direction(Direction.Ltr)
    .margin({ top: 24 })
  }

  @Builder
  CompassLabels() {
    Stack() {
      Text('N')
        .fontSize(18).fontWeight(FontWeight.Bold)
        .fontColor(this.colors.accentGold)
        .margin({ bottom: 240 })

      Text('S')
        .fontSize(18).fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textMuted)
        .margin({ top: 240 })

      Text('E')
        .fontSize(18).fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textMuted)
        .margin({ left: 240 })

      Text('W')
        .fontSize(18).fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textMuted)
        .margin({ right: 240 })
    }
    .width(280).height(280)
    .direction(Direction.Ltr)
  }

  @Builder
  StatusCard() {
    Column() {
      if (!this.sensorReady) {
        Row() {
          Text('⚠️').fontSize(16).margin({ right: 8 })
          Text(this.tr('sensor_unavailable'))
            .fontSize(12).fontColor(this.colors.textMuted).layoutWeight(1)
        }
        .width('100%')
      } else if (!this.isFlat) {
        Row() {
          Text('📐').fontSize(16).margin({ right: 8 })
          Text(this.tr('keep_device_flat'))
            .fontSize(12).fontColor(this.colors.textMuted).layoutWeight(1)
        }
        .width('100%')
      } else {
        Row() {
          Text('✅').fontSize(16).margin({ right: 8 })
          Text(this.tr('compass_ready'))
            .fontSize(12).fontColor(this.colors.textMuted).layoutWeight(1)
        }
        .width('100%')
      }
    }
    .width('100%').padding(14)
    .backgroundColor(this.colors.tintSubtle)
    .borderRadius(12)
    .border({ width: 1, color: this.colors.borderSoft })
    .margin({ top: 16 })
  }
}