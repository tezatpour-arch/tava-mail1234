class Note {
  final int? id;
  final String noteType;
  final String sender;
  final String subject;
  final String? severity;
  final String text;
  final DateTime date;

  Note({
    this.id,
    required this.noteType,
    required this.sender,
    required this.subject,
    this.severity,
    required this.text,
    required this.date,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      noteType: map['noteType'] as String,
      sender: map['sender'] as String,
      subject: map['subject'] as String,
      severity: map['severity'] as String?,
      text: map['text'] as String,
      date: DateTime.parse(map['date'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'noteType': noteType,
      'sender': sender,
      'subject': subject,
      'severity': severity,
      'text': text,
      'date': date.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) => Note.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  Note copyWith({
    int? id,
    String? noteType,
    String? sender,
    String? subject,
    String? severity,
    String? text,
    DateTime? date,
  }) {
    return Note(
      id: id ?? this.id,
      noteType: noteType ?? this.noteType,
      sender: sender ?? this.sender,
      subject: subject ?? this.subject,
      severity: severity ?? this.severity,
      text: text ?? this.text,
      date: date ?? this.date,
    );
  }
}
