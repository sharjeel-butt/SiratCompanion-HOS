// entry/src/main/ets/pages/TasbihPage.ets

import { router } from '@kit.ArkUI';
import { mediaquery } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { ThemeColors, ThemeMode } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import {
  STORAGE_KEY_THEME_MODE,
  STORAGE_KEY_NAV_DIRECTION,
  STORAGE_KEY_LANGUAGE
} from '../common/StorageKeys';
import { Tasbih, Dhikr, DhikrFields, BeadView } from '../models/TasbihModels';
import { TasbihManager } from '../utils/TasbihManager';
import { TasbihStorage } from '../utils/TasbihStorage';
import { NavHelper } from '../helper/NavHelper';
import { HapticHelper } from '../helper/HapticHelper';
import { L } from '../helper/LocalizationHelper';

// ============================================================
// BEAD VISUAL CONSTANTS
// ============================================================

const BEAD_SIZE       = 24;
const BEAD_GAP        = 6;
const SWIPE_THRESHOLD = 50;
const STRING_WIDTH    = 2;
const STRING_LINE_COLOR = 'rgba(232, 164, 76, 0.35)';

const SHADE_HEAD_HI    = '#F5C57A';
const SHADE_HEAD_BASE  = '#D18F35';
const SHADE_HEAD_LO    = '#7A4A10';

const SHADE_GOLD_HI    = '#FFE0A0';
const SHADE_GOLD_BASE  = '#E8A44C';
const SHADE_GOLD_LO    = '#8B5A1A';

const SHADE_DONE_HI    = '#A7F3C0';
const SHADE_DONE_BASE  = '#4ADE80';
const SHADE_DONE_LO    = '#1E7A4E';

const SHADE_PEND_HI_L  = '#EFEAE0';
const SHADE_PEND_BASE_L = '#C9C2B8';
const SHADE_PEND_LO_L  = '#8E8878';

const SHADE_PEND_HI_D  = '#5A5A5A';
const SHADE_PEND_BASE_D = '#3A3A3A';
const SHADE_PEND_LO_D  = '#1A1A1A';

@Entry
@Component
struct TasbihPage {

  // ============================================================
  // THEME + NAV + LANGUAGE
  // ============================================================

  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;

  @StorageLink(STORAGE_KEY_NAV_DIRECTION)
  navDirection: string = 'forward';

  @StorageLink(STORAGE_KEY_LANGUAGE)
  @Watch('onLanguageChanged')
  appLanguage: string = 'en';

  /** Plain @State mirror — guarantees a re-render on language change. */
  @State private currentLanguage: string = 'en';

  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  private systemDarkListener: mediaquery.MediaQueryListener | null = null;

  // ============================================================
  // DATA
  // ============================================================

  @State tasbihs: Tasbih[] = [];
  @State activeTasbihId: string = '';
  @State activeDhikrIndex: number = 0;

  @State private beadView: BeadView = {
    topIds: [], bottomIds: [], isComplete: false, topAtCap: false, bottomAtCap: false
  };
  @State private topPulseTick: number = 0;

  // ============================================================
  // OVERLAYS
  // ============================================================

  @State showTasbihPicker: boolean = false;
  @State showDhikrPicker: boolean = false;
  @State showTasbihEditor: boolean = false;
  @State showDhikrEditor: boolean = false;

  @State editingTasbihId: string = '';
  @State formTasbihName: string = '';

  @State editingDhikrId: string = '';
  @State formDhikrArabic: string = '';
  @State formDhikrTranslit: string = '';
  @State formDhikrTranslation: string = '';
  @State formDhikrTarget: string = '33';

  // ============================================================
  // SWIPE + ADVANCE LOCK
  // ============================================================

  private swipeStartY: number = 0;
  private swipeLastY: number = 0;
  private advanceLock: boolean = false;

  // ============================================================
  // LOCALIZATION + DIRECTION HELPERS
  // ============================================================

  private tr(key: string): string {
    return L.get(key, this.currentLanguage);
  }

  private isRtl(): boolean {
    return L.isRtlLang(this.currentLanguage);
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

  // ============================================================
  // PAGE TRANSITION
  // ============================================================

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

  // ============================================================
  // LIFECYCLE
  // ============================================================

  async aboutToAppear(): Promise<void> {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
    this.systemDarkListener = PageTheme.installSystemListener(this.themeMode, (c) => {
      this.colors = c;
    });

    const ctx = getContext(this) as common.UIAbilityContext;
    await TasbihStorage.init(ctx);
    const loaded = await TasbihStorage.load(TasbihManager.createDefaults());
    this.tasbihs = loaded.tasbihs;
    this.activeTasbihId = loaded.activeTasbihId;
    this.activeDhikrIndex = loaded.activeDhikrIndex;
    this.refreshBeadView();
  }

  aboutToDisappear(): void {
    PageTheme.uninstallSystemListener(this.systemDarkListener);
    this.systemDarkListener = null;
  }

  onPageShow(): void {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
    this.refreshBeadView();
  }

  onBackPress(): boolean {
    NavHelper.prepareBackward();
    return false;
  }

  // ============================================================
  // LOOKUP / DERIVED STATE
  // ============================================================

  private getActiveTasbih(): Tasbih | null {
    return TasbihManager.findTasbih(this.tasbihs, this.activeTasbihId);
  }

  private getActiveDhikr(): Dhikr | null {
    return TasbihManager.getActiveDhikr(this.tasbihs, this.activeTasbihId, this.activeDhikrIndex);
  }

  private getLifetimeCount(): number {
    const t = this.getActiveTasbih();
    return t ? (t.lifetimeCount || 0) : 0;
  }

  private refreshBeadView(): void {
    const dhikr = this.getActiveDhikr();
    const next = TasbihManager.computeBeadView(dhikr);

    const topSame = next.topIds.length === this.beadView.topIds.length;

    if (topSame && next.topAtCap && next.topIds.length > 0) {
      this.topPulseTick = this.topPulseTick + 1;
    }

    this.beadView = next;
  }

  private persist(): void {
    TasbihStorage.save(this.tasbihs, this.activeTasbihId, this.activeDhikrIndex);
  }

  // ============================================================
  // COUNTING
  // ============================================================

  private increment(): void {
    if (this.advanceLock) return;

    const dhikr = this.getActiveDhikr();
    if (!dhikr) return;

    HapticHelper.tick();

    animateTo({ duration: 260, curve: Curve.EaseOut }, () => {
      this.tasbihs = TasbihManager.increment(this.tasbihs, this.activeTasbihId, dhikr.id);
      this.refreshBeadView();
    });

    const updatedDhikr = this.getActiveDhikr();
    if (!updatedDhikr) {
      this.persist();
      return;
    }

    const isComplete = updatedDhikr.count >= updatedDhikr.target;
    const tasbih = this.getActiveTasbih();
    const hasNext = tasbih !== null && this.activeDhikrIndex < tasbih.dhikrs.length - 1;

    if (isComplete && hasNext) {
      this.persist();
      this.advanceLock = true;
      HapticHelper.confirm();

      setTimeout(() => {
        animateTo({ duration: 260, curve: Curve.EaseOut }, () => {
          this.activeDhikrIndex = this.activeDhikrIndex + 1;
          this.refreshBeadView();
        });
        this.advanceLock = false;
        this.persist();
      }, 400);
      return;
    }

    if (isComplete && !hasNext) {
      HapticHelper.confirm();
      this.getUIContext().getPromptAction().showToast({
        message: this.tr('all_dhikrs_complete'), duration: 1800
      });
    }

    this.persist();
  }

  private decrement(): void {
    if (this.advanceLock) return;

    const dhikr = this.getActiveDhikr();
    if (!dhikr || dhikr.count === 0) return;

    HapticHelper.tick();

    animateTo({ duration: 260, curve: Curve.EaseOut }, () => {
      this.tasbihs = TasbihManager.decrement(this.tasbihs, this.activeTasbihId, dhikr.id);
      this.refreshBeadView();
    });
    this.persist();
  }

  private resetCurrent(): void {
    if (this.advanceLock) return;

    const dhikr = this.getActiveDhikr();
    if (!dhikr) return;

    animateTo({ duration: 260, curve: Curve.EaseOut }, () => {
      this.tasbihs = TasbihManager.reset(this.tasbihs, this.activeTasbihId, dhikr.id);
      this.refreshBeadView();
    });
    this.persist();
    this.getUIContext().getPromptAction().showToast({
      message: this.tr('counter_reset_toast'), duration: 1200
    });
  }

  // ============================================================
  // SWIPE — vertical
  // ============================================================

  private handleSwipe(event: TouchEvent): void {
    if (event.touches && event.touches.length > 0) {
      const y = event.touches[0].y;
      if (event.type === TouchType.Down) {
        this.swipeStartY = y;
        this.swipeLastY = y;
      } else if (event.type === TouchType.Move) {
        this.swipeLastY = y;
      }
    }
    if (event.type === TouchType.Up) {
      const delta = this.swipeLastY - this.swipeStartY;
      if (Math.abs(delta) > SWIPE_THRESHOLD) {
        if (delta < 0) this.increment();
        else this.decrement();
      }
    }
  }

  // ============================================================
  // TASBIH CRUD
  // ============================================================

  private openNewTasbihEditor(): void {
    this.editingTasbihId = '';
    this.formTasbihName = '';
    this.showTasbihPicker = false;
    this.showTasbihEditor = true;
  }

  private openEditTasbihEditor(t: Tasbih): void {
    this.editingTasbihId = t.id;
    this.formTasbihName = t.name;
    this.showTasbihPicker = false;
    this.showTasbihEditor = true;
  }

  private saveTasbih(): void {
    const name = this.formTasbihName.trim();
    if (name.length === 0) return;

    if (this.editingTasbihId.length > 0) {
      this.tasbihs = TasbihManager.renameTasbih(this.tasbihs, this.editingTasbihId, name);
    } else {
      const res = TasbihManager.addTasbih(this.tasbihs, name);
      this.tasbihs = res.tasbihs;
      this.activeTasbihId = res.newId;
      this.activeDhikrIndex = 0;
    }
    this.refreshBeadView();
    this.persist();
    this.showTasbihEditor = false;
  }

  private deleteTasbih(id: string): void {
    if (this.tasbihs.length <= 1) {
      this.showTasbihPicker = false;
      return;
    }
    const wasActive = this.activeTasbihId === id;
    this.tasbihs = TasbihManager.removeTasbih(this.tasbihs, id);
    if (wasActive) {
      this.activeTasbihId = this.tasbihs[0].id;
      this.activeDhikrIndex = 0;
    }
    this.refreshBeadView();
    this.persist();
    this.showTasbihPicker = false;
  }

  private selectTasbih(id: string): void {
    this.activeTasbihId = id;
    this.activeDhikrIndex = 0;
    this.refreshBeadView();
    this.persist();
    this.showTasbihPicker = false;
  }

  private selectDhikr(index: number): void {
    this.activeDhikrIndex = index;
    this.refreshBeadView();
    this.persist();
    this.showDhikrPicker = false;
  }

  // ============================================================
  // DHIKR CRUD
  // ============================================================

  private openNewDhikrEditor(): void {
    this.editingDhikrId = '';
    this.formDhikrArabic = '';
    this.formDhikrTranslit = '';
    this.formDhikrTranslation = '';
    this.formDhikrTarget = '33';
    this.showDhikrPicker = false;
    this.showDhikrEditor = true;
  }

  private openEditDhikrEditor(d: Dhikr): void {
    this.editingDhikrId = d.id;
    this.formDhikrArabic = d.arabic;
    this.formDhikrTranslit = d.transliteration;
    this.formDhikrTranslation = d.translation;
    this.formDhikrTarget = d.target.toString();
    this.showDhikrPicker = false;
    this.showDhikrEditor = true;
  }

  private saveDhikr(): void {
    const arabic = this.formDhikrArabic.trim();
    const translit = this.formDhikrTranslit.trim();
    const translation = this.formDhikrTranslation.trim();
    const targetNum = parseInt(this.formDhikrTarget, 10);

    if (arabic.length === 0 && translit.length === 0) return;
    const target = isNaN(targetNum) || targetNum <= 0 ? 33 : targetNum;

    const fields: DhikrFields = {
      arabic, transliteration: translit, translation, target
    };

    if (this.editingDhikrId.length > 0) {
      this.tasbihs = TasbihManager.updateDhikr(
        this.tasbihs, this.activeTasbihId, this.editingDhikrId, fields
      );
    } else {
      this.tasbihs = TasbihManager.addDhikr(this.tasbihs, this.activeTasbihId, fields);
      const t = this.getActiveTasbih();
      if (t) this.activeDhikrIndex = t.dhikrs.length - 1;
    }
    this.refreshBeadView();
    this.persist();
    this.showDhikrEditor = false;
  }

  private deleteDhikr(id: string): void {
    this.tasbihs = TasbihManager.removeDhikr(this.tasbihs, this.activeTasbihId, id);
    this.activeDhikrIndex = 0;
    this.refreshBeadView();
    this.persist();
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  private onFloatingBarTap(tabId: string): void {
    if (tabId === 'tasbih') return;

    if (tabId === 'home') {
      NavHelper.prepareBackward();
      try { router.back({ url: 'pages/Index' }); }
      catch (err) {
        router.clear();
        NavHelper.prepare('home', 'tasbih');
        router.pushUrl({ url: 'pages/Index' })
          .catch((e: Error) => console.error('Navigation failed:', JSON.stringify(e)));
      }
      return;
    }

    if (tabId === 'compass') {
      NavHelper.prepare('compass', 'tasbih');
      router.pushUrl({ url: 'pages/QiblaPage' })
        .catch((err: Error) => console.error('Navigation failed:', JSON.stringify(err)));
      return;
    }

    if (tabId === 'calendar') {
      NavHelper.prepare('calendar', 'tasbih');
      router.pushUrl({ url: 'pages/HijriCalendarPage' })
        .catch((err: Error) => console.error('Navigation failed:', JSON.stringify(err)));
    }
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
        this.TopBar()

        Row() {
          // LEFT COLUMN — Arabic text, counter, hint, reset
          Column() {
            if (this.getActiveDhikr() !== null) {
              Text(this.getActiveDhikr()!.arabic)
                .fontSize(22)
                .fontColor(this.colors.textWhite)
                .textAlign(TextAlign.Start)
                .lineHeight(34)
                .width('100%')

              Blank().layoutWeight(1)

              Column() {
                Text(`${this.getActiveDhikr()!.count}`)
                  .fontSize(96)
                  .fontWeight(FontWeight.Normal)
                  .fontColor(this.beadView.isComplete ? SHADE_DONE_BASE : this.colors.textWhite)

                Text(`${this.tr('target_count')} ${this.getActiveDhikr()!.target}`)
                  .fontSize(16)
                  .fontColor(this.colors.textMuted)
                  .margin({ top: -6 })

                Text(`${this.getLifetimeCount()} ${this.tr('total_on_tasbih')}`)
                  .fontSize(12)
                  .fontColor(this.colors.textMuted)
                  .opacity(0.7)
                  .margin({ top: 6 })
              }
              .alignItems(HorizontalAlign.Start)

              Row() {
                Text('↑').fontSize(18).fontColor(this.colors.textMuted).opacity(0.5)
                Text(`  ${this.tr('flick_up_to_count')}  `)
                  .fontSize(12).fontColor(this.colors.textMuted).letterSpacing(1)
              }
              .margin({ top: 24 })

              Text(this.tr('flick_hint'))
                .fontSize(10).fontColor(this.colors.textMuted).opacity(0.7)
                .margin({ top: 6 })

              Row() {
                Text('↺').fontSize(14).fontColor(this.colors.textMuted)
                Text(this.tr('reset')).fontSize(12).fontColor(this.colors.textMuted).margin({ left: 6 })
              }
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .backgroundColor(this.colors.tintSubtle)
              .borderRadius(16)
              .border({ width: 1, color: this.colors.borderSoft })
              .margin({ top: 20, bottom: 8 })
              .onClick(() => { this.resetCurrent(); })
            } else {
              this.EmptyState()
            }
          }
          .layoutWeight(1)
          .height('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 24, right: 8, top: 16, bottom: 110 })

          // RIGHT COLUMN — Vertical bead string
          this.BeadStringColumn()
        }
        .layoutWeight(1)
        .width('100%')
        .alignItems(VerticalAlign.Top)
        .onTouch((event: TouchEvent) => { this.handleSwipe(event); })
      }
      .width('100%').height('100%')

      this.FloatingBar()

      if (this.showTasbihPicker) { this.TasbihPicker() }
      if (this.showDhikrPicker)  { this.DhikrPicker() }
      if (this.showTasbihEditor) { this.TasbihEditor() }
      if (this.showDhikrEditor)  { this.DhikrEditor() }
    }
    .width('100%').height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  // ============================================================
  // 3D BEAD
  // ============================================================

  @Builder
  Bead(hi: string, base: string, lo: string) {
    Stack() {
      Column()
        .width(BEAD_SIZE).height(BEAD_SIZE)
        .borderRadius(BEAD_SIZE / 2)
        .linearGradient({
          angle: 135,
          colors: [[hi, 0], [base, 0.55], [lo, 1]]
        })
        .shadow({ radius: 3, color: 'rgba(0,0,0,0.35)', offsetX: 0, offsetY: 2 })

      Column()
        .width(BEAD_SIZE * 0.28)
        .height(BEAD_SIZE * 0.28)
        .borderRadius(BEAD_SIZE * 0.14)
        .backgroundColor('rgba(255,255,255,0.55)')
        .position({ x: BEAD_SIZE * 0.22, y: BEAD_SIZE * 0.18 })
    }
    .width(BEAD_SIZE)
    .height(BEAD_SIZE)
    .direction(Direction.Ltr)
  }

  // ============================================================
  // VERTICAL BEAD STRING COLUMN
  // ============================================================
  //
  // Direction is forced to LTR so the bead column always sits on
  // the physical right edge of the screen, keeping the same visual
  // layout as English. The counter stays on the left regardless of
  // language.

  @Builder
  BeadStringColumn() {
    Stack() {
      // String line
      Column()
        .width(STRING_WIDTH)
        .height('100%')
        .backgroundColor(STRING_LINE_COLOR)
        .borderRadius(STRING_WIDTH / 2)

      // Beads
      Column() {
        // TOP CLUSTER — counted beads
        ForEach(this.beadView.topIds, (i: number) => {
          Column() {
            if (this.beadView.isComplete) {
              this.Bead(SHADE_DONE_HI, SHADE_DONE_BASE, SHADE_DONE_LO)
            } else {
              this.Bead(SHADE_GOLD_HI, SHADE_GOLD_BASE, SHADE_GOLD_LO)
            }
          }
          .margin({ top: i === 0 ? 0 : BEAD_GAP })
          .transition({ type: TransitionType.Insert, translate: { x: 0, y: 60 }, opacity: 0 })
          .transition({ type: TransitionType.Delete, translate: { x: 0, y: 60 }, opacity: 0 })
        }, (i: number) => {
          const isTail = i === this.beadView.topIds.length - 1;
          return (this.beadView.topAtCap && isTail)
            ? `top-${i}-p${this.topPulseTick}`
            : `top-${i}`;
        })

        // Flexible gap
        Blank().layoutWeight(1)

        // BOTTOM CLUSTER — pending beads
        ForEach(this.beadView.bottomIds, (i: number) => {
          Column() {
            if (PageTheme.isSystemDark()) {
              this.Bead(SHADE_PEND_HI_D, SHADE_PEND_BASE_D, SHADE_PEND_LO_D)
            } else {
              this.Bead(SHADE_PEND_HI_L, SHADE_PEND_BASE_L, SHADE_PEND_LO_L)
            }
          }
          .margin({ top: i === 0 ? 0 : BEAD_GAP })
          .transition({ type: TransitionType.Insert, translate: { x: 0, y: -60 }, opacity: 0 })
          .transition({ type: TransitionType.Delete, translate: { x: 0, y: -60 }, opacity: 0 })
        }, (i: number) => `bottom-${i}`)
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width(60)
    .height('100%')
    .padding({ top: 16, bottom: 110, right: 40 })
    .direction(Direction.Ltr)
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  @Builder
  EmptyState() {
    Column() {
      Text('📿').fontSize(64).opacity(0.5)
      Text(this.tr('no_dhikr_title'))
        .fontSize(16).fontColor(this.colors.textMuted).margin({ top: 16 })
      Text(this.tr('no_dhikr_hint'))
        .fontSize(13).fontColor(this.colors.textMuted).margin({ top: 6 })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  @Builder
  TopBar() {
    Row() {
      // Tasbih pill
      Row() {
        Text('📿').fontSize(14).margin({ right: 6 }).flexShrink(0)
        Text(this.getActiveTasbih() ? this.getActiveTasbih()!.name : this.tr('tab_tasbih'))
          .fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        Text('▼').fontSize(10).fontColor(this.colors.accentGold).margin({ left: 6 }).opacity(0.7).flexShrink(0)
      }
      .constraintSize({ maxWidth: 160 })
      .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      .backgroundColor(this.colors.cardDark)
      .borderRadius(18)
      .border({ width: 1, color: this.colors.borderSoft })
      .onClick(() => { this.showTasbihPicker = true; })

      Blank()

      // Dhikr pill
      Row() {
        Text(this.getActiveDhikr() && this.getActiveDhikr()!.transliteration.length > 0
          ? this.getActiveDhikr()!.transliteration
          : this.tr('select_dhikr'))
          .fontSize(13).fontColor(this.colors.accentGold).fontWeight(FontWeight.Medium)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        Text('▼').fontSize(10).fontColor(this.colors.accentGold).margin({ left: 6 }).opacity(0.7).flexShrink(0)
      }
      .constraintSize({ maxWidth: 160 })
      .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      .backgroundColor(this.colors.cardDark)
      .borderRadius(18)
      .border({ width: 1, color: this.colors.borderSoft })
      .onClick(() => { this.showDhikrPicker = true; })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 32, bottom: 8 })
    .alignItems(VerticalAlign.Center)
  }

  // ============================================================
  // FLOATING BAR — 4 tabs, Tasbih active
  // ============================================================

  @Builder
  FloatingBar() {
    Row() {
      Row() {
        // Home
        Column() {
          Text('🏠').fontSize(22).opacity(0.7)
          Text(this.tr('tab_home'))
            .fontSize(10).fontWeight(FontWeight.Normal)
            .fontColor(PageTheme.isSystemDark() ? 'rgba(241,245,249,0.65)' : 'rgba(26,26,26,0.55)')
            .margin({ top: 2 })
        }
        .layoutWeight(1).height('100%').justifyContent(FlexAlign.Center)
        .onClick(() => { this.onFloatingBarTap('home'); })

        Divider().vertical(true).height(28)
          .color(PageTheme.isSystemDark() ? 'rgba(74,222,128,0.20)' : 'rgba(15,81,50,0.12)')

        // Tasbih (active)
        Column() {
          Text('📿').fontSize(22).opacity(1.0)
          Text(this.tr('tab_tasbih'))
            .fontSize(10).fontWeight(FontWeight.Bold)
            .fontColor(PageTheme.isSystemDark() ? '#4ADE80' : '#0F5132')
            .margin({ top: 2 })
        }
        .layoutWeight(1).height('100%').justifyContent(FlexAlign.Center)
        .onClick(() => { this.onFloatingBarTap('tasbih'); })

        Divider().vertical(true).height(28)
          .color(PageTheme.isSystemDark() ? 'rgba(74,222,128,0.20)' : 'rgba(15,81,50,0.12)')

        // Compass
        Column() {
          Text('🧭').fontSize(22).opacity(0.7)
          Text(this.tr('tab_compass'))
            .fontSize(10).fontWeight(FontWeight.Normal)
            .fontColor(PageTheme.isSystemDark() ? 'rgba(241,245,249,0.65)' : 'rgba(26,26,26,0.55)')
            .margin({ top: 2 })
        }
        .layoutWeight(1).height('100%').justifyContent(FlexAlign.Center)
        .onClick(() => { this.onFloatingBarTap('compass'); })

        Divider().vertical(true).height(28)
          .color(PageTheme.isSystemDark() ? 'rgba(74,222,128,0.20)' : 'rgba(15,81,50,0.12)')

        // Calendar
        Column() {
          Text('📅').fontSize(22).opacity(0.7)
          Text(this.tr('tab_calendar'))
            .fontSize(10).fontWeight(FontWeight.Normal)
            .fontColor(PageTheme.isSystemDark() ? 'rgba(241,245,249,0.65)' : 'rgba(26,26,26,0.55)')
            .margin({ top: 2 })
        }
        .layoutWeight(1).height('100%').justifyContent(FlexAlign.Center)
        .onClick(() => { this.onFloatingBarTap('calendar'); })
      }
      .width('92%').height(68)
      .backgroundBlurStyle(
        BlurStyle.Thin,
        {
          colorMode: PageTheme.isSystemDark() ? ThemeColorMode.DARK : ThemeColorMode.LIGHT,
          adaptiveColor: AdaptiveColor.DEFAULT,
          scale: 1.0
        }
      )
      .backgroundColor(
        PageTheme.isSystemDark() ? 'rgba(20, 27, 46, 0.50)' : 'rgba(255, 255, 255, 0.35)'
      )
      .borderRadius(34)
      .border({
        width: 1,
        color: PageTheme.isSystemDark()
          ? 'rgba(74, 222, 128, 0.35)'
          : 'rgba(255, 255, 255, 0.65)'
      })
      .shadow({
        radius: 28,
        color: PageTheme.isSystemDark() ? 'rgba(0, 0, 0, 0.50)' : 'rgba(0, 0, 0, 0.14)',
        offsetX: 0, offsetY: 10
      })
    }
    .width('100%').justifyContent(FlexAlign.Center)
    .position({ bottom: 24 })
  }

  // ============================================================
  // TASBIH PICKER
  // ============================================================

  @Builder
  TasbihPicker() {
    Column()
      .width('100%').height('100%')
      .backgroundColor(this.colors.overlayDim)
      .onClick(() => { this.showTasbihPicker = false; })

    Column() {
      Row().width(44).height(4)
        .backgroundColor(this.colors.overlayDimSoft).borderRadius(2).margin({ top: 10 })

      Row() {
        Text('📿').fontSize(22)
          .width(44).height(44).textAlign(TextAlign.Center)
          .backgroundColor(this.colors.tintSoft).borderRadius(12)
          .border({ width: 1, color: this.colors.borderSoft })
        Text(this.tr('my_tasbihs'))
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
          .margin({ left: 14 })
      }
      .width('100%').padding({ left: 20, top: 20, bottom: 20 })

      Divider().color(this.colors.borderSoft).width('90%')

      Column() {
        ForEach(this.tasbihs, (t: Tasbih) => {
          Row() {
            Row() {
              if (t.id === this.activeTasbihId) {
                Row().width(10).height(10).borderRadius(5).backgroundColor(this.colors.accentGold)
              }
            }
            .width(22).height(22).borderRadius(11)
            .border({
              width: t.id === this.activeTasbihId ? 2 : 1.5,
              color: t.id === this.activeTasbihId
                ? this.colors.accentGold
                : this.colors.borderStrong
            })
            .justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)

            Column() {
              Text(t.name)
                .fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
                .width('100%')
              Text(`${t.dhikrs.length} ${t.dhikrs.length === 1 ? this.tr('dhikr_count_singular') : this.tr('dhikr_count_plural')} · ${t.lifetimeCount || 0} ${this.tr('total_on_tasbih')}`)
                .fontSize(11).fontColor(this.colors.textMuted)
                .margin({ top: 2 }).width('100%')
            }
            .alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 14 })

            Text('✏️').fontSize(18).width(36).height(36).textAlign(TextAlign.Center)
              .onClick(() => { this.openEditTasbihEditor(t); })

            if (this.tasbihs.length > 1) {
              Text('🗑️').fontSize(18).width(36).height(36).textAlign(TextAlign.Center)
                .onClick(() => { this.deleteTasbih(t.id); })
            }
          }
          .width('100%')
          .padding({ top: 12, bottom: 12, left: 16, right: 8 })
          .backgroundColor(t.id === this.activeTasbihId ? this.colors.tintSoft : 'transparent')
          .borderRadius(12).margin({ bottom: 4 })
          .onClick(() => { this.selectTasbih(t.id); })
        }, (t: Tasbih) => `${t.id}-${t.name}-${t.dhikrs.length}`)
      }
      .width('100%').padding({ left: 8, right: 8, top: 12, bottom: 12 })

      Button(this.tr('new_tasbih_button'))
        .width('90%').height(48).fontSize(15).fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textOnAccent).backgroundColor(this.colors.accentGold)
        .borderRadius(12).margin({ top: 4, bottom: 8 })
        .onClick(() => { this.openNewTasbihEditor(); })

      Button(this.tr('cancel'))
        .width('90%').height(44).fontSize(14).fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textWhite).backgroundColor(this.colors.tintSoft)
        .borderRadius(12).margin({ bottom: 24 })
        .onClick(() => { this.showTasbihPicker = false; })
    }
    .width('100%').backgroundColor(this.colors.cardDark)
    .borderRadius({ topLeft: 28, topRight: 28 })
    .shadow({ radius: 24, color: this.colors.shadowFloating, offsetX: 0, offsetY: -6 })
    .border({ width: { top: 1 }, color: this.colors.borderSoft })
    .position({ bottom: 0 })
  }

  // ============================================================
  // DHIKR PICKER
  // ============================================================

  @Builder
  DhikrPicker() {
    Column()
      .width('100%').height('100%')
      .backgroundColor(this.colors.overlayDim)
      .onClick(() => { this.showDhikrPicker = false; })

    Column() {
      Row().width(44).height(4)
        .backgroundColor(this.colors.overlayDimSoft).borderRadius(2).margin({ top: 10 })

      Row() {
        Text('📿').fontSize(22)
          .width(44).height(44).textAlign(TextAlign.Center)
          .backgroundColor(this.colors.tintSoft).borderRadius(12)
          .border({ width: 1, color: this.colors.borderSoft })
        Text(this.tr('select_dhikr'))
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
          .margin({ left: 14 })
      }
      .width('100%').padding({ left: 20, top: 20, bottom: 20 })

      Divider().color(this.colors.borderSoft).width('90%')

      Scroll() {
        Column() {
          if (this.getActiveTasbih() !== null) {
            ForEach(this.getActiveTasbih()!.dhikrs, (d: Dhikr, index: number) => {
              Row() {
                Row() {
                  if (index === this.activeDhikrIndex) {
                    Row().width(10).height(10).borderRadius(5)
                      .backgroundColor(this.colors.accentGold)
                  }
                }
                .width(22).height(22).borderRadius(11)
                .border({
                  width: index === this.activeDhikrIndex ? 2 : 1.5,
                  color: index === this.activeDhikrIndex
                    ? this.colors.accentGold
                    : this.colors.borderStrong
                })
                .justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)

                Column() {
                  Text(d.transliteration.length > 0 ? d.transliteration : d.arabic)
                    .fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
                    .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                  Text(`${d.count} / ${d.target}`)
                    .fontSize(11).fontColor(this.colors.textMuted)
                    .margin({ top: 2 }).width('100%')
                }
                .alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 14 })

                Text('✏️').fontSize(16).width(32).height(32).textAlign(TextAlign.Center)
                  .onClick(() => { this.openEditDhikrEditor(d); })

                Text('🗑️').fontSize(16).width(32).height(32).textAlign(TextAlign.Center)
                  .onClick(() => { this.deleteDhikr(d.id); })
              }
              .width('100%')
              .padding({ top: 12, bottom: 12, left: 16, right: 8 })
              .backgroundColor(index === this.activeDhikrIndex ? this.colors.tintSoft : 'transparent')
              .borderRadius(12).margin({ bottom: 4 })
              .onClick(() => { this.selectDhikr(index); })
            }, (d: Dhikr) => `${d.id}-${d.count}-${d.target}`)
          }
        }
        .width('100%').padding({ left: 8, right: 8, top: 12, bottom: 12 })
      }
      .constraintSize({ maxHeight: 320 })

      Button(this.tr('add_dhikr_button'))
        .width('90%').height(46).fontSize(14).fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textOnAccent).backgroundColor(this.colors.accentGold)
        .borderRadius(12).margin({ top: 4, bottom: 8 })
        .onClick(() => { this.openNewDhikrEditor(); })

      Button(this.tr('cancel'))
        .width('90%').height(44).fontSize(14).fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textWhite).backgroundColor(this.colors.tintSoft)
        .borderRadius(12).margin({ bottom: 24 })
        .onClick(() => { this.showDhikrPicker = false; })
    }
    .width('100%').backgroundColor(this.colors.cardDark)
    .borderRadius({ topLeft: 28, topRight: 28 })
    .shadow({ radius: 24, color: this.colors.shadowFloating, offsetX: 0, offsetY: -6 })
    .border({ width: { top: 1 }, color: this.colors.borderSoft })
    .position({ bottom: 0 })
  }

  // ============================================================
  // TASBIH EDITOR
  // ============================================================

  @Builder
  TasbihEditor() {
    Column()
      .width('100%').height('100%')
      .backgroundColor(this.colors.overlayDim)
      .onClick(() => { this.showTasbihEditor = false; })

    Column() {
      Row().width(44).height(4)
        .backgroundColor(this.colors.overlayDimSoft).borderRadius(2).margin({ top: 10 })

      Text(this.editingTasbihId.length > 0 ? this.tr('edit_tasbih') : this.tr('new_tasbih'))
        .fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
        .margin({ top: 20, bottom: 20 })

      Divider().color(this.colors.borderSoft).width('90%')

      Column() {
        Text(this.tr('tasbih_name')).fontSize(12).fontColor(this.colors.textMuted)
          .width('100%').margin({ bottom: 6 })
        TextInput({ text: this.formTasbihName, placeholder: this.tr('tasbih_name_placeholder') })
          .type(InputType.Normal)
          .onChange((value: string) => { this.formTasbihName = value; })
          .fontSize(15).fontColor(this.colors.textWhite)
          .placeholderColor(this.colors.placeholder)
          .caretColor(this.colors.accentGold)
          .backgroundColor(this.colors.tintSoft).borderRadius(10)
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .width('100%')
      }
      .width('100%').padding({ left: 20, right: 20, top: 20, bottom: 20 })

      Row() {
        Button(this.tr('cancel')).layoutWeight(1).height(46).fontSize(15)
          .fontColor(this.colors.textWhite).backgroundColor(this.colors.tintSoft).borderRadius(12)
          .onClick(() => { this.showTasbihEditor = false; })
        Button(this.tr('save')).layoutWeight(1).height(46).fontSize(15).fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textOnAccent).backgroundColor(this.colors.accentGold).borderRadius(12)
          .margin({ left: 8 })
          .onClick(() => { this.saveTasbih(); })
      }
      .width('100%').padding({ left: 20, right: 20, bottom: 24 })
    }
    .width('100%').backgroundColor(this.colors.cardDark)
    .borderRadius({ topLeft: 28, topRight: 28 })
    .shadow({ radius: 24, color: this.colors.shadowFloating, offsetX: 0, offsetY: -6 })
    .border({ width: { top: 1 }, color: this.colors.borderSoft })
    .position({ bottom: 0 })
  }

  // ============================================================
  // DHIKR EDITOR
  // ============================================================

  @Builder
  DhikrEditor() {
    Column()
      .width('100%').height('100%')
      .backgroundColor(this.colors.overlayDim)
      .onClick(() => { this.showDhikrEditor = false; })

    Column() {
      Row().width(44).height(4)
        .backgroundColor(this.colors.overlayDimSoft).borderRadius(2).margin({ top: 10 })

      Text(this.editingDhikrId.length > 0 ? this.tr('edit_dhikr') : this.tr('new_dhikr'))
        .fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
        .margin({ top: 20, bottom: 20 })

      Divider().color(this.colors.borderSoft).width('90%')

      Scroll() {
        Column() {
          Column() {
            Text(this.tr('dhikr_arabic')).fontSize(12).fontColor(this.colors.textMuted)
              .width('100%').margin({ bottom: 6 })
            TextInput({ text: this.formDhikrArabic, placeholder: 'سُبْحَانَ ٱللَّٰهِ' })
              .type(InputType.Normal)
              .onChange((value: string) => { this.formDhikrArabic = value; })
              .fontSize(16).fontColor(this.colors.textWhite)
              .placeholderColor(this.colors.placeholder).caretColor(this.colors.accentGold)
              .backgroundColor(this.colors.tintSoft).borderRadius(10)
              .padding({ left: 14, right: 14, top: 10, bottom: 10 }).width('100%')
          }.width('100%').margin({ bottom: 14 })

          Column() {
            Text(this.tr('dhikr_transliteration')).fontSize(12).fontColor(this.colors.textMuted)
              .width('100%').margin({ bottom: 6 })
            TextInput({ text: this.formDhikrTranslit, placeholder: this.tr('dhikr_transliteration_placeholder') })
              .type(InputType.Normal)
              .onChange((value: string) => { this.formDhikrTranslit = value; })
              .fontSize(14).fontColor(this.colors.textWhite)
              .placeholderColor(this.colors.placeholder).caretColor(this.colors.accentGold)
              .backgroundColor(this.colors.tintSoft).borderRadius(10)
              .padding({ left: 14, right: 14, top: 10, bottom: 10 }).width('100%')
          }.width('100%').margin({ bottom: 14 })

          Column() {
            Text(this.tr('dhikr_translation')).fontSize(12).fontColor(this.colors.textMuted)
              .width('100%').margin({ bottom: 6 })
            TextInput({ text: this.formDhikrTranslation, placeholder: this.tr('dhikr_translation_placeholder') })
              .type(InputType.Normal)
              .onChange((value: string) => { this.formDhikrTranslation = value; })
              .fontSize(14).fontColor(this.colors.textWhite)
              .placeholderColor(this.colors.placeholder).caretColor(this.colors.accentGold)
              .backgroundColor(this.colors.tintSoft).borderRadius(10)
              .padding({ left: 14, right: 14, top: 10, bottom: 10 }).width('100%')
          }.width('100%').margin({ bottom: 14 })

          Column() {
            Text(this.tr('target_count')).fontSize(12).fontColor(this.colors.textMuted)
              .width('100%').margin({ bottom: 6 })
            TextInput({ text: this.formDhikrTarget, placeholder: '33' })
              .type(InputType.Number)
              .direction(Direction.Ltr)
              .onChange((value: string) => { this.formDhikrTarget = value; })
              .fontSize(14).fontColor(this.colors.textWhite)
              .placeholderColor(this.colors.placeholder).caretColor(this.colors.accentGold)
              .backgroundColor(this.colors.tintSoft).borderRadius(10)
              .padding({ left: 14, right: 14, top: 10, bottom: 10 }).width('100%')
          }.width('100%').margin({ bottom: 14 })
        }
        .width('100%').padding({ left: 20, right: 20, top: 20, bottom: 8 })
      }
      .constraintSize({ maxHeight: 340 })

      Row() {
        Button(this.tr('cancel')).layoutWeight(1).height(46).fontSize(15)
          .fontColor(this.colors.textWhite).backgroundColor(this.colors.tintSoft).borderRadius(12)
          .onClick(() => { this.showDhikrEditor = false; })
        Button(this.tr('save')).layoutWeight(1).height(46).fontSize(15).fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textOnAccent).backgroundColor(this.colors.accentGold).borderRadius(12)
          .margin({ left: 8 })
          .onClick(() => { this.saveDhikr(); })
      }
      .width('100%').padding({ left: 20, right: 20, top: 8, bottom: 24 })
    }
    .width('100%').backgroundColor(this.colors.cardDark)
    .borderRadius({ topLeft: 28, topRight: 28 })
    .shadow({ radius: 24, color: this.colors.shadowFloating, offsetX: 0, offsetY: -6 })
    .border({ width: { top: 1 }, color: this.colors.borderSoft })
    .position({ bottom: 0 })
  }
}