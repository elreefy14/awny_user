import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:booking_system_flutter/model/dashboard_model.dart';

void main() {
  runApp(TestApp());
}

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'API Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: APITestScreen(),
    );
  }
}

class APITestScreen extends StatefulWidget {
  @override
  _APITestScreenState createState() => _APITestScreenState();
}

class _APITestScreenState extends State<APITestScreen> {
  bool isLoading = true;
  String resultText = "Testing API...";
  Map<String, dynamic>? rawResponse;
  DashboardResponse? dashboardResponse;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      // Parameters for the API call
      String countryParam = "egypt"; // or "saudi arabia"

      // Build the URL with query parameters
      String url =
          "https://awnyapp.com/api/dashboard-detail?country=$countryParam";

      // Make the API request
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Parse the response
        final jsonResponse = json.decode(response.body);

        setState(() {
          rawResponse = jsonResponse;
          try {
            dashboardResponse = DashboardResponse.fromJson(jsonResponse);
            resultText = "API call successful. Processing data...";

            // Analyze the results
            analyzeResults();
          } catch (e) {
            resultText =
                "Error parsing response: $e\n\nRaw response: ${response.body}";
          }
        });
      } else {
        setState(() {
          resultText =
              "API call failed with status: ${response.statusCode}\nBody: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        resultText = "Error fetching data: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void analyzeResults() {
    if (dashboardResponse == null) {
      resultText = "No data to analyze";
      return;
    }

    StringBuffer buffer = StringBuffer();
    buffer.writeln("Dashboard Data Analysis:");
    buffer.writeln("=========================");

    // Categories
    int categoryCount = dashboardResponse!.category?.length ?? 0;
    buffer.writeln("Categories: $categoryCount");

    if (categoryCount > 0) {
      buffer.writeln("\nSample categories:");
      int showCount = categoryCount > 5 ? 5 : categoryCount;
      for (int i = 0; i < showCount; i++) {
        var category = dashboardResponse!.category![i];
        buffer.writeln("${i + 1}. ${category.name} (ID: ${category.id})");
      }
    }

    // Services
    int serviceCount = dashboardResponse!.service?.length ?? 0;
    buffer.writeln("\nServices: $serviceCount");

    if (serviceCount > 0) {
      buffer.writeln("\nSample services:");
      int showCount = serviceCount > 5 ? 5 : serviceCount;
      for (int i = 0; i < showCount; i++) {
        var service = dashboardResponse!.service![i];
        buffer.writeln(
            "${i + 1}. ${service.name} (ID: ${service.id}, Category ID: ${service.categoryId})");
      }

      // Category-Service Mapping
      buffer.writeln("\nCategory-Service Relationships:");
      Map<dynamic, List<dynamic>> categoryServiceMap = {};

      // Initialize map with all categories
      dashboardResponse!.category?.forEach((category) {
        categoryServiceMap[category.id] = [];
      });

      // Count services for each category
      int matchedServices = 0;
      dashboardResponse!.service?.forEach((service) {
        if (service.categoryId != null &&
            categoryServiceMap.containsKey(service.categoryId)) {
          categoryServiceMap[service.categoryId]!.add(service);
          matchedServices++;
        }
      });

      buffer.writeln(
          "Total matched services: $matchedServices out of $serviceCount");
      buffer.writeln("\nCategory service counts:");

      // Sort categories by service count (descending)
      List<MapEntry<dynamic, List<dynamic>>> sortedEntries =
          categoryServiceMap.entries.toList()
            ..sort((a, b) => b.value.length.compareTo(a.value.length));

      for (var entry in sortedEntries) {
        buffer.writeln(
            "Category ID ${entry.key}: ${entry.value.length} services");
      }

      // Zero service categories
      List<dynamic> emptyCategories = sortedEntries
          .where((entry) => entry.value.isEmpty)
          .map((entry) => entry.key)
          .toList();

      buffer.writeln(
          "\nCategories with no services (${emptyCategories.length}):");
      if (emptyCategories.isNotEmpty) {
        for (var catId in emptyCategories) {
          var cat = dashboardResponse!.category!.firstWhere(
              (c) => c.id == catId,
              orElse: () => dashboardResponse!.category!.first);
          buffer.writeln("Category ID $catId (${cat.name})");
        }
      } else {
        buffer.writeln("All categories have services");
      }

      // Type debugging
      if (dashboardResponse!.service != null &&
          dashboardResponse!.service!.isNotEmpty) {
        var sampleService = dashboardResponse!.service!.first;
        var sampleCategory = dashboardResponse!.category!.first;

        buffer.writeln("\nType analysis:");
        buffer.writeln("Service ID type: ${sampleService.id.runtimeType}");
        buffer.writeln("Category ID type: ${sampleCategory.id.runtimeType}");
        buffer.writeln(
            "Service categoryId type: ${sampleService.categoryId.runtimeType}");

        // Try string comparison
        if (sampleService.categoryId != null) {
          buffer.writeln("\nMatching test:");
          var catIdStr = sampleCategory.id.toString();
          var srvCatIdStr = sampleService.categoryId.toString();
          buffer.writeln("Category ID as string: $catIdStr");
          buffer.writeln("Service categoryId as string: $srvCatIdStr");
          buffer.writeln("String match: ${catIdStr == srvCatIdStr}");

          // Try int comparison
          int catIdInt = int.tryParse(catIdStr) ?? -1;
          int srvCatIdInt = int.tryParse(srvCatIdStr) ?? -2;
          buffer.writeln("Category ID as int: $catIdInt");
          buffer.writeln("Service categoryId as int: $srvCatIdInt");
          buffer.writeln("Int match: ${catIdInt == srvCatIdInt}");
        }
      }
    }

    setState(() {
      resultText = buffer.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('API Test'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
                resultText = "Refreshing...";
              });
              fetchDashboardData();
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'API Response Analysis',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SelectableText(
                      resultText,
                      style: TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
