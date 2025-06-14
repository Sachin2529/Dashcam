import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BoardingPointScreen extends StatefulWidget {
  const BoardingPointScreen({Key? key}) : super(key: key);

  @override
  _BoardingPointScreenState createState() => _BoardingPointScreenState();
}

class _BoardingPointScreenState extends State<BoardingPointScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _busNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedCoordinates();
  }

  Future<void> _loadSavedCoordinates() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('boarding_lat');
    final lng = prefs.getDouble('boarding_lng');
    final busNumber = prefs.getInt('bus_number');

    if (lat != null) _latController.text = lat.toString();
    if (lng != null) _lngController.text = lng.toString();
    if (busNumber != null) _busNumberController.text = busNumber.toString();
  }

  void _saveBoardingPoint() async {
    if (_formKey.currentState!.validate()) {
      final lat = double.tryParse(_latController.text.trim());
      final lng = double.tryParse(_lngController.text.trim());
      final busNumber = int.tryParse(_busNumberController.text.trim());

      if (lat != null && lng != null && busNumber != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('boarding_lat', lat);
        await prefs.setDouble('boarding_lng', lng);
        await prefs.setInt('bus_number', busNumber);

        await prefs.remove('home_route');
        await prefs.remove('college_route');
        Navigator.pop(context); // Return to previous screen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Boarding Point'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'SET YOUR BOARDING POINT',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _latController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(),
                  hintText: "e.g., 12.9633",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Latitude is required';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed < -90 || parsed > 90) {
                    return 'Invalid latitude (-90 to 90)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _lngController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(),
                  hintText: "e.g., 77.5906",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Longitude is required';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed < -180 || parsed > 180) {
                    return 'Invalid longitude (-180 to 180)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // New Bus Number field
              TextFormField(
                controller: _busNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Bus Number',
                  border: OutlineInputBorder(),
                  hintText: 'Enter bus number',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bus number is required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Invalid bus number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveBoardingPoint,
                child: const Text('SAVE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
