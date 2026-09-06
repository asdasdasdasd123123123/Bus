# Birmingham Buses

Live map of National Express West Midlands buses around Birmingham. Default route on first launch is **16** (Birmingham – Great Barr via Hockley, Handsworth Wood & Hamstead).

The app is a Flutter project at the repository root (package name `bus`). You do **not** need a local Flutter install to put it on an Android phone — GitHub Actions builds an installable APK.

## Phone install (no developer tools)

1. On your phone, open this GitHub repo in a browser: [asdasdasdasd123123123/Bus](https://github.com/asdasdasdasd123123123/Bus).
2. Open the **Actions** tab.
3. Sign in to GitHub if asked (artifacts are visible to people with repo access).
4. Tap the latest **Android APK** workflow run (green tick). Runs start on push to `main`, on pull requests, or when you tap **Run workflow** (pick this PR branch if `main` has not been updated yet). Wait a few minutes, then open that run.
5. Scroll to **Artifacts** and download **birmingham-buses-apk**.
6. Unzip the download if needed and tap `app-release.apk`.
7. If Android blocks the install, allow installs from the browser / Files app, then try again.

The APK is a **release** build signed with Flutter’s **debug keystore** (see `android/app/build.gradle.kts`). That is intentional so the file installs without a Play Store upload key. Updates from later CI runs install over the same app. Do **not** use this signing for Google Play.

An optional **birmingham-buses-web** artifact is the same UI compiled for a browser. The native Android map (OpenStreetMap via `flutter_map`) is the intended experience.

### iOS

Installing on iPhone requires an Apple Developer account and TestFlight (or Xcode on a Mac). This repo does not block that, but it does not ship an iOS download. Use the Android APK or the web artifact.

## What you get

- Map with **small red dots** for live vehicles (not large pins). Blue dots are curated stops.
- Default **route 16**; the map fits those buses or Birmingham city centre.
- Route picker for other West Midlands / Birmingham NXWM routes (11A/11C, 50, X1, 9, …). Switching updates dots and departures.
- Live departures for the selected route / stop: **ETA, headsign, route number**.
- Favourites for routes and stops, stored on the device (`shared_preferences`).
- Auto-refresh every **20 seconds** while the map is open, plus pull-to-refresh on the departures sheet.
- Material 3, loading / empty / error states, and a **Demo / mock data** toggle.

## Data sources (verified)

| Source | Endpoint | Auth | Used for |
| --- | --- | --- | --- |
| **BODS SIRI-VM** | `https://data.bus-data.dft.gov.uk/api/v1/datafeed/?operatorRef=NWMS,TNXB&lineRef=16&boundingBox=…` | `api_key` | Official live vehicle positions |
| **BODS GTFS-RT** | `https://data.bus-data.dft.gov.uk/api/v1/gtfsrtdatafeed/` | `api_key` | Documented; vehicles use SIRI-VM XML |
| **TfWM arrivals** | `http://api.tfwm.org.uk/StopPoint/{atco}/Arrivals` | `app_id` + `app_key` | Official stop ETAs when configured |
| **TfWM GTFS-RT** | `http://api.tfwm.org.uk/gtfs/vehicle_positions` and `…/gtfs/trip_updates` | same | Documented; HTTP-only host |
| **bustimes.org** | `https://bustimes.org/vehicles.json?service=6247` and `/stops/{atco}/times.json` | none | Public live fallback so a key-less APK still shows buses |
| **Demo / mock** | in-app | none | Simulated 16 corridor if live feeds fail or `DEMO_MODE=true` |

BODS and TfWM were probed without credentials: BODS returns **401** (endpoint exists), TfWM returns **403 Authentication parameters missing**, and `…/siri-sm` is **404** (no BODS stop-monitoring API). Route 16 Birmingham service id **6247** and Digbeth Markets stop **43000203903** were confirmed live.

Get a free BODS key: [register](https://data.bus-data.dft.gov.uk/account/signup/) → Account Settings. TfWM keys: [api-portal.tfwm.org.uk](https://api-portal.tfwm.org.uk/).

**Never commit secrets.** Use `--dart-define` or a private GitHub Actions secret if you rebuild with a key.

## Run locally (contributors)

```bash
flutter pub get
flutter analyze
flutter test

# Demo data only
flutter run --dart-define=DEMO_MODE=true

# Official BODS vehicles (falls back to bustimes.org / mock on error)
flutter run --dart-define=BODS_API_KEY=your_key_here

# Optional TfWM stop arrivals
flutter run --dart-define=TFWM_APP_ID=xxx --dart-define=TFWM_APP_KEY=yyy
```

See `.env.example` for the variable names. There is no committed `.env`.

Default first-launch route is **16**. Map tiles are OpenStreetMap (`flutter_map`). State uses **Riverpod**.

## Signing notes

CI and `flutter build apk --release` use the Android **debug** signing config so anyone can sideload the artifact. Replace `signingConfig` in `android/app/build.gradle.kts` with your own upload keystore before Play Store publishing.

## License / attribution

Bus times and locations are public-sector / operator open data (BODS, TfWM) and bustimes.org. Map © OpenStreetMap contributors.
