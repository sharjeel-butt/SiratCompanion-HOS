// entry/src/main/ets/components/SubsectionHeader.ets

import { ThemeColors } from '../common/Theme';
import { L } from '../i8n/LocalizationHelper';

/**
 * Small gold section label used inside Customize's category bodies.
 *
 * A @Component rather than a parameterized @Builder: a @Builder
 * caches its arguments at first render, which left these headings
 * stuck in whatever language was active when the page first built.
 * @Prop is reactive, so the label re-resolves on every language change.
 */
@Component
export struct SubsectionHeader {
  @Prop colors: ThemeColors;
  @Prop titleKey: string = '';
  @Prop currentLanguage: string = 'en';

  build() {
    Text(L.get(this.titleKey, this.currentLanguage))
      .fontSize(12)
      .fontColor(this.colors.accentGold)
      .fontWeight(FontWeight.Bold)
      .letterSpacing(1.2)
      .width('100%')
      .padding({ left: 4, top: 8, bottom: 8 })
  }
}