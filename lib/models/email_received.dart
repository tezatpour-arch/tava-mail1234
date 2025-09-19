class EmailReceived {
  final int id;
  final String from;
  final String subject;
  final String date;
  final String body;

  EmailReceived({
    required this.id,
    required this.from,
    required this.subject,
    required this.date,
    required this.body,
  });

  factory EmailReceived.fromJson(Map<String, dynamic> json) {
    return EmailReceived(
      id: json['id'],
      from: json['from'],
      subject: json['subject'],
      date: json['date'],
      body: json['body'],
    );
  }
}
