import { promptAction, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { ThemeColors, ThemeMode } from '../core/Theme';
import { PageTheme } from '../core/PageTheme';
import { L } from '../i18n/LocalizationHelper';
import { STORAGE_KEY_LANGUAGE, STORAGE_KEY_THEME_MODE } from '../core/StorageKeys';
import { MosqueService } from '../mosques/MosqueService';
import { MosqueModel } from '../mosques/MosqueModels';
import { MosqueDbHelper } from '../mosques/MosqueDbHelper';
import { LocationCache } from '../location/LocationCache';
import { OfflineCityLookup } from '../location/OfflineCityLookup';
import { MosqueStorage } from '../mosques/MosqueStorage';
import { LocationHelper } from '../location/LocationUtils';

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
  @State isCountryAvailable: boolean = false;
  @State selectedMosque: MosqueModel | null = null;
  @State showDetailsSheet: boolean = false;
  @State showFormSheet: boolean = false;
  @State editingMosque: MosqueModel | null = null;
  // Form fields
  @State formName: string = '';
  @State formAddress: string = '';
  @State formLat: string = '';
  @State formLng: string = '';
  @State locationStatus: string = '';
  @State renderTick: number = 0;
  @State activeFilter: string = 'all';

  @State isFetchingLocation: boolean = false;

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
    this.isCountryAvailable = false;
    try {
      const cache = await LocationCache.load();
      if (!cache) {
        this.statusText = 'Location unavailable. Please ensure GPS is on.';
        return;
      }

      const city = OfflineCityLookup.nearestCityForTimezone(cache.latitude, cache.longitude);
      if (city && city.countryCode) {
        this.currentCountry = city.countryCode.toUpperCase();
      } else {
        this.statusText = 'Could not determine your country.';
        return;
      }

      const ctx = getContext(this) as common.UIAbilityContext;
      const isDownloaded = MosqueDbHelper.isDownloaded(ctx, this.currentCountry);

      if (!isDownloaded) {
        const manifest = await MosqueService.fetchManifest(ctx);
        if (manifest && manifest.countries && manifest.countries[this.currentCountry]) {
          const item = manifest.countries[this.currentCountry];
          this.currentCountryName = item.country;
          this.isCountryAvailable = true;
          this.downloadSizeMb = item.size_mb;
          this.statusText = `Data pack for ${item.country} is required.`;
        } else {
          this.statusText = `Data pack for ${this.currentCountry} is not available on CDN.`;
        }
        return;
      }

      this.mosques = await MosqueService.searchNearby(ctx, this.currentCountry, cache.latitude, cache.longitude, 15);
      this.statusText = this.mosques.length > 0 ? '' : 'No mosques found nearby.';

    } catch (e) {
      this.statusText = 'An error occurred while resolving location.';
      console.error(JSON.stringify(e));
    } finally {
      this.isLoading = false; // Guaranteed to run
    }
  }

  async downloadCurrentCountry() {
    this.isDownloading = true;
    this.statusText = 'Downloading...';
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const manifest = await MosqueService.fetchManifest(ctx);

      let expectedSize = 0;
      if (manifest && manifest.countries && manifest.countries[this.currentCountry]) {
        expectedSize = manifest.countries[this.currentCountry].size_bytes;
      }

      if (expectedSize === 0) {
        this.statusText = 'Could not read manifest file size.';
        return;
      }

      const success = await MosqueService.downloadPack(ctx, this.currentCountry, expectedSize);
      if (success) {
        await this.initLocationAndData();
      } else {
        this.statusText = 'Download failed. File corrupted or missing on server.';
      }
    } catch (e) {
      this.statusText = 'Download failed. Check your connection.';
    } finally {
      this.isDownloading = false; // Guaranteed to run
    }
  }

  build() {

    Stack({ alignContent: Alignment.BottomEnd }) {
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
            Text('Resolving location...').fontSize(14).fontColor(this.colors.textMuted).margin({ top: 16 })
          }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)

        } else if (!MosqueDbHelper.isDownloaded(getContext(this), this.currentCountry)) {
          // Download Prompt
          Column() {
            Text(this.statusText)
              .fontSize(16)
              .fontColor(this.colors.textWhite)
              .textAlign(TextAlign.Center)
              .margin({ bottom: 8 })

            if (this.downloadSizeMb > 0 && this.isCountryAvailable) {
              Text(`Size: ${this.downloadSizeMb.toFixed(2)} MB`)
                .fontSize(12).fontColor(this.colors.textMuted)
                .margin({ bottom: 20 })
            }

            Button(
              this.isDownloading
                ? 'Downloading...'
                : (this.isCountryAvailable ? `Download ${this.currentCountryName || this.currentCountry} Pack` :
                'Data Pack Unavailable')
            )
              .width('80%')
              .height(48)
              // FIX: Change background color to grey if unavailable
              .backgroundColor(this.isCountryAvailable ? this.colors.accentGold : this.colors.tintMedium)
              // FIX: Change text color to muted if unavailable
              .fontColor(this.isCountryAvailable ? this.colors.textOnAccent : this.colors.textMuted)
              // FIX: Disable the button if country not available or currently downloading
              .enabled(this.isCountryAvailable && !this.isDownloading)
              .onClick(() => this.downloadCurrentCountry())
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        } else {
          // Filter chip row — direct child of the outer Column, same
          // layout context as the original top bar.
          Row({ space: 8 }) {
            this.FilterChip('all')
            this.FilterChip('default')
            this.FilterChip('custom')
          }
          .width('100%')
          .padding({
            left: 16,
            right: 16,
            top: 12,
            bottom: 4
          })

          // List or empty state — also direct child, so layoutWeight(1)
          // resolves against the outer Column (identical to how the
          // original list sized itself).
          if (this.filteredMosques().length === 0) {
            this.EmptyFilterState()
          } else {
            List({ space: 12 }) {
              ForEach(this.filteredMosques(), (mosque: MosqueModel) => {
                ListItem() {
                  Column() {
                    // ---- mosque card body — unchanged from current file ----
                    Row() {
                      Text(MosqueService.getLocalizedName(mosque, this.appLanguage))
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(this.colors.textWhite)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .layoutWeight(1)

                      if (mosque.isCustom) {
                        Text('Custom')
                          .fontSize(9)
                          .fontColor(this.colors.textOnAccent)
                          .backgroundColor(this.colors.accentGold)
                          .padding({
                            left: 6,
                            right: 6,
                            top: 2,
                            bottom: 2
                          })
                          .borderRadius(4)
                          .margin({ left: 8 })
                          .flexShrink(0)
                      }
                    }
                    .width('100%')
                    .alignItems(VerticalAlign.Center)
                    .margin({ bottom: 4 })

                    Text(`${mosque.distanceKm.toFixed(1)} ${L.get('km_away', this.appLanguage)} (direct)`)
                      .fontSize(12)
                      .fontColor(this.colors.accentGold)
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
                  .clip(true)
                }
                .width('100%')
                .swipeAction({
                  start: mosque.isCustom ? {
                    builder: () => {
                      this.SwipeEditAction(mosque)
                    }
                  } : undefined,
                  end: mosque.isCustom ? {
                    builder: () => {
                      this.SwipeDeleteAction(mosque)
                    }
                  } : undefined
                })
                .onClick(() => {
                  this.selectedMosque = mosque;
                  this.showDetailsSheet = true;
                })
              }, (mosque: MosqueModel) =>
              `mosque-${mosque.id}-${mosque.isCustom}-${this.activeFilter}-${this.appLanguage}-${mosque.name}`
              )
            }
            .width('100%')
            .layoutWeight(1)
            .padding({
              left: 16,
              right: 16,
              top: 12,
              bottom: 16
            })
          }
        }
      }

      Row() {
        Image($r('app.media.ic_add'))
          .width(24).height(24)
          .fillColor(this.colors.textOnAccent)
      }
      .width(56)
      .height(56)
      .backgroundColor(this.colors.accentGold)
      .borderRadius(28)
      .shadow({
        radius: 12,
        color: this.colors.shadowFloating,
        offsetX: 0,
        offsetY: 4
      })
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .margin({ right: 24, bottom: 24 })
      .onClick(() => this.openAddForm())
      .bindSheet($$this.showFormSheet, this.AddEditMosqueSheet(), {
        height: SheetSize.FIT_CONTENT,
        dragBar: true,
        backgroundColor: this.colors.cardDark,
        onDisappear: () => {
          this.showFormSheet = false;
        }
      })
    }
    .width('100%')
    .height('100%')
    .bindSheet($$this.showDetailsSheet, this.MosqueDetailsSheet(), {
      height: SheetSize.FIT_CONTENT,
      dragBar: true,
      showClose: false,
      backgroundColor: this.colors.cardDark,
      onDisappear: () => {
        this.selectedMosque = null;
      }
    })
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .direction(L.isRtlLang(this.appLanguage) ? Direction.Rtl : Direction.Ltr)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

  }

  @Builder
  SwipeEditAction(mosque: MosqueModel) {
    Row() {
      Image($r('app.media.ic_edit'))
        .width(24)
        .height(24)
        .fillColor(this.colors.textOnAccent)
    }
    .width(80)
    .height('100%')
    .backgroundColor(this.colors.accentGold)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .borderRadius({ topLeft: 12, bottomLeft: 12 }) // Matches the card's corner
    .onClick(() => {
      this.openEditForm(mosque);
    })
  }

  @Builder
  SwipeDeleteAction(mosque: MosqueModel) {
    Row() {
      Image($r('app.media.ic_delete'))
        .width(24)
        .height(24)
        .fillColor('#FFFFFF') // Force white for contrast
    }
    .width(80)
    .height('100%')
    .backgroundColor(this.colors.statusExpress) // Red color
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .borderRadius({ topRight: 12, bottomRight: 12 }) // Matches the card's corner
    .onClick(() => {
      this.deleteCustomMosque(mosque);
    })
  }

  /**
   * One filter pill. Reads `this.activeFilter` directly inside the
   * builder — build() re-runs on every @State change, so the builder
   * is re-invoked with fresh state and the selected/hover styling
   * updates automatically.
   *
   * The `(N)` suffix is the count for that filter, so the user can
   * tell the difference between "no custom mosques added yet" and
   * "custom mosques exist but are filtered out of the current view".
   */
  @Builder
  FilterChip(id: string) {
    Text(`${this.filterLabel(id)} (${this.filterCount(id)})`)
      .fontSize(13)
      .fontWeight(this.activeFilter === id ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.activeFilter === id
        ? this.colors.textOnAccent
        : this.colors.textMuted)
      .backgroundColor(this.activeFilter === id
        ? this.colors.accentGold
        : this.colors.cardDark)
      .padding({
        left: 14,
        right: 14,
        top: 8,
        bottom: 8
      })
      .borderRadius(16)
      .border({
        width: 1,
        color: this.activeFilter === id
          ? this.colors.accentGold
          : this.colors.borderSoft
      })
      .maxLines(1)
      .onClick(() => {
        if (this.activeFilter !== id) {
          this.activeFilter = id;
        }
      })
  }

  /**
   * Shown when the current filter yields zero results.
   *
   * Three distinct messages so the user understands *why* the list
   * is empty:
   *   • custom-empty  → "You haven't added any custom mosques yet"
   *                     plus a CTA to open the add form
   *   • default-empty → "No downloaded mosques found nearby"
   *   • all-empty     → "No mosques found nearby"
   */
  @Builder
  EmptyFilterState() {
    Column() {
      Image($r('app.media.ic_nav_mosque'))
        .width(48)
        .height(48)
        .fillColor(this.colors.textMuted)
        .opacity(0.45)
        .margin({ bottom: 16 })

      Text(L.get(this.emptyMessageKey(), this.appLanguage))
        .fontSize(14)
        .fontColor(this.colors.textMuted)
        .textAlign(TextAlign.Center)
        .lineHeight(20)
        .padding({ left: 32, right: 32 })
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      if (this.activeFilter === 'custom') {
        Button() {
          Row({ space: 6 }) {
            Image($r('app.media.ic_add'))
              .width(16)
              .height(16)
              .fillColor(this.colors.textOnAccent)
            Text(L.get('mosque_add_custom_cta', this.appLanguage))
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.colors.textOnAccent)
          }
        }
        .height(44)
        .padding({ left: 20, right: 20 })
        .backgroundColor(this.colors.accentGold)
        .borderRadius(12)
        .margin({ top: 20 })
        .onClick(() => {
          this.openAddForm();
        })
      }
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({
      left: 16,
      right: 16,
      top: 40,
      bottom: 40
    })
  }

  @Builder
  AddEditMosqueSheet() {
    Column() {
      Row().height(8)
      Text(this.editingMosque ? 'Edit Custom Mosque' : 'Add Custom Mosque')
        .fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
        .margin({ bottom: 20 })

      Scroll() {
        Column({ space: 16 }) {
          // --- Name Input ---
          TextInput({ text: this.formName, placeholder: 'Mosque Name *' })
            .onChange(v => this.formName = v)
            .backgroundColor(this.colors.tintSoft).fontColor(this.colors.textWhite)

          // --- Address Input ---
          TextInput({ text: this.formAddress, placeholder: 'Address (Optional)' })
            .onChange(v => this.formAddress = v)
            .backgroundColor(this.colors.tintSoft).fontColor(this.colors.textWhite)

          // --- Lat / Lng Inputs ---
          Row({ space: 12 }) {
            // 👇 FIX: Use $$ binding so they update when handleLocationFetch changes the state
            TextInput({ text: $$this.formLat, placeholder: 'Latitude' })
              .type(InputType.Normal)
              .backgroundColor(this.colors.tintSoft)
              .fontColor(this.colors.textWhite)
              .layoutWeight(1)

            TextInput({ text: $$this.formLng, placeholder: 'Longitude' })
              .type(InputType.Normal)
              .backgroundColor(this.colors.tintSoft)
              .fontColor(this.colors.textWhite)
              .layoutWeight(1)
          }

          // --- Use Current Location Button ---
          Row() {
            if (this.isFetchingLocation) {
              Row({ space: 8 }) {
                LoadingProgress().width(16).height(16).color(this.colors.accentGold)
                Text(L.get('fetching', this.appLanguage))
                  .fontSize(14).fontColor(this.colors.accentGold)
              }
            } else {
              Text(L.get('wizard_location_title', this.appLanguage))
                .fontSize(14).fontColor(this.colors.accentGold)
            }
          }
          .width('100%')
          .height(44)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .backgroundColor(this.colors.tintSubtle)
          .borderRadius(8)
          .border({ width: 1, color: this.colors.borderSoft })
          .parallelGesture(
            TapGesture().onAction(() => {
              this.handleLocationFetch();
            })
          )

          // 👇 Debug Status Text
          if (this.locationStatus.length > 0) {
            Text(this.locationStatus)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .backgroundColor(this.locationStatus.startsWith('ERROR') ? '#FF0000' : '#00AA00')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(8)
              .borderRadius(8)
          }
        }
      }
      .key(this.renderTick.toString()) // 👈 FORCE the Sheet to redraw when tick changes

      // --- Action Buttons (Cancel / Save) ---
      Row({ space: 12 }) {
        Button('Cancel')
          .layoutWeight(1)
          .height(48)
          .backgroundColor(this.colors.tintSoft)
          .fontColor(this.colors.textWhite)
          .onClick(() => this.showFormSheet = false)

        Button('Save')
          .layoutWeight(1)
          .height(48)
          .backgroundColor(this.colors.accentGold)
          .fontColor(this.colors.textOnAccent)
          .onClick(() => this.saveCustomMosque())
      }
      .width('100%').margin({ top: 24 })
    }
    .width('100%').padding({ left: 20, right: 20, bottom: 40 })
  }

  @Builder
  MosqueDetailsSheet() {
    if (this.selectedMosque) {
      Column() {
        // 1. Drag Bar
        Row().height(8)

        // 2. Header (Name and Distance)
        Row() {
          Column() {
            Text(MosqueService.getLocalizedName(this.selectedMosque, this.appLanguage))
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.colors.textWhite)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
              .textAlign(TextAlign.Start)

            Text(`${this.selectedMosque.distanceKm.toFixed(1)} km (direct line)`)
              .fontSize(13)
              .fontColor(this.colors.accentGold)
              .margin({ top: 4 })
              .width('100%')
              .textAlign(TextAlign.Start)
          }
          .layoutWeight(1).alignItems(HorizontalAlign.Start)

          Image($r('app.media.ic_close'))
            .width(24).height(24).fillColor(this.colors.textMuted)
            .onClick(() => {
              this.showDetailsSheet = false;
            })
        }
        .width('100%')
        .padding({
          top: 10,
          bottom: 16,
          left: 20,
          right: 20
        })

        Divider().color(this.colors.borderSoft).width('90%')

        // 3. Address (If available)
        if (this.selectedMosque.address && this.selectedMosque.address.length > 0) {
          Row({ space: 12 }) {
            Image($r('app.media.ic_pin'))
              .width(16).height(16)
              .fillColor(this.colors.accentGold)
              .margin({ top: 2 })
            Text(this.selectedMosque.address)
              .fontSize(14).fontColor(this.colors.textMuted).lineHeight(20)
              .layoutWeight(1)
          }
          .width('100%')
          .padding({
            top: 16,
            bottom: 16,
            left: 20,
            right: 20
          })
          .alignItems(VerticalAlign.Top)

          Divider().color(this.colors.borderSoft).width('90%')
        }

        // 4. Action Buttons
        Column({ space: 12 }) {
          // ---- Get Directions — always shown ----
          Button() {
            Row({ space: 8 }) {
              Image($r('app.media.ic_compass'))
                .width(18).height(18)
                .fillColor(this.colors.textOnAccent)
              Text(L.get('get_directions', this.appLanguage))
                .fontSize(15).fontWeight(FontWeight.Medium)
                .fontColor(this.colors.textOnAccent)
            }
          }
          .width('100%')
          .height(48)
          .backgroundColor(this.colors.accentGold)
          .borderRadius(12)
          .onClick(() => {
            if (this.selectedMosque) {
              this.openMaps(this.selectedMosque);
            }
          })

          // ---- Phone — conditional ----
          if (this.selectedMosque.phone && this.selectedMosque.phone.length > 0) {
            Button() {
              Row({ space: 8 }) {
                Image($r('app.media.ic_phone'))
                  .width(18).height(18).fillColor(this.colors.textWhite)
                Text(this.selectedMosque.phone)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.colors.textWhite)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
                  .textAlign(TextAlign.Center)
              }
            }
            .width('100%')
            .height(48)
            .backgroundColor(this.colors.tintSoft)
            .borderRadius(12)
            .onClick(() => {
              if (this.selectedMosque) {
                this.openDialer(this.selectedMosque.phone);
              }
            })
          }

          // ---- Website — conditional ----
          if (this.selectedMosque.website && this.selectedMosque.website.length > 0) {
            Button() {
              Row({ space: 8 }) {
                Image($r('app.media.ic_globe'))
                  .width(18).height(18).fillColor(this.colors.textWhite)
                Text(L.get('visit_website', this.appLanguage))
                  .fontSize(15).fontWeight(FontWeight.Medium)
                  .fontColor(this.colors.textWhite)
              }
            }
            .width('100%')
            .height(48)
            .backgroundColor(this.colors.tintSoft)
            .borderRadius(12)
            .onClick(() => {
              if (this.selectedMosque) {
                this.openWebsite(this.selectedMosque.website);
              }
            })
          }

          // ---- No-contact hint ----
          if ((!this.selectedMosque.phone || this.selectedMosque.phone.length === 0) &&
            (!this.selectedMosque.website || this.selectedMosque.website.length === 0)) {
            Text(L.get('no_contact_info', this.appLanguage))
              .fontSize(12)
              .fontColor(this.colors.textMuted)
              .fontStyle(FontStyle.Italic)
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding({ top: 4 })
          }
        }
        .width('100%')
        .padding({
          top: 20,
          bottom: 40,
          left: 20,
          right: 20
        })
      }
      .width('100%').backgroundColor(this.colors.cardDark)
      .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
    } else {
      // Fallback
      Column().width('100%').height(100).backgroundColor(this.colors.cardDark)
    }
  }

  openAddForm() {
    this.editingMosque = null;
    this.formName = '';
    this.formAddress = '';

    // Pre-fill with current location if available
    LocationCache.load().then(cache => {
      if (cache) {
        this.formLat = cache.latitude.toFixed(6);
        this.formLng = cache.longitude.toFixed(6);
      }
    });

    this.showFormSheet = true;
  }

  openEditForm(mosque: MosqueModel) {
    this.editingMosque = mosque;
    this.formName = mosque.name;
    this.formAddress = mosque.address;
    this.formLat = mosque.lat.toFixed(6);
    this.formLng = mosque.lng.toFixed(6);
    this.showDetailsSheet = false; // Close details
    this.showFormSheet = true; // Open editor
  }

  async saveCustomMosque() {
    if (!this.formName.trim()) {
      return;
    }

    const lat = parseFloat(this.formLat);
    const lng = parseFloat(this.formLng);
    // FIX: Validate coordinate boundaries
    if (isNaN(lat) || lat < -90 || lat > 90) {
      promptAction.showToast({ message: 'Invalid Latitude' });
      return;
    }
    if (isNaN(lng) || lng < -180 || lng > 180) {
      promptAction.showToast({ message: 'Invalid Longitude' });
      return;
    }

    const newMosque: MosqueModel = {
      id: this.editingMosque ? this.editingMosque.id : Date.now(),
      osmId: this.editingMosque ? this.editingMosque.osmId : `custom_${Date.now()}`,
      name: this.formName.trim(),
      nameAr: '',
      nameUr: '',
      nameTr: '',
      nameId: '',
      nameBn: '',
      nameZh: '',
      lat: lat,
      lng: lng,
      cityName: 'Custom',
      address: this.formAddress.trim(),
      phone: '',
      website: '',
      distanceKm: 0,
      isCustom: true
    };

    await MosqueStorage.addOrUpdate(newMosque);
    this.showFormSheet = false;
    this.activeFilter = 'custom';

    await this.initLocationAndData();
  }

  async deleteCustomMosque(mosque: MosqueModel) {
    // Show confirmation dialog
    promptAction.showDialog({
      title: 'Delete Mosque',
      message: `Are you sure you want to delete "${mosque.name}"?`,
      buttons: [
        { text: 'Cancel', color: this.colors.dialogCancel },
        { text: 'Delete', color: this.colors.statusExpress }
      ]
    }).then(async (res) => {
      if (res.index === 1) {
        await MosqueStorage.delete(mosque.id);
        this.showDetailsSheet = false;
        await this.initLocationAndData();
      }
    });
  }

  openMaps(mosque: MosqueModel) {
    const ctx = getContext(this) as common.UIAbilityContext;
    // Standard format: geo:lat,lng?q=lat,lng(label)
    const uri = `geo:${mosque.lat},${mosque.lng}?q=${mosque.lat},${mosque.lng}(${encodeURIComponent(mosque.name)})`;

    ctx.startAbility({
      action: 'ohos.want.action.viewData',
      uri: uri
    }).catch((e: Error) => {
      console.error('Maps failed', e.message);
      // Fallback: open in browser if no map app is installed
      ctx.startAbility({
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: `https://maps.google.com/?q=${mosque.lat},${mosque.lng}`
      });
    });
  }

  openDialer(phone: string) {
    const ctx = getContext(this) as common.UIAbilityContext;
    ctx.startAbility({
      action: 'ohos.want.action.dial',
      uri: `tel:${phone}`
    }).catch((e: Error) => console.error('Dialer failed', e.message));
  }

  openWebsite(url: string) {
    const ctx = getContext(this) as common.UIAbilityContext;
    // Ensure URL has a protocol
    const finalUrl = url.startsWith('http') ? url : `https://${url}`;
    ctx.startAbility({
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: finalUrl
    }).catch((e: Error) => console.error('Browser failed', e.message));
  }

  private async handleLocationFetch() {
    if (this.isFetchingLocation) {
      return;
    }
    this.isFetchingLocation = true;
    this.locationStatus = 'Starting GPS...';
    this.renderTick++; // 👈 Force UI update

    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const data = await LocationHelper.fetchLocationData(ctx, 'interactive');

      this.formLat = data.latitude.toFixed(6);
      this.formLng = data.longitude.toFixed(6);
      this.locationStatus = `Success: ${data.latitude.toFixed(4)}, ${data.longitude.toFixed(4)}`;

      this.getUIContext().getPromptAction().showToast({ message: "Location fetched!" });
    } catch (err) {
      const error = err as Error;
      this.locationStatus = `ERROR: ${error.message}`;

      if (error.message === 'GPS_OFF') {
        await LocationHelper.showLocationDisabledDialog(this.colors.accentGold);
      } else if (error.message === 'PERMISSION_DENIED') {
        await LocationHelper.showPermissionDeniedDialog(this.colors.accentGold);
      }

      const cache = await LocationCache.load();
      if (cache) {
        this.formLat = cache.latitude.toFixed(6);
        this.formLng = cache.longitude.toFixed(6);
        this.locationStatus += ' (Used Cache)';
      }
    } finally {
      this.isFetchingLocation = false;
      this.renderTick++; // 👈 Force UI update
    }
  }

  private isRtl(): boolean {
    return L.isRtlLang(this.appLanguage);
  }

  /**
   * Return the filtered subset of `this.mosques` matching the
   * current `activeFilter`. Called from build() for both the length
   * check and the ForEach — cheap enough at typical list sizes
   * (usually < 25 mosques) that recomputing is preferable to a
   * cached @State field that could go stale.
   */
  private filteredMosques(): MosqueModel[] {
    if (this.activeFilter === 'custom') {
      return this.mosques.filter((m: MosqueModel): boolean => m.isCustom);
    }
    if (this.activeFilter === 'default') {
      return this.mosques.filter((m: MosqueModel): boolean => !m.isCustom);
    }
    return this.mosques;
  }

  /** Number of mosques in the given filter category. */
  private filterCount(filter: string): number {
    if (filter === 'all') {
      return this.mosques.length;
    }
    if (filter === 'custom') {
      let n = 0;
      for (const m of this.mosques) {
        if (m.isCustom) {
          n++;
        }
      }
      return n;
    }
    if (filter === 'default') {
      let n = 0;
      for (const m of this.mosques) {
        if (!m.isCustom) {
          n++;
        }
      }
      return n;
    }
    return 0;
  }

  /** Localized label for the given filter chip. */
  private filterLabel(filter: string): string {
    if (filter === 'all') {
      return L.get('filter_all', this.appLanguage);
    }
    if (filter === 'custom') {
      return L.get('filter_custom', this.appLanguage);
    }
    if (filter === 'default') {
      return L.get('filter_default', this.appLanguage);
    }
    return filter;
  }

  /** Localized empty-state message key for the current filter. */
  private emptyMessageKey(): string {
    if (this.activeFilter === 'custom') {
      return 'mosque_filter_empty_custom';
    }
    if (this.activeFilter === 'default') {
      return 'mosque_filter_empty_default';
    }
    return 'mosque_filter_empty_all';
  }
}