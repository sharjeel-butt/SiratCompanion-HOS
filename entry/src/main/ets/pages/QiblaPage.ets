// entry/src/main/ets/pages/QiblaPage.ets

import { router } from '@kit.ArkUI';
import { mediaquery } from '@kit.ArkUI';
import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Theme, ThemeColors, ThemeMode } from '../common/Theme';
import { STORAGE_KEY_THEME_MODE } from '../common/StorageKeys';
import { QiblaCalculator } from '../utils/QiblaCalculator';
import { SettingsHelper } from '../utils/SettingsHelper';
import { LocationCache } from '../utils/LocationCache';

@Entry
@Component
struct QiblaPage {

  // ============================================================
  // THEME
  // ============================================================

  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;

  @State colors: ThemeColors = Theme.getColors(ThemeMode.LIGHT, false);
  private systemDarkListener: mediaquery.MediaQueryListener | null = null;

  // ============================================================
  // COMPASS STATE
  // ============================================================

  /** Device heading (0 = North). Rotates as the user turns. */
  @State deviceHeading: number = 0;

  /** Bearing to the Kaaba from the user's location. */
  @State qiblaBearing: number = 0;

  /** Distance to the Kaaba in km. */
  @State distanceKm: number = 0;

  /** True when sensor is calibrated / accurate. */
  @State sensorReady: boolean = false;

  /** True when the device is flat enough for a reliable reading. */
  @State isFlat: boolean = false;

  /** User's location. */
  @State latitude: number = 0;
  @State longitude: number = 0;
  @State cityName: string = '';

  /** Angle of the Qibla needle relative to the top of the screen. */
  @State qiblaNeedleAngle: number = 0;

  private sensorRegistered: boolean = false;

  // ============================================================
  // THEME HELPERS
  // ============================================================

  private isSystemDark(): boolean {
    try {
      const listener = mediaquery.matchMediaSync('(dark-mode: true)');
      return listener.matches;
    } catch (err) {
      return false;
    }
  }

  private applyTheme(): void {
    this.colors = Theme.getColors(this.themeMode, this.isSystemDark());
  }

  private onThemeModeChanged(): void {
    this.colors = Theme.getColors(this.themeMode, this.isSystemDark());
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  aboutToAppear(): void {
    this.applyTheme();

    try {
      this.systemDarkListener = mediaquery.matchMediaSync('(dark-mode: true)');
      this.systemDarkListener.on('change', (result: mediaquery.MediaQueryResult) => {
        if (this.themeMode === ThemeMode.SYSTEM) {
          this.colors = Theme.getColors(this.themeMode, result.matches);
        }
      });
    } catch (err) { /* ignore */ }

    this.loadLocation();
    this.registerSensor();
  }

  aboutToDisappear(): void {
    if (this.systemDarkListener) {
      this.systemDarkListener.off('change');
      this.systemDarkListener = null;
    }
    this.unregisterSensor();
  }

  onPageShow(): void {
    this.applyTheme();
    this.loadLocation();
  }

  // ============================================================
  // LOCATION
  // ============================================================

  private async loadLocation(): Promise<void> {
    // Try manual coordinates first
    const mode = await SettingsHelper.getLocationMode();

    // Manual mode
    if (mode.toString() === 'Manual') {
      const coords = await SettingsHelper.getManualCoords();
      if (coords.lat !== 0 || coords.lng !== 0) {
        this.latitude = coords.lat;
        this.longitude = coords.lng;
        this.cityName = coords.cityName.length > 0
          ? `${coords.cityName} (Manual)`
          : 'Manual Location';
        this.updateQibla();
        return;
      }
    }

    // GPS mode: use cached location
    const cached = await LocationCache.load();
    if (cached) {
      this.latitude = cached.latitude;
      this.longitude = cached.longitude;
      this.cityName = cached.cityName;
      this.updateQibla();
    } else {
      this.cityName = 'Location unavailable';
    }
  }

  private updateQibla(): void {
    if (this.latitude === 0 && this.longitude === 0) return;

    this.qiblaBearing = QiblaCalculator.calculateBearing(this.latitude, this.longitude);
    this.distanceKm = QiblaCalculator.calculateDistance(this.latitude, this.longitude);
    this.updateNeedleAngle();
  }

  private updateNeedleAngle(): void {
    // The compass rose is rotated by -deviceHeading.
    // The needle should point at (qiblaBearing - deviceHeading) relative to the screen top.
    this.qiblaNeedleAngle = (this.qiblaBearing - this.deviceHeading + 360) % 360;
  }

  // ============================================================
  // SENSOR
  // ============================================================

  private registerSensor(): void {
    try {
      // Orientation sensor combines magnetometer + accelerometer
      sensor.on(sensor.SensorId.ORIENTATION, (data: sensor.OrientationResponse) => {
        const heading = data.alpha; // 0–360, clockwise from North
        this.deviceHeading = heading;

        // "Flat" if beta and gamma are near 0 (device lying flat)
        const flat = Math.abs(data.beta) < 25 && Math.abs(data.gamma) < 25;
        this.isFlat = flat;

        this.sensorReady = true;
        this.updateNeedleAngle();
      }, { interval: 100000000 }); // 100ms

      this.sensorRegistered = true;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to register orientation sensor: ${error.code} — ${error.message}`);
      // Fall back to magnetometer-only heading
      this.registerMagnetometerFallback();
    }
  }

  private registerMagnetometerFallback(): void {
    try {
      sensor.on(sensor.SensorId.MAGNETIC_FIELD, (data: sensor.MagneticFieldResponse) => {
        let heading = Math.atan2(data.y, data.x) * 180 / Math.PI;
        heading = (heading + 360) % 360;
        this.deviceHeading = heading;
        this.sensorReady = true;
        this.isFlat = true;
        this.updateNeedleAngle();
      }, { interval: 100000000 });

      this.sensorRegistered = true;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to register magnetometer: ${error.code} — ${error.message}`);
      this.sensorReady = false;
    }
  }

  private unregisterSensor(): void {
    if (!this.sensorRegistered) return;
    try {
      sensor.off(sensor.SensorId.ORIENTATION);
    } catch (err) { /* ignore */ }
    try {
      sensor.off(sensor.SensorId.MAGNETIC_FIELD);
    } catch (err) { /* ignore */ }
    this.sensorRegistered = false;
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  private onFloatingBarTap(tabId: string): void {
    if (tabId === 'home') {
      // ✅ back() re-shows the existing Home instance — instant
      router.back();
      return;
    }
    if (tabId === 'tasbih') {
      // Replace current page — stack stays at [Home, Tasbih]
      router.replaceUrl({ url: 'pages/TasbihPage' })
        .catch((err: Error) => console.error('Navigation failed:', JSON.stringify(err)));
      return;
    }
    if (tabId === 'compass') {
      // Already here
      return;
    }
  }

  // ============================================================
  // FORMATTERS
  // ============================================================

  private formatDegree(deg: number): string {
    return `${Math.round(deg)}°`;
  }

  private formatDistance(km: number): string {
    if (km < 1) return `${Math.round(km * 1000)} m`;
    return `${Math.round(km).toLocaleString()} km`;
  }

  // ============================================================
  // BUILD
  // ============================================================

  build() {
    Stack() {
      Column() {
        // ---- Top bar ----
        Row() {
          Text('Qibla Compass')
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
            .margin({ left: 20 })
        }
        .width('100%').height(72).backgroundColor(this.colors.cardDark)
        .alignItems(VerticalAlign.Center)

        // ---- Body ----
        Scroll() {
          Column() {
            // Location pill
            Row() {
              Text('📍').fontSize(14)
              Text(this.cityName.length > 0 ? this.cityName : 'Loading...')
                .fontSize(14).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
                .margin({ left: 8 })
                .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .height(34)
            .padding({ left: 14, right: 14 })
            .backgroundColor(this.colors.cardDark)
            .borderRadius(17)
            .border({ width: 1, color: this.colors.borderSoft })
            .margin({ top: 20 })

            // Compass
            this.CompassView()

            // Direction info
            Column() {
              Row() {
                Text('Qibla Direction')
                  .fontSize(13).fontColor(this.colors.textMuted)
                  .layoutWeight(1)
                Text(this.formatDegree(this.qiblaBearing))
                  .fontSize(15).fontColor(this.colors.accentGold).fontWeight(FontWeight.Bold)
              }
              .width('100%').padding({ top: 8, bottom: 8 })

              Divider().color(this.colors.borderSoft).width('100%')

              Row() {
                Text('Device Heading')
                  .fontSize(13).fontColor(this.colors.textMuted)
                  .layoutWeight(1)
                Text(this.formatDegree(this.deviceHeading))
                  .fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
              }
              .width('100%').padding({ top: 8, bottom: 8 })

              Divider().color(this.colors.borderSoft).width('100%')

              Row() {
                Text('Distance to Kaaba')
                  .fontSize(13).fontColor(this.colors.textMuted)
                  .layoutWeight(1)
                Text(this.formatDistance(this.distanceKm))
                  .fontSize(15).fontColor(this.colors.accentGoldLight).fontWeight(FontWeight.Medium)
              }
              .width('100%').padding({ top: 8, bottom: 8 })
            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.colors.cardDark)
            .borderRadius(Theme.radiusMedium)
            .border({ width: 1, color: this.colors.borderSoft })
            .margin({ top: 20 })

            // Status / warnings
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

      // ============================================================
      // FLOATING BAR — 3 tabs (Home, Tasbih, Compass)
      // ============================================================
      Row() {
        Row() {
          // ---- Home ----
          Column() {
            Text('🏠')
              .fontSize(24)
              .opacity(0.7)

            Text('Home')
              .fontSize(11)
              .fontWeight(FontWeight.Normal)
              .fontColor(this.isSystemDark() ? 'rgba(241,245,249,0.65)' : 'rgba(26,26,26,0.55)')
              .margin({ top: 3 })
          }
          .layoutWeight(1)
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .onClick(() => { this.onFloatingBarTap('home'); })

          // Divider
          Divider()
            .vertical(true)
            .height(28)
            .color(this.isSystemDark() ? 'rgba(74,222,128,0.20)' : 'rgba(15,81,50,0.12)')

          // ---- Tasbih ----
          Column() {
            Text('📿')
              .fontSize(24)
              .opacity(0.7)

            Text('Tasbih')
              .fontSize(11)
              .fontWeight(FontWeight.Normal)
              .fontColor(this.isSystemDark() ? 'rgba(241,245,249,0.65)' : 'rgba(26,26,26,0.55)')
              .margin({ top: 3 })
          }
          .layoutWeight(1)
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .onClick(() => { this.onFloatingBarTap('tasbih'); })

          // Divider
          Divider()
            .vertical(true)
            .height(28)
            .color(this.isSystemDark() ? 'rgba(74,222,128,0.20)' : 'rgba(15,81,50,0.12)')

          // ---- Compass (active) ----
          Column() {
            Text('🧭')
              .fontSize(24)
              .opacity(1.0)

            Text('Compass')
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isSystemDark() ? '#4ADE80' : '#0F5132')
              .margin({ top: 3 })
          }
          .layoutWeight(1)
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .onClick(() => { this.onFloatingBarTap('compass'); })
        }
        .width('84%')
        .height(68)
        .backgroundBlurStyle(
          BlurStyle.Thin,
          {
            colorMode: this.isSystemDark() ? ThemeColorMode.DARK : ThemeColorMode.LIGHT,
            adaptiveColor: AdaptiveColor.DEFAULT,
            scale: 1.0
          }
        )
        .backgroundColor(
          this.isSystemDark()
            ? 'rgba(20, 27, 46, 0.50)'
            : 'rgba(255, 255, 255, 0.35)'
        )
        .borderRadius(34)
        .border({
          width: 1,
          color: this.isSystemDark()
            ? 'rgba(74, 222, 128, 0.35)'
            : 'rgba(255, 255, 255, 0.65)'
        })
        .shadow({
          radius: 28,
          color: this.isSystemDark()
            ? 'rgba(0, 0, 0, 0.50)'
            : 'rgba(0, 0, 0, 0.14)',
          offsetX: 0,
          offsetY: 10
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .position({ bottom: 24 })
    }
    .width('100%').height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  // ============================================================
  // COMPASS VIEW
  // ============================================================

  @Builder
  CompassView() {
    Stack() {
      // Rotating compass rose (rotates with device heading)
      Column() {
        this.CompassLabels()
      }
      .width(280).height(280)
      .rotate({ angle: -this.deviceHeading })
      .animation({ duration: 150, curve: Curve.Linear })

      // Static Qibla needle (rotates with qiblaNeedleAngle)
      Column() {
        Column() {
          // Kaaba icon
          Text('🕋')
            .fontSize(36)
            .margin({ bottom: -8 })

          // Needle line
          Column()
            .width(4)
            .height(90)
            .backgroundColor(this.colors.accentGold)
            .borderRadius(2)
        }
        .margin({ bottom: 140 })
      }
      .width(280).height(280)
      .rotate({ angle: this.qiblaNeedleAngle })
      .animation({ duration: 150, curve: Curve.Linear })

      // Center dot
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
    .margin({ top: 24 })
  }

  @Builder
  CompassLabels() {
    Stack() {
      // N (top)
      Text('N')
        .fontSize(18).fontWeight(FontWeight.Bold)
        .fontColor(this.colors.accentGold)
        .margin({ bottom: 240 })

      // S (bottom)
      Text('S')
        .fontSize(18).fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textMuted)
        .margin({ top: 240 })

      // E (right)
      Text('E')
        .fontSize(18).fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textMuted)
        .margin({ left: 240 })

      // W (left)
      Text('W')
        .fontSize(18).fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textMuted)
        .margin({ right: 240 })
    }
    .width(280).height(280)
  }

  // ============================================================
  // STATUS CARD
  // ============================================================

  @Builder
  StatusCard() {
    Column() {
      if (!this.sensorReady) {
        Row() {
          Text('⚠️').fontSize(16).margin({ right: 8 })
          Text('Compass sensor not available. Please test on a real device.')
            .fontSize(12).fontColor(this.colors.textMuted)
            .layoutWeight(1)
        }
        .width('100%')
      } else if (!this.isFlat) {
        Row() {
          Text('📐').fontSize(16).margin({ right: 8 })
          Text('Keep your device flat for accurate readings.')
            .fontSize(12).fontColor(this.colors.textMuted)
            .layoutWeight(1)
        }
        .width('100%')
      } else {
        Row() {
          Text('✅').fontSize(16).margin({ right: 8 })
          Text('Compass is ready. Rotate your device to align with the 🕋 marker.')
            .fontSize(12).fontColor(this.colors.textMuted)
            .layoutWeight(1)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.colors.tintSubtle)
    .borderRadius(12)
    .border({ width: 1, color: this.colors.borderSoft })
    .margin({ top: 16 })
  }
}