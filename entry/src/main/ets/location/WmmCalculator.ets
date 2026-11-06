// entry/src/main/ets/location/WmmCalculator.ets

// Fix for ArkTS strict mode: explicitly type the object literals
interface MagField {
  val: number;
}

export class WmmCalculator {
  // WGS84 Ellipsoid Constants
  private static readonly A = 6378.137;
  private static readonly B = 6356.7523142;
  private static readonly RE = 6371.2;
  private static readonly A2 = WmmCalculator.A * WmmCalculator.A;
  private static readonly B2 = WmmCalculator.B * WmmCalculator.B;
  private static readonly C2 = WmmCalculator.A2 - WmmCalculator.B2;
  private static readonly A4 = WmmCalculator.A2 * WmmCalculator.A2;
  private static readonly B4 = WmmCalculator.B2 * WmmCalculator.B2;
  private static readonly C4 = WmmCalculator.A4 - WmmCalculator.B4;

  // WMM2025 Coefficients (Degree/Order 12)
  // Format: [n, m, g, h, gdot, hdot]
  private static readonly COEFFS: number[][] = [
    [1, 0, -29351.8, 0.0, 12.0, 0.0],
    [1, 1, -1410.8, 4545.4, 9.7, -21.5],
    [2, 0, -2556.6, 0.0, -11.6, 0.0],
    [2, 1, 2951.1, -3133.6, -5.2, -27.7],
    [2, 2, 1649.3, -815.1, -8.0, -12.1],
    [3, 0, 1336.4, 0.0, -1.3, 0.0],
    [3, 1, -2305.3, -112.6, -6.4, 4.0],
    [3, 2, 1246.8, 237.5, 0.2, -0.3],
    [3, 3, 634.2, -549.5, -0.6, -13.4],
    [4, 0, 912.5, 0.0, -0.7, 0.0],
    [4, 1, 808.9, 286.4, 0.3, 1.1],
    [4, 2, 335.2, -242.0, -3.3, 0.8],
    [4, 3, -211.9, 80.6, 0.9, 4.4],
    [4, 4, 165.5, -137.8, -3.3, 2.6],
    [5, 0, -227.9, 0.0, -0.5, 0.0],
    [5, 1, 131.8, 22.0, 0.6, -0.3],
    [5, 2, 73.0, 14.8, -0.6, -0.5],
    [5, 3, -160.5, -68.5, 0.3, 1.1],
    [5, 4, -11.5, 56.1, 1.1, -0.4],
    [5, 5, 37.3, 4.6, 0.8, -0.5],
    [6, 0, 73.4, 0.0, -0.3, 0.0],
    [6, 1, -21.7, -28.6, -0.2, 0.3],
    [6, 2, -36.5, -9.9, -0.1, 0.2],
    [6, 3, 13.7, -23.6, 0.4, 0.2],
    [6, 4, -15.3, 8.3, 0.1, -0.4],
    [6, 5, -2.2, -1.6, 0.3, 0.1],
    [6, 6, 4.6, -3.0, -0.1, 0.1],
    [7, 0, 28.7, 0.0, 0.0, 0.0],
    [7, 1, 9.4, -5.8, 0.1, 0.0],
    [7, 2, -5.7, 4.0, 0.1, -0.1],
    [7, 3, -2.7, -1.7, 0.0, 0.1],
    [7, 4, -1.6, 1.8, 0.0, 0.0],
    [7, 5, 0.8, -0.9, 0.0, 0.0],
    [7, 6, 0.6, -0.2, 0.0, 0.0],
    [7, 7, -0.2, 0.3, 0.0, 0.0],
    [8, 0, 6.4, 0.0, 0.0, 0.0],
    [8, 1, 2.0, -1.4, 0.0, 0.0],
    [8, 2, -0.6, 0.6, 0.0, 0.0],
    [8, 3, -0.4, 0.2, 0.0, 0.0],
    [8, 4, 0.1, 0.0, 0.0, 0.0],
    [8, 5, 0.1, -0.1, 0.0, 0.0],
    [8, 6, -0.1, -0.1, 0.0, 0.0],
    [8, 7, 0.0, 0.0, 0.0, 0.0],
    [8, 8, -0.1, -0.1, 0.0, 0.0],
    [9, 0, 2.4, 0.0, 0.0, 0.0],
    [9, 1, 0.4, 0.3, 0.0, 0.0],
    [9, 2, -0.2, -0.1, 0.0, 0.0],
    [9, 3, 0.0, 0.1, 0.0, 0.0],
    [9, 4, -0.1, 0.0, 0.0, 0.0],
    [9, 5, 0.0, 0.0, 0.0, 0.0],
    [9, 6, 0.0, 0.0, 0.0, 0.0],
    [9, 7, 0.0, 0.0, 0.0, 0.0],
    [9, 8, 0.0, 0.0, 0.0, 0.0],
    [9, 9, -0.1, 0.0, 0.0, 0.0],
    [10, 0, 1.4, 0.0, 0.0, 0.0],
    [10, 1, 0.2, -0.1, 0.0, 0.0],
    [10, 2, 0.0, 0.0, 0.0, 0.0],
    [10, 3, 0.0, 0.0, 0.0, 0.0],
    [10, 4, 0.0, 0.0, 0.0, 0.0],
    [10, 5, 0.0, 0.0, 0.0, 0.0],
    [10, 6, 0.0, 0.0, 0.0, 0.0],
    [10, 7, 0.0, 0.0, 0.0, 0.0],
    [10, 8, 0.0, 0.0, 0.0, 0.0],
    [10, 9, 0.0, 0.0, 0.0, 0.0],
    [10, 10, 0.0, 0.0, 0.0, 0.0],
    [11, 0, 0.7, 0.0, 0.0, 0.0],
    [11, 1, 0.1, 0.0, 0.0, 0.0],
    [11, 2, 0.0, 0.0, 0.0, 0.0],
    [11, 3, 0.0, 0.0, 0.0, 0.0],
    [11, 4, 0.0, 0.0, 0.0, 0.0],
    [11, 5, 0.0, 0.0, 0.0, 0.0],
    [11, 6, 0.0, 0.0, 0.0, 0.0],
    [11, 7, 0.0, 0.0, 0.0, 0.0],
    [11, 8, 0.0, 0.0, 0.0, 0.0],
    [11, 9, 0.0, 0.0, 0.0, 0.0],
    [11, 10, 0.0, 0.0, 0.0, 0.0],
    [11, 11, 0.0, 0.0, 0.0, 0.0],
    [12, 0, 0.4, 0.0, 0.0, 0.0],
    [12, 1, 0.0, 0.0, 0.0, 0.0],
    [12, 2, 0.0, 0.0, 0.0, 0.0],
    [12, 3, 0.0, 0.0, 0.0, 0.0],
    [12, 4, 0.0, 0.0, 0.0, 0.0],
    [12, 5, 0.0, 0.0, 0.0, 0.0],
    [12, 6, 0.0, 0.0, 0.0, 0.0],
    [12, 7, 0.0, 0.0, 0.0, 0.0],
    [12, 8, 0.0, 0.0, 0.0, 0.0],
    [12, 9, 0.0, 0.0, 0.0, 0.0],
    [12, 10, 0.0, 0.0, 0.0, 0.0],
    [12, 11, 0.0, 0.0, 0.0, 0.0],
    [12, 12, 0.0, 0.0, 0.0, 0.0]
  ];

  /**
   * Computes the magnetic declination in degrees.
   * @param lat Geodetic latitude in degrees
   * @param lng Geodetic longitude in degrees
   * @param altitudeKm Altitude in kilometers above WGS84 ellipsoid (default 0)
   * @param date The date of calculation
   * @returns Declination in degrees (east is positive)
   */
  static getDeclination(lat: number, lng: number, altitudeKm: number = 0, date: Date): number {
    // 1. Convert Date to Decimal Year
    const decimalYear = WmmCalculator.dateToDecimalYear(date);

    // WMM2025 is valid 2025.0 to 2030.0
    const timeDelta = decimalYear - 2025.0;

    // 2. Convert geodetic to spherical coordinates
    const rlat = lat * Math.PI / 180.0;
    const rlng = lng * Math.PI / 180.0;

    const sinLat = Math.sin(rlat);
    const cosLat = Math.cos(rlat);
    const sinLat2 = sinLat * sinLat;

    const rc = WmmCalculator.A / Math.sqrt(1.0 - (WmmCalculator.C2 / WmmCalculator.A2) * sinLat2);
    const r = Math.sqrt(
      altitudeKm * (altitudeKm + 2.0 * rc) +
        (WmmCalculator.A4 - WmmCalculator.C4 * sinLat2) / (WmmCalculator.A2 - WmmCalculator.C2 * sinLat2)
    );

    const cd = (altitudeKm + rc) / r;
    const sd = (WmmCalculator.C2 / WmmCalculator.A2) * sinLat * cosLat / r;

    const rlatSpherical = Math.asin(sinLat * cd + cosLat * sd);
    const rlngSpherical = rlng;

    // 3. Compute Spherical Harmonics
    const N = 12;

    // Typed object literals to satisfy ArkTS
    const Bx: MagField = { val: 0 };
    const By: MagField = { val: 0 };
    const Bz: MagField = { val: 0 };

    const P = new Array<number>( (N + 1) * (N + 1) ).fill(0);
    const dP = new Array<number>( (N + 1) * (N + 1) ).fill(0);

    P[0] = 1.0;
    dP[0] = 0.0;

    const sinTheta = Math.sin(Math.PI / 2.0 - rlatSpherical);
    const cosTheta = Math.cos(Math.PI / 2.0 - rlatSpherical);

    // Precompute Legendre polynomials and derivatives
    for (let n = 1; n <= N; n++) {
      const nIdx = n * (n + 1);
      for (let m = 0; m <= n; m++) {
        const idx = nIdx + m;
        if (m === n) {
          const idx1 = (n - 1) * n + (m - 1);
          P[idx] = sinTheta * P[idx1];
          dP[idx] = sinTheta * dP[idx1] + cosTheta * P[idx1];
        } else if (m === n - 1) {
          const idx1 = (n - 1) * n + m;
          const k = (2 * n - 1);
          P[idx] = cosTheta * P[idx1] * k;
          dP[idx] = cosTheta * dP[idx1] * k - sinTheta * P[idx1] * k;
        } else {
          const idx1 = (n - 1) * n + m;
          const idx2 = (n - 2) * (n - 1) + m;
          const k1 = (2 * n - 1) / (n - m);
          const k2 = (n + m - 1) / (n - m);
          P[idx] = (cosTheta * P[idx1] * k1 - P[idx2] * k2);
          dP[idx] = (cosTheta * dP[idx1] * k1 - sinTheta * P[idx1] * k1 - dP[idx2] * k2);
        }
      }
    }

    // 4. Sum the series
    for (let n = 1; n <= N; n++) {
      const nIdx = n * (n + 1);
      const rPow = Math.pow(WmmCalculator.RE / r, n + 2);

      for (let m = 0; m <= n; m++) {
        const idx = nIdx + m;

        let g = 0, h = 0, gdot = 0, hdot = 0;
        for (let c = 0; c < WmmCalculator.COEFFS.length; c++) {
          const co = WmmCalculator.COEFFS[c];
          if (co[0] === n && co[1] === m) {
            g = co[2]; h = co[3]; gdot = co[4]; hdot = co[5];
            break;
          }
        }

        const gT = g + timeDelta * gdot;
        const hT = h + timeDelta * hdot;

        const mPhi = m * rlngSpherical;
        const cosMPhi = Math.cos(mPhi);
        const sinMPhi = Math.sin(mPhi);

        const Pval = P[idx];
        const dPval = dP[idx];

        const temp1 = gT * cosMPhi + hT * sinMPhi;
        const temp2 = gT * sinMPhi - hT * cosMPhi;

        Bx.val += rPow * temp1 * dPval;
        By.val += rPow * (m * temp2 * Pval) / cosTheta;
        Bz.val -= (n + 1) * rPow * temp1 * Pval;
      }
    }

    if (Math.abs(cosTheta) < 1e-10) {
      By.val = 0;
    }

    // 5. Rotate to geodetic coordinates
    const bx = Bx.val * cd + Bz.val * sd;
    const by = By.val;

    // 6. Calculate Declination (D = atan2(By, Bx))
    const declinationRad = Math.atan2(by, bx);
    return declinationRad * 180.0 / Math.PI;
  }

  private static dateToDecimalYear(date: Date): number {
    const year = date.getUTCFullYear();
    const start = new Date(Date.UTC(year, 0, 1));
    const end = new Date(Date.UTC(year + 1, 0, 1));
    const yearProgress = (date.getTime() - start.getTime()) / (end.getTime() - start.getTime());
    return year + yearProgress;
  }
}