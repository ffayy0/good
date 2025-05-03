import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mut6/alert_dialog_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RequestHelpScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const RequestHelpScreen({
    Key? key,
    required this.studentId,
    required this.studentName,
    required schoolId,
  }) : super(key: key);

  @override
  _RequestHelpScreenState createState() => _RequestHelpScreenState();
}

class _RequestHelpScreenState extends State<RequestHelpScreen> {
  LatLng? _parentLocation;
  LatLng? _schoolLocation;
  LatLng _mapCenter = LatLng(24.5247, 39.5692);
  MapController _mapController = MapController();
  bool _requestSent = false;

  @override
  void initState() {
    super.initState();
    _initializeLocationAndSchool();
  }

  Future<void> _initializeLocationAndSchool() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _parentLocation = LatLng(position.latitude, position.longitude);
        _mapCenter = _parentLocation!;
      });
      print("✅ موقع المستخدم الحالي (ولي الأمر): $_parentLocation");

      String? schoolId = await _getSchoolIdFromStudent(widget.studentId);
      if (schoolId == null) {
        print("❌ لم يتم استخراج schoolId للطالب");
        _showLocationError();
        return;
      }
      print("✅ تم استخراج schoolId: $schoolId");

      DocumentSnapshot schoolDoc =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(schoolId)
              .get();

      if (!schoolDoc.exists) {
        print("❌ المدرسة غير موجودة في قاعدة البيانات");
        _showLocationError();
        return;
      }

      if (schoolDoc['latitude'] == null || schoolDoc['longitude'] == null) {
        print("❌ المدرسة موجودة ولكن بدون إحداثيات");
        _showLocationError();
        return;
      }

      _schoolLocation = LatLng(schoolDoc['latitude'], schoolDoc['longitude']);
      print("✅ تم تحميل موقع المدرسة: $_schoolLocation");

      setState(() {});
    } catch (e) {
      print('❌ خطأ أثناء التهيئة: $e');
      _showLocationError();
    }
  }

  Future<String?> _getSchoolIdFromStudent(String studentId) async {
    try {
      final studentDoc =
          await FirebaseFirestore.instance
              .collection('students')
              .doc(studentId)
              .get();

      if (!studentDoc.exists) return null;
      final guardianId = studentDoc['guardianId'];

      final parentQuery =
          await FirebaseFirestore.instance
              .collection('parents')
              .where('id', isEqualTo: guardianId)
              .limit(1)
              .get();

      if (parentQuery.docs.isEmpty) return null;
      return parentQuery.docs.first['schoolId'];
    } catch (e) {
      print("❌ خطأ في استخراج schoolId: $e");
      return null;
    }
  }

  void _showLocationError() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("خطأ"),
            content: const Text(
              "لم يتم تحديد موقعك أو موقع المدرسة بشكل صحيح.",
            ),
            actions: [
              TextButton(
                child: const Text("حسناً"),
                onPressed: () => Navigator.pop(context), // ✅ إصلاح زر الإغلاق
              ),
            ],
          ),
    );
  }

  Future<void> _saveRequestToFirestore() async {
    if (_requestSent || _parentLocation == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      String? schoolId = prefs.getString('schoolId') ?? '';

      await FirebaseFirestore.instance.collection('pikup_call').add({
        'studentName': widget.studentName,
        'studentId': widget.studentId,
        'timestamp': Timestamp.now(),
        'status': 'جديد',
        'location':
            '${_parentLocation!.latitude}, ${_parentLocation!.longitude}',
        'schoolId': schoolId,
      });

      setState(() {
        _requestSent = true;
      });

      Future.delayed(const Duration(minutes: 5), () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "انتهى الطلب تلقائيًا بعد 5 دقائق، يمكنك إنشاء طلب جديد الآن.",
            ),
            backgroundColor: Colors.orange,
          ),
        );
      });
    } catch (e) {
      print('❌ خطأ أثناء حفظ الطلب: $e');
    }
  }

  void _checkDistance() {
    if (_parentLocation == null || _schoolLocation == null) {
      _showLocationError();
      return;
    }

    double distanceInMeters = Distance().as(
      LengthUnit.Meter,
      _parentLocation!,
      _schoolLocation!,
    );

    double walkingSpeedMetersPerMinute = 80;
    double estimatedMinutes = distanceInMeters / walkingSpeedMetersPerMinute;

    print("📏 المسافة: $distanceInMeters متر ≈ $estimatedMinutes دقائق");

    if (estimatedMinutes <= 5) {
      _saveRequestToFirestore();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => const AlertDialogHelper(
                title: "تم إرسال الطلب",
                message: "سيتم إلغاء الطلب بعد 5 دقائق تلقائيًا",
              ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => const AlertDialogHelper(
                title: "عذراً",
                message: "لا يمكنك تنفيذ العملية بسبب بعدك عن المدرسة",
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('طلب نداء', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child:
            (_parentLocation == null || _schoolLocation == null)
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'موقعك الحالي سيتم التحقق منه تلقائيًا',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color.fromARGB(255, 1, 113, 189),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.1 * 255).toInt()),
                            blurRadius: 5,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _mapCenter,
                            initialZoom: 13.0,
                            minZoom: 1.0,
                            maxZoom: 18.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _parentLocation!,
                                  child: const Icon(
                                    Icons.person_pin_circle,
                                    color: Colors.blue,
                                    size: 40,
                                  ),
                                ),
                                Marker(
                                  point: _schoolLocation!,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 150,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _checkDistance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            1,
                            113,
                            189,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'تأكيد',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
