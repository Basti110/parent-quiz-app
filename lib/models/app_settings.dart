/// Model representing user application settings.
///
/// Stores user preferences for theme, language, and avatar selection.
class AppSettings {
  /// Whether dark mode is enabled
  final bool darkMode;

  /// Language code (e.g., 'en', 'de')
  final String languageCode;

  /// Optional path to user's selected avatar asset
  final String? avatarPath;

  const AppSettings({
    required this.darkMode,
    required this.languageCode,
    this.avatarPath,
  });

  /// Creates an AppSettings instance from a map.
  ///
  /// Used for deserializing from Firestore or SharedPreferences.
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      darkMode: map['darkMode'] as bool? ?? false,
      languageCode: map['languageCode'] as String? ?? 'en',
      avatarPath: map['avatarPath'] as String?,
    );
  }

  /// Converts the AppSettings instance to a map.
  ///
  /// Used for serializing to Firestore or SharedPreferences.
  Map<String, dynamic> toMap() {
    return {
      'darkMode': darkMode,
      'languageCode': languageCode,
      'avatarPath': avatarPath,
    };
  }

  /// Creates a copy of this AppSettings with the given fields replaced.
  AppSettings copyWith({
    bool? darkMode,
    String? languageCode,
    String? avatarPath,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      languageCode: languageCode ?? this.languageCode,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppSettings &&
        other.darkMode == darkMode &&
        other.languageCode == languageCode &&
        other.avatarPath == avatarPath;
  }

  @override
  int get hashCode {
    return darkMode.hashCode ^ languageCode.hashCode ^ avatarPath.hashCode;
  }

  @override
  String toString() {
    return 'AppSettings(darkMode: $darkMode, languageCode: $languageCode, avatarPath: $avatarPath)';
  }
}
