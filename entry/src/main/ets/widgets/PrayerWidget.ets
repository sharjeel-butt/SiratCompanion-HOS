@Entry
@Component
struct PrayerWidget {
  @LocalStorageProp('dimension') dimension: string = '2*2';
  @LocalStorageProp('city') city: string = '—';
  @LocalStorageProp('hijriDate') hijriDate: string = '—';
  @LocalStorageProp('nextId') nextId: string = '—';
  @LocalStorageProp('nextName') nextName: string = '—';
  @LocalStorageProp('nextTime') nextTime: string = '--:--';
  @LocalStorageProp('currentName') currentName: string = '—';
  @LocalStorageProp('currentTime') currentTime: string = '--:--';
  @LocalStorageProp('methodLabel') methodLabel: string = '—';
  @LocalStorageProp('asrLabel') asrLabel: string = '—';
  @LocalStorageProp('highLatLabel') highLatLabel: string = '—';
  @LocalStorageProp('roundingLabel') roundingLabel: string = '—';
  @LocalStorageProp('midnightLabel') midnightLabel: string = '—';
  @LocalStorageProp('polarLabel') polarLabel: string = '—';
  @LocalStorageProp('shafaqLabel') shafaqLabel: string = '—';
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
  @LocalStorageProp('lblCurrent') lblCurrent: string = 'CURRENT PRAYER';
  @LocalStorageProp('lblNext') lblNext: string = 'NEXT PRAYER';
  @LocalStorageProp('lblMethod') lblMethod: string = 'Method';
  @LocalStorageProp('lblMadhab') lblMadhab: string = 'Madhab';
  @LocalStorageProp('lblHighLat') lblHighLat: string = 'High Lat';
  @LocalStorageProp('lblRounding') lblRounding: string = 'Rounding';
  @LocalStorageProp('lblMidnight') lblMidnight: string = 'Midnight';
  @LocalStorageProp('lblPolar') lblPolar: string = 'Polar';
  @LocalStorageProp('lblShafaq') lblShafaq: string = 'Shafaq';
  @LocalStorageProp('error') error: string = '';

  private isRtl(): boolean {
    return this.lang === 'ar' || this.lang === 'ur';
  }

  build() {
    Stack() {
      Column() {
        if (this.error.length > 0) {
          Column() {
            Text(this.error).fontSize(14).fontColor('#FF6B6B').textAlign(TextAlign.Center).width('100%')
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
        } else {

          // ========== HEADER ==========
          if (this.dimension === '2*2') {
            Column() {
              Row() {
                Text(this.hijriDate).fontSize(10).fontColor('#E8A44C').maxLines(1)
              }.width('100%').justifyContent(FlexAlign.Start)

              Row() {
                Text(this.city)
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }.width('100%').justifyContent(FlexAlign.Start).margin({ top: 2 })
            }
            .width('100%').margin({ bottom: 8 })
          } else {
            Row() {
              Row() {
                Text(this.city)
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }.layoutWeight(1).justifyContent(FlexAlign.Start)

              Text(this.hijriDate).fontSize(10).fontColor('#E8A44C').maxLines(1)
            }
            .width('100%').margin({ bottom: 12 })
          }

          // ========== BODY ==========
          if (this.dimension === '2*2') {
            Column() {
              Text(this.lblNext)
                .fontSize(9)
                .fontColor('#AAAAAA')
                .width('100%')
                .textAlign(TextAlign.Start)
                .letterSpacing(1)
              Text(this.nextName)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#E8A44C')
                .width('100%')
                .textAlign(TextAlign.Start)
                .margin({ top: 2 })
                .maxLines(1)
              Text(this.nextTime)
                .fontSize(16)
                .fontColor('#FFFFFF')
                .width('100%')
                .textAlign(TextAlign.Start)
                .margin({ top: 4 })
            }
            .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)

          } else if (this.dimension === '2*4') {
            Row() {
              // Fajr
              Column() {
                Image($r('app.media.ic_prayer_sajdah'))
                  .width(16)
                  .height(16)
                  .fillColor(this.nextId === 'fajr' ? '#E8A44C' : '#A5B8CC')
                  .margin({ bottom: 6 })
                Text(this.fajrName)
                  .fontSize(12)
                  .fontColor(this.nextId === 'fajr' ? '#E8A44C' : '#A5B8CC')
                  .fontWeight(this.nextId === 'fajr' ? FontWeight.Bold : FontWeight.Normal)
                  .maxLines(1)
                Text(this.fajrTime)
                  .fontSize(12)
                  .fontColor(this.nextId === 'fajr' ? '#E8A44C' : '#FFFFFF')
                  .fontWeight(this.nextId === 'fajr' ? FontWeight.Bold : FontWeight.Medium)
                  .maxLines(1)
                  .margin({ top: 4 })
              }.layoutWeight(1).alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)

              // Dhuhr
              Column() {
                Image($r('app.media.ic_prayer_sajdah'))
                  .width(16)
                  .height(16)
                  .fillColor(this.nextId === 'dhuhr' ? '#E8A44C' : '#A5B8CC')
                  .margin({ bottom: 6 })
                Text(this.dhuhrName)
                  .fontSize(12)
                  .fontColor(this.nextId === 'dhuhr' ? '#E8A44C' : '#A5B8CC')
                  .fontWeight(this.nextId === 'dhuhr' ? FontWeight.Bold : FontWeight.Normal)
                  .maxLines(1)
                Text(this.dhuhrTime)
                  .fontSize(12)
                  .fontColor(this.nextId === 'dhuhr' ? '#E8A44C' : '#FFFFFF')
                  .fontWeight(this.nextId === 'dhuhr' ? FontWeight.Bold : FontWeight.Medium)
                  .maxLines(1)
                  .margin({ top: 4 })
              }.layoutWeight(1).alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)

              // Asr
              Column() {
                Image($r('app.media.ic_prayer_sajdah'))
                  .width(16)
                  .height(16)
                  .fillColor(this.nextId === 'asr' ? '#E8A44C' : '#A5B8CC')
                  .margin({ bottom: 6 })
                Text(this.asrName)
                  .fontSize(12)
                  .fontColor(this.nextId === 'asr' ? '#E8A44C' : '#A5B8CC')
                  .fontWeight(this.nextId === 'asr' ? FontWeight.Bold : FontWeight.Normal)
                  .maxLines(1)
                Text(this.asrTime)
                  .fontSize(12)
                  .fontColor(this.nextId === 'asr' ? '#E8A44C' : '#FFFFFF')
                  .fontWeight(this.nextId === 'asr' ? FontWeight.Bold : FontWeight.Medium)
                  .maxLines(1)
                  .margin({ top: 4 })
              }.layoutWeight(1).alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)

              // Maghrib
              Column() {
                Image($r('app.media.ic_prayer_sajdah'))
                  .width(16)
                  .height(16)
                  .fillColor(this.nextId === 'maghrib' ? '#E8A44C' : '#A5B8CC')
                  .margin({ bottom: 6 })
                Text(this.maghribName)
                  .fontSize(12)
                  .fontColor(this.nextId === 'maghrib' ? '#E8A44C' : '#A5B8CC')
                  .fontWeight(this.nextId === 'maghrib' ? FontWeight.Bold : FontWeight.Normal)
                  .maxLines(1)
                Text(this.maghribTime)
                  .fontSize(12)
                  .fontColor(this.nextId === 'maghrib' ? '#E8A44C' : '#FFFFFF')
                  .fontWeight(this.nextId === 'maghrib' ? FontWeight.Bold : FontWeight.Medium)
                  .maxLines(1)
                  .margin({ top: 4 })
              }.layoutWeight(1).alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)

              // Isha
              Column() {
                Image($r('app.media.ic_prayer_sajdah'))
                  .width(16)
                  .height(16)
                  .fillColor(this.nextId === 'isha' ? '#E8A44C' : '#A5B8CC')
                  .margin({ bottom: 6 })
                Text(this.ishaName)
                  .fontSize(12)
                  .fontColor(this.nextId === 'isha' ? '#E8A44C' : '#A5B8CC')
                  .fontWeight(this.nextId === 'isha' ? FontWeight.Bold : FontWeight.Normal)
                  .maxLines(1)
                Text(this.ishaTime)
                  .fontSize(12)
                  .fontColor(this.nextId === 'isha' ? '#E8A44C' : '#FFFFFF')
                  .fontWeight(this.nextId === 'isha' ? FontWeight.Bold : FontWeight.Medium)
                  .maxLines(1)
                  .margin({ top: 4 })
              }.layoutWeight(1).alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
            }
            .width('100%').layoutWeight(1).alignItems(VerticalAlign.Center).justifyContent(FlexAlign.SpaceBetween)

          } else if (this.dimension === '4*4') {
            Column() {
              // 1. Top Row: Current & Next
              Row() {
                Column() {
                  Text(this.lblCurrent).fontSize(9).fontColor('#AAAAAA').letterSpacing(1)
                  Text(this.currentName)
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FFFFFF')
                    .margin({ top: 2 })
                  Text(this.currentTime).fontSize(14).fontColor('#A5B8CC').margin({ top: 2 })
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)

                Divider().vertical(true).height(44).color('#333333').margin({ left: 12, right: 12 })

                Column() {
                  Text(this.lblNext).fontSize(9).fontColor('#AAAAAA').letterSpacing(1)
                  Text(this.nextName).fontSize(22).fontWeight(FontWeight.Bold).fontColor('#E8A44C').margin({ top: 2 })
                  Text(this.nextTime).fontSize(14).fontColor('#E8A44C').margin({ top: 2 })
                }.layoutWeight(1).alignItems(HorizontalAlign.End)
              }
              .width('100%').margin({ bottom: 12 }).alignItems(VerticalAlign.Center)

              Divider().color('#333333').margin({ bottom: 12 })

              // 2. Settings Grid (Exact SettingsRow pattern)
              Row({ space: 16 }) {
                Column() {
                  Row() {
                    Text(this.lblMethod).fontSize(9).fontColor('#A5B8CC').layoutWeight(1).textAlign(TextAlign.Start)
                    Text(this.methodLabel).fontSize(9).fontColor('#FFFFFF').maxLines(1).textAlign(TextAlign.End)
                  }.width('100%').margin({ bottom: 4 })

                  Row() {
                    Text(this.lblMadhab).fontSize(9).fontColor('#A5B8CC').layoutWeight(1).textAlign(TextAlign.Start)
                    Text(this.asrLabel).fontSize(9).fontColor('#FFFFFF').textAlign(TextAlign.End)
                  }.width('100%').margin({ bottom: 4 })

                  Row() {
                    Text(this.lblHighLat).fontSize(9).fontColor('#A5B8CC').layoutWeight(1).textAlign(TextAlign.Start)
                    Text(this.highLatLabel).fontSize(9).fontColor('#FFFFFF').maxLines(1).textAlign(TextAlign.End)
                  }.width('100%').margin({ bottom: 4 })

                  Row() {
                    Text(this.lblRounding).fontSize(9).fontColor('#A5B8CC').layoutWeight(1).textAlign(TextAlign.Start)
                    Text(this.roundingLabel).fontSize(9).fontColor('#FFFFFF').textAlign(TextAlign.End)
                  }.width('100%')
                }.layoutWeight(1)

                Column() {
                  Row() {
                    Text(this.lblMidnight).fontSize(9).fontColor('#A5B8CC').layoutWeight(1).textAlign(TextAlign.Start)
                    Text(this.midnightLabel).fontSize(9).fontColor('#FFFFFF').textAlign(TextAlign.End)
                  }.width('100%').margin({ bottom: 4 })

                  Row() {
                    Text(this.lblPolar).fontSize(9).fontColor('#A5B8CC').layoutWeight(1).textAlign(TextAlign.Start)
                    Text(this.polarLabel).fontSize(9).fontColor('#FFFFFF').maxLines(1).textAlign(TextAlign.End)
                  }.width('100%').margin({ bottom: 4 })

                  Row() {
                    Text(this.lblShafaq).fontSize(9).fontColor('#A5B8CC').layoutWeight(1).textAlign(TextAlign.Start)
                    Text(this.shafaqLabel).fontSize(9).fontColor('#FFFFFF').maxLines(1).textAlign(TextAlign.End)
                  }.width('100%')
                }.layoutWeight(1)
              }
              .width('100%').margin({ bottom: 12 })

              Divider().color('#333333').margin({ bottom: 12 })

              // 3. Prayer Timings
              Column() {
                Row() {
                  Text(this.fajrName)
                    .width('50%')
                    .textAlign(TextAlign.Start)
                    .fontSize(11)
                    .fontColor(this.nextId === 'fajr' ? '#E8A44C' : '#A5B8CC')
                    .fontWeight(this.nextId === 'fajr' ? FontWeight.Bold : FontWeight.Normal)
                  Text(this.fajrTime)
                    .width('50%')
                    .textAlign(TextAlign.End)
                    .fontSize(11)
                    .fontColor(this.nextId === 'fajr' ? '#E8A44C' : '#FFFFFF')
                    .fontWeight(this.nextId === 'fajr' ? FontWeight.Bold : FontWeight.Medium)
                }.width('80%').margin({ bottom: 6 })

                Row() {
                  Text(this.dhuhrName)
                    .width('50%')
                    .textAlign(TextAlign.Start)
                    .fontSize(11)
                    .fontColor(this.nextId === 'dhuhr' ? '#E8A44C' : '#A5B8CC')
                    .fontWeight(this.nextId === 'dhuhr' ? FontWeight.Bold : FontWeight.Normal)
                  Text(this.dhuhrTime)
                    .width('50%')
                    .textAlign(TextAlign.End)
                    .fontSize(11)
                    .fontColor(this.nextId === 'dhuhr' ? '#E8A44C' : '#FFFFFF')
                    .fontWeight(this.nextId === 'dhuhr' ? FontWeight.Bold : FontWeight.Medium)
                }.width('80%').margin({ bottom: 6 })

                Row() {
                  Text(this.asrName)
                    .width('50%')
                    .textAlign(TextAlign.Start)
                    .fontSize(11)
                    .fontColor(this.nextId === 'asr' ? '#E8A44C' : '#A5B8CC')
                    .fontWeight(this.nextId === 'asr' ? FontWeight.Bold : FontWeight.Normal)
                  Text(this.asrTime)
                    .width('50%')
                    .textAlign(TextAlign.End)
                    .fontSize(11)
                    .fontColor(this.nextId === 'asr' ? '#E8A44C' : '#FFFFFF')
                    .fontWeight(this.nextId === 'asr' ? FontWeight.Bold : FontWeight.Medium)
                }.width('80%').margin({ bottom: 6 })

                Row() {
                  Text(this.maghribName)
                    .width('50%')
                    .textAlign(TextAlign.Start)
                    .fontSize(11)
                    .fontColor(this.nextId === 'maghrib' ? '#E8A44C' : '#A5B8CC')
                    .fontWeight(this.nextId === 'maghrib' ? FontWeight.Bold : FontWeight.Normal)
                  Text(this.maghribTime)
                    .width('50%')
                    .textAlign(TextAlign.End)
                    .fontSize(11)
                    .fontColor(this.nextId === 'maghrib' ? '#E8A44C' : '#FFFFFF')
                    .fontWeight(this.nextId === 'maghrib' ? FontWeight.Bold : FontWeight.Medium)
                }.width('80%').margin({ bottom: 6 })

                Row() {
                  Text(this.ishaName)
                    .width('50%')
                    .textAlign(TextAlign.Start)
                    .fontSize(11)
                    .fontColor(this.nextId === 'isha' ? '#E8A44C' : '#A5B8CC')
                    .fontWeight(this.nextId === 'isha' ? FontWeight.Bold : FontWeight.Normal)
                  Text(this.ishaTime)
                    .width('50%')
                    .textAlign(TextAlign.End)
                    .fontSize(11)
                    .fontColor(this.nextId === 'isha' ? '#E8A44C' : '#FFFFFF')
                    .fontWeight(this.nextId === 'isha' ? FontWeight.Bold : FontWeight.Medium)
                }.width('80%')
              }
              .width('100%').layoutWeight(1).justifyContent(FlexAlign.SpaceEvenly).alignItems(HorizontalAlign.Center)
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
      .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          abilityName: 'EntryAbility',
          params: { targetPage: 'pages/MainTabs', targetTab: 'prayers' }
        });
      })
    }
    .width('100%').height('100%')
  }
}