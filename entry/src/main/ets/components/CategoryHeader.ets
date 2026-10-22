import { ThemeColors } from '../common/Theme';
import { L } from '../i8n/LocalizationHelper';

@Component
export struct CategoryHeader {
  @Prop colors: ThemeColors;
  @Prop icon: string = '';
  @Prop titleKey: string = '';
  @Prop categoryKey: string = '';
  @Prop expanded: boolean = false;
  @Prop currentLanguage: string = 'en';
  onTap: () => void = () => {
  };

  build() {
    Row() {
      Text(this.icon)
        .fontSize(18)
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.colors.tintSoft)
        .borderRadius(12)
        .border({ width: 1, color: this.colors.borderSoft })
        .flexShrink(0)
        // Gap between Icon and Text
        .margin({
          right: L.isRtlLang(this.currentLanguage) ? 0 : 14,
          left: L.isRtlLang(this.currentLanguage) ? 14 : 0
        })

      Text(L.get(this.titleKey, this.currentLanguage))
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.colors.textWhite)

      Blank() // Pushes the arrow to the far edge

      Text(this.expanded ? '▲' : '▼')
        .fontSize(12)
        .fontColor(this.colors.accentGold)
        .opacity(0.8)
        .flexShrink(0)
    }
    .width('100%')
    // Flip the outer padding so the icon gets 12, arrow gets 16
    .padding(L.isRtlLang(this.currentLanguage)
      ? {
        top: 12,
        bottom: 12,
        left: 16,
        right: 12
      }
      : {
        top: 12,
        bottom: 12,
        left: 12,
        right: 16
      }
    )
    .backgroundColor(this.colors.cardDark)
    .borderRadius(16)
    .border({ width: 1, color: this.colors.borderSoft })
    .margin({ bottom: 8 })
    .onClick(() => this.onTap())
  }
}