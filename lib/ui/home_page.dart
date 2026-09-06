import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/geography.dart';
import '../models/models.dart';
import '../providers/providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _mapController = MapController();
  String? _fittedRouteId;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      ref.read(vehiclesProvider.notifier).refresh(),
      ref.read(departuresProvider.notifier).refresh(),
    ]);
  }

  void _fitToVehicles(List<Vehicle> vehicles, String routeId) {
    if (!mounted) return;
    if (vehicles.isEmpty) {
      _mapController.move(Geography.birminghamCentre, Geography.defaultZoom);
      _fittedRouteId = routeId;
      return;
    }
    if (vehicles.length == 1) {
      _mapController.move(vehicles.first.location, 14);
      _fittedRouteId = routeId;
      return;
    }
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: [for (final v in vehicles) v.location],
        padding: const EdgeInsets.fromLTRB(36, 120, 36, 220),
        maxZoom: 14.2,
        minZoom: 11,
      ),
    );
    _fittedRouteId = routeId;
  }

  @override
  Widget build(BuildContext context) {
    final route = ref.watch(selectedRouteProvider);
    final vehicles = ref.watch(vehiclesProvider);
    final favorites = ref.watch(favoritesProvider);
    final isFav = favorites.asData?.value.routes.any((e) => e.id == route.id) ??
        false;

    ref.listen<AsyncValue<VehicleSnapshot>>(vehiclesProvider, (prev, next) {
      final snap = next.asData?.value;
      if (snap == null) return;
      if (_fittedRouteId != route.id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitToVehicles(snap.vehicles, route.id);
        });
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Birmingham Buses'),
        actions: [
          IconButton(
            tooltip: isFav ? 'Remove route from favourites' : 'Save route',
            onPressed: () =>
                ref.read(favoritesProvider.notifier).toggleRoute(route),
            icon: Icon(isFav ? Icons.star : Icons.star_border),
          ),
          IconButton(
            tooltip: 'Favourites',
            onPressed: () => _showFavorites(context),
            icon: const Icon(Icons.bookmarks_outlined),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'demo':
                  ref.read(demoModeProvider.notifier).toggle();
                case 'center':
                  final list = vehicles.asData?.value.vehicles ?? const [];
                  _fitToVehicles(list, route.id);
                case 'about':
                  _showAbout(context);
              }
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: 'demo',
                checked: ref.watch(demoModeProvider),
                child: const Text('Demo / mock data'),
              ),
              const PopupMenuItem(
                value: 'center',
                child: Text('Fit map to buses'),
              ),
              const PopupMenuItem(value: 'about', child: Text('Data sources')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRoutePicker(context),
        icon: const Icon(Icons.alt_route),
        label: Text('Route ${route.line}'),
      ),
      body: Stack(
        children: [
          _BusMap(
            controller: _mapController,
            vehicles: vehicles.asData?.value.vehicles ?? const [],
            stops: route.stops,
            selectedStop: ref.watch(selectedStopProvider),
          ),
          if (vehicles.isLoading && !vehicles.hasValue)
            const SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 72),
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Loading live buses…'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _DeparturesSheet(onRefresh: _refreshAll),
          ),
        ],
      ),
    );
  }

  Future<void> _showRoutePicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => const _RoutePickerSheet(),
    );
  }

  Future<void> _showFavorites(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => const _FavoritesSheet(),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data sources'),
        content: const Text(
          'Live vehicles: UK Bus Open Data Service SIRI-VM '
          '(data.bus-data.dft.gov.uk) when BODS_API_KEY is set.\n\n'
          'Without a key the app uses bustimes.org public JSON '
          '(itself sourced from BODS) so a phone APK still shows live dots.\n\n'
          'Departures: bustimes.org stop times, or TfWM StopPoint arrivals '
          'when TFWM_APP_ID and TFWM_APP_KEY are set.\n\n'
          'Demo mode simulates the 16 corridor without any network key.\n\n'
          'Map tiles: OpenStreetMap. Never commit API keys.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _BusMap extends StatelessWidget {
  const _BusMap({
    required this.controller,
    required this.vehicles,
    required this.stops,
    required this.selectedStop,
  });

  final MapController controller;
  final List<Vehicle> vehicles;
  final List<BusStop> stops;
  final BusStop? selectedStop;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: const MapOptions(
        initialCenter: Geography.birminghamCentre,
        initialZoom: Geography.defaultZoom,
        backgroundColor: Color(0xFFE8EEF2),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.birmingham.bus',
          maxZoom: 19,
        ),
        CircleLayer(
          circles: [
            for (final stop in stops)
              if (stop.location != null)
                CircleMarker(
                  point: stop.location!,
                  radius: stop == selectedStop ? 6 : 4,
                  color: stop == selectedStop
                      ? const Color(0xFF1565C0)
                      : const Color(0xAA1565C0),
                  borderColor: Colors.white,
                  borderStrokeWidth: 1,
                ),
          ],
        ),
        CircleLayer(
          circles: [
            for (final vehicle in vehicles)
              CircleMarker(
                point: vehicle.location,
                radius: 5,
                  color: const Color(0xFFE53935),
                  borderColor: Colors.white,
                  borderStrokeWidth: 1.2,
                ),
          ],
        ),
        RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _DeparturesSheet extends ConsumerWidget {
  const _DeparturesSheet({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(selectedRouteProvider);
    final stop = ref.watch(selectedStopProvider);
    final departures = ref.watch(departuresProvider);
    final vehicles = ref.watch(vehiclesProvider);
    final theme = Theme.of(context);
    final source = vehicles.asData?.value.source;
    final warning = vehicles.asData?.value.warning ??
        departures.asData?.value.warning;

    return DraggableScrollableSheet(
      initialChildSize: 0.34,
      minChildSize: 0.22,
      maxChildSize: 0.78,
      builder: (context, controller) {
        return Material(
          elevation: 10,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          color: theme.colorScheme.surface,
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      child: Text(
                        route.line.length > 3
                            ? route.line.substring(0, 3)
                            : route.line,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route.name,
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            route.operatorName,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (source != null)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(source.label),
                      ),
                  ],
                ),
                if (warning != null) ...[
                  const SizedBox(height: 8),
                  Text(warning, style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: 8),
                _StopSelector(route: route, stop: stop),
                const SizedBox(height: 8),
                Text('Live departures', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                ...departures.when(
                  loading: () => [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                  error: (error, _) => [
                    _StatusCard(
                      icon: Icons.error_outline,
                      title: 'Could not load departures',
                      body: error.toString(),
                      onRetry: () =>
                          ref.read(departuresProvider.notifier).refresh(),
                    ),
                  ],
                  data: (snap) {
                    if (snap.departures.isEmpty) {
                      return [
                        _StatusCard(
                          icon: Icons.schedule,
                          title: 'No departures right now',
                          body: stop == null
                              ? 'Pick a stop to see ETAs, headsign and route number.'
                              : 'Nothing due at ${stop.label} for route ${route.line}.',
                        ),
                      ];
                    }
                    return [
                      for (final item in snap.departures)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Badge(
                            label: Text(item.isRealtime ? 'Live' : 'TT'),
                            child: CircleAvatar(
                              child: Text(item.routeNumber),
                            ),
                          ),
                          title: Text(item.headsign),
                          subtitle: Text(
                            item.isRealtime
                                ? 'Realtime · route ${item.routeNumber}'
                                : 'Timetable · route ${item.routeNumber}',
                          ),
                          trailing: Text(
                            item.etaLabel(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ];
                  },
                ),
                vehicles.when(
                  loading: () => const SizedBox.shrink(),
                  error: (error, _) => _StatusCard(
                    icon: Icons.map_outlined,
                    title: 'Map vehicles unavailable',
                    body: error.toString(),
                    onRetry: () =>
                        ref.read(vehiclesProvider.notifier).refresh(),
                  ),
                  data: (snap) {
                    if (snap.vehicles.isEmpty) {
                      return _StatusCard(
                        icon: Icons.directions_bus_outlined,
                        title: 'No buses reporting',
                        body:
                            'No live vehicles for route ${route.line}. '
                            'The map is centred on Birmingham city centre.',
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${snap.vehicles.length} buses on the map'
                        '${snap.fetchedAt == null ? '' : ' · updated ${_time(snap.fetchedAt!)}'}',
                        style: theme.textTheme.bodySmall,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _time(DateTime when) {
    final local = when.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _StopSelector extends ConsumerWidget {
  const _StopSelector({required this.route, required this.stop});

  final BusRoute route;
  final BusStop? stop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stops = route.stops;
    if (stops.isEmpty) {
      return Text(
        'No curated stops for this route. Favourites can still save a stop once one is selected.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Row(
      children: [
        Expanded(
          child: DropdownMenu<BusStop>(
            initialSelection: stop,
            expandedInsets: EdgeInsets.zero,
            label: const Text('Stop'),
            dropdownMenuEntries: [
              for (final item in stops)
                DropdownMenuEntry(value: item, label: item.label),
            ],
            onSelected: (value) {
              if (value != null) {
                ref.read(selectedStopProvider.notifier).choose(value);
              }
            },
          ),
        ),
        if (stop != null)
          IconButton(
            tooltip: 'Favourite this stop',
            onPressed: () =>
                ref.read(favoritesProvider.notifier).toggleStop(stop!, route),
            icon: Icon(
              ref.watch(favoritesProvider).asData?.value.stops.any(
                            (item) => item.id == stop!.atco,
                          ) ??
                      false
                  ? Icons.favorite
                  : Icons.favorite_border,
            ),
          ),
      ],
    );
  }
}

class _RoutePickerSheet extends ConsumerStatefulWidget {
  const _RoutePickerSheet();

  @override
  ConsumerState<_RoutePickerSheet> createState() => _RoutePickerSheetState();
}

class _RoutePickerSheetState extends ConsumerState<_RoutePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(routeCatalogProvider);
    final favorites = ref.watch(favoritesProvider).asData?.value;
    final selected = ref.watch(selectedRouteProvider);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('West Midlands routes',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search 16, X1, Outer Circle…',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: catalog.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _StatusCard(
                  icon: Icons.error_outline,
                  title: 'Could not load extra routes',
                  body: '$error\nPopular Birmingham routes are still available.',
                ),
                data: (routes) {
                  final q = _query.toLowerCase();
                  final filtered = q.isEmpty
                      ? routes
                      : routes
                          .where(
                            (r) =>
                                r.line.toLowerCase().contains(q) ||
                                r.name.toLowerCase().contains(q),
                          )
                          .toList();
                  final favRoutes = favorites?.routes
                          .map((e) => e.route)
                          .whereType<BusRoute>()
                          .toList() ??
                      const <BusRoute>[];
                  return ListView(
                    children: [
                      if (favRoutes.isNotEmpty && q.isEmpty) ...[
                        Text(
                          'Favourites',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        for (final route in favRoutes)
                          _RouteTile(
                            route: route,
                            selected: route.id == selected.id,
                          ),
                        const Divider(),
                      ],
                      if (filtered.isEmpty)
                        const _StatusCard(
                          icon: Icons.search_off,
                          title: 'No matching routes',
                          body: 'Try a line number such as 16, 50 or X1.',
                        )
                      else
                        for (final route in filtered)
                          _RouteTile(
                            route: route,
                            selected: route.id == selected.id,
                          ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteTile extends ConsumerWidget {
  const _RouteTile({required this.route, required this.selected});

  final BusRoute route;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      selected: selected,
      leading: CircleAvatar(child: Text(route.line)),
      title: Text('Route ${route.line}'),
      subtitle: Text(route.name),
      trailing: selected ? const Icon(Icons.check) : null,
      onTap: () async {
        await ref.read(selectedRouteProvider.notifier).choose(route);
        if (context.mounted) Navigator.pop(context);
      },
    );
  }
}

class _FavoritesSheet extends ConsumerWidget {
  const _FavoritesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: favorites.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _StatusCard(
            icon: Icons.error_outline,
            title: 'Favourites unavailable',
            body: error.toString(),
          ),
          data: (snap) {
            if (snap.routes.isEmpty && snap.stops.isEmpty) {
              return const _StatusCard(
                icon: Icons.star_border,
                title: 'No favourites yet',
                body:
                    'Star a route from the app bar, or heart a stop in the departures panel.',
              );
            }
            return ListView(
              children: [
                Text('Favourites',
                    style: Theme.of(context).textTheme.titleLarge),
                if (snap.routes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Routes', style: Theme.of(context).textTheme.titleSmall),
                  for (final item in snap.routes)
                    ListTile(
                      leading: const Icon(Icons.directions_bus),
                      title: Text(item.label),
                      subtitle: Text(item.route?.name ?? ''),
                      onTap: () async {
                        if (item.route != null) {
                          await ref
                              .read(selectedRouteProvider.notifier)
                              .choose(item.route!);
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                ],
                if (snap.stops.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Stops', style: Theme.of(context).textTheme.titleSmall),
                  for (final item in snap.stops)
                    ListTile(
                      leading: const Icon(Icons.place_outlined),
                      title: Text(item.label),
                      subtitle: Text(
                        item.route == null
                            ? item.stop?.atco ?? ''
                            : 'Route ${item.route!.line}',
                      ),
                      onTap: () async {
                        if (item.route != null) {
                          await ref
                              .read(selectedRouteProvider.notifier)
                              .choose(item.route!);
                        }
                        if (item.stop != null) {
                          ref
                              .read(selectedStopProvider.notifier)
                              .choose(item.stop);
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.body,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(body, textAlign: TextAlign.center),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
