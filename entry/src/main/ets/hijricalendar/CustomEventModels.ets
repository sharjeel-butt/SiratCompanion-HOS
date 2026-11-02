// entry/src/main/ets/models/CustomEventModels.ets

export enum RecurrenceType {
  NONE = 'none',
  YEARLY = 'yearly',
  MONTHLY = 'monthly',
  WEEKLY = 'weekly'
}

export interface CustomEvent {
  id: string;
  title: string;
  hijriYear: number; // Exact year if NONE, else -1
  hijriMonth: number; // 1-12
  hijriDay: number; // 1-30
  notificationEnabled: boolean;
  inputType?: 'hijri' | 'gregorian';
  recurrence?: RecurrenceType;
  gregorianDayOfWeek?: number; // 0-6 (Sunday-Saturday) used for WEEKLY
}