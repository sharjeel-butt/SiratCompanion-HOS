import { AppLanguageJson } from './LanguageModels';
import { common } from '@kit.AbilityKit';
import { RawPaths } from '../core/common/RawPaths';
import { AppLogger } from '../core/app/AppLogger';
import { util } from '@kit.ArkTS';
import { i18n } from '@kit.LocalizationKit';


export class LanguageService {
  private static languages: AppLanguageJson[] = [];
  private static isLoaded: boolean = false;

  static async init(ctx: common.Context): Promise<void> {
    if (LanguageService.isLoaded) {
      return;
    }
    if (LanguageService.languages.length > 0) {
      return;
    }

    try {
      const raw = await ctx.resourceManager.getRawFileContent(
        RawPaths.APP_LANGS
      );

      LanguageService.languages =
        JSON.parse(
          util.TextDecoder.create().decodeToString(raw)
        ) as AppLanguageJson[];
      LanguageService.isLoaded = true;
    } catch (e) {
      AppLogger.error('LanguageService',
        `Failed to load languages: ${JSON.stringify(e)}`);
    }
  }

  static getAllLanguages(): AppLanguageJson[] {
    return LanguageService.languages;
  }

  static find(id: string): AppLanguageJson {
    const found = LanguageService.languages.find(l => l.id === id);

    if (found) {
      return found;
    }

    return {
      id: 'en',
      nameKey: 'lang_en',
      nativeName: 'English',
      rtl: false,
      isDefault: true
    };
  }

  static getDefaultLanguage(): AppLanguageJson {
    const found = LanguageService.languages.find(
      l => l.isDefault === true
    );

    return found ?? LanguageService.find('en');
  }

  static isRtl(id: string): boolean {
    return LanguageService.find(id).rtl;
  }

  static supports(id: string): boolean {
    return LanguageService.languages.some(
      l => l.id === id
    );
  }

  static defaultLanguage(): string {
    const found = LanguageService.languages.find(
      l => l.isDefault === true
    );

    if (found) {
      return found.id;
    }

    return 'en';
  }

  static systemLanguage(): string {
    try {
      const locale =
        i18n.System.getSystemLocale();

      const lang =
        locale.split('-')[0].toLowerCase();

      if (LanguageService.supports(lang)) {
        return lang;
      }
    } catch (_) {
    }

    return LanguageService.defaultLanguage();
  }
}