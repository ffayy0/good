import 'package:flutter/material.dart';
import 'package:mut6/request.dart';

class RequestWidget extends StatelessWidget {
  final Request request;

  const RequestWidget({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    Color getColor() {
      if (request.distance <= 0.1) return Colors.red;
      if (request.distance <= 0.5) return Colors.orange;
      return Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: getColor().withOpacity(0.2),
        border: Border.all(color: getColor(), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '👦 الطالب: ${request.student.name}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text('📚 الصف: ${request.student.schoolClass}'),
          Text('👤 ولي الأمر: ${request.guardian.guardianName}'),
          Text('📍 البعد: ${request.distance.toStringAsFixed(2)} كم'),
          Text('🚦 الحالة: ${request.distance <= 0.1 ? "وصل" : "قريب"}'),
        ],
      ),
    );
  }
}
