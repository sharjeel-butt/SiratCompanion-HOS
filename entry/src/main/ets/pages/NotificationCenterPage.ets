import { router } from '@kit.ArkUI';

import {
  NotificationService
} from '../core/notifications/NotificationService';

import {
  AppNotification, NotificationCategory
} from '../core/notifications/NotificationModels';

import {
  PageTheme
} from '../core/ui/PageTheme';

import {
  ThemeColors, ThemeMode
} from '../core/ui/themes/Theme';
import { L } from '../i18n/LocalizationHelper';
import { STORAGE_KEY_LANGUAGE } from '../core/common/StorageKeys';

@Entry
@Component
export struct NotificationCenterPage {
  @StorageLink(STORAGE_KEY_LANGUAGE) @Watch('onLangChanged') appLanguage: string = 'en';
  @State notifications: AppNotification[] = [];
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.SYSTEM);
  @State private dismissingIds: string[] = [];

  aboutToAppear(): void {
    this.notifications = NotificationService.getNotifications();
  }

  onLangChanged() {
  }

  build() {
    Column() { // Header
      Row({ space: 16 }) {
        Row() {
          Image($r('app.media.ic_chevron_right')).width(20).height(20).fillColor(this.colors.textWhite).rotate({
            angle: L.isRtlLang(this.appLanguage) ? 0 : 180
          })
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .borderRadius(20)
        .backgroundColor(this.colors.tintSoft)
        .onClick(() => {
          router.back();
        })

        Text(L.get('title_notifications', this.appLanguage))
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
          .maxLines(1)
          .textOverflow({
            overflow: TextOverflow.Ellipsis
          })
      }
      .width('100%')
      .height(72)
      .padding({
        left: 16, right: 16
      })
      .backgroundColor(this.colors.cardDark)
      .borderRadius(16)

      if (this.notifications.length === 0) {

        Column() {

          Text(L.get('notifications_empty', this.appLanguage))
            .fontSize(16)
            .fontColor(this.colors.textMuted)
            .textAlign(TextAlign.Start)
            .maxLines(1)
            .textOverflow({
              overflow: TextOverflow.Ellipsis
            })
        }.layoutWeight(1).justifyContent(FlexAlign.Center).width('100%')

      } else {

        List() {

          ForEach(this.notifications, (item: AppNotification, index: number) => {

            ListItem() {

              Row({ space: 12 }) {

                Image(this.getNotificationIcon(item)).width(22).height(22).fillColor(this.colors.accentGold)

                Column({ space: 6 }) {

                  Text(L.get(item.titleKey, this.appLanguage))
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.colors.textWhite)
                    .width('100%')

                  Text(L.get(item.messageKey, this.appLanguage))
                    .fontSize(13)
                    .fontColor(this.colors.textMuted)
                    .maxLines(3)
                    .width('100%')

                }.layoutWeight(1)

                if (item.category === NotificationCategory.ACHIEVEMENT) {

                  Button({
                    type: ButtonType.Circle
                  }) {

                    Image($r('app.media.ic_close')).width(14).height(14).fillColor(this.colors.textMuted)

                  }.width(32).height(32).backgroundColor(this.colors.tintSoft).onClick(() => {

                    animateTo({
                      duration: 280, curve: Curve.EaseOut
                    }, () => {

                      this.dismissingIds = [...this.dismissingIds, item.id];

                    });

                    setTimeout(() => {

                      NotificationService.dismissAchievement(item.id);

                      this.notifications = NotificationService.getNotifications();

                    }, 300);
                  })
                }

              }
              .width('100%')
              .padding(16)
              .backgroundColor(

                item.category === NotificationCategory.ACHIEVEMENT

                  ? this.colors.tintSubtle

                  : this.colors.cardDark

              )
              .borderRadius(16)
              .opacity(

                this.dismissingIds.indexOf(item.id) >= 0

                  ? 0

                  : 1

              )
              .scale({
                x: this.dismissingIds.indexOf(item.id) >= 0 ? 0.94 : 1,
                y: this.dismissingIds.indexOf(item.id) >= 0 ? 0.94 : 1
              })

            }.width('100%').padding({
              bottom: 10
            }).onClick(() => {
              if (item.category === NotificationCategory.ACHIEVEMENT) {
                return;
              }

              this.openPrayerNotification(item);
            })

          },
            (item: AppNotification, index: number): string => 'notif-' + item.id + '-' + this.appLanguage + '-' + index)
        }.width('100%').layoutWeight(1).margin({
          top: 16
        })
      }
    }
    .width('100%')
    .height('100%')
    .direction(L.isRtlLang(this.appLanguage) ? Direction.Rtl : Direction.Ltr)
    .padding(16)
    .backgroundColor(this.colors.primaryGreen)
  }

  private getNotificationIcon(item: AppNotification): Resource {

    if (item.category === NotificationCategory.ACHIEVEMENT) {
      return $r('app.media.ic_trophy');
    }

    const prayerId = item.payload;

    if (prayerId === undefined) {
      return $r('app.media.ic_bell');
    }
    if (item.category === NotificationCategory.RAMADAN) {

      return $r('app.media.ic_ramadan_moon');
    }

    switch (prayerId) {

      case 'fajr':
        return $r('app.media.ic_fajr');

      case 'dhuhr':
        return $r('app.media.ic_dhuhr');

      case 'asr':
        return $r('app.media.ic_asr');

      case 'maghrib':
        return $r('app.media.ic_maghrib');

      case 'isha':
        return $r('app.media.ic_isha');

      default:
        return $r('app.media.ic_bell');
    }


  }

  private loadNotifications(): void {
    this.notifications = NotificationService.getNotifications();
  }

  private openPrayerNotification(item: AppNotification): void {
    if (item.payload !== undefined) { // Clear first so the Watch always fires
      AppStorage.setOrCreate('prayer_highlight_target', '');
      AppStorage.setOrCreate('prayer_highlight_target', item.payload);
    }
    AppStorage.setOrCreate('nav_target_tab', 'prayers');
    router.back();
  }

  private dismissNotification(item: AppNotification): void {
    if (this.dismissingIds.indexOf(item.id) >= 0) {
      return;
    }
    this.dismissingIds = [...this.dismissingIds, item.id];
    setTimeout(() => {
      NotificationService.dismissAchievement(item.id);
      this.notifications = NotificationService.getNotifications();
      this.dismissingIds = this.dismissingIds.filter((id: string) => id !== item.id);
    }, 300);
  }
}