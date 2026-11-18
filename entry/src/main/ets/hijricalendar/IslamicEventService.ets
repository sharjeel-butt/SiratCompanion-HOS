// entry/src/main/ets/hijricalendar/IslamicEventService.ets

import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { AppLogger } from '../core/AppLogger';
import { RawPaths } from '../core/RawPaths';
import { EventRecurrence, EventSect, IslamicEvent, IslamicEventSource } from './DateModels';

// Interface for the JSON structure
interface EventTranslation {
  name: string;
  desc: string;
}

interface EventJsonItem {
  key: string;
  month: number;
  day: number;
  recurrence: string;
  sect: string;
  translations: Record<string, EventTranslation>;
  sources?: IslamicEventSource[];
  duas?: string[];
  recitations?: string[];
  migration_status?: string;
}

export class IslamicEventService {
  private static events: EventJsonItem[] = [];
  private static isLoaded: boolean = false;

  static async init(context: common.Context): Promise<void> {
    if (IslamicEventService.isLoaded) {
      return;
    }

    try {
      const mgr = context.resourceManager;
      const data = await mgr.getRawFileContent(RawPaths.EVENTS);
      const jsonStr = util.TextDecoder.create('utf-8').decodeToString(data);
      IslamicEventService.events = JSON.parse(jsonStr) as EventJsonItem[];
      IslamicEventService.isLoaded = true;
      AppLogger.info('IslamicEventService', `Loaded ${IslamicEventService.events.length} Islamic events`);
    } catch (e) {
      AppLogger.error('IslamicEventService', `Failed to load islamic_events.json: ${JSON.stringify(e)}`);
    }
  }

  static getEvents(perspective: string): IslamicEvent[] {
    const out: IslamicEvent[] = [];
    for (const item of IslamicEventService.events) {
      if (IslamicEventService.matchesPerspective(item.sect, perspective)) {
        out.push({
          key: item.key,
          name: item.translations['en']?.name || item.key,
          month: item.month,
          day: item.day,
          recurrence: item.recurrence as EventRecurrence,
          sect: item.sect as EventSect,
          sources: item.sources ?? [],
          duas: item.duas ?? [],
          recitations: item.recitations ?? [],
          migrationStatus: item.migration_status ?? ''
        });
      }
    }
    return out;
  }

  // New accessors for citation UI
  static getEventSources(key: string): IslamicEventSource[] {
    const e = IslamicEventService.events.find(x => x.key === key);
    return e?.sources ?? [];
  }

  static getEventDuas(key: string): string[] {
    const e = IslamicEventService.events.find(x => x.key === key);
    return e?.duas ?? [];
  }

  static getEventRecitations(key: string): string[] {
    const e = IslamicEventService.events.find(x => x.key === key);
    return e?.recitations ?? [];
  }

  static getEventMigrationStatus(key: string): string {
    const e = IslamicEventService.events.find(x => x.key === key);
    return e?.migration_status ?? '';
  }

  /**
   * Gets the localized event name.
   */
  static getEventName(key: string, lang: string): string {
    const event = IslamicEventService.events.find(e => e.key === key);
    if (!event) {
      return key;
    }

    const trans = event.translations[lang] || event.translations['en'];
    return trans ? trans.name : key;
  }

  /**
   * Gets the localized event description.
   */
  static getEventDesc(key: string, lang: string): string {
    const event = IslamicEventService.events.find(e => e.key === key);
    if (!event) {
      return '';
    }

    const trans = event.translations[lang] || event.translations['en'];
    return trans ? trans.desc : '';
  }

  private static matchesPerspective(sect: string, perspective: string): boolean {
    if (perspective === 'universal') {
      return sect === 'universal';
    }
    if (perspective === 'sunni') {
      return sect === 'universal' || sect === 'sunni';
    }
    if (perspective === 'shia') {
      return sect === 'universal' || sect === 'shia';
    }
    return true; // 'all'
  }
}