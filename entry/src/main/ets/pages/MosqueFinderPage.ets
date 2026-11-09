import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { ThemeColors, ThemeMode } from '../core/Theme';
import { PageTheme } from '../core/PageTheme';
import { L } from '../i18n/LocalizationHelper';
import { STORAGE_KEY_LANGUAGE, STORAGE_KEY_THEME_MODE } from '../core/StorageKeys';
import { MosqueService } from '../mosques/MosqueService';
import { MosqueModel } from '../mosques/MosqueModels'; // <-- Import ManifestData
import { MosqueDbHelper } from '../mosques/MosqueDbHelper';
import { LocationCache } from '../location/LocationCache';
import { OfflineCityLookup } from '../location/OfflineCityLookup';

@Entry
@Component
struct MosqueFinderPage {
  @StorageLink(STORAGE_KEY_THEME_MODE) @Watch('onThemeModeChanged') themeMode: string = ThemeMode.SYSTEM;
  @StorageLink(STORAGE_KEY_LANGUAGE) @Watch('onLangChanged') appLanguage: string = 'en';
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.SYSTEM);
  @State isLoading: boolean = true;
  @State statusText: string = 'Resolving location...';
  @State mosques: MosqueModel[] = [];
  @State currentCountry: string = '';
  @State currentCountryName: string = '';
  @State downloadSizeMb: number = 0;
  @State isDownloading: boolean = false;

  async aboutToAppear() {
    this.colors = PageTheme.compute(this.themeMode);
    await this.initLocationAndData();
  }

  onThemeModeChanged() {
    this.colors = PageTheme.compute(this.themeMode);
  }

  onLangChanged() { /* Re-render localized names */
  }

  async initLocationAndData() {
    this.isLoading = true;

    const cache = await LocationCache.load();
    if (!cache) {
      this.statusText = L.get('location_unavailable', this.appLanguage);
      this.isLoading = false;
      return;
    }

    const city = OfflineCityLookup.nearestCityForTimezone(cache.latitude, cache.longitude);
    if (city && city.countryCode) {
      this.currentCountry = city.countryCode.toUpperCase();
    } else {
      this.statusText = 'Could not determine your country.';
      this.isLoading = false;
      return;
    }

    const ctx = getContext(this) as common.UIAbilityContext;
    const isDownloaded = MosqueDbHelper.isDownloaded(ctx, this.currentCountry);

    if (!isDownloaded) {
      // Fetch manifest just to get the country name and size for the UI
      const manifest = await MosqueService.fetchManifest(ctx);
      if (manifest && manifest.countries[this.currentCountry]) {
        const item = manifest.countries[this.currentCountry];
        this.currentCountryName = item.country;
        this.downloadSizeMb = item.size_mb;
        this.statusText = `Data pack for ${item.country} is not downloaded.`;
      } else {
        this.statusText = `Data pack for ${this.currentCountry} is not available.`;
      }
      this.isLoading = false;
      return;
    }

    this.mosques = await MosqueService.searchNearby(ctx, this.currentCountry, cache.latitude, cache.longitude, 15);
    this.statusText = this.mosques.length > 0 ? '' : L.get('no_mosques_found', this.appLanguage);
    this.isLoading = false;
  }

  async downloadCurrentCountry() {
    this.isDownloading = true;
    const ctx = getContext(this) as common.UIAbilityContext;

    const manifest = await MosqueService.fetchManifest(ctx);
    // Access the nested "countries" object
    if (!manifest || !manifest.countries || !manifest.countries[this.currentCountry]) {
      this.statusText = `No data pack available for ${this.currentCountry}.`;
      this.isDownloading = false;
      return;
    }

    const success = await MosqueService.downloadPack(ctx, this.currentCountry);
    if (success) {
      await this.initLocationAndData();
    } else {
      this.statusText = 'Download failed. Check internet connection.';
    }
    this.isDownloading = false;
  }

  build() {
    Column() {
      // Top Bar
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

        Text('Mosque Finder')
          .fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
          .layoutWeight(1)
      }
      .width('100%').height(72).padding({ left: 16, right: 16 }).backgroundColor(this.colors.cardDark)

      // Content
      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).color(this.colors.accentGold)
          Text(this.statusText).fontSize(14).fontColor(this.colors.textMuted).margin({ top: 16 })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (!MosqueDbHelper.isDownloaded(getContext(this), this.currentCountry)) {
        // Download Prompt
        Column() {
          Text(this.statusText)
            .fontSize(16).fontColor(this.colors.textWhite)
            .textAlign(TextAlign.Center).margin({ bottom: 8 })

          if (this.downloadSizeMb > 0) {
            Text(`Size: ${this.downloadSizeMb.toFixed(2)} MB`)
              .fontSize(12).fontColor(this.colors.textMuted)
              .margin({ bottom: 20 })
          }

          Button(this.isDownloading ? 'Downloading...' : `Download ${this.currentCountryName} Pack`)
            .width('80%')
            .height(48)
            .backgroundColor(this.colors.accentGold)
            .fontColor(this.colors.textOnAccent)
            .enabled(!this.isDownloading)
            .onClick(() => this.downloadCurrentCountry())
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        // Mosque List
        List({ space: 12 }) {
          ForEach(this.mosques, (mosque: MosqueModel) => {
            ListItem() {
              Column() {
                Text(MosqueService.getLocalizedName(mosque, this.appLanguage))
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.colors.textWhite)
                  .width('100%')
                  .textAlign(TextAlign.Start)

                Text(`${mosque.distanceKm.toFixed(1)} km away`)
                  .fontSize(12)
                  .fontColor(this.colors.accentGold)
                  .margin({ top: 4 })
                  .width('100%')
                  .textAlign(TextAlign.Start)

                if (mosque.address && mosque.address.length > 0) {
                  Text(mosque.address)
                    .fontSize(12)
                    .fontColor(this.colors.textMuted)
                    .margin({ top: 4 })
                    .width('100%')
                    .textAlign(TextAlign.Start)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
              }
              .width('100%')
              .padding(16)
              .backgroundColor(this.colors.cardDark)
              .borderRadius(12)
              .border({ width: 1, color: this.colors.borderSoft })
            }
          }, (mosque: MosqueModel) => `mosque-${mosque.id}-${mosque.distanceKm.toFixed(1)}`) // Rulebook §I
        }
        .width('100%').layoutWeight(1).padding(16)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .direction(L.isRtlLang(this.appLanguage) ? Direction.Rtl : Direction.Ltr)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }
}