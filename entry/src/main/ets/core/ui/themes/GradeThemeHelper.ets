// entry/src/main/ets/core/GradeThemeHelper.ets

import { ThemeColors } from './Theme'

export class GradeThemeHelper {
  static getTextColor(grade: string, colors: ThemeColors): string {
    if (!grade) {
      return colors.colorGradeUnverified
    }
    const g = grade.toLowerCase()
    if (g === 'sahih') {
      return colors.colorGradeSahih
    }
    if (g === 'hasan' || g === 'hasan_sahih') {
      return colors.colorGradeHasan
    }
    if (g === 'daif') {
      return colors.colorGradeDaif
    }
    if (g === 'mawdu') {
      return colors.colorGradeMawdu
    }
    return colors.colorGradeUnverified
  }

  static getBgColor(grade: string, colors: ThemeColors): string {
    if (!grade) {
      return colors.bgGradeUnverified
    }
    const g = grade.toLowerCase()
    if (g === 'sahih') {
      return colors.bgGradeSahih
    }
    if (g === 'hasan' || g === 'hasan_sahih') {
      return colors.bgGradeHasan
    }
    if (g === 'daif') {
      return colors.bgGradeDaif
    }
    if (g === 'mawdu') {
      return colors.bgGradeMawdu
    }
    return colors.bgGradeUnverified
  }
}
