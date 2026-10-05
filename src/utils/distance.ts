export interface Coordinates {
  latitude: number;
  longitude: number;
}

// Fallback user location (Centro de São Paulo)
export const DEFAULT_USER_LOCATION: Coordinates = {
  latitude: -23.561684,
  longitude: -46.655981,
};

let cachedUserLocation: Coordinates | null = null;

/**
 * Returns user actual GPS coordinates from browser Geolocation API
 */
export async function getRealUserLocation(): Promise<Coordinates> {
  if (cachedUserLocation) return cachedUserLocation;

  if (typeof navigator !== 'undefined' && 'geolocation' in navigator) {
    try {
      const pos = await new Promise<GeolocationPosition>((resolve, reject) => {
        navigator.geolocation.getCurrentPosition(resolve, reject, {
          enableHighAccuracy: true,
          timeout: 6000,
          maximumAge: 60000,
        });
      });
      cachedUserLocation = {
        latitude: pos.coords.latitude,
        longitude: pos.coords.longitude,
      };
      return cachedUserLocation;
    } catch (_) {
      // Fallback
    }
  }

  cachedUserLocation = DEFAULT_USER_LOCATION;
  return DEFAULT_USER_LOCATION;
}

export function getCurrentUserCoordinates(): Coordinates {
  return cachedUserLocation || DEFAULT_USER_LOCATION;
}

// Initialize GPS retrieval
if (typeof window !== 'undefined') {
  getRealUserLocation().catch(() => {});
}

/**
 * Calculates geodesic distance in meters between two coordinates using the Haversine formula
 */
export function calculateDistanceMeters(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371e3; // Earth radius in meters
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
  const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return Math.round(R * c);
}

/**
 * Formats distance into human-readable meters or kilometers
 */
export function formatDistance(meters: number): string {
  if (meters < 1000) {
    return `${Math.max(50, Math.round(meters / 10) * 10)} m`;
  }
  const km = meters / 1000;
  return `${km < 10 ? km.toFixed(1).replace('.', ',') : Math.round(km)} km`;
}

/**
 * Assigns realistic coordinates around the region if coordinates are missing
 */
export function getProductCoordinates(index: number, address: string): Coordinates {
  const base = getCurrentUserCoordinates();
  const offsets = [
    { dLat: 0.0035, dLon: 0.0028 }, // ~450m
    { dLat: -0.0055, dLon: 0.0062 }, // ~890m
    { dLat: 0.0120, dLon: -0.0085 }, // ~1.6km
    { dLat: -0.0180, dLon: 0.0150 }, // ~2.5km
    { dLat: 0.0270, dLon: 0.0210 }, // ~3.8km
    { dLat: -0.0350, dLon: -0.0250 }, // ~4.7km
    { dLat: 0.0450, dLon: -0.0350 }, // ~6.3km
  ];
  const offset = offsets[index % offsets.length];
  return {
    latitude: base.latitude + offset.dLat,
    longitude: base.longitude + offset.dLon,
  };
}
