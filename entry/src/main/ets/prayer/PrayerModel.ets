// entry/src/main/ets/models/PrayerModel.ets

export interface PrayerModel {
  id: string;
  name: string;
  arabicName: string;
  time: string;
  status: 'next' | 'pray' | 'both' | 'prayed' | 'express' | 'abbreviation';
  checked?: boolean;
}

export interface ExtraTiming {
  id: string;
  name: string;
  arabicName: string;
  time: string;
  status: 'next' | 'pray' | 'both' | 'prayed' | 'express' | 'abbreviation';
  icon?: Resource;
}