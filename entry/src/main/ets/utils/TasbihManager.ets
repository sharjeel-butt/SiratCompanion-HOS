// entry/src/main/ets/utils/TasbihManager.ets

import { AddTasbihResult, BeadView, Dhikr, DhikrFields, Tasbih } from '../models/TasbihModels';

export const MAX_TOP_BEADS    = 3;
export const MAX_BOTTOM_BEADS = 5;

export class TasbihManager {

  static generateId(): string {
    return `id_${Date.now()}_${Math.floor(Math.random() * 100000)}`;
  }

  static createDefaults(): Tasbih[] {
    const classic: Dhikr[] = [
      { id: TasbihManager.generateId(), arabic: 'سُبْحَانَ ٱللَّٰهِ', transliteration: 'SubhanAllah',
        translation: 'Glory be to Allah', target: 33, count: 0 },
      { id: TasbihManager.generateId(), arabic: 'ٱلْحَمْدُ لِلَّٰهِ', transliteration: 'Alhamdulillah',
        translation: 'All praise is for Allah', target: 33, count: 0 },
      { id: TasbihManager.generateId(), arabic: 'ٱللَّٰهُ أَكْبَرُ', transliteration: 'Allahu Akbar',
        translation: 'Allah is the Greatest', target: 34, count: 0 }
    ];
    const tahlil: Dhikr[] = [
      { id: TasbihManager.generateId(),
        arabic: 'لَا إِلَٰهَ إِلَّا ٱللَّٰهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ ٱلْمُلْكُ وَلَهُ ٱلْحَمْدُ',
        transliteration: 'La ilaha illallahu wahdahu la sharika lah',
        translation: 'There is no god but Allah, alone, without partner', target: 100, count: 0 }
    ];
    const istighfar: Dhikr[] = [
      { id: TasbihManager.generateId(), arabic: 'أَسْتَغْفِرُ ٱللَّٰهَ', transliteration: 'Astaghfirullah',
        translation: 'I seek forgiveness from Allah', target: 100, count: 0 }
    ];

    const out: Tasbih[] = [
      { id: TasbihManager.generateId(), name: 'Classic 33', createdAt: Date.now(),     dhikrs: classic,    lifetimeCount: 0 },
      { id: TasbihManager.generateId(), name: 'Tahlil 100', createdAt: Date.now() + 1, dhikrs: tahlil,     lifetimeCount: 0 },
      { id: TasbihManager.generateId(), name: 'Istighfar',  createdAt: Date.now() + 2, dhikrs: istighfar,  lifetimeCount: 0 }
    ];
    return out;
  }

  static findTasbih(tasbihs: Tasbih[], id: string): Tasbih | null {
    const found = tasbihs.find((t): boolean => t.id === id);
    return found ? found : null;
  }

  static getActiveDhikr(tasbihs: Tasbih[], activeTasbihId: string, index: number): Dhikr | null {
    const t = TasbihManager.findTasbih(tasbihs, activeTasbihId);
    if (!t || t.dhikrs.length === 0) return null;
    const safeIdx = Math.min(index, t.dhikrs.length - 1);
    return t.dhikrs[safeIdx];
  }

  static computeBeadView(dhikr: Dhikr | null): BeadView {
    if (!dhikr) {
      const empty: BeadView = {
        topIds: [], bottomIds: [],
        isComplete: false, topAtCap: false, bottomAtCap: false
      };
      return empty;
    }

    const isComplete = dhikr.count >= dhikr.target;
    const topCount = Math.min(Math.max(0, dhikr.count), MAX_TOP_BEADS);
    const bottomCount = Math.min(
      Math.max(0, dhikr.target - dhikr.count), MAX_BOTTOM_BEADS
    );

    const topIds: number[] = [];
    for (let i = 0; i < topCount; i++) topIds.push(i);

    const bottomIds: number[] = [];
    for (let i = 0; i < bottomCount; i++) bottomIds.push(i);

    const view: BeadView = {
      topIds: topIds,
      bottomIds: bottomIds,
      isComplete: isComplete,
      topAtCap: topCount === MAX_TOP_BEADS,
      bottomAtCap: bottomCount === MAX_BOTTOM_BEADS
    };
    return view;
  }

  // ============================================================
  // COUNTING — increment bumps lifetimeCount by 1
  // ============================================================

  static increment(tasbihs: Tasbih[], activeId: string, dhikrId: string): Tasbih[] {
    return TasbihManager.mutateDhikr(tasbihs, activeId, dhikrId, 1, (d: Dhikr): Dhikr => {
      const next: Dhikr = {
        id: d.id, arabic: d.arabic, transliteration: d.transliteration,
        translation: d.translation, target: d.target, count: d.count + 1
      };
      return next;
    });
  }

  static decrement(tasbihs: Tasbih[], activeId: string, dhikrId: string): Tasbih[] {
    return TasbihManager.mutateDhikr(tasbihs, activeId, dhikrId, 0, (d: Dhikr): Dhikr => {
      const next: Dhikr = {
        id: d.id, arabic: d.arabic, transliteration: d.transliteration,
        translation: d.translation, target: d.target,
        count: d.count > 0 ? d.count - 1 : 0
      };
      return next;
    });
  }

  static reset(tasbihs: Tasbih[], activeId: string, dhikrId: string): Tasbih[] {
    return TasbihManager.mutateDhikr(tasbihs, activeId, dhikrId, 0, (d: Dhikr): Dhikr => {
      const next: Dhikr = {
        id: d.id, arabic: d.arabic, transliteration: d.transliteration,
        translation: d.translation, target: d.target, count: 0
      };
      return next;
    });
  }

  // ============================================================
  // TASBIH CRUD — every rebuild preserves lifetimeCount
  // ============================================================

  static addTasbih(tasbihs: Tasbih[], name: string): AddTasbihResult {
    const newTasbih: Tasbih = {
      id: TasbihManager.generateId(),
      name: name,
      dhikrs: [],
      createdAt: Date.now(),
      lifetimeCount: 0
    };
    const result: AddTasbihResult = {
      tasbihs: [...tasbihs, newTasbih], newId: newTasbih.id
    };
    return result;
  }

  static renameTasbih(tasbihs: Tasbih[], id: string, name: string): Tasbih[] {
    return tasbihs.map((t: Tasbih): Tasbih => {
      if (t.id !== id) return t;
      const updated: Tasbih = {
        id: t.id, name: name, dhikrs: t.dhikrs,
        createdAt: t.createdAt, lifetimeCount: t.lifetimeCount
      };
      return updated;
    });
  }

  static removeTasbih(tasbihs: Tasbih[], id: string): Tasbih[] {
    if (tasbihs.length <= 1) return tasbihs;
    return tasbihs.filter((t: Tasbih): boolean => t.id !== id);
  }

  // ============================================================
  // DHIKR CRUD
  // ============================================================

  static addDhikr(tasbihs: Tasbih[], activeId: string, fields: DhikrFields): Tasbih[] {
    const newDhikr: Dhikr = {
      id: TasbihManager.generateId(),
      arabic: fields.arabic, transliteration: fields.transliteration,
      translation: fields.translation, target: fields.target, count: 0
    };
    return tasbihs.map((t: Tasbih): Tasbih => {
      if (t.id !== activeId) return t;
      const updated: Tasbih = {
        id: t.id, name: t.name, dhikrs: [...t.dhikrs, newDhikr],
        createdAt: t.createdAt, lifetimeCount: t.lifetimeCount
      };
      return updated;
    });
  }

  static updateDhikr(tasbihs: Tasbih[], activeId: string, dhikrId: string, fields: DhikrFields): Tasbih[] {
    return tasbihs.map((t: Tasbih): Tasbih => {
      if (t.id !== activeId) return t;
      const updated: Dhikr[] = t.dhikrs.map((d: Dhikr): Dhikr => {
        if (d.id !== dhikrId) return d;
        const next: Dhikr = {
          id: d.id, arabic: fields.arabic, transliteration: fields.transliteration,
          translation: fields.translation, target: fields.target, count: d.count
        };
        return next;
      });
      const result: Tasbih = {
        id: t.id, name: t.name, dhikrs: updated,
        createdAt: t.createdAt, lifetimeCount: t.lifetimeCount
      };
      return result;
    });
  }

  static removeDhikr(tasbihs: Tasbih[], activeId: string, dhikrId: string): Tasbih[] {
    return tasbihs.map((t: Tasbih): Tasbih => {
      if (t.id !== activeId) return t;
      const filtered: Dhikr[] = t.dhikrs.filter((d: Dhikr): boolean => d.id !== dhikrId);
      const result: Tasbih = {
        id: t.id, name: t.name, dhikrs: filtered,
        createdAt: t.createdAt, lifetimeCount: t.lifetimeCount
      };
      return result;
    });
  }

  // ============================================================
  // INTERNAL
  // ============================================================

  private static mutateDhikr(
    tasbihs: Tasbih[],
    activeId: string,
    dhikrId: string,
    lifetimeDelta: number,
    fn: (d: Dhikr) => Dhikr
  ): Tasbih[] {
    return tasbihs.map((t: Tasbih): Tasbih => {
      if (t.id !== activeId) return t;
      const updated: Dhikr[] = t.dhikrs.map((d: Dhikr): Dhikr => {
        if (d.id !== dhikrId) return d;
        return fn(d);
      });
      const result: Tasbih = {
        id: t.id, name: t.name, dhikrs: updated,
        createdAt: t.createdAt,
        lifetimeCount: (t.lifetimeCount || 0) + lifetimeDelta
      };
      return result;
    });
  }
}