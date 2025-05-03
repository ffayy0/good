import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mut6/alert_dialog_helper.dart';

class RequestHelpScreenWithSchoolInput extends StatefulWidget {
  final String studentId;
  final String studentName;

  const RequestHelpScreenWithSchoolInput({
    Key? key,
    required this.studentId,
    required this.studentName,
    required schoolId,
  }) : super(key: key);

  @override
  _RequestHelpScreenWithSchoolInputState createState() =>
      _RequestHelpScreenWithSchoolInputState();
}

class _RequestHelpScreenWithSchoolInputState
    extends State<RequestHelpScreenWithSchoolInput> {
  LatLng? _parentLocation;
  LatLng? _schoolLocation;
  LatLng _mapCenter = LatLng(24.5247, 39.5692);
  MapController _mapController = MapController();
  final TextEditingController _schoolIdController = TextEditingController();
  bool _requestSent = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
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
    } catch (e) {
      print('❌ خطأ في تحديد الموقع: $e');
      _showLocationError();
    }
  }

  void _showLocationError() {
    showDialog(
      context: context,
      builder:
          (context) => const AlertDialog(
            title: Text("خطأ"),
            content: Text("لم يتم تحديد موقعك أو المدرسة بشكل صحيح."),
            actions: [TextButton(child: Text("حسناً"), onPressed: null)],
          ),
    );
  }

  Future<bool> _isSchoolMatchingStudent(
    String studentId,
    String schoolId,
  ) async {
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('students')
              .where('id', isEqualTo: studentId)
              .limit(1)
              .get();

      if (query.docs.isNotEmpty &&
          query.docs.first.data()['schoolId'] == schoolId) {
        return true;
      }
    } catch (e) {
      print("❌ خطأ أثناء التحقق من تطابق المدرسة والطالب: $e");
    }
    return false;
  }

  Future<void> _validateSchoolIdAndProceed() async {
    final enteredId = _schoolIdController.text.trim();
    if (enteredId.isEmpty) {
      _showSnack("الرجاء إدخال معرف المدرسة");
      return;
    }

    final doc =
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(enteredId)
            .get();

    if (!doc.exists || doc['latitude'] == null || doc['longitude'] == null) {
      _showSnack("معرف المدرسة غير صحيح أو ناقص");
      return;
    }

    final isMatch = await _isSchoolMatchingStudent(widget.studentId, enteredId);
    if (!isMatch) {
      _showSnack("المدرسة لا تتطابق مع الطالب");
      return;
    }

    _schoolLocation = LatLng(doc['latitude'], doc['longitude']);
    _checkDistance(enteredId);
  }

  void _checkDistance(String schoolId) {
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

    if (estimatedMinutes <= 5) {
      _saveRequestToFirestore(schoolId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => const AlertDialogHelper(
                title: "تم إرسال الطلب",
                message: "يمكنك تكرار الطلب بعد 5 دقائق ",
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

  Future<void> _saveRequestToFirestore(String schoolId) async {
    if (_requestSent || _parentLocation == null) return;

    try {
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
            content: Text("انتهى الطلب  بعد 5 دقائق"),
            backgroundColor: Colors.orange,
          ),
        );
      });
    } catch (e) {
      print('❌ خطأ أثناء حفظ الطلب: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _schoolIdController,
              decoration: InputDecoration(
                labelText: "أدخل معرف المدرسة",
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.right,
            ),
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
                    if (_schoolLocation != null)
                      MarkerLayer(
                        markers: [
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
                onPressed: _validateSchoolIdAndProceed,
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
