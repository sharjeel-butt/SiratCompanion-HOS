import { PreferencesHelper } from '../core/PreferencesHelper';
import { MosqueModel } from './MosqueModels';

const KEY_CUSTOM_MOSQUES = 'custom_mosques_data';

export class MosqueStorage {
  static async load(): Promise<MosqueModel[]> {
    try {
      const json = await PreferencesHelper.getString(KEY_CUSTOM_MOSQUES, '[]');
      return JSON.parse(json) as MosqueModel[];
    } catch (e) {
      return [];
    }
  }

  static async save(mosques: MosqueModel[]): Promise<void> {
    // Only save the custom ones
    const customOnly = mosques.filter(m => m.isCustom);
    await PreferencesHelper.setString(KEY_CUSTOM_MOSQUES, JSON.stringify(customOnly));
  }

  static async addOrUpdate(mosque: MosqueModel): Promise<void> {
    const existing = await MosqueStorage.load();
    const idx = existing.findIndex(m => m.id === mosque.id);

    if (idx >= 0) {
      existing[idx] = mosque;
    } else {
      existing.push(mosque);
    }
    await MosqueStorage.save(existing);
  }

  static async delete(id: number): Promise<void> {
    const existing = await MosqueStorage.load();
    const filtered = existing.filter(m => m.id !== id);
    await MosqueStorage.save(filtered);
  }
}