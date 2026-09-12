// entry/src/main/ets/models/SettingsModels.ets

export interface PickerItem {
  id: string;
  label: string;
  selected: boolean;
}

export enum CalculationSource {
  LOCAL = 'Local',
  API = 'API'
}

export enum LocationMode {
  GPS = 'GPS',
  MANUAL = 'Manual'
}

export interface ManualCoords {
  lat: number;
  lng: number;
  refresh: number;   // timestamp (0 = never)
  cityName: string;
}