import { common, Want } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { ThemeColors, ThemeMode } from '../core/Theme';
import { PageTheme } from '../core/PageTheme';
import { L } from '../i18n/LocalizationHelper';
import { STORAGE_KEY_LANGUAGE, STORAGE_KEY_THEME_MODE } from '../core/StorageKeys';
import { PrivacyPolicyProvider } from '../legal/PrivacyPolicy';

@Entry
@Component
struct PrivacyPolicyPage {
  @StorageLink(STORAGE_KEY_THEME_MODE) @Watch('onThemeModeChanged') themeMode: string = ThemeMode.SYSTEM;
  @StorageLink(STORAGE_KEY_LANGUAGE) @Watch('onLangChanged') appLanguage: string = 'en';
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  @State policyText: string = '';
  @State isLoading: boolean = true;

  async aboutToAppear() {
    this.colors = PageTheme.compute(this.themeMode);
    await this.loadPolicy();
  }

  async onLangChanged() {
    await this.loadPolicy();
  }

  onThemeModeChanged() {
    this.colors = PageTheme.compute(this.themeMode);
  }

  async loadPolicy() {
    this.isLoading = true;
    const doc = await PrivacyPolicyProvider.load(this.appLanguage);
    this.policyText = doc.body;
    this.isLoading = false;
  }

  async openOnlinePolicy() {
    const ctx = getContext(this) as common.UIAbilityContext;
    const targetUrl = PrivacyPolicyProvider.getFullUrl(this.appLanguage);
    const want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: targetUrl
    };
    try {
      await ctx.startAbility(want);
    } catch (e) {
      this.getUIContext().getPromptAction().showToast({
        message: targetUrl, duration: 4000
      });
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

        Text(L.get('privacy_title', this.appLanguage))
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
      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).color(this.colors.accentGold)
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            Text(this.policyText.length > 0 ? this.policyText : 'No privacy policy available offline.')
              .fontSize(14)
              .fontColor(this.colors.textWhite)
              .lineHeight(22)
              .width('100%')
              .textAlign(TextAlign.Start)
              .margin({ bottom: 24 })

            // Online Link Button
            Button() {
              Row({ space: 8 }) {
                Image($r('app.media.ic_globe')).width(16).height(16).fillColor(this.colors.textOnAccent)
                Text(L.get('privacy_view_online', this.appLanguage))
                  .fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.colors.textOnAccent)
              }
            }
            .width('100%')
            .height(48)
            .backgroundColor(this.colors.accentGold)
            .borderRadius(12)
            .margin({ bottom: 40 })
            .onClick(() => this.openOnlinePolicy())

          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 20 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%').height('100%').backgroundColor(this.colors.primaryGreen)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }
}