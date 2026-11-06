// entry/src/main/ets/pages/LicensesPage.ets

import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { util } from '@kit.ArkTS';
import { Theme, ThemeColors, ThemeMode } from '../core/Theme';
import { PageTheme } from '../core/PageTheme';
import { L } from '../i18n/LocalizationHelper';
import { STORAGE_KEY_LANGUAGE } from '../core/StorageKeys';
import { AppLogger } from '../core/AppLogger';

interface LicenseItem {
  name: string;
  source: string;
  sourceUrl: string;
  license: string;
  licenseUrl: string;
  attribution: string;
}

interface LicenseSection {
  id: string;
  items: LicenseItem[];
}

interface LicenseFile {
  datasetVersion: string;
  sections: LicenseSection[];
}

@Entry
@Component
struct LicensesPage {
  @StorageLink(STORAGE_KEY_LANGUAGE) @Watch('onLangChanged') appLanguage: string = 'en';
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.SYSTEM);
  @State sections: LicenseSection[] = [];
  @State datasetVersion: string = '';
  @State isLoading: boolean = true;

  async aboutToAppear() {
    await this.loadData();
  }

  onLangChanged() {
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const data = await ctx.resourceManager.getRawFileContent('licenses/quran_licenses.json');
      const parsed = JSON.parse(util.TextDecoder.create('utf-8').decodeToString(data)) as LicenseFile;
      this.sections = parsed.sections;
      this.datasetVersion = parsed.datasetVersion;
    } catch (e) {
      AppLogger.error('LicensesPage', `Failed to load: ${JSON.stringify(e)}`);
    }
    this.isLoading = false;
  }

  build() {
    Column() {
      // Top Bar
      Row({ space: 16 }) {
        Row() {
          Image($r('app.media.ic_chevron_right')).width(20).height(20)
            .fillColor(this.colors.textWhite)
            .rotate({ angle: this.isRtl() ? 0 : 180 })
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .borderRadius(20)
        .backgroundColor(this.colors.tintSoft)
        .onClick(() => router.back())

        Text(this.tr('licenses_title'))
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
      }
      .width('100%').height(72).padding({ left: 16, right: 16 })
      .backgroundColor(this.colors.cardDark)

      if (this.isLoading) {
        LoadingProgress().width(40).height(40).color(this.colors.accentGold).margin({ top: 40 })
      } else {
        Scroll() {
          Column({ space: 14 }) {
            // Intro
            Text(this.tr('licenses_intro'))
              .fontSize(13).fontColor(this.colors.textMuted).lineHeight(20)
              .width('100%')

            Text(`Dataset version: ${this.datasetVersion}`)
              .fontSize(11).fontColor(this.colors.accentGold).fontWeight(FontWeight.Medium)
              .width('100%')

            // Sections
            ForEach(this.sections, (section: LicenseSection) => {
              this.SectionCard(section)
            }, (section: LicenseSection) => section.id)

            Column().height(40)
          }
          .width('100%').padding(16)
        }
        .layoutWeight(1).scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  @Builder
  SectionCard(section: LicenseSection) {
    Column() {
      Text(this.tr('license_section_' + section.id))
        .fontSize(12)
        .fontColor(this.colors.accentGold)
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1.2)
        .width('100%')
        .padding({ bottom: 12 })

      Column({ space: 10 }) {
        ForEach(section.items, (item: LicenseItem) => {
          this.LicenseItemCard(item)
        }, (item: LicenseItem) => `${section.id}-${item.name}`)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusLarge)
    .border({ width: 1, color: this.colors.borderSoft })
  }

  @Builder
  LicenseItemCard(item: LicenseItem) {
    Column({ space: 6 }) {
      Text(item.name)
        .fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
        .width('100%')

      Row({ space: 6 }) {
        Text(this.tr('license_source_label'))
          .fontSize(11).fontColor(this.colors.textMuted).flexShrink(0)
        Text(item.source)
          .fontSize(11).fontColor(this.colors.textLight).layoutWeight(1)
      }.width('100%')

      Row({ space: 6 }) {
        Text(this.tr('license_license_label'))
          .fontSize(11).fontColor(this.colors.textMuted).flexShrink(0)
        Text(item.license)
          .fontSize(11).fontColor(this.colors.accentGold).layoutWeight(1)
      }.width('100%')

      if (item.attribution.length > 0) {
        Text(item.attribution)
          .fontSize(10)
          .fontColor(this.colors.textMuted)
          .fontStyle(FontStyle.Italic)
          .lineHeight(15)
          .width('100%')
          .margin({ top: 4 })
      }

      // License link (if present)
      if (item.licenseUrl.length > 0) {
        Row({ space: 4 }) {
          Image($r('app.media.ic_globe')).width(10).height(10).fillColor(this.colors.accentGold)
          Text(item.licenseUrl)
            .fontSize(10)
            .fontColor(this.colors.accentGold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%').margin({ top: 4 })
        .onClick(() => {
          const ctx = getContext(this) as common.UIAbilityContext;
          ctx.startAbility({
            action: 'ohos.want.action.viewData',
            entities: ['entity.system.browsable'],
            uri: item.licenseUrl
          }).catch((e: Error) => console.error(e.message));
        })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.colors.tintSubtle)
    .borderRadius(10)
    .alignItems(HorizontalAlign.Start)
  }

  private tr(key: string): string {
    return L.get(key, this.appLanguage);
  }

  private isRtl(): boolean {
    return L.isRtlLang(this.appLanguage);
  }
}