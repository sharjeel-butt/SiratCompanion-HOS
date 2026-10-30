// entry/src/main/ets/components/SettingsRow.ets

import { ThemeColors } from '../common/Theme';
import { L } from '../i8n/LocalizationHelper';

/**
 * A single tappable settings row: title, optional description, a
 * current-value line, and a chevron.
 *
 * Extracted from SettingsPage as a proper @Component so that the
 * tap callback is re-bound on every parent render. A parameterized
 * @Builder caches its arguments at first render on some ArkUI
 * builds, which caused the tap to stop firing after state changes.
 */
@Component
export struct SettingsRow {
  @Prop colors: ThemeColors;
  @Prop title: string = '';
  @Prop description: string = '';
  @Prop value: string = '';
  /** Tap handler supplied by the parent. */
  onTap: () => void = () => {
  };

  build() {
    Row({ space: 8 }) {
      Column() {
        Text(this.title)
          .fontSize(15)
          .fontColor(this.colors.textWhite)
          .fontWeight(FontWeight.Medium)

        if (this.description.length > 0) {
          Text(this.description)
            .fontSize(11)
            .fontColor(this.colors.textMuted)
            .margin({ top: 2 })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        Text(this.value)
          .fontSize(12)
          .fontColor(this.colors.accentGold)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 6 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Image($r('app.media.ic_chevron_right'))
        .width(16)
        .height(16)
        .fillColor(this.colors.accentGold)
        .opacity(0.7)
        .rotate({ angle: L.isRtl() ? 180 : 0 })
        .flexShrink(0)
    }
    .width('100%')
    .padding({
      top: 14,
      bottom: 14,
      left: 16,
      right: 16
    })
    .backgroundColor(this.colors.tintSubtle)
    .borderRadius(12)
    .margin({ bottom: 8 })
    .onClick(() => {
      this.onTap();
    })
  }
}