@Entry
@Component
struct TrackerWidget {
  @LocalStorageProp('dimension') dimension: string = '4*4';
  @LocalStorageProp('isRtl') isRtl: boolean = false;
  @LocalStorageProp('error') error: string = '';
  @LocalStorageProp('lblTitle') lblTitle: string = "Daily Faith";
  @LocalStorageProp('p1Name') p1Name: string = 'Fajr';
  @LocalStorageProp('p1Time') p1Time: string = '05:00';
  @LocalStorageProp('p1Checked') p1Checked: boolean = false;
  @LocalStorageProp('p2Name') p2Name: string = 'Dhuhr';
  @LocalStorageProp('p2Time') p2Time: string = '12:00';
  @LocalStorageProp('p2Checked') p2Checked: boolean = false;
  @LocalStorageProp('p3Name') p3Name: string = 'Asr';
  @LocalStorageProp('p3Time') p3Time: string = '15:00';
  @LocalStorageProp('p3Checked') p3Checked: boolean = false;
  @LocalStorageProp('p4Name') p4Name: string = 'Maghrib';
  @LocalStorageProp('p4Time') p4Time: string = '18:00';
  @LocalStorageProp('p4Checked') p4Checked: boolean = false;
  @LocalStorageProp('p5Name') p5Name: string = 'Isha';
  @LocalStorageProp('p5Time') p5Time: string = '19:30';
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
              this.PrayerCellInline(this.p5Name, this.p5Time, this.p5Checked)
              this.PrayerCellInline(this.p4Name, this.p4Time, this.p4Checked)
              this.PrayerCellInline(this.p3Name, this.p3Time, this.p3Checked)
              this.PrayerCellInline(this.p2Name, this.p2Time, this.p2Checked)
              this.PrayerCellInline(this.p1Name, this.p1Time, this.p1Checked)
            } else {
              this.PrayerCellInline(this.p1Name, this.p1Time, this.p1Checked)
              this.PrayerCellInline(this.p2Name, this.p2Time, this.p2Checked)
              this.PrayerCellInline(this.p3Name, this.p3Time, this.p3Checked)
              this.PrayerCellInline(this.p4Name, this.p4Time, this.p4Checked)
              this.PrayerCellInline(this.p5Name, this.p5Time, this.p5Checked)
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

  @Builder
  PrayerCellInline(name: string, time: string, checked: boolean) {
    Column() {
      Image(checked ? $r('app.media.ic_check') : $r('app.media.ic_prayer_sajdah'))
        .width('24vp').height('24vp')
        .fillColor(checked ? '#E8A44C' : '#A5B8CC')
        .margin({ bottom: 4 })

      Text(name)
        .fontSize('12vp')
        .fontWeight(checked ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(checked ? '#E8A44C' : '#FFFFFF')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(time)
        .fontSize('10vp')
        .fontColor('#A5B8CC')
        .margin({ top: 2 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(checked ? 'rgba(232, 164, 76, 0.15)' : 'rgba(255, 255, 255, 0.05)')
    .borderRadius(10)
  }
}