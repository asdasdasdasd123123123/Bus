import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../data/favorites_store.dart';
import '../data/routes_catalog.dart';
import '../data/transit_repository.dart';
import '../models/models.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

final transitRepositoryProvider = Provider<TransitRepository>((ref) {
  return TransitRepository(config: ref.watch(appConfigProvider));
});

final favoritesStoreProvider = Provider<FavoritesStore>((ref) {
  return FavoritesStore();
});

class DemoMode extends Notifier<bool> {
  @override
  bool build() => ref.watch(appConfigProvider).forceDemo;

  void toggle() {
    if (ref.read(appConfigProvider).forceDemo) return;
    state = !state;
  }
}

final demoModeProvider = NotifierProvider<DemoMode, bool>(DemoMode.new);

class SelectedRoute extends Notifier<BusRoute> {
  @override
  BusRoute build() => RoutesCatalog.defaultRoute;

  Future<void> choose(BusRoute route) async {
    state = route;
    await ref.read(favoritesStoreProvider).saveLastRoute(route.id);
    final stop = route.defaultStop;
    ref.read(selectedStopProvider.notifier).choose(stop);
  }

  void restore(BusRoute route) {
    state = route;
    ref.read(selectedStopProvider.notifier).choose(route.defaultStop);
  }
}

final selectedRouteProvider =
    NotifierProvider<SelectedRoute, BusRoute>(SelectedRoute.new);

class SelectedStop extends Notifier<BusStop?> {
  @override
  BusStop? build() => RoutesCatalog.defaultRoute.defaultStop;

  void choose(BusStop? stop) => state = stop;
}

final selectedStopProvider =
    NotifierProvider<SelectedStop, BusStop?>(SelectedStop.new);

class RouteCatalog extends AsyncNotifier<List<BusRoute>> {
  @override
  Future<List<BusRoute>> build() async {
    final extras =
        await ref.watch(transitRepositoryProvider).extraRoutes();
    final merged = <String, BusRoute>{
      for (final route in RoutesCatalog.popular) route.id: route,
    };
    for (final extra in extras) {
      merged.putIfAbsent(extra.id, () => extra);
    }
    final routes = merged.values.toList()
      ..sort((a, b) {
        if (a.isDefault) return -1;
        if (b.isDefault) return 1;
        final byLine = _lineKey(a.line).compareTo(_lineKey(b.line));
        if (byLine != 0) return byLine;
        return a.name.compareTo(b.name);
      });
    return routes;
  }

  String _lineKey(String line) {
    final match = RegExp(r'^(\d+)').firstMatch(line);
    if (match == null) return 'z$line';
    return match.group(1)!.padLeft(4, '0') + line;
  }
}

final routeCatalogProvider =
    AsyncNotifierProvider<RouteCatalog, List<BusRoute>>(RouteCatalog.new);

class VehiclesController extends AsyncNotifier<VehicleSnapshot> {
  @override
  Future<VehicleSnapshot> build() async {
    final timer = Timer.periodic(const Duration(seconds: 20), (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
    final route = ref.watch(selectedRouteProvider);
    final demo = ref.watch(demoModeProvider);
    return ref.read(transitRepositoryProvider).vehicles(
          route: route,
          preferDemo: demo,
        );
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final route = ref.read(selectedRouteProvider);
      final demo = ref.read(demoModeProvider);
      return ref.read(transitRepositoryProvider).vehicles(
            route: route,
            preferDemo: demo,
          );
    });
  }
}

final vehiclesProvider =
    AsyncNotifierProvider<VehiclesController, VehicleSnapshot>(
  VehiclesController.new,
);

class DeparturesController extends AsyncNotifier<DepartureSnapshot> {
  @override
  Future<DepartureSnapshot> build() async {
    final route = ref.watch(selectedRouteProvider);
    final stop = ref.watch(selectedStopProvider);
    final demo = ref.watch(demoModeProvider);
    return ref.read(transitRepositoryProvider).departures(
          route: route,
          stop: stop,
          preferDemo: demo,
        );
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      return ref.read(transitRepositoryProvider).departures(
            route: ref.read(selectedRouteProvider),
            stop: ref.read(selectedStopProvider),
            preferDemo: ref.read(demoModeProvider),
          );
    });
  }
}

final departuresProvider =
    AsyncNotifierProvider<DeparturesController, DepartureSnapshot>(
  DeparturesController.new,
);

class FavoritesController extends AsyncNotifier<FavoritesSnapshot> {
  @override
  Future<FavoritesSnapshot> build() async {
    final snapshot = await ref.watch(favoritesStoreProvider).load();
    _restoreLastRoute(snapshot.lastRouteId);
    return snapshot;
  }

  void _restoreLastRoute(String? lastRouteId) {
    if (lastRouteId == null) return;
    final catalog = [
      ...RoutesCatalog.popular,
      ...?ref.read(routeCatalogProvider).asData?.value,
    ];
    for (final route in catalog) {
      if (route.id == lastRouteId) {
        ref.read(selectedRouteProvider.notifier).restore(route);
        return;
      }
    }
  }

  Future<void> _persist(FavoritesSnapshot snapshot) async {
    state = AsyncData(snapshot);
    await ref.read(favoritesStoreProvider).save(snapshot);
  }

  bool isRouteFavorite(BusRoute route) {
    final current = state.asData?.value;
    if (current == null) return false;
    return current.routes.any((item) => item.id == route.id);
  }

  bool isStopFavorite(BusStop stop) {
    final current = state.asData?.value;
    if (current == null) return false;
    return current.stops.any((item) => item.id == stop.atco);
  }

  Future<void> toggleRoute(BusRoute route) async {
    final current = state.asData?.value ??
        const FavoritesSnapshot(routes: [], stops: []);
    final exists = current.routes.any((item) => item.id == route.id);
    final routes = exists
        ? current.routes.where((item) => item.id != route.id).toList()
        : [
            ...current.routes,
            FavoriteItem(
              kind: 'route',
              id: route.id,
              label: 'Route ${route.line}',
              route: route,
            ),
          ];
    await _persist(current.copyWith(routes: routes, lastRouteId: route.id));
  }

  Future<void> toggleStop(BusStop stop, BusRoute route) async {
    final current = state.asData?.value ??
        const FavoritesSnapshot(routes: [], stops: []);
    final exists = current.stops.any((item) => item.id == stop.atco);
    final stops = exists
        ? current.stops.where((item) => item.id != stop.atco).toList()
        : [
            ...current.stops,
            FavoriteItem(
              kind: 'stop',
              id: stop.atco,
              label: stop.label,
              route: route,
              stop: stop,
            ),
          ];
    await _persist(current.copyWith(stops: stops));
  }
}

final favoritesProvider =
    AsyncNotifierProvider<FavoritesController, FavoritesSnapshot>(
  FavoritesController.new,
);
