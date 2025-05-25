// main.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize WebView platform
  if (WebViewPlatform.instance == null) {
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      WebViewPlatform.instance = WebKitWebViewPlatform();
    } else {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    }
  }

  runApp(const ArgusScanApp());
}

class ArgusScanApp extends StatelessWidget {
  const ArgusScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArgusScan',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   List<dynamic> countries = [];
//   List<dynamic> cameras = [];
//   String selectedCountry = '';
//   bool isLoading = false;
//   bool testAccessibility = false;
//   int maxPages = 1;
//   String outputText = '';

//   @override
//   void initState() {
//     super.initState();
//     fetchCountries();
//   }

//   Future<void> fetchCountries() async {
//     setState(() => isLoading = true);
//     try {
//       final response = await http.get(
//         Uri.parse('http://www.insecam.org/en/jsoncountries/'),
//         headers: {
//           'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
//         },
//       );
//       if (response.statusCode == 200) {
//         setState(() {
//           countries = json.decode(response.body)['countries'].entries.map((e) {
//             return {
//               'code': e.key,
//               'name': e.value['country'],
//               'count': e.value['count']
//             };
//           }).toList();
//         });
//       }
//     } catch (e) {
//       debugPrint('Error fetching countries: $e');
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   Future<void> scanCameras() async {
//     if (selectedCountry.isEmpty) return;
    
//     setState(() {
//       isLoading = true;
//       cameras = [];
//       outputText = 'Scanning $selectedCountry...\n';
//     });

//     try {
//       for (int page = 0; page < maxPages; page++) {
//         final response = await http.get(
//           Uri.parse('http://www.insecam.org/en/bycountry/$selectedCountry/?page=$page'),
//           headers: {
//             'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
//           },
//         );

//         if (response.statusCode == 200) {
//           final regex = RegExp(r"http://\d+\.\d+\.\d+\.\d+:\d+");
//           final matches = regex.allMatches(response.body);
          
//           setState(() {
//             cameras.addAll(matches.map((m) => m.group(0)).toList());
//             outputText += 'Page ${page + 1}: Found ${matches.length} cameras\n';
//           });
//         }
//       }

//       if (testAccessibility) {
//         outputText += '\nTesting camera accessibility...\n';
//         int accessible = 0;
        
//         for (var camera in cameras) {
//           try {
//             final response = await http.get(Uri.parse(camera!)).timeout(const Duration(seconds: 3));
//             if (response.statusCode == 200) {
//               accessible++;
//             }
//           } catch (_) {}
//         }
        
//         outputText += 'Accessible cameras: $accessible/${cameras.length}\n';
//       }

//       outputText += '\nScan completed! Total cameras: ${cameras.length}';
//     } catch (e) {
//       outputText += '\nError: $e';
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('ArgusScan'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.info_outline),
//             onPressed: () => Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => const InfoScreen()),
//             ),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Country Selection
//             DropdownButtonFormField<String>(
//               decoration: const InputDecoration(
//                 labelText: 'Select Country',
//                 border: OutlineInputBorder(),
//               ),
//               items: countries.map((country) {
//                 return DropdownMenuItem<String>(
//                   value: country['code'],
//                   child: Text(
//                     '${country['name']} (${country['code']}) - ${country['count']} cams',
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 );
//               }).toList(),
//               onChanged: (value) => setState(() => selectedCountry = value!),
//             ),

//             const SizedBox(height: 16),

//             // Scan Options
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Scan Options',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     SwitchListTile(
//                       title: const Text('Test Camera Accessibility'),
//                       value: testAccessibility,
//                       onChanged: (value) => setState(() => testAccessibility = value),
//                     ),
//                     ListTile(
//                       title: const Text('Max Pages to Scan'),
//                       trailing: DropdownButton<int>(
//                         value: maxPages,
//                         items: [1, 3, 5, 10].map((value) {
//                           return DropdownMenuItem<int>(
//                             value: value,
//                             child: Text('$value'),
//                           );
//                         }).toList(),
//                         onChanged: (value) => setState(() => maxPages = value!),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Scan Button
//             ElevatedButton.icon(
//               icon: isLoading
//                   ? const SizedBox(
//                       width: 24,
//                       height: 24,
//                       child: CircularProgressIndicator(color: Colors.white),
//                     )
//                   : const Icon(Icons.search),
//               label: const Text('Start Scan'),
//               onPressed: isLoading ? null : scanCameras,
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Results
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     const Text(
//                       'Scan Results',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     Container(
//                       height: 200,
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.grey),
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                       padding: const EdgeInsets.all(8),
//                       child: SingleChildScrollView(
//                         child: Text(outputText),
//                       ),
//                     ),
//                     if (cameras.isNotEmpty) ...[
//                       const SizedBox(height: 8),
//                       Text('Total Cameras Found: ${cameras.length}'),
//                       const SizedBox(height: 8),
//                       ElevatedButton(
//                         child: const Text('Save to File'),
//                         onPressed: () {
//                           // Implement file saving functionality
//                         },
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class InfoScreen extends StatelessWidget {
//   const InfoScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('About ArgusScan')),
//       body: Markdown(
//         data: '''
// # ArgusScan 👁️‍🗨️

// **The All-Seeing Camera Scanner**  
// *Named after Argus Panoptes - The Hundred-Eyed Giant*

// ## Features
// - Country-specific camera scanning
// - Accessibility testing
// - Multi-page scanning
// - Results export

// ## Legal Disclaimer
// This app is for educational purposes only. Unauthorized scanning may violate laws in your jurisdiction.

// ## How It Works
// 1. Select a country from the dropdown
// 2. Configure scan options
// 3. Press "Start Scan"
// 4. View and save results

// ''',
//       ),
//     );
//   }
// }