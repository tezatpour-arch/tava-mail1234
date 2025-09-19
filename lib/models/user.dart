class User {
  final int id;
  final String name;
  final String email;
  final String jobTitle;
  final String responsibility;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.jobTitle,
    required this.responsibility,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      jobTitle: json['job_title'],
      responsibility: json['responsibility'],
    );
  }
}
