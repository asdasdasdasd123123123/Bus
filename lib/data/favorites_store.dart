import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class FavoritesSnapshot {
  const FavoritesSnapshot({
    required this.routes,
    required this.stops,
    this.lastRouteId,
  });

  final List<FavoriteItem> routes;
  final List<FavoriteItem> stops;
  final String? lastRouteId;

  FavoritesSnapshot copyWith({
    List<FavoriteItem>? routes,
    List<FavoriteItem>? stops,
    String? lastRouteId,
  }) {
    return FavoritesSnapshot(
      routes: routes ?? this.routes,
      stops: stops ?? this.stops,
      lastRouteId: lastRouteId ?? this.lastRouteId,
    );
  }
}

class FavoritesStore {
  static const _key = 'birmingham_buses.favorites.v1';
  static const _routeKey = 'birmingham_buses.last_route.v1';

  Future<FavoritesSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final lastRouteId = prefs.getString(_routeKey);
    if (raw == null || raw.isEmpty) {
      return FavoritesSnapshot(
        routes: const [],
        stops: const [],
        lastRouteId: lastRouteId,
      );
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    List<FavoriteItem> parse(String field) {
      return (decoded[field] as List<dynamic>? ?? const [])
          .map(
            (e) => FavoriteItem.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    }

    return FavoritesSnapshot(
      routes: parse('routes'),
      stops: parse('stops'),
      lastRouteId: lastRouteId ?? decoded['lastRouteId'] as String?,
    );
  }

  Future<void> save(FavoritesSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'routes': snapshot.routes.map((e) => e.toJson()).toList(),
        'stops': snapshot.stops.map((e) => e.toJson()).toList(),
      }),
    );
    if (snapshot.lastRouteId != null) {
      await prefs.setString(_routeKey, snapshot.lastRouteId!);
    }
  }

  Future<void> saveLastRoute(String routeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_routeKey, routeId);
  }
}
