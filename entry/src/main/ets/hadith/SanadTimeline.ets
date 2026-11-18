// entry/src/main/ets/hadith/SanadTimeline.ets

import { ThemeColors } from '../core/Theme';
import { L } from '../i18n/LocalizationHelper';
import { Sanad, SanadStep } from './HadithModels';

@Component
export struct SanadTimeline {
  @Prop colors: ThemeColors;
  @Prop sanad: Sanad;
  @Prop currentLanguage: string = 'en';

  build() {
    if (this.sanad.confidence !== 'none' && this.sanad.steps.length > 0) {
      Column() {
        // Header
        Row({ space: 8 }) {
          Text(L.get('sanad_title', this.currentLanguage))
            .fontSize(11)
            .fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Bold)
            .letterSpacing(1.2)
          Text(`${this.sanad.steps.length}`)
            .fontSize(11)
            .fontColor(this.colors.textMuted)
            .layoutWeight(1)
          Text(this.confidenceLabel())
            .fontSize(10)
            .fontColor(this.colors.accentGold)
            .backgroundColor(this.colors.tintSoft)
            .padding({
              left: 8,
              right: 8,
              top: 2,
              bottom: 2
            })
            .borderRadius(8)
        }
        .width('100%')
        .padding({ bottom: 10 })

        ForEach(
          this.sanad.steps,
          (step: SanadStep, idx: number) => {
            Row({ space: 10 }) {
              // Timeline dot + connector line
              Column() {
                if (idx > 0) {
                  Column()
                    .width(2).height(12)
                    .backgroundColor(this.colors.borderSoft)
                }
                Circle()
                  .width(10).height(10)
                  .fill(this.colors.accentGold)
                if (idx < this.sanad.steps.length - 1) {
                  Column()
                    .width(2).height(12)
                    .backgroundColor(this.colors.borderSoft)
                }
              }
              .width(20)
              .alignItems(HorizontalAlign.Center)

              Column() {
                // FIX: use displayName() which falls back past empty
                // strings, not just null.
                Text(this.displayName(step))
                  .fontSize(13)
                  .fontColor(this.colors.textWhite)
                  .fontWeight(FontWeight.Medium)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')

                Row({ space: 6 }) {
                  if (step.generation !== null && step.generation.length > 0) {
                    Text(step.generation)
                      .fontSize(10)
                      .fontColor(this.colors.accentGold)
                  }
                  if (step.reliability !== null && step.reliability.length > 0) {
                    Text('·')
                      .fontSize(10)
                      .fontColor(this.colors.textMuted)
                    Text(step.reliability)
                      .fontSize(10)
                      .fontColor(this.colors.textMuted)
                  }
                }
                .margin({ top: 2 })
                .width('100%')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding({ top: 4, bottom: 4 })
          },
          (step: SanadStep, idx: number) => `sanad-${idx}-${step.narrator_id}`
        )
      }
      .width('100%')
      .padding(16)
      .backgroundColor(this.colors.cardDark)
      .borderRadius(12)
      .border({ width: 1, color: this.colors.borderSoft })
      .margin({ bottom: 16 })
      .alignItems(HorizontalAlign.Start)
    }
  }

  /**
   * Robust narrator label resolution.
   *
   * The bundle pipeline fills name_en with an empty string '' (not
   * NULL) for the ~42,168 uncurated narrators. The nullish coalescing
   * operator (`??`) does not fall through on empty string, so the
   * direct expression `step.name_en ?? step.name_ar` was rendering
   * an empty Text node. This helper handles null, undefined, AND
   * empty string, falling back through name_en → name_ar →
   * narrator_id so a row can never be blank.
   */
  private displayName(step: SanadStep): string {
    if (step.name_en !== null && step.name_en !== undefined && step.name_en.length > 0) {
      return step.name_en;
    }
    if (step.name_ar !== null && step.name_ar !== undefined && step.name_ar.length > 0) {
      return step.name_ar;
    }
    return step.narrator_id;
  }

  private confidenceLabel(): string {
    switch (this.sanad.confidence) {
      case 'high':
        return L.get('sanad_confidence_high', this.currentLanguage);
      case 'medium':
        return L.get('sanad_confidence_medium', this.currentLanguage);
      case 'athar':
        return L.get('sanad_confidence_athar', this.currentLanguage);
      default:
        return '';
    }
  }
}