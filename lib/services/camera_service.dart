import 'dart:convert';
import 'package:http/http.dart' as http;

class CameraService {
  static const String baseUrl = 'http://www.insecam.org/en';
  static const Map<String, String> headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.5',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
  };

  // Local country data
  static const Map<String, dynamic> localCountriesData = {
    "status": "success",
    "countries": {
      "US": {"country": "United States", "count": 754},
      "JP": {"country": "Japan", "count": 454},
      "IT": {"country": "Italy", "count": 176},
      "DE": {"country": "Germany", "count": 155},
      "RU": {"country": "Russian Federation", "count": 99},
      "FR": {"country": "France", "count": 92},
      "AT": {"country": "Austria", "count": 85},
      "CZ": {"country": "Czech Republic", "count": 77},
      "KR": {"country": "Korea, Republic Of", "count": 58},
      "TW": {"country": "Taiwan, Province Of ", "count": 49},
      "CH": {"country": "Switzerland", "count": 49},
      "NO": {"country": "Norway", "count": 44},
      "RO": {"country": "Romania", "count": 41},
      "CA": {"country": "Canada", "count": 39},
      "NL": {"country": "Netherlands", "count": 37},
      "ES": {"country": "Spain", "count": 36},
      "PL": {"country": "Poland", "count": 35},
      "GB": {"country": "United Kingdom", "count": 33},
      "SE": {"country": "Sweden", "count": 29},
      "BG": {"country": "Bulgaria", "count": 21},
      "DK": {"country": "Denmark", "count": 18},
      "BE": {"country": "Belgium", "count": 16},
      "RS": {"country": "Serbia", "count": 14},
      "IN": {"country": "India", "count": 10},
      "UA": {"country": "Ukraine", "count": 10},
      "ZA": {"country": "South Africa", "count": 10},
      "VN": {"country": "Viet Nam", "count": 10},
      "FI": {"country": "Finland", "count": 9},
      "SK": {"country": "Slovakia", "count": 8},
      "TR": {"country": "Turkey", "count": 8},
      "-": {"country": "-", "count": 8},
      "GR": {"country": "Greece", "count": 8},
      "BR": {"country": "Brazil", "count": 8},
      "ID": {"country": "Indonesia", "count": 8},
      "HU": {"country": "Hungary", "count": 8},
      "MX": {"country": "Mexico", "count": 7},
      "BA": {"country": "Bosnia And Herzegovina", "count": 7},
      "TH": {"country": "Thailand", "count": 6},
      "AU": {"country": "Australia", "count": 6},
      "IL": {"country": "Israel", "count": 6},
      "HK": {"country": "Hong Kong", "count": 5},
      "AR": {"country": "Argentina", "count": 5},
      "MY": {"country": "Malaysia", "count": 4},
      "MD": {"country": "Moldova, Republic Of", "count": 4},
      "SI": {"country": "Slovenia", "count": 4},
      "SY": {"country": "Syria", "count": 4},
      "LT": {"country": "Lithuania", "count": 4},
      "EE": {"country": "Estonia", "count": 4},
      "NZ": {"country": "New Zealand", "count": 4},
      "IE": {"country": "Ireland", "count": 4},
      "EC": {"country": "Ecuador", "count": 4},
      "CL": {"country": "Chile", "count": 4},
      "IR": {"country": "Iran, Islamic Republic", "count": 3},
      "KZ": {"country": "Kazakhstan", "count": 3},
      "CN": {"country": "China", "count": 3},
      "NI": {"country": "Nicaragua", "count": 2},
      "BY": {"country": "Belarus", "count": 2},
      "ME": {"country": "Montenegro", "count": 2},
      "IS": {"country": "Iceland", "count": 2},
      "FO": {"country": "Faroe Islands", "count": 2},
      "HN": {"country": "Honduras", "count": 2},
      "CO": {"country": "Colombia", "count": 2},
      "PE": {"country": "Peru", "count": 1},
      "DO": {"country": "Dominican Republic", "count": 1},
      "PA": {"country": "Panama", "count": 1},
      "CY": {"country": "Cyprus", "count": 1},
      "NC": {"country": "New Caledonia", "count": 1},
      "AO": {"country": "Angola", "count": 1},
      "NG": {"country": "Nigeria", "count": 1},
      "GU": {"country": "Guam", "count": 1},
      "LU": {"country": "Luxembourg", "count": 1},
      "GE": {"country": "Georgia", "count": 1},
      "PH": {"country": "Philippines", "count": 1},
      "LA": {"country": "Laos", "count": 1},
      "TN": {"country": "Tunisia", "count": 1},
      "AM": {"country": "Armenia", "count": 1},
      "TZ": {"country": "Tanzania", "count": 1}
    }
  };

  Future<List<Map<String, dynamic>>> fetchCountries() async {
    try {
      final countries = localCountriesData['countries'] as Map<String, dynamic>;
      return countries.entries.map((e) => {
        'code': e.key,
        'name': e.value['country'],
        'count': e.value['count']
      }).toList();
    } catch (e) {
      print('Error processing countries: $e');
      throw Exception('Error processing countries: $e');
    }
  }

  Future<List<String>> scanCameras(String countryCode, int maxPages) async {
    List<String> cameras = [];
    List<String> accessibleCameras = [];
    
    // Get the country's camera count from local data
    final countryData = localCountriesData['countries'][countryCode];
    if (countryData == null) {
      print('Country not found: $countryCode');
      return [];
    }

    print('Scanning for cameras in $countryCode (expected count: ${countryData['count']})');
    
    // Fetch cameras from the URL
    for (int page = 0; page < maxPages; page++) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/bycountry/$countryCode/?page=$page'),
          headers: headers,
        );

        if (response.statusCode == 200) {
          // Extract camera URLs from the response
          final regex = RegExp(r"http://\d+\.\d+\.\d+\.\d+:\d+");
          final matches = regex.allMatches(response.body);
          cameras.addAll(matches.map((m) => m.group(0)!).toList());
          print('Found ${matches.length} cameras on page $page');
        }
      } catch (e) {
        print('Error scanning page $page: $e');
      }
    }

    print('Found total of ${cameras.length} cameras, checking accessibility...');

    // Check accessibility of each camera
    for (var camera in cameras) {
      try {
        final response = await http.get(
          Uri.parse(camera),
          headers: headers,
        ).timeout(const Duration(seconds: 3));
        
        if (response.statusCode == 200) {
          accessibleCameras.add(camera);
          print('Found accessible camera: $camera');
        }
      } catch (_) {
        // Skip inaccessible cameras
      }
    }
    
    print('Found ${accessibleCameras.length} accessible cameras');
    return accessibleCameras;
  }

  Future<bool> testCameraAccessibility(String cameraUrl) async {
    try {
      final response = await http.get(
        Uri.parse(cameraUrl),
        headers: headers,
      ).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
} 