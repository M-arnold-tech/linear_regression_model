import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const WastePredictorApp());
}

class WastePredictorApp extends StatelessWidget {
  const WastePredictorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'African MSW Predictor',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
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
  // Form controllers matching the required API variables
  final _countryController = TextEditingController();
  final _popController = TextEditingController();
  final _gdpController = TextEditingController();
  final _foodController = TextEditingController();
  final _paperController = TextEditingController();
  final _plasticController = TextEditingController();

  String _result = "";
  bool _isLoading = false;
  bool _isError = false;

  // Render API Endpoint
  final String _apiUrl = "https://linear-regression-model-iurj.onrender.com/predict";

Future<void> _makePrediction() async {
    if (_countryController.text.isEmpty ||
        _popController.text.isEmpty ||
        _gdpController.text.isEmpty ||
        _foodController.text.isEmpty ||
        _paperController.text.isEmpty ||
        _plasticController.text.isEmpty) {
      setState(() {
        _isError = true;
        _result = "Please fill in all 6 input fields.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _result = "";
      _isError = false;
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "country_name": _countryController.text.trim(),
          "population": double.tryParse(_popController.text) ?? 0.0,
          "gdp": double.tryParse(_gdpController.text) ?? 0.0,
          "food_organic_pct": double.tryParse(_foodController.text) ?? 0.0,
          "paper_cardboard_pct": double.tryParse(_paperController.text) ?? 0.0,
          "plastic_pct": double.tryParse(_plasticController.text) ?? 0.0,
        }),
      );

      // Handle double-encoded JSON strings if Render wraps response in quotes
      dynamic decodedData = jsonDecode(response.body);
      if (decodedData is String) {
        try {
          decodedData = jsonDecode(decodedData);
        } catch (_) {}
      }

      if (response.statusCode == 200) {
        double? predictedValue;

        // 1. If decoded payload is a Map / JSON Object
        if (decodedData is Map) {
          final rawVal = decodedData['predicted_msw'] ??
              decodedData['predicted_total_msw_tons_year'] ??
              decodedData['prediction'];
          if (rawVal != null) {
            predictedValue = double.tryParse(rawVal.toString());
          }
        } 
        // 2. If decoded payload is directly a Number (e.g. 18457232.0)
        else if (decodedData is num) {
          predictedValue = decodedData.toDouble();
        } 
        // 3. If decoded payload is a numeric String (e.g. "18457232.0")
        else if (decodedData is String) {
          predictedValue = double.tryParse(decodedData);
        }

        final String countryName = _countryController.text.trim();

        setState(() {
          if (predictedValue != null) {
            _isError = false;
            // Format number cleanly (e.g., 18,457,232.00 Tons / Year)
            final String formattedVal = predictedValue!.toStringAsFixed(2);
            _result = "Predicted MSW for $countryName:\n\n$formattedVal Tons / Year";
          } else {
            _isError = true;
            // Debug fallback to show actual structure if decoding fails
            _result = "Could not parse prediction.\nAPI Payload: ${response.body}";
          }
        });
      } else {
        String errorMsg = "Prediction failed.";
        if (decodedData is Map && decodedData['detail'] != null) {
          if (decodedData['detail'] is List && (decodedData['detail'] as List).isNotEmpty) {
            errorMsg = decodedData['detail'][0]['msg'] ?? "Invalid input value.";
          } else if (decodedData['detail'] is String) {
            errorMsg = decodedData['detail'];
          }
        }

        setState(() {
          _isError = true;
          _result = "Error: $errorMsg";
        });
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _result = "Connection Error: Check network or API availability.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  @override
  void dispose() {
    _countryController.dispose();
    _popController.dispose();
    _gdpController.dispose();
    _foodController.dispose();
    _paperController.dispose();
    _plasticController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("African Country MSW Predictor"),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Predict Municipal Solid Waste Generation",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _countryController,
              decoration: const InputDecoration(
                labelText: "African Country Name",
                hintText: "e.g. Nigeria, Kenya, Ghana",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _popController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Population",
                hintText: "e.g. 180000000",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _gdpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "GDP (USD)",
                hintText: "e.g. 450000000000",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _foodController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Food & Organic Waste (%)",
                hintText: "0 to 100",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _paperController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Paper & Cardboard Waste (%)",
                hintText: "0 to 100",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _plasticController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Plastic Waste (%)",
                hintText: "0 to 100",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _makePrediction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text("Predict", style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 24),
            if (_result.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isError ? Colors.red.shade50 : Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isError ? Colors.red : Colors.teal,
                  ),
                ),
                child: Text(
                  _result,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isError ? Colors.red.shade800 : Colors.teal.shade900,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}