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
      title: 'African MSW Predictor',
      theme: ThemeData(primarySwatch: Colors.green),
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
  final _popController = TextEditingController();
  final _gdpController = TextEditingController();
  final _foodController = TextEditingController();
  final _plasticController = TextEditingController();

  String _result = "";
  bool _isLoading = false;

  // Replace with your actual Render API Endpoint URL
  final String _apiUrl = "https://your-render-app.onrender.com/predict";

  Future<void> _makePrediction() async {
    setState(() {
      _isLoading = true;
      _result = "";
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "country_name": _countryController.text.trim(),
          "population": double.parse(_popController.text),
          "gdp": double.parse(_gdpController.text),
          "food_waste_percent": double.parse(_foodController.text),
          "plastic_percent": double.parse(_plasticController.text),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _result = "Predicted MSW: ${data['predicted_total_msw_tons_year']} Tons/Year";
        });
      } else {
        final err = jsonDecode(response.body);
        setState(() {
          _result = "Error: ${err['detail'] ?? 'Out of range or invalid input'}";
        });
      }
    } catch (e) {
      setState(() {
        _result = "Invalid input or connectivity error.";
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
      appBar: AppBar(title: const Text("African Country MSW Predictor")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _countryController, decoration: const InputDecoration(labelText: "African Country Name")),
            TextField(controller: _popController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Population")),
            TextField(controller: _gdpController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "GDP (USD)")),
            TextField(controller: _foodController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Food Waste (%)")),
            TextField(controller: _plasticController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Plastic Waste (%)")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _makePrediction,
              child: _isLoading ? const CircularProgressIndicator() : const Text("Predict"),
            ),
            const SizedBox(height: 20),
            Text(_result, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          ],
        ),
      ),
    );
  }
}