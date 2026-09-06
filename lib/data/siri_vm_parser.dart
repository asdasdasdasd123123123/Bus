import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart';

import '../models/models.dart';

/// Parses UK BODS SIRI-VM 2.0 XML into [Vehicle] records.
///
/// Element lookup is namespace-agnostic because BODS responses mix the
/// `http://www.siri.org.uk/siri` default namespace with unprefixed children.
class SiriVmParser {
  const SiriVmParser();

  List<Vehicle> parse(
    String xml, {
    String? lineFilter,
    bool Function(Vehicle vehicle)? keep,
  }) {
    final document = XmlDocument.parse(xml);
    final activities = document.descendants
        .whereType<XmlElement>()
        .where((e) => e.localName == 'VehicleActivity');

    final vehicles = <Vehicle>[];
    for (final activity in activities) {
      final journey = _child(activity, 'MonitoredVehicleJourney');
      if (journey == null) continue;

      final locationEl = _child(journey, 'VehicleLocation');
      final lat = _parseDouble(_text(locationEl, 'Latitude'));
      final lon = _parseDouble(_text(locationEl, 'Longitude'));
      if (lat == null || lon == null) continue;

      final line = _firstNonEmpty([
        _text(journey, 'PublishedLineName'),
        _text(journey, 'LineRef'),
      ]);
      if (lineFilter != null &&
          line != null &&
          line.toUpperCase() != lineFilter.toUpperCase()) {
        continue;
      }

      final id = _firstNonEmpty([
        _text(journey, 'VehicleRef'),
        _text(journey, 'VehicleJourneyRef'),
        _text(activity, 'ItemIdentifier'),
      ]);

      final recorded = _parseDate(
        _text(activity, 'RecordedAtTime') ?? _text(journey, 'RecordedAtTime'),
      );

      final vehicle = Vehicle(
        id: id ?? '${lat}_$lon',
        line: line ?? lineFilter ?? '?',
        location: LatLng(lat, lon),
        heading: _parseDouble(_text(journey, 'Bearing')),
        headsign: _firstNonEmpty([
          _text(journey, 'DestinationName'),
          _text(journey, 'DestinationRef'),
        ]),
        vehicleName: _text(journey, 'VehicleRef'),
        updatedAt: recorded,
        delaySeconds: _parseDelay(_text(journey, 'Delay')),
      );
      if (keep != null && !keep(vehicle)) continue;
      vehicles.add(vehicle);
    }
    return vehicles;
  }

  static XmlElement? _child(XmlElement? parent, String localName) {
    if (parent == null) return null;
    for (final child in parent.descendants.whereType<XmlElement>()) {
      if (child.localName == localName) return child;
    }
    return null;
  }

  static String? _text(XmlElement? parent, String localName) {
    final el = _child(parent, localName);
    if (el == null) return null;
    final value = el.innerText.trim();
    return value.isEmpty ? null : value;
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static double? _parseDouble(String? raw) =>
      raw == null ? null : double.tryParse(raw);

  static DateTime? _parseDate(String? raw) =>
      raw == null ? null : DateTime.tryParse(raw);

  /// BODS delay is typically `PT2M30S` or a signed seconds integer.
  static int? _parseDelay(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final asInt = int.tryParse(raw);
    if (asInt != null) return asInt;
    final match = RegExp(
      r'^(-?)P(?:(\d+)D)?T?(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$',
    ).firstMatch(raw);
    if (match == null) return null;
    final sign = match.group(1) == '-' ? -1 : 1;
    final days = int.tryParse(match.group(2) ?? '') ?? 0;
    final hours = int.tryParse(match.group(3) ?? '') ?? 0;
    final minutes = int.tryParse(match.group(4) ?? '') ?? 0;
    final seconds = int.tryParse(match.group(5) ?? '') ?? 0;
    return sign * (((days * 24 + hours) * 60 + minutes) * 60 + seconds);
  }
}
