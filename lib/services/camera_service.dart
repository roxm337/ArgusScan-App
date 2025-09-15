import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CameraService {
  static const String baseUrl = 'http://www.insecam.org';
  static const String countriesUrl = 'http://www.insecam.org/en/jsoncountries/';
  static const Map<String, String> headers = {
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'Cache-Control': 'max-age=0',
    'Connection': 'keep-alive',
    'Host': 'www.insecam.org',
    'Upgrade-Insecure-Requests': '1',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36'
  };

  Future<bool> testNetworkConnectivity() async {
    try {
      print('Testing network connectivity...');

      // Use dio for cross-platform network testing
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 5);
      dio.options.receiveTimeout = const Duration(seconds: 5);
      dio.options.headers = headers;

      try {
        final response = await dio.get(baseUrl);
        print('Network response status: ${response.statusCode}');
        return response.statusCode == 200;
      } catch (e) {
        print('Network request failed: $e');
        if (e is DioException) {
          print('Dio error type: ${e.type}');
          print('Dio error message: ${e.message}');
        }
      }

      return false;
    } catch (e) {
      print('Error testing network connectivity: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchCountries() async {
    try {
      final response = await http
          .get(
            Uri.parse(countriesUrl),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['countries'];
      }
      print('Error fetching countries: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error fetching countries: $e');
      return null;
    }
  }

  Future<List<String>> scanCameras(String countryCode, {int? maxPages}) async {
    try {
      // Get first page to determine total pages
      final firstPageUrl = '$baseUrl/en/bycountry/$countryCode';
      final response = await http
          .get(
            Uri.parse(firstPageUrl),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print('Error accessing country page: ${response.statusCode}');
        return [];
      }

      // Extract total pages using regex
      final pageRegex = RegExp(r'pagenavigator\("\?page=", (\d+)');
      final match = pageRegex.firstMatch(response.body);
      if (match == null) {
        print('No cameras found for this country.');
        return [];
      }

      int totalPages = int.parse(match.group(1)!);
      if (maxPages != null && maxPages < totalPages) {
        totalPages = maxPages;
      }

      print('Found $totalPages pages to scan...');

      // Use Future.wait for parallel processing
      final futures = List.generate(
          totalPages + 1, (page) => fetchPageUrls(countryCode, page));

      final results = await Future.wait(futures);
      final allUrls = results.expand((urls) => urls).toList();

      print('Found ${allUrls.length} total cameras');
      return allUrls;
    } catch (e) {
      print('Error scanning cameras: $e');
      return [];
    }
  }

  Future<List<String>> fetchPageUrls(String countryCode, int page) async {
    try {
      final url = '$baseUrl/en/bycountry/$countryCode/?page=$page';
      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final regex = RegExp(r"http://\d+\.\d+\.\d+\.\d+:\d+");
        return regex.allMatches(response.body).map((m) => m.group(0)!).toList();
      }
      print('Error fetching page $page: ${response.statusCode}');
      return [];
    } catch (e) {
      print('Warning: Error fetching page $page: $e');
      return [];
    }
  }

  Future<List<String>> testCameraAccessibility(List<String> urls,
      {bool verbose = false}) async {
    print('\nTesting camera accessibility...');
    final accessible = <String>[];

    // Use Future.wait for parallel processing
    final futures = urls.map((url) => checkCamera(url, verbose));
    final results = await Future.wait(futures);

    for (var i = 0; i < urls.length; i++) {
      if (results[i]) {
        accessible.add(urls[i]);
      }
    }

    print('Found ${accessible.length} accessible cameras');
    return accessible;
  }

  Future<bool> checkCamera(String url, bool verbose) async {
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(const Duration(seconds: 5));

      final isAccessible = response.statusCode == 200;
      if (verbose) {
        print(isAccessible
            ? '[+] $url - Accessible'
            : '[-] $url - Not accessible');
      }
      return isAccessible;
    } catch (e) {
      if (verbose) {
        print('[-] $url - Not accessible');
      }
      return false;
    }
  }

  Future<void> saveToFile(List<String> urls, String filename) async {
    try {
      final content = urls.join('\n');

      // For mobile platforms, save to device storage and share
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(content);

      // Share the file
      await Share.shareXFiles([XFile(file.path)], text: 'Camera URLs');
      print('Saved ${urls.length} URLs to $filename and shared');
    } catch (e) {
      print('Error saving to file: $e');
    }
  }
}
