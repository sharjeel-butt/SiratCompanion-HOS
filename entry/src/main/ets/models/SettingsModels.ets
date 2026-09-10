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