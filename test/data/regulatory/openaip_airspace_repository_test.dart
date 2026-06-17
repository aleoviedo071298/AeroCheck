import 'package:aerocheck/data/regulatory/openaip_airspace_repository.dart';
import 'package:aerocheck/data/regulatory/regulatory_repository_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'repository builds OpenAIP airspaces request with api key header',
    () async {
      Uri? requestedUri;
      Map<String, String>? requestedHeaders;
      final repository = OpenAipAirspaceRepository(
        apiKey: 'test-key',
        client: MockClient((request) async {
          requestedUri = request.url;
          requestedHeaders = request.headers;
          return http.Response(_openAipAirspacesFixture, 200);
        }),
      );

      final airspaces = await repository.fetchNearbyAirspaces(
        latitude: -45.8641,
        longitude: -67.4966,
        radiusKm: 7,
      );

      expect(airspaces, hasLength(2));
      expect(requestedUri, isNotNull);
      expect(requestedUri!.path, '/api/airspaces');
      expect(requestedUri!.queryParameters['pos'], '-45.8641,-67.4966');
      expect(requestedUri!.queryParameters['dist'], '7000');
      expect(requestedUri!.queryParameters['limit'], '50');
      expect(requestedUri!.queryParameters['fields'], contains('geometry'));
      expect(requestedHeaders?['x-openaip-api-key'], 'test-key');
    },
  );

  test('maps OpenAIP airspace response into compact model', () async {
    final repository = OpenAipAirspaceRepository(
      apiKey: 'test-key',
      client: MockClient(
        (request) async => http.Response(_openAipAirspacesFixture, 200),
      ),
    );

    final airspaces = await repository.fetchNearbyAirspaces(
      latitude: -45.8641,
      longitude: -67.4966,
      radiusKm: 7,
    );

    expect(airspaces.first.id, 'airspace-1');
    expect(airspaces.first.name, 'Comodoro CTR');
    expect(airspaces.first.typeLabel, 'Controlled Tower Region (CTR)');
    expect(airspaces.first.icaoClassLabel, 'D');
    expect(airspaces.first.country, 'AR');
    expect(airspaces.first.lowerLimitLabel, '0 ft GND');
    expect(airspaces.first.upperLimitLabel, '3500 ft MSL');
    expect(airspaces.first.coordinates, hasLength(4));
    expect(airspaces.first.coordinates.first.latitude, -45.8);
    expect(airspaces.first.coordinates.first.longitude, -67.6);
    expect(airspaces.last.typeLabel, 'Restricted');
    expect(airspaces.last.requestCompliance, isTrue);
  });

  test('throws controlled exception when api key is missing', () async {
    final repository = OpenAipAirspaceRepository(
      apiKey: '',
      client: MockClient((request) async => http.Response('{}', 200)),
    );

    expect(
      () => repository.fetchNearbyAirspaces(
        latitude: -45.8641,
        longitude: -67.4966,
        radiusKm: 7,
      ),
      throwsA(isA<RegulatoryRepositoryException>()),
    );
  });

  test('throws controlled exception for non-success status', () async {
    final repository = OpenAipAirspaceRepository(
      apiKey: 'test-key',
      client: MockClient((request) async => http.Response('failure', 401)),
    );

    expect(
      () => repository.fetchNearbyAirspaces(
        latitude: -45.8641,
        longitude: -67.4966,
        radiusKm: 7,
      ),
      throwsA(isA<RegulatoryRepositoryException>()),
    );
  });
}

const _openAipAirspacesFixture = '''
{
  "page": 1,
  "limit": 50,
  "totalCount": 2,
  "totalPages": 1,
  "items": [
    {
      "_id": "airspace-1",
      "name": "Comodoro CTR",
      "type": 4,
      "icaoClass": 3,
      "country": "AR",
      "requestCompliance": false,
      "lowerLimit": {"value": 0, "unit": 1, "referenceDatum": 0},
      "upperLimit": {"value": 3500, "unit": 1, "referenceDatum": 1},
      "geometry": {
        "type": "Polygon",
        "coordinates": [[
          [-67.6, -45.8],
          [-67.4, -45.8],
          [-67.4, -45.9],
          [-67.6, -45.8]
        ]]
      }
    },
    {
      "_id": "airspace-2",
      "name": "Zona restringida ejemplo",
      "type": 1,
      "icaoClass": 8,
      "country": "AR",
      "requestCompliance": true,
      "lowerLimit": {"value": 0, "unit": 0, "referenceDatum": 0},
      "upperLimit": {"value": 120, "unit": 0, "referenceDatum": 0},
      "geometry": {
        "type": "Polygon",
        "coordinates": [[
          [-67.5, -45.82],
          [-67.48, -45.84],
          [-67.52, -45.86],
          [-67.5, -45.82]
        ]]
      }
    }
  ]
}
''';
