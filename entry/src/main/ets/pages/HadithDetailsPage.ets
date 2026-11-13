import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { ThemeColors, ThemeMode } from '../core/Theme';
import { PageTheme } from '../core/PageTheme';
import { L } from '../i18n/LocalizationHelper';
import { STORAGE_KEY_LANGUAGE, STORAGE_KEY_THEME_MODE } from '../core/StorageKeys';
import { BilingualHadith } from '../hadith/HadithModels';
import { HadithDbHelper } from '../hadith/HadithDbHelper';
import { HadithSearchService } from '../hadith/HadithSearchService';

@Entry
@Component
struct HadithDetailsPage {
  @StorageLink(STORAGE_KEY_THEME_MODE) @Watch('onThemeModeChanged') themeMode: string = ThemeMode.SYSTEM;
  @StorageLink(STORAGE_KEY_LANGUAGE) @Watch('onLangChanged') appLanguage: string = 'en';
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  @State hadith: BilingualHadith | null = null;
  private hadithId: string = '';

  async aboutToAppear() {
    this.colors = PageTheme.compute(this.themeMode);
    const params = router.getParams() as Record<string, string>;

    if (params && params['id']) {
      this.hadithId = params['id'];
      await this.loadHadith();

      if (this.hadith !== null) {
        let metaApplied = false;

        // 1. Try to get metadata from router params (Search flow)
        if (params['meta']) {
          try {
            const meta = JSON.parse(params['meta']) as Record<string, Object>;
            if (meta['section']) {
              this.hadith.section =
                HadithDbHelper.translateSection(meta['section'] as string, this.appLanguage);
            }
            if (meta['contexts']) {
              this.hadith.life_contexts = meta['contexts'] as string[];
            }
            if (meta['topics']) {
              this.hadith.topics = meta['topics'] as string[];
            }
            metaApplied = true;
          } catch (e) {
          }
        }

        // 2. If no metadata was passed (Featured flow), look it up dynamically
        if (!metaApplied) {
          const ctx = getContext(this) as common.UIAbilityContext;
          const meta = await HadithSearchService.getMetadataForId(ctx, this.hadithId);
          if (meta !== null) {
            this.hadith.section = meta.section;
            this.hadith.life_contexts = meta.life_contexts;
            this.hadith.topics = meta.topics;
          }
        }


      }
    }
  }

  async onLangChanged() {
    await this.loadHadith();
  }

  onThemeModeChanged() {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private tr(key: string): string {
    return L.get(key, this.appLanguage);
  }

  async loadHadith() {
    const ctx = getContext(this) as common.UIAbilityContext;
    this.hadith = await HadithDbHelper.getBilingualById(ctx, this.hadithId, this.appLanguage);
  }

  @Builder
  HadithHeader() {
    if (this.hadith !== null) {
      Column() {
        // 1. Top Row: Hadith Number Badge Only
        Row() {
          // Gold Badge for Hadith Number (e.g., "#2123")
          Text(`#${this.hadith.hadith_number}`)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textOnAccent)
            .backgroundColor(this.colors.accentGold)
            .padding({
              left: 12,
              right: 12,
              top: 6,
              bottom: 6
            })
            .borderRadius(8)
        }
        .width('100%')
        .justifyContent(L.isRtlLang(this.appLanguage) ? FlexAlign.End : FlexAlign.Start)

        // 2. Middle Row: Section Name
        if (this.hadith.section && this.hadith.section.length > 0) {
          Text(this.hadith.section) // e.g., "Transferance of a Debt..."
            .fontSize(15)
            .fontColor(this.colors.textWhite)
            .fontWeight(FontWeight.Medium)
            .margin({ top: 12 })
            .width('100%')
            .textAlign(TextAlign.Start)
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        // 3. Bottom Row: Context & Topic Tags
        if ((this.hadith.life_contexts && this.hadith.life_contexts.length > 0) ||
          (this.hadith.topics && this.hadith.topics.length > 0)) {

          Flex({ wrap: FlexWrap.Wrap }) {
            // Context Tags
            if (this.hadith.life_contexts) {
              ForEach(this.hadith.life_contexts, (ctx: string) => {
                // 👇 FIX: Use HadithSearchService.translate
                Text(HadithSearchService.translate('context_' + ctx, this.appLanguage))
                  .fontSize(11)
                  .fontColor(this.colors.accentGold)
                  .backgroundColor(this.colors.tintSubtle)
                  .padding({
                    left: 10,
                    right: 10,
                    top: 4,
                    bottom: 4
                  })
                  .borderRadius(6)
                  .margin({ top: 8, right: 6 })
                  .border({ width: 1, color: this.colors.borderSoft })
              })
            }
            // Topic Tags
            if (this.hadith.topics) {
              ForEach(this.hadith.topics, (topic: string) => {
                // 👇 FIX: Use HadithSearchService.translate
                Text(HadithSearchService.translate('topic_' + topic, this.appLanguage))
                  .fontSize(11)
                  .fontColor(this.colors.textMuted)
                  .backgroundColor(this.colors.tintSoft)
                  .padding({
                    left: 10,
                    right: 10,
                    top: 4,
                    bottom: 4
                  })
                  .borderRadius(6)
                  .margin({ top: 8, right: 6 })
              })
            }
          }.width('100%').margin({ top: 12 })
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor(this.colors.cardDark)
      .borderRadius(16)
      .border({ width: 1, color: this.colors.borderSoft })
      .shadow({
        radius: 12,
        color: this.colors.shadowCard,
        offsetX: 0,
        offsetY: 4
      })
      .margin({ top: 20, bottom: 24 })
      .direction(L.isRtlLang(this.appLanguage) ? Direction.Rtl : Direction.Ltr)
    }
  }

  build() {
    Column() {
      // === TOP BAR ===
      Row({ space: 16 }) {
        Row() {
          Image($r('app.media.ic_chevron_right')).width(20).height(20)
            .fillColor(this.colors.textWhite)
            .rotate({ angle: L.isRtlLang(this.appLanguage) ? 0 : 180 })
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .borderRadius(20)
        .backgroundColor(this.colors.tintSoft)
        .onClick(() => router.back())

        Text(this.hadith !== null ? this.hadith.collection : this.tr('hadith_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%').height(72).padding({ left: 16, right: 16 })
      .backgroundColor(this.colors.cardDark)

      // === CONTENT ===
      if (this.hadith !== null) {
        Scroll() {
          Column() {


            this.HadithHeader()


            if (this.hadith.arabic_text.length > 0) {
              Column() {
                Text(this.hadith.arabic_text)
                  .fontSize(28)
                  .fontFamily('AmiriQuran, sans-serif')
                  .fontColor(this.colors.textWhite)
                  .lineHeight(50)
                  .textAlign(TextAlign.Start)
                  .direction(Direction.Rtl)
                  .width('100%')
              }
              .width('100%')
              .padding(20)
              .backgroundColor(this.colors.cardDark)
              .borderRadius(16)
              .border({ width: 1, color: this.colors.borderSoft })
              .margin({ bottom: 20 })
            } else {
              // Debug Fallback if Arabic is missing
              Text(`[Debug] Arabic missing for ID: ${this.hadith.id}`)
                .fontSize(14)
                .fontColor(this.colors.statusExpress)
                .width('100%')
                .margin({ bottom: 20, top: 10 })
                .textAlign(TextAlign.Center)
            }

            // 👇 3. TRANSLATION
            if (this.appLanguage !== 'ar' && this.hadith.translated_text.length > 0) {
              Column() {
                Row({ space: 8 }) {
                  Image($r('app.media.ic_globe')).width(16).height(16).fillColor(this.colors.accentGold)
                  Text(this.tr('hadith_translation'))
                    .fontSize(13)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.colors.accentGold)
                }.width('100%').margin({ bottom: 12 })

                Text(this.hadith.translated_text)
                  .fontSize(17)
                  .fontFamily('Outfit, sans-serif')
                  .fontColor(this.colors.textWhite)
                  .lineHeight(28)
                  .textAlign(TextAlign.Start)
                  .width('100%')
              }
              .width('100%')
              .padding(20)
              .backgroundColor(this.colors.cardDark)
              .borderRadius(16)
              .border({ width: 1, color: this.colors.borderSoft })
              .margin({ bottom: 20 })
            }

            Column().height(40)
          }
          .width('100%').padding({ left: 16, right: 16 })
        }
        .layoutWeight(1)
      } else {
        LoadingProgress().width(40).height(40).color(this.colors.accentGold).margin({ top: 40 })
      }
    }
    .width('100%').height('100%').backgroundColor(this.colors.primaryGreen)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }
}