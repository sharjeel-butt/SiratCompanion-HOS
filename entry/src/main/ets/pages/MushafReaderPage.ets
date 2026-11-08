// entry/src/main/ets/pages/MushafReaderPage.ets

import { router } from '@kit.ArkUI';
import { ThemeColors, ThemeMode } from '../core/Theme';
import { PageTheme } from '../core/PageTheme';
import { MushafPageView } from '../quran/MushafPageView';
import { MushafDbHelper } from '../quran/MushafDbHelper';
import { common } from '@kit.AbilityKit';
import { STORAGE_KEY_LANGUAGE } from '../core/StorageKeys';

@Entry
@Component
struct MushafReaderPage {
  @StorageLink(STORAGE_KEY_LANGUAGE) appLanguage: string = 'en';
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.SYSTEM);
  @State currentPage: number = 1;
  private pages: number[] = [];

  async aboutToAppear() {
    const ctx = getContext(this) as common.UIAbilityContext;
    await MushafDbHelper.init(ctx);

    // Initialize array of 604 pages
    for (let i = 1; i <= 604; i++) {
      this.pages.push(i);
    }

    // Optional: Jump to a specific page if passed via router params
    const params = router.getParams() as Record<string, Object>;
    if (params && typeof params['page'] === 'number') {
      this.currentPage = params['page'] as number;
    }
  }

  build() {
    Column() {
      // Top Bar
      Row() {
        Image($r('app.media.ic_chevron_right'))
          .width(24)
          .height(24)
          .fillColor(this.colors.textWhite)
          .rotate({ angle: 180 })
          .onClick(() => router.back())

        Text(`Page ${this.currentPage}`)
          .fontSize(18).fontColor(this.colors.textWhite).layoutWeight(1).textAlign(TextAlign.Center)

        Column().width(24) // Balance the row
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })
      .backgroundColor(this.colors.primaryGreen)

      // Swiper for Page Turning
      Swiper() {
        ForEach(this.pages, (pageNum: number) => {
          MushafPageView({
            pageNumber: pageNum,
            colors: this.colors
          })
        }, (pageNum: number) => `page-${pageNum}`)
      }
      .index(this.currentPage - 1)
      .loop(false)
      .indicator(false)
      .onChange((index: number) => {
        this.currentPage = index + 1;
      })
      .layoutWeight(1)
      .backgroundColor(this.colors.cardDark)
    }
    .width('100%').height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}