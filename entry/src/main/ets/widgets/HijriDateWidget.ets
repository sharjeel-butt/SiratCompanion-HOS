import { WidgetCalendarDay } from './WidgetDataBuilder';

@Entry
@Component
struct HijriDateWidget {
  @LocalStorageProp('dimension') dimension: string = '2*2';
  @LocalStorageProp('hijriDay') hijriDay: string = '30';
  @LocalStorageProp('hijriMonth') hijriMonth: string = 'Jumada al-Thani';
  @LocalStorageProp('gregDate') gregDate: string = '11 Nov';
  @LocalStorageProp('dayOfWeek') dayOfWeek: string = 'Wed';
  @LocalStorageProp('isRtl') isRtl: boolean = false;
  @LocalStorageProp('error') error: string = '';
  // 4x4 Grid Props
  @LocalStorageProp('headerTitle') headerTitle: string = 'Jumada al-Thani 1445';
  @LocalStorageProp('weekdays') weekdays: string[] = [];
  @LocalStorageProp('calendarDays') calendarDays: WidgetCalendarDay[] = [];

  build() {
    Stack() {
      // Background Layer
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({ angle: 145, colors: [['#1A2235', 0], ['#0F1522', 1]] })
        .borderRadius(24)
        .border({ width: 1, color: 'rgba(255, 255, 255, 0.15)' })
        .shadow({
          radius: 16,
          color: 'rgba(0, 0, 0, 0.4)',
          offsetX: 0,
          offsetY: 6
        })

      // Watermark
      Stack() {
        Image($r('app.media.ic_nav_calendar'))
          .width(120)
          .height(120)
          .fillColor('#FFFFFF')
          .opacity(0.03)
          .position({ x: '60%', y: '-10%' })
      }
      .width('100%').height('100%').clip(true).borderRadius(24)

      // ==========================================
      // 4x4 CALENDAR LAYOUT
      // ==========================================
      if (this.dimension === '4*4') {
        Column() {
          // Header
          Row() {
            Text(this.headerTitle)
              .fontSize('14vp')
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%').justifyContent(FlexAlign.Center).margin({ bottom: 10 })

          // Weekday Headers
          Row() {
            ForEach(this.weekdays, (day: string) => {
              Text(day)
                .fontSize('9vp').fontColor('#A5B8CC').textAlign(TextAlign.Center)
                .layoutWeight(1)
            })
          }
          .width('100%').margin({ bottom: 6 }).direction(Direction.Ltr)

          // Days Grid
          // Days Grid
          Flex({
            wrap: FlexWrap.Wrap,
            alignContent: FlexAlign.SpaceBetween, // <-- FIX: Distributes rows evenly vertically
            justifyContent: FlexAlign.Center
          }) {
            ForEach(this.calendarDays, (cell: WidgetCalendarDay) => {
              Column() {
                if (!cell.isPadding) {
                  Text(cell.dayText)
                    .fontSize('11vp')
                    .fontWeight(cell.isToday ? FontWeight.Bold : FontWeight.Normal)
                    .fontColor(cell.isToday ? '#141B2E' : '#FFFFFF')
                    .width('22vp')
                    .height('22vp')
                    .textAlign(TextAlign.Center)
                    .backgroundColor(cell.isToday ? '#E8A44C' : Color.Transparent)
                    .borderRadius(11) // Circle shape

                  if (cell.hasEvent) {
                    Circle()
                      .width('4vp').height('4vp')
                      .fill(cell.isToday ? '#141B2E' : '#E8A44C')
                      .margin({ top: 2 })
                  } else {
                    Circle().width('4vp').height('4vp').fill(Color.Transparent).margin({ top: 2 })
                  }
                }
              }
              .width('14.28%') // 100% / 7 columns
              .height('34vp') // <-- FIX: Taller cells to fill the widget
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
            })
          }
          .width('100%')
          .layoutWeight(1)
          .direction(Direction.Ltr) // Keeps structural flex LTR

        }
        .width('100%').height('100%').padding(14)
        .direction(Direction.Ltr)

      } else {
        // ==========================================
        // 2x2 / 2x4 STANDARD LAYOUT
        // ==========================================
        Column() {
          if (this.error.length > 0) {
            Text(this.error).fontSize('12vp').fontColor('#FF6B6B')
          } else {
            Row({ space: 6 }) {
              if (this.isRtl) {
                Text(this.hijriMonth)
                  .fontSize('13vp')
                  .fontColor('#FFFFFF')
                  .fontWeight(FontWeight.Medium)
                  .constraintSize({ minWidth: 0 })
                Text(this.dayOfWeek).fontSize('13vp').fontColor('#FF7A59').fontWeight(FontWeight.Bold).flexShrink(0)
              } else {
                Text(this.dayOfWeek).fontSize('13vp').fontColor('#FF7A59').fontWeight(FontWeight.Bold).flexShrink(0)
                Text(this.hijriMonth)
                  .fontSize('13vp')
                  .fontColor('#FFFFFF')
                  .fontWeight(FontWeight.Medium)
                  .constraintSize({ minWidth: 0 })
              }
            }
            .width('100%').justifyContent(FlexAlign.Center).margin({ top: 8, bottom: 4 })

            Text(this.hijriDay)
              .fontSize('56vp')
              .fontWeight(FontWeight.Bolder)
              .fontColor('#FFFFFF')
              .margin({ top: 0, bottom: 4 })
              .maxLines(1)
              .textShadow({
                radius: 12,
                color: 'rgba(255, 255, 255, 0.25)',
                offsetX: 0,
                offsetY: 4
              })

            Divider().width('40%').color('rgba(255, 255, 255, 0.1)').strokeWidth(1).margin({ top: 4, bottom: 8 })

            Text(this.gregDate)
              .fontSize('11vp')
              .fontColor('#A5B8CC')
              .fontWeight(FontWeight.Medium)
              .letterSpacing(0.5)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .width('100%')
        .height('100%')
        .padding({
          left: 12,
          right: 12,
          top: 12,
          bottom: 12
        })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .direction(Direction.Ltr)
      }
    }
    .width('100%').height('100%')
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        bundleName: 'com.siratcompanion.hos.app',
        abilityName: 'EntryAbility',
        params: { targetPage: 'pages/MainTabs', targetTab: 'calendar' }
      });
    })
  }
}