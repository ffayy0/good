class Student {
  final int id;
  final String name;
  final String schoolClass;
  final String stage;

  Student({
    required this.id,
    required this.name,
    required this.schoolClass,
    required this.stage,
  });

  factory Student.fromFirestore(Map<String, dynamic> data) {
    return Student(
      id: data['id'],
      name: data['name'],
      schoolClass: data['schoolClass'],
      stage: data['stage'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'id': id, 'name': name, 'schoolClass': schoolClass, 'stage': stage};
  }
}
