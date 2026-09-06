import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/app_config.dart';
import '../config/geography.dart';
import '../models/models.dart';
import 'mock_feed.dart';
import 'siri_vm_parser.dart';

class TransitException implements Exception {
  TransitException(this.message);
  final String message;

  @override
  String toString() => message;
}

class TransitRepository {
  TransitRepository({
    required this.config,
    http.Client? client,
    this.parser = const SiriVmParser(),
    MockFeed? mockFeed,
  })  : _client = client ?? http.Client(),
        _mock = mockFeed ?? MockFeed();

  final SiriVmParser parser;

  final AppConfig config;
  final http.Client _client;
  final MockFeed _mock;

  Future<List<BusRoute>> extraRoutes() async {
    if (config.forceDemo) return const [];
    try {
      final uri = Uri.parse(AppConfig.bustimesServicesUrl).replace(
        queryParameters: {'operator': 'TNXB', 'limit': '200'},
      );
      final response = await _get(uri);
      final decoded = jsonDecode(response) as Map<String, dynamic>;
      final results = decoded['results'] as List<dynamic>? ?? const [];
      return [
        for (final raw in results)
          _routeFromBustimes(Map<String, dynamic>.from(raw as Map)),
      ];
    } catch (_) {
      return const [];
    }
  }

  BusRoute _routeFromBustimes(Map<String, dynamic> json) {
    final operators = (json['operator'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
    return BusRoute(
      line: json['line_name'] as String? ?? '?',
      name: json['description'] as String? ?? '',
      operatorName: 'National Express West Midlands',
      operatorRefs: operators.isEmpty ? const ['TNXB'] : operators,
      bustimesServiceId: json['id'] as int?,
    );
  }

  Future<VehicleSnapshot> vehicles({
    required BusRoute route,
    required bool preferDemo,
  }) async {
    if (preferDemo || config.forceDemo) {
      return _mock.vehiclesFor(route);
    }

    if (config.hasBodsKey) {
      try {
        return await _bodsVehicles(route);
      } catch (error) {
        final fallback = await _bustimesVehiclesOrNull(route);
        if (fallback != null) {
          return VehicleSnapshot(
            vehicles: fallback.vehicles,
            source: fallback.source,
            fetchedAt: fallback.fetchedAt,
            warning: 'BODS failed (${_short(error)}); using bustimes.org.',
          );
        }
        return VehicleSnapshot(
          vehicles: _mock.vehiclesFor(route).vehicles,
          source: DataSource.mock,
          fetchedAt: DateTime.now(),
          warning: 'Live vehicles unavailable (${_short(error)}). Showing demo data.',
        );
      }
    }

    try {
      return await _bustimesVehicles(route);
    } catch (error) {
      return VehicleSnapshot(
        vehicles: _mock.vehiclesFor(route).vehicles,
        source: DataSource.mock,
        fetchedAt: DateTime.now(),
        warning: 'Live vehicles unavailable (${_short(error)}). Showing demo data.',
      );
    }
  }

  Future<DepartureSnapshot> departures({
    required BusRoute route,
    required BusStop? stop,
    required bool preferDemo,
  }) async {
    if (preferDemo || config.forceDemo) {
      return _mock.departuresFor(route, stop);
    }

    if (stop != null && config.hasTfwmKeys) {
      try {
        return await _tfwmDepartures(route, stop);
      } catch (error) {
        final fallback = await _bustimesDeparturesOrNull(route, stop);
        if (fallback != null) {
          return DepartureSnapshot(
            departures: fallback.departures,
            source: fallback.source,
            stop: stop,
            warning: 'TfWM arrivals failed (${_short(error)}); using bustimes.org.',
          );
        }
      }
    }

    if (stop != null) {
      try {
        return await _bustimesDepartures(route, stop);
      } catch (error) {
        return DepartureSnapshot(
          departures: _mock.departuresFor(route, stop).departures,
          source: DataSource.mock,
          stop: stop,
          warning: 'Live departures unavailable (${_short(error)}). Showing demo data.',
        );
      }
    }

    return _mock.departuresFor(route, stop);
  }

  Future<VehicleSnapshot> _bodsVehicles(BusRoute route) async {
    final bbox = Geography.westMidlandsBbox;
    final uri = Uri.parse(AppConfig.bodsDatafeedUrl).replace(
      queryParameters: {
        'api_key': config.bodsApiKey,
        'operatorRef': route.operatorRefs.join(','),
        'lineRef': route.line,
        'boundingBox': '${bbox.$1},${bbox.$2},${bbox.$3},${bbox.$4}',
      },
    );
    final xml = await _get(uri, accept: 'application/xml, text/xml, */*');
    final vehicles = parser.parse(xml, lineFilter: route.line);
    return VehicleSnapshot(
      vehicles: vehicles,
      source: DataSource.bods,
      fetchedAt: DateTime.now(),
    );
  }

  Future<VehicleSnapshot> _bustimesVehicles(BusRoute route) async {
    final serviceId = route.bustimesServiceId;
    final uri = Uri.parse(AppConfig.bustimesVehiclesUrl).replace(
      queryParameters: serviceId == null
          ? null
          : {'service': '$serviceId'},
    );
    final body = await _get(uri);
    final decoded = jsonDecode(body);
    if (decoded is! List) {
      throw TransitException('Unexpected vehicles payload');
    }
    final vehicles = <Vehicle>[];
    for (final raw in decoded) {
      final map = Map<String, dynamic>.from(raw as Map);
      final coords = map['coordinates'] as List<dynamic>?;
      if (coords == null || coords.length < 2) continue;
      final lon = (coords[0] as num).toDouble();
      final lat = (coords[1] as num).toDouble();
      final service = Map<String, dynamic>.from(
        (map['service'] as Map?) ?? const {},
      );
      final line = (service['line_name'] as String?) ?? route.line;
      if (line.toUpperCase() != route.line.toUpperCase()) continue;
      final vehicle = Map<String, dynamic>.from(
        (map['vehicle'] as Map?) ?? const {},
      );
      vehicles.add(
        Vehicle(
          id: '${map['id']}',
          line: line,
          location: LatLng(lat, lon),
          heading: (map['heading'] as num?)?.toDouble(),
          headsign: map['destination'] as String?,
          vehicleName: vehicle['name'] as String?,
          updatedAt: DateTime.tryParse(map['datetime'] as String? ?? ''),
          delaySeconds: (map['delay'] as num?)?.round(),
        ),
      );
    }
    return VehicleSnapshot(
      vehicles: vehicles,
      source: DataSource.bustimes,
      fetchedAt: DateTime.now(),
    );
  }

  Future<VehicleSnapshot?> _bustimesVehiclesOrNull(BusRoute route) async {
    try {
      return await _bustimesVehicles(route);
    } catch (_) {
      return null;
    }
  }

  Future<DepartureSnapshot> _bustimesDepartures(
    BusRoute route,
    BusStop stop,
  ) async {
    final body = await _get(Uri.parse(AppConfig.bustimesStopTimesUrl(stop.atco)));
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final times = decoded['times'] as List<dynamic>? ?? const [];
    final departures = <Departure>[];
    for (final raw in times) {
      final map = Map<String, dynamic>.from(raw as Map);
      final service = Map<String, dynamic>.from(
        (map['service'] as Map?) ?? const {},
      );
      final line = service['line_name'] as String? ?? '';
      if (line.toUpperCase() != route.line.toUpperCase()) continue;
      final destination = map['destination'];
      var headsign = route.name;
      if (destination is Map) {
        headsign = (destination['locality'] as String?) ??
            (destination['name'] as String?) ??
            headsign;
        final name = destination['name'] as String?;
        if (name != null && name.isNotEmpty) {
          headsign = name
              .replaceAll(RegExp(r'\s*\(Stop .+\)$'), '')
              .replaceAll(RegExp(r'^.*?,\s*(before|after|opp|adj)\s+'), '');
        }
      }
      final expected = DateTime.tryParse(
        (map['expected_departure_time'] as String?) ??
            (map['expected_arrival_time'] as String?) ??
            '',
      );
      final aimed = DateTime.tryParse(
        (map['aimed_departure_time'] as String?) ??
            (map['aimed_arrival_time'] as String?) ??
            '',
      );
      final when = expected ?? aimed;
      if (when == null) continue;
      departures.add(
        Departure(
          routeNumber: line,
          headsign: headsign,
          when: when,
          aimed: aimed,
          isRealtime: expected != null,
          isOverdue: map['overdue'] == true,
        ),
      );
    }
    departures.sort((a, b) => a.when.compareTo(b.when));
    return DepartureSnapshot(
      departures: departures,
      source: DataSource.bustimes,
      stop: stop,
    );
  }

  Future<DepartureSnapshot?> _bustimesDeparturesOrNull(
    BusRoute route,
    BusStop stop,
  ) async {
    try {
      return await _bustimesDepartures(route, stop);
    } catch (_) {
      return null;
    }
  }

  Future<DepartureSnapshot> _tfwmDepartures(
    BusRoute route,
    BusStop stop,
  ) async {
    final uri = Uri.parse(AppConfig.tfwmStopArrivalsUrl(stop.atco)).replace(
      queryParameters: {
        'app_id': config.tfwmAppId,
        'app_key': config.tfwmAppKey,
        'format': 'json',
      },
    );
    final body = await _get(uri);
    final decoded = jsonDecode(body);
    final rows = _flattenPredictions(decoded);
    final departures = <Departure>[];
    for (final map in rows) {
      final line = '${map['LineName'] ?? map['lineName'] ?? map['LineId'] ?? ''}';
      if (line.isNotEmpty && line.toUpperCase() != route.line.toUpperCase()) {
        continue;
      }
      final headsign =
          '${map['DestinationName'] ?? map['destinationName'] ?? route.name}';
      final when = DateTime.tryParse(
            '${map['EstimatedTime'] ?? map['expectedArrival'] ?? ''}',
          ) ??
          DateTime.tryParse('${map['ScheduledTime'] ?? map['aimedArrival'] ?? ''}');
      if (when == null) continue;
      departures.add(
        Departure(
          routeNumber: line.isEmpty ? route.line : line,
          headsign: headsign,
          when: when,
          isRealtime: map['EstimatedTime'] != null || map['expectedArrival'] != null,
        ),
      );
    }
    departures.sort((a, b) => a.when.compareTo(b.when));
    return DepartureSnapshot(
      departures: departures,
      source: DataSource.tfwm,
      stop: stop,
    );
  }

  List<Map<String, dynamic>> _flattenPredictions(Object? decoded) {
    if (decoded is List) {
      return [
        for (final item in decoded)
          if (item is Map) Map<String, dynamic>.from(item),
      ];
    }
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final predictions = map['Predictions'] ?? map['predictions'];
      if (predictions is Map) {
        final inner = predictions['Prediction'] ?? predictions['prediction'];
        return _flattenPredictions(inner);
      }
      if (predictions is List) return _flattenPredictions(predictions);
    }
    return const [];
  }

  Future<String> _get(Uri uri, {String? accept}) async {
    final response = await _client
        .get(
          uri,
          headers: {
            'User-Agent': AppConfig.httpUserAgent,
            'Accept': accept ?? 'application/json, text/xml, */*',
          },
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw TransitException(
        'Feed returned ${response.statusCode} (check API key)',
      );
    }
    if (response.statusCode >= 400) {
      throw TransitException('Feed returned HTTP ${response.statusCode}');
    }
    return response.body;
  }

  String _short(Object error) {
    final text = error.toString();
    return text.length > 80 ? '${text.substring(0, 80)}…' : text;
  }
}
