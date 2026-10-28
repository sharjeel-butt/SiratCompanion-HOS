import { ThemeColors } from '../common/Theme';
import { L } from '../i8n/LocalizationHelper';

@Component
export struct CategoryHeader {
  @Prop colors: ThemeColors;
  @Prop icon: Resource;
  @Prop titleKey: string = '';
  @Prop categoryKey: string = '';
  @Prop expanded: boolean = false;
  @Prop currentLanguage: string = 'en';
  onTap: () => void = () => {
  };

  build() {
    Row({ space: 14 }) {
      Row() {
        Image(this.icon)
          .width(20)
          .height(20)
          .fillColor(this.colors.accentGold)
      }
      .width(40)
      .height(40)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.colors.tintSoft)
      .borderRadius(12)
      .border({ width: 1, color: this.colors.borderSoft })
      .flexShrink(0)

      Text(L.get(this.titleKey, this.currentLanguage))
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.colors.textWhite)
        .layoutWeight(1)
        .textAlign(TextAlign.Start)

      Image(this.expanded
        ? $r('app.media.ic_chevron_up')
        : $r('app.media.ic_chevron_down'))
        .width(16)
        .height(16)
        .fillColor(this.colors.accentGold)
        .opacity(0.8)
        .flexShrink(0)
    }
    .width('100%')
    .padding({
      top: 12,
      bottom: 12,
      left: 16,
      right: 16
    })
    .backgroundColor(this.colors.cardDark)
    .borderRadius(16)
    .border({ width: 1, color: this.colors.borderSoft })
    .margin({ bottom: 8 })
    .onClick(() => this.onTap())
  }
}