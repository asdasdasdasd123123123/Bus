/// Compile-time configuration. Secrets are injected with `--dart-define`
/// and must never be committed.
class AppConfig {
  const AppConfig({
    required this.bodsApiKey,
    required this.tfwmAppId,
    required this.tfwmAppKey,
    required this.forceDemo,
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      bodsApiKey: String.fromEnvironment('BODS_API_KEY'),
      tfwmAppId: String.fromEnvironment('TFWM_APP_ID'),
      tfwmAppKey: String.fromEnvironment('TFWM_APP_KEY'),
      forceDemo: bool.fromEnvironment('DEMO_MODE'),
    );
  }

  final String bodsApiKey;
  final String tfwmAppId;
  final String tfwmAppKey;
  final bool forceDemo;

  bool get hasBodsKey => bodsApiKey.isNotEmpty;
  bool get hasTfwmKeys => tfwmAppId.isNotEmpty && tfwmAppKey.isNotEmpty;

  /// Official BODS SIRI-VM vehicle feed (requires [bodsApiKey]).
  static const bodsDatafeedUrl =
      'https://data.bus-data.dft.gov.uk/api/v1/datafeed/';

  /// Official BODS GTFS-RT snapshot (requires [bodsApiKey]).
  static const bodsGtfsRtUrl =
      'https://data.bus-data.dft.gov.uk/api/v1/gtfsrtdatafeed/';

  /// TfWM GTFS-RT (HTTP; documented by the TfWM API portal).
  static const tfwmVehiclePositionsUrl =
      'http://api.tfwm.org.uk/gtfs/vehicle_positions';
  static const tfwmTripUpdatesUrl =
      'http://api.tfwm.org.uk/gtfs/trip_updates';

  static String tfwmStopArrivalsUrl(String atco) =>
      'http://api.tfwm.org.uk/StopPoint/$atco/Arrivals';

  /// Public bustimes.org endpoints used when no official key is present.
  static const bustimesVehiclesUrl = 'https://bustimes.org/vehicles.json';
  static const bustimesServicesUrl = 'https://bustimes.org/api/services/';
  static const bustimesStopsUrl = 'https://bustimes.org/api/stops/';

  static String bustimesStopTimesUrl(String atco) =>
      'https://bustimes.org/stops/$atco/times.json';

  static const httpUserAgent =
      'BirminghamBuses/1.0 (Flutter; https://github.com/asdasdasdasd123123123/Bus)';
}
