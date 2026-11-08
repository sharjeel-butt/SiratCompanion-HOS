// entry/src/main/ets/pages/RecitationsPage.ets

import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { ThemeColors, ThemeMode } from '../core/Theme';
import { PageTheme } from '../core/PageTheme';
import { L } from '../i18n/LocalizationHelper';
import { QuranService } from '../quran/QuranService';
import { RecitationTask } from '../quran/QuranSurahModels';
import { TypographyHelper } from '../core/TypographyHelper';
import { STORAGE_KEY_LANGUAGE } from '../core/StorageKeys';
import { NavHelper } from '../core/NavHelper';
import { CustomEventStorage } from '../hijricalendar/CustomEventStorage';
import { UpcomingCustomEvent } from './HomePage';
import { CustomEventNotifier } from '../hijricalendar/CustomEventNotifier';
import { SettingsHelper } from '../settings/SettingsHelper';

@Entry
@Component
struct RecitationsPage {
  @StorageLink(STORAGE_KEY_LANGUAGE) @Watch('onLangChanged') appLanguage: string = 'en';
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.SYSTEM);
  @State tasks: RecitationTask[] = [];
  @State isLoading: boolean = true;

  async aboutToAppear() {
    await this.loadData();
  }

  onLangChanged() {
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    const ctx = getContext(this) as common.UIAbilityContext;

    const isFriday = new Date().getDay() === 5;
    const customEventsRaw = await CustomEventStorage.load();
    const hijriOffset = await SettingsHelper.getHijriOffset();

    const upcomingCustomEvents: UpcomingCustomEvent[] = [];
    for (const ev of customEventsRaw) {
      const nextDate = CustomEventNotifier.getNextOccurrence(ev, hijriOffset);
      if (nextDate) {
        upcomingCustomEvents.push({ ev: ev, date: nextDate });
      }
    }

    // Pass `true` to show ALL recitations
    this.tasks = await QuranService.getRecommendedRecitations(
      ctx, this.appLanguage, isFriday, upcomingCustomEvents, true
    );

    this.isLoading = false;
  }

  build() {
    Column() {
      Row({ space: 16 }) {
        Row() {
          Image($r('app.media.ic_chevron_right')).width(20).height(20)
            .fillColor(this.colors.textWhite)
            .rotate({ angle: L.isRtlLang(this.appLanguage) ? 0 : 180 })
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .borderRadius(20)
        .backgroundColor(this.colors.tintSoft)
        .onClick(() => router.back())

        Text(L.get('surah_recommendations', this.appLanguage))
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
      }
      .width('100%').height(72).padding({ left: 16, right: 16 })
      .backgroundColor(this.colors.cardDark)

      if (this.isLoading) {
        LoadingProgress().width(40).height(40).color(this.colors.accentGold).margin({ top: 40 })
      } else {
        List({ space: 12 }) {
          ForEach(this.tasks, (task: RecitationTask) => {
            ListItem() {
              Row() {
                Column() {
                  Text(task.name)
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.colors.textWhite)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  if (task.notes.length > 0) {
                    Text(task.notes)
                      .fontSize(11)
                      .fontColor(this.colors.textMuted)
                      .margin({ top: 4 })
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }

                  Row({ space: 8 }) {
                    Text(`${task.repeatCount > 1 ? `${task.repeatCount}x ` : ''}${L.get('occasion_' + task.occasion,
                      this.appLanguage)}`)
                      .fontSize(11).fontColor(this.colors.accentGold)

                    if (task.authenticity) {
                      Text(task.authenticity.toUpperCase())
                        .fontSize(9)
                        .fontColor(this.colors.textOnAccent)
                        .backgroundColor(this.colors.statusExpress)
                        .padding({
                          left: 4,
                          right: 4,
                          top: 1,
                          bottom: 1
                        })
                        .borderRadius(4)
                    }
                  }
                  .margin({ top: 6 })
                }
                .alignItems(HorizontalAlign.Start).layoutWeight(1)

                Column() {
                  Text(task.surahNameArabic)
                    .fontSize(20).fontFamily(TypographyHelper.getFont('ar', false)).fontColor(this.colors.accentGold)
                  Image($r('app.media.ic_chevron_right'))
                    .width(14)
                    .height(14)
                    .fillColor(this.colors.accentGold)
                    .opacity(0.6)
                    .margin({ top: 4 })
                    .rotate({ angle: L.isRtlLang(this.appLanguage) ? 180 : 0 })
                }
                .alignItems(HorizontalAlign.End).margin({ left: 12 })
              }
              .width('100%')
              .padding(16)
              .backgroundColor(this.colors.cardDark)
              .borderRadius(12)
              .border({ width: 1, color: this.colors.borderSoft })
              .direction(L.isRtlLang(this.appLanguage) ? Direction.Rtl : Direction.Ltr)
              .onClick(() => {
                // Determine the correct verse range
                let startV = task.startVerse;
                let endV = task.endVerse;

                // If startVerse is null, check for alternative selections
                if (startV === null && task.verseSelections && task.verseSelections.length > 0) {
                  startV = task.verseSelections[0].startVerse;
                  endV = task.verseSelections[0].endVerse;
                }

                NavHelper.prepareForward();
                router.pushUrl({
                  url: 'pages/SurahDetailsPage',
                  params: {
                    surahId: task.surahNumber,
                    startVerse: startV,
                    endVerse: endV,
                    taskId: task.id
                  }
                }).catch((e: Error) => console.error('Navigation failed', e));
              })
            }
          }, (task: RecitationTask) => `rec-${task.id}-${task.name}-${task.notes}`)
        }
        .width('100%').layoutWeight(1).padding({ left: 16, right: 16, top: 16 })
      }
    }
    .width('100%').height('100%').backgroundColor(this.colors.primaryGreen)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }
}