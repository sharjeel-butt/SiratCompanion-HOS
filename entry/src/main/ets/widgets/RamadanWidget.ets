@Entry
@Component
struct RamadanWidget {
  @LocalStorageProp('dimension') dimension: string = '2*2';
  @LocalStorageProp('city') city: string = '—';
  @LocalStorageProp('hijriDate') hijriDate: string = '—';
  @LocalStorageProp('lang') lang: string = 'en';
  @LocalStorageProp('error') error: string = '';
  @LocalStorageProp('imsak') imsak: string = '--:--';
  @LocalStorageProp('iftar') iftar: string = '--:--';
  @LocalStorageProp('fajr') fajr: string = '--:--';
  @LocalStorageProp('targetName') targetName: string = '—';
  @LocalStorageProp('targetTime') targetTime: string = '--:--';
  @LocalStorageProp('countdown') countdown: string = '';
  @LocalStorageProp('isRamadan') isRamadan: boolean = false;
  @LocalStorageProp('lblSahur') lblSahur: string = 'Sahur';
  @LocalStorageProp('lblIftar') lblIftar: string = 'Iftar';

  build() {
    // FORCE LTR ON THE ROOT TO PREVENT OS AUTO-MIRRORING
    Stack() {
      Column() {
        if (this.error.length > 0) {
          Column() {
            Text(this.error).fontSize('14vp').fontColor('#FF6B6B').textAlign(TextAlign.Center).width('100%')
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        } else {

          /// ========== HEADER ==========
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
            .width('100%').margin({ bottom: 12 })
            .direction(Direction.Ltr)
          }

          // ========== BODY ==========
          if (!this.isRamadan) {
            // NOTIFICATION STATE (Not Ramadan)
            Column() {
              Image($r('app.media.ic_ramadan_moon')).width(32).height(32).fillColor('#E8A44C').margin({ bottom: 8 })
              Text(this.targetName).fontSize('16vp').fontWeight(FontWeight.Bold).fontColor('#FFFFFF').maxLines(1)
              Text(this.countdown).fontSize('14vp').fontColor('#E8A44C').margin({ top: 4 }).maxLines(1)
            }
            .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)

          } else if (this.dimension === '2*2') {
            Column() {
              Text(this.targetName)
                .fontSize('18vp')
                .fontColor('#AAAAAA')
                .width('100%')
                .textAlign(this.isRtl() ? TextAlign.RIGHT : TextAlign.LEFT)
                .letterSpacing(1)
              Text(this.targetTime)
                .fontSize('26vp')
                .fontWeight(FontWeight.Bold)
                .fontColor('#E8A44C')
                .width('100%')
                .textAlign(this.isRtl() ? TextAlign.RIGHT : TextAlign.LEFT)
                .margin({ top: 2 })
              Text(this.countdown)
                .fontSize('14vp')
                .fontColor('#FFFFFF')
                .width('100%')
                .textAlign(this.isRtl() ? TextAlign.RIGHT : TextAlign.LEFT)
                .margin({ top: 4 })
                .opacity(0.8)
            }
            .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)

          } else if (this.dimension === '2*4') {
            Row() {
              if (this.isRtl()) {
                // RTL: Iftar on Left (End of day), Imsak on Right (Start of day)
                Column() {
                  Image($r('app.media.ic_iftaar')).width(20).height(20).fillColor('#E8A44C').margin({ bottom: 6 })
                  Text(this.lblIftar).fontSize('12vp').fontColor('#E8A44C').maxLines(1)
                  Text(this.iftar).fontSize('16vp').fontColor('#FFFFFF').fontWeight(FontWeight.Bold).margin({ top: 4 })
                }.layoutWeight(1).alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)

                Column() {
                  Text(this.targetName).fontSize('11vp').fontColor('#E8A44C').maxLines(1)
                  Text(this.countdown)
                    .fontSize('16vp')
                    .fontColor('#FFFFFF')
                    .fontWeight(FontWeight.Bold)
                    .margin({ top: 4 })
                }.layoutWeight(1.5).alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)

                Column() {
                  Image($r('app.media.ic_sahur')).width(20).height(20).fillColor('#A5B8CC').margin({ bottom: 6 })
                  Text(this.lblSahur).fontSize('12vp').fontColor('#A5B8CC').maxLines(1)
                  Text(this.imsak).fontSize('16vp').fontColor('#FFFFFF').fontWeight(FontWeight.Bold).margin({ top: 4 })
                }.layoutWeight(1).alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
              } else {
                // LTR: Imsak on Left (Start of day), Iftar on Right (End of day)
                Column() {
                  Image($r('app.media.ic_sahur')).width(20).height(20).fillColor('#A5B8CC').margin({ bottom: 6 })
                  Text(this.lblSahur).fontSize('12vp').fontColor('#A5B8CC').maxLines(1)
                  Text(this.imsak).fontSize('16vp').fontColor('#FFFFFF').fontWeight(FontWeight.Bold).margin({ top: 4 })
                }.layoutWeight(1).alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)

                Column() {
                  Text(this.targetName).fontSize('11vp').fontColor('#E8A44C').maxLines(1)
                  Text(this.countdown)
                    .fontSize('16vp')
                    .fontColor('#FFFFFF')
                    .fontWeight(FontWeight.Bold)
                    .margin({ top: 4 })
                }.layoutWeight(1.5).alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)

                Column() {
                  Image($r('app.media.ic_iftaar')).width(20).height(20).fillColor('#E8A44C').margin({ bottom: 6 })
                  Text(this.lblIftar).fontSize('12vp').fontColor('#E8A44C').maxLines(1)
                  Text(this.iftar).fontSize('16vp').fontColor('#FFFFFF').fontWeight(FontWeight.Bold).margin({ top: 4 })
                }.layoutWeight(1).alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
              }
            }
            .width('100%').layoutWeight(1).alignItems(VerticalAlign.Center)
            .direction(Direction.Ltr)
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
          params: { targetPage: 'pages/RamadanDetailsPage' }
        });
      })
    }
    .width('100%').height('100%')
    .direction(Direction.Ltr) // FORCE LTR ON ROOT TO PREVENT SYSTEM DOUBLE-MIRRORING
  }

  private isRtl(): boolean {
    return this.lang === 'ar' || this.lang === 'ur';
  }
}