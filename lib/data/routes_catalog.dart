import 'package:latlong2/latlong.dart';

import '../models/models.dart';

/// Curated National Express West Midlands / Birmingham routes.
///
/// [bustimesServiceId] values were verified against
/// `https://bustimes.org/api/services/?operator=TNXB` on 2026-09-06.
class RoutesCatalog {
  static const operatorName = 'National Express West Midlands';

  static const defaultRoute16Stops = <BusStop>[
    BusStop(
      atco: '43000203903',
      name: 'Digbeth Markets',
      indicator: 'Stop MK3',
      location: LatLng(52.47617, -1.89295),
    ),
    BusStop(
      atco: '43000206802',
      name: 'Albert Street',
      indicator: 'Stop MS10',
      location: LatLng(52.48106, -1.89147),
    ),
    BusStop(
      atco: '43000208504',
      name: 'Colmore Circus',
      indicator: 'Stop PQ5',
      location: LatLng(52.48294, -1.89588),
    ),
    BusStop(
      atco: '43000207205',
      name: 'Lloyd House',
      indicator: 'Stop SQ2',
      location: LatLng(52.48402, -1.89828),
    ),
    BusStop(
      atco: '43000270103',
      name: 'Water Street',
      indicator: 'Stop CN3',
      location: LatLng(52.48612, -1.90111),
    ),
    BusStop(
      atco: '43000534102',
      name: 'Handsworth Wood, Selborne Road',
      indicator: 'adj',
      location: LatLng(52.51586, -1.92426),
    ),
    BusStop(
      atco: '43000540603',
      name: 'Newton, Green Lane',
      indicator: 'before',
      location: LatLng(52.53804, -1.94781),
    ),
  ];

  static const parkStreet = BusStop(
    atco: '43000202301',
    name: 'Park Street',
    indicator: 'Stop MK6',
    location: LatLng(52.47659, -1.89292),
  );

  static final defaultRoute = BusRoute(
    line: '16',
    name: 'Birmingham – Great Barr via Hockley & Hamstead',
    operatorName: operatorName,
    bustimesServiceId: 6247,
    stops: defaultRoute16Stops,
    isDefault: true,
  );

  static final popular = <BusRoute>[
    defaultRoute,
    const BusRoute(
      line: '11A',
      name: 'Outer Circle (clockwise)',
      operatorName: operatorName,
      bustimesServiceId: 6186,
    ),
    const BusRoute(
      line: '11C',
      name: 'Outer Circle (anti-clockwise)',
      operatorName: operatorName,
      bustimesServiceId: 6190,
    ),
    BusRoute(
      line: '50',
      name: 'Birmingham – Druids Heath / Wythall',
      operatorName: operatorName,
      bustimesServiceId: 6432,
      stops: const [parkStreet],
    ),
    const BusRoute(
      line: '9',
      name: 'Birmingham – Stourbridge via Quinton',
      operatorName: operatorName,
      bustimesServiceId: 6750,
    ),
    const BusRoute(
      line: 'X1',
      name: 'Birmingham – Coventry via Airport / NEC',
      operatorName: operatorName,
      bustimesServiceId: 6769,
    ),
    const BusRoute(
      line: 'X2',
      name: 'Birmingham – Solihull via Sheldon',
      operatorName: operatorName,
      bustimesServiceId: 6773,
    ),
    const BusRoute(
      line: 'X3',
      name: 'Birmingham – Hill Hook',
      operatorName: operatorName,
      bustimesServiceId: 6775,
    ),
    const BusRoute(
      line: 'X4',
      name: 'Birmingham – Falcon Lodge',
      operatorName: operatorName,
      bustimesServiceId: 6776,
    ),
    const BusRoute(
      line: 'X12',
      name: 'Birmingham – Airport / Solihull',
      operatorName: operatorName,
      bustimesServiceId: 6766,
    ),
    BusRoute(
      line: '6',
      name: 'Birmingham – Solihull via Hall Green',
      operatorName: operatorName,
      bustimesServiceId: 6514,
      stops: const [parkStreet],
    ),
    BusRoute(
      line: '4',
      name: 'Birmingham – Solihull',
      operatorName: operatorName,
      bustimesServiceId: 6416,
      stops: const [parkStreet],
    ),
    const BusRoute(
      line: '45',
      name: 'Birmingham – Longbridge',
      operatorName: operatorName,
      bustimesServiceId: 6387,
    ),
    const BusRoute(
      line: '47',
      name: 'Birmingham – Rednal',
      operatorName: operatorName,
      bustimesServiceId: 6401,
    ),
    const BusRoute(
      line: '61',
      name: 'Birmingham – Frankley',
      operatorName: operatorName,
      bustimesServiceId: 6483,
    ),
    const BusRoute(
      line: '63',
      name: 'Birmingham – Frankley',
      operatorName: operatorName,
      bustimesServiceId: 6490,
    ),
    const BusRoute(
      line: '23',
      name: 'Birmingham – Bartley Green',
      operatorName: operatorName,
      bustimesServiceId: 6278,
    ),
    const BusRoute(
      line: '24',
      name: 'Birmingham – Quinton Road West',
      operatorName: operatorName,
      bustimesServiceId: 6288,
    ),
    const BusRoute(
      line: '8A',
      name: 'Inner Circle (clockwise)',
      operatorName: operatorName,
      bustimesServiceId: 6694,
    ),
    const BusRoute(
      line: '8C',
      name: 'Inner Circle (anti-clockwise)',
      operatorName: operatorName,
      bustimesServiceId: 6697,
    ),
    BusRoute(
      line: '97',
      name: 'Birmingham – Chelmsley Wood',
      operatorName: operatorName,
      bustimesServiceId: 63911,
      stops: const [parkStreet],
    ),
    const BusRoute(
      line: '94',
      name: 'Birmingham – Chelmsley Wood',
      operatorName: operatorName,
      bustimesServiceId: 6725,
    ),
    const BusRoute(
      line: '7',
      name: 'Birmingham – Perry Common',
      operatorName: operatorName,
      bustimesServiceId: 6602,
    ),
    const BusRoute(
      line: '51',
      name: 'Birmingham – Walsall',
      operatorName: operatorName,
      bustimesServiceId: 70001,
    ),
    const BusRoute(
      line: '74',
      name: 'Birmingham – Dudley via West Bromwich',
      operatorName: operatorName,
      bustimesServiceId: 6561,
    ),
    const BusRoute(
      line: '87',
      name: 'Birmingham – Dudley',
      operatorName: operatorName,
      bustimesServiceId: 6666,
    ),
    const BusRoute(
      line: 'X8',
      name: 'Birmingham – Wolverhampton',
      operatorName: operatorName,
      bustimesServiceId: 6788,
    ),
    const BusRoute(
      line: '16',
      name: 'Wolverhampton – Stourbridge',
      operatorName: operatorName,
      bustimesServiceId: 6249,
    ),
  ];

  static BusRoute byId(String id) {
    return popular.firstWhere(
      (r) => r.id == id,
      orElse: () => defaultRoute,
    );
  }

  static BusRoute? find({String? line, int? bustimesServiceId}) {
    for (final route in popular) {
      if (bustimesServiceId != null &&
          route.bustimesServiceId == bustimesServiceId) {
        return route;
      }
    }
    if (line != null) {
      for (final route in popular) {
        if (route.line.toUpperCase() == line.toUpperCase()) return route;
      }
    }
    return null;
  }
}
