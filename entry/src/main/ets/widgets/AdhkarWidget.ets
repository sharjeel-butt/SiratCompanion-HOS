@Entry
@Component
struct AdhkarWidget {
  @LocalStorageProp('dimension') dimension: string = '2*4';
  @LocalStorageProp('arabicText') arabicText: string = 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ';
  @LocalStorageProp('source') source: string = 'Quran 11:47';
  @LocalStorageProp('error') error: string = '';
  @LocalStorageProp('lblHeader') lblHeader: string = 'DUAS';
  @LocalStorageProp('lblReadMore') lblReadMore: string = 'View All';
  @LocalStorageProp('isRtl') isRtl: boolean = false;

  build() {
    Stack() {
      // Background & Watermark
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

      Stack() {
        Image($r('app.media.ic_dua'))
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
            .fontSize('12vp')
            .fontColor('#FF6B6B')
            .maxLines(4)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        } else {

          // Header Row (Reference + Label)
          Row() {
            if (this.isRtl) {
              Image($r('app.media.ic_dua')).width('12vp').height('12vp').fillColor('#E8A44C')
              Text(this.source)
                .fontSize('10vp')
                .fontColor('#E8A44C')
                .fontWeight(FontWeight.Medium)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
                .textAlign(TextAlign.LEFT)
                .margin({ left: 6 })
              Text(this.lblHeader)
                .fontSize('11vp')
                .fontColor('#A5B8CC')
                .fontWeight(FontWeight.Bold)
                .letterSpacing(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            } else {
              Text(this.lblHeader)
                .fontSize('11vp')
                .fontColor('#A5B8CC')
                .fontWeight(FontWeight.Bold)
                .letterSpacing(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(this.source)
                .fontSize('10vp')
                .fontColor('#E8A44C')
                .fontWeight(FontWeight.Medium)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
                .textAlign(TextAlign.RIGHT)
                .margin({ right: 6 })
              Image($r('app.media.ic_dua')).width('12vp').height('12vp').fillColor('#E8A44C')
            }
          }
          .width('100%').direction(Direction.Ltr).margin({ bottom: 4 })

          Blank() // Spacer

          // Arabic Text
          Column() {
            Text(this.arabicText)
              .fontSize('22vp')
              .fontFamily('AmiriQuran, sans-serif')
              .fontColor('#FFFFFF')
              .lineHeight('36vp')
              .textAlign(TextAlign.Center)
              .direction(Direction.Rtl)
              .width('100%')
              .maxLines(this.dimension === '4*4' ? 5 : 4)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)

          Blank() // Spacer

          // Footer Section (Matched to EventWidget Pattern)
          Column() {
            Divider().color('rgba(255, 255, 255, 0.08)').margin({ bottom: 8 })
            Row() {
              if (this.isRtl) {
                Image($r('app.media.ic_chevron_right'))
                  .width('10vp')
                  .height('10vp')
                  .fillColor('#E8A44C')
                  .rotate({ angle: 180 })
                Text(this.lblReadMore)
                  .fontSize('10vp')
                  .fontColor('#E8A44C')
                  .fontWeight(FontWeight.Bold)
                  .margin({ right: 4 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              } else {
                Text(this.lblReadMore)
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
            .margin({ top: 4, bottom: 0 })
            .direction(Direction.Ltr)
          }.width('100%')

        }
      }
      .width('100%')
      .height('100%')
      .padding({
        top: 14,
        bottom: 14,
        left: 14,
        right: 14
      })
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%').height('100%')
    .direction(Direction.Ltr)
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        bundleName: 'com.siratcompanion.hos.app',
        abilityName: 'EntryAbility',
        params: { targetPage: 'pages/DuasPage' }
      });
    })
  }
}