// entry/src/main/ets/pages/WizardPage.ets

import { mediaquery, router } from '@kit.ArkUI';
import { Theme, ThemeColors, ThemeMode, ThemePreset } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import {
  STORAGE_KEY_APP_FOREGROUND_TICK,
  STORAGE_KEY_APP_THEME,
  STORAGE_KEY_BREAKPOINT,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_THEME_MODE
} from '../common/StorageKeys';
import { AsrShadowRule, CalculationMethod } from '../utils/PrayerTimeCalculator';
import { SettingsHelper } from '../helper/SettingsHelper';
import { LocationData, LocationHelper } from '../utils/LocationUtils';
import { LocationCache } from '../utils/LocationCache';
import { CalculationSource, LocationMode, PickerItem } from '../models/SettingsModels';
import { AppLanguage, L } from '../helper/LocalizationHelper';
import { NavHelper } from '../helper/NavHelper';
import { PrivacyPolicyProvider } from '../data/PrivacyPolicy';
import { Breakpoints } from '../common/Breakpoints';

const TOTAL_STEPS = 5;

interface LanguageOption {
  id: string;
  nativeName: string;
  englishName: string;
}

interface ThemeOption {
  id: string;
  nameKey: string;
  descKey: string;
}

@Entry
@Component
struct WizardPage {

  // ============================================================
  // STORAGE LINKS
  // ============================================================

  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;

  @StorageLink(STORAGE_KEY_LANGUAGE)
  @Watch('onLanguageChanged')
  appLanguage: string = AppLanguage.ENGLISH;

  @StorageLink(STORAGE_KEY_APP_THEME)
  @Watch('onAppThemeChanged')
  appTheme: string = ThemePreset.CURRENT;
  @StorageLink(STORAGE_KEY_APP_FOREGROUND_TICK)
  @Watch('onAppForegrounded')
  appForegroundTick: number = 0;
  @StorageLink(STORAGE_KEY_BREAKPOINT)
  breakpoint: string = 'sm';

  @State private currentLanguage: string = AppLanguage.ENGLISH;
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  private systemDarkListener: mediaquery.MediaQueryListener | null = null;

  // ============================================================
  // WIZARD STATE
  // ============================================================

  @State step: number = 0;

  // ---- Step 0: language ----
  @State selectedLanguage: string = AppLanguage.ENGLISH;

  // ---- Step 1: privacy policy ----
  @State privacyAccepted: boolean = false;

  // ---- Step 2: theme ----
  @State selectedTheme: string = ThemePreset.CURRENT;

  // ---- Step 3: location ----
  @State locationMode: LocationMode = LocationMode.GPS;
  @State manualLat: string = '';
  @State manualLng: string = '';
  @State manualCity: string = '';
  @State isGettingLocation: boolean = false;
  @State locationStatus: string = 'idle';
  @State detectedCity: string = '';

  // ---- Step 4: calculation ----
  @State calcMethod: CalculationMethod = CalculationMethod.KARACHI;
  @State asrRule: AsrShadowRule = AsrShadowRule.STANDARD;
  @State calcSource: CalculationSource = CalculationSource.LOCAL;
  @State showMethodPicker: boolean = false;
  @State showAsrPicker: boolean = false;
  @State showSourcePicker: boolean = false;

  // ============================================================
  // LOCALIZATION + DIRECTION + BREAKPOINT HELPERS
  // ============================================================

  private tr(key: string): string {
    return L.get(key, this.currentLanguage);
  }

  private isRtl(): boolean {
    return L.isRtlLang(this.currentLanguage);
  }

  private isTablet(): boolean {
    return Breakpoints.isTablet(this.breakpoint);
  }

  // ============================================================
  // WATCHERS
  // ============================================================

  private onThemeModeChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onLanguageChanged(): void {
    this.currentLanguage = this.appLanguage;
  }

  private onAppThemeChanged(): void {
    // Recompute the wizard's palette the instant a new theme is picked.
    this.colors = PageTheme.compute(this.themeMode);
    this.selectedTheme = this.appTheme;
  }

  private async onAppForegrounded(): Promise<void> {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
    this.selectedTheme = await SettingsHelper.getAppTheme();
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  aboutToAppear(): void {
    this.currentLanguage = this.appLanguage;
    this.selectedLanguage = this.appLanguage;
    this.selectedTheme = this.appTheme;
    this.colors = PageTheme.compute(this.themeMode);
    this.systemDarkListener = PageTheme.installSystemListener(this.themeMode, (c) => {
      this.colors = c;
    });

    this.reloadDefaults();
  }

  aboutToDisappear(): void {
    PageTheme.uninstallSystemListener(this.systemDarkListener);
    this.systemDarkListener = null;
  }

  onPageShow(): void {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
  }

  private async reloadDefaults(): Promise<void> {
    const data = await SettingsHelper.loadAll();
    this.calcMethod = data.method;
    this.asrRule = data.asr;
    this.calcSource = data.source;
    this.locationMode = await SettingsHelper.getLocationMode();
    this.selectedTheme = await SettingsHelper.getAppTheme();
  }

  // ============================================================
  // PAGE TRANSITION
  // ============================================================

  pageTransition() {
    PageTransitionEnter({ type: RouteType.Push, duration: 300, curve: Curve.Friction })
      .opacity(0)
    PageTransitionExit({ type: RouteType.Push, duration: 300, curve: Curve.Friction })
      .opacity(0)

    PageTransitionEnter({ type: RouteType.Pop, duration: 300, curve: Curve.Friction })
      .opacity(0)
    PageTransitionExit({ type: RouteType.Pop, duration: 300, curve: Curve.Friction })
      .opacity(0)
  }

  // ============================================================
  // STEP NAVIGATION
  // ============================================================

  private canProceed(): boolean {
    // Step 1 (privacy) requires acceptance.
    if (this.step === 1 && !this.privacyAccepted) {
      return false;
    }
    return true;
  }

  private goNext(): void {
    if (!this.canProceed()) {
      return;
    }

    if (this.step < TOTAL_STEPS - 1) {
      this.step = this.step + 1;
      return;
    }
    this.finish();
  }

  private goBack(): void {
    if (this.step <= 0) return;
    this.step = this.step - 1;
  }

  private finish(): void {
    SettingsHelper.markWizardCompleted();
    NavHelper.prepareForward();
    router.replaceUrl({ url: 'pages/HomePage' })
      .catch((err: Error) => console.error('Wizard finish failed:', JSON.stringify(err)));
  }

  // ============================================================
  // STEP 0 — LANGUAGE
  // ============================================================

  private getLanguageOptions(): LanguageOption[] {
    const en: LanguageOption = {
      id: AppLanguage.ENGLISH, nativeName: 'English', englishName: 'English'
    };
    const zh: LanguageOption = {
      id: AppLanguage.CHINESE, nativeName: '中文', englishName: 'Chinese'
    };
    const ar: LanguageOption = {
      id: AppLanguage.ARABIC, nativeName: 'العربية', englishName: 'Arabic'
    };
    return [en, zh, ar];
  }

  private pickLanguage(id: string): void {
    this.selectedLanguage = id;
    this.appLanguage = id;
    this.currentLanguage = id;
    SettingsHelper.saveLanguage(id);
  }

  // ============================================================
  // STEP 1 — PRIVACY POLICY
  // ============================================================

  private getPrivacyPolicyText(): string {
    return PrivacyPolicyProvider.get(this.currentLanguage);
  }

  // ============================================================
  // STEP 2 — THEME
  // ============================================================

  private getThemeOptions(): ThemeOption[] {
    const current: ThemeOption = {
      id: ThemePreset.CURRENT,
      nameKey: 'theme_preset_current',
      descKey: 'theme_preset_current_desc'
    };
    const h7: ThemeOption = {
      id: ThemePreset.HARMONY_7,
      nameKey: 'theme_preset_harmony7',
      descKey: 'theme_preset_harmony7_desc'
    };
    const h6: ThemeOption = {
      id: ThemePreset.HARMONY_6,
      nameKey: 'theme_preset_harmony6',
      descKey: 'theme_preset_harmony6_desc'
    };
    const h5: ThemeOption = {
      id: ThemePreset.HARMONY_5,
      nameKey: 'theme_preset_harmony5',
      descKey: 'theme_preset_harmony5_desc'
    };
    return [current, h7, h6, h5];
  }

  /**
   * Applies the theme immediately — both to the persisted setting
   * and to the wizard's own colours.
   */
  private pickAppTheme(id: string): void {
    this.selectedTheme = id;
    this.appTheme = id;
    SettingsHelper.saveAppTheme(id);
    this.colors = PageTheme.compute(this.themeMode);
  }

  /** Preview swatch — accent colour for the current mode. */
  private themePreviewSwatch(preset: string): string {
    const preview = Theme.getColors(
      this.themeMode,
      PageTheme.isSystemDark(),
      preset
    );
    return preview.accentGold;
  }

  /** Preview background — page background for the current mode. */
  private themePreviewBackground(preset: string): string {
    const preview = Theme.getColors(
      this.themeMode,
      PageTheme.isSystemDark(),
      preset
    );
    return preview.primaryGreen;
  }

  // ============================================================
  // STEP 3 — LOCATION
  // ============================================================

  private async requestGpsLocation(): Promise<void> {
    if (this.isGettingLocation) return;
    this.isGettingLocation = true;
    this.locationStatus = 'idle';
    this.detectedCity = '';

    try {
      const data: LocationData = await LocationHelper.fetchLocationData(getContext(this));
      await LocationCache.save(data.latitude, data.longitude, data.cityName);
      await SettingsHelper.saveLocationMode(LocationMode.GPS);

      this.detectedCity = data.cityName;
      this.locationStatus = 'ready';
    } catch (err) {
      const error = err as Error;
      this.locationStatus = 'failed';
      if (error.message === 'GPS_OFF') {
        await LocationHelper.showLocationDisabledDialog();
      } else if (error.message === 'PERMISSION_DENIED') {
        await LocationHelper.showPermissionDeniedDialog();
      }
    } finally {
      this.isGettingLocation = false;
    }
  }

  private async saveManualCoords(): Promise<void> {
    const lat = parseFloat(this.manualLat.trim());
    const lng = parseFloat(this.manualLng.trim());

    if (isNaN(lat) || lat < -90 || lat > 90) {
      this.getUIContext().getPromptAction().showToast({
        message: this.tr('latitude_hint'), duration: 2500
      });
      return;
    }
    if (isNaN(lng) || lng < -180 || lng > 180) {
      this.getUIContext().getPromptAction().showToast({
        message: this.tr('longitude_hint'), duration: 2500
      });
      return;
    }

    this.isGettingLocation = true;

    let cityName = this.manualCity.trim();
    if (cityName.length === 0) {
      try { cityName = await LocationHelper.reverseGeocode(lat, lng); } catch (e) { }
      if (cityName === 'Unknown location' || cityName.length === 0) {
        cityName = `${lat.toFixed(2)}, ${lng.toFixed(2)}`;
      }
    }

    await SettingsHelper.saveManualCoords(lat, lng, cityName);
    await SettingsHelper.saveLocationMode(LocationMode.MANUAL);
    this.isGettingLocation = false;

    this.detectedCity = cityName;
    this.locationStatus = 'ready';

    this.getUIContext().getPromptAction().showToast({
      message: `${this.tr('save')}: ${cityName}`, duration: 2000
    });
  }

  private async selectLocationMode(mode: LocationMode): Promise<void> {
    this.locationMode = mode;
    this.locationStatus = 'idle';
    this.detectedCity = '';

    if (mode === LocationMode.GPS) {
      return;
    }
    SettingsHelper.saveLocationMode(mode);
  }

  // ============================================================
  // STEP 4 — CALCULATION
  // ============================================================

  private pickMethod(id: string): void {
    const method = id as CalculationMethod;
    this.calcMethod = method;
    SettingsHelper.saveMethod(method);
    this.showMethodPicker = false;
  }

  private pickAsrRule(id: string): void {
    const rule = Number(id) as AsrShadowRule;
    this.asrRule = rule;
    SettingsHelper.saveAsrRule(rule);
    this.showAsrPicker = false;
  }

  private pickSource(id: string): void {
    const source = id as CalculationSource;
    if (source === CalculationSource.API) {
      this.getUIContext().getPromptAction().showToast({
        message: this.tr('coming_soon'), duration: 1500
      });
      return;
    }
    this.calcSource = source;
    SettingsHelper.saveSource(source);
    this.showSourcePicker = false;
  }

  // ============================================================
  // HEADER TEXT
  // ============================================================

  private stepTitle(): string {
    if (this.step === 0) return this.tr('wizard_language_title');
    if (this.step === 1) {
      return this.tr('wizard_privacy_title');
    }
    if (this.step === 2) {
      return this.tr('wizard_theme_title');
    }
    if (this.step === 3) {
      return this.tr('wizard_location_title');
    }
    return this.tr('wizard_convention_title');
  }

  private stepDescription(): string {
    if (this.step === 0) return this.tr('wizard_language_desc');
    if (this.step === 1) {
      return this.tr('wizard_privacy_desc');
    }
    if (this.step === 2) {
      return this.tr('wizard_theme_desc');
    }
    if (this.step === 3) {
      return this.tr('wizard_location_desc');
    }
    return this.tr('wizard_convention_desc');
  }

  // ============================================================
  // BUILD
  // ============================================================

  build() {
    Stack() {
      Column()
        .width('100%').height('100%')
        .backgroundColor(this.colors.primaryGreen)

      Column() {
        this.ProgressHeader()

        // Constrained content wrapper for tablet.
        Row() {
          Column() {
            // ---- Title + description ----
            Column() {
              Text(this.stepTitle())
                .fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
                .width('100%')
              Text(this.stepDescription())
                .fontSize(13)
                .fontColor(this.colors.textMuted)
                .width('100%')
                .margin({ top: 6 })
                .lineHeight(20)
            }
            .width('100%')
            .padding({
              left: this.isTablet() ? 32 : 24,
              right: this.isTablet() ? 32 : 24,
              top: 8,
              bottom: 16
            })
            .alignItems(HorizontalAlign.Start)

            // ---- Step content ----
            if (this.step === 0) {
              this.LanguageStep()
            } else if (this.step === 1) {
              this.PrivacyStep()
            } else if (this.step === 2) {
              this.ThemeStep()
            } else if (this.step === 3) {
              this.LocationStep()
            } else {
              this.ConventionStep()
            }
          }
          .width('100%')
          .constraintSize({ maxWidth: this.isTablet() ? 720 : 100000 })
          .layoutWeight(1)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)

        // Constrained footer for tablet.
        Row() {
          Column() {
            this.Footer()
          }
          .width('100%')
          .constraintSize({ maxWidth: this.isTablet() ? 720 : 100000 })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%').height('100%')

      if (this.showMethodPicker) {
        this.PickerOverlay(
          this.tr('convention'), '🕌',
          SettingsHelper.buildMethodPickerItems(this.calcMethod),
          (id: string) => { this.pickMethod(id); },
          () => { this.showMethodPicker = false; }
        )
      }
      if (this.showAsrPicker) {
        this.PickerOverlay(
          this.tr('madhab'), '🌅',
          SettingsHelper.buildAsrPickerItems(this.asrRule),
          (id: string) => { this.pickAsrRule(id); },
          () => { this.showAsrPicker = false; }
        )
      }
      if (this.showSourcePicker) {
        this.PickerOverlay(
          this.tr('source'), '🌐',
          SettingsHelper.buildSourcePickerItems(this.calcSource),
          (id: string) => { this.pickSource(id); },
          () => { this.showSourcePicker = false; }
        )
      }
    }
    .width('100%').height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  // ============================================================
  // PROGRESS HEADER
  // ============================================================

  @Builder
  ProgressHeader() {
    Row() {
      Text('←')
        .fontSize(22)
        .fontColor(this.step === 0 ? this.colors.textMuted : this.colors.textWhite)
        .width(40).height(40).textAlign(TextAlign.Center)
        .borderRadius(20)
        .backgroundColor(this.step === 0 ? 'transparent' : this.colors.tintSoft)
        .border(this.step === 0
          ? { width: 0 }
          : { width: 1, color: this.colors.borderSoft })
        .margin({ left: 16 })
        .enabled(this.step > 0)
        .onClick(() => { this.goBack(); })

      Blank()

      Row({ space: 6 }) {
        Text(this.tr('wizard_step'))
          .fontSize(12).fontColor(this.colors.textMuted).letterSpacing(1)
        Text(`${this.step + 1} / ${TOTAL_STEPS}`)
          .fontSize(12).fontColor(this.colors.accentGold).fontWeight(FontWeight.Bold)
          .direction(Direction.Ltr)
      }
      .margin({ right: 20 })
    }
    .width('100%').height(72)
    .alignItems(VerticalAlign.Center)
  }

  // ============================================================
  // STEP 0 — LANGUAGE
  // ============================================================

  @Builder
  LanguageStep() {
    Scroll() {
      Column() {
        Column() {
          Text(this.tr('wizard_welcome_title'))
            .fontSize(15).fontColor(this.colors.accentGold).fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.tr('wizard_welcome_desc'))
            .fontSize(12)
            .fontColor(this.colors.textMuted)
            .width('100%')
            .margin({ top: 4 })
            .lineHeight(18)
        }
        .width('100%')
        .padding(14)
        .backgroundColor(this.colors.tintSubtle)
        .borderRadius(12)
        .border({ width: 1, color: this.colors.borderSoft })
        .margin({ bottom: 16 })
        .alignItems(HorizontalAlign.Start)

        ForEach(this.getLanguageOptions(), (opt: LanguageOption) => {
          Row() {
            Column() {
              Text(opt.nativeName)
                .fontSize(18).fontWeight(FontWeight.Bold)
                .fontColor(this.colors.textWhite)
                .width('100%')
              Text(opt.englishName)
                .fontSize(11).fontColor(this.colors.textMuted)
                .margin({ top: 2 }).width('100%')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Stack() {
              if (opt.id === this.selectedLanguage) {
                Row().width(12).height(12).borderRadius(6)
                  .backgroundColor(this.colors.accentGold)
              }
            }
            .width(24)
            .height(24)
            .borderRadius(12)
            .border({
              width: opt.id === this.selectedLanguage ? 2 : 1.5,
              color: opt.id === this.selectedLanguage
                ? this.colors.accentGold
                : this.colors.borderStrong
            })
            .alignContent(Alignment.Center)
          }
          .width('100%')
          .padding({
            top: 16,
            bottom: 16,
            left: 16,
            right: 16
          })
          .backgroundColor(this.colors.cardDark)
          .borderRadius(14)
          .border({
            width: opt.id === this.selectedLanguage ? 2 : 1,
            color: opt.id === this.selectedLanguage
              ? this.colors.accentGold
              : this.colors.borderSoft
          })
          .margin({ bottom: 10 })
          .onClick(() => {
            this.pickLanguage(opt.id);
          })
        }, (opt: LanguageOption) =>
        `lang-${opt.id}-${opt.id === this.selectedLanguage ? 'sel' : 'un'}`)
      }
      .width('100%')
      .padding({
        left: this.isTablet() ? 32 : 24,
        right: this.isTablet() ? 32 : 24,
        bottom: 24
      })
    }
    .layoutWeight(1)
    .width('100%')
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
  }

  // ============================================================
  // STEP 1 — PRIVACY POLICY
  // ============================================================

  @Builder
  PrivacyStep() {
    Column() {
      Scroll() {
        Column() {
          Text(this.getPrivacyPolicyText())
            .fontSize(13)
            .fontColor(this.colors.textWhite)
            .lineHeight(20)
            .width('100%')
            .textAlign(TextAlign.Start)
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor(this.colors.cardDark)
      .borderRadius(14)
      .border({ width: 1, color: this.colors.borderSoft })
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)

      Row() {
        Stack() {
          if (this.privacyAccepted) {
            Text('✓')
              .fontSize(14)
              .fontColor(this.colors.textOnAccent)
              .fontWeight(FontWeight.Bold)
          }
        }
        .width(24)
        .height(24)
        .borderRadius(6)
        .backgroundColor(this.privacyAccepted
          ? this.colors.accentGold
          : 'transparent')
        .border({
          width: this.privacyAccepted ? 0 : 1.5,
          color: this.colors.borderStrong
        })
        .alignContent(Alignment.Center)
        .onClick(() => {
          this.privacyAccepted = !this.privacyAccepted;
        })

        Text(this.tr('privacy_agree_label'))
          .fontSize(13)
          .fontColor(this.colors.textWhite)
          .margin({ left: 12 })
          .layoutWeight(1)
          .onClick(() => {
            this.privacyAccepted = !this.privacyAccepted;
          })
      }
      .width('100%')
      .padding({ top: 16, bottom: 8 })
      .alignItems(VerticalAlign.Center)

      Row() {
        Text(this.tr('privacy_view_full'))
          .fontSize(11)
          .fontColor(this.colors.accentGold)
          .decoration({ type: TextDecorationType.Underline })
      }
      .width('100%')
      .padding({ bottom: 4 })
      .justifyContent(FlexAlign.Start)
      .onClick(() => {
        this.getUIContext().getPromptAction().showToast({
          message: PrivacyPolicyProvider.FULL_URL, duration: 3000
        });
      })
    }
    .width('100%')
    .layoutWeight(1)
    .padding({
      left: this.isTablet() ? 32 : 24,
      right: this.isTablet() ? 32 : 24,
      bottom: 12
    })
  }

  // ============================================================
  // STEP 2 — THEME
  // ============================================================

  @Builder
  ThemeStep() {
    Scroll() {
      Column() {
        ForEach(this.getThemeOptions(), (opt: ThemeOption) => {
          Row() {
            // ---- Preview swatch: mini card in the theme's colours ----
            Stack() {
              Column()
                .width('100%').height('100%')
                .backgroundColor(this.themePreviewBackground(opt.id))
                .borderRadius(10)

              Row()
                .width(18).height(18).borderRadius(9)
                .backgroundColor(this.themePreviewSwatch(opt.id))
            }
            .width(56).height(56)
            .borderRadius(10)
            .border({
              width: opt.id === this.selectedTheme ? 2 : 1,
              color: opt.id === this.selectedTheme
                ? this.colors.accentGold
                : this.colors.borderSoft
            })

            Column() {
              Text(this.tr(opt.nameKey))
                .fontSize(16).fontWeight(FontWeight.Bold)
                .fontColor(opt.id === this.selectedTheme
                  ? this.colors.accentGold
                  : this.colors.textWhite)
                .width('100%')
              Text(this.tr(opt.descKey))
                .fontSize(11)
                .fontColor(this.colors.textMuted)
                .margin({ top: 4 })
                .width('100%')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1).margin({ left: 14 })

            // ---- Selection indicator ----
            Stack() {
              if (opt.id === this.selectedTheme) {
                Text('✓')
                  .fontSize(14)
                  .fontColor(this.colors.textOnAccent)
                  .fontWeight(FontWeight.Bold)
              }
            }
            .width(24)
            .height(24)
            .borderRadius(12)
            .backgroundColor(opt.id === this.selectedTheme
              ? this.colors.accentGold
              : 'transparent')
            .border({
              width: opt.id === this.selectedTheme ? 0 : 1.5,
              color: this.colors.borderStrong
            })
            .alignContent(Alignment.Center)
          }
          .width('100%')
          .padding({
            top: 14,
            bottom: 14,
            left: 14,
            right: 14
          })
          .backgroundColor(this.colors.cardDark)
          .borderRadius(14)
          .border({
            width: opt.id === this.selectedTheme ? 2 : 1,
            color: opt.id === this.selectedTheme
              ? this.colors.accentGold
              : this.colors.borderSoft
          })
          .margin({ bottom: 10 })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.pickAppTheme(opt.id);
          })
        }, (opt: ThemeOption) =>
        `theme-${opt.id}-${opt.id === this.selectedTheme ? 'sel' : 'un'}`)
      }
      .width('100%')
      .padding({
        left: this.isTablet() ? 32 : 24,
        right: this.isTablet() ? 32 : 24,
        bottom: 24
      })
    }
    .layoutWeight(1)
    .width('100%')
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
  }

  // ============================================================
  // STEP 3 — LOCATION
  // ============================================================

  @Builder
  LocationStep() {
    Scroll() {
      Column() {
        Row() {
          this.LocationModeButton(this.tr('gps'), LocationMode.GPS)
          this.LocationModeButton(this.tr('manual_location'), LocationMode.MANUAL)
        }
        .width('100%')
        .padding({ bottom: 16 })

        if (this.locationMode === LocationMode.GPS) {
          Column() {
            if (this.locationStatus === 'ready' && this.detectedCity.length > 0) {
              Row() {
                Text('✅').fontSize(20)
                Column() {
                  Text(this.tr('wizard_location_ready'))
                    .fontSize(12).fontColor(this.colors.accentGold).fontWeight(FontWeight.Medium)
                    .width('100%')
                  Text(this.detectedCity)
                    .fontSize(15)
                    .fontColor(this.colors.textWhite)
                    .fontWeight(FontWeight.Bold)
                    .margin({ top: 2 })
                    .width('100%')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1).margin({ left: 12 })
              }
              .width('100%')
              .padding(16)
              .backgroundColor(this.colors.cardDark)
              .borderRadius(14)
              .border({ width: 1, color: this.colors.borderSoft })

              Button(this.tr('wizard_retry'))
                .width('100%')
                .height(44)
                .fontSize(14)
                .fontColor(this.colors.accentGold)
                .backgroundColor(this.colors.tintSoft)
                .borderRadius(10)
                .margin({ top: 12 })
                .onClick(() => {
                  this.requestGpsLocation();
                })
            } else if (this.locationStatus === 'failed') {
              Column() {
                Text('⚠️').fontSize(40).margin({ bottom: 10 })
                Text(this.tr('wizard_location_failed'))
                  .fontSize(14).fontColor(this.colors.textWhite)
                  .textAlign(TextAlign.Center)
                Button(this.tr('wizard_retry'))
                  .width('100%')
                  .height(44)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.colors.textOnAccent)
                  .backgroundColor(this.colors.accentGold)
                  .borderRadius(10)
                  .margin({ top: 16 })
                  .onClick(() => {
                    this.requestGpsLocation();
                  })
              }
              .width('100%')
              .padding(20)
              .backgroundColor(this.colors.cardDark)
              .borderRadius(14)
              .border({ width: 1, color: this.colors.borderSoft })
              .alignItems(HorizontalAlign.Center)
            } else {
              Column() {
                Text('📍').fontSize(48).margin({ bottom: 12 })
                Text(this.isGettingLocation
                  ? this.tr('wizard_getting_location')
                  : this.tr('wizard_location_desc'))
                  .fontSize(12).fontColor(this.colors.textMuted)
                  .textAlign(TextAlign.Center).lineHeight(18)

                Button() {
                  if (this.isGettingLocation) {
                    Row() {
                      LoadingProgress().width(18).height(18).color(this.colors.textOnAccent)
                      Text(this.tr('wizard_getting_location'))
                        .fontSize(14).fontColor(this.colors.textOnAccent).margin({ left: 8 })
                    }
                  } else {
                    Text(this.tr('wizard_grant_permission'))
                      .fontSize(14).fontWeight(FontWeight.Medium)
                      .fontColor(this.colors.textOnAccent)
                  }
                }
                .width('100%')
                .height(46)
                .backgroundColor(this.colors.accentGold)
                .borderRadius(10)
                .margin({ top: 20 })
                .enabled(!this.isGettingLocation)
                .onClick(() => {
                  this.requestGpsLocation();
                })
              }
              .width('100%')
              .padding(20)
              .backgroundColor(this.colors.cardDark)
              .borderRadius(14)
              .border({ width: 1, color: this.colors.borderSoft })
              .alignItems(HorizontalAlign.Center)
            }
          }
          .width('100%')
        } else {
          Column() {
            Column() {
              Text(this.tr('latitude_hint')).fontSize(11).fontColor(this.colors.textMuted)
                .width('100%').margin({ bottom: 4 })
              TextInput({ text: this.manualLat, placeholder: 'e.g. 33.6844' })
                .type(InputType.Normal)
                .inputFilter('[\\-0-9\\.]')
                .direction(Direction.Ltr)
                .onChange((value: string) => {
                  this.manualLat = value;
                })
                .fontSize(14)
                .fontColor(this.colors.textWhite)
                .placeholderColor(this.colors.placeholder)
                .caretColor(this.colors.accentGold)
                .backgroundColor(this.colors.tintSoft)
                .borderRadius(8)
                .padding({
                  left: 12,
                  right: 12,
                  top: 8,
                  bottom: 8
                })
            }
            .width('100%').margin({ bottom: 10 })

            Column() {
              Text(this.tr('longitude_hint')).fontSize(11).fontColor(this.colors.textMuted)
                .width('100%').margin({ bottom: 4 })
              TextInput({ text: this.manualLng, placeholder: 'e.g. 73.0479' })
                .type(InputType.Normal)
                .inputFilter('[\\-0-9\\.]')
                .direction(Direction.Ltr)
                .onChange((value: string) => {
                  this.manualLng = value;
                })
                .fontSize(14)
                .fontColor(this.colors.textWhite)
                .placeholderColor(this.colors.placeholder)
                .caretColor(this.colors.accentGold)
                .backgroundColor(this.colors.tintSoft)
                .borderRadius(8)
                .padding({
                  left: 12,
                  right: 12,
                  top: 8,
                  bottom: 8
                })
            }
            .width('100%').margin({ bottom: 10 })

            Column() {
              Text(this.tr('city_name_optional')).fontSize(11).fontColor(this.colors.textMuted)
                .width('100%').margin({ bottom: 4 })
              TextInput({ text: this.manualCity, placeholder: this.tr('city_name_placeholder') })
                .type(InputType.Normal)
                .onChange((value: string) => {
                  this.manualCity = value;
                })
                .fontSize(14)
                .fontColor(this.colors.textWhite)
                .placeholderColor(this.colors.placeholder)
                .caretColor(this.colors.accentGold)
                .backgroundColor(this.colors.tintSoft)
                .borderRadius(8)
                .padding({
                  left: 12,
                  right: 12,
                  top: 8,
                  bottom: 8
                })
            }
            .width('100%').margin({ bottom: 14 })

            Button() {
              if (this.isGettingLocation) {
                LoadingProgress().width(18).height(18).color(this.colors.textOnAccent)
              } else {
                Text(this.tr('save_coordinates'))
                  .fontSize(14).fontWeight(FontWeight.Medium)
                  .fontColor(this.colors.textOnAccent)
              }
            }
            .width('100%')
            .height(46)
            .backgroundColor(this.colors.accentGold)
            .borderRadius(10)
            .enabled(!this.isGettingLocation)
            .onClick(() => {
              this.saveManualCoords();
            })

            if (this.locationStatus === 'ready' && this.detectedCity.length > 0) {
              Row() {
                Text('✅').fontSize(16)
                Text(this.detectedCity)
                  .fontSize(13)
                  .fontColor(this.colors.accentGold)
                  .fontWeight(FontWeight.Medium)
                  .margin({ left: 8 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%').margin({ top: 12 })
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor(this.colors.cardDark)
          .borderRadius(14)
          .border({ width: 1, color: this.colors.borderSoft })
        }
      }
      .width('100%')
      .padding({
        left: this.isTablet() ? 32 : 24,
        right: this.isTablet() ? 32 : 24,
        bottom: 24
      })
    }
    .layoutWeight(1)
    .width('100%')
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  LocationModeButton(label: string, mode: LocationMode) {
    Text(label)
      .fontSize(13)
      .fontWeight(this.locationMode === mode ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.locationMode === mode
        ? this.colors.textOnAccent
        : this.colors.textWhite)
      .backgroundColor(this.locationMode === mode
        ? this.colors.accentGold
        : this.colors.tintSoft)
      .textAlign(TextAlign.Center)
      .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      .height(42).layoutWeight(1).borderRadius(10)
      .border(this.locationMode === mode
        ? { width: 0 }
        : { width: 1, color: this.colors.borderSoft })
      .margin({
        right: mode === LocationMode.GPS ? 6 : 0,
        left: mode === LocationMode.MANUAL ? 6 : 0
      })
      .onClick(() => { this.selectLocationMode(mode); })
  }

  // ============================================================
  // STEP 4 — CONVENTION / MADHAB / SOURCE
  // ============================================================

  @Builder
  ConventionStep() {
    Scroll() {
      Column() {
        Row() {
          Column() {
            Text(this.tr('convention'))
              .fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
            Text(this.tr('convention_desc'))
              .fontSize(11).fontColor(this.colors.textMuted).margin({ top: 2 })
            Text(SettingsHelper.getCalcMethodLabel(this.calcMethod))
              .fontSize(12)
              .fontColor(this.colors.accentGold)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 6 })
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)
          Text('›').fontSize(22).fontColor(this.colors.accentGold).opacity(0.7)
        }
        .width('100%')
        .padding(16)
        .backgroundColor(this.colors.cardDark)
        .borderRadius(14)
        .border({ width: 1, color: this.colors.borderSoft })
        .margin({ bottom: 10 })
        .onClick(() => {
          this.showMethodPicker = true;
        })

        Row() {
          Column() {
            Text(this.tr('madhab'))
              .fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
            Text(this.tr('madhab_desc'))
              .fontSize(11).fontColor(this.colors.textMuted).margin({ top: 2 })
            Text(SettingsHelper.getAsrRuleLabel(this.asrRule))
              .fontSize(12)
              .fontColor(this.colors.accentGold)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 6 })
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)
          Text('›').fontSize(22).fontColor(this.colors.accentGold).opacity(0.7)
        }
        .width('100%')
        .padding(16)
        .backgroundColor(this.colors.cardDark)
        .borderRadius(14)
        .border({ width: 1, color: this.colors.borderSoft })
        .margin({ bottom: 10 })
        .onClick(() => {
          this.showAsrPicker = true;
        })

        Row() {
          Column() {
            Text(this.tr('source'))
              .fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
            Text(this.tr('source_desc'))
              .fontSize(11).fontColor(this.colors.textMuted).margin({ top: 2 })
            Text(SettingsHelper.getCalcSourceLabel(this.calcSource))
              .fontSize(12)
              .fontColor(this.colors.accentGold)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 6 })
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)
          Text('›').fontSize(22).fontColor(this.colors.accentGold).opacity(0.7)
        }
        .width('100%')
        .padding(16)
        .backgroundColor(this.colors.cardDark)
        .borderRadius(14)
        .border({ width: 1, color: this.colors.borderSoft })
        .margin({ bottom: 10 })
        .onClick(() => {
          this.showSourcePicker = true;
        })
      }
      .width('100%')
      .padding({
        left: this.isTablet() ? 32 : 24,
        right: this.isTablet() ? 32 : 24,
        bottom: 24
      })
    }
    .layoutWeight(1)
    .width('100%')
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
  }

  // ============================================================
  // FOOTER
  // ============================================================

  @Builder
  Footer() {
    Row() {
      Button(this.step < TOTAL_STEPS - 1 ? this.tr('wizard_next') : this.tr('wizard_finish'))
        .width('100%').height(50)
        .fontSize(15).fontWeight(FontWeight.Medium)
        .fontColor(this.canProceed()
          ? this.colors.textOnAccent
          : this.colors.textMuted)
        .backgroundColor(this.canProceed()
          ? this.colors.accentGold
          : this.colors.tintMedium)
        .borderRadius(12)
        .enabled(this.canProceed())
        .onClick(() => { this.goNext(); })
    }
    .width('100%')
    .padding({
      left: this.isTablet() ? 32 : 24,
      right: this.isTablet() ? 32 : 24,
      top: 12,
      bottom: 24
    })
    .backgroundColor(this.colors.primaryGreen)
  }

  // ============================================================
  // PICKER OVERLAY
  // ============================================================

  @Builder
  PickerOverlay(
    title: string,
    icon: string,
    items: PickerItem[],
    onSelect: (id: string) => void,
    onCancel: () => void
  ) {
    Column()
      .width('100%').height('100%')
      .backgroundColor(this.colors.overlayDim)
      .onClick(() => { onCancel(); })

    Column() {
      Row().width(44).height(4)
        .backgroundColor(this.colors.overlayDimSoft)
        .borderRadius(2).margin({ top: 10 })

      Row() {
        Text(icon)
          .fontSize(22).width(44).height(44).textAlign(TextAlign.Center)
          .backgroundColor(this.colors.tintSoft).borderRadius(12)
          .border({ width: 1, color: this.colors.borderSoft })
        Text(title)
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
          .margin({ left: 14 })
      }
      .width('100%').padding({ left: 20, top: 20, bottom: 20 })

      Divider().color(this.colors.borderSoft).width('90%')

      Column() {
        ForEach(items, (item: PickerItem) => {
          Row() {
            Row() {
              if (item.selected) {
                Row().width(10).height(10).borderRadius(5)
                  .backgroundColor(this.colors.accentGold)
              }
            }
            .width(22).height(22).borderRadius(11)
            .border({
              width: item.selected ? 2 : 1.5,
              color: item.selected ? this.colors.accentGold : this.colors.borderStrong
            })
            .justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)

            Text(item.label)
              .fontSize(15)
              .fontColor(item.selected ? this.colors.accentGold : this.colors.textWhite)
              .fontWeight(item.selected ? FontWeight.Bold : FontWeight.Normal)
              .layoutWeight(1).maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ left: 14 })
          }
          .width('100%')
          .padding({ top: 16, bottom: 16, left: 20, right: 20 })
          .backgroundColor(item.selected ? this.colors.tintSoft : 'transparent')
          .borderRadius(12).margin({ bottom: 4 })
          .onClick(() => { onSelect(item.id); })
        }, (item: PickerItem) => item.id)
      }
      .width('100%').padding({ left: 8, right: 8, top: 12, bottom: 12 })

      Button(this.tr('cancel'))
        .width('90%').height(48).fontSize(15).fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textWhite).backgroundColor(this.colors.tintSoft)
        .borderRadius(12).margin({ top: 8, bottom: 24 })
        .onClick(() => { onCancel(); })
    }
    .width('100%').backgroundColor(this.colors.cardDark)
    .borderRadius({ topLeft: 28, topRight: 28 })
    .shadow({ radius: 24, color: this.colors.shadowFloating, offsetX: 0, offsetY: -6 })
    .border({ width: { top: 1 }, color: this.colors.borderSoft })
    .position({ bottom: 0 })
  }
}