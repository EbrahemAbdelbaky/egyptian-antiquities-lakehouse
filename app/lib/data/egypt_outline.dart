/// A schematic outline of Egypt, the Nile and a few cities, for the map of find sites.
///
/// There is no map tile and no map file in the app: the outline is a hand-made polygon through well-known places
/// (the coast from Salloum to Rafah, the Sinai, the Red Sea coast, the borders at 22 N and 25 E).
/// It is for orientation only. It is not a survey and must not be used to measure anything.
/// Every point is [longitude, latitude] in degrees.

const List<List<double>> kEgyptOutline = <List<double>>[
  <double>[25.0, 31.6], // Salloum
  <double>[25.9, 31.6],
  <double>[27.2, 31.35], // Marsa Matruh
  <double>[28.95, 30.85], // El Alamein
  <double>[29.9, 31.2], // Alexandria
  <double>[30.4, 31.5],
  <double>[31.0, 31.6],
  <double>[31.8, 31.5],
  <double>[32.3, 31.27], // Port Said
  <double>[33.8, 31.13], // El Arish
  <double>[34.25, 31.3], // Rafah
  <double>[34.9, 29.5], // Taba
  <double>[34.65, 28.1],
  <double>[34.25, 27.73], // Ras Mohammed, the tip of the Sinai
  <double>[33.6, 28.25],
  <double>[33.1, 29.05],
  <double>[32.55, 29.95], // Suez
  <double>[32.35, 29.6],
  <double>[32.65, 29.1],
  <double>[33.1, 28.35],
  <double>[33.8, 27.25], // Hurghada
  <double>[33.95, 26.75],
  <double>[34.28, 26.1],
  <double>[34.9, 25.07], // Marsa Alam
  <double>[35.48, 23.9],
  <double>[36.9, 22.0],
  <double>[25.0, 22.0],
];

/// The Nile from Aswan to the apex of the Delta.
const List<List<double>> kNile = <List<double>>[
  <double>[32.9, 24.09], // Aswan
  <double>[32.93, 24.45],
  <double>[32.87, 24.98],
  <double>[32.55, 25.3],
  <double>[32.64, 25.7], // Luxor
  <double>[32.72, 26.16],
  <double>[32.25, 26.05],
  <double>[31.9, 26.2],
  <double>[31.7, 26.55],
  <double>[31.18, 27.18],
  <double>[30.84, 27.73],
  <double>[30.75, 28.1],
  <double>[31.1, 29.07],
  <double>[31.2, 30.0],
  <double>[31.25, 30.2],
];

/// The two branches of the Delta, from the apex to the sea (Rosetta and Damietta).
const List<List<double>> kRosetta = <List<double>>[
  <double>[31.25, 30.2],
  <double>[30.9, 30.8],
  <double>[30.4, 31.45],
];

const List<List<double>> kDamietta = <List<double>>[
  <double>[31.25, 30.2],
  <double>[31.5, 30.9],
  <double>[31.8, 31.45],
];

/// Lake Nasser, south of Aswan.
const List<List<double>> kLakeNasser = <List<double>>[
  <double>[32.9, 24.09],
  <double>[32.8, 23.5],
  <double>[32.6, 22.5],
  <double>[32.4, 22.0],
];

/// A city that helps the eye to find its way on the map.
class MapPlace {
  const MapPlace(this.name, this.lon, this.lat);

  final String name;
  final double lon;
  final double lat;
}

const List<MapPlace> kMapPlaces = <MapPlace>[
  MapPlace('Alexandria', 29.92, 31.2),
  MapPlace('Cairo', 31.24, 30.04),
  MapPlace('Luxor', 32.64, 25.7),
  MapPlace('Aswan', 32.9, 24.09),
];
