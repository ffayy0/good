import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DistanceService {
  static const double earthRadius = 6371; // نصف قطر الأرض بالكيلومترات

  static double calculateDistance(LatLng point1, LatLng point2) {
    double dLat = _degToRad(point2.latitude - point1.latitude);
    double dLon = _degToRad(point2.longitude - point1.longitude);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(point1.latitude)) *
            cos(_degToRad(point2.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degToRad(double degree) {
    return degree * pi / 180; // تحويل من درجات إلى راديان
  }
}
