// entry/src/main/ets/pages/RecitationsPage.ets

import { common } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import { ThemeColors, ThemeMode } from '../core/ui/themes/Theme';
import { PageTheme } from '../core/ui/PageTheme';
import { L } from '../i18n/LocalizationHelper';
import { QuranService } from '../quran/QuranService';
import { RecitationTask } from '../quran/QuranSurahModels';
import { TypographyHelper } from '../core/ui/themes/TypographyHelper';
import { STORAGE_KEY_LANGUAGE, STORAGE_KEY_QURAN_TRANSLATION_LANG } from '../core/common/StorageKeys';
import { NavHelper } from '../core/util/NavHelper';
import { CustomEventStorage } from '../hijricalendar/CustomEventStorage';
import { UpcomingCustomEvent } from './HomePage';
import { CustomEventNotifier } from '../hijricalendar/CustomEventNotifier';
import { SettingsHelper } from '../settings/SettingsHelper';
import { GradeThemeHelper } from '../core/ui/themes/GradeThemeHelper';

@Entry
@Component
struct RecitationsPage {
  @StorageLink(STORAGE_KEY_LANGUAGE) @Watch('onLangChanged') appLanguage: string = 'en';
  @StorageLink(STORAGE_KEY_QURAN_TRANSLATION_LANG) @Watch('onLangChanged') quranTransLang: string = 'default';

  @State colors: ThemeColors = PageTheme.compute(ThemeMode.SYSTEM);
  @State tasks: RecitationTask[] = [];
  @State isLoading: boolean = true;

  async aboutToAppear() {
    await this.loadData();
  }

  private getQuranTranslationLang(): string {
    if (this.quranTransLang === 'default' || this.quranTransLang === '') {
      return this.appLanguage;
    }
    return this.quranTransLang;
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
      ctx, this.getQuranTranslationLang(), isFriday, upcomingCustomEvents, true
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
                // 1. Text Information (Left side in LTR, Right side in RTL)
                Column() {
                  Text(task.name)
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.colors.textWhite)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                    .textAlign(TextAlign.Start)

                  if (task.notes.length > 0) {
                    Text(task.notes)
                      .fontSize(11)
                      .fontColor(this.colors.textMuted)
                      .margin({ top: 4 })
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')
                      .textAlign(TextAlign.Start)
                  }

                  Row({ space: 8 }) {
                    Text(`${task.repeatCount > 1 ? `${task.repeatCount}x ` : ''}${L.get('occasion_' + task.occasion,
                      this.appLanguage)}`)
                      .fontSize(11).fontColor(this.colors.accentGold)

                    if (task.authenticity) {
                      Text(this.getAuthenticityLabel(task.authenticity))
                        .fontSize(9)
                        .fontColor(GradeThemeHelper.getTextColor(task.authenticity, this.colors))
                        .backgroundColor(GradeThemeHelper.getBgColor(task.authenticity, this.colors))
                        .padding({
                          left: 4,
                          right: 4,
                          top: 1,
                          bottom: 1
                        })
                        .borderRadius(4)
                        .border({ width: 1, color: GradeThemeHelper.getTextColor(task.authenticity, this.colors) })
                        .onClick(() => {
                          this.handleAuthenticityTap(task);
                        })
                    }
                  }
                  .margin({ top: 6 })
                  .width('100%')
                  .alignItems(VerticalAlign.Center)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                // 2. Arabic Text & Chevron (Right side in LTR, Left side in RTL)
                Column() {
                  Text(task.surahNameArabic)
                    .fontSize(20)
                    .fontFamily(TypographyHelper.getArabicFont(true)) // 👈 FIX: Uses the new Arabic font resolver
                    .fontColor(this.colors.accentGold)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Image($r('app.media.ic_chevron_right'))
                    .width(14)
                    .height(14)
                    .fillColor(this.colors.accentGold)
                    .opacity(0.6)
                    .margin({ top: 4 })
                    .rotate({ angle: L.isRtlLang(this.appLanguage) ? 180 : 0 })
                }
                .alignItems(HorizontalAlign.End)
                .margin({ left: this.isRtl() ? 12 : 0, right: this.isRtl() ? 0 : 12 })
              }
              .width('100%')
              .padding(16)
              .backgroundColor(this.colors.cardDark)
              .borderRadius(12)
              .border({ width: 1, color: this.colors.borderSoft })
              .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr) // 👈 FIX: Forces RTL layout for the row
              .onClick(() => {
                // Determine the correct verse range
                let startV = task.startVerse;
                let endV = task.endVerse;

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
                }).catch((e: Error) => console.error(JSON.stringify(e)));
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

  /**
   * Resolves the authenticity grade to a localized string.
   * Falls back to the raw uppercase string if the key is missing
   * (e.g., if a new grade is added by the pipeline before the app
   * supports it).
   */
  private getAuthenticityLabel(auth: string): string {
    if (!auth || auth.length === 0) {
      return '';
    }

    // Standardize to lowercase to match our keys (grade_sahih, grade_hasan)
    const key = 'grade_' + auth.toLowerCase();
    const localized = L.get(key, this.appLanguage);

    // L.get returns the key itself if not found
    if (localized === key) {
      // Fallback: uppercase the raw string (works for English, safe for others)
      return auth.toUpperCase();
    }

    return localized;
  }

  private isRtl(): boolean {
    return L.isRtlLang(this.appLanguage);
  }

  private getCanonicalCollection(col: string): string {
    const c = col.toLowerCase();
    if (c.includes('bukhari') || c === 'bukh') {
      return 'bukhari';
    }
    if (c.includes('muslim') || c === 'musl') {
      return 'muslim';
    }
    if (c.includes('abu dawud') || c.includes('abudawud') || c === 'abud') {
      return 'abudawud';
    }
    if (c.includes('tirmidhi') || c === 'tirm') {
      return 'tirmidhi';
    }
    if (c.includes('nasai') || c === 'nasa') {
      return 'nasai';
    }
    if (c.includes('ibn majah') || c.includes('ibnmajah') || c === 'ibnm') {
      return 'ibnmajah';
    }
    if (c.includes('malik') || c === 'mali') {
      return 'malik';
    }
    return c;
  }

  private handleAuthenticityTap(task: RecitationTask): void {
    // 1. Try to navigate to the Hadith if evidence exists
    if (task.evidence && task.evidence.length > 0) {
      const primaryEvidence = task.evidence[0];
      const colId = this.getCanonicalCollection(primaryEvidence.collection);
      const hadithId = `${colId}:${primaryEvidence.hadithNumber}`;

      NavHelper.prepareForward();
      router.pushUrl({
        url: 'pages/HadithDetailsPage',
        params: { id: hadithId }
      }).catch((e: Error) => console.error(JSON.stringify(e)));
      return;
    }

    // 2. Fallback: Show the localized dialog
    let evidenceText = task.reference;
    if (task.evidence && task.evidence.length > 0) {
      const parts: string[] = [];
      for (const e of task.evidence) {
        parts.push(`${e.collection} ${e.hadithNumber} (${e.grade})`);
      }
      evidenceText = parts.join('\n');
    }

    promptAction.showDialog({
      title: L.get('hadith_evidence_title', this.appLanguage),
      message: evidenceText,
      buttons: [{ text: L.get('ok', this.appLanguage), color: this.colors.accentGold }]
    });
  }
}