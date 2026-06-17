import 'dart:convert';

import 'package:http/http.dart' as http;

class NoaaKpIndexService {
  NoaaKpIndexService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _baseUrl =
      'https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json';

  Future<double?> fetchCurrentKpIndex() async {
    try {
      final response = await _client
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty) {
        final lastEntry = data.last;
        if (lastEntry is Map<String, Object?>) {
          final kp = lastEntry['Kp'];
          if (kp is num) {
            return kp.toDouble();
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Interprets Kp value: 0-2 = quiet, 3-4 = unsettled, 5-6 = minor storm,
  /// 7-8 = major storm, 9 = severe storm
  static String interpretKp(double kpValue) {
    if (kpValue < 3) {
      return 'Quieto';
    } else if (kpValue < 5) {
      return 'Inestable';
    } else if (kpValue < 7) {
      return 'Tormenta Menor';
    } else if (kpValue < 9) {
      return 'Tormenta Mayor';
    } else {
      return 'Tormenta Severa';
    }
  }
}
