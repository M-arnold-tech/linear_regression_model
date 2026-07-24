import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const YieldPredictionApp());
}

class YieldPredictionApp extends StatelessWidget {
  const YieldPredictionApp({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop Yield Predictor',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const PredictionScreen(),
    );
  }
}

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({Key? key}) : super(key: key);

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final TextEditingController _latController = TextEditingController(text: "22.62");
  final TextEditingController _lonController = TextEditingController(text: "88.49");
  final TextEditingController _ndviController = TextEditingController(text: "0.45");
  final TextEditingController _gndviController = TextEditingController(text: "0.41");
  final TextEditingController _ndwiController = TextEditingController(text: "-0.41");
  final TextEditingController _saviController = TextEditingController(text: "0.67");
  final TextEditingController _soilMoistureController = TextEditingController(text: "25.29");
  final TextEditingController _tempController = TextEditingController(text: "29.05");
  final TextEditingController _rainfallController = TextEditingController(text: "11.03");

  String _selectedCrop = 'Rice';
  final List<String> _crops = [
    'Rice', 'Wheat', 'Maize', 'Bajra', 'Jowar', 'Soybean', 
    'Sugarcane', 'Cotton', 'Mustard', 'Sunflower', 'Ragi'
  ];

  String _resultText = "";
  bool _isLoading = false;
  bool _isError = false;

  // Replace with your public Render URL
  final String _apiUrl = "https://linear-regression-model-z0pv.onrender.com/predict";

  Future<void> _makePrediction() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isError = true;
        _resultText = "Please fix input errors before submitting.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _resultText = "";
      _isError = false;
    });

    final Map<String, dynamic> requestData = {
      "latitude": double.parse(_latController.text),
      "longitude": double.parse(_lonController.text),
      "NDVI": double.parse(_ndviController.text),
      "GNDVI": double.parse(_gndviController.text),
      "NDWI": double.parse(_ndwiController.text),
      "SAVI": double.parse(_saviController.text),
      "soil_moisture": double.parse(_soilMoistureController.text),
      "temperature": double.parse(_tempController.text),
      "rainfall": double.parse(_rainfallController.text),
      "crop_type": _selectedCrop
    };

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isError = false;
          _resultText = "Predicted Yield: ${data['predicted_yield']} ${data['units']}";
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _isError = true;
          _resultText = "API Error: ${errorData['detail'] ?? 'Validation failed.'}";
        });
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _resultText = "Network Error: Could not connect to API server.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Field cannot be empty";
          }
          if (double.tryParse(value) == null) {
            return "Enter a valid number";
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Precision Agriculture Yield Estimator'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Input Satellite & Weather Parameters",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              
              // Dropdown for Crop Type
              DropdownButtonFormField<String>(
                value: _selectedCrop,
                decoration: const InputDecoration(
                  labelText: "Crop Type",
                  border: OutlineInputBorder(),
                ),
                items: _crops.map((String crop) {
                  return DropdownMenuItem(value: crop, child: Text(crop));
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCrop = newValue!;
                  });
                },
              ),
              const SizedBox(height: 6),
              
              _buildTextField(_latController, "Latitude (-90 to 90)", "e.g. 22.62"),
              _buildTextField(_lonController, "Longitude (-180 to 180)", "e.g. 88.49"),
              _buildTextField(_ndviController, "NDVI (-1.0 to 1.0)", "e.g. 0.45"),
              _buildTextField(_gndviController, "GNDVI (-1.0 to 1.0)", "e.g. 0.41"),
              _buildTextField(_ndwiController, "NDWI (-1.0 to 1.0)", "e.g. -0.41"),
              _buildTextField(_saviController, "SAVI (-1.0 to 1.5)", "e.g. 0.67"),
              _buildTextField(_soilMoistureController, "Soil Moisture (0 to 100%)", "e.g. 25.29"),
              _buildTextField(_tempController, "Temperature (°C)", "e.g. 29.05"),
              _buildTextField(_rainfallController, "Rainfall (mm)", "e.g. 11.03"),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _isLoading ? null : _makePrediction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Predict Yield", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),

              const SizedBox(height: 20),

              // Display Area
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isError ? Colors.red : Colors.green,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _resultText.isEmpty ? "Prediction output will appear here." : _resultText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isError ? Colors.red.shade900 : Colors.green.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}