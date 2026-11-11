@Entry
@Component
struct TrackerWidget {
  @LocalStorageProp('dimension') dimension: string = '4*4';
  @LocalStorageProp('isRtl') isRtl: boolean = false;
  @LocalStorageProp('error') error: string = '';
  @LocalStorageProp('lblTitle') lblTitle: string = "Daily Faith";
  @LocalStorageProp('fajrName') p1Name: string = 'Fajr';
  @LocalStorageProp('fajrTime24') p1Time: string = '--:--';
  @LocalStorageProp('p1Checked') p1Checked: boolean = false;
  @LocalStorageProp('dhuhrName') p2Name: string = 'Dhuhr';
  @LocalStorageProp('dhuhrTime24') p2Time: string = '--:--';
  @LocalStorageProp('p2Checked') p2Checked: boolean = false;
  @LocalStorageProp('asrName') p3Name: string = 'Asr';
  @LocalStorageProp('asrTime24') p3Time: string = '--:--';
  @LocalStorageProp('p3Checked') p3Checked: boolean = false;
  @LocalStorageProp('maghribName') p4Name: string = 'Maghrib';
  @LocalStorageProp('maghribTime24') p4Time: string = '--:--';
  @LocalStorageProp('p4Checked') p4Checked: boolean = false;
  @LocalStorageProp('ishaName') p5Name: string = 'Isha';
  @LocalStorageProp('ishaTime24') p5Time: string = '--:--';
  @LocalStorageProp('p5Checked') p5Checked: boolean = false;

  @LocalStorageProp('taskQuran') taskQuran: string = 'Quran';
  @LocalStorageProp('taskDua') taskDua: string = 'Duas';
  @LocalStorageProp('taskRecitations') taskRecitations: string = 'Recitations';
  @LocalStorageProp('taskTasbih') taskTasbih: string = 'Tasbih';

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({ angle: 145, colors: [['#1A2235', 0], ['#0F1522', 1]] })
        .borderRadius(24)
        .border({ width: 1, color: 'rgba(255, 255, 255, 0.15)' })

      Column() {
        if (this.error.length > 0) {
          Text(this.error)
            .fontSize('12vp')
            .fontColor('#FF6B6B')
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        } else {

          // Header Row - FIXED RTL SWAP
          Row() {
            if (this.isRtl) {
              Image($r('app.media.ic_nav_mosque')).width('18vp').height('18vp').fillColor('#E8A44C')
              Blank()
              Text(this.lblTitle)
                .fontSize('15vp')
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .textAlign(TextAlign.RIGHT)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            } else {
              Text(this.lblTitle)
                .fontSize('15vp')
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .textAlign(TextAlign.LEFT)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Blank()
              Image($r('app.media.ic_nav_mosque')).width('18vp').height('18vp').fillColor('#E8A44C')
            }
          }.width('100%').margin({ bottom: 10 }).direction(Direction.Ltr)

          // Prayer Grid
          Row({ space: 6 }) {
            if (this.isRtl) {
              Column() {
                Image(this.p5Checked ? $r('app.media.ic_check') : $r('app.media.ic_prayer_sajdah'))
                  .width('24vp')
                  .height('24vp')
                  .fillColor(this.p5Checked ? '#E8A44C' : '#A5B8CC')
                  .margin({ bottom: 4 })
                Text(this.p5Name)
                  .fontSize('12vp')
                  .fontWeight(this.p5Checked ? FontWeight.Bold : FontWeight.Medium)
                  .fontColor(this.p5Checked ? '#E8A44C' : '#FFFFFF')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.p5Time)
                  .fontSize('10vp')
                  .fontColor('#A5B8CC')
                  .margin({ top: 2 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .layoutWeight(1)
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .backgroundColor(this.p5Checked ? 'rgba(232, 164, 76, 0.15)' : 'rgba(255, 255, 255, 0.05)')
              .borderRadius(10)

              Column() {
                Image(this.p4Checked ? $r('app.media.ic_check') : $r('app.media.ic_prayer_sajdah'))
                  .width('24vp')
                  .height('24vp')
                  .fillColor(this.p4Checked ? '#E8A44C' : '#A5B8CC')
                  .margin({ bottom: 4 })
                Text(this.p4Name)
                  .fontSize('12vp')
                  .fontWeight(this.p4Checked ? FontWeight.Bold : FontWeight.Medium)
                  .fontColor(this.p4Checked ? '#E8A44C' : '#FFFFFF')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.p4Time)
                  .fontSize('10vp')
                  .fontColor('#A5B8CC')
                  .margin({ top: 2 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .layoutWeight(1)
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .backgroundColor(this.p4Checked ? 'rgba(232, 164, 76, 0.15)' : 'rgba(255, 255, 255, 0.05)')
              .borderRadius(10)

              Column() {
                Image(this.p3Checked ? $r('app.media.ic_check') : $r('app.media.ic_prayer_sajdah'))
                  .width('24vp')
                  .height('24vp')
                  .fillColor(this.p3Checked ? '#E8A44C' : '#A5B8CC')
                  .margin({ bottom: 4 })
                Text(this.p3Name)
                  .fontSize('12vp')
                  .fontWeight(this.p3Checked ? FontWeight.Bold : FontWeight.Medium)
                  .fontColor(this.p3Checked ? '#E8A44C' : '#FFFFFF')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.p3Time)
                  .fontSize('10vp')
                  .fontColor('#A5B8CC')
                  .margin({ top: 2 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .layoutWeight(1)
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .backgroundColor(this.p3Checked ? 'rgba(232, 164, 76, 0.15)' : 'rgba(255, 255, 255, 0.05)')
              .borderRadius(10)

              Column() {
                Image(this.p2Checked ? $r('app.media.ic_check') : $r('app.media.ic_prayer_sajdah'))
                  .width('24vp')
                  .height('24vp')
                  .fillColor(this.p2Checked ? '#E8A44C' : '#A5B8CC')
                  .margin({ bottom: 4 })
                Text(this.p2Name)
                  .fontSize('12vp')
                  .fontWeight(this.p2Checked ? FontWeight.Bold : FontWeight.Medium)
                  .fontColor(this.p2Checked ? '#E8A44C' : '#FFFFFF')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.p2Time)
                  .fontSize('10vp')
                  .fontColor('#A5B8CC')
                  .margin({ top: 2 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .layoutWeight(1)
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .backgroundColor(this.p2Checked ? 'rgba(232, 164, 76, 0.15)' : 'rgba(255, 255, 255, 0.05)')
              .borderRadius(10)

              Column() {
                Image(this.p1Checked ? $r('app.media.ic_check') : $r('app.media.ic_prayer_sajdah'))
                  .width('24vp')
                  .height('24vp')
                  .fillColor(this.p1Checked ? '#E8A44C' : '#A5B8CC')
                  .margin({ bottom: 4 })
                Text(this.p1Name)
                  .fontSize('12vp')
                  .fontWeight(this.p1Checked ? FontWeight.Bold : FontWeight.Medium)
                  .fontColor(this.p1Checked ? '#E8A44C' : '#FFFFFF')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.p1Time)
                  .fontSize('10vp')
                  .fontColor('#A5B8CC')
                  .margin({ top: 2 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .layoutWeight(1)
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .backgroundColor(this.p1Checked ? 'rgba(232, 164, 76, 0.15)' : 'rgba(255, 255, 255, 0.05)')
              .borderRadius(10)
            } else {
              Column() {
                Image(this.p1Checked ? $r('app.media.ic_check') : $r('app.media.ic_prayer_sajdah'))
                  .width('24vp')
                  .height('24vp')
                  .fillColor(this.p1Checked ? '#E8A44C' : '#A5B8CC')
                  .margin({ bottom: 4 })
                Text(this.p1Name)
                  .fontSize('12vp')
                  .fontWeight(this.p1Checked ? FontWeight.Bold : FontWeight.Medium)
                  .fontColor(this.p1Checked ? '#E8A44C' : '#FFFFFF')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.p1Time)
                  .fontSize('10vp')
                  .fontColor('#A5B8CC')
                  .margin({ top: 2 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .layoutWeight(1)
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .backgroundColor(this.p1Checked ? 'rgba(232, 164, 76, 0.15)' : 'rgba(255, 255, 255, 0.05)')
              .borderRadius(10)

              Column() {
                Image(this.p2Checked ? $r('app.media.ic_check') : $r('app.media.ic_prayer_sajdah'))
                  .width('24vp')
                  .height('24vp')
                  .fillColor(this.p2Checked ? '#E8A44C' : '#A5B8CC')
                  .margin({ bottom: 4 })
                Text(this.p2Name)
                  .fontSize('12vp')
                  .fontWeight(this.p2Checked ? FontWeight.Bold : FontWeight.Medium)
                  .fontColor(this.p2Checked ? '#E8A44C' : '#FFFFFF')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.p2Time)
                  .fontSize('10vp')
                  .fontColor('#A5B8CC')
                  .margin({ top: 2 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .layoutWeight(1)
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .backgroundColor(this.p2Checked ? 'rgba(232, 164, 76, 0.15)' : 'rgba(255, 255, 255, 0.05)')
              .borderRadius(10)

              Column() {
                Image(this.p3Checked ? $r('app.media.ic_check') : $r('app.media.ic_prayer_sajdah'))
                  .width('24vp')
                  .height('24vp')
                  .fillColor(this.p3Checked ? '#E8A44C' : '#A5B8CC')
                  .margin({ bottom: 4 })
                Text(this.p3Name)
                  .fontSize('12vp')
                  .fontWeight(this.p3Checked ? FontWeight.Bold : FontWeight.Medium)
                  .fontColor(this.p3Checked ? '#E8A44C' : '#FFFFFF')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.p3Time)
                  .fontSize('10vp')
                  .fontColor('#A5B8CC')
                  .margin({ top: 2 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .layoutWeight(1)
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .backgroundColor(this.p3Checked ? 'rgba(232, 164, 76, 0.15)' : 'rgba(255, 255, 255, 0.05)')
              .borderRadius(10)

              Column() {
                Image(this.p4Checked ? $r('app.media.ic_check') : $r('app.media.ic_prayer_sajdah'))
                  .width('24vp')
                  .height('24vp')
                  .fillColor(this.p4Checked ? '#E8A44C' : '#A5B8CC')
                  .margin({ bottom: 4 })
                Text(this.p4Name)
                  .fontSize('12vp')
                  .fontWeight(this.p4Checked ? FontWeight.Bold : FontWeight.Medium)
                  .fontColor(this.p4Checked ? '#E8A44C' : '#FFFFFF')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.p4Time)
                  .fontSize('10vp')
                  .fontColor('#A5B8CC')
                  .margin({ top: 2 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .layoutWeight(1)
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .backgroundColor(this.p4Checked ? 'rgba(232, 164, 76, 0.15)' : 'rgba(255, 255, 255, 0.05)')
              .borderRadius(10)

              Column() {
                Image(this.p5Checked ? $r('app.media.ic_check') : $r('app.media.ic_prayer_sajdah'))
                  .width('24vp')
                  .height('24vp')
                  .fillColor(this.p5Checked ? '#E8A44C' : '#A5B8CC')
                  .margin({ bottom: 4 })
                Text(this.p5Name)
                  .fontSize('12vp')
                  .fontWeight(this.p5Checked ? FontWeight.Bold : FontWeight.Medium)
                  .fontColor(this.p5Checked ? '#E8A44C' : '#FFFFFF')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.p5Time)
                  .fontSize('10vp')
                  .fontColor('#A5B8CC')
                  .margin({ top: 2 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .layoutWeight(1)
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .backgroundColor(this.p5Checked ? 'rgba(232, 164, 76, 0.15)' : 'rgba(255, 255, 255, 0.05)')
              .borderRadius(10)
            }
          }.width('100%').height(72).direction(Direction.Ltr)

          // Bottom Actions
          if (this.dimension === '4*4') {
            Column({ space: 8 }) {
              Row({ space: 8 }) {
                if (this.isRtl) {
                  Row({ space: 8 }) {
                    Image($r('app.media.ic_nav_tasbih')).width('18vp').height('18vp').fillColor('#E8A44C')
                    Text(this.taskTasbih)
                      .fontSize('12vp')
                      .fontColor('#FFFFFF')
                      .fontWeight(FontWeight.Medium)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('48%')
                  .height('40vp')
                  .backgroundColor('rgba(255,255,255,0.08)')
                  .borderRadius(10)
                  .justifyContent(FlexAlign.Center)
                  .onClick(() => {
                    postCardAction(this, {
                      action: 'router',
                      bundleName: 'com.siratcompanion.hos.app',
                      abilityName: 'EntryAbility',
                      params: { targetPage: 'pages/MainTabs', targetTab: 'tasbih' }
                    });
                  })

                  Row({ space: 8 }) {
                    Image($r('app.media.ic_book')).width('18vp').height('18vp').fillColor('#E8A44C')
                    Text(this.taskQuran)
                      .fontSize('12vp')
                      .fontColor('#FFFFFF')
                      .fontWeight(FontWeight.Medium)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('48%')
                  .height('40vp')
                  .backgroundColor('rgba(255,255,255,0.08)')
                  .borderRadius(10)
                  .justifyContent(FlexAlign.Center)
                  .onClick(() => {
                    postCardAction(this, {
                      action: 'router',
                      bundleName: 'com.siratcompanion.hos.app',
                      abilityName: 'EntryAbility',
                      params: { targetPage: 'pages/QuranPage' }
                    });
                  })
                } else {
                  Row({ space: 8 }) {
                    Image($r('app.media.ic_book')).width('18vp').height('18vp').fillColor('#E8A44C')
                    Text(this.taskQuran)
                      .fontSize('12vp')
                      .fontColor('#FFFFFF')
                      .fontWeight(FontWeight.Medium)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('48%')
                  .height('40vp')
                  .backgroundColor('rgba(255,255,255,0.08)')
                  .borderRadius(10)
                  .justifyContent(FlexAlign.Center)
                  .onClick(() => {
                    postCardAction(this, {
                      action: 'router',
                      bundleName: 'com.siratcompanion.hos.app',
                      abilityName: 'EntryAbility',
                      params: { targetPage: 'pages/QuranPage' }
                    });
                  })

                  Row({ space: 8 }) {
                    Image($r('app.media.ic_nav_tasbih')).width('18vp').height('18vp').fillColor('#E8A44C')
                    Text(this.taskTasbih)
                      .fontSize('12vp')
                      .fontColor('#FFFFFF')
                      .fontWeight(FontWeight.Medium)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('48%')
                  .height('40vp')
                  .backgroundColor('rgba(255,255,255,0.08)')
                  .borderRadius(10)
                  .justifyContent(FlexAlign.Center)
                  .onClick(() => {
                    postCardAction(this, {
                      action: 'router',
                      bundleName: 'com.siratcompanion.hos.app',
                      abilityName: 'EntryAbility',
                      params: { targetPage: 'pages/MainTabs', targetTab: 'tasbih' }
                    });
                  })
                }
              }.width('100%').direction(Direction.Ltr)

              Row({ space: 8 }) {
                if (this.isRtl) {
                  Row({ space: 8 }) {
                    Image($r('app.media.ic_dua')).width('18vp').height('18vp').fillColor('#E8A44C')
                    Text(this.taskDua)
                      .fontSize('12vp')
                      .fontColor('#FFFFFF')
                      .fontWeight(FontWeight.Medium)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('48%')
                  .height('40vp')
                  .backgroundColor('rgba(255,255,255,0.08)')
                  .borderRadius(10)
                  .justifyContent(FlexAlign.Center)
                  .onClick(() => {
                    postCardAction(this, {
                      action: 'router',
                      bundleName: 'com.siratcompanion.hos.app',
                      abilityName: 'EntryAbility',
                      params: { targetPage: 'pages/DuasPage' }
                    });
                  })

                  Row({ space: 8 }) {
                    Image($r('app.media.ic_sound')).width('18vp').height('18vp').fillColor('#E8A44C')
                    Text(this.taskRecitations)
                      .fontSize('12vp')
                      .fontColor('#FFFFFF')
                      .fontWeight(FontWeight.Medium)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('48%')
                  .height('40vp')
                  .backgroundColor('rgba(255,255,255,0.08)')
                  .borderRadius(10)
                  .justifyContent(FlexAlign.Center)
                  .onClick(() => {
                    postCardAction(this, {
                      action: 'router',
                      bundleName: 'com.siratcompanion.hos.app',
                      abilityName: 'EntryAbility',
                      params: { targetPage: 'pages/RecitationsPage' }
                    });
                  })
                } else {
                  Row({ space: 8 }) {
                    Image($r('app.media.ic_sound')).width('18vp').height('18vp').fillColor('#E8A44C')
                    Text(this.taskRecitations)
                      .fontSize('12vp')
                      .fontColor('#FFFFFF')
                      .fontWeight(FontWeight.Medium)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('48%')
                  .height('40vp')
                  .backgroundColor('rgba(255,255,255,0.08)')
                  .borderRadius(10)
                  .justifyContent(FlexAlign.Center)
                  .onClick(() => {
                    postCardAction(this, {
                      action: 'router',
                      bundleName: 'com.siratcompanion.hos.app',
                      abilityName: 'EntryAbility',
                      params: { targetPage: 'pages/RecitationsPage' }
                    });
                  })

                  Row({ space: 8 }) {
                    Image($r('app.media.ic_dua')).width('18vp').height('18vp').fillColor('#E8A44C')
                    Text(this.taskDua)
                      .fontSize('12vp')
                      .fontColor('#FFFFFF')
                      .fontWeight(FontWeight.Medium)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('48%')
                  .height('40vp')
                  .backgroundColor('rgba(255,255,255,0.08)')
                  .borderRadius(10)
                  .justifyContent(FlexAlign.Center)
                  .onClick(() => {
                    postCardAction(this, {
                      action: 'router',
                      bundleName: 'com.siratcompanion.hos.app',
                      abilityName: 'EntryAbility',
                      params: { targetPage: 'pages/DuasPage' }
                    });
                  })
                }
              }.width('100%').direction(Direction.Ltr)
            }.width('100%').margin({ top: 12 }).direction(Direction.Ltr)
          }
        }
      }
      .width('100%').height('100%').padding(16).justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%').height('100%').direction(Direction.Ltr)
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        bundleName: 'com.siratcompanion.hos.app',
        abilityName: 'EntryAbility',
        params: { targetPage: 'pages/MainTabs', targetTab: 'prayers' }
      });
    })
  }
}