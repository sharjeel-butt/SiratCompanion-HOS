// entry/src/main/ets/components/CategoryHeader.ets

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

      Text(L.get(this.titleKey, this.currentLanguage))
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.colors.textWhite)
        .margin({ left: 14 })
        .layoutWeight(1)

      Text(this.expanded ? '▲' : '▼')
        .fontSize(12)
        .fontColor(this.colors.accentGold)
        .opacity(0.8)
    }
    .width('100%')
    .padding({
      top: 12,
      bottom: 12,
      left: 12,
      right: 16
    })
    .backgroundColor(this.colors.cardDark)
    .borderRadius(16)
    .border({ width: 1, color: this.colors.borderSoft })
    .margin({ bottom: 8 })
    .onClick(() => this.onTap())
  }
}