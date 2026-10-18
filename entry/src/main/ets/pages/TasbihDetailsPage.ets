// entry/src/main/ets/pages/TasbihDetailsPage.ets

import { mediaquery, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { Theme, ThemeColors, ThemeMode, ThemePreset } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import {
  STORAGE_KEY_APP_FOREGROUND_TICK,
  STORAGE_KEY_APP_THEME,
  STORAGE_KEY_BREAKPOINT,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_TASBIH_STATE_VERSION,
  STORAGE_KEY_THEME_MODE
} from '../common/StorageKeys';
import { L } from '../i8n/LocalizationHelper';
import { Breakpoints } from '../common/Breakpoints';
import { Tasbih } from '../tasbih/TasbihModels';
import { TasbihManager } from '../tasbih/TasbihManager';
import { TasbihStorage } from '../tasbih/TasbihStorage';
import {
  ProgressHelper,
  TasbihDetailsSnapshot,
  TasbihDhikrProgress,
  TasbihPeriod,
  TasbihProgressRow
} from '../utils/ProgressHelper';
import { TasbihThemes } from '../tasbih/TasbihThemes';

@Entry
@Component
struct TasbihDetailsPage {
  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;
  @StorageLink(STORAGE_KEY_TASBIH_STATE_VERSION)
  @Watch('onTasbihStateChanged')
  tasbihStateVersion: number = 0;
  @StorageLink(STORAGE_KEY_LANGUAGE)
  appLanguage: string = 'en';
  @StorageLink(STORAGE_KEY_APP_THEME)
  @Watch('onAppThemePresetChanged')
  appThemePreset: string = ThemePreset.SIRAT;
  @StorageLink(STORAGE_KEY_APP_FOREGROUND_TICK)
  @Watch('onAppForegrounded')
  appForegroundTick: number = 0;
  @StorageLink(STORAGE_KEY_BREAKPOINT)
  breakpoint: string = 'sm';
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  @State period: TasbihPeriod = 'week';
  @State snapshot: TasbihDetailsSnapshot = {
    rows: [],
    totalDaysCompleted: 0,
    totalDaysPossible: 0,
    totalCountInPeriod: 0,
    daysInPeriod: 7
  };
  private tasbihs: Tasbih[] = [];
  private activeId: string = '';
  private systemDarkListener: mediaquery.MediaQueryListener | null = null;

  aboutToAppear(): void {
    this.colors = PageTheme.compute(this.themeMode);
    this.systemDarkListener = PageTheme.installSystemListener(
      this.themeMode, (c) => {
      this.colors = c;
    }
    );

    const ctx = getContext(this) as common.UIAbilityContext;
    TasbihStorage.init(ctx).then(() => {
      this.reload();
    });
  }

  aboutToDisappear(): void {
    PageTheme.uninstallSystemListener(this.systemDarkListener);
    this.systemDarkListener = null;
  }

  onPageShow(): void {
    this.colors = PageTheme.compute(this.themeMode);
    this.reload();
  }

  private async reload(): Promise<void> {
    const loaded = await TasbihStorage.load(TasbihManager.createDefaults());
    this.tasbihs = loaded.tasbihs;
    this.activeId = loaded.activeTasbihId;
    this.recompute();
  }

  private recompute(): void {
    this.snapshot = ProgressHelper.getTasbihDetails(
      this.tasbihs, this.activeId, this.period
    );
  }

  private onThemeModeChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onAppThemePresetChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onTasbihStateChanged(): void {
    this.reload();
  }

  private async onAppForegrounded(): Promise<void> {
    await this.reload();
  }

  private tr(key: string): string {
    return L.get(key, this.appLanguage);
  }

  private isRtl(): boolean {
    return L.isRtlLang(this.appLanguage);
  }

  private percentForPeriod(): number {
    if (this.snapshot.totalDaysPossible === 0) {
      return 0;
    }
    return Math.round(
      this.snapshot.totalDaysCompleted / this.snapshot.totalDaysPossible * 100
    );
  }

  build() {
    Stack() {
      Column() {
        this.TopBar()

        Scroll() {
          Row() {
            Column() {
              this.PeriodSelector()
              this.SummaryCard()

              ForEach(this.snapshot.rows, (row: TasbihProgressRow) => {
                this.TasbihCard(row)
              }, (row: TasbihProgressRow) =>
              `t-${row.tasbihId}-${this.period}-${row.totalDaysCompleted}-${row.totalDaysPossible}`)

              Column().height(40)
            }
            .width('100%')
            .constraintSize({
              maxWidth: Breakpoints.maxContentWidth(this.breakpoint)
            })
            .padding({ left: 16, right: 16, top: 16 })
          }
          .width('100%').justifyContent(FlexAlign.Center)
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
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
  }

  @Builder
  TopBar() {
    Row() {
      Text('←')
        .fontSize(26)
        .fontColor(this.colors.textWhite)
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .borderRadius(20)
        .backgroundColor(this.colors.tintSoft)
        .margin({ left: 16 })
        .onClick(() => router.back())

      Text(this.tr('title_tasbih_details'))
        .fontSize(22).fontWeight(FontWeight.Bold)
        .fontColor(this.colors.textWhite)
        .letterSpacing(-0.5)
        .margin({ left: 16 })
    }
    .width('100%').height(72)
    .backgroundColor(this.colors.cardDark)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  PeriodSelector() {
    Row() {
      this.PeriodChip('week')
      this.PeriodChip('month')
      this.PeriodChip('year')
    }
    .width('100%')
    .padding(4)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(12)
    .border({ width: 1, color: this.colors.borderSoft })
    .margin({ bottom: 14 })
  }

  @Builder
  PeriodChip(id: string) {
    Text(this.periodLabel(id))
      .fontSize(13)
      .fontWeight(this.period === id ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.period === id
        ? this.colors.textOnAccent : this.colors.textWhite)
      .backgroundColor(this.period === id
        ? this.colors.accentGold : Color.Transparent)
      .textAlign(TextAlign.Center)
      .height(38)
      .layoutWeight(1)
      .borderRadius(9)
      .onClick(() => {
        this.period = id as TasbihPeriod;
        this.recompute();
      })
  }

  private periodLabel(id: string): string {
    if (id === 'week') {
      return this.tr('details_period_week');
    }
    if (id === 'month') {
      return this.tr('details_period_month');
    }
    return this.tr('details_period_year');
  }

  @Builder
  SummaryCard() {
    Column() {
      Row() {
        Column() {
          Row() {
            Text(`${this.snapshot.totalDaysCompleted}`)
              .fontSize(48).fontWeight(FontWeight.Bold)
              .fontColor(this.colors.textWhite)
              .fontFeature('"tnum" 1')
            Text(` / ${this.snapshot.totalDaysPossible}`)
              .fontSize(20).fontColor(this.colors.textMuted)
              .margin({ left: 4, bottom: 8 })
          }
          .alignItems(VerticalAlign.Bottom)

          Text(this.tr('details_tasbih_summary_dhikrs'))
            .fontSize(12).fontColor(this.colors.textMuted)
            .margin({ top: -4 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Stack() {
          Circle()
            .width(72)
            .height(72)
            .fill(Color.Transparent)
            .stroke(this.colors.tintMedium)
            .strokeWidth(6)
          Circle()
            .width(72)
            .height(72)
            .fill(Color.Transparent)
            .stroke(this.colors.accentGold)
            .strokeWidth(6)
            .strokeDashArray([this.percentForPeriod() / 100 * 226.2, 500])
            .strokeLineCap(LineCapStyle.Round)
            .rotate({ angle: -90 })
          Text(`${this.percentForPeriod()}%`)
            .fontSize(15).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textWhite)
        }
        .width(72).height(72)
      }
      .width('100%')

      Row() {
        Column() {
          Text(`${this.snapshot.totalCountInPeriod}`)
            .fontSize(20).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.accentGold)
          Text(this.tr('details_tasbih_summary_lifetime'))
            .fontSize(10).fontColor(this.colors.textMuted)
            .margin({ top: 2 })
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Start)
      }
      .width('100%').margin({ top: 16 })
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusLarge)
    .border({
      width: 1,
      color: PageTheme.isDarkFor(this.themeMode)
        ? 'rgba(255, 255, 255, 0.08)'
        : this.colors.borderSoft
    })
    .shadow({
      radius: 16,
      color: PageTheme.isDarkFor(this.themeMode)
        ? 'rgba(0, 0, 0, 0.35)'
        : 'rgba(0, 0, 0, 0.08)',
      offsetX: 0,
      offsetY: 6
    })
    .margin({ bottom: 14 })
  }

  @Builder
  TasbihCard(row: TasbihProgressRow) {
    Column() {
      Row() {
        Column()
          .width(14)
          .height(14)
          .borderRadius(7)
          .backgroundColor(TasbihThemes.presetById(
            row.themePresetId.length > 0
              ? row.themePresetId
              : TasbihThemes.DEFAULT_PRESET_ID
          ).swatch)

        Text(row.tasbihName)
          .fontSize(16)
          .fontColor(this.colors.textWhite)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ left: 12 })

        if (row.isActive) {
          Text('●')
            .fontSize(8).fontColor(this.colors.accentGold)
            .margin({ right: 6 })
        }

        Text(`${row.totalDaysCompleted} / ${row.totalDaysPossible}`)
          .fontSize(13).fontColor(this.colors.accentGold)
          .fontWeight(FontWeight.Bold)
          .direction(Direction.Ltr)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding({ bottom: 12 })

      if (row.perDhikr.length === 0) {
        Text(this.tr('no_dhikr_title'))
          .fontSize(12).fontColor(this.colors.textMuted)
          .width('100%').padding({ top: 4, bottom: 8 })
      } else {
        ForEach(row.perDhikr, (p: TasbihDhikrProgress) => {
          this.DhikrRow(p)
        }, (p: TasbihDhikrProgress) =>
        `d-${p.dhikrId}-${p.daysCompleted}-${p.daysInPeriod}-${this.period}`)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.colors.tintSubtle)
    .borderRadius(14)
    .margin({ bottom: 8 })
  }

  @Builder
  DhikrRow(p: TasbihDhikrProgress) {
    Column() {
      Row() {
        Text(p.dhikrLabel)
          .fontSize(14)
          .fontColor(this.colors.textWhite)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${p.daysCompleted} / ${p.daysInPeriod} ${this.tr('home_days')}`)
          .fontSize(12).fontColor(this.colors.accentGold)
          .fontWeight(FontWeight.Medium)
          .direction(Direction.Ltr)
      }
      .width('100%')

      Row() {
        Row()
          .width(`${p.daysInPeriod > 0
            ? Math.round(p.daysCompleted / p.daysInPeriod * 100) : 0}%`)
          .height(5)
          .backgroundColor(this.colors.accentGold)
          .borderRadius(3)
      }
      .width('100%')
      .height(5)
      .backgroundColor(this.colors.tintMedium)
      .borderRadius(3)
      .margin({ top: 6 })

      Row() {
        Text(`${p.totalCount}`)
          .fontSize(10).fontColor(this.colors.textMuted)
          .direction(Direction.Ltr)
        Text(` · ${this.tr('target_count')} ${p.target}`)
          .fontSize(10).fontColor(this.colors.textMuted)
          .direction(Direction.Ltr)
      }
      .width('100%').margin({ top: 4 })
    }
    .width('100%')
    .padding({
      top: 8,
      bottom: 8,
      left: 8,
      right: 8
    })
    .margin({ bottom: 4 })
  }
}