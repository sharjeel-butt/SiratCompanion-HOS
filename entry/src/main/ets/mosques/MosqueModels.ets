export interface ManifestCountryItem {
  country: string;
  country_code: string;
  db: string;
  records: number;
  size_bytes: number;
  size_mb: number;
  dataset_version: string;
  schema_version: string;
  generated_at: string;
  checksum: string;
}

export interface ManifestData {
  version: number;
  schema_version: number;
  generated_at: string;
  total_records: number;
  country_count: number;
  countries: Record<string, ManifestCountryItem>;
}

export interface MosqueModel {
  id: number; // For custom mosques, this will be a timestamp
  osmId: string; // For custom mosques, this will be "custom_<timestamp>"
  name: string;
  nameAr: string;
  nameUr: string;
  nameTr: string;
  nameId: string;
  nameBn: string;
  nameZh: string;
  lat: number;
  lng: number;
  cityName: string;
  address: string;
  phone: string;
  website: string;
  distanceKm: number;
  isCustom: boolean; // NEW: Distinguishes user-added vs OSM data
}