class Request {
  final Student student;
  final Guardian guardian;
  final double distance;

  Request({
    required this.student,
    required this.guardian,
    required this.distance,
    required String id,
  });
}

class Student {
  final String name;
  final String schoolClass;

  Student({required this.name, required this.schoolClass, required id});
}

class Guardian {
  final String guardianName;

  Guardian({required this.guardianName});
}
