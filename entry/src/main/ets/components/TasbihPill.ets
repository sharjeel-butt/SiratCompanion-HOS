import { common } from '@kit.AbilityKit';
import { ThemeColors } from '../common/Theme';
import { L } from '../i8n/LocalizationHelper';
import { STORAGE_KEY_TASBIH_STATE_VERSION } from '../common/StorageKeys';
import { TasbihStorage } from '../tasbih/TasbihStorage';
import { TasbihManager } from '../tasbih/TasbihManager';
import { Dhikr, Tasbih } from '../tasbih/TasbihModels';

@Component
export struct TasbihPill {
  @Prop colors: ThemeColors;
  @Prop @Watch('onLanguageChanged') currentLanguage: string;
  @Prop @Watch('onPrayerChanged') prayerName: string = '';
  // ADDED: Callback to navigate
  onNavigate: (tasbihId: string, dhikrIndex: number, prayerId: string) => void = () => {
  };
  @StorageLink(STORAGE_KEY_TASBIH_STATE_VERSION)
  @Watch('onTasbihUpdate')
  tasbihVersion: number = 0;
  @State private boundTasbihs: Tasbih[] = [];
  @State private hasTasbih: boolean = false;
  @State private isRtl: boolean = false;
  @State private showPopup: boolean = false;
  private prayerId: string = '';
  private todayKey: string = '';
  private dateCheckTimer: number = -1;

  aboutToAppear(): void {
    this.isRtl = L.isRtlLang(this.currentLanguage);
    this.todayKey = TasbihManager.todayKey();
    this.loadTasbihData();
    // Check for date change every 60 seconds
    this.dateCheckTimer = setInterval(() => {
      const now = TasbihManager.todayKey();
      if (this.todayKey !== now) {
        this.todayKey = now;
        this.loadTasbihData(); // This will trigger the cache reset logic
      }
    }, 60000);
  }

  aboutToDisappear(): void {
    if (this.dateCheckTimer !== -1) {
      clearInterval(this.dateCheckTimer);
    }
  }

  onLanguageChanged(): void {
    this.isRtl = L.isRtlLang(this.currentLanguage);
  }

  onPrayerChanged(): void {
    this.loadTasbihData();
  }

  onTasbihUpdate(): void {
    this.loadTasbihData();
  }

  private async loadTasbihData(): Promise<void> {
    if (!this.prayerName || this.prayerName === '—') {
      this.hasTasbih = false;
      return;
    }

    this.prayerId = this.prayerName.toLowerCase().replace('jummah', 'dhuhr');
    if (!['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'].includes(this.prayerId)) {
      this.hasTasbih = false;
      return;
    }

    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      await TasbihStorage.init(ctx);
      const loaded = await TasbihStorage.load(TasbihManager.createDefaults());

      this.boundTasbihs = loaded.tasbihs.filter(t => t.boundPrayerIds?.includes(this.prayerId));
      this.hasTasbih = this.boundTasbihs.length > 0;
    } catch (e) {
      this.hasTasbih = false;
    }
  }

  private getPillText(): string {
    if (this.boundTasbihs.length === 0) {
      return '';
    }
    const first = this.boundTasbihs[0];
    const name = first.nameKey ? L.get(first.nameKey, this.currentLanguage) : first.name;
    if (this.boundTasbihs.length > 1) {
      return `${name} (+${this.boundTasbihs.length - 1})`;
    }
    return name;
  }

  private getDhikrName(d: Dhikr): string {
    let name = d.transliterationKey ? L.get(d.transliterationKey, this.currentLanguage) : d.transliteration;
    return name || d.arabic;
  }

  private getDhikrCount(d: Dhikr): number {
    if (d.liveCounts && d.liveCounts[this.prayerId] !== undefined) {
      return d.liveCounts[this.prayerId];
    }
    return d.count;
  }

  @Builder
  PopupContent() {
    Column() {
      Scroll() {
        Column() {
          ForEach(this.boundTasbihs, (t: Tasbih) => {
            this.TasbihGroup(t)
          })
        }
        .width('100%')
        .padding(16)
        .direction(this.isRtl ? Direction.Rtl : Direction.Ltr)
      }
      .width('100%')
      .constraintSize({ maxHeight: 400 })
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      .direction(this.isRtl ? Direction.Rtl : Direction.Ltr)
    }
    .width(260) // Slightly wider to accommodate the arrow
    .backgroundColor(this.colors.cardDark)
    .borderRadius(16)
    .border({ width: 1, color: this.colors.borderSoft })
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.3)', offsetY: 4 })
    .clip(true)
  }

  @Builder
  TasbihGroup(t: Tasbih) {
    Column() {
      // Header
      Row({ space: 8 }) {
        Text('📿').fontSize(16)
        Text(t.nameKey ? L.get(t.nameKey, this.currentLanguage) : t.name)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .layoutWeight(1)
          .textAlign(TextAlign.Start)

        if (TasbihManager.isTasbihCompleteForPrayer(t, this.prayerId, this.todayKey)) {
          Text('✓').fontSize(14).fontColor(this.colors.accentGold).fontWeight(FontWeight.Bold)
        }
      }
      .width('100%')
      .padding({ bottom: 8 })
      .direction(this.isRtl ? Direction.Rtl : Direction.Ltr)

      // Dhikrs
      ForEach(t.dhikrs, (d: Dhikr, index: number) => {
        Row({ space: 8 }) {
          Text(this.getDhikrName(d))
            .fontSize(13)
            .fontColor(this.colors.textWhite)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Start)

          Text(`${this.getDhikrCount(d)}/${d.target}`)
            .fontSize(13).fontWeight(FontWeight.Bold)
            .fontColor(this.getDhikrCount(d) >= d.target ? this.colors.accentGold : this.colors.textMuted)
            .direction(Direction.Ltr)

          // ADDED: Anchor icon to navigate
          Image($r('app.media.ic_chevron_right'))
            .width(12)
            .height(12)
            .fillColor(this.colors.accentGold)
            .opacity(0.7)
            .rotate({ angle: this.isRtl ? 180 : 0 })
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        .direction(this.isRtl ? Direction.Rtl : Direction.Ltr)
        // ADDED: onClick handler
        .onClick(() => {
          this.onNavigate(t.id, index, this.prayerId);
          this.showPopup = false;
        })
      })

      Divider().color(this.colors.borderSoft).margin({ top: 8, bottom: 8 })
    }
    .width('100%')
  }

  build() {
    if (this.hasTasbih) {
      Row({ space: 4 }) {
        Text('📿').fontSize(11).opacity(0.8).flexShrink(0)
        Text(this.getPillText())
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.accentGold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          .textAlign(TextAlign.Start)

        Image($r('app.media.ic_chevron_right'))
          .width(10)
          .height(10)
          .fillColor(this.colors.accentGold)
          .rotate({ angle: 90 })
          .flexShrink(0)
      }
      .constraintSize({ maxWidth: '40%' })
      .height(52)
      .padding({ left: 10, right: 8 })
      .backgroundColor(this.colors.cardDark)
      .borderRadius(19)
      .border({ width: 1, color: this.colors.borderSoft })
      .alignItems(VerticalAlign.Center)
      .direction(this.isRtl ? Direction.Rtl : Direction.Ltr)
      .onClick(() => {
        this.showPopup = !this.showPopup;
      })
      .bindPopup(this.showPopup, {
        builder: this.PopupContent.bind(this),
        placement: Placement.Bottom,
        popupColor: Color.Transparent,
        onStateChange: (e) => {
          if (!e.isVisible) {
            this.showPopup = false;
          }
        }
      })
    }
  }
}