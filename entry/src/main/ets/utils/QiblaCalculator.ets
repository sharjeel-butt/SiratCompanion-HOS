// entry/src/main/ets/utils/QiblaCalculator.ets

/**
 * Qibla direction calculator.
 * Uses the great-circle bearing formula to determine the direction
 * from any point on Earth to the Kaaba in Makkah.
 */
export class QiblaCalculator {

  // Kaaba coordinates (Makkah)
  private static readonly KAABA_LAT = 21.4225;
  private static readonly KAABA_LNG = 39.8262;

  /**
   * Calculate the Qibla bearing (0–360°) from true North.
   *
   * @param latitude  User's latitude in decimal degrees
   * @param longitude User's longitude in decimal degrees
   * @returns Bearing in degrees (0 = North, 90 = East, 180 = South, 270 = West)
   */
  static calculateBearing(latitude: number, longitude: number): number {
    const φ1 = QiblaCalculator.toRadians(latitude);
    const φ2 = QiblaCalculator.toRadians(QiblaCalculator.KAABA_LAT);
    const ΔL = QiblaCalculator.toRadians(QiblaCalculator.KAABA_LNG - longitude);

    const y = Math.sin(ΔL);
    const x = Math.cos(φ1) * Math.tan(φ2) - Math.sin(φ1) * Math.cos(ΔL);

    let bearing = Math.atan2(y, x);
    bearing = QiblaCalculator.toDegrees(bearing);

    // Normalize to 0–360
    return (bearing + 360) % 360;
  }

  /**
   * Distance to the Kaaba in kilometres (great-circle / haversine).
   */
  static calculateDistance(latitude: number, longitude: number): number {
    const R = 6371; // Earth radius in km
    const φ1 = QiblaCalculator.toRadians(latitude);
    const φ2 = QiblaCalculator.toRadians(QiblaCalculator.KAABA_LAT);
    const Δφ = QiblaCalculator.toRadians(QiblaCalculator.KAABA_LAT - latitude);
    const ΔL = QiblaCalculator.toRadians(QiblaCalculator.KAABA_LNG - longitude);

    const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
      Math.cos(φ1) * Math.cos(φ2) *
        Math.sin(ΔL / 2) * Math.sin(ΔL / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c;
  }

  private static toRadians(deg: number): number {
    return deg * Math.PI / 180;
  }

  private static toDegrees(rad: number): number {
    return rad * 180 / Math.PI;
  }
}