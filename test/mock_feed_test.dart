import 'package:bus/data/mock_feed.dart';
import 'package:bus/data/routes_catalog.dart';
import 'package:bus/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default catalog route is NXWM 16', () {
    final route = RoutesCatalog.defaultRoute;
    expect(route.line, '16');
    expect(route.isDefault, isTrue);
    expect(route.bustimesServiceId, 6247);
    expect(route.defaultStop?.atco, '43000203903');
  });

  test('mock feed produces red-dot vehicles and departures for route 16', () {
    final now = DateTime(2026, 9, 6, 12, 0);
    final feed = MockFeed(now: now);
    final vehicles = feed.vehiclesFor(RoutesCatalog.defaultRoute);
    expect(vehicles.source, DataSource.mock);
    expect(vehicles.vehicles, isNotEmpty);
    expect(vehicles.vehicles.every((v) => v.line == '16'), isTrue);

    final departures = feed.departuresFor(
      RoutesCatalog.defaultRoute,
      RoutesCatalog.defaultRoute.defaultStop,
    );
    expect(departures.departures, isNotEmpty);
    expect(departures.departures.first.routeNumber, '16');
    expect(departures.departures.first.headsign, isNotEmpty);
    expect(departures.departures.first.etaLabel(), isNotEmpty);
  });

  test('favorite JSON round-trips a route and a stop', () {
    final item = FavoriteItem(
      kind: 'route',
      id: RoutesCatalog.defaultRoute.id,
      label: 'Route 16',
      route: RoutesCatalog.defaultRoute,
    );
    final restored = FavoriteItem.fromJson(item.toJson());
    expect(restored.id, item.id);
    expect(restored.route?.line, '16');
    expect(restored.route?.stops.first.atco, '43000203903');
  });
}
