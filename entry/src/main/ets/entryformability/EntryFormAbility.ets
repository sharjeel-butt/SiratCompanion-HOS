import { formBindingData, FormExtensionAbility, formProvider } from '@kit.FormKit';
import { common, Want } from '@kit.AbilityKit';
import { Configuration } from '@ohos.app.ability.Configuration'; // Required for API 11+
import { PreferencesHelper } from '../core/PreferencesHelper';
import { WidgetDataBuilder } from '../widgets/WidgetDataBuilder';
import { STORAGE_KEY_WIDGET_DIM_PREFIX, STORAGE_KEY_WIDGET_FORM_IDS, WidgetHelper } from '../widgets/WidgetHelper';
import { STORAGE_KEY_LANGUAGE, STORAGE_KEY_LANGUAGE_OVERRIDE, STORAGE_KEY_TIME_FORMAT } from '../core/StorageKeys';
import { L } from '../i18n/LocalizationHelper';

const FORM_DIM_KEY = 'ohos.extra.param.key.form_dimension';
const FORM_ID_KEYS: string[] = [
  'ohos.extra.param.key.form_id',
  'ohos.extra.param.key.form_identity'
];
const TAG = 'EntryFormAbility';

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const ctx: common.Context = this.context;

    // 1. Initialize context and apply the preferred language
    L.init(ctx);
    const savedOverride: string = AppStorage.get<string>(STORAGE_KEY_LANGUAGE_OVERRIDE) ?? 'system';
    L.applySystemLanguage(savedOverride);

    PreferencesHelper.init(ctx).catch((): void => {
    });

    const dimension: string = EntryFormAbility.dimensionFromWant(want);
    const formId: string = EntryFormAbility.formIdFromWant(want);

    const retryDelays: number[] = [600, 1500, 3000];
    for (const d of retryDelays) {
      setTimeout((): void => {
        EntryFormAbility.doAsyncRefresh(ctx, formId, dimension).catch((e: Error) => {
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
      await EntryFormAbility.doAsyncRefresh(ctx, formId, dim);
    }).catch((e: Error): void => {
      console.error(`[${TAG}] onUpdateForm init failed: ${e.message}`);
    });
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    console.info(`[${TAG}] System config updated, refreshing widgets...`);
    WidgetHelper.refreshAll().catch((e: Error) => {
      console.error(`[${TAG}] Config refresh failed: ${e.message}`);
    });
  }

  private static async doAsyncRefresh(
    ctx: common.Context,
    formId: string,
    dimension: string
  ): Promise<void> {
    try {
      await PreferencesHelper.init(ctx);

      const savedOverride: string = await PreferencesHelper.getString(STORAGE_KEY_LANGUAGE_OVERRIDE, 'system');
      const savedLang: string = await PreferencesHelper.getString(STORAGE_KEY_LANGUAGE, 'en');
      const savedFormat: string = await PreferencesHelper.getString(STORAGE_KEY_TIME_FORMAT, 'System');

      AppStorage.setOrCreate(STORAGE_KEY_LANGUAGE_OVERRIDE, savedOverride);
      AppStorage.setOrCreate(STORAGE_KEY_LANGUAGE, savedLang);
      AppStorage.setOrCreate(STORAGE_KEY_TIME_FORMAT, savedFormat);

      // CRITICAL: Apply language to context before building data and rendering
      L.init(ctx);
      L.applySystemLanguage(savedOverride);

      if (formId.length === 0) {
        return;
      }

      await EntryFormAbility.addFormId(formId);
      await PreferencesHelper.setString(STORAGE_KEY_WIDGET_DIM_PREFIX + formId, dimension);

      // Pass the resolved language to the builder
      const data: Record<string, Object> = await WidgetDataBuilder.build(dimension, savedLang);
      const fb = WidgetDataBuilder.toFormBindingData(data);

      await formProvider.updateForm(formId, fb);
      console.info(`[${TAG}] updateForm SUCCESS formId='${formId}' dim='${dimension}'`);
    } catch (e) {
      console.error(`[${TAG}] doAsyncRefresh EXCEPTION: ${(e as Error).message}`);
    }
  }

  // ----------------------------------------------------------
  // FORM ID ARRAY MANAGEMENT
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
        console.info(`[${TAG}] addFormId: now ${JSON.stringify(ids)}`);
      }
    } catch (e) {
      // swallow
    }
  }

  private static async removeFormId(formId: string): Promise<void> {
    if (formId.length === 0) {
      return;
    }
    try {
      const ids: string[] = await EntryFormAbility.readFormIds();
      const filtered: string[] = ids.filter((id: string) => id !== formId);
      await PreferencesHelper.setString(STORAGE_KEY_WIDGET_FORM_IDS, JSON.stringify(filtered));
      await PreferencesHelper.setString(STORAGE_KEY_WIDGET_DIM_PREFIX + formId, '');
      console.info(`[${TAG}] removeFormId: now ${JSON.stringify(filtered)}`);
    } catch (e) {
      // swallow
    }
  }

  private static async readFormIds(): Promise<string[]> {
    try {
      const json: string = await PreferencesHelper.getString(
        STORAGE_KEY_WIDGET_FORM_IDS, '[]'
      );
      const parsed: Object = JSON.parse(json);
      if (!Array.isArray(parsed)) {
        return [];
      }
      return parsed as string[];
    } catch (e) {
      return [];
    }
  }

  // ----------------------------------------------------------
  // WANT PARSING
  // ----------------------------------------------------------

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
    if (typeof raw === 'string') {
      const s: string = raw as string;
      if (s.indexOf('4*4') >= 0) {
        return '4*4';
      }
      if (s.indexOf('2*4') >= 0) {
        return '2*4';
      }
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

  private static placeholderData(dimension: string): Record<string, Object> {
    return WidgetDataBuilder.errorData(dimension, '');
  }
}