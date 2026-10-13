// entry/src/main/ets/components/CalendarDayCell.ets

import { ThemeColors } from '../common/Theme';
import { CalendarDay } from '../hijricalendar/HijriCalendarModels';

/**
 * One day cell in the Hijri calendar grid.
 *
 * A @Component rather than a parameterized @Builder — a @Builder
 * caches its object arguments at first render, so a cell would
 * keep showing the events it had when the row was first built even
 * after the month data was rebuilt. @Prop updates whenever the
 * parent passes a new CalendarDay.
 */
@Component
export struct CalendarDayCell {
  @Prop cell: CalendarDay;
  @Prop colors: ThemeColors;

  build() {
    Column() {
      Text(`${this.cell.hijri.day}`)
        .fontSize(17)
        .fontWeight(this.cell.isToday
          ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.cell.isToday
          ? this.colors.textOnAccent
          : (this.cell.events.length > 0
            ? this.colors.accentGold
            : this.colors.textWhite))

      Text(`${this.cell.gregorianDate.getDate()}`)
        .fontSize(10)
        .fontColor(this.cell.isToday
          ? this.colors.textOnAccent : this.colors.textMuted)
        .opacity(this.cell.isToday ? 0.85 : 0.7)
        .margin({ top: -2 })

      if (this.cell.events.length > 0 && !this.cell.isToday) {
        Row()
          .width(5)
          .height(5)
          .borderRadius(3)
          .backgroundColor(this.colors.accentGold)
          .margin({ top: 3 })
      } else if (this.cell.events.length > 0 && this.cell.isToday) {
        Row()
          .width(5)
          .height(5)
          .borderRadius(3)
          .backgroundColor(this.colors.textOnAccent)
          .margin({ top: 3 })
      } else {
        Row().width(5).height(5).margin({ top: 3 })
      }
    }
    .layoutWeight(1)
    .height(56)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.cell.isToday
      ? this.colors.accentGold
      : (this.cell.isFriday ? this.colors.tintSubtle : Color.Transparent))
    .borderRadius(10)
    .border(this.cell.isFriday && !this.cell.isToday
      ? { width: 1, color: this.colors.borderSoft }
      : { width: 0 })
    .margin({ left: 2, right: 2 })
  }
}