import 'dart:convert';
import 'package:http/http.dart' as http;

class CameraService {
  static const String baseUrl = 'http://www.insecam.org/en';
  static const Map<String, String> headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
  };

  Future<List<Map<String, dynamic>>> fetchCountries() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/jsoncountries/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['countries'].entries.map((e) => {
          'code': e.key,
          'name': e.value['country'],
          'count': e.value['count']
        }).toList();
      }
      throw Exception('Failed to fetch countries');
    } catch (e) {
      throw Exception('Error fetching countries: $e');
    }
  }

  Future<List<String>> scanCameras(String countryCode, int maxPages) async {
    List<String> cameras = [];
    List<String> accessibleCameras = [];
    
    for (int page = 0; page < maxPages; page++) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/bycountry/$countryCode/?page=$page'),
          headers: headers,
        );

        if (response.statusCode == 200) {
          final regex = RegExp(r"http://\d+\.\d+\.\d+\.\d+:\d+");
          final matches = regex.allMatches(response.body);
          cameras.addAll(matches.map((m) => m.group(0)!).toList());
        }
      } catch (e) {
        print('Error scanning page $page: $e');
      }
    }

    // Check accessibility of each camera
    for (var camera in cameras) {
      try {
        final response = await http.get(
          Uri.parse(camera),
          headers: headers,
        ).timeout(const Duration(seconds: 3));
        
        if (response.statusCode == 200) {
          accessibleCameras.add(camera);
        }
      } catch (_) {
        // Skip inaccessible cameras
      }
    }
    
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