export interface Prayer {
  id: string;
  name: string;
  arabicName: string;
  time: string;
  status: 'next' | 'pray' | 'express' | 'abbreviation' | 'locked';
  checked?: boolean;
}

export interface ExtraTiming {
  id: string;
  name: string;
  arabicName: string;
  time: string;
  status: 'abbreviation' | 'normal';
}