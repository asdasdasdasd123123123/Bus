import 'dart:math';

import 'package:latlong2/latlong.dart';

import '../config/geography.dart';
import '../models/models.dart';

/// Deterministic-enough demo positions along the Birmingham 16 corridor
/// (and a few other popular lines) so the UI works without credentials.
class MockFeed {
  MockFeed({DateTime? now, Random? random})
      : _now = now ?? DateTime.now(),
        _random = random ?? Random(16);

  final DateTime _now;
  final Random _random;

  VehicleSnapshot vehiclesFor(BusRoute route) {
    final path = _pathFor(route);
    final count = route.line == '16' ? 10 : 7;
    final vehicles = <Vehicle>[];
    for (var i = 0; i < count; i++) {
      final t = ((i / count) + (_now.second / 60) * 0.08) % 1.0;
      final outbound = i.isEven;
      final progress = outbound ? t : 1 - t;
      final point = _along(path, progress);
      final wobble = (_random.nextDouble() - 0.5) * 0.0004;
      final jittered = LatLng(
        point.latitude + wobble,
        point.longitude + wobble,
      );
      vehicles.add(
        Vehicle(
          id: 'mock-${route.line}-$i',
          line: route.line,
          location: jittered,
          heading: outbound ? 330 : 150,
          headsign: outbound ? _outboundHeadsign(route) : 'Birmingham',
          vehicleName: 'Demo ${4700 + i}',
          updatedAt: _now,
          delaySeconds: i % 3 == 0 ? 90 : 0,
        ),
      );
    }
    return VehicleSnapshot(
      vehicles: vehicles,
      source: DataSource.mock,
      fetchedAt: _now,
    );
  }

  DepartureSnapshot departuresFor(BusRoute route, BusStop? stop) {
    final headsigns = [_outboundHeadsign(route), 'Birmingham'];
    final departures = <Departure>[
      for (var i = 0; i < 8; i++)
        Departure(
          routeNumber: route.line,
          headsign: headsigns[i % headsigns.length],
          when: _now.add(Duration(minutes: 2 + i * 7 + (i % 2))),
          aimed: _now.add(Duration(minutes: 2 + i * 7)),
          isRealtime: i < 5,
        ),
    ];
    return DepartureSnapshot(
      departures: departures,
      source: DataSource.mock,
      stop: stop,
    );
  }

  List<LatLng> _pathFor(BusRoute route) {
    if (route.line == '16' && (route.bustimesServiceId ?? 6247) == 6247) {
      return Geography.route16Corridor;
    }
    // Offset the 16 corridor slightly so other mock routes are visible.
    final jitter = (route.line.hashCode % 17) * 0.0012;
    return [
      for (final p in Geography.route16Corridor)
        LatLng(p.latitude + jitter * 0.4, p.longitude - jitter),
    ];
  }

  String _outboundHeadsign(BusRoute route) {
    final parts = route.name.split('–');
    if (parts.length >= 2) {
      return parts[1].split('via').first.trim();
    }
    return route.name;
  }

  LatLng _along(List<LatLng> path, double t) {
    if (path.length == 1) return path.first;
    final scaled = t.clamp(0.0, 0.999) * (path.length - 1);
    final i = scaled.floor();
    final f = scaled - i;
    final a = path[i];
    final b = path[i + 1];
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * f,
      a.longitude + (b.longitude - a.longitude) * f,
    );
  }

}
