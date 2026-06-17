import 'package:aerocheck/data/regulatory/openaip_airport_repository.dart';
import 'package:aerocheck/data/regulatory/regulatory_repository_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'repository builds OpenAIP airports request with api key header',
    () async {
      Uri? requestedUri;
      Map<String, String>? requestedHeaders;
      final repository = OpenAipAirportRepository(
        apiKey: 'test-key',
        client: MockClient((request) async {
          requestedUri = request.url;
          requestedHeaders = request.headers;
          return http.Response(_openAipAirportsFixture, 200);
        }),
      );

      final airports = await repository.fetchNearbyAirports(
        latitude: -45.8641,
        longitude: -67.4966,
        radiusKm: 7,
      );

      expect(airports, hasLength(2));
      expect(requestedUri, isNotNull);
      expect(requestedUri!.path, '/api/airports');
      expect(requestedUri!.queryParameters['pos'], '-45.8641,-67.4966');
      expect(requestedUri!.queryParameters['dist'], '7000');
      expect(requestedUri!.queryParameters['limit'], '50');
      expect(requestedUri!.queryParameters['fields'], contains('geometry'));
      expect(requestedHeaders?['x-openaip-api-key'], 'test-key');
    },
  );

  test('maps OpenAIP airport response into domain model', () async {
    final repository = OpenAipAirportRepository(
      apiKey: 'test-key',
      client: MockClient(
        (request) async => http.Response(_openAipAirportsFixture, 200),
      ),
    );

    final airports = await repository.fetchNearbyAirports(
      latitude: -45.8641,
      longitude: -67.4966,
      radiusKm: 7,
    );

    expect(airports.first.id, 'airport-1');
    expect(airports.first.name, '13 DE DICIEMBRE');
    expect(airports.first.typeCode, 2);
    expect(airports.first.icaoCode, isNull);
    expect(airports.first.latitude, -45.904);
    expect(airports.first.longitude, -67.559);

    expect(airports.last.id, 'airport-2');
    expect(airports.last.name, 'COMODORO RIVADAVIA');
    expect(airports.last.icaoCode, 'SAVC');
    expect(airports.last.typeCode, 3);
  });

  test('throws controlled exception when api key is missing', () async {
    final repository = OpenAipAirportRepository(
      apiKey: '',
      client: MockClient((request) async => http.Response('{}', 200)),
    );

    expect(
      () => repository.fetchNearbyAirports(
        latitude: -45.8641,
        longitude: -67.4966,
        radiusKm: 7,
      ),
      throwsA(isA<RegulatoryRepositoryException>()),
    );
  });

  test('throws controlled exception for non-success status', () async {
    final repository = OpenAipAirportRepository(
      apiKey: 'test-key',
      client: MockClient((request) async => http.Response('failure', 401)),
    );

    expect(
      () => repository.fetchNearbyAirports(
        latitude: -45.8641,
        longitude: -67.4966,
        radiusKm: 7,
      ),
      throwsA(isA<RegulatoryRepositoryException>()),
    );
  });
}

const _openAipAirportsFixture = '''
{
  "page": 1,
  "limit": 50,
  "totalCount": 2,
  "totalPages": 1,
  "items": [
    {
      "_id": "airport-1",
      "name": "13 DE DICIEMBRE",
      "type": 2,
      "country": "AR",
      "geometry": {
        "type": "Point",
        "coordinates": [
          -67.559,
          -45.904
        ]
      }
    },
    {
      "_id": "airport-2",
      "name": "COMODORO RIVADAVIA",
      "icaoCode": "SAVC",
      "type": 3,
      "country": "AR",
      "geometry": {
        "type": "Point",
        "coordinates": [
          -67.466,
          -45.785
        ]
      }
    }
  ]
}
''';
