import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const AfricanWastePredictorApp());
}

class AfricanWastePredictorApp extends StatelessWidget {
  const AfricanWastePredictorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Africa Waste Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const WasteScreen(),
    );
  }
}

class WasteScreen extends StatefulWidget {
  const WasteScreen({super.key});

  @override
  State<WasteScreen> createState() => _WasteScreenState();
}

class _WasteScreenState extends State<WasteScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _gdpController = TextEditingController();
  final TextEditingController _popController = TextEditingController();
  final TextEditingController _foodController = TextEditingController();
  final TextEditingController _paperController = TextEditingController();
  final TextEditingController _plasticController = TextEditingController();

  String _result = "";
  bool _isLoading = false;

  final String apiUrl = "https://your-render-app.onrender.com/predict";

  Future<void> _getPrediction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _result = "";
    });

    try {
      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "gdp": double.parse(_gdpController.text),
          "population": double.parse(_popController.text),
          "food_organic_pct": double.parse(_foodController.text),
          "paper_cardboard_pct": double.parse(_paperController.text),
          "plastic_pct": double.parse(_plasticController.text),
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _result = "Predicted Annual Waste: ${data['predicted_msw_tons_year']} Tons/Year";
        });
      } else {
        final err = jsonDecode(res.body);
        setState(() {
          _result = "Error: ${err['detail'] ?? 'Invalid input range'}";
        });
      }
    } catch (e) {
      setState(() {
        _result = "Connection failed: $e";
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
      appBar: AppBar(title: const Text("African Waste Predictor")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _gdpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Country GDP (USD)", border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? "Enter GDP" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _popController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Population", border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? "Enter Population" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _foodController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Organic Waste % (0 - 100)", border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? "Enter Organic %" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _paperController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Paper/Cardboard % (0 - 100)", border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? "Enter Paper %" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _plasticController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Plastic % (0 - 100)", border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? "Enter Plastic %" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _getPrediction,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: _isLoading ? const CircularProgressIndicator() : const Text("Predict"),
              ),
              const SizedBox(height: 20),
              Text(
                _result,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      ),
    );
  }
}