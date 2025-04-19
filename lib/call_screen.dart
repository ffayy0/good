import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:mut6/alert_dialog_helper.dart';

class RequestHelpScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const RequestHelpScreen({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  _RequestHelpScreenState createState() => _RequestHelpScreenState();
}

class _RequestHelpScreenState extends State<RequestHelpScreen> {
  LatLng? _parentLocation; // موقع ولي الأمر
  LatLng? _schoolLocation; // موقع المدرسة
  LatLng _mapCenter = LatLng(24.5247, 39.5692); // مركز الخريطة الافتراضي
  MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    print("بدء تهيئة الموقع...");
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      // طلب صلاحية الموقع
      print("طلب صلاحية الموقع...");
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        print("صلاحية الموقع مرفوضة، طلب الصلاحية مرة أخرى...");
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("تم رفض صلاحية الموقع من قبل المستخدم.");
          return;
        }
      }

      // الحصول على موقع ولي الأمر
      print("جلب موقع ولي الأمر...");
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: AppleSettings(
          accuracy: LocationAccuracy.best,
          activityType: ActivityType.fitness,
          pauseLocationUpdatesAutomatically: true,
          allowBackgroundLocationUpdates: false,
        ),
      );
      _parentLocation = LatLng(position.latitude, position.longitude);
      print("موقع ولي الأمر: $_parentLocation");

      // جلب موقع المدرسة من Firestore
      print("جلب موقع المدرسة من Firestore...");
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc('1nopwBHqOJSVawb8kXD0Y45R0Iv1')
              .get();

      if (!doc.exists) {
        print(
          "خطأ: الوثيقة '1nopwBHqOJSVawb8kXD0Y45R0Iv1' غير موجودة في Firestore.",
        );
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("خطأ"),
                content: const Text(
                  "لم يتم العثور على موقع المدرسة في قاعدة البيانات.",
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("حسناً"),
                  ),
                ],
              ),
        );
        return;
      }

      // استخراج الموقع من حقل schoolLocation
      String schoolLocationStr = doc.get('schoolLocation');
      List<String> coordinates = schoolLocationStr.split(',');
      double lat = double.parse(coordinates[0]);
      double lng = double.parse(coordinates[1]);
      _schoolLocation = LatLng(lat, lng);
      print("موقع المدرسة: $_schoolLocation");

      // تحديث مركز الخريطة إلى موقع ولي الأمر
      setState(() {
        _mapCenter = _parentLocation!;
      });
      print("تم تحديث مركز الخريطة بنجاح.");
    } catch (e) {
      print('خطأ أثناء جلب الموقع: $e');
    }
  }

  void _checkDistance() {
    if (_parentLocation == null || _schoolLocation == null) {
      print("خطأ: موقع ولي الأمر أو المدرسة غير متوفر.");
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
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("حسناً"),
                ),
              ],
            ),
      );
      return;
    }

    // حساب المسافة بين ولي الأمر والمدرسة
    double distance = Distance().as(
      LengthUnit.Meter,
      _parentLocation!,
      _schoolLocation!,
    );
    print("المسافة بين ولي الأمر والمدرسة: $distance متر");

    if (distance <= 500) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => const AlertDialogHelper(
                title: "تم إرسال الطلب",
                message: "سوف يتم إلغاء الطلب بعد 5 دقائق",
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
                message: "لا يمكنك إتمام العملية بسبب بعدك عن المدرسة",
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
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
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                    ),
                    if (_parentLocation != null)
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
                  backgroundColor: const Color.fromARGB(255, 1, 113, 189),
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
