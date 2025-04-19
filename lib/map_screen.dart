// map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mut6/distance_service.dart';
import 'package:mut6/location_service.dart';

class MapScreen extends StatefulWidget {
  final LatLng schoolLocation;

  const MapScreen({super.key, required this.schoolLocation});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? guardianLocation;
  final LocationService _locationService = LocationService();
  late GoogleMapController _mapController;
  double? _distanceToSchool;

  @override
  void initState() {
    super.initState();
    _locationService.requestPermission().then((granted) {
      if (granted) {
        _locationService.getCurrentLocation().then((location) {
          setState(() {
            guardianLocation = location;
            _updateDistance(location);
          });
        });

        _locationService.trackLocation().listen((location) {
          setState(() {
            guardianLocation = location;
            _updateDistance(location);
          });
        });
      }
    });
  }

  void _updateDistance(LatLng? location) {
    if (location != null) {
      _distanceToSchool = DistanceService.calculateDistance(
        location,
        widget.schoolLocation,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تتبع الموقع المباشر")),
      body: Column(
        children: [
          Expanded(
            child:
                guardianLocation == null
                    ? const Center(child: CircularProgressIndicator())
                    : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: guardianLocation!,
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId("guardian"),
                          position: guardianLocation!,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                        ),
                        Marker(
                          markerId: const MarkerId("school"),
                          position: widget.schoolLocation,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueGreen,
                          ),
                        ),
                      },
                      onMapCreated: (controller) => _mapController = controller,
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child:
                _distanceToSchool != null
                    ? Text(
                      "المسافة إلى المدرسة: ${_distanceToSchool!.toStringAsFixed(2)} كم",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    : const Text("جارٍ حساب المسافة..."),
          ),
        ],
      ),
    );
  }
}
