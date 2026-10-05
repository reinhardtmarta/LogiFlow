/**
 * DistanceBot Service - Banco de Dados Geográfico & Roteamento Sustentável
 * 
 * NOTA DE ARQUITETURA:
 * Não é necessária API de IA para cálculo de distâncias.
 * Modelos de IA geram alucinações numéricas e custos altos por token.
 * A computação tradicional com banco de coordenadas de cidades/bairros
 * + fórmula geodésica de Haversine com fator de curvatura rodoviária (1.25x)
 * é 100% determinística, gratuita, instantânea (0ms) e funciona offline.
 */

export interface DistanceCalculationResult {
  buyerLocation: string;
  sellerLocation: string;
  distanceMeters: number;
  distanceKm: number;
  distanceFormatted: string;
  walkingMinutes: number;
  bikingMinutes: number;
  drivingMinutes: number;
  co2SavedGrams: number;
  recommendation: string;
  matchedCities: {
    buyer?: string;
    seller?: string;
  };
}

// Banco de Dados Geográfico de Cidades e Bairros com Coordenadas Centróides Oficiais
export const GEO_DATABASE: Record<string, { lat: number; lng: number; uf?: string }> = {
  // Principais Cidades de SP
  'sao paulo': { lat: -23.5505, lng: -46.6333, uf: 'SP' },
  'campinas': { lat: -22.9099, lng: -47.0626, uf: 'SP' },
  'santos': { lat: -23.9608, lng: -46.3336, uf: 'SP' },
  'sao bernardo': { lat: -23.6944, lng: -46.5654, uf: 'SP' },
  'santo andre': { lat: -23.6638, lng: -46.5383, uf: 'SP' },
  'osasco': { lat: -23.5329, lng: -46.7916, uf: 'SP' },
  'guarulhos': { lat: -23.4628, lng: -46.5333, uf: 'SP' },
  'sorocaba': { lat: -23.5015, lng: -47.4526, uf: 'SP' },
  'ribeirao preto': { lat: -21.1704, lng: -47.8103, uf: 'SP' },
  'sao jose dos campos': { lat: -23.1896, lng: -45.8841, uf: 'SP' },
  'jundiai': { lat: -23.1857, lng: -46.8978, uf: 'SP' },
  'piracicaba': { lat: -22.7338, lng: -47.6476, uf: 'SP' },
  'bauru': { lat: -22.3145, lng: -49.0587, uf: 'SP' },
  'sao carlos': { lat: -22.0174, lng: -47.8908, uf: 'SP' },
  'marilia': { lat: -22.2139, lng: -49.9458, uf: 'SP' },

  // Capitais e Centros Nacionais
  'rio de janeiro': { lat: -22.9068, lng: -43.1729, uf: 'RJ' },
  'belo horizonte': { lat: -19.9167, lng: -43.9345, uf: 'MG' },
  'curitiba': { lat: -25.4290, lng: -49.2671, uf: 'PR' },
  'porto alegre': { lat: -30.0346, lng: -51.2177, uf: 'RS' },
  'florianopolis': { lat: -27.5954, lng: -48.5480, uf: 'SC' },
  'brasilia': { lat: -15.7975, lng: -47.8919, uf: 'DF' },
  'goiania': { lat: -16.6869, lng: -49.2648, uf: 'GO' },
  'salvador': { lat: -12.9714, lng: -38.5014, uf: 'BA' },
  'recife': { lat: -8.0476, lng: -34.8770, uf: 'PE' },
  'fortaleza': { lat: -3.7172, lng: -38.5433, uf: 'CE' },

  // Bairros e Polos Urbanos de Referência (São Paulo & Regiões)
  'centro': { lat: -23.5505, lng: -46.6333 },
  'paulista': { lat: -23.5616, lng: -46.6559 },
  'bela vista': { lat: -23.5600, lng: -46.6450 },
  'consolacao': { lat: -23.5520, lng: -46.6580 },
  'pinheiros': { lat: -23.5670, lng: -46.6930 },
  'vila madalena': { lat: -23.5530, lng: -46.6910 },
  'vila mariana': { lat: -23.5850, lng: -46.6370 },
  'santana': { lat: -23.5040, lng: -46.6260 },
  'morumbi': { lat: -23.6020, lng: -46.7130 },
  'butanta': { lat: -23.5710, lng: -46.7180 },
  'mooca': { lat: -23.5530, lng: -46.5980 },
  'tatuape': { lat: -23.5400, lng: -46.5760 },
  'ipiranga': { lat: -23.5910, lng: -46.6080 },
  'lapa': { lat: -23.5210, lng: -46.7020 },
  'perdizes': { lat: -23.5350, lng: -46.6740 },
  'santo amaro': { lat: -23.6530, lng: -46.7080 },
  'itaim bibi': { lat: -23.5830, lng: -46.6800 },
  'jardins': { lat: -23.5680, lng: -46.6660 },
  'penha': { lat: -23.5240, lng: -46.5450 },
  'vila leopoldina': { lat: -23.5280, lng: -46.7260 },
};

function normalizeString(str: string): string {
  return (str || '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim();
}

function findCoords(queryText: string, fallbackSeed: number = 0): { coords: { lat: number; lng: number }; matchName?: string } {
  const norm = normalizeString(queryText);

  // Direct and substring match in geographical database
  for (const [key, val] of Object.entries(GEO_DATABASE)) {
    const normKey = normalizeString(key);
    if (norm.includes(normKey) || normKey.includes(norm)) {
      return { coords: val, matchName: key };
    }
  }

  // Fallback: deterministic regional dispersion based on text hash
  let hash = 0;
  for (let i = 0; i < norm.length; i++) {
    hash = (hash << 5) - hash + norm.charCodeAt(i);
    hash |= 0;
  }
  const offsetLat = ((Math.abs(hash + fallbackSeed) % 120) / 1000) - 0.06;
  const offsetLng = ((Math.abs((hash >> 2) + fallbackSeed) % 120) / 1000) - 0.06;

  return {
    coords: {
      lat: -23.5505 + offsetLat,
      lng: -46.6333 + offsetLng,
    },
  };
}

export function calculateGreatCircleDistanceMeters(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371e3; // Earth radius in meters
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
  const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

export class DistanceBot {
  /**
   * Fator de curva viária/rodoviária realista:
   * Em trajetos terrestres, a rota por ruas e estradas é em média ~25% maior que a linha reta.
   */
  private static ROAD_DETOUR_FACTOR = 1.25;

  public static calculate(
    buyerAddress: string,
    sellerAddress: string,
    seed: number = 0
  ): DistanceCalculationResult {
    const buyerClean = buyerAddress?.trim() || 'São Paulo, Centro';
    const sellerClean = sellerAddress?.trim() || 'São Paulo';

    const bMatch = findCoords(buyerClean, 1);
    const sMatch = findCoords(sellerClean, seed + 3);

    const directMeters = calculateGreatCircleDistanceMeters(
      bMatch.coords.lat,
      bMatch.coords.lng,
      sMatch.coords.lat,
      sMatch.coords.lng
    );

    // Distância real estimada por malha viária (ruas e estradas)
    const distanceMeters = Math.max(200, Math.round(directMeters * this.ROAD_DETOUR_FACTOR));
    const distanceKm = Number((distanceMeters / 1000).toFixed(1));

    // Velocidades médias:
    // Caminhada urbana: ~4.5 km/h (75 m/min)
    // Bicicleta: ~14 km/h (233 m/min)
    // Carro urbano/rodoviário: ~35 a 60 km/h (média ~700 m/min)
    const walkingMinutes = Math.max(3, Math.round(distanceMeters / 75));
    const bikingMinutes = Math.max(2, Math.round(distanceMeters / 233));
    const drivingMinutes = Math.max(2, Math.round(distanceMeters / 700));

    // CO2 economizado se resgatar sem carro (130g de CO2/km)
    const co2SavedGrams = Math.round(distanceKm * 130);

    const distanceFormatted =
      distanceMeters < 1000
        ? `${Math.round(distanceMeters / 50) * 50} m`
        : `${distanceKm.toFixed(1).replace('.', ',')} km`;

    let recommendation = 'Muito próximo! Excelente para ir a pé e resgatar sem emissões.';
    if (distanceKm > 30) {
      recommendation = `Distância entre cidades (~${distanceKm} km). Ideal para compras programadas ou frete combinado.`;
    } else if (distanceKm > 5) {
      recommendation = 'Distância média. Indicado ir de bicicleta, transporte coletivo ou veículo.';
    } else if (distanceKm > 2) {
      recommendation = 'Ótima distância para ir de bicicleta (~' + bikingMinutes + ' min) ou caminhada saudável.';
    }

    return {
      buyerLocation: buyerClean,
      sellerLocation: sellerClean,
      distanceMeters,
      distanceKm,
      distanceFormatted,
      walkingMinutes,
      bikingMinutes,
      drivingMinutes,
      co2SavedGrams,
      recommendation,
      matchedCities: {
        buyer: bMatch.matchName,
        seller: sMatch.matchName,
      },
    };
  }
}
