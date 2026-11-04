import { formBindingData, formProvider } from '@kit.FormKit';
import { PreferencesHelper } from '../core/PreferencesHelper';
import { WidgetDataBuilder } from './WidgetDataBuilder';
import { AppLogger } from '../core/AppLogger';

export const STORAGE_KEY_WIDGET_FORM_IDS = 'widget_form_ids';

export const STORAGE_KEY_WIDGET_DIM_PREFIX = 'widget_dim_';

const TAG = 'WidgetHelper';

export class WidgetHelper {
  private static debounceTimer: number = -1;

  static async refreshAll(): Promise<void> {
    try {
      const formIds: string[] = await WidgetHelper.readFormIds();
      if (formIds.length === 0) {
        AppLogger.info(TAG, 'No widgets registered — skipping');
        return;
      }
      AppLogger.info(TAG, `Refreshing ${formIds.length} widget(s)`);

      const alive: string[] = [];
      for (const formId of formIds) {
        const ok: boolean = await WidgetHelper.refreshOne(formId);
        if (ok) {
          alive.push(formId);
        } else {
          AppLogger.warn(TAG, `Widget ${formId} is stale — pruning from store`);
        }
      }

      if (alive.length !== formIds.length) {
        await PreferencesHelper.setString(
          STORAGE_KEY_WIDGET_FORM_IDS,
          JSON.stringify(alive)
        );
        AppLogger.info(TAG,
          `Pruned ${formIds.length - alive.length} stale ID(s); ${alive.length} remain`);
      }
    } catch (e) {
      AppLogger.warn(TAG, `refreshAll failed: ${(e as Error).message}`);
    }
  }

  static refreshAllDebounced(): void {
    if (WidgetHelper.debounceTimer !== -1) {
      clearTimeout(WidgetHelper.debounceTimer);
    }
    WidgetHelper.debounceTimer = setTimeout((): void => {
      WidgetHelper.debounceTimer = -1;
      WidgetHelper.refreshAll().catch((): void => {
        // swallow
      });
    }, 400);
  }

  static async refreshOne(formId: string): Promise<boolean> {
    try {
      const dim: string = await PreferencesHelper.getString(
        STORAGE_KEY_WIDGET_DIM_PREFIX + formId, '2*2'
      );
      const lang = AppStorage.get<string>('app_language') ?? 'en';
      const data: Record<string, Object> = await WidgetDataBuilder.build(dim, lang);
      const fb: formBindingData.FormBindingData =
        WidgetDataBuilder.toFormBindingData(data);
      await formProvider.updateForm(formId, fb);
      return true;
    } catch (e) {
      return false;
    }
  }

  static async readFormIds(): Promise<string[]> {
    try {
      await PreferencesHelper.reloadFromDisk();
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
}