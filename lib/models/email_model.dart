class AppearanceSetting {
  final int id;
  final String themeColor;
  final bool isDarkMode;

  AppearanceSetting({
    required this.id,
    required this.themeColor,
    required this.isDarkMode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'themeColor': themeColor,
      'isDarkMode': isDarkMode ? 1 : 0,
    };
  }

  factory AppearanceSetting.fromMap(Map<String, dynamic> map) {
    return AppearanceSetting(
      id: map['id'],
      themeColor: map['themeColor'],
      isDarkMode: map['isDarkMode'] == 1,
    );
  }
}
