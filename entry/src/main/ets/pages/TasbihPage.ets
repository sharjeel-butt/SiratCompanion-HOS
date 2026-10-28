// entry/src/main/ets/pages/TasbihPage.ets

import {
  AnimatorOptions, AnimatorResult, LengthMetrics, mediaquery, promptAction
} from '@kit.ArkUI';
import { MaterialHelper } from '../helper/MaterialHelper';
import { common } from '@kit.AbilityKit';
import { ThemeColors, ThemeMode, ThemePreset } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import {
  STORAGE_KEY_APP_FOREGROUND_TICK,
  STORAGE_KEY_APP_THEME,
  STORAGE_KEY_BREAKPOINT,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_THEME_MODE
} from '../common/StorageKeys';
import { BeadView, Dhikr, DhikrFields, Tasbih } from '../tasbih/TasbihModels';
import { MAX_BOTTOM_BEADS, TasbihManager } from '../tasbih/TasbihManager';
import { TasbihStorage } from '../tasbih/TasbihStorage';
import { HapticHelper } from '../helper/HapticHelper';
import { SoundHelper } from '../helper/SoundHelper';
import { SettingsHelper } from '../helper/SettingsHelper';
import { L } from '../i8n/LocalizationHelper';
import {
  BeadCanvasConfig, BeadRenderStyle, TasbihCanvasRenderer
} from '../tasbih/TasbihCanvasRenderer';
import {
  TASBIH_THEME_PRESETS,
  TasbihColor,
  TasbihTheme,
  TasbihThemePreset,
  TasbihThemes
} from '../tasbih/TasbihThemes';
import { Breakpoints } from '../common/Breakpoints';
import { TypographyHelper } from '../helper/TypographyHelper';

const BEAD_SIZE = 28;
const BEAD_GAP = 7;
const BEAD_STEP = BEAD_SIZE + BEAD_GAP;
const SWIPE_THRESHOLD = 50;
const STRING_WIDTH = 2;
const STRING_LINE_COLOR = 'rgba(232, 164, 76, 0.35)';
const FISHEYE_ANIM_MS = 180;
const TOP_SHIFT_MS = 250;
const BOTTOM_FLY_MS = 500;

const BEAD_COLUMN_TOP_PADDING = 16;

const SHADE_DONE_HI = '#A7F3C0';
const SHADE_DONE_BASE = '#4ADE80';
const SHADE_DONE_LO = '#1E7A4E';

const SHADE_PEND_HI_L = '#EFEAE0';
const SHADE_PEND_BASE_L = '#C9C2B8';
const SHADE_PEND_LO_L = '#8E8878';

const SHADE_PEND_HI_D = '#5A5A5A';
const SHADE_PEND_BASE_D = '#3A3A3A';
const SHADE_PEND_LO_D = '#1A1A1A';

/** Which sheet is currently presented. */
type TasbihSheet = 'none' | 'tasbihPicker' | 'dhikrPicker'
  | 'tasbihEditor' | 'dhikrEditor';

@Component
export struct TasbihPage {

  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;
  @StorageLink(STORAGE_KEY_LANGUAGE)
  @Watch('onLanguageChanged')
  appLanguage: string = 'en';
  @StorageLink(STORAGE_KEY_APP_FOREGROUND_TICK)
  @Watch('onAppForegrounded')
  appForegroundTick: number = 0;
  @StorageLink(STORAGE_KEY_BREAKPOINT)
  breakpoint: string = 'sm';
  @StorageLink(STORAGE_KEY_APP_THEME)
  @Watch('onAppThemePresetChanged')
  appThemePreset: string = ThemePreset.SIRAT;
  @StorageLink('nav_target_tasbih')
  @Watch('onNavTargetTasbihChanged')
  navTargetTasbih: string = '';

  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  @State tasbihs: Tasbih[] = [];
  @State activeTasbihId: string = '';
  @State activeDhikrIndex: number = 0;
  @State private activePrayerId: string = '';
  @State private activeSheet: TasbihSheet = 'none';

  @State editingTasbihId: string = '';
  @State formTasbihName: string = '';
  @State formThemePresetId: string = TasbihThemes.DEFAULT_PRESET_ID;
  @State editingDhikrId: string = '';
  @State formDhikrArabic: string = '';
  @State formDhikrTranslit: string = '';
  @State formDhikrTranslation: string = '';
  @State formDhikrTarget: string = '33';

  @State private currentLanguage: string = 'en';
  private systemDarkListener: mediaquery.MediaQueryListener | null = null;

  @State private beadView: BeadView = {
    topIds: [],
    bottomIds: [],
    isComplete: false,
    topAtCap: false,
    bottomAtCap: false
  };
  @State private topPulseTick: number = 0;

  private swipeStartY: number = 0;
  private swipeLastY: number = 0;
  private advanceLock: boolean = false;

  @State private renderStyle: BeadRenderStyle = 'premium';
  @State private canvasWidth: number = 72;
  @State private canvasHeight: number = 0;
  private ctx: CanvasRenderingContext2D =
    new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private canvasReady: boolean = false;

  @State private activeThemePresetId: string =
    TasbihThemes.DEFAULT_PRESET_ID;
  @State private activeTheme: TasbihTheme =
    TasbihThemes.themeForPreset(TasbihThemes.DEFAULT_PRESET_ID);
  @State private currentDateKey: string = TasbihManager.todayKey();
  private dateCheckTimer: number = -1;

  @State private fingerY: number = -1;
  @State private fisheyeStrength: number = 0;
  @State formBoundPrayerIds: string[] = [];

  private fisheyeAnimId: number = -1;

  @State private topShiftActive: boolean = false;
  @State private topShiftProgress: number = 0;
  private topShiftAnimator: AnimatorResult | null = null;

  private shiftPrevBottomCount: number = -1;
  private shiftFadeProgress: number = 0;
  private bottomPopProgress: number = 0;
  private bottomFlyAnimator: AnimatorResult | null = null;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  async aboutToAppear(): Promise<void> {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
    this.systemDarkListener = PageTheme.installSystemListener(
      this.themeMode, (c) => {
      this.colors = c;
    }
    );

    const storedStyle = await SettingsHelper.getTasbihRenderStyle();
    this.renderStyle = storedStyle === 'classic' ? 'classic' : 'premium';

    const ctx = getContext(this) as common.UIAbilityContext;
    await TasbihStorage.init(ctx);

    // REPLACED WITH METHOD CALL
    await this.reloadTasbihs();

    // ADDED: Midnight Timer
    this.dateCheckTimer = setInterval(() => {
      const now = TasbihManager.todayKey();
      if (this.currentDateKey !== now) {
        this.currentDateKey = now;
        this.reloadTasbihs();
      }
    }, 60000);
  }

  private async reloadTasbihs(): Promise<void> {
    const loaded = await TasbihStorage.load(TasbihManager.createDefaults());
    this.tasbihs = loaded.tasbihs;
    this.activeTasbihId = loaded.activeTasbihId;
    this.activeDhikrIndex = loaded.activeDhikrIndex;

    // CHECK FOR PENDING NAVIGATION HERE (Data is now loaded safely)
    const targetTasbih = AppStorage.get<string>('nav_target_tasbih');
    if (targetTasbih) {
      this.activeTasbihId = targetTasbih;
      this.activeDhikrIndex = AppStorage.get<number>('nav_target_dhikr') ?? 0;
      const targetPrayer = AppStorage.get<string>('nav_target_prayer') ?? '';

      if (targetPrayer) {
        this.restorePrayerCount(targetPrayer);
      } else {
        // Ensure the index is valid
        const t = this.getActiveTasbih();
        if (t && t.dhikrs.length > 0) {
          this.activeDhikrIndex = Math.min(this.activeDhikrIndex, t.dhikrs.length - 1);
        }
        this.resolveActiveTheme();
        this.refreshBeadView();
      }

      // Clear the targets so it doesn't re-trigger
      AppStorage.setOrCreate('nav_target_tasbih', '');
    } else {
      this.resolveActiveTheme();
      this.refreshBeadView();
    }
  }

  private onNavTargetTasbihChanged(): void {
    if (this.navTargetTasbih) {
      const targetDhikr = AppStorage.get<number>('nav_target_dhikr') ?? 0;
      const targetPrayer = AppStorage.get<string>('nav_target_prayer') ?? '';

      this.activeTasbihId = this.navTargetTasbih;
      this.activeDhikrIndex = targetDhikr;

      if (targetPrayer) {
        this.restorePrayerCount(targetPrayer);
      }

      this.resolveActiveTheme();
      this.refreshBeadView();
      this.persist();

      // Clear the targets
      AppStorage.setOrCreate('nav_target_tasbih', '');
      AppStorage.setOrCreate('nav_target_dhikr', 0);
      AppStorage.setOrCreate('nav_target_prayer', '');
    }
  }

  aboutToDisappear(): void {
    PageTheme.uninstallSystemListener(this.systemDarkListener);
    this.systemDarkListener = null;
    if (this.fisheyeAnimId !== -1) {
      clearInterval(this.fisheyeAnimId);
      this.fisheyeAnimId = -1;
    }
    if (this.topShiftAnimator !== null) {
      this.topShiftAnimator.cancel();
      this.topShiftAnimator = null;
    }
    if (this.bottomFlyAnimator !== null) {
      this.bottomFlyAnimator.cancel();
      this.bottomFlyAnimator = null;
    }

    // ADDED: Clear date timer
    if (this.dateCheckTimer !== -1) {
      clearInterval(this.dateCheckTimer);
      this.dateCheckTimer = -1;
    }
  }

  onPageShow(): void {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);

    // If there's a pending target, reload to process it. Otherwise, just refresh.
    const target = AppStorage.get<string>('nav_target_tasbih');
    if (target) {
      this.reloadTasbihs();
    } else {
      this.resolveActiveTheme();
      this.refreshBeadView();
    }
  }

  private getSortedBoundPrayers(prayerIds: string[]): string[] {
    const order = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    return prayerIds.slice().sort((a, b) => order.indexOf(a) - order.indexOf(b));
  }

  private resolveActivePrayer(): void {
    const t = this.getActiveTasbih();
    if (!t || !t.boundPrayerIds || t.boundPrayerIds.length === 0) {
      this.activePrayerId = '';
      return;
    }
    const todayKey = TasbihManager.todayKey();
    const pending = t.boundPrayerIds.find(p => !TasbihManager.isTasbihCompleteForPrayer(t, p, todayKey));
    const targetPrayer = pending || t.boundPrayerIds[0];

    this.restorePrayerCount(targetPrayer);
  }

  private selectPrayer(prayer: string): void {
    if (this.activePrayerId === prayer) {
      return;
    }
    this.restorePrayerCount(prayer);
  }

  private restorePrayerCount(newPrayer: string): void {
    const oldPrayer = this.activePrayerId;
    this.activePrayerId = newPrayer;

    const t = this.getActiveTasbih();
    if (t) {
      this.tasbihs = this.tasbihs.map((tas: Tasbih): Tasbih => {
        if (tas.id !== t.id) {
          return tas;
        }

        const newDhikrs = tas.dhikrs.map((d: Dhikr): Dhikr => {
          const lc: Record<string, number> = {};
          if (d.liveCounts) {
            const keys = Object.keys(d.liveCounts);
            for (let i = 0; i < keys.length; i++) {
              lc[keys[i]] = d.liveCounts[keys[i]];
            }
          }

          // Save old prayer's count
          if (oldPrayer) {
            lc[oldPrayer] = d.count;
          }

          // Restore new prayer's count
          const newCount = lc[newPrayer] || 0;

          const updatedDhikr: Dhikr = {
            id: d.id,
            arabic: d.arabic,
            transliteration: d.transliteration,
            translation: d.translation,
            transliterationKey: d.transliterationKey,
            translationKey: d.translationKey,
            target: d.target,
            count: newCount,
            lastCountDate: d.lastCountDate,
            dailyTotal: d.dailyTotal,
            liveCounts: lc
          };
          return updatedDhikr;
        });

        const updatedTasbih: Tasbih = {
          id: tas.id,
          name: tas.name,
          nameKey: tas.nameKey,
          dhikrs: newDhikrs,
          createdAt: tas.createdAt,
          lifetimeCount: tas.lifetimeCount,
          theme: tas.theme,
          themePresetId: tas.themePresetId,
          history: tas.history,
          boundPrayerIds: tas.boundPrayerIds,
          prayerCompletions: tas.prayerCompletions
        };
        return updatedTasbih;
      });
    }

    // Force index to be valid
    const active = this.getActiveTasbih();
    if (active && active.dhikrs.length > 0) {
      this.activeDhikrIndex = Math.min(this.activeDhikrIndex, active.dhikrs.length - 1);
    } else {
      this.activeDhikrIndex = 0;
    }

    this.refreshBeadView();
    this.persist();
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
        // if (deviceInfo.sdkApiVersion < 23) {
        //   Column().height(72)
        // }

        this.TopBar()

        // --- NEW: Prayer Selector ---
        // --- Prayer Selector ---
        if (this.getActiveTasbih()?.boundPrayerIds && this.getActiveTasbih()!.boundPrayerIds!.length > 0) {
          Row({ space: 8 }) {
            // USE THE SORTED ARRAY HERE
            ForEach(this.getSortedBoundPrayers(this.getActiveTasbih()!.boundPrayerIds!), (prayer: string) => {
              Row({ space: 4 }) {
                Text(this.tr('prayer_' + prayer))
                  .fontSize(12)
                  .fontColor(this.activePrayerId === prayer ? this.colors.textOnAccent : this.colors.textMuted)

                if (TasbihManager.isTasbihCompleteForPrayer(this.getActiveTasbih()!, prayer,
                  TasbihManager.todayKey())) {
                  Text('✓')
                    .fontSize(12)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.activePrayerId === prayer ? this.colors.textOnAccent : this.colors.accentGold)
                }
              }
              .padding({
                left: 12,
                right: 12,
                top: 6,
                bottom: 6
              })
              .backgroundColor(this.activePrayerId === prayer ? this.colors.accentGold : this.colors.tintSoft)
              .borderRadius(12)
              .border({
                width: 1,
                color: (!this.activePrayerId || this.activePrayerId !== prayer) &&
                  TasbihManager.isTasbihCompleteForPrayer(this.getActiveTasbih()!, prayer, TasbihManager.todayKey())
                  ? this.colors.accentGold
                  : this.colors.borderSoft
              })
              .onClick(() => {
                this.selectPrayer(prayer);
              })
            })
          }
          .margin({ top: 8, bottom: 8 })
          .padding({ left: 16, right: 16 })
          .width('100%')
        }

        Row() {
          Column() {
            if (this.getActiveDhikr() !== null) {
              Text(this.getActiveDhikr()!.arabic)
                .fontSize(26)
                .fontFamily(TypographyHelper.getFont(this.currentLanguage, false))
                .letterSpacing(0)
                .fontColor(this.colors.textWhite)
                .textAlign(TextAlign.Start)
                .lineHeight(38) // Adjust line height for Naskh
                .width('100%')

              Blank().layoutWeight(1)

              Column() {
                Text(`${this.getActiveDhikr()!.count}`)
                  .fontSize(96).fontWeight(FontWeight.Normal)
                  .fontFamily(TypographyHelper.getFont(this.currentLanguage, true))
                  .fontFeature('"tnum" 1')
                  .fontColor(this.beadView.isComplete
                    ? SHADE_DONE_BASE : this.colors.textWhite)

                Text(`${this.tr('target_count')} ${this.getActiveDhikr()!.target}`)
                  .fontSize(16).fontColor(this.colors.textMuted)
                  .margin({ top: -6 })

                Text(`${this.getLifetimeCount()} ${this.tr('total_on_tasbih')}`)
                  .fontSize(12).fontColor(this.colors.textMuted)
                  .opacity(0.7).margin({ top: 6 })
              }
              .alignItems(HorizontalAlign.Start)

              Row() {
                Text('↑').fontSize(18)
                  .fontColor(this.colors.textMuted).opacity(0.5)
                Text(`  ${this.tr('flick_up_to_count')}  `)
                  .fontSize(12).fontColor(this.colors.textMuted)
                  .letterSpacing(1)
              }
              .margin({ top: 24 })

              Text(this.tr('flick_hint'))
                .fontSize(10).fontColor(this.colors.textMuted)
                .opacity(0.7).margin({ top: 6 })

              Row() {
                Row() {
                  Text('↺').fontSize(14).fontColor(this.colors.textMuted)
                  Text(this.tr('reset'))
                    .fontSize(12).fontColor(this.colors.textMuted)
                    .margin({ left: 6 })
                }
                .padding({
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: 8
                })
                .backgroundColor(this.colors.tintSubtle)
                .borderRadius(16)
                .border({ width: 1, color: this.colors.borderSoft })
                .onClick(() => {
                  this.resetCurrent();
                })

                Row() {
                  Text('↻').fontSize(14).fontColor(this.colors.textMuted)
                  Text(this.tr('reset_all'))
                    .fontSize(12).fontColor(this.colors.textMuted)
                    .margin({ left: 6 })
                }
                .padding({
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: 8
                })
                .backgroundColor(this.colors.tintSubtle)
                .borderRadius(16)
                .border({ width: 1, color: this.colors.borderSoft })
                .margin({ left: 8 })
                .onClick(() => {
                  this.resetWholeTasbih();
                })
              }
              .margin({ top: 20, bottom: 8 })
            } else {
              this.EmptyState()
            }
          }
          .layoutWeight(1).height('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({
            left: this.isRtl() ? 8 : (this.isTablet() ? 48 : 24),
            right: this.isRtl() ? (this.isTablet() ? 48 : 24) : 8,
            top: 16,
            bottom: 110
          })

          if (this.renderStyle === 'classic') {
            this.BeadStringColumnClassic()
          } else {
            this.BeadStringColumnCanvas()
          }
        }
        .layoutWeight(1).width('100%')
        .alignItems(VerticalAlign.Top)
        .onTouch((event: TouchEvent) => { this.handleSwipe(event); })
      }
      .width('100%').height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    // Single bindSheet for all four overlay types. Renders in the system
    // modal layer, above the native Tabs chrome — so the floating tab
    // bar cannot overlap any Tasbih dialog.
    .bindSheet(
      this.activeSheet !== 'none',
      this.ActiveSheetContent(),
      MaterialHelper.buildSheetOptions(
        this.sheetHeight(),
        true,
        this.colors.cardDark,
        this.colors.overlayDim,
        () => {
          this.activeSheet = 'none';
        }
      )
    )
  }

  @Builder
  TopBar() {
    Row() {
      // Tasbih picker
      Row() {
        Text('📿').fontSize(14).margin({ right: 6 }).flexShrink(0)
        Text(this.getActiveTasbih()
          ? this.getTasbihName(this.getActiveTasbih()) // <-- Updated
          : this.tr('tab_tasbih'))
          .fontSize(15)
          .fontColor(this.colors.textWhite)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        Text('▼')
          .fontSize(10)
          .fontColor(this.colors.accentGold)
          .margin({ left: 6 })
          .opacity(0.7)
          .flexShrink(0)
      }
      .constraintSize({ maxWidth: 160 })
      .padding({
        left: 14,
        right: 14,
        top: 8,
        bottom: 8
      })
      .backgroundColor(this.colors.cardDark)
      .borderRadius(18)
      .border({ width: 1, color: this.colors.borderSoft })
      .onClick(() => {
        this.activeSheet = 'tasbihPicker';
      })

      Blank()

      // Dhikr picker
      Row() {
        Text(this.getActiveDhikr()
          ? this.getDhikrLabel(this.getActiveDhikr()) // <-- Updated
          : this.tr('select_dhikr'))
          .fontSize(13)
          .fontColor(this.colors.accentGold)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        Text('▼')
          .fontSize(10)
          .fontColor(this.colors.accentGold)
          .margin({ left: 6 })
          .opacity(0.7)
          .flexShrink(0)
      }
      .constraintSize({ maxWidth: 160 })
      .padding({
        left: 14,
        right: 14,
        top: 8,
        bottom: 8
      })
      .backgroundColor(this.colors.cardDark)
      .borderRadius(18)
      .border({ width: 1, color: this.colors.borderSoft })
      .onClick(() => {
        this.activeSheet = 'dhikrPicker';
      })
    }
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: 8,
      bottom: 8
    })
    .alignItems(VerticalAlign.Center)
  }

  // ============================================================
  // SHEET DISPATCH
  // ============================================================

  /**
   * Return the sheet height for the current sheet type. TasbihEditor
   * and DhikrEditor need more room; the two pickers are more compact.
   */
  private sheetHeight(): number | SheetSize {
    return SheetSize.FIT_CONTENT;
  }

  @Builder
  ActiveSheetContent() {
    if (this.activeSheet === 'tasbihPicker') {
      this.TasbihPickerContent()
    } else if (this.activeSheet === 'dhikrPicker') {
      this.DhikrPickerContent()
    } else if (this.activeSheet === 'tasbihEditor') {
      this.TasbihEditorContent()
    } else if (this.activeSheet === 'dhikrEditor') {
      this.DhikrEditorContent()
    } else {
      Column().width('100%').height('100%')
    }
  }

  // ============================================================
  // BEAD VIEWS
  // ============================================================

  @Builder
  Bead(hi: string, base: string, lo: string) {
    Stack() {
      Column()
        .width(BEAD_SIZE)
        .height(BEAD_SIZE)
        .borderRadius(BEAD_SIZE / 2)
        .linearGradient({
          angle: 135,
          colors: [[hi, 0], [base, 0.55], [lo, 1]]
        })
        .shadow({
          radius: 3,
          color: 'rgba(0,0,0,0.35)',
          offsetX: 0,
          offsetY: 2
        })

      Column()
        .width(BEAD_SIZE * 0.28)
        .height(BEAD_SIZE * 0.28)
        .borderRadius(BEAD_SIZE * 0.14)
        .backgroundColor('rgba(255,255,255,0.55)')
        .position({ x: BEAD_SIZE * 0.22, y: BEAD_SIZE * 0.18 })
    }
    .width(BEAD_SIZE).height(BEAD_SIZE)
  }

  @Builder
  BeadStringColumnClassic() {
    Stack() {
      Column()
        .width(STRING_WIDTH).height('100%')
        .backgroundColor(STRING_LINE_COLOR)
        .borderRadius(STRING_WIDTH / 2)

      Column() {
        ForEach(this.beadView.topIds, (i: number) => {
          Column() {
            if (this.beadView.isComplete) {
              this.Bead(SHADE_DONE_HI, SHADE_DONE_BASE, SHADE_DONE_LO)
            } else {
              this.Bead(
                TasbihThemes.palette(this.currentThemeColor()).hi,
                TasbihThemes.palette(this.currentThemeColor()).base,
                TasbihThemes.palette(this.currentThemeColor()).lo
              )
            }
          }
          .margin({ top: i === 0 ? 0 : BEAD_GAP })
          .translate({ y: -this.topShiftProgress * BEAD_STEP })
          .opacity((i === 0 && this.topShiftProgress > 0)
            ? 1 - this.topShiftProgress : 1)
        }, (i: number) => `top-${i}-${this.currentThemeColor()}`)

        if (this.topShiftActive) {
          Column() {
            if (this.beadView.isComplete) {
              this.Bead(SHADE_DONE_HI, SHADE_DONE_BASE, SHADE_DONE_LO)
            } else {
              this.Bead(
                TasbihThemes.palette(this.currentThemeColor()).hi,
                TasbihThemes.palette(this.currentThemeColor()).base,
                TasbihThemes.palette(this.currentThemeColor()).lo
              )
            }
          }
          .margin({ top: BEAD_GAP })
          .translate({ y: -this.topShiftProgress * BEAD_STEP })
          .opacity(this.topShiftProgress)
        }

        Blank().layoutWeight(1)

        ForEach(this.beadView.bottomIds, (i: number) => {
          Column() {
            if (PageTheme.isDarkFor(this.themeMode)) {
              this.Bead(SHADE_PEND_HI_D, SHADE_PEND_BASE_D, SHADE_PEND_LO_D)
            } else {
              this.Bead(SHADE_PEND_HI_L, SHADE_PEND_BASE_L, SHADE_PEND_LO_L)
            }
          }
          .margin({ top: i === 0 ? 0 : BEAD_GAP })
        }, (i: number) => `bottom-${i}`)
      }
      .width('100%').height('100%').alignItems(HorizontalAlign.Center)
    }
    .width(this.isTablet() ? 120 : 72)
    .height('100%')
    .padding({
      top: BEAD_COLUMN_TOP_PADDING,
      bottom: 110,
      left: this.isRtl() ? (this.isTablet() ? 60 : 40) : 0,
      right: this.isRtl() ? 0 : (this.isTablet() ? 60 : 40)
    })
    .direction(Direction.Ltr)
  }

  @Builder
  BeadStringColumnCanvas() {
    Stack() {
      Canvas(this.ctx)
        .width('100%').height('100%')
        .onReady(() => {
          this.canvasReady = true;
          this.drawCanvasBeads();
        })
        .onAreaChange((oldArea: Area, newArea: Area) => {
          const w = parseFloat(String(newArea.width));
          const h = parseFloat(String(newArea.height));
          if (!isNaN(w) && w > 0 && h > 0) {
            this.canvasWidth = w;
            this.canvasHeight = h;
            this.drawCanvasBeads();
          }
        })
    }
    .width(this.isTablet() ? 120 : 72)
    .height('100%')
    .padding({
      top: BEAD_COLUMN_TOP_PADDING,
      bottom: 110,
      left: this.isRtl() ? (this.isTablet() ? 60 : 40) : 0,
      right: this.isRtl() ? 0 : (this.isTablet() ? 60 : 40)
    })
    .direction(Direction.Ltr)
  }

  @Builder
  EmptyState() {
    Column() {
      Text('📿').fontSize(64).opacity(0.5)
      Text(this.tr('no_dhikr_title'))
        .fontSize(16).fontColor(this.colors.textMuted).margin({ top: 16 })
      Text(this.tr('no_dhikr_hint'))
        .fontSize(13).fontColor(this.colors.textMuted).margin({ top: 6 })
    }
    .width('100%').justifyContent(FlexAlign.Center)
  }

  // ============================================================
  // TASBIH PICKER SHEET
  // ============================================================

  @Builder
  TasbihPickerContent() {
    Column() {
      // Header band — title vertically and horizontally centred.
      Row() {
        Text(this.tr('my_tasbihs'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .margin({ top: 4, bottom: 4 })

      // Divider under the title.
      Divider()
        .strokeWidth(1)
        .color(this.colors.borderMedium)
        .width('100%')
        .margin({ bottom: 10 })

      Scroll() {
        Column() {
          ForEach(this.tasbihs, (t: Tasbih) => {
            Row({ space: 12 }) { // <-- Added Row space
              Row() {
                if (t.id === this.activeTasbihId) {
                  Row().width(10).height(10).borderRadius(5)
                    .backgroundColor(this.colors.accentGold)
                }
              }
              .width(22)
              .height(22)
              .borderRadius(11)
              .border({
                width: t.id === this.activeTasbihId ? 2 : 1.5,
                color: t.id === this.activeTasbihId
                  ? this.colors.accentGold : this.colors.borderStrong
              })
              .justifyContent(FlexAlign.Center)
              .alignItems(VerticalAlign.Center)
              .flexShrink(0) // Prevent squish

              Column()
                .width(16)
                .height(16)
                .borderRadius(8)
                .flexShrink(0) // Prevent squish
                .backgroundColor(TasbihThemes.presetById(
                  t.themePresetId !== undefined && t.themePresetId.length > 0
                    ? t.themePresetId
                    : TasbihThemes.DEFAULT_PRESET_ID
                ).swatch)

              Column() {
                Text(this.getTasbihName(t)) // <-- Updated
                  .fontSize(15).fontColor(this.colors.textWhite)
                  .fontWeight(FontWeight.Medium).width('100%')
                Text(`${t.dhikrs.length} ${t.dhikrs.length === 1
                  ? this.tr('dhikr_count_singular')
                  : this.tr('dhikr_count_plural')} · ${t.lifetimeCount || 0} ${this.tr('total_on_tasbih')}`)
                  .fontSize(11).fontColor(this.colors.textMuted)
                  .margin({ top: 2 }).width('100%')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Text('✏️')
                .fontSize(18)
                .width(36)
                .height(36)
                .textAlign(TextAlign.Center)
                .flexShrink(0)
                .onClick(() => {
                  this.openEditTasbihEditor(t);
                })

              if (this.tasbihs.length > 1) {
                Text('🗑️')
                  .fontSize(18)
                  .width(36)
                  .height(36)
                  .textAlign(TextAlign.Center)
                  .flexShrink(0)
                  .onClick(() => {
                    this.deleteTasbih(t.id);
                  })
              }
            }
            .width('100%')
            .padding({
              top: 12,
              bottom: 12,
              left: this.isRtl() ? 8 : 16,
              right: this.isRtl() ? 16 : 8
            })
            .backgroundColor(t.id === this.activeTasbihId
              ? this.colors.tintSoft : 'transparent')
            .borderRadius(12)
            .margin({ bottom: 4 })
            .onClick(() => {
              this.selectTasbih(t.id);
            })
          }, (t: Tasbih) =>
          `${t.id}-${t.name}-${t.dhikrs.length}-${t.themePresetId ?? 'default'}`)
        }
        .width('100%')
        .padding({ left: 8, right: 8, bottom: 8 })
      }
      .flexShrink(1)
      .width('100%')
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)

      Button(this.tr('new_tasbih_button'))
        .width('90%')
        .height(46)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textOnAccent)
        .backgroundColor(this.colors.accentGold)
        .borderRadius(12)
        .margin({ top: 8, bottom: 8 })
        .onClick(() => { this.openNewTasbihEditor(); })

      Button(this.tr('cancel'))
        .width('90%')
        .height(44)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textWhite)
        .backgroundColor(this.colors.tintSoft)
        .borderRadius(12)
        .margin({ bottom: 20 })
        .onClick(() => {
          this.activeSheet = 'none';
        })
    }
    .width('100%').height('100%')
  }

  private dhikrCountLabel(n: number): string {
    // Arabic dual form ("ذكران") implies "two" and takes no numeral.
    if (this.currentLanguage === 'ar' && n === 2) {
      return this.tr('dhikr_count_dual');
    }
    const word = n === 1
      ? this.tr('dhikr_count_singular')
      : this.tr('dhikr_count_plural');
    return `${n} ${word}`;
  }

  // ============================================================
  // DHIKR PICKER SHEET
  // ============================================================

  @Builder
  DhikrPickerContent() {
    Column() {
      // Header band — title vertically and horizontally centred.
      Row() {
        Text(this.tr('select_dhikr'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .margin({ top: 4, bottom: 4 })

      // Divider under the title.
      Divider()
        .strokeWidth(1)
        .color(this.colors.borderMedium)
        .width('100%')
        .margin({ bottom: 10 })

      Scroll() {
        Column() {
          if (this.getActiveTasbih() !== null) {
            ForEach(this.getActiveTasbih()!.dhikrs,
              (d: Dhikr, index: number) => {
                Row({ space: 14 }) {
                  // Radio Button
                  Row() {
                    if (index === this.activeDhikrIndex) {
                      Row().width(10).height(10).borderRadius(5)
                        .backgroundColor(this.colors.accentGold)
                    }
                  }
                  .width(22)
                  .height(22)
                  .borderRadius(11)
                  .border({
                    width: index === this.activeDhikrIndex ? 2 : 1.5,
                    color: index === this.activeDhikrIndex
                      ? this.colors.accentGold : this.colors.borderStrong
                  })
                  .justifyContent(FlexAlign.Center)
                  .alignItems(VerticalAlign.Center)
                  .flexShrink(0)

                  // Text Column (Using localized label)
                  Column() {
                    Text(this.getDhikrLabel(d))
                      .fontSize(15)
                      .fontColor(this.colors.textWhite)
                      .fontWeight(FontWeight.Medium)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')
                    Text(`${d.count} / ${d.target}`)
                      .fontSize(11).fontColor(this.colors.textMuted)
                      .margin({ top: 2 }).width('100%')
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  // Edit Button
                  Text('✏️')
                    .fontSize(16)
                    .width(32)
                    .height(32)
                    .textAlign(TextAlign.Center)
                    .flexShrink(0)
                    .onClick(() => {
                      this.openEditDhikrEditor(d);
                    })

                  // Delete Button
                  Text('🗑️')
                    .fontSize(16)
                    .width(32)
                    .height(32)
                    .textAlign(TextAlign.Center)
                    .flexShrink(0)
                    .onClick(() => {
                      this.deleteDhikr(d.id);
                    })
                }
                .width('100%')
                .padding({
                  top: 12,
                  bottom: 12,
                  left: this.isRtl() ? 8 : 16,
                  right: this.isRtl() ? 16 : 8
                })
                .backgroundColor(index === this.activeDhikrIndex
                  ? this.colors.tintSoft : 'transparent')
                .borderRadius(12)
                .margin({ bottom: 4 })
                .onClick(() => {
                  this.selectDhikr(index);
                })
              }, (d: Dhikr) => `${d.id}-${d.count}-${d.target}`)
          }
        }
        .width('100%')
        .padding({ left: 8, right: 8, bottom: 8 })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)

      // Add Button
      Button(this.tr('add_dhikr_button'))
        .width('90%')
        .height(46)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textOnAccent)
        .backgroundColor(this.colors.accentGold)
        .borderRadius(12)
        .margin({ top: 8, bottom: 8 })
        .onClick(() => { this.openNewDhikrEditor(); })

      // Cancel Button
      Button(this.tr('cancel'))
        .width('90%')
        .height(44)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textWhite)
        .backgroundColor(this.colors.tintSoft)
        .borderRadius(12)
        .margin({ bottom: 20 })
        .onClick(() => {
          this.activeSheet = 'none';
        })
    }
    .width('100%').height('100%')
  }

  // ============================================================
  // TASBIH EDITOR SHEET
  // ============================================================

  @Builder
  TasbihEditorContent() {
    Column() {
      // Header band — title vertically and horizontally centred.
      Row() {
        Text(this.editingTasbihId.length > 0
          ? this.tr('edit_tasbih') : this.tr('new_tasbih'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .margin({ top: 4, bottom: 4 })

      // Divider under the title.
      Divider()
        .strokeWidth(1)
        .color(this.colors.borderMedium)
        .width('100%')
        .margin({ bottom: 10 })

      Scroll() {
        Column() {
          // --- Name Input ---
          Column() {
            Text(this.tr('tasbih_name'))
              .fontSize(12).fontColor(this.colors.textMuted)
              .width('100%').margin({ bottom: 6 })
            TextInput({
              text: this.formTasbihName,
              placeholder: this.tr('tasbih_name_placeholder')
            })
              .type(InputType.Normal)
              .onChange((value: string) => {
                this.formTasbihName = value;
              })
              .fontSize(15)
              .fontColor(this.colors.textWhite)
              .placeholderColor(this.colors.placeholder)
              .caretColor(this.colors.accentGold)
              .backgroundColor(this.colors.tintSoft)
              .borderRadius(10)
              .padding({
                left: 14,
                right: 14,
                top: 10,
                bottom: 10
              })
              .width('100%')
          }
          .width('100%')
          .padding({
            left: 20,
            right: 20,
            top: 0,
            bottom: 16
          })

          // --- Bind to Prayers ---
          Column() {
            Text(L.get('bind_to_prayers', this.currentLanguage))
              .fontSize(12).fontColor(this.colors.textMuted)
              .width('100%').margin({ bottom: 8 })

            Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(8), cross: LengthMetrics.vp(8) } }) {
              ForEach(['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'], (prayer: string) => {
                Text(L.get('prayer_' + prayer, this.currentLanguage))
                  .padding({
                    left: 12,
                    right: 12,
                    top: 6,
                    bottom: 6
                  })
                  .fontColor(
                    this.formBoundPrayerIds.includes(prayer) ? this.colors.textOnAccent : this.colors.textWhite)
                  .backgroundColor(
                    this.formBoundPrayerIds.includes(prayer) ? this.colors.accentGold : this.colors.tintSoft)
                  .borderRadius(16)
                  .onClick(() => {
                    if (this.formBoundPrayerIds.includes(prayer)) {
                      this.formBoundPrayerIds = this.formBoundPrayerIds.filter(id => id !== prayer);
                    } else {
                      this.formBoundPrayerIds = [...this.formBoundPrayerIds, prayer];
                    }
                  })
              })
            }
            .width('100%')
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 16 })

          // --- Theme Swatches ---
          Column() {
            Text(this.tr('tasbih_render_style'))
              .fontSize(12).fontColor(this.colors.textMuted)
              .width('100%').margin({ bottom: 8 })

            Flex({
              wrap: FlexWrap.Wrap,
              justifyContent: FlexAlign.Start,
              alignItems: ItemAlign.Center
            }) {
              ForEach(TASBIH_THEME_PRESETS, (preset: TasbihThemePreset) => {
                Stack() {
                  Column()
                    .width(36)
                    .height(36)
                    .borderRadius(18)
                    .backgroundColor(preset.swatch)
                    .shadow({
                      radius: 3,
                      color: 'rgba(0,0,0,0.35)',
                      offsetX: 0,
                      offsetY: 2
                    })

                  if (preset.id === this.formThemePresetId) {
                    Column()
                      .width(48).height(48).borderRadius(24)
                      .border({ width: 2, color: this.colors.accentGold })
                  }
                }
                .width(52).height(52)
                // Ensure there is spacing between swatches
                .margin({ right: 6, bottom: 6 })
                .onClick(() => {
                  this.formThemePresetId = preset.id;
                })
              }, (preset: TasbihThemePreset) =>
              `editor-${preset.id}-${preset.id === this.formThemePresetId ? 'sel' : 'un'}`)
            }
            .width('100%')
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 16 })
        }
        .width('100%')
      }
      .flexShrink(1) // <-- Replaced layoutWeight(1) so content auto-sizes
      .width('100%')
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)

      // --- Buttons ---
      Row() {
        Button(this.tr('cancel'))
          .layoutWeight(1)
          .height(46)
          .fontSize(15)
          .fontColor(this.colors.textWhite)
          .backgroundColor(this.colors.tintSoft)
          .borderRadius(12)
          .onClick(() => {
            this.activeSheet = 'none';
          })
        Button(this.tr('save'))
          .layoutWeight(1)
          .height(46)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textOnAccent)
          .backgroundColor(this.colors.accentGold)
          .borderRadius(12)
          .margin({ left: 8 })
          .onClick(() => { this.saveTasbih(); })
      }
      .width('100%')
      .padding({
        left: 20,
        right: 20,
        top: 8,
        bottom: 20
      })
    }
    .width('100%')
  }

  // ============================================================
  // DHIKR EDITOR SHEET
  // ============================================================

  @Builder
  DhikrEditorContent() {
    Column() {
      // Header band — title vertically and horizontally centred.
      Row() {
        Text(this.editingDhikrId.length > 0
          ? this.tr('edit_dhikr') : this.tr('new_dhikr'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .margin({ top: 4, bottom: 4 })

      // Divider under the title.
      Divider()
        .strokeWidth(1)
        .color(this.colors.borderMedium)
        .width('100%')
        .margin({ bottom: 10 })

      Scroll() {
        Column() {
          Column() {
            Text(this.tr('dhikr_arabic'))
              .fontSize(12).fontColor(this.colors.textMuted)
              .width('100%').margin({ bottom: 6 })
            TextInput({
              text: this.formDhikrArabic,
              placeholder: 'سُبْحَانَ ٱللَّٰهِ'
            })
              .type(InputType.Normal)
              .onChange((value: string) => { this.formDhikrArabic = value; })
              .fontSize(16)
              .fontColor(this.colors.textWhite)
              .placeholderColor(this.colors.placeholder)
              .caretColor(this.colors.accentGold)
              .backgroundColor(this.colors.tintSoft)
              .borderRadius(10)
              .padding({
                left: 14,
                right: 14,
                top: 10,
                bottom: 10
              })
              .width('100%')
          }.width('100%').margin({ bottom: 14 })

          Column() {
            Text(this.tr('dhikr_transliteration'))
              .fontSize(12).fontColor(this.colors.textMuted)
              .width('100%').margin({ bottom: 6 })
            TextInput({
              text: this.formDhikrTranslit,
              placeholder: this.tr('dhikr_transliteration_placeholder')
            })
              .type(InputType.Normal)
              .onChange((value: string) => { this.formDhikrTranslit = value; })
              .fontSize(14)
              .fontColor(this.colors.textWhite)
              .placeholderColor(this.colors.placeholder)
              .caretColor(this.colors.accentGold)
              .backgroundColor(this.colors.tintSoft)
              .borderRadius(10)
              .padding({
                left: 14,
                right: 14,
                top: 10,
                bottom: 10
              })
              .width('100%')
          }.width('100%').margin({ bottom: 14 })

          Column() {
            Text(this.tr('dhikr_translation'))
              .fontSize(12).fontColor(this.colors.textMuted)
              .width('100%').margin({ bottom: 6 })
            TextInput({
              text: this.formDhikrTranslation,
              placeholder: this.tr('dhikr_translation_placeholder')
            })
              .type(InputType.Normal)
              .onChange((value: string) => {
                this.formDhikrTranslation = value;
              })
              .fontSize(14)
              .fontColor(this.colors.textWhite)
              .placeholderColor(this.colors.placeholder)
              .caretColor(this.colors.accentGold)
              .backgroundColor(this.colors.tintSoft)
              .borderRadius(10)
              .padding({
                left: 14,
                right: 14,
                top: 10,
                bottom: 10
              })
              .width('100%')
          }.width('100%').margin({ bottom: 14 })

          Column() {
            Text(this.tr('target_count'))
              .fontSize(12).fontColor(this.colors.textMuted)
              .width('100%').margin({ bottom: 6 })
            TextInput({ text: this.formDhikrTarget, placeholder: '33' })
              .type(InputType.Number)
              .direction(Direction.Ltr)
              .onChange((value: string) => { this.formDhikrTarget = value; })
              .fontSize(14)
              .fontColor(this.colors.textWhite)
              .placeholderColor(this.colors.placeholder)
              .caretColor(this.colors.accentGold)
              .backgroundColor(this.colors.tintSoft)
              .borderRadius(10)
              .padding({
                left: 14,
                right: 14,
                top: 10,
                bottom: 10
              })
              .width('100%')
          }.width('100%').margin({ bottom: 8 })
        }
        .width('100%')
        .padding({
          left: 20,
          right: 20,
          top: 0,
          bottom: 8
        })
      }
      .flexShrink(1)
      .width('100%')
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)

      Row() {
        Button(this.tr('cancel'))
          .layoutWeight(1)
          .height(46)
          .fontSize(15)
          .fontColor(this.colors.textWhite)
          .backgroundColor(this.colors.tintSoft)
          .borderRadius(12)
          .onClick(() => {
            this.activeSheet = 'none';
          })
        Button(this.tr('save'))
          .layoutWeight(1)
          .height(46)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textOnAccent)
          .backgroundColor(this.colors.accentGold)
          .borderRadius(12)
          .margin({ left: 8 })
          .onClick(() => { this.saveDhikr(); })
      }
      .width('100%')
      .padding({
        left: 20,
        right: 20,
        top: 8,
        bottom: 20
      })
    }
    .width('100%').height('100%')
  }

  // ============================================================
  // HELPERS
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

  private onThemeModeChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onAppThemePresetChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onLanguageChanged(): void {
    this.currentLanguage = this.appLanguage;
  }

  private async onAppForegrounded(): Promise<void> {
    await this.reloadTasbihs();
  }

  private getActiveTasbih(): Tasbih | null {
    return TasbihManager.findTasbih(this.tasbihs, this.activeTasbihId);
  }

  private getActiveDhikr(): Dhikr | null {
    return TasbihManager.getActiveDhikr(
      this.tasbihs, this.activeTasbihId, this.activeDhikrIndex
    );
  }

  private getLifetimeCount(): number {
    const t = this.getActiveTasbih();
    return t ? (t.lifetimeCount || 0) : 0;
  }

  private resolveActiveTheme(): void {
    const t = this.getActiveTasbih();
    const presetId = (t && t.themePresetId !== undefined
      && t.themePresetId.length > 0)
      ? t.themePresetId
      : TasbihThemes.DEFAULT_PRESET_ID;
    this.activeThemePresetId = presetId;
    this.activeTheme = TasbihThemes.themeForPreset(presetId);
  }

  private currentTheme(): TasbihTheme {
    const t = this.getActiveTasbih();
    if (!t) {
      return TasbihThemes.themeForPreset(TasbihThemes.DEFAULT_PRESET_ID);
    }
    if (t.themePresetId !== undefined && t.themePresetId.length > 0) {
      return TasbihThemes.themeForPreset(t.themePresetId);
    }
    if (t.theme !== undefined) {
      return t.theme;
    }
    return TasbihThemes.themeForPreset(TasbihThemes.DEFAULT_PRESET_ID);
  }

  private currentThemeColor(): TasbihColor {
    return this.currentTheme().color;
  }

  private refreshBeadView(): void {
    const dhikr = this.getActiveDhikr();
    const next = TasbihManager.computeBeadView(dhikr);

    const topSame = next.topIds.length === this.beadView.topIds.length;
    if (topSame && next.topAtCap && next.topIds.length > 0) {
      this.topPulseTick = this.topPulseTick + 1;
    }

    this.beadView = next;
    this.drawCanvasBeads();
  }

  // Update persist() to save the active count just in case the app closes
  private persist(): void {
    if (this.activePrayerId) {
      const t = this.getActiveTasbih();
      if (t) {
        this.tasbihs = this.tasbihs.map((tas: Tasbih): Tasbih => {
          if (tas.id !== t.id) {
            return tas;
          }

          const newDhikrs: Dhikr[] = tas.dhikrs.map((d: Dhikr): Dhikr => {
            const lc: Record<string, number> = {};
            if (d.liveCounts) {
              const keys = Object.keys(d.liveCounts);
              for (let i = 0; i < keys.length; i++) {
                lc[keys[i]] = d.liveCounts[keys[i]];
              }
            }

            lc[this.activePrayerId] = d.count;

            // Explicitly type the object
            const updatedDhikr: Dhikr = {
              id: d.id,
              arabic: d.arabic,
              transliteration: d.transliteration,
              translation: d.translation,
              transliterationKey: d.transliterationKey,
              translationKey: d.translationKey,
              target: d.target,
              count: d.count,
              lastCountDate: d.lastCountDate,
              dailyTotal: d.dailyTotal,
              liveCounts: lc
            };
            return updatedDhikr;
          });

          // Explicitly type the object
          const updatedTasbih: Tasbih = {
            id: tas.id,
            name: tas.name,
            nameKey: tas.nameKey,
            createdAt: tas.createdAt,
            lifetimeCount: tas.lifetimeCount,
            theme: tas.theme,
            themePresetId: tas.themePresetId,
            history: tas.history,
            boundPrayerIds: tas.boundPrayerIds,
            prayerCompletions: tas.prayerCompletions,
            dhikrs: newDhikrs
          };
          return updatedTasbih;
        });
      }
    }

    TasbihStorage.save(this.tasbihs, this.activeTasbihId, this.activeDhikrIndex);
  }

  private drawCanvasBeads(): void {
    if (!this.canvasReady || this.canvasHeight <= 0) {
      return;
    }
    if (this.renderStyle !== 'premium') {
      return;
    }

    const liveTheme: TasbihTheme = this.currentTheme();

    const cfg: BeadCanvasConfig = {
      topCount: this.beadView.topIds.length,
      bottomCount: this.beadView.bottomIds.length,
      isComplete: this.beadView.isComplete,
      fingerY: this.fingerY,
      fisheyeStrength: this.fisheyeStrength,
      beadRadius: BEAD_SIZE / 2,
      beadGap: BEAD_GAP,
      renderStyle: this.renderStyle,
      isDark: PageTheme.isDarkFor(this.themeMode),
      stringColor: STRING_LINE_COLOR,
      topShiftProgress: this.topShiftProgress,
      theme: liveTheme,
      bottomPrevCount: this.shiftPrevBottomCount,
      bottomFadeProgress: this.shiftFadeProgress,
      bottomPopProgress: this.bottomPopProgress
    };

    TasbihCanvasRenderer.drawCanvas(
      this.ctx, this.canvasWidth, this.canvasHeight, cfg
    );
  }

  private startFisheye(): void {
    this.animateFisheyeTo(1);
  }

  private fadeFisheye(): void {
    this.animateFisheyeTo(0);
  }

  private animateFisheyeTo(target: number): void {
    if (this.fisheyeAnimId !== -1) {
      clearInterval(this.fisheyeAnimId);
      this.fisheyeAnimId = -1;
    }
    const start = this.fisheyeStrength;
    const startTime = Date.now();
    const duration = FISHEYE_ANIM_MS;

    this.fisheyeAnimId = setInterval(() => {
      const t = Math.min((Date.now() - startTime) / duration, 1);
      const eased = 1 - Math.pow(1 - t, 3);
      this.fisheyeStrength = start + (target - start) * eased;
      this.drawCanvasBeads();
      if (t >= 1) {
        clearInterval(this.fisheyeAnimId);
        this.fisheyeAnimId = -1;
        if (target === 0) {
          this.fingerY = -1;
          this.drawCanvasBeads();
        }
      }
    }, 16);
  }

  private startTopShift(): void {
    if (this.topShiftAnimator !== null) {
      this.topShiftAnimator.cancel();
      this.topShiftAnimator = null;
    }

    this.topShiftActive = true;
    this.topShiftProgress = 0;

    const options: AnimatorOptions = {
      duration: TOP_SHIFT_MS,
      easing: 'ease-out',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: 1,
      begin: 0,
      end: 1
    };

    const animator: AnimatorResult =
      this.getUIContext().createAnimator(options);

    animator.onFrame = (value: number) => {
      this.topShiftProgress = value;
      this.shiftFadeProgress = value;
      this.drawCanvasBeads();
    };

    animator.onFinish = () => {
      this.topShiftActive = false;
      this.topShiftProgress = 0;
      this.shiftFadeProgress = 0;
      this.shiftPrevBottomCount = -1;
      this.drawCanvasBeads();
      this.topShiftAnimator = null;
    };

    this.topShiftAnimator = animator;
    animator.play();
  }

  private startBottomFlyPop(oldBottomCount: number): void {
    if (this.bottomFlyAnimator !== null) {
      this.bottomFlyAnimator.cancel();
      this.bottomFlyAnimator = null;
    }

    this.shiftPrevBottomCount = oldBottomCount;
    this.shiftFadeProgress = 0;
    this.bottomPopProgress = 0;

    const options: AnimatorOptions = {
      duration: BOTTOM_FLY_MS,
      easing: 'ease-in-out',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: 1,
      begin: 0,
      end: 1
    };

    const animator: AnimatorResult =
      this.getUIContext().createAnimator(options);

    animator.onFrame = (value: number) => {
      this.shiftFadeProgress = value;
      this.bottomPopProgress = Math.min(value / 0.5, 1);
      this.drawCanvasBeads();
    };

    animator.onFinish = () => {
      this.shiftPrevBottomCount = -1;
      this.shiftFadeProgress = 0;
      this.bottomPopProgress = 0;
      this.bottomFlyAnimator = null;
      this.drawCanvasBeads();
    };

    this.bottomFlyAnimator = animator;
    animator.play();
  }

  private increment(): void {
    if (this.advanceLock) {
      return;
    }

    const dhikr = this.getActiveDhikr();
    if (!dhikr) {
      return;
    }

    HapticHelper.tick();
    SoundHelper.tick();

    const wasAtCap = this.beadView.topAtCap;
    const oldBottomCount = this.beadView.bottomIds.length;

    this.tasbihs = TasbihManager.increment(
      this.tasbihs, this.activeTasbihId, dhikr.id
    );
    this.refreshBeadView();

    if (wasAtCap && this.beadView.topAtCap) {
      this.startTopShift();
    }

    if (oldBottomCount === MAX_BOTTOM_BEADS) {
      this.startBottomFlyPop(oldBottomCount);
    }

    const updatedDhikr = this.getActiveDhikr();
    if (!updatedDhikr) {
      this.persist();
      return;
    }

    const isComplete = updatedDhikr.count >= updatedDhikr.target;
    const tasbih = this.getActiveTasbih();
    const hasNext = tasbih !== null
      && this.activeDhikrIndex < tasbih.dhikrs.length - 1;

    if (isComplete && hasNext) {
      this.persist();
      this.advanceLock = true;
      HapticHelper.confirm();

      setTimeout(() => {
        this.activeDhikrIndex = this.activeDhikrIndex + 1;
        this.refreshBeadView();
        this.advanceLock = false;
        this.persist();
      }, 400);
      return;
    }

    if (isComplete && !hasNext) {
      HapticHelper.complete();
      this.getUIContext().getPromptAction().showToast({
        message: this.tr('all_dhikrs_complete'), duration: 1800
      });

      const tasbih = this.getActiveTasbih();
      if (this.activePrayerId && tasbih) {
        this.tasbihs = TasbihManager.markPrayerComplete(
          this.tasbihs, tasbih.id, this.activePrayerId, TasbihManager.todayKey()
        );
        this.persist();
      }
    }

    this.persist();
  }

  private decrement(): void {
    if (this.advanceLock) {
      return;
    }

    const dhikr = this.getActiveDhikr();
    if (!dhikr || dhikr.count === 0) {
      return;
    }

    HapticHelper.tick();
    SoundHelper.tick();

    this.tasbihs = TasbihManager.decrement(
      this.tasbihs, this.activeTasbihId, dhikr.id
    );
    this.refreshBeadView();
    this.persist();
  }

  private resetCurrent(): void {
    if (this.advanceLock) {
      return;
    }

    const dhikr = this.getActiveDhikr();
    if (!dhikr) {
      return;
    }

    this.tasbihs = TasbihManager.reset(
      this.tasbihs, this.activeTasbihId, dhikr.id
    );
    this.refreshBeadView();
    this.persist();
    this.getUIContext().getPromptAction().showToast({
      message: this.tr('counter_reset_toast'), duration: 1200
    });
  }

  private resetWholeTasbih(): void {
    if (this.advanceLock) {
      return;
    }
    const dhikr = this.getActiveDhikr();
    if (!dhikr) {
      return;
    }

    this.getUIContext()
      .getPromptAction()
      .showDialog({
        title: this.tr('reset_all_confirm_title'),
        message: this.tr('reset_all_confirm_message'),
        buttons: [
          { text: this.tr('cancel'), color: this.colors.dialogCancel },
          { text: this.tr('reset'), color: this.colors.statusExpress }
        ]
      })
      .then((result: promptAction.ShowDialogSuccessResponse) => {
        if (result.index === 1) {
          this.tasbihs = TasbihManager.resetAll(
            this.tasbihs, this.activeTasbihId
          );
          this.activeDhikrIndex = 0;
          this.refreshBeadView();
          this.persist();
          this.getUIContext().getPromptAction().showToast({
            message: this.tr('reset_all_done'), duration: 1200
          });
        }
      })
      .catch((err: Error) => {
        console.error('[TasbihPage] reset dialog failed:', JSON.stringify(err));
      });
  }

  private handleSwipe(event: TouchEvent): void {
    // Guard: while a modal sheet is presented, do not treat drags as
    // Tasbih swipes. The sheet is in the system modal layer, but on
    // some HOS builds the initial drag can still land on this Row.
    if (this.activeSheet !== 'none') {
      return;
    }

    if (event.touches && event.touches.length > 0) {
      const rowY = event.touches[0].y;
      const canvasY = rowY - BEAD_COLUMN_TOP_PADDING;

      if (event.type === TouchType.Down) {
        this.swipeStartY = rowY;
        this.swipeLastY = rowY;
        this.fingerY = canvasY;
        this.startFisheye();
        this.drawCanvasBeads();
      } else if (event.type === TouchType.Move) {
        this.swipeLastY = rowY;
        this.fingerY = canvasY;
        this.drawCanvasBeads();
      }
    }

    if (event.type === TouchType.Up) {
      const delta = this.swipeLastY - this.swipeStartY;
      this.fadeFisheye();
      if (Math.abs(delta) > SWIPE_THRESHOLD) {
        if (delta < 0) {
          this.increment();
        } else {
          this.decrement();
        }
      }
    }
  }

  // ============================================================
  // EDITOR OPEN/SAVE
  // ============================================================

  private openNewTasbihEditor(): void {
    this.editingTasbihId = '';
    this.formTasbihName = '';
    this.formThemePresetId = TasbihThemes.DEFAULT_PRESET_ID;
    this.formBoundPrayerIds = [];
    this.activeSheet = 'tasbihEditor';
  }

  private openEditTasbihEditor(t: Tasbih): void {
    this.editingTasbihId = t.id;
    this.formTasbihName = this.getTasbihName(t);
    this.formThemePresetId = t.themePresetId || TasbihThemes.DEFAULT_PRESET_ID;
    this.formBoundPrayerIds = t.boundPrayerIds || [];
    this.activeSheet = 'tasbihEditor';
  }

  private saveTasbih(): void {
    const name = this.formTasbihName.trim();
    const finalName = name.length > 0 ? name : 'Tasbih';

    if (this.editingTasbihId.length > 0) {
      this.tasbihs = TasbihManager.renameTasbih(
        this.tasbihs, this.editingTasbihId, finalName, this.formThemePresetId
      );
      this.tasbihs = TasbihManager.setTheme(
        this.tasbihs, this.editingTasbihId, this.formThemePresetId
      );
      this.tasbihs = TasbihManager.updateBinding(
        this.tasbihs, this.editingTasbihId, this.formBoundPrayerIds
      );
    } else {
      const res = TasbihManager.addTasbih(this.tasbihs, finalName, this.formThemePresetId);
      this.tasbihs = res.tasbihs;
      this.tasbihs = TasbihManager.updateBinding(this.tasbihs, res.newId, this.formBoundPrayerIds);
      this.activeTasbihId = res.newId;
      this.activeDhikrIndex = 0;
    }

    this.resolveActiveTheme();
    this.persist();
    this.refreshBeadView();
    this.activeSheet = 'none';
    console.info('[Tasbih Page]SAVED BINDINGS:', JSON.stringify(this.formBoundPrayerIds));
  }

  private deleteTasbih(id: string): void {
    if (this.tasbihs.length <= 1) {
      return;
    }
    const wasActive = this.activeTasbihId === id;
    this.tasbihs = TasbihManager.removeTasbih(this.tasbihs, id);
    if (wasActive) {
      this.activeTasbihId = this.tasbihs[0].id;
      this.activeDhikrIndex = 0;
    }
    this.resolveActiveTheme();
    this.refreshBeadView();
    this.persist();
  }

  private selectTasbih(id: string): void {
    this.activeTasbihId = id;
    this.activeDhikrIndex = 0;
    this.resolveActiveTheme();
    this.refreshBeadView();
    this.persist();
    this.activeSheet = 'none';
  }

  private selectDhikr(index: number): void {
    this.activeDhikrIndex = index;
    this.refreshBeadView();
    this.persist();
    this.activeSheet = 'none';
  }

  private openNewDhikrEditor(): void {
    this.editingDhikrId = '';
    this.formDhikrArabic = '';
    this.formDhikrTranslit = '';
    this.formDhikrTranslation = '';
    this.formDhikrTarget = '33';
    this.activeSheet = 'dhikrEditor';
  }

  private openEditDhikrEditor(d: Dhikr): void {
    this.editingDhikrId = d.id;
    this.formDhikrArabic = d.arabic;
    this.formDhikrTranslit = this.getDhikrLabel(d); // Uses translation
    this.formDhikrTranslation = this.getDhikrTranslation(d); // Uses translation
    this.formDhikrTarget = d.target.toString();
    this.activeSheet = 'dhikrEditor';
  }

  private saveDhikr(): void {
    const arabic = this.formDhikrArabic.trim();
    const translit = this.formDhikrTranslit.trim();
    const translation = this.formDhikrTranslation.trim();
    const targetNum = parseInt(this.formDhikrTarget, 10);

    if (arabic.length === 0 && translit.length === 0) {
      return;
    }
    const target = isNaN(targetNum) || targetNum <= 0 ? 33 : targetNum;

    const fields: DhikrFields = {
      arabic,
      transliteration: translit,
      translation,
      target
    };

    if (this.editingDhikrId.length > 0) {
      this.tasbihs = TasbihManager.updateDhikr(
        this.tasbihs, this.activeTasbihId, this.editingDhikrId, fields
      );
    } else {
      this.tasbihs = TasbihManager.addDhikr(
        this.tasbihs, this.activeTasbihId, fields
      );
      const t = this.getActiveTasbih();
      if (t) {
        this.activeDhikrIndex = t.dhikrs.length - 1;
      }
    }
    this.refreshBeadView();
    this.persist();
    this.activeSheet = 'none';
  }

  private deleteDhikr(id: string): void {
    this.tasbihs = TasbihManager.removeDhikr(
      this.tasbihs, this.activeTasbihId, id
    );
    this.activeDhikrIndex = 0;
    this.refreshBeadView();
    this.persist();
  }

  private getTasbihName(t: Tasbih | null): string {
    if (!t) {
      return '';
    }
    return (t.nameKey && t.nameKey.length > 0)
      ? L.get(t.nameKey, this.currentLanguage)
      : t.name;
  }

  private getDhikrLabel(d: Dhikr | null): string {
    if (!d) {
      return '';
    }
    const trans = (d.transliterationKey && d.transliterationKey.length > 0)
      ? L.get(d.transliterationKey, this.currentLanguage)
      : d.transliteration;
    return trans.length > 0 ? trans : d.arabic;
  }

  private getDhikrTranslation(d: Dhikr | null): string {
    if (!d) {
      return '';
    }
    return (d.translationKey && d.translationKey.length > 0)
      ? L.get(d.translationKey, this.currentLanguage) : d.translation;
  }
}