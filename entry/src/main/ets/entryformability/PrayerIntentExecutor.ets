import { insightIntent, InsightIntentExecutor } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { WidgetDataBuilder } from '../widgets/WidgetDataBuilder';

export default class PrayerIntentExecutor extends InsightIntentExecutor {
  async onExecuteInUIAbilityForegroundMode(
    name: string,
    param: Record<string, Object>,
    pageLoader: window.WindowStage
  ): Promise<insightIntent.ExecuteResult> {
    if (name === 'GetPrayerTimes') {
      try {
        // 1. Build the latest widget data (calculates prayer times based on current location)
        const data: Record<string, Object> = await WidgetDataBuilder.build('2*2');

        const nextName: string = data.nextName as string;
        const nextTime: string = data.nextTime as string;
        const message: string = `The next prayer is ${nextName} at ${nextTime}.`;

        // 2. Return the result to Xiaoyi
        const result: insightIntent.ExecuteResult = {
          code: 0,
          result: {
            message: message
          }
        };
        return result;
      } catch (e) {
        const error: Error = e as Error;
        const result: insightIntent.ExecuteResult = {
          code: -1,
          result: {
            message: `Failed to calculate prayer times: ${error.message}`
          }
        };
        return result;
      }
    }

    // Fallback for unknown intents
    const defaultResult: insightIntent.ExecuteResult = {
      code: -1,
      result: {
        message: 'Unknown intent'
      }
    };
    return defaultResult;
  }
}