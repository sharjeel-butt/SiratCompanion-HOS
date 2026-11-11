@Entry
@Component
struct EventWidget {
  @LocalStorageProp('dimension') dimension: string = '2*2';
  @LocalStorageProp('eventName') eventName: string = 'Isra and Mi\'raj';
  @LocalStorageProp('eventDays') eventDays: string = '55';
  @LocalStorageProp('eventDate') eventDate: string = '27 Rajab 1448';
  @LocalStorageProp('eventDesc') eventDesc: string = 'The night journey of Prophet Muhammad.';
  @LocalStorageProp('error') error: string = '';
  @LocalStorageProp('isRtl') isRtl: boolean = false;
  @LocalStorageProp('eventHijriYear') eventHijriYear: number = 0;
  @LocalStorageProp('eventHijriMonth') eventHijriMonth: number = 0;
  @LocalStorageProp('eventHijriDay') eventHijriDay: number = 0;
  @LocalStorageProp('lblUpcoming') lblUpcoming: string = 'NEXT EVENT';
  @LocalStorageProp('lblDays') lblDays: string = 'days';
  @LocalStorageProp('lblViewCal') lblViewCal: string = 'View Details';

  build() {
    Stack() {
      // Background
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
        Image($r('app.media.ic_star'))
          .width(120)
          .height(120)
          .fillColor('#FFFFFF')
          .opacity(0.03)
          .position({ x: '60%', y: '-10%' })
      }.width('100%').height('100%').clip(true).borderRadius(24)

      // Content
      Column() {
        if (this.error.length > 0) {
          Text(this.error)
            .fontSize('12vp').fontColor('#FF6B6B')
            .maxLines(3).textOverflow({ overflow: TextOverflow.Ellipsis })
        } else {

          // TOP SECTION
          Column() {
            // Header Row
            Row() {
              if (this.isRtl) {
                Image($r('app.media.ic_star')).width('12vp').height('12vp').fillColor('#E8A44C')
                Text(this.lblUpcoming)
                  .fontSize('11vp')
                  .fontColor('#A5B8CC')
                  .fontWeight(FontWeight.Bold)
                  .letterSpacing(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
                  .textAlign(TextAlign.RIGHT)
                  .margin({ right: 8 })
              } else {
                Text(this.lblUpcoming)
                  .fontSize('11vp')
                  .fontColor('#A5B8CC')
                  .fontWeight(FontWeight.Bold)
                  .letterSpacing(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
                  .textAlign(TextAlign.LEFT)
                Image($r('app.media.ic_star')).width('12vp').height('12vp').fillColor('#E8A44C').margin({ left: 8 })
              }
            }.width('100%').margin({ bottom: 6 }).direction(Direction.Ltr)

            // Event Name
            Text(this.eventName)
              .fontSize('16vp')
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .width('100%')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .textAlign(this.isRtl ? TextAlign.RIGHT : TextAlign.LEFT)
          }
          .width('100%')

          // MIDDLE SECTION (Countdown & Description)
          if (this.dimension === '2*4') {
            Row({ space: 12 }) {
              if (this.isRtl) {
                // Description Left, Countdown Right
                Column() {
                  Text(this.eventDesc)
                    .fontSize('12vp')
                    .fontColor('#A5B8CC')
                    .width('100%')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .textAlign(TextAlign.RIGHT)
                    .lineHeight('16vp')
                }
                .layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.End)

                Column({ space: 4 }) {
                  Row() {
                    // FIX: Manually swapped for RTL (Days first, Number second visually)
                    Text(` ${this.lblDays}`)
                      .fontSize('12vp')
                      .fontColor('#A5B8CC')
                      .margin({ right: 4, bottom: 4 })
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(this.eventDays)
                      .fontSize('30vp')
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#E8A44C')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }.alignItems(VerticalAlign.Bottom).direction(Direction.Ltr)

                  Text(this.eventDate)
                    .fontSize('10vp')
                    .fontColor('#E8A44C')
                    .backgroundColor('rgba(232, 164, 76, 0.15)')
                    .padding({
                      left: 6,
                      right: 6,
                      top: 2,
                      bottom: 2
                    })
                    .borderRadius(4)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }.alignItems(HorizontalAlign.Start)

              } else {
                // Countdown Left, Description Right
                Column({ space: 4 }) {
                  Row() {
                    Text(this.eventDays)
                      .fontSize('30vp')
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#E8A44C')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(` ${this.lblDays}`)
                      .fontSize('12vp')
                      .fontColor('#A5B8CC')
                      .margin({ left: 4, bottom: 4 })
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }.alignItems(VerticalAlign.Bottom).direction(Direction.Ltr)

                  Text(this.eventDate)
                    .fontSize('10vp')
                    .fontColor('#E8A44C')
                    .backgroundColor('rgba(232, 164, 76, 0.15)')
                    .padding({
                      left: 6,
                      right: 6,
                      top: 2,
                      bottom: 2
                    })
                    .borderRadius(4)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }.alignItems(HorizontalAlign.End)

                Column() {
                  Text(this.eventDesc)
                    .fontSize('12vp')
                    .fontColor('#A5B8CC')
                    .width('100%')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .textAlign(TextAlign.LEFT)
                    .lineHeight('16vp')
                }
                .layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.End)
              }
            }
            .width('100%').alignItems(VerticalAlign.Center).direction(Direction.Ltr)

          } else {
            // 2x2 LAYOUT
            Row() {
              if (this.isRtl) {
                Blank()
                // FIX: Manually swapped for RTL
                Text(` ${this.lblDays} `)
                  .fontSize('12vp')
                  .fontColor('#A5B8CC')
                  .margin({ right: 4, bottom: 4 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.eventDays)
                  .fontSize('30vp')
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#E8A44C')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              } else {
                Text(this.eventDays)
                  .fontSize('30vp')
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#E8A44C')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(` ${this.lblDays}`)
                  .fontSize('12vp')
                  .fontColor('#A5B8CC')
                  .margin({ left: 4, bottom: 4 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Blank()
              }
            }
            .width('100%')
            .margin({ top: 4 })
            .alignItems(VerticalAlign.Bottom)
            .direction(Direction.Ltr)
          }

          // BOTTOM SECTION (Footer)
          Row() {
            if (this.isRtl) {
              Image($r('app.media.ic_chevron_right'))
                .width('10vp')
                .height('10vp')
                .fillColor('#E8A44C')
                .rotate({ angle: 180 })
              Text(this.lblViewCal)
                .fontSize('10vp')
                .fontColor('#E8A44C')
                .fontWeight(FontWeight.Bold)
                .margin({ right: 4 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            } else {
              Text(this.lblViewCal)
                .fontSize('10vp')
                .fontColor('#E8A44C')
                .fontWeight(FontWeight.Bold)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Image($r('app.media.ic_chevron_right'))
                .width('10vp')
                .height('10vp')
                .fillColor('#E8A44C')
                .margin({ left: 4 })
            }
          }
          .width('100%')
          .justifyContent(this.isRtl ? FlexAlign.Start : FlexAlign.End)
          .direction(Direction.Ltr)

        }
      }
      .width('100%')
      .height('100%')
      .padding({
        top: 12,
        bottom: 16,
        left: 14,
        right: 14
      })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(this.isRtl ? HorizontalAlign.Start : HorizontalAlign.End)
    }
    .width('100%').height('100%')
    .direction(Direction.Ltr)
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        bundleName: 'com.siratcompanion.hos.app',
        abilityName: 'EntryAbility',
        params: {
          targetPage: 'pages/MainTabs',
          targetTab: 'calendar',
          // NEW: Pass the specific date
          targetHijriYear: this.eventHijriYear,
          targetHijriMonth: this.eventHijriMonth,
          targetHijriDay: this.eventHijriDay
        }
      });
    })
  }
}