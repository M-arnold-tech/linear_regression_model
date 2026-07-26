import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const AfricanWastePredictionApp());
}

class AfricanWastePredictionApp extends StatelessWidget {
  const AfricanWastePredictionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'African Waste Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const PredictionScreen(),
    );
  }
}

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final _countryController = TextEditingController();
  final _gdpController = TextEditingController();

  String _result = "";
  Map<String, dynamic>? _details;
  bool _isLoading = false;

  // ⚠️ Replace with your actual deployed Render API endpoint URL
  final String _apiUrl = "https://your-render-api.onrender.com/predict-by-country";

  Future<void> _makePrediction() async {
    setState(() {
      _isLoading = true;
      _result = "";
      _details = null;
    });

    final String country = _countryController.text.trim();
    final String gdpInput = _gdpController.text.trim();

    if (country.isEmpty) {
      setState(() {
        _result = "Error: Please enter an African country name.";
        _isLoading = false;
      });
      return;
    }

    try {
      final Map<String, dynamic> requestBody = {
        "country_name": country,
      };

      // Add optional GDP override if provided by user
      if (gdpInput.isNotEmpty) {
        final double? parsedGdp = double.tryParse(gdpInput);
        if (parsedGdp != null && parsedGdp >= 0) {
          requestBody["override_gdp"] = parsedGdp;
        }
      }

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _result = "Predicted Solid Waste:\n${data['predicted_msw_tons_year']} Tons/Year";
          _details = data['inputs_used'];
        });
      } else {
        final err = jsonDecode(response.body);
        setState(() {
          _result = "Error: ${err['detail'] ?? 'Failed to get prediction.'}";
        });
      }
    } catch (e) {
      setState(() {
        _result = "Network Error: Could not connect to API server.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("African Solid Waste Predictor"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Predict Municipal Solid Waste",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter an African country. Demographic & composition factors are auto-populated by the API.",
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Country Input Field
              TextField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: "African Country Name *",
                  hintText: "e.g. Nigeria, Kenya, Egypt",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),

              // Optional GDP Input Field
              TextField(
                controller: _gdpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "GDP in USD (Optional Override)",
                  hintText: "Leave blank to use default dataset GDP",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 24),

              // Predict Button
              ElevatedButton(
                onPressed: _isLoading ? null : _makePrediction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text("Predict", style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 24),

              // Output Display Area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _result.isEmpty ? "Prediction output will appear here." : _result,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _result.startsWith("Error") ? Colors.red : Colors.teal.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_details != null) ...[
                      const Divider(height: 24),
                      const Text(
                        "Auto-Fetched Metrics Used:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text("• Country: ${_details!['country']}"),
                      Text("• Population: ${_details!['fetched_population']}"),
                      Text("• Organic Waste: ${_details!['food_organic_pct']}%"),
                      Text("• Paper/Cardboard: ${_details!['paper_cardboard_pct']}%"),
                      Text("• Plastic: ${_details!['plastic_pct']}%"),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}