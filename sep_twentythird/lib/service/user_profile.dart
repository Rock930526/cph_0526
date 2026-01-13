class UserProfile {
  final String uid;

  final String? birthday; // ISO yyyy-MM-dd
  final String? gender;   // male / female / other
  final double? heightCm;
  final double? weightKg;
  final String? chronicConditions;
  final String? email;
  final String? phone;

  final int updatedAt; // unix timestamp (ms)

  UserProfile({
    required this.uid,
    this.birthday,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.chronicConditions,
    this.email,
    this.phone,
    required this.updatedAt,
  });

  /// =======================
  /// 從 SQLite Map 轉成物件
  /// =======================
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'],
      birthday: map['birthday'],
      gender: map['gender'],
      heightCm: map['height_cm']?.toDouble(),
      weightKg: map['weight_kg']?.toDouble(),
      chronicConditions: map['chronic_conditions'],
      email: map['email'],
      phone: map['phone'],
      updatedAt: map['updated_at'],
    );
  }

  /// =======================
  /// 轉成 SQLite Map
  /// =======================
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'birthday': birthday,
      'gender': gender,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'chronic_conditions': chronicConditions,
      'email': email,
      'phone': phone,
      'updated_at': updatedAt,
    };
  }

  /// =======================
  /// 建立「空白使用者」
  /// （第一次登入但尚未填）
  /// =======================
  factory UserProfile.empty(String uid, {String? email}) {
    return UserProfile(
      uid: uid,
      email: email,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
