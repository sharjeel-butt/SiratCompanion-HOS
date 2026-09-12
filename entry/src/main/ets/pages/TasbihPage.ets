// entry/src/main/ets/pages/TasbihPage.ets

import { router } from '@kit.ArkUI';
import { mediaquery } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Theme, ThemeColors, ThemeMode } from '../common/Theme';
import { STORAGE_KEY_THEME_MODE } from '../common/StorageKeys';

// ============================================================
// DATA MODELS
// ============================================================

interface Dhikr {
  id: string;
  arabic: string;
  transliteration: string;
  translation: string;
  target: number;
  count: number;
}

interface Tasbih {
  id: string;
  name: string;
  dhikrs: Dhikr[];
  createdAt: number;
}

// Fixed palette for the bead visual (always gold regardless of theme)
const BEAD_GOLD = '#E8A44C';
const BEAD_GOLD_DEEP = '#D18F35';
const BEAD_COMPLETE = '#4ADE80';

@Entry
@Component
struct TasbihPage {

  // ============================================================
  // THEME
  // ============================================================

  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;

  @State colors: ThemeColors = Theme.getColors(ThemeMode.LIGHT, false);
  private systemDarkListener: mediaquery.MediaQueryListener | null = null;

  // ============================================================
  // STATE — Tasbih data
  // ============================================================

  @State tasbihs: Tasbih[] = [];
  @State activeTasbihId: string = '';
  @State activeDhikrIndex: number = 0;

  // ============================================================
  // STATE — UI overlays
  // ============================================================

  @State showTasbihPicker: boolean = false;
  @State showDhikrPicker: boolean = false;
  @State showTasbihEditor: boolean = false;
  @State showDhikrEditor: boolean = false;
  @State showDhikrMenu: boolean = false;

  // ---- Tasbih editor ----
  @State editingTasbihId: string = '';
  @State formTasbihName: string = '';

  // ---- Dhikr editor ----
  @State editingDhikrId: string = '';
  @State formDhikrArabic: string = '';
  @State formDhikrTranslit: string = '';
  @State formDhikrTranslation: string = '';
  @State formDhikrTarget: string = '33';

  // ---- Dhikr action menu ----
  @State menuDhikrId: string = '';
  @State menuDhikrName: string = '';

  // ============================================================
  // STORAGE
  // ============================================================

  private prefStore: preferences.Preferences | null = null;
  private readonly PREF_STORE = 'tasbih_prefs';
  private readonly KEY_TASBIHS = 'tasbihs_data';
  private readonly KEY_ACTIVE = 'tasbih_active_id';
  private readonly MAX_VISIBLE_TAIL = 12;

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

  async aboutToAppear(): Promise<void> {
    this.applyTheme();

    try {
      this.systemDarkListener = mediaquery.matchMediaSync('(dark-mode: true)');
      this.systemDarkListener.on('change', (result: mediaquery.MediaQueryResult) => {
        if (this.themeMode === ThemeMode.SYSTEM) {
          this.colors = Theme.getColors(this.themeMode, result.matches);
        }
      });
    } catch (err) { /* ignore */ }

    try {
      const context = getContext(this) as common.UIAbilityContext;
      this.prefStore = await preferences.getPreferences(context, this.PREF_STORE);
      await this.loadTasbihs();
    } catch (err) {
      console.warn('Tasbih storage init failed');
      this.tasbihs = this.createDefaultTasbihs();
      this.activeTasbihId = this.tasbihs.length > 0 ? this.tasbihs[0].id : '';
    }
  }

  aboutToDisappear(): void {
    if (this.systemDarkListener) {
      this.systemDarkListener.off('change');
      this.systemDarkListener = null;
    }
  }

  onPageShow(): void {
    this.applyTheme();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  private generateId(): string {
    return `id_${Date.now()}_${Math.floor(Math.random() * 100000)}`;
  }

  private getActiveTasbih(): Tasbih | null {
    const found = this.tasbihs.find(t => t.id === this.activeTasbihId);
    return found ? found : null;
  }

  private getActiveDhikr(): Dhikr | null {
    const tasbih = this.getActiveTasbih();
    if (!tasbih || tasbih.dhikrs.length === 0) return null;
    const idx = Math.min(this.activeDhikrIndex, tasbih.dhikrs.length - 1);
    return tasbih.dhikrs[idx];
  }

  /** Returns [0..min(count, MAX_VISIBLE)] for the visible tail beads. */
  private getVisibleTailBeads(): number[] {
    const dhikr = this.getActiveDhikr();
    if (!dhikr) return [];
    const visible = Math.min(dhikr.count, this.MAX_VISIBLE_TAIL);
    const arr: number[] = [];
    for (let i = 0; i < visible; i++) arr.push(i);
    return arr;
  }

  // ============================================================
  // DEFAULT DATA
  // ============================================================

  private createDefaultTasbihs(): Tasbih[] {
    const classicDhikrs: Dhikr[] = [
      { id: this.generateId(), arabic: 'سُبْحَانَ ٱللَّٰهِ', transliteration: 'SubhanAllah', translation: 'Glory be to Allah', target: 33, count: 0 },
      { id: this.generateId(), arabic: 'ٱلْحَمْدُ لِلَّٰهِ', transliteration: 'Alhamdulillah', translation: 'All praise is for Allah', target: 33, count: 0 },
      { id: this.generateId(), arabic: 'ٱللَّٰهُ أَكْبَرُ', transliteration: 'Allahu Akbar', translation: 'Allah is the Greatest', target: 34, count: 0 }
    ];
    const tahlilDhikrs: Dhikr[] = [
      { id: this.generateId(), arabic: 'لَا إِلَٰهَ إِلَّا ٱللَّٰهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ ٱلْمُلْكُ وَلَهُ ٱلْحَمْدُ', transliteration: 'La ilaha illallahu wahdahu la sharika lah', translation: 'There is no god but Allah, alone, without partner', target: 100, count: 0 }
    ];
    const istighfarDhikrs: Dhikr[] = [
      { id: this.generateId(), arabic: 'أَسْتَغْفِرُ ٱللَّٰهَ', transliteration: 'Astaghfirullah', translation: 'I seek forgiveness from Allah', target: 100, count: 0 }
    ];

    return [
      { id: this.generateId(), name: 'Classic 33', createdAt: Date.now(), dhikrs: classicDhikrs },
      { id: this.generateId(), name: 'Tahlil 100', createdAt: Date.now() + 1, dhikrs: tahlilDhikrs },
      { id: this.generateId(), name: 'Istighfar', createdAt: Date.now() + 2, dhikrs: istighfarDhikrs }
    ];
  }

  // ============================================================
  // PERSISTENCE
  // ============================================================

  private async loadTasbihs(): Promise<void> {
    if (!this.prefStore) return;
    try {
      const json = await this.prefStore.get(this.KEY_TASBIHS, '') as string;
      if (json && json.length > 0) {
        this.tasbihs = JSON.parse(json) as Tasbih[];
      }
      if (this.tasbihs.length === 0) {
        this.tasbihs = this.createDefaultTasbihs();
      }
      const activeId = await this.prefStore.get(this.KEY_ACTIVE, '') as string;
      const found = this.tasbihs.find(t => t.id === activeId);
      this.activeTasbihId = found ? activeId : this.tasbihs[0].id;
      this.activeDhikrIndex = 0;
      await this.saveTasbihs();
    } catch (err) {
      this.tasbihs = this.createDefaultTasbihs();
      this.activeTasbihId = this.tasbihs[0].id;
      this.activeDhikrIndex = 0;
    }
  }

  private async saveTasbihs(): Promise<void> {
    if (!this.prefStore) return;
    try {
      await this.prefStore.put(this.KEY_TASBIHS, JSON.stringify(this.tasbihs));
      await this.prefStore.put(this.KEY_ACTIVE, this.activeTasbihId);
      await this.prefStore.flush();
    } catch (err) {
      console.warn('Save tasbih failed');
    }
  }

  // ============================================================
  // ACTIONS — Counting
  // ============================================================

  private increment(): void {
    const dhikr = this.getActiveDhikr();
    if (!dhikr) return;

    this.tasbihs = this.tasbihs.map((t): Tasbih => {
      if (t.id !== this.activeTasbihId) return t;
      const updated: Dhikr[] = t.dhikrs.map((d): Dhikr => {
        if (d.id !== dhikr.id) return d;
        return {
          id: d.id, arabic: d.arabic, transliteration: d.transliteration,
          translation: d.translation, target: d.target, count: d.count + 1
        };
      });
      return { id: t.id, name: t.name, dhikrs: updated, createdAt: t.createdAt };
    });
    this.saveTasbihs();
  }

  private decrement(): void {
    const dhikr = this.getActiveDhikr();
    if (!dhikr) return;

    this.tasbihs = this.tasbihs.map((t): Tasbih => {
      if (t.id !== this.activeTasbihId) return t;
      const updated: Dhikr[] = t.dhikrs.map((d): Dhikr => {
        if (d.id !== dhikr.id) return d;
        return {
          id: d.id, arabic: d.arabic, transliteration: d.transliteration,
          translation: d.translation, target: d.target,
          count: d.count > 0 ? d.count - 1 : 0
        };
      });
      return { id: t.id, name: t.name, dhikrs: updated, createdAt: t.createdAt };
    });
    this.saveTasbihs();
  }

  private resetCurrent(): void {
    const dhikr = this.getActiveDhikr();
    if (!dhikr) return;

    this.tasbihs = this.tasbihs.map((t): Tasbih => {
      if (t.id !== this.activeTasbihId) return t;
      const updated: Dhikr[] = t.dhikrs.map((d): Dhikr => {
        if (d.id !== dhikr.id) return d;
        return {
          id: d.id, arabic: d.arabic, transliteration: d.transliteration,
          translation: d.translation, target: d.target, count: 0
        };
      });
      return { id: t.id, name: t.name, dhikrs: updated, createdAt: t.createdAt };
    });
    this.saveTasbihs();
    this.showDhikrMenu = false;
  }

  private resetDhikrById(dhikrId: string): void {
    this.tasbihs = this.tasbihs.map((t): Tasbih => {
      if (t.id !== this.activeTasbihId) return t;
      const updated: Dhikr[] = t.dhikrs.map((d): Dhikr => {
        if (d.id !== dhikrId) return d;
        return {
          id: d.id, arabic: d.arabic, transliteration: d.transliteration,
          translation: d.translation, target: d.target, count: 0
        };
      });
      return { id: t.id, name: t.name, dhikrs: updated, createdAt: t.createdAt };
    });
    this.saveTasbihs();
    this.showDhikrMenu = false;
  }

  // ============================================================
  // ACTIONS — Tasbih CRUD
  // ============================================================

  private openNewTasbihEditor(): void {
    this.editingTasbihId = '';
    this.formTasbihName = '';
    this.showTasbihPicker = false;
    this.showTasbihEditor = true;
  }

  private openEditTasbihEditor(tasbih: Tasbih): void {
    this.editingTasbihId = tasbih.id;
    this.formTasbihName = tasbih.name;
    this.showTasbihPicker = false;
    this.showTasbihEditor = true;
  }

  private saveTasbih(): void {
    const name = this.formTasbihName.trim();
    if (name.length === 0) return;

    if (this.editingTasbihId.length > 0) {
      this.tasbihs = this.tasbihs.map((t): Tasbih => {
        if (t.id !== this.editingTasbihId) return t;
        return { id: t.id, name: name, dhikrs: t.dhikrs, createdAt: t.createdAt };
      });
    } else {
      const newTasbih: Tasbih = {
        id: this.generateId(), name: name, dhikrs: [], createdAt: Date.now()
      };
      this.tasbihs = [...this.tasbihs, newTasbih];
      this.activeTasbihId = newTasbih.id;
      this.activeDhikrIndex = 0;
    }

    this.saveTasbihs();
    this.showTasbihEditor = false;
  }

  private deleteTasbih(tasbihId: string): void {
    if (this.tasbihs.length <= 1) {
      this.showTasbihPicker = false;
      return;
    }
    this.tasbihs = this.tasbihs.filter((t): boolean => t.id !== tasbihId);
    if (this.activeTasbihId === tasbihId) {
      this.activeTasbihId = this.tasbihs[0].id;
      this.activeDhikrIndex = 0;
    }
    this.saveTasbihs();
    this.showTasbihPicker = false;
  }

  private selectTasbih(tasbihId: string): void {
    this.activeTasbihId = tasbihId;
    this.activeDhikrIndex = 0;
    this.saveTasbihs();
    this.showTasbihPicker = false;
  }

  private selectDhikr(index: number): void {
    this.activeDhikrIndex = index;
    this.showDhikrPicker = false;
  }

  // ============================================================
  // ACTIONS — Dhikr CRUD
  // ============================================================

  private openNewDhikrEditor(): void {
    this.editingDhikrId = '';
    this.formDhikrArabic = '';
    this.formDhikrTranslit = '';
    this.formDhikrTranslation = '';
    this.formDhikrTarget = '33';
    this.showDhikrEditor = true;
  }

  private openEditDhikrEditor(dhikr: Dhikr): void {
    this.editingDhikrId = dhikr.id;
    this.formDhikrArabic = dhikr.arabic;
    this.formDhikrTranslit = dhikr.transliteration;
    this.formDhikrTranslation = dhikr.translation;
    this.formDhikrTarget = dhikr.target.toString();
    this.showDhikrMenu = false;
    this.showDhikrEditor = true;
  }

  private saveDhikr(): void {
    const arabic = this.formDhikrArabic.trim();
    const translit = this.formDhikrTranslit.trim();
    const translation = this.formDhikrTranslation.trim();
    const targetNum = parseInt(this.formDhikrTarget, 10);

    if (arabic.length === 0 && translit.length === 0) return;
    const finalTarget = isNaN(targetNum) || targetNum <= 0 ? 33 : targetNum;

    if (this.editingDhikrId.length > 0) {
      this.tasbihs = this.tasbihs.map((t): Tasbih => {
        if (t.id !== this.activeTasbihId) return t;
        const updated: Dhikr[] = t.dhikrs.map((d): Dhikr => {
          if (d.id !== this.editingDhikrId) return d;
          return {
            id: d.id, arabic: arabic, transliteration: translit,
            translation: translation, target: finalTarget, count: d.count
          };
        });
        return { id: t.id, name: t.name, dhikrs: updated, createdAt: t.createdAt };
      });
    } else {
      const newDhikr: Dhikr = {
        id: this.generateId(), arabic: arabic, transliteration: translit,
        translation: translation, target: finalTarget, count: 0
      };
      this.tasbihs = this.tasbihs.map((t): Tasbih => {
        if (t.id !== this.activeTasbihId) return t;
        return { id: t.id, name: t.name, dhikrs: [...t.dhikrs, newDhikr], createdAt: t.createdAt };
      });
      const t = this.getActiveTasbih();
      if (t) this.activeDhikrIndex = t.dhikrs.length - 1;
    }

    this.saveTasbihs();
    this.showDhikrEditor = false;
  }

  private deleteDhikr(dhikrId: string): void {
    this.tasbihs = this.tasbihs.map((t): Tasbih => {
      if (t.id !== this.activeTasbihId) return t;
      const filtered: Dhikr[] = t.dhikrs.filter((d): boolean => d.id !== dhikrId);
      return { id: t.id, name: t.name, dhikrs: filtered, createdAt: t.createdAt };
    });
    this.activeDhikrIndex = 0;
    this.saveTasbihs();
    this.showDhikrMenu = false;
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  private onFloatingBarTap(tabId: string): void {
    if (tabId === 'home') { router.back(); return; }
    if (tabId === 'tasbih') return;
    if (tabId === 'compass') {
      router.replaceUrl({ url: 'pages/QiblaPage' })
        .catch((err: Error) => console.error('Navigation failed:', JSON.stringify(err)));
      return;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  build() {
    Stack() {
      // ---- Background ----
      Column()
        .width('100%').height('100%')
        .backgroundColor(this.colors.primaryGreen)

      // ---- Full-screen tap area ----
      Column()
        .width('100%').height('100%')
        .backgroundColor(Color.Transparent)
        .onClick(() => { this.increment(); })

      // ---- Content (decorative) ----
      if (this.getActiveDhikr() !== null) {
        this.ContentView()
      } else {
        this.EmptyState()
      }

      // ---- Top bar ----
      this.TopBar()

      // ---- Floating bar ----
      this.FloatingBar()

      // ---- Overlays ----
      if (this.showTasbihPicker) { this.TasbihPicker() }
      if (this.showDhikrPicker) { this.DhikrPicker() }
      if (this.showTasbihEditor) { this.TasbihEditor() }
      if (this.showDhikrEditor) { this.DhikrEditor() }
      if (this.showDhikrMenu) { this.DhikrMenu() }
    }
    .width('100%').height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  // ============================================================
  // CONTENT VIEW (Arabic + beads + count)
  // ============================================================

  @Builder
  ContentView() {
    // Arabic dhikr text
    Text(this.getActiveDhikr()!.arabic)
      .fontSize(22)
      .fontColor(this.colors.textWhite)
      .textAlign(TextAlign.Center)
      .lineHeight(36)
      .width('100%')
      .padding({ left: 36, right: 36 })
      .position({ x: 0, y: '22%' })

    // Bead column
    Stack() {
      // String line (behind)
      Column()
        .width(2)
        .height('100%')
        .backgroundColor(this.isSystemDark() ? '#2A2A2A' : '#D5D0C7')

      // Beads (head at top, tail at bottom)
      Column() {
        // ---- Head beads (2) ----
        Column() {
          Column()
            .width(36).height(36).borderRadius(18)
            .backgroundColor(BEAD_GOLD)
            .shadow({ radius: 6, color: 'rgba(232,164,76,0.4)', offsetX: 0, offsetY: 2 })

          Column()
            .width(36).height(36).borderRadius(18)
            .backgroundColor(BEAD_GOLD)
            .margin({ top: 6 })
            .shadow({ radius: 6, color: 'rgba(232,164,76,0.4)', offsetX: 0, offsetY: 2 })
        }
        .alignItems(HorizontalAlign.Center)

        // ---- Tail beads (dynamic) ----
        Column() {
          ForEach(this.getVisibleTailBeads(), (i: number) => {
            Column()
              .width(36).height(36).borderRadius(18)
              .backgroundColor(this.getActiveDhikr()!.count >= this.getActiveDhikr()!.target
                ? BEAD_COMPLETE
                : BEAD_GOLD)
              .margin({ top: 6 })
              .shadow({
                radius: 6,
                color: this.getActiveDhikr()!.count >= this.getActiveDhikr()!.target
                  ? 'rgba(74,222,128,0.4)'
                  : 'rgba(232,164,76,0.4)',
                offsetX: 0, offsetY: 2
              })
          }, (i: number) => `tail-${i}`)
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(HorizontalAlign.Center)
    }
    .width(44)
    .height('76%')
    .position({ x: '62%', y: '12%' })

    // Count number (left)
    Column() {
      Text(`${this.getActiveDhikr()!.count}`)
        .fontSize(110)
        .fontWeight(FontWeight.Normal)
        .fontColor(this.colors.textWhite)

      Text(`out of ${this.getActiveDhikr()!.target}`)
        .fontSize(16)
        .fontColor(this.colors.textMuted)
        .margin({ top: -8 })
    }
    .position({ x: 48, y: '54%' })
    .alignItems(HorizontalAlign.Start)
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  @Builder
  EmptyState() {
    Column() {
      Text('📿').fontSize(64).opacity(0.5)
      Text('No Dhikr in this Tasbih')
        .fontSize(16).fontColor(this.colors.textMuted)
        .margin({ top: 16 })
      Text('Tap "⋯" to add one')
        .fontSize(13).fontColor(this.colors.textMuted)
        .margin({ top: 6 })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .position({ x: 0, y: '40%' })
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  @Builder
  TopBar() {
    Row() {
      // Current Tasbih — tap to open tasbih picker
      Row() {
        Text('📿').fontSize(14).margin({ right: 6 })
        Text(this.getActiveTasbih() ? this.getActiveTasbih()!.name : 'Tasbih')
          .fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text('▼').fontSize(10).fontColor(this.colors.accentGold).margin({ left: 6 }).opacity(0.7)
      }
      .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      .backgroundColor(this.colors.cardDark)
      .borderRadius(18)
      .border({ width: 1, color: this.colors.borderSoft })
      .onClick(() => { this.showTasbihPicker = true; })

      Blank()

      // Menu button
      Text('⋯')
        .fontSize(24).fontColor(this.colors.textWhite)
        .width(40).height(40).textAlign(TextAlign.Center)
        .onClick(() => {
          const d = this.getActiveDhikr();
          if (d) {
            this.menuDhikrId = d.id;
            this.menuDhikrName = d.transliteration.length > 0 ? d.transliteration : d.arabic;
            this.showDhikrMenu = true;
          }
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 32, bottom: 8 })
    .position({ x: 0, y: 0 })
    .alignItems(VerticalAlign.Center)
  }

  // ============================================================
  // FLOATING BAR
  // ============================================================

  @Builder
  FloatingBar() {
    Row() {
      Row() {
        Column() {
          Text('🏠').fontSize(24).opacity(0.7)
          Text('Home')
            .fontSize(11).fontWeight(FontWeight.Normal)
            .fontColor(this.isSystemDark() ? 'rgba(241,245,249,0.65)' : 'rgba(26,26,26,0.55)')
            .margin({ top: 3 })
        }
        .layoutWeight(1).height('100%').justifyContent(FlexAlign.Center)
        .onClick(() => { this.onFloatingBarTap('home'); })

        Divider().vertical(true).height(28)
          .color(this.isSystemDark() ? 'rgba(74,222,128,0.20)' : 'rgba(15,81,50,0.12)')

        Column() {
          Text('📿').fontSize(24).opacity(1.0)
          Text('Tasbih')
            .fontSize(11).fontWeight(FontWeight.Bold)
            .fontColor(this.isSystemDark() ? '#4ADE80' : '#0F5132')
            .margin({ top: 3 })
        }
        .layoutWeight(1).height('100%').justifyContent(FlexAlign.Center)
        .onClick(() => { this.onFloatingBarTap('tasbih'); })

        Divider().vertical(true).height(28)
          .color(this.isSystemDark() ? 'rgba(74,222,128,0.20)' : 'rgba(15,81,50,0.12)')

        Column() {
          Text('🧭').fontSize(24).opacity(0.7)
          Text('Compass')
            .fontSize(11).fontWeight(FontWeight.Normal)
            .fontColor(this.isSystemDark() ? 'rgba(241,245,249,0.65)' : 'rgba(26,26,26,0.55)')
            .margin({ top: 3 })
        }
        .layoutWeight(1).height('100%').justifyContent(FlexAlign.Center)
        .onClick(() => { this.onFloatingBarTap('compass'); })
      }
      .width('84%').height(68)
      .backgroundBlurStyle(
        BlurStyle.Thin,
        {
          colorMode: this.isSystemDark() ? ThemeColorMode.DARK : ThemeColorMode.LIGHT,
          adaptiveColor: AdaptiveColor.DEFAULT,
          scale: 1.0
        }
      )
      .backgroundColor(
        this.isSystemDark() ? 'rgba(20, 27, 46, 0.50)' : 'rgba(255, 255, 255, 0.35)'
      )
      .borderRadius(34)
      .border({
        width: 1,
        color: this.isSystemDark() ? 'rgba(74, 222, 128, 0.35)' : 'rgba(255, 255, 255, 0.65)'
      })
      .shadow({
        radius: 28,
        color: this.isSystemDark() ? 'rgba(0, 0, 0, 0.50)' : 'rgba(0, 0, 0, 0.14)',
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
        Text('My Tasbihs')
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
              color: t.id === this.activeTasbihId ? this.colors.accentGold : this.colors.borderStrong
            })
            .justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)

            Column() {
              Text(t.name)
                .fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
                .width('100%')
              Text(`${t.dhikrs.length} dhikr${t.dhikrs.length === 1 ? '' : 's'}`)
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

      Button('+ New Tasbih')
        .width('90%').height(48).fontSize(15).fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textOnAccent).backgroundColor(this.colors.accentGold)
        .borderRadius(12).margin({ top: 4, bottom: 8 })
        .onClick(() => { this.openNewTasbihEditor(); })

      Button('Cancel')
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
        Text('Select Dhikr')
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
                    Row().width(10).height(10).borderRadius(5).backgroundColor(this.colors.accentGold)
                  }
                }
                .width(22).height(22).borderRadius(11)
                .border({
                  width: index === this.activeDhikrIndex ? 2 : 1.5,
                  color: index === this.activeDhikrIndex ? this.colors.accentGold : this.colors.borderStrong
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
              }
              .width('100%')
              .padding({ top: 14, bottom: 14, left: 16, right: 16 })
              .backgroundColor(index === this.activeDhikrIndex ? this.colors.tintSoft : 'transparent')
              .borderRadius(12).margin({ bottom: 4 })
              .onClick(() => { this.selectDhikr(index); })
            }, (d: Dhikr) => `${d.id}-${d.count}-${d.target}`)
          }
        }
        .width('100%').padding({ left: 8, right: 8, top: 12, bottom: 12 })
      }
      .constraintSize({ maxHeight: 320 })

      Button('+ Add Dhikr')
        .width('90%').height(46).fontSize(14).fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textOnAccent).backgroundColor(this.colors.accentGold)
        .borderRadius(12).margin({ top: 4, bottom: 8 })
        .onClick(() => {
          this.showDhikrPicker = false;
          this.openNewDhikrEditor();
        })

      Button('Cancel')
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

      Text(this.editingTasbihId.length > 0 ? 'Edit Tasbih' : 'New Tasbih')
        .fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
        .margin({ top: 20, bottom: 20 })

      Divider().color(this.colors.borderSoft).width('90%')

      Column() {
        Text('Name').fontSize(12).fontColor(this.colors.textMuted)
          .width('100%').margin({ bottom: 6 })
        TextInput({ text: this.formTasbihName, placeholder: 'e.g. Evening Adhkar' })
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
        Button('Cancel').layoutWeight(1).height(46).fontSize(15)
          .fontColor(this.colors.textWhite).backgroundColor(this.colors.tintSoft).borderRadius(12)
          .onClick(() => { this.showTasbihEditor = false; })
        Button('Save').layoutWeight(1).height(46).fontSize(15).fontWeight(FontWeight.Medium)
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

      Text(this.editingDhikrId.length > 0 ? 'Edit Dhikr' : 'New Dhikr')
        .fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
        .margin({ top: 20, bottom: 20 })

      Divider().color(this.colors.borderSoft).width('90%')

      Scroll() {
        Column() {
          Column() {
            Text('Arabic').fontSize(12).fontColor(this.colors.textMuted)
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
            Text('Transliteration (optional)').fontSize(12).fontColor(this.colors.textMuted)
              .width('100%').margin({ bottom: 6 })
            TextInput({ text: this.formDhikrTranslit, placeholder: 'e.g. SubhanAllah' })
              .type(InputType.Normal)
              .onChange((value: string) => { this.formDhikrTranslit = value; })
              .fontSize(14).fontColor(this.colors.textWhite)
              .placeholderColor(this.colors.placeholder).caretColor(this.colors.accentGold)
              .backgroundColor(this.colors.tintSoft).borderRadius(10)
              .padding({ left: 14, right: 14, top: 10, bottom: 10 }).width('100%')
          }.width('100%').margin({ bottom: 14 })

          Column() {
            Text('Target count').fontSize(12).fontColor(this.colors.textMuted)
              .width('100%').margin({ bottom: 6 })
            TextInput({ text: this.formDhikrTarget, placeholder: '33' })
              .type(InputType.Number)
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
        Button('Cancel').layoutWeight(1).height(46).fontSize(15)
          .fontColor(this.colors.textWhite).backgroundColor(this.colors.tintSoft).borderRadius(12)
          .onClick(() => { this.showDhikrEditor = false; })
        Button('Save').layoutWeight(1).height(46).fontSize(15).fontWeight(FontWeight.Medium)
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

  // ============================================================
  // DHIKR MENU
  // ============================================================

  @Builder
  DhikrMenu() {
    Column()
      .width('100%').height('100%')
      .backgroundColor(this.colors.overlayDim)
      .onClick(() => { this.showDhikrMenu = false; })

    Column() {
      Row().width(44).height(4)
        .backgroundColor(this.colors.overlayDimSoft).borderRadius(2).margin({ top: 10 })

      Text(this.menuDhikrName.length > 0 ? this.menuDhikrName : 'Dhikr options')
        .fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        .padding({ left: 20, right: 20 })
        .margin({ top: 20, bottom: 16 })

      Divider().color(this.colors.borderSoft).width('90%')

      Column() {
        // Switch Dhikr
        Row() {
          Text('🔄').fontSize(18).margin({ right: 14 })
          Text('Switch dhikr').fontSize(15).fontColor(this.colors.textWhite)
        }
        .width('100%').padding({ top: 16, bottom: 16, left: 20 })
        .onClick(() => {
          this.showDhikrMenu = false;
          this.showDhikrPicker = true;
        })

        Divider().color(this.colors.borderSoft).width('90%')

        // Reset counter
        Row() {
          Text('↺').fontSize(18).margin({ right: 14 })
          Text('Reset counter').fontSize(15).fontColor(this.colors.textWhite)
        }
        .width('100%').padding({ top: 16, bottom: 16, left: 20 })
        .onClick(() => { this.resetCurrent(); })

        Divider().color(this.colors.borderSoft).width('90%')

        // Edit
        Row() {
          Text('✏️').fontSize(18).margin({ right: 14 })
          Text('Edit dhikr').fontSize(15).fontColor(this.colors.textWhite)
        }
        .width('100%').padding({ top: 16, bottom: 16, left: 20 })
        .onClick(() => {
          const d = this.getActiveDhikr();
          if (d) this.openEditDhikrEditor(d);
        })

        Divider().color(this.colors.borderSoft).width('90%')

        // Add new
        Row() {
          Text('➕').fontSize(18).margin({ right: 14 })
          Text('Add new dhikr').fontSize(15).fontColor(this.colors.textWhite)
        }
        .width('100%').padding({ top: 16, bottom: 16, left: 20 })
        .onClick(() => {
          this.showDhikrMenu = false;
          this.openNewDhikrEditor();
        })

        Divider().color(this.colors.borderSoft).width('90%')

        // Delete
        Row() {
          Text('🗑️').fontSize(18).margin({ right: 14 })
          Text('Delete dhikr').fontSize(15).fontColor('#E53935')
        }
        .width('100%').padding({ top: 16, bottom: 16, left: 20 })
        .onClick(() => { this.deleteDhikr(this.menuDhikrId); })
      }
      .width('100%').padding({ top: 4, bottom: 4 })

      Button('Cancel')
        .width('90%').height(44).fontSize(14).fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textWhite).backgroundColor(this.colors.tintSoft)
        .borderRadius(12).margin({ top: 16, bottom: 24 })
        .onClick(() => { this.showDhikrMenu = false; })
    }
    .width('100%').backgroundColor(this.colors.cardDark)
    .borderRadius({ topLeft: 28, topRight: 28 })
    .shadow({ radius: 24, color: this.colors.shadowFloating, offsetX: 0, offsetY: -6 })
    .border({ width: { top: 1 }, color: this.colors.borderSoft })
    .position({ bottom: 0 })
  }
}