// entry/src/main/ets/components/ExtraTimingToggleRow.ets

import { ThemeColors } from '../common/Theme';
import { L } from '../helper/LocalizationHelper';

/**
 * A single toggle row for one extra timing on one surface — either
 * the prayer list or the sun path.
 *
 * A @Component rather than a @Builder: a parameterized @Builder
 * snapshots its arguments at first render, which freezes the
 * toggle state and label in whatever value was active when the
 * parent first built.
 *
 * Note: the "on" state prop is named isOn, not enabled —
 * CustomComponent already declares enabled(value) as a chainable
 * attribute method, and a @Prop with that name shadows it.
 */
@Component
export struct ExtraTimingToggleRow {
  @Prop colors: ThemeColors;
  @Prop titleKey: string = '';
  @Prop descriptionKey: string = '';
  @Prop currentLanguage: string = 'en';
  @Prop isOn: boolean = true;
  onToggle: (isOn: boolean) => void = () => {
  };

  build() {
    Row() {
      Column() {
        Text(L.get(this.titleKey, this.currentLanguage))
          .fontSize(15)
          .fontColor(this.colors.textWhite)
          .fontWeight(FontWeight.Medium)
          .width('100%')

        Text(L.get(this.descriptionKey, this.currentLanguage))
          .fontSize(11)
          .fontColor(this.colors.textMuted)
          .margin({ top: 2 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: this.isOn })
        .selectedColor(this.colors.accentGold)
        .onChange((value: boolean) => {
          this.onToggle(value);
        })
    }
    .width('100%')
    .padding({
      top: 12,
      bottom: 12,
      left: 16,
      right: 16
    })
    .backgroundColor(this.colors.tintSubtle)
    .borderRadius(12)
    .margin({ bottom: 6 })
  }
}