import { LoadedSettings, PrayerOffsets, SettingsHelper } from '../settings/SettingsHelper';
import { LocationCache } from '../location/LocationCache';
import {
  AdvancedCalcSettings,
  MidnightMethod,
  PolarResolution,
  RoundingMethod,
  Shafaq
} from '../prayer/AdvancedCalcModels';
import { DailyPrayerTimes, HighLatitudeRule, PrayerTimeCalculator } from '../prayer/PrayerTimeCalculator';
import { PrayerManager } from '../prayer/PrayerManager';
import { DateHelper } from '../hijricalendar/DateUtils';
import { L } from '../i18n/LocalizationHelper';
import { STORAGE_KEY_LANGUAGE, STORAGE_KEY_LANGUAGE_OVERRIDE } from '../core/StorageKeys';
import { ClockFormatHelper } from '../core/ClockFormat';
import { AppLogger } from '../core/AppLogger';
import { formBindingData } from '@kit.FormKit';
import { PreferencesHelper } from '../core/PreferencesHelper';

export class WidgetDataBuilder {
  static async build(dimension: string, currentLang?: string): Promise<Record<string, Object>> {
    try {
      let lang: string = currentLang ?? '';

      // If no language passed, fetch from disk and resolve "System"
      if (lang.length === 0) {
        await PreferencesHelper.reloadFromDisk();
        const override = await PreferencesHelper.getString(STORAGE_KEY_LANGUAGE_OVERRIDE, 'system');
        if (override === 'system') {
          lang = L.matchSystemLocale();
        } else {
          lang = await PreferencesHelper.getString(STORAGE_KEY_LANGUAGE, 'en');
        }
      }

      // const lang = currentLang ?? 'en';

      const settings: LoadedSettings = await SettingsHelper.loadAll();
      const mode: string = await SettingsHelper.getLocationMode();
      const highLat: HighLatitudeRule = await SettingsHelper.getHighLatRule();
      const advanced: AdvancedCalcSettings = await SettingsHelper.getAdvancedCalcSettings();
      const offsets: PrayerOffsets = await SettingsHelper.getPrayerOffsets();

      let lat: number = 0;
      let lng: number = 0;
      let city: string = '—';

      if (mode === 'Manual') {
        const manual = await SettingsHelper.getManualCoords();
        lat = manual.lat;
        lng = manual.lng;
        city = manual.cityName.length > 0 ? manual.cityName : 'Manual';
      } else {
        const cached = await LocationCache.load();
        if (cached !== null) {
          lat = cached.latitude;
          lng = cached.longitude;
          city = cached.cityName;
        }
      }

      if (lat === 0 && lng === 0) {
        return WidgetDataBuilder.errorData(dimension, 'Set location in app');
      }

      const times: DailyPrayerTimes = PrayerTimeCalculator.calculateWithDeviceTimezone(
        new Date(), lat, lng, settings.method, settings.asr, highLat, advanced
      );

      const fajrRaw: string = PrayerManager.offsetTime(times.fajr, offsets.fajr);
      const dhuhrRaw: string = PrayerManager.offsetTime(times.dhuhr, offsets.dhuhr);
      const asrRaw: string = PrayerManager.offsetTime(times.asr, offsets.asr);
      const maghribRaw: string = PrayerManager.offsetTime(times.maghrib, offsets.maghrib);
      const ishaRaw: string = PrayerManager.offsetTime(times.isha, offsets.isha);

      const fajr: string = ClockFormatHelper.reformat(fajrRaw);
      const dhuhr: string = ClockFormatHelper.reformat(dhuhrRaw);
      const asr: string = ClockFormatHelper.reformat(asrRaw);
      const maghrib: string = ClockFormatHelper.reformat(maghribRaw);
      const isha: string = ClockFormatHelper.reformat(ishaRaw);

      const nowMin: number = new Date().getHours() * 60 + new Date().getMinutes();

      const ids: string[] = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
      const names: string[] = [
        L.get('prayer_fajr', lang),
        L.get('prayer_dhuhr', lang),
        L.get('prayer_asr', lang),
        L.get('prayer_maghrib', lang),
        L.get('prayer_isha', lang)
      ];
      const rawArr: string[] = [fajrRaw, dhuhrRaw, asrRaw, maghribRaw, ishaRaw];
      const timeArr: string[] = [fajr, dhuhr, asr, maghrib, isha];

      let nextIdx: number = 4;
      let currentIdx: number = -1;

      for (let i = 0; i < rawArr.length; i++) {
        const mins: number = PrayerManager.timeToMinutes(rawArr[i]);
        if (mins > nowMin) {
          nextIdx = i;
          break;
        } else {
          currentIdx = i;
        }
      }

      if (currentIdx === -1) {
        currentIdx = 4;
      }

      const hijriStr: string = DateHelper.getFormattedHijriDateFor(new Date());

      const methodLabel = SettingsHelper.getCalcMethodShortLabel(settings.method);
      const asrLabel = SettingsHelper.getAsrRuleShortLabel(settings.asr);
      const highLatLabel = SettingsHelper.getHighLatRuleLabel(highLat);

      let roundingLabel = L.get('rounding_nearest', lang);
      if (advanced.rounding === RoundingMethod.UP) {
        roundingLabel =
          L.get('rounding_up', lang);
      } else if (advanced.rounding === RoundingMethod.NONE) {
        roundingLabel =
          L.get('rounding_none', lang);
      }

      let midnightLabel = advanced.midnight === MidnightMethod.STANDARD
        ? L.get('midnight_standard', lang)
        : L.get('midnight_jafari', lang);

      let polarLabel = L.get('polar_unresolved', lang);
      if (advanced.polarResolution === PolarResolution.AQRAB_BALAD) {
        polarLabel =
          L.get('polar_aqrab_balad', lang);
      } else if (advanced.polarResolution === PolarResolution.AQRAB_YAUM) {
        polarLabel =
          L.get('polar_aqrab_yaum', lang);
      }

      let shafaqLabel = L.get('shafaq_general', lang);
      if (advanced.shafaq === Shafaq.AHMER) {
        shafaqLabel = L.get('shafaq_ahmer', lang);
      } else if (advanced.shafaq ===
        Shafaq.ABYAD) {
        shafaqLabel = L.get('shafaq_abyad', lang);
      }

      const out: Record<string, Object> = {};
      out.dimension = dimension;
      out.city = city;
      out.hijriDate = hijriStr;

      out.nextId = ids[nextIdx];
      out.nextName = names[nextIdx];
      out.nextTime = timeArr[nextIdx];

      out.currentName = names[currentIdx];
      out.currentTime = timeArr[currentIdx];

      out.methodLabel = methodLabel;
      out.asrLabel = asrLabel;
      out.highLatLabel = highLatLabel;
      out.roundingLabel = roundingLabel;
      out.midnightLabel = midnightLabel;
      out.polarLabel = polarLabel;
      out.shafaqLabel = shafaqLabel;

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

      out.isRtl = L.isRtlLang(lang);
      out.lblCurrent = L.get('current_prayer', lang);
      out.lblNext = L.get('next_prayer', lang);
      out.lblMethod = L.get('convention', lang);
      out.lblMadhab = L.get('madhab', lang);
      out.lblHighLat = L.get('high_latitude', lang);
      out.lblRounding = L.get('rounding_method', lang);
      out.lblMidnight = L.get('midnight_method', lang);
      out.lblPolar = L.get('polar_resolution', lang);
      out.lblShafaq = L.get('shafaq', lang);
      out.lang = lang;
      out.error = '';
      AppLogger.info('WidgetDataBuilder', `Built widget for lang='${lang}', isRtl=${L.isRtlLang(lang)}`);
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
    out.nextId = '—';
    out.nextName = '—';
    out.nextTime = '--:--';
    out.currentName = '—';
    out.currentTime = '--:--';
    out.methodLabel = '—';
    out.asrLabel = '—';
    out.highLatLabel = '—';
    out.roundingLabel = '—';
    out.midnightLabel = '—';
    out.polarLabel = '—';
    out.shafaqLabel = '—';

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

    out.isRtl = false;
    out.lblCurrent = 'Current';
    out.lblNext = 'Next';
    out.lblMethod = 'Method';
    out.lblMadhab = 'Madhab';
    out.lblHighLat = 'High Lat';
    out.lblRounding = 'Rounding';
    out.lblMidnight = 'Midnight';
    out.lblPolar = 'Polar';
    out.lblShafaq = 'Shafaq';

    out.error = msg;

    return out;
  }

  static toFormBindingData(data: Record<string, Object>): formBindingData.FormBindingData {
    return formBindingData.createFormBindingData(data);
  }
}