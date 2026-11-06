import { LoadedSettings, PrayerOffsets, SettingsHelper } from '../settings/SettingsHelper';
import { LocationCache } from '../location/LocationCache';
import { AdvancedCalcSettings } from '../prayer/AdvancedCalcModels';
import { DailyPrayerTimes, HighLatitudeRule, PrayerTimeCalculator } from '../prayer/PrayerTimeCalculator';
import { PrayerManager } from '../prayer/PrayerManager';
import { DateHelper } from '../hijricalendar/DateUtils';
import { RamadanHelper } from '../ramadan/RamadanHelper';
import { L } from '../i18n/LocalizationHelper';
import { STORAGE_KEY_LANGUAGE, STORAGE_KEY_LANGUAGE_OVERRIDE } from '../core/StorageKeys';
import { ClockFormatHelper } from '../core/ClockFormat';
import { AppLogger } from '../core/AppLogger';
import { formBindingData } from '@kit.FormKit';
import { PreferencesHelper } from '../core/PreferencesHelper';
import { OfflineCityLookup } from '../location/OfflineCityLookup';

export class WidgetDataBuilder {
  static async build(dimension: string, currentLang?: string): Promise<Record<string, Object>> {
    try {
      // ALWAYS reload from disk to get the absolute latest language setting
      await PreferencesHelper.reloadFromDisk();

      let lang: string = currentLang ?? '';
      const override = await PreferencesHelper.getString(STORAGE_KEY_LANGUAGE_OVERRIDE, 'system');

      // If Auto-Detect is set, resolve the system language directly
      if (override === 'system') {
        lang = L.matchSystemLocale();
      } else if (override.length > 0) {
        lang = override;
      } else if (lang.length === 0) {
        lang = await PreferencesHelper.getString(STORAGE_KEY_LANGUAGE, 'en');
      }

      const settings: LoadedSettings = await SettingsHelper.loadAll();
      const mode: string = await SettingsHelper.getLocationMode();
      const highLat: HighLatitudeRule = await SettingsHelper.getHighLatRule();
      const advanced: AdvancedCalcSettings = await SettingsHelper.getAdvancedCalcSettings();
      const offsets: PrayerOffsets = await SettingsHelper.getPrayerOffsets();
      const hijriOffset: number = await SettingsHelper.getHijriOffset();

      let lat: number = 0;
      let lng: number = 0;
      let city: string = '—';

      if (mode === 'Manual') {
        const manual = await SettingsHelper.getManualCoords();
        lat = manual.lat;
        lng = manual.lng;
        let rawCity = manual.cityName;
        if (rawCity === 'DEFAULT LOCATION' || rawCity.length === 0) {
          rawCity = L.get('default_location', lang);
        } else {
          rawCity = OfflineCityLookup.translateCityName(rawCity, lang);
        }
        city = rawCity;
      } else {
        const cached = await LocationCache.load();
        if (cached !== null) {
          lat = cached.latitude;
          lng = cached.longitude;
          let rawCity = cached.cityName;
          if (rawCity === 'DEFAULT LOCATION' || rawCity.length === 0) {
            rawCity = L.get('default_location', lang);
          } else {
            rawCity = OfflineCityLookup.translateCityName(rawCity, lang);
          }
          city = rawCity;
        }
      }
      if (lat === 0 && lng === 0) {
        return WidgetDataBuilder.errorData(dimension, 'Set location in app');
      }

      const times: DailyPrayerTimes = PrayerTimeCalculator.calculateWithDeviceTimezone(
        new Date(), lat, lng, settings.method, settings.asr, highLat, advanced
      );

      // Apply offsets to all times
      const fajrRaw = PrayerManager.offsetTime(times.fajr, offsets.fajr);
      const dhuhrRaw = PrayerManager.offsetTime(times.dhuhr, offsets.dhuhr);
      const asrRaw = PrayerManager.offsetTime(times.asr, offsets.asr);
      const maghribRaw = PrayerManager.offsetTime(times.maghrib, offsets.maghrib);
      const ishaRaw = PrayerManager.offsetTime(times.isha, offsets.isha);
      const imsakRaw = PrayerManager.offsetTime(times.imsak, offsets.fajr);
      const sunriseRaw = times.sunrise;
      const sunsetRaw = times.sunset;

      // Format to user's 12h/24h preference
      const fajr = ClockFormatHelper.reformat(fajrRaw);
      const dhuhr = ClockFormatHelper.reformat(dhuhrRaw);
      const asr = ClockFormatHelper.reformat(asrRaw);
      const maghrib = ClockFormatHelper.reformat(maghribRaw);
      const isha = ClockFormatHelper.reformat(ishaRaw);
      const imsak = ClockFormatHelper.reformat(imsakRaw);
      const sunrise = ClockFormatHelper.reformat(sunriseRaw);
      const sunset = ClockFormatHelper.reformat(sunsetRaw);

      const nowMin: number = new Date().getHours() * 60 + new Date().getMinutes();
      const ids: string[] = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
      // --- APPLY JUMMAH ALTERNATE ---
      const isFriday = new Date().getDay() === 5;
      const dhuhrKey = isFriday ? 'prayer_jummah' : 'prayer_dhuhr';
      const names: string[] = [
        L.get('prayer_fajr', lang),
        L.get(dhuhrKey, lang),
        L.get('prayer_asr', lang),
        L.get('prayer_maghrib', lang),
        L.get('prayer_isha', lang)
      ];
      const rawArr: string[] = [fajrRaw, dhuhrRaw, asrRaw, maghribRaw, ishaRaw];
      const timeArr: string[] = [fajr, dhuhr, asr, maghrib, isha];

      // Determine Next & Current Prayer
      let nextIdx: number = -1;
      let currentIdx: number = 4; // Default to Isha if before Fajr
      let isCurrentYesterday = false;

      for (let i = 0; i < rawArr.length; i++) {
        const mins = PrayerManager.timeToMinutes(rawArr[i]);
        if (mins > nowMin) {
          nextIdx = i;
          break;
        } else {
          currentIdx = i;
        }
      }

      let isTomorrow = false;
      if (nextIdx === -1) {
        nextIdx = 0; // Tomorrow's Fajr
        isTomorrow = true;
      }

      // Smart Current Prayer Handling (Before Fajr)
      if (currentIdx === 4 && nowMin < PrayerManager.timeToMinutes(rawArr[0])) {
        isCurrentYesterday = true;
      }

      // Calculate Countdown
      let minsUntil = PrayerManager.timeToMinutes(rawArr[nextIdx]) - nowMin;
      if (isTomorrow) {
        minsUntil += 1440;
      }

      const h = Math.floor(minsUntil / 60);
      const m = minsUntil % 60;

      const parts: string[] = [];
      if (h > 0) {
        parts.push(`${h} ${L.get('hours_short', lang)}`);
      }
      if (m > 0) {
        parts.push(`${m} ${L.get('minutes_short', lang)}`);
      }

      const duration = parts.join(' ');
      const countdown = duration.length > 0
        ? `${L.get('countdown_prefix', lang)} ${duration}`
        : L.get('countdown_now', lang);

      // Calculate Progress Bar (Between Fajr and Isha)
      const fajrMin = PrayerManager.timeToMinutes(rawArr[0]);
      const ishaMin = PrayerManager.timeToMinutes(rawArr[4]);
      let progress = 0;
      if (nowMin >= ishaMin) {
        progress = 100;
      } else if (nowMin > fajrMin) {
        progress = Math.round(((nowMin - fajrMin) / (ishaMin - fajrMin)) * 100);
      }

      // Ramadan Context
      const ramadanInfo = RamadanHelper.getRamadanInfo(hijriOffset);
      const isRamadan = ramadanInfo !== null && ramadanInfo.isRamadanNow;

      const hijriStr: string = DateHelper.getFormattedHijriDateFor(new Date());

      const out: Record<string, Object> = {};
      out.dimension = dimension;
      out.city = city;
      out.hijriDate = hijriStr;
      out.lang = lang;

      out.nextId = ids[nextIdx];
      out.nextName = names[nextIdx];
      out.nextTime = timeArr[nextIdx];
      out.countdown = countdown;

      out.currentName = names[currentIdx];
      out.currentTime = timeArr[currentIdx];

      // New Fields for UI
      out.isCurrentYesterday = isCurrentYesterday;
      out.lblYesterday = L.get('yesterday', lang);
      out.progressPercent = progress;

      out.fajrName = names[0];
      out.fajrTime = fajr;
      out.dhuhrName = names[1];
      out.dhuhrTime = dhuhr;
      out.asrName = names[2];
      out.asrTime = asr;
      out.maghribName = names[3];
      out.maghribTime = maghrib;
      out.ishaName = names[4];
      out.ishaTime = isha;

      // Context Data for 4x4
      out.isRamadan = isRamadan;
      if (isRamadan) {
        out.contextLabel1 = L.get('export_sahur', lang);
        out.contextTime1 = imsak;
        out.contextLabel2 = L.get('export_iftar', lang);
        out.contextTime2 = maghrib;
      } else {
        out.contextLabel1 = L.get('timing_sunrise', lang);
        out.contextTime1 = sunrise;
        out.contextLabel2 = L.get('timing_sunset', lang);
        out.contextTime2 = sunset;
      }

      out.error = '';
      return out;
    } catch (e) {
      const err = e as Error;
      AppLogger.error('WidgetDataBuilder', `build EXCEPTION: ${err.message}`);
      return WidgetDataBuilder.errorData(dimension, 'Calc error');
    }
  }

  static async buildRamadanWidget(dimension: string, currentLang?: string): Promise<Record<string, Object>> {
    try {
      await PreferencesHelper.reloadFromDisk();

      let lang: string = currentLang ?? '';
      const override = await PreferencesHelper.getString(STORAGE_KEY_LANGUAGE_OVERRIDE, 'system');

      if (override === 'system') {
        lang = L.matchSystemLocale();
      } else if (override.length > 0) {
        lang = override;
      } else if (lang.length === 0) {
        lang = await PreferencesHelper.getString(STORAGE_KEY_LANGUAGE, 'en');
      }

      const settings: LoadedSettings = await SettingsHelper.loadAll();
      const mode: string = await SettingsHelper.getLocationMode();
      const hijriOffset: number = await SettingsHelper.getHijriOffset();

      let lat = 0, lng = 0;
      let city: string = '—';

      if (mode === 'Manual') {
        const manual = await SettingsHelper.getManualCoords();
        lat = manual.lat;
        lng = manual.lng;
        city = OfflineCityLookup.translateCityName(manual.cityName || 'DEFAULT LOCATION', lang);
      } else {
        const cached = await LocationCache.load();
        if (cached) {
          lat = cached.latitude;
          lng = cached.longitude;
          city = OfflineCityLookup.translateCityName(cached.cityName, lang);
        }
      }

      if (lat === 0 && lng === 0) {
        return WidgetDataBuilder.errorData(dimension, 'Set location in app');
      }

      // --- Check if it is currently Ramadan ---
      const ramadanInfo = RamadanHelper.getRamadanInfo(hijriOffset);
      const isRamadan = ramadanInfo !== null && ramadanInfo.isRamadanNow;

      const prevLang = AppStorage.get<string>(STORAGE_KEY_LANGUAGE);
      AppStorage.setOrCreate(STORAGE_KEY_LANGUAGE, lang);
      const hijriStr: string = DateHelper.getFormattedHijriDateFor(new Date());
      AppStorage.setOrCreate(STORAGE_KEY_LANGUAGE, prevLang);

      const out: Record<string, Object> = {};
      out.dimension = dimension;
      out.city = city;
      out.hijriDate = hijriStr;
      out.lang = lang;
      out.isRtl = L.isRtlLang(lang);
      out.isRamadan = isRamadan;
      out.error = '';

      // --- If NOT Ramadan, return early with notification payload ---
      if (!isRamadan) {
        out.targetName = L.get('ramadan_card_title', lang);
        out.countdown = ramadanInfo !== null
          ? `${ramadanInfo.daysUntilStart} ${L.get('home_days', lang)}`
          : L.get('coming_soon', lang);
        out.imsak = '--:--';
        out.iftar = '--:--';
        out.fajr = '--:--';
        out.targetTime = '';
        out.lblSahur = L.get('export_sahur', lang);
        out.lblIftar = L.get('export_iftar', lang);
        return out;
      }

      // --- Proceed with normal Ramadan calculation ---
      const highLat: HighLatitudeRule = await SettingsHelper.getHighLatRule();
      const advanced: AdvancedCalcSettings = await SettingsHelper.getAdvancedCalcSettings();
      const offsets: PrayerOffsets = await SettingsHelper.getPrayerOffsets();

      const times = PrayerTimeCalculator.calculateWithDeviceTimezone(
        new Date(), lat, lng, settings.method, settings.asr, highLat, advanced
      );

      const imsakRaw = PrayerManager.offsetTime(times.imsak, offsets.fajr);
      const maghribRaw = PrayerManager.offsetTime(times.maghrib, offsets.maghrib);
      const fajrRaw = PrayerManager.offsetTime(times.fajr, offsets.fajr);

      const imsak = ClockFormatHelper.reformat(imsakRaw);
      const iftar = ClockFormatHelper.reformat(maghribRaw);
      const fajr = ClockFormatHelper.reformat(fajrRaw);

      const nowMin = new Date().getHours() * 60 + new Date().getMinutes();
      const imsakMin = PrayerManager.timeToMinutes(imsakRaw);
      const maghribMin = PrayerManager.timeToMinutes(maghribRaw);

      let targetName = '';
      let targetTime = '';
      let targetMin = 0;
      let isNextDay = false;

      if (nowMin < maghribMin && nowMin >= imsakMin) {
        targetName = L.get('export_iftar', lang);
        targetTime = iftar;
        targetMin = maghribMin;
      } else if (nowMin < imsakMin) {
        targetName = L.get('export_sahur', lang);
        targetTime = imsak;
        targetMin = imsakMin;
      } else {
        targetName = L.get('export_sahur', lang);
        targetTime = imsak;
        targetMin = imsakMin;
        isNextDay = true;
      }

      let minsUntil = targetMin - nowMin;
      if (isNextDay) {
        minsUntil += 1440;
      }
      const h = Math.floor(minsUntil / 60);
      const m = minsUntil % 60;
      const parts: string[] = [];
      if (h > 0) {
        parts.push(`${h} ${L.get('hours_short', lang)}`);
      }
      if (m > 0) {
        parts.push(`${m} ${L.get('minutes_short', lang)}`);
      }
      const duration = parts.join(' ');

      const countdown = duration.length > 0
        ? `${L.get('countdown_prefix', lang)} ${duration}`
        : L.get('countdown_now', lang);

      out.imsak = imsak;
      out.iftar = iftar;
      out.fajr = fajr;
      out.targetName = targetName;
      out.targetTime = targetTime;
      out.countdown = countdown;
      out.lblSahur = L.get('export_sahur', lang);
      out.lblIftar = L.get('export_iftar', lang);

      return out;
    } catch (e) {
      return WidgetDataBuilder.errorData(dimension, 'Calc error');
    }
  }

  static errorData(dimension: string, msg: string): Record<string, Object> {
    const out: Record<string, Object> = {};
    out.dimension = dimension;
    out.city = '—';
    out.hijriDate = '—';
    out.lang = 'en';

    // ---- Prayer widget ----
    out.nextId = '—';
    out.nextName = '—';
    out.nextTime = '--:--';
    out.countdown = '';
    out.currentName = '—';
    out.currentTime = '--:--';
    out.isCurrentYesterday = false;
    out.lblYesterday = 'Yesterday';
    out.progressPercent = 0;

    out.fajrName = 'Fajr';
    out.fajrTime = '--:--';
    out.dhuhrName = 'Dhuhr';
    out.dhuhrTime = '--:--';
    out.asrName = 'Asr';
    out.asrTime = '--:--';
    out.maghribName = 'Maghrib';
    out.maghribTime = '--:--';
    out.ishaName = 'Isha';
    out.ishaTime = '--:--';

    out.isRamadan = false;
    out.contextLabel1 = '—';
    out.contextTime1 = '--:--';
    out.contextLabel2 = '—';
    out.contextTime2 = '--:--';

    // ---- Ramadan widget ----
    // Every field RamadanWidget declares as @LocalStorageProp must
    // be present here, so a fresh widget that lands in error state
    // on first bind gets deterministic placeholders instead of the
    // widget file's hardcoded initialisers (FormExtensionAbility
    // does not guarantee LocalStorageProp initialisers run before
    // the first formProvider.updateForm call).
    out.imsak = '--:--';
    out.iftar = '--:--';
    out.fajr = '--:--';
    out.targetName = '—';
    out.targetTime = '--:--';
    out.lblSahur = 'Sahur'; // added by H3
    out.lblIftar = 'Iftar'; // added by H3

    out.error = msg;
    return out;
  }

  static toFormBindingData(data: Record<string, Object>): formBindingData.FormBindingData {
    return formBindingData.createFormBindingData(data);
  }
}