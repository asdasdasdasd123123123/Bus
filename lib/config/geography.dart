import 'package:latlong2/latlong.dart';

/// Birmingham city centre and the default National Express WM 16 corridor.
class Geography {
  static const birminghamCentre = LatLng(52.4797, -1.9026);

  /// minLon, minLat, maxLon, maxLat — BODS `boundingBox` order.
  static const westMidlandsBbox = (-2.15, 52.36, -1.70, 52.64);

  /// Default first-launch viewport when no vehicles are available yet.
  static const defaultZoom = 12.6;

  /// Route 16 (Birmingham – Great Barr) corridor used by demo/mock mode.
  static const route16Corridor = <LatLng>[
    LatLng(52.47617, -1.89295), // Digbeth Markets
    LatLng(52.48106, -1.89147), // Albert Street
    LatLng(52.48294, -1.89588), // Colmore Circus
    LatLng(52.48402, -1.89828), // Lloyd House
    LatLng(52.48612, -1.90111), // Water Street
    LatLng(52.4908, -1.9132), // Hockley Circus
    LatLng(52.51586, -1.92426), // Handsworth Wood
    LatLng(52.5295, -1.9298), // Hamstead
    LatLng(52.53804, -1.94781), // Newton Green Lane
    LatLng(52.5482, -1.9325), // Great Barr / Scott Arms
  ];
}
