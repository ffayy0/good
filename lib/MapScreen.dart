import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng _selectedLocation = LatLng(24.5247, 39.5692); // الموقع الأولي
  GoogleMapController? _mapController;
  double _zoomLevel = 13.0;

  // دالة لتحديث الموقع في Firebase
  Future<void> _updateLocationInFirebase() async {
    try {
      // التحقق من تسجيل الدخول
      if (FirebaseAuth.instance.currentUser == null) {
        print("⚠️ المستخدم غير مسجل الدخول.");
        return;
      }

      // الحصول على المعرف الفعلي للمستخدم
      final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

      // الحصول على مرجع للمستند الذي يحتوي على بيانات المدرسة
      final schoolRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(currentUserId);

      // التحقق من وجود المستند
      final docSnapshot = await schoolRef.get();
      if (!docSnapshot.exists) {
        print("⚠️ المستند الخاص بالمدرسة غير موجود في Firestore.");
        return;
      }

      // تحديث الموقع في قاعدة البيانات
      await schoolRef.update({
        'schoolLocation': GeoPoint(
          _selectedLocation.latitude,
          _selectedLocation.longitude,
        ), // حفظ الموقع الجديد
      });

      print("✅ الموقع تم تحديثه في Firebase بنجاح!");
    } catch (e) {
      print("❌ حدث خطأ أثناء تحديث الموقع في Firebase: $e");
    }
  }

  void _zoomIn() {
    if (_mapController != null) {
      _zoomLevel++;
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _selectedLocation, zoom: _zoomLevel),
        ),
      );
    }
  }

  void _zoomOut() {
    if (_mapController != null && _zoomLevel > 1) {
      _zoomLevel--;
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _selectedLocation, zoom: _zoomLevel),
        ),
      );
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('تم تأكيد الموقع'),
          content: Text('تم اختيار الموقع: $_selectedLocation'),
          actions: [
            TextButton(
              child: Text('موافق'),
              onPressed: () {
                Navigator.of(context).pop();
                // تحديث الموقع في Firebase بعد التأكيد
                _updateLocationInFirebase();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تغيير موقع المدرسة',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              child: Text(
                'حدد موقع المدرسة الجديدة',
                style: TextStyle(
                  fontSize: 20,
                  color: Color.fromARGB(255, 1, 113, 189),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: _zoomLevel,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  markers: {
                    Marker(
                      markerId: MarkerId('selected-location'),
                      position: _selectedLocation,
                    ),
                  },
                  onTap: (LatLng position) {
                    setState(() {
                      _selectedLocation = position;
                    });
                  },
                  zoomControlsEnabled: false,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.zoom_in, size: 30, color: Colors.black54),
                  onPressed: _zoomIn,
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: Icon(Icons.zoom_out, size: 30, color: Colors.black54),
                  onPressed: _zoomOut,
                ),
              ],
            ),
            const SizedBox(height: 20),
            CustomButton(title: "تأكيد", onPressed: _showConfirmationDialog),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Simple button widget like in your original
class CustomButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;

  const CustomButton({required this.title, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onPressed,
      child: Text(title, style: TextStyle(color: Colors.white, fontSize: 18)),
    );
  }
}
