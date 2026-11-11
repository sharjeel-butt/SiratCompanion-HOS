import { formBindingData, FormExtensionAbility, formProvider } from '@kit.FormKit';
import { common, Want } from '@kit.AbilityKit';
import { Configuration } from '@ohos.app.ability.Configuration';
import { PreferencesHelper } from '../core/PreferencesHelper';
import { WidgetDataBuilder } from '../widgets/WidgetDataBuilder';
import {
  STORAGE_KEY_WIDGET_DIM_PREFIX,
  STORAGE_KEY_WIDGET_FORM_IDS,
  STORAGE_KEY_WIDGET_NAME_PREFIX,
  WidgetHelper
} from '../widgets/WidgetHelper';
import { STORAGE_KEY_LANGUAGE, STORAGE_KEY_LANGUAGE_OVERRIDE, STORAGE_KEY_TIME_FORMAT } from '../core/StorageKeys';
import { AppLanguage, L } from '../i18n/LocalizationHelper';
import { OfflineCityLookup } from '../location/OfflineCityLookup';
import { AppLogger } from '../core/AppLogger';

const FORM_DIM_KEY = 'ohos.extra.param.key.form_dimension';
const FORM_NAME_KEY = 'ohos.extra.param.key.form_name'; // NEW
const FORM_ID_KEYS: string[] = [
  'ohos.extra.param.key.form_id',
  'ohos.extra.param.key.form_identity'
];

const TAG = 'EntryFormAbility';

export default class EntryFormAbility extends FormExtensionAbility {
  private static async doAsyncRefresh(
    ctx: common.Context,
    formId: string,
    dimension: string,
    formName: string // Added parameter
  ): Promise<void> {
    try {
      await PreferencesHelper.init(ctx);

      const savedOverride: string = await PreferencesHelper.getString(STORAGE_KEY_LANGUAGE_OVERRIDE, 'system');
      const savedLang: string = await PreferencesHelper.getString(STORAGE_KEY_LANGUAGE, 'en');
      const savedFormat: string = await PreferencesHelper.getString(STORAGE_KEY_TIME_FORMAT, 'System');

      AppStorage.setOrCreate(STORAGE_KEY_LANGUAGE_OVERRIDE, savedOverride);
      AppStorage.setOrCreate(STORAGE_KEY_LANGUAGE, savedLang);
      AppStorage.setOrCreate(STORAGE_KEY_TIME_FORMAT, savedFormat);

      L.init(ctx);
      L.applySystemLanguage(savedOverride);
      await OfflineCityLookup.init(ctx);

      if (formId.length === 0) {
        return;
      }

      await EntryFormAbility.addFormId(formId);
      await PreferencesHelper.setString(STORAGE_KEY_WIDGET_DIM_PREFIX + formId, dimension);
      await PreferencesHelper.setString(STORAGE_KEY_WIDGET_NAME_PREFIX + formId, formName); // Save name

      // RENAMED variable from 'data' to 'widgetData' to prevent collision
      let widgetData: Record<string, Object>;

      if (formName === 'ramadan_widget') {
        widgetData = await WidgetDataBuilder.buildRamadanWidget(dimension, savedLang);
      } else if (formName === 'hijri_date_widget') {
        widgetData = await WidgetDataBuilder.buildDateWidget(ctx, dimension, savedLang); // <-- Pass ctx
      } else if (formName === 'event_widget') {
        widgetData = await WidgetDataBuilder.buildEventWidget(ctx, dimension, savedLang); // <-- Pass ctx
      } else if (formName === 'adhkar_widget') {
        widgetData = await WidgetDataBuilder.buildAdhkarWidget(ctx, dimension, savedLang); // <-- Pass ctx
      } else if (formName === 'tracker_widget') {
        widgetData = await WidgetDataBuilder.buildTrackerWidget(ctx, dimension, savedLang);
      } else {
        widgetData = await WidgetDataBuilder.build(dimension, savedLang);
      }

      const fb = WidgetDataBuilder.toFormBindingData(widgetData);
      await formProvider.updateForm(formId, fb);

      console.info(`[${TAG}] updateForm SUCCESS formId='${formId}' name='${formName}' dim='${dimension}'`);
    } catch (e) {
      console.error(`[${TAG}] doAsyncRefresh EXCEPTION: ${(e as Error).message}`);
    }
  }

  private static dimensionFromWant(want: Want): string {
    const params: Record<string, Object> | undefined = want.parameters;
    if (params === undefined) {
      return '2*2';
    }
    const raw: Object | undefined = params[FORM_DIM_KEY];
    if (typeof raw === 'number') {
      const n: number = raw as number;
      if (n === 4) {
        return '4*4';
      }
      if (n === 3) {
        return '2*4';
      }
      return '2*2';
    }
    return '2*2';
  }

  private static formIdFromWant(want: Want): string {
    const params: Record<string, Object> | undefined = want.parameters;
    if (params === undefined) {
      return '';
    }
    for (const key of FORM_ID_KEYS) {
      const raw: Object | undefined = params[key];
      if (typeof raw === 'string') {
        const s: string = raw as string;
        if (s.length > 0) {
          return s;
        }
      }
      if (typeof raw === 'number') {
        return (raw as number).toString();
      }
    }
    return '';
  }

  // NEW HELPER
  private static formNameFromWant(want: Want): string {
    const params: Record<string, Object> | undefined = want.parameters;
    if (params === undefined) {
      return 'prayer_widget';
    }
    const raw: Object | undefined = params[FORM_NAME_KEY];
    if (typeof raw === 'string') {
      return raw as string;
    }
    return 'prayer_widget'; // Default fallback
  }

  // ----------------------------------------------------------
  // WANT PARSING
  // ----------------------------------------------------------

  private static async addFormId(formId: string): Promise<void> {
    if (formId.length === 0) {
      return;
    }
    try {
      const ids: string[] = await EntryFormAbility.readFormIds();
      if (ids.indexOf(formId) === -1) {
        ids.push(formId);
        await PreferencesHelper.setString(STORAGE_KEY_WIDGET_FORM_IDS, JSON.stringify(ids));
      }
    } catch (e) { /* swallow */
    }
  }

  private static async readFormIds(): Promise<string[]> {
    try {
      const json: string = await PreferencesHelper.getString(STORAGE_KEY_WIDGET_FORM_IDS, '[]');
      const parsed: Object = JSON.parse(json);
      if (!Array.isArray(parsed)) {
        return [];
      }
      return parsed as string[];
    } catch (e) {
      return [];
    }
  }

  private static placeholderData(dimension: string): Record<string, Object> {
    return WidgetDataBuilder.errorData(dimension, '');
  }

  // ----------------------------------------------------------
  // FORM ID ARRAY MANAGEMENT
  // ----------------------------------------------------------

  onAddForm(want: Want): formBindingData.FormBindingData {
    const ctx: common.Context = this.context;

    L.init(ctx);
    const savedOverride: string = AppStorage.get<string>(STORAGE_KEY_LANGUAGE_OVERRIDE) ?? 'system';
    L.applySystemLanguage(savedOverride);

    PreferencesHelper.init(ctx).catch((): void => {
    });

    const dimension: string = EntryFormAbility.dimensionFromWant(want);
    const formId: string = EntryFormAbility.formIdFromWant(want);
    const formName: string = EntryFormAbility.formNameFromWant(want); // Extract name

    const retryDelays: number[] = [600, 1500, 3000];
    for (const d of retryDelays) {
      setTimeout((): void => {
        EntryFormAbility.doAsyncRefresh(ctx, formId, dimension, formName).catch((e: Error) => {
          console.error(`[${TAG}] refresh@${d}ms failed: ${e.message}`);
        });
      }, d);
    }

    const placeholderData: Record<string, Object> = EntryFormAbility.placeholderData(dimension);
    return WidgetDataBuilder.toFormBindingData(placeholderData);
  }

  onUpdateForm(formId: string): void {
    const ctx: common.Context = this.context;

    L.init(ctx);
    const savedOverride: string = AppStorage.get<string>(STORAGE_KEY_LANGUAGE_OVERRIDE) ?? 'system';
    L.applySystemLanguage(savedOverride);

    PreferencesHelper.init(ctx).then(async (): Promise<void> => {
      const dim: string = await PreferencesHelper.getString(
        STORAGE_KEY_WIDGET_DIM_PREFIX + formId, '2*2'
      );
      // Read the saved formName from preferences
      const formName: string = await PreferencesHelper.getString(
        STORAGE_KEY_WIDGET_NAME_PREFIX + formId, 'prayer_widget'
      );

      await EntryFormAbility.doAsyncRefresh(ctx, formId, dim, formName);
    }).catch((e: Error): void => {
      console.error(`[${TAG}] onUpdateForm init failed: ${e.message}`);
    });
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    console.info(`[${TAG}] System config updated, refreshing widgets...`);
    this.reResolveSystemLanguage();
    WidgetHelper.refreshAll().catch((e: Error) => {
      console.error(`[${TAG}] Config refresh failed: ${e.message}`);
    });
  }

  /**
   * If the user picked "Auto Detect" as their language, re-check
   * the device locale every time the app foregrounds or the OS
   * configuration changes.
   */
  private reResolveSystemLanguage(): void {
    const override = AppStorage.get<string>(STORAGE_KEY_LANGUAGE_OVERRIDE);
    if (override !== AppLanguage.SYSTEM) {
      return;
    }
    const current = AppStorage.get<string>(STORAGE_KEY_LANGUAGE);
    const resolved = L.matchSystemLocale();

    if (current !== resolved) {
      AppLogger.info('EntryAbility', `System language changed → '${resolved}'`);
      AppStorage.setOrCreate(STORAGE_KEY_LANGUAGE, resolved);
      PreferencesHelper.setString(STORAGE_KEY_LANGUAGE, resolved);
      L.applySystemLanguage(override);
    }
  }
}