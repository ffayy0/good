import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late GoogleMapController _mapController;
  LatLng _pickedLocation = LatLng(0.0, 0.0); // موقع افتراضي

  // عندما يتم إنشاء الخريطة
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  // عندما يتم النقر على الخريطة لتحديد الموقع
  void _onTap(LatLng location) {
    setState(() {
      _pickedLocation = location; // تحديث الموقع المحدد
    });
  }

  // عندما يضغط المستخدم على زر التأكيد، يتم العودة إلى الشاشة السابقة مع الموقع المحدد
  void _confirmLocation() {
    Navigator.pop(context, _pickedLocation); // إرسال الموقع المحدد
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختيار موقع المدرسة'),
        backgroundColor: const Color.fromARGB(255, 1, 113, 189),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _pickedLocation,
          zoom: 15,
        ),
        onMapCreated: _onMapCreated,
        onTap: _onTap, // عندما ينقر المستخدم على الخريطة
        markers: {
          Marker(
            markerId: MarkerId('picked-location'),
            position: _pickedLocation,
          ),
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _confirmLocation,
        backgroundColor: const Color.fromARGB(255, 1, 113, 189), // تأكيد الموقع
        child: Icon(Icons.check),
      ),
    );
  }
}
