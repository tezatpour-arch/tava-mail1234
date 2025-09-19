class UserModel {
  final int? id;
  final String fullName;
  final String email;
  final String password;
  final bool isAdmin;

  UserModel({
    this.id,
    required this.fullName,
    required this.email,
    required this.password,
    this.isAdmin = false,
  });

  // تبدیل از JSON (برای API یا دیتابیس)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      password: json['password'],
      isAdmin: json['isAdmin'] == 1,
    );
  }

  // تبدیل به JSON (برای ارسال به API یا ذخیره در دیتابیس)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'password': password,
      'isAdmin': isAdmin ? 1 : 0,
    };
  }
}
