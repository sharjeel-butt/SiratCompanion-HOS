// entry/src/main/ets/hadith/GradeBadge.ets

import { ThemeColors } from '../core/ui/themes/Theme';
import { L } from '../i18n/LocalizationHelper';
import { HadithGrading } from './HadithModels';
import { GradeThemeHelper } from '../core/ui/themes/GradeThemeHelper';

@Component
export struct GradeBadge {
  @Prop colors: ThemeColors;
  @Prop grades: HadithGrading[];
  @Prop currentLanguage: string = 'en';

  build() {
    if (this.grades.length > 0) {
      Column() {
        Row({ space: 8 }) {
          Text(L.get('hadith_grade_title', this.currentLanguage))
            .fontSize(11)
            .fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Bold)
            .letterSpacing(1.2)
            .layoutWeight(1)
        }.width('100%').padding({ bottom: 8 })

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.grades, (g: HadithGrading, i: number) => {
            Row({ space: 4 }) {
              Image(this.iconFor(g.grade))
                .width(12)
                .height(12)
                .fillColor(GradeThemeHelper.getTextColor(g.grade, this.colors)) // 👈 Global Color
              Text(`${this.gradeLabel(g.grade)} (${this.graderLabel(g.grader)})`)
                .fontSize(10)
                .fontColor(GradeThemeHelper.getTextColor(g.grade, this.colors)) // 👈 Global Color
                .fontWeight(FontWeight.Medium)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .padding({
              left: 8,
              right: 8,
              top: 4,
              bottom: 4
            })
            .backgroundColor(GradeThemeHelper.getBgColor(g.grade, this.colors)) // 👈 Global Color
            .borderRadius(6)
            .border({ width: 1, color: GradeThemeHelper.getTextColor(g.grade, this.colors) }) // 👈 Global Color
            .margin({ right: 4, top: 4 })
          }, (g: HadithGrading, i: number) => `grade-${i}-${g.grade}-${g.grader}`)
        }.width('100%')
      }
      .width('100%')
      .padding(12)
      .backgroundColor(this.colors.tintSubtle)
      .borderRadius(10)
      .border({ width: 1, color: this.colors.borderSoft })
      .margin({ bottom: 16 })
      .alignItems(HorizontalAlign.Start)
    } else {
      Text(L.get('hadith_grade_unverified', this.currentLanguage))
        .fontSize(11)
        .fontColor(this.colors.textMuted)
        .fontStyle(FontStyle.Italic)
        .width('100%')
        .padding(10)
        .backgroundColor(this.colors.tintSubtle)
        .borderRadius(8)
        .margin({ bottom: 16 })
    }
  }

  private iconFor(grade: string): Resource {
    if (grade === 'sahih' || grade === 'hasan') {
      return $r('app.media.ic_check');
    }
    if (grade === 'daif') {
      return $r('app.media.ic_warning');
    }
    return $r('app.media.ic_info');
  }

  private gradeLabel(grade: string): string {
    switch (grade) {
      case 'sahih':
        return L.get('grade_sahih', this.currentLanguage);
      case 'hasan':
        return L.get('grade_hasan', this.currentLanguage);
      case 'daif':
        return L.get('grade_daif', this.currentLanguage);
      case 'mawdu':
        return L.get('grade_mawdu', this.currentLanguage);
      default:
        return L.get('grade_unverified', this.currentLanguage);
    }
  }

  private graderLabel(grader: string): string {
    switch (grader) {
      case 'albani':
        return 'Al-Albani';
      case 'zubair_ali_zai':
        return 'Zubair Ali Zai';
      case 'shuaib_al_arnaut':
        return 'Shuaib Al Arnaut';
      case 'abu_ghuddah':
        return 'Abu Ghuddah';
      case 'salim_al_hilali':
        return 'Salim Al-Hilali';
      case 'abdul_hamid':
        return 'Abdul Hamid';
      case 'abd_al_baqi':
        return 'Abd Al-Baqi';
      case 'bukhari':
        return 'Al-Bukhari';
      case 'muslim':
        return 'Muslim';
      case 'tirmidhi':
        return 'Al-Tirmidhi';
      case 'collection_consensus':
        return 'Collection Consensus';
      default:
        return grader;
    }
  }
}