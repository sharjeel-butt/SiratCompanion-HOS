@Entry
@Component
struct PrayerWidget {
  @LocalStorageProp('dimension') dimension: string = '2*2';
  @LocalStorageProp('city') city: string = '—';
  @LocalStorageProp('hijriDate') hijriDate: string = '—';
  @LocalStorageProp('nextId') nextId: string = '—';
  @LocalStorageProp('nextName') nextName: string = '—';
  @LocalStorageProp('nextTime') nextTime: string = '--:--';
  @LocalStorageProp('countdown') countdown: string = '';
  @LocalStorageProp('currentName') currentName: string = '—';
  @LocalStorageProp('currentTime') currentTime: string = '--:--';
  @LocalStorageProp('isCurrentYesterday') isCurrentYesterday: boolean = false;
  @LocalStorageProp('lblYesterday') lblYesterday: string = 'Yesterday';
  @LocalStorageProp('progressPercent') progressPercent: number = 0;
  @LocalStorageProp('contextLabel1') contextLabel1: string = '—';
  @LocalStorageProp('contextTime1') contextTime1: string = '--:--';
  @LocalStorageProp('contextLabel2') contextLabel2: string = '—';
  @LocalStorageProp('contextTime2') contextTime2: string = '--:--';
  @LocalStorageProp('fajrName') fajrName: string = 'Fajr';
  @LocalStorageProp('fajrTime') fajrTime: string = '--:--';
  @LocalStorageProp('dhuhrName') dhuhrName: string = 'Dhuhr';
  @LocalStorageProp('dhuhrTime') dhuhrTime: string = '--:--';
  @LocalStorageProp('asrName') asrName: string = 'Asr';
  @LocalStorageProp('asrTime') asrTime: string = '--:--';
  @LocalStorageProp('maghribName') maghribName: string = 'Maghrib';
  @LocalStorageProp('maghribTime') maghribTime: string = '--:--';
  @LocalStorageProp('ishaName') ishaName: string = 'Isha';
  @LocalStorageProp('ishaTime') ishaTime: string = '--:--';
  @LocalStorageProp('lang') lang: string = 'en';
  @LocalStorageProp('error') error: string = '';

  build() {
    Stack() {
      Column() {
        if (this.error.length > 0) {
          Column() {
            Text(this.error).fontSize('14vp').fontColor('#FF6B6B').textAlign(TextAlign.Center).width('100%')
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
        } else {

          // ========== HEADER ==========
          if (this.dimension === '2*2') {
            Column() {
              Text(this.hijriDate)
                .fontSize('10vp')
                .fontColor('#E8A44C')
                .width('100%')
                .textAlign(this.isRtl() ? TextAlign.RIGHT : TextAlign.LEFT)
                .maxLines(1)
              Text(this.city)
                .fontSize('12vp')
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .width('100%')
                .textAlign(this.isRtl() ? TextAlign.RIGHT : TextAlign.LEFT)
                .maxLines(1)
                .margin({ top: 2 })
            }
            .width('100%').alignItems(this.isRtl() ? HorizontalAlign.End : HorizontalAlign.Start).margin({ bottom: 8 })
          } else {
            Row() {
              if (this.isRtl()) {
                Text(this.hijriDate).fontSize('10vp').fontColor('#E8A44C').maxLines(1).flexShrink(0)
                Text(this.city)
                  .fontSize('12vp')
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                  .maxLines(1)
                  .layoutWeight(1)
                  .textAlign(TextAlign.RIGHT)
              } else {
                Text(this.city)
                  .fontSize('12vp')
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                  .maxLines(1)
                  .layoutWeight(1)
                  .textAlign(TextAlign.LEFT)
                Text(this.hijriDate).fontSize('10vp').fontColor('#E8A44C').maxLines(1).flexShrink(0)
              }
            }
            .width('100%').margin({ bottom: 12 }).direction(Direction.Ltr)
          }

          // ========== BODY ==========
          if (this.dimension === '2*2') {
            Column() {
              Text(this.nextName)
                .fontSize('18vp')
                .fontColor('#AAAAAA')
                .width('100%')
                .textAlign(this.isRtl() ? TextAlign.RIGHT : TextAlign.LEFT)
                .letterSpacing(1)
                .maxLines(1)
              Text(this.nextTime)
                .fontSize('32vp')
                .fontWeight(FontWeight.Bold)
                .fontColor('#E8A44C')
                .width('100%')
                .textAlign(this.isRtl() ? TextAlign.RIGHT : TextAlign.LEFT)
                .margin({ top: 2 })
                .maxLines(1)
              Text(this.countdown)
                .fontSize('14vp')
                .fontColor('#FFFFFF')
                .width('100%')
                .textAlign(this.isRtl() ? TextAlign.RIGHT : TextAlign.LEFT)
                .margin({ top: 4 })
                .opacity(0.8)
                .maxLines(1)
            }
            .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)

          } else if (this.dimension === '2*4') {
            Column() {
              Row({ space: 6 }) {
                if (this.isRtl()) {
                  Column() {
                    Image($r('app.media.ic_prayer_sajdah'))
                      .width('16vp')
                      .height('16vp')
                      .fillColor(this.nextId === 'isha' ? '#E8A44C' : '#A5B8CC')
                      .margin({ bottom: 4 })
                    Text(this.ishaName)
                      .fontSize('10vp')
                      .fontColor(this.nextId === 'isha' ? '#E8A44C' : '#A5B8CC')
                      .fontWeight(this.nextId === 'isha' ? FontWeight.Bold : FontWeight.Normal)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(this.ishaTime)
                      .fontSize('10vp')
                      .fontColor(this.nextId === 'isha' ? '#E8A44C' : '#FFFFFF')
                      .fontWeight(this.nextId === 'isha' ? FontWeight.Bold : FontWeight.Medium)
                      .maxLines(1)
                      .margin({ top: 2 })
                  }
                  .layoutWeight(1)
                  .height('100%')
                  .justifyContent(FlexAlign.Center)
                  .backgroundColor(this.nextId === 'isha' ? 'rgba(232, 164, 76, 0.15)' : 'rgba(255, 255, 255, 0.05)')
                  .borderRadius(8)

                  Column() {
                    Image($r('app.media.ic_prayer_sajdah'))
                      .width('16vp')
                      .height('16vp')
                      .fillColor(this.nextId === 'maghrib' ? '#E8A44C' : '#A5B8CC')
                      .margin({ bottom: 4 })
                    Text(this.maghribName)
                      .fontSize('10vp')
                      .fontColor(this.nextId === 'maghrib' ? '#E8A44C' : '#A5B8CC')
                      .fontWeight(this.nextId === 'maghrib' ? FontWeight.Bold : FontWeight.Normal)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(this.maghribTime)
                      .fontSize('10vp')
                      .fontColor(this.nextId === 'maghrib' ? '#E8A44C' : '#FFFFFF')
                      .fontWeight(this.nextId === 'maghrib' ? FontWeight.Bold : FontWeight.Medium)
                      .maxLines(1)
                      .margin({ top: 2 })
                  }
                  .layoutWeight(1)
                  .height('100%')
                  .justifyContent(FlexAlign.Center)
                  .backgroundColor(this.nextId === 'maghrib' ? 'rgba(232, 164, 76, 0.15)' : 'rgba(255, 255, 255, 0.05)')
                  .borderRadius(8)

                  Column() {
                    Image($r('app.media.ic_prayer_sajdah'))
                      .width('16vp')
                      .height('16vp')
                      .fillColor(this.nextId === 'asr' ? '#E8A44C' : '#A5B8CC')
                      .margin({ bottom: 4 })
                    Text(this.asrName)
                      .fontSize('10vp')
                      .fontColor(this.nextId === 'asr' ? '#E8A44C' : '#A5B8CC')
                      .fontWeight(this.nextId === 'asr' ? FontWeight.Bold : FontWeight.Normal)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(this.asrTime)
                      .fontSize('10vp')
                      .fontColor(this.nextId === 'asr' ? '#E8A44C' : '#FFFFFF')
                      .fontWeight(this.nextId === 'asr' ? FontWeight.Bold : FontWeight.Medium)
                      .maxLines(1)
                      .margin({ top: 2 })
                  }
                  .layoutWeight(1)
                  .height('100%')
                  .justifyContent(FlexAlign.Center)
                  .backgroundColor(this.nextId === 'asr' ? 'rgba(232, 164, 76, 0.15)' : 'rgba(255, 255, 255, 0.05)')
                  .borderRadius(8)

                  Column() {
                    Image($r('app.media.ic_prayer_sajdah'))
                      .width('16vp')
                      .height('16vp')
                      .fillColor(this.nextId === 'dhuhr' ? '#E8A44C' : '#A5B8CC')
                      .margin({ bottom: 4 })
                    Text(this.dhuhrName)
                      .fontSize('10vp')
                      .fontColor(this.nextId === 'dhuhr' ? '#E8A44C' : '#A5B8CC')
                      .fontWeight(this.nextId === 'dhuhr' ? FontWeight.Bold : FontWeight.Normal)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(this.dhuhrTime)
                      .fontSize('10vp')
                      .fontColor(this.nextId === 'dhuhr' ? '#E8A44C' : '#FFFFFF')
                      .fontWeight(this.nextId === 'dhuhr' ? FontWeight.Bold : FontWeight.Medium)
                      .maxLines(1)
                      .margin({ top: 2 })
                  }
                  .layoutWeight(1)
                  .height('100%')
                  .justifyContent(FlexAlign.Center)
                  .backgroundColor(this.nextId === 'dhuhr' ? 'rgba(232, 164, 76, 0.15)' : 'rgba(255, 255, 255, 0.05)')
                  .borderRadius(8)

                  Column() {
                    Image($r('app.media.ic_prayer_sajdah'))
                      .width('16vp')
                      .height('16vp')
                      .fillColor(this.nextId === 'fajr' ? '#E8A44C' : '#A5B8CC')
                      .margin({ bottom: 4 })
                    Text(this.fajrName)
                      .fontSize('10vp')
                      .fontColor(this.nextId === 'fajr' ? '#E8A44C' : '#A5B8CC')
                      .fontWeight(this.nextId === 'fajr' ? FontWeight.Bold : FontWeight.Normal)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(this.fajrTime)
                      .fontSize('10vp')
                      .fontColor(this.nextId === 'fajr' ? '#E8A44C' : '#FFFFFF')
                      .fontWeight(this.nextId === 'fajr' ? FontWeight.Bold : FontWeight.Medium)
                      .maxLines(1)
                      .margin({ top: 2 })
                  }
                  .layoutWeight(1)
                  .height('100%')
                  .justifyContent(FlexAlign.Center)
                  .backgroundColor(this.nextId === 'fajr' ? 'rgba(232, 164, 76, 0.15)' : 'rgba(255, 255, 255, 0.05)')
                  .borderRadius(8)
                } else {
                  Column() {
                    Image($r('app.media.ic_prayer_sajdah'))
                      .width('16vp')
                      .height('16vp')
                      .fillColor(this.nextId === 'fajr' ? '#E8A44C' : '#A5B8CC')
                      .margin({ bottom: 4 })
                    Text(this.fajrName)
                      .fontSize('10vp')
                      .fontColor(this.nextId === 'fajr' ? '#E8A44C' : '#A5B8CC')
                      .fontWeight(this.nextId === 'fajr' ? FontWeight.Bold : FontWeight.Normal)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(this.fajrTime)
                      .fontSize('10vp')
                      .fontColor(this.nextId === 'fajr' ? '#E8A44C' : '#FFFFFF')
                      .fontWeight(this.nextId === 'fajr' ? FontWeight.Bold : FontWeight.Medium)
                      .maxLines(1)
                      .margin({ top: 2 })
                  }
                  .layoutWeight(1)
                  .height('100%')
                  .justifyContent(FlexAlign.Center)
                  .backgroundColor(this.nextId === 'fajr' ? 'rgba(232, 164, 76, 0.15)' : 'rgba(255, 255, 255, 0.05)')
                  .borderRadius(8)

                  Column() {
                    Image($r('app.media.ic_prayer_sajdah'))
                      .width('16vp')
                      .height('16vp')
                      .fillColor(this.nextId === 'dhuhr' ? '#E8A44C' : '#A5B8CC')
                      .margin({ bottom: 4 })
                    Text(this.dhuhrName)
                      .fontSize('10vp')
                      .fontColor(this.nextId === 'dhuhr' ? '#E8A44C' : '#A5B8CC')
                      .fontWeight(this.nextId === 'dhuhr' ? FontWeight.Bold : FontWeight.Normal)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(this.dhuhrTime)
                      .fontSize('10vp')
                      .fontColor(this.nextId === 'dhuhr' ? '#E8A44C' : '#FFFFFF')
                      .fontWeight(this.nextId === 'dhuhr' ? FontWeight.Bold : FontWeight.Medium)
                      .maxLines(1)
                      .margin({ top: 2 })
                  }
                  .layoutWeight(1)
                  .height('100%')
                  .justifyContent(FlexAlign.Center)
                  .backgroundColor(this.nextId === 'dhuhr' ? 'rgba(232, 164, 76, 0.15)' : 'rgba(255, 255, 255, 0.05)')
                  .borderRadius(8)

                  Column() {
                    Image($r('app.media.ic_prayer_sajdah'))
                      .width('16vp')
                      .height('16vp')
                      .fillColor(this.nextId === 'asr' ? '#E8A44C' : '#A5B8CC')
                      .margin({ bottom: 4 })
                    Text(this.asrName)
                      .fontSize('10vp')
                      .fontColor(this.nextId === 'asr' ? '#E8A44C' : '#A5B8CC')
                      .fontWeight(this.nextId === 'asr' ? FontWeight.Bold : FontWeight.Normal)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(this.asrTime)
                      .fontSize('10vp')
                      .fontColor(this.nextId === 'asr' ? '#E8A44C' : '#FFFFFF')
                      .fontWeight(this.nextId === 'asr' ? FontWeight.Bold : FontWeight.Medium)
                      .maxLines(1)
                      .margin({ top: 2 })
                  }
                  .layoutWeight(1)
                  .height('100%')
                  .justifyContent(FlexAlign.Center)
                  .backgroundColor(this.nextId === 'asr' ? 'rgba(232, 164, 76, 0.15)' : 'rgba(255, 255, 255, 0.05)')
                  .borderRadius(8)

                  Column() {
                    Image($r('app.media.ic_prayer_sajdah'))
                      .width('16vp')
                      .height('16vp')
                      .fillColor(this.nextId === 'maghrib' ? '#E8A44C' : '#A5B8CC')
                      .margin({ bottom: 4 })
                    Text(this.maghribName)
                      .fontSize('10vp')
                      .fontColor(this.nextId === 'maghrib' ? '#E8A44C' : '#A5B8CC')
                      .fontWeight(this.nextId === 'maghrib' ? FontWeight.Bold : FontWeight.Normal)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(this.maghribTime)
                      .fontSize('10vp')
                      .fontColor(this.nextId === 'maghrib' ? '#E8A44C' : '#FFFFFF')
                      .fontWeight(this.nextId === 'maghrib' ? FontWeight.Bold : FontWeight.Medium)
                      .maxLines(1)
                      .margin({ top: 2 })
                  }
                  .layoutWeight(1)
                  .height('100%')
                  .justifyContent(FlexAlign.Center)
                  .backgroundColor(this.nextId === 'maghrib' ? 'rgba(232, 164, 76, 0.15)' : 'rgba(255, 255, 255, 0.05)')
                  .borderRadius(8)

                  Column() {
                    Image($r('app.media.ic_prayer_sajdah'))
                      .width('16vp')
                      .height('16vp')
                      .fillColor(this.nextId === 'isha' ? '#E8A44C' : '#A5B8CC')
                      .margin({ bottom: 4 })
                    Text(this.ishaName)
                      .fontSize('10vp')
                      .fontColor(this.nextId === 'isha' ? '#E8A44C' : '#A5B8CC')
                      .fontWeight(this.nextId === 'isha' ? FontWeight.Bold : FontWeight.Normal)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(this.ishaTime)
                      .fontSize('10vp')
                      .fontColor(this.nextId === 'isha' ? '#E8A44C' : '#FFFFFF')
                      .fontWeight(this.nextId === 'isha' ? FontWeight.Bold : FontWeight.Medium)
                      .maxLines(1)
                      .margin({ top: 2 })
                  }
                  .layoutWeight(1)
                  .height('100%')
                  .justifyContent(FlexAlign.Center)
                  .backgroundColor(this.nextId === 'isha' ? 'rgba(232, 164, 76, 0.15)' : 'rgba(255, 255, 255, 0.05)')
                  .borderRadius(8)
                }
              }
              .width('100%').layoutWeight(1).direction(Direction.Ltr)

              // Progress Bar
              Row() {
                Row()
                  .width(`${this.progressPercent}%`)
                  .height('100%')
                  .backgroundColor('#E8A44C')
                  .borderRadius(2)
                  .animation({ duration: 1000, curve: Curve.EaseInOut })
              }
              .width('100%')
              .height(4)
              .backgroundColor('#333333')
              .borderRadius(2)
              .margin({ top: 8 })
              .direction(Direction.Ltr)
              .justifyContent(this.isRtl() ? FlexAlign.End : FlexAlign.Start)
            }
            .width('100%').layoutWeight(1).justifyContent(FlexAlign.SpaceBetween)

          } else if (this.dimension === '4*4') {
            Column() {
              // 1. Top Row
              Row() {
                if (this.isRtl()) {
                  Column() {
                    Text(this.nextName)
                      .fontSize('18vp')
                      .fontColor('#E8A44C')
                      .fontWeight(FontWeight.Bold)
                      .textAlign(TextAlign.LEFT)
                      .maxLines(1)
                    Text(this.nextTime)
                      .fontSize('14vp')
                      .fontColor('#E8A44C')
                      .margin({ top: 2 })
                      .textAlign(TextAlign.LEFT)
                      .maxLines(1)
                    Text(this.countdown)
                      .fontSize('11vp')
                      .fontColor('#FFFFFF')
                      .opacity(0.7)
                      .margin({ top: 2 })
                      .textAlign(TextAlign.LEFT)
                      .maxLines(1)
                  }.layoutWeight(1).alignItems(HorizontalAlign.Start).direction(Direction.Ltr)
                  Divider().vertical(true).height(40).color('#333333').margin({ left: 12, right: 12 })
                  Column() {
                    Text(this.currentName + (this.isCurrentYesterday ? ` (${this.lblYesterday})` : ''))
                      .fontSize('16vp')
                      .fontColor('#FFFFFF')
                      .fontWeight(FontWeight.Bold)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(this.currentTime).fontSize('12vp').fontColor('#A5B8CC').margin({ top: 2 }).maxLines(1)
                  }.layoutWeight(1).alignItems(HorizontalAlign.End).direction(Direction.Ltr)
                } else {
                  Column() {
                    Text(this.currentName + (this.isCurrentYesterday ? ` (${this.lblYesterday})` : ''))
                      .fontSize('16vp')
                      .fontColor('#FFFFFF')
                      .fontWeight(FontWeight.Bold)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(this.currentTime).fontSize('12vp').fontColor('#A5B8CC').margin({ top: 2 }).maxLines(1)
                  }.layoutWeight(1).alignItems(HorizontalAlign.Start).direction(Direction.Ltr)
                  Divider().vertical(true).height(40).color('#333333').margin({ left: 12, right: 12 })
                  Column() {
                    Text(this.nextName).fontSize('18vp').fontColor('#E8A44C').fontWeight(FontWeight.Bold).maxLines(1)
                    Text(this.nextTime).fontSize('14vp').fontColor('#E8A44C').margin({ top: 2 }).maxLines(1)
                    Text(this.countdown)
                      .fontSize('11vp')
                      .fontColor('#FFFFFF')
                      .opacity(0.7)
                      .margin({ top: 2 })
                      .maxLines(1)
                  }.layoutWeight(1).alignItems(HorizontalAlign.End).direction(Direction.Ltr)
                }
              }.width('100%').margin({ bottom: 12 }).alignItems(VerticalAlign.Center).direction(Direction.Ltr)

              Divider().color('#333333').margin({ bottom: 12 })

              // 2. Contextual Row
              Row() {
                if (this.isRtl()) {
                  Column() {
                    Text(this.contextLabel1)
                      .fontSize('10vp')
                      .fontColor('#A5B8CC')
                      .width('100%')
                      .textAlign(TextAlign.LEFT)
                      .maxLines(1)
                    Text(this.contextTime1)
                      .fontSize('14vp')
                      .fontColor('#FFFFFF')
                      .fontWeight(FontWeight.Bold)
                      .margin({ top: 2 })
                      .width('100%')
                      .textAlign(TextAlign.LEFT)
                      .direction(Direction.Ltr)
                      .maxLines(1)
                  }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                  Column() {
                    Text(this.contextLabel2)
                      .fontSize('10vp')
                      .fontColor('#A5B8CC')
                      .width('100%')
                      .textAlign(TextAlign.RIGHT)
                      .maxLines(1)
                    Text(this.contextTime2)
                      .fontSize('14vp')
                      .fontColor('#FFFFFF')
                      .fontWeight(FontWeight.Bold)
                      .margin({ top: 2 })
                      .width('100%')
                      .textAlign(TextAlign.RIGHT)
                      .direction(Direction.Ltr)
                      .maxLines(1)
                  }.layoutWeight(1).alignItems(HorizontalAlign.End)
                } else {
                  Column() {
                    Text(this.contextLabel1)
                      .fontSize('10vp')
                      .fontColor('#A5B8CC')
                      .width('100%')
                      .textAlign(TextAlign.LEFT)
                      .maxLines(1)
                    Text(this.contextTime1)
                      .fontSize('14vp')
                      .fontColor('#FFFFFF')
                      .fontWeight(FontWeight.Bold)
                      .margin({ top: 2 })
                      .width('100%')
                      .textAlign(TextAlign.LEFT)
                      .direction(Direction.Ltr)
                      .maxLines(1)
                  }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                  Column() {
                    Text(this.contextLabel2)
                      .fontSize('10vp')
                      .fontColor('#A5B8CC')
                      .width('100%')
                      .textAlign(TextAlign.RIGHT)
                      .maxLines(1)
                    Text(this.contextTime2)
                      .fontSize('14vp')
                      .fontColor('#FFFFFF')
                      .fontWeight(FontWeight.Bold)
                      .margin({ top: 2 })
                      .width('100%')
                      .textAlign(TextAlign.RIGHT)
                      .direction(Direction.Ltr)
                      .maxLines(1)
                  }.layoutWeight(1).alignItems(HorizontalAlign.End)
                }
              }.width('100%').margin({ bottom: 16 }).direction(Direction.Ltr)

              Divider().color('#333333').margin({ bottom: 12 })

              // 3. Prayer Timings (Compact, using Column space, no clipping)
              Column({ space: 4 }) {
                if (this.isRtl()) {
                  Row() {
                    Text(this.ishaTime)
                      .width('50%')
                      .textAlign(TextAlign.LEFT)
                      .fontSize('14vp')
                      .fontColor(this.nextId === 'isha' ? '#E8A44C' : '#FFFFFF')
                      .fontWeight(this.nextId === 'isha' ? FontWeight.Bold : FontWeight.Medium)
                      .maxLines(1);
                    Text(this.ishaName)
                      .width('50%')
                      .textAlign(TextAlign.RIGHT)
                      .fontSize('14vp')
                      .fontColor(this.nextId === 'isha' ? '#E8A44C' : '#A5B8CC')
                      .fontWeight(this.nextId === 'isha' ? FontWeight.Bold : FontWeight.Normal)
                      .maxLines(1)
                  }
                  .width('100%')
                  .height(28)
                  .padding({ left: 12, right: 12 })
                  .backgroundColor('rgba(255, 255, 255, 0.05)')
                  .borderRadius(8)
                  .direction(Direction.Ltr)

                  Row() {
                    Text(this.maghribTime)
                      .width('50%')
                      .textAlign(TextAlign.LEFT)
                      .fontSize('14vp')
                      .fontColor(this.nextId === 'maghrib' ? '#E8A44C' : '#FFFFFF')
                      .fontWeight(this.nextId === 'maghrib' ? FontWeight.Bold : FontWeight.Medium)
                      .maxLines(1);
                    Text(this.maghribName)
                      .width('50%')
                      .textAlign(TextAlign.RIGHT)
                      .fontSize('14vp')
                      .fontColor(this.nextId === 'maghrib' ? '#E8A44C' : '#A5B8CC')
                      .fontWeight(this.nextId === 'maghrib' ? FontWeight.Bold : FontWeight.Normal)
                      .maxLines(1)
                  }
                  .width('100%')
                  .height(28)
                  .padding({ left: 12, right: 12 })
                  .backgroundColor('rgba(255, 255, 255, 0.05)')
                  .borderRadius(8)
                  .direction(Direction.Ltr)

                  Row() {
                    Text(this.asrTime)
                      .width('50%')
                      .textAlign(TextAlign.LEFT)
                      .fontSize('14vp')
                      .fontColor(this.nextId === 'asr' ? '#E8A44C' : '#FFFFFF')
                      .fontWeight(this.nextId === 'asr' ? FontWeight.Bold : FontWeight.Medium)
                      .maxLines(1);
                    Text(this.asrName)
                      .width('50%')
                      .textAlign(TextAlign.RIGHT)
                      .fontSize('14vp')
                      .fontColor(this.nextId === 'asr' ? '#E8A44C' : '#A5B8CC')
                      .fontWeight(this.nextId === 'asr' ? FontWeight.Bold : FontWeight.Normal)
                      .maxLines(1)
                  }
                  .width('100%')
                  .height(28)
                  .padding({ left: 12, right: 12 })
                  .backgroundColor('rgba(255, 255, 255, 0.05)')
                  .borderRadius(8)
                  .direction(Direction.Ltr)

                  Row() {
                    Text(this.dhuhrTime)
                      .width('50%')
                      .textAlign(TextAlign.LEFT)
                      .fontSize('14vp')
                      .fontColor(this.nextId === 'dhuhr' ? '#E8A44C' : '#FFFFFF')
                      .fontWeight(this.nextId === 'dhuhr' ? FontWeight.Bold : FontWeight.Medium)
                      .maxLines(1);
                    Text(this.dhuhrName)
                      .width('50%')
                      .textAlign(TextAlign.RIGHT)
                      .fontSize('14vp')
                      .fontColor(this.nextId === 'dhuhr' ? '#E8A44C' : '#A5B8CC')
                      .fontWeight(this.nextId === 'dhuhr' ? FontWeight.Bold : FontWeight.Normal)
                      .maxLines(1)
                  }
                  .width('100%')
                  .height(28)
                  .padding({ left: 12, right: 12 })
                  .backgroundColor('rgba(255, 255, 255, 0.05)')
                  .borderRadius(8)
                  .direction(Direction.Ltr)

                  Row() {
                    Text(this.fajrTime)
                      .width('50%')
                      .textAlign(TextAlign.LEFT)
                      .fontSize('14vp')
                      .fontColor(this.nextId === 'fajr' ? '#E8A44C' : '#FFFFFF')
                      .fontWeight(this.nextId === 'fajr' ? FontWeight.Bold : FontWeight.Medium)
                      .maxLines(1);
                    Text(this.fajrName)
                      .width('50%')
                      .textAlign(TextAlign.RIGHT)
                      .fontSize('14vp')
                      .fontColor(this.nextId === 'fajr' ? '#E8A44C' : '#A5B8CC')
                      .fontWeight(this.nextId === 'fajr' ? FontWeight.Bold : FontWeight.Normal)
                      .maxLines(1)
                  }
                  .width('100%')
                  .height(28)
                  .padding({ left: 12, right: 12 })
                  .backgroundColor('rgba(255, 255, 255, 0.05)')
                  .borderRadius(8)
                  .direction(Direction.Ltr)
                } else {
                  Row() {
                    Text(this.fajrName)
                      .width('50%')
                      .textAlign(TextAlign.LEFT)
                      .fontSize('14vp')
                      .fontColor(this.nextId === 'fajr' ? '#E8A44C' : '#A5B8CC')
                      .fontWeight(this.nextId === 'fajr' ? FontWeight.Bold : FontWeight.Normal)
                      .maxLines(1);
                    Text(this.fajrTime)
                      .width('50%')
                      .textAlign(TextAlign.RIGHT)
                      .fontSize('14vp')
                      .fontColor(this.nextId === 'fajr' ? '#E8A44C' : '#FFFFFF')
                      .fontWeight(this.nextId === 'fajr' ? FontWeight.Bold : FontWeight.Medium)
                      .maxLines(1)
                  }
                  .width('100%')
                  .height(28)
                  .padding({ left: 12, right: 12 })
                  .backgroundColor('rgba(255, 255, 255, 0.05)')
                  .borderRadius(8)
                  .direction(Direction.Ltr)

                  Row() {
                    Text(this.dhuhrName)
                      .width('50%')
                      .textAlign(TextAlign.LEFT)
                      .fontSize('14vp')
                      .fontColor(this.nextId === 'dhuhr' ? '#E8A44C' : '#A5B8CC')
                      .fontWeight(this.nextId === 'dhuhr' ? FontWeight.Bold : FontWeight.Normal)
                      .maxLines(1);
                    Text(this.dhuhrTime)
                      .width('50%')
                      .textAlign(TextAlign.RIGHT)
                      .fontSize('14vp')
                      .fontColor(this.nextId === 'dhuhr' ? '#E8A44C' : '#FFFFFF')
                      .fontWeight(this.nextId === 'dhuhr' ? FontWeight.Bold : FontWeight.Medium)
                      .maxLines(1)
                  }
                  .width('100%')
                  .height(28)
                  .padding({ left: 12, right: 12 })
                  .backgroundColor('rgba(255, 255, 255, 0.05)')
                  .borderRadius(8)
                  .direction(Direction.Ltr)

                  Row() {
                    Text(this.asrName)
                      .width('50%')
                      .textAlign(TextAlign.LEFT)
                      .fontSize('14vp')
                      .fontColor(this.nextId === 'asr' ? '#E8A44C' : '#A5B8CC')
                      .fontWeight(this.nextId === 'asr' ? FontWeight.Bold : FontWeight.Normal)
                      .maxLines(1);
                    Text(this.asrTime)
                      .width('50%')
                      .textAlign(TextAlign.RIGHT)
                      .fontSize('14vp')
                      .fontColor(this.nextId === 'asr' ? '#E8A44C' : '#FFFFFF')
                      .fontWeight(this.nextId === 'asr' ? FontWeight.Bold : FontWeight.Medium)
                      .maxLines(1)
                  }
                  .width('100%')
                  .height(28)
                  .padding({ left: 12, right: 12 })
                  .backgroundColor('rgba(255, 255, 255, 0.05)')
                  .borderRadius(8)
                  .direction(Direction.Ltr)

                  Row() {
                    Text(this.maghribName)
                      .width('50%')
                      .textAlign(TextAlign.LEFT)
                      .fontSize('14vp')
                      .fontColor(this.nextId === 'maghrib' ? '#E8A44C' : '#A5B8CC')
                      .fontWeight(this.nextId === 'maghrib' ? FontWeight.Bold : FontWeight.Normal)
                      .maxLines(1);
                    Text(this.maghribTime)
                      .width('50%')
                      .textAlign(TextAlign.RIGHT)
                      .fontSize('14vp')
                      .fontColor(this.nextId === 'maghrib' ? '#E8A44C' : '#FFFFFF')
                      .fontWeight(this.nextId === 'maghrib' ? FontWeight.Bold : FontWeight.Medium)
                      .maxLines(1)
                  }
                  .width('100%')
                  .height(28)
                  .padding({ left: 12, right: 12 })
                  .backgroundColor('rgba(255, 255, 255, 0.05)')
                  .borderRadius(8)
                  .direction(Direction.Ltr)

                  Row() {
                    Text(this.ishaName)
                      .width('50%')
                      .textAlign(TextAlign.LEFT)
                      .fontSize('14vp')
                      .fontColor(this.nextId === 'isha' ? '#E8A44C' : '#A5B8CC')
                      .fontWeight(this.nextId === 'isha' ? FontWeight.Bold : FontWeight.Normal)
                      .maxLines(1);
                    Text(this.ishaTime)
                      .width('50%')
                      .textAlign(TextAlign.RIGHT)
                      .fontSize('14vp')
                      .fontColor(this.nextId === 'isha' ? '#E8A44C' : '#FFFFFF')
                      .fontWeight(this.nextId === 'isha' ? FontWeight.Bold : FontWeight.Medium)
                      .maxLines(1)
                  }
                  .width('100%')
                  .height(28)
                  .padding({ left: 12, right: 12 })
                  .backgroundColor('rgba(255, 255, 255, 0.05)')
                  .borderRadius(8)
                  .direction(Direction.Ltr)
                }
              }
              .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
            }
            .width('100%').layoutWeight(1)
          }
        }
      }
      .width('100%')
      .height('100%')
      .padding(14)
      .backgroundColor('#141B2E')
      .borderRadius(16)
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          bundleName: 'com.siratcompanion.hos.app',
          abilityName: 'EntryAbility',
          params: { targetPage: 'pages/MainTabs', targetTab: 'prayers' }
        });
      })
    }
    .width('100%').height('100%').direction(Direction.Ltr)
  }

  private isRtl(): boolean {
    return this.lang === 'ar' || this.lang === 'ur';
  }
}