class Invoice {
  int? id;
  String description;
  String filePath;
  DateTime date;
  String status;
  String receiver;

  Invoice({
    this.id,
    required this.description,
    required this.filePath,
    required this.date,
    this.status = 'در حال بررسی',
    required this.receiver,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'filePath': filePath,
      'date': date.toIso8601String(),
      'status': status,
      'receiver': receiver,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      description: map['description'],
      filePath: map['filePath'],
      date: DateTime.parse(map['date']),
      status: map['status'],
      receiver: map['receiver'],
    );
  }
}
