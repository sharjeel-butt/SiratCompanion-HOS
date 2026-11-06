// entry/src/main/ets/pages/QuranPage.ets

import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { ThemeColors, ThemeMode } from '../core/Theme';
import { PageTheme } from '../core/PageTheme';
import { L } from '../i18n/LocalizationHelper';
import { QuranService } from '../quran/QuranService';
import { CompleteSurah } from '../quran/QuranSurahModels';
import { TypographyHelper } from '../core/TypographyHelper';
import { STORAGE_KEY_LANGUAGE } from '../core/StorageKeys';
import { NavHelper } from '../core/NavHelper';

@Entry
@Component
struct QuranPage {
  @StorageLink(STORAGE_KEY_LANGUAGE) @Watch('onLangChanged') appLanguage: string = 'en';
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.SYSTEM);
  @State allSurahs: CompleteSurah[] = [];
  @State filteredSurahs: CompleteSurah[] = [];
  @State searchQuery: string = '';
  @State isLoading: boolean = true;

  async aboutToAppear() {
    await this.loadData();
  }

  onLangChanged() {
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    const ctx = getContext(this) as common.UIAbilityContext;
    this.allSurahs = await QuranService.loadSurahs(ctx, this.appLanguage);
    this.applyFilter();
    this.isLoading = false;
  }

  applyFilter() {
    if (this.searchQuery.trim().length === 0) {
      this.filteredSurahs = this.allSurahs;
    } else {
      const q = this.searchQuery.toLowerCase();
      this.filteredSurahs = this.allSurahs.filter(s =>
      s.nameTransliteration.toLowerCase().includes(q) ||
        s.nameMeaning.toLowerCase().includes(q) ||
        s.id.toString() === q
      );
    }
  }

  build() {
    Column() {
      // Top Bar
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

        Text(L.get('quran_full_title', this.appLanguage))
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .layoutWeight(1)
          .textAlign(TextAlign.Start)

        // Info icon → LicensesPage
        Row() {
          Image($r('app.media.ic_info')).width(20).height(20).fillColor(this.colors.accentGold)
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .borderRadius(20)
        .backgroundColor(this.colors.tintSoft)
        .onClick(() => {
          NavHelper.prepareForward();
          router.pushUrl({ url: 'pages/LicensesPage' })
            .catch((e: Error) => console.error(e.message));
        })
      }
      .width('100%').height(72).padding({ left: 16, right: 16 })
      .backgroundColor(this.colors.cardDark)

      // Search Bar
      Search({
        value: this.searchQuery,
        placeholder: L.get('search_surahs', this.appLanguage)
      })
        .onChange((val: string) => {
          this.searchQuery = val;
          this.applyFilter();
        })
        .margin({
          left: 16,
          right: 16,
          top: 16,
          bottom: 8
        })
        .backgroundColor(this.colors.cardDark)
        .placeholderColor(this.colors.textMuted)
        .textFont({ size: 15 })

      // List
      if (this.isLoading) {
        LoadingProgress().width(40).height(40).color(this.colors.accentGold).margin({ top: 40 })
      } else {
        List({ space: 12 }) {
          ForEach(this.filteredSurahs, (surah: CompleteSurah) => {
            ListItem() {
              Row() {
                // Surah Number
                Column() {
                  Text(`${surah.id}`)
                    .fontSize(14).fontWeight(FontWeight.Bold)
                    .fontColor(this.colors.accentGold)
                }
                .width(40)
                .height(40)
                .borderRadius(20)
                .backgroundColor(this.colors.tintSubtle)
                .border({ width: 1, color: this.colors.accentGold })
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .flexShrink(0)

                // Surah Names
                Column() {
                  Text(surah.nameTransliteration)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.colors.textWhite)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(`${surah.nameMeaning} · ${surah.ayahCount} ${L.get('ayahs', this.appLanguage)}`)
                    .fontSize(11)
                    .fontColor(this.colors.textMuted)
                    .margin({ top: 4 })
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .alignItems(HorizontalAlign.Start).layoutWeight(1)
                .padding({ left: 12, right: 12 })

                // Arabic Name (Uses the correct script)
                Text(surah.nameArabic)
                  .fontSize(22)
                  .fontFamily(TypographyHelper.getQuranFont(this.appLanguage)) // <-- Rulebook compliant
                  .fontColor(this.colors.accentGold)
                  .flexShrink(0)
              }
              .width('100%')
              .padding(16)
              .backgroundColor(this.colors.cardDark)
              .borderRadius(12)
              .border({ width: 1, color: this.colors.borderSoft })
              .direction(L.isRtlLang(this.appLanguage) ? Direction.Rtl : Direction.Ltr)
              .onClick(() => {
                NavHelper.prepareForward();
                router.pushUrl({
                  url: 'pages/SurahDetailsPage',
                  params: { surahId: surah.id }
                }).catch((e: Error) => console.error('Navigation failed', e));
              })
            }
          }, (surah: CompleteSurah) => `quran-${surah.id}`)
        }
        .width('100%').layoutWeight(1).padding({ left: 16, right: 16, bottom: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr) // Rulebook §A
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  private isRtl(): boolean {
    return L.isRtlLang(this.appLanguage);
  }
}