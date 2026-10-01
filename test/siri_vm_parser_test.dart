import 'package:bus/data/siri_vm_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sample = '''
<?xml version="1.0" encoding="UTF-8"?>
<Siri xmlns="http://www.siri.org.uk/siri" version="2.0">
  <ServiceDelivery>
    <VehicleMonitoringDelivery>
      <VehicleActivity>
        <RecordedAtTime>2026-09-06T11:20:00+01:00</RecordedAtTime>
        <MonitoredVehicleJourney>
          <LineRef>16</LineRef>
          <PublishedLineName>16</PublishedLineName>
          <DirectionRef>outbound</DirectionRef>
          <OperatorRef>NWMS</OperatorRef>
          <VehicleRef>E203</VehicleRef>
          <DestinationName>Great Barr</DestinationName>
          <VehicleLocation>
            <Longitude>-1.89588</Longitude>
            <Latitude>52.48294</Latitude>
          </VehicleLocation>
          <Bearing>330</Bearing>
          <Delay>PT1M30S</Delay>
        </MonitoredVehicleJourney>
      </VehicleActivity>
      <VehicleActivity>
        <MonitoredVehicleJourney>
          <LineRef>50</LineRef>
          <VehicleRef>2099</VehicleRef>
          <VehicleLocation>
            <Longitude>-1.89</Longitude>
            <Latitude>52.47</Latitude>
          </VehicleLocation>
        </MonitoredVehicleJourney>
      </VehicleActivity>
    </VehicleMonitoringDelivery>
  </ServiceDelivery>
</Siri>
''';

  test('parses BODS SIRI-VM vehicles and filters by line', () {
    const parser = SiriVmParser();
    final all = parser.parse(sample);
    expect(all, hasLength(2));

    final sixteen = parser.parse(sample, lineFilter: '16');
    expect(sixteen, hasLength(1));
    expect(sixteen.single.line, '16');
    expect(sixteen.single.headsign, 'Great Barr');
    expect(sixteen.single.location.latitude, closeTo(52.48294, 0.00001));
    expect(sixteen.single.location.longitude, closeTo(-1.89588, 0.00001));
    expect(sixteen.single.heading, 330);
    expect(sixteen.single.delaySeconds, 90);
  });
}
