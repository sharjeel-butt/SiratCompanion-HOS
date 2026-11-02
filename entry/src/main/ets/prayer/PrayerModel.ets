// entry/src/main/ets/prayer/PrayerModel.ets

export interface PrayerModel {
  id: string;
  name: string;
  arabicName: string;
  time: string;
  status: 'next' | 'pray' | 'prayed' | 'abbreviation';
  checked?: boolean;
}

export interface ExtraTiming {
  id: string;
  name: string;
  arabicName: string;
  time: string;
  status: 'next' | 'pray' | 'prayed' | 'abbreviation';
  icon?: Resource;
}