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
  id: number;
  osmId: string;
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
  distanceKm: number;
}