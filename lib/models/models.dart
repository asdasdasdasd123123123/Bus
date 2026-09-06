import 'package:latlong2/latlong.dart';

enum DataSource { bods, tfwm, bustimes, mock }

extension DataSourceLabel on DataSource {
  String get label => switch (this) {
        DataSource.bods => 'BODS live',
        DataSource.tfwm => 'TfWM live',
        DataSource.bustimes => 'Live (bustimes.org)',
        DataSource.mock => 'Demo data',
      };

  String get detail => switch (this) {
        DataSource.bods =>
          'Vehicle positions from the UK Bus Open Data Service SIRI-VM feed.',
        DataSource.tfwm =>
          'Stop arrivals from the Transport for West Midlands API.',
        DataSource.bustimes =>
          'Public live positions from bustimes.org (sourced from BODS). '
              'Add a BODS API key for the official feed.',
        DataSource.mock =>
          'Simulated West Midlands buses so the UI works without an API key.',
      };
}

class BusRoute {
  const BusRoute({
    required this.line,
    required this.name,
    required this.operatorName,
    this.operatorRefs = const ['NWMS', 'TNXB'],
    this.bustimesServiceId,
    this.stops = const [],
    this.isDefault = false,
  });

  final String line;
  final String name;
  final String operatorName;
  final List<String> operatorRefs;
  final int? bustimesServiceId;
  final List<BusStop> stops;
  final bool isDefault;

  String get id => '${operatorRefs.first}|$line|${bustimesServiceId ?? 0}';

  String get subtitle => '$operatorName · $name';

  BusStop? get defaultStop => stops.isEmpty ? null : stops.first;

  BusRoute copyWith({List<BusStop>? stops}) {
    return BusRoute(
      line: line,
      name: name,
      operatorName: operatorName,
      operatorRefs: operatorRefs,
      bustimesServiceId: bustimesServiceId,
      stops: stops ?? this.stops,
      isDefault: isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'line': line,
        'name': name,
        'operatorName': operatorName,
        'operatorRefs': operatorRefs,
        'bustimesServiceId': bustimesServiceId,
        'isDefault': isDefault,
        'stops': stops.map((s) => s.toJson()).toList(),
      };

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      line: json['line'] as String,
      name: json['name'] as String? ?? '',
      operatorName: json['operatorName'] as String? ?? 'National Express WM',
      operatorRefs: (json['operatorRefs'] as List<dynamic>? ?? const ['NWMS'])
          .map((e) => e.toString())
          .toList(),
      bustimesServiceId: json['bustimesServiceId'] as int?,
      isDefault: json['isDefault'] as bool? ?? false,
      stops: (json['stops'] as List<dynamic>? ?? const [])
          .map((e) => BusStop.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BusRoute && other.id == id && other.line == line;

  @override
  int get hashCode => id.hashCode;
}

class BusStop {
  const BusStop({
    required this.atco,
    required this.name,
    this.indicator,
    this.location,
  });

  final String atco;
  final String name;
  final String? indicator;
  final LatLng? location;

  String get label =>
      indicator == null || indicator!.isEmpty ? name : '$name ($indicator)';

  Map<String, dynamic> toJson() => {
        'atco': atco,
        'name': name,
        'indicator': indicator,
        'lat': location?.latitude,
        'lon': location?.longitude,
      };

  factory BusStop.fromJson(Map<String, dynamic> json) {
    final lat = (json['lat'] as num?)?.toDouble();
    final lon = (json['lon'] as num?)?.toDouble();
    return BusStop(
      atco: json['atco'] as String,
      name: json['name'] as String,
      indicator: json['indicator'] as String?,
      location: lat != null && lon != null ? LatLng(lat, lon) : null,
    );
  }

  @override
  bool operator ==(Object other) => other is BusStop && other.atco == atco;

  @override
  int get hashCode => atco.hashCode;
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.line,
    required this.location,
    this.heading,
    this.headsign,
    this.vehicleName,
    this.updatedAt,
    this.delaySeconds,
  });

  final String id;
  final String line;
  final LatLng location;
  final double? heading;
  final String? headsign;
  final String? vehicleName;
  final DateTime? updatedAt;
  final int? delaySeconds;
}

class Departure {
  const Departure({
    required this.routeNumber,
    required this.headsign,
    required this.when,
    this.aimed,
    this.isRealtime = false,
    this.isOverdue = false,
  });

  final String routeNumber;
  final String headsign;
  final DateTime when;
  final DateTime? aimed;
  final bool isRealtime;
  final bool isOverdue;

  int get minutesUntil {
    final delta = when.difference(DateTime.now()).inMinutes;
    return delta;
  }

  String etaLabel() {
    final mins = minutesUntil;
    if (isOverdue && mins <= 0) return 'Due';
    if (mins <= 0) return 'Due';
    if (mins == 1) return '1 min';
    if (mins < 60) return '$mins min';
    final hour = when.toLocal();
    final hh = hour.hour.toString().padLeft(2, '0');
    final mm = hour.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class VehicleSnapshot {
  const VehicleSnapshot({
    required this.vehicles,
    required this.source,
    this.fetchedAt,
    this.warning,
  });

  final List<Vehicle> vehicles;
  final DataSource source;
  final DateTime? fetchedAt;
  final String? warning;
}

class DepartureSnapshot {
  const DepartureSnapshot({
    required this.departures,
    required this.source,
    this.stop,
    this.warning,
  });

  final List<Departure> departures;
  final DataSource source;
  final BusStop? stop;
  final String? warning;
}

class FavoriteItem {
  const FavoriteItem({
    required this.kind,
    required this.id,
    required this.label,
    this.route,
    this.stop,
  });

  final String kind; // route | stop
  final String id;
  final String label;
  final BusRoute? route;
  final BusStop? stop;

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'id': id,
        'label': label,
        'route': route?.toJson(),
        'stop': stop?.toJson(),
      };

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      kind: json['kind'] as String,
      id: json['id'] as String,
      label: json['label'] as String,
      route: json['route'] == null
          ? null
          : BusRoute.fromJson(Map<String, dynamic>.from(json['route'] as Map)),
      stop: json['stop'] == null
          ? null
          : BusStop.fromJson(Map<String, dynamic>.from(json['stop'] as Map)),
    );
  }
}
