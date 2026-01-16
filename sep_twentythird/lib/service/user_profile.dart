class UserProfile {
  final String uid;

  final String? birthday; // yyyy-MM-dd
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

  // =======================
  // SQLite → Model（防呆完整版）
  // =======================
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    int _toInt(dynamic v, {int defaultValue = 0}) {
      if (v == null) return defaultValue;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? defaultValue;
      return defaultValue;
    }

    return UserProfile(
      uid: map['uid']?.toString() ?? '',
      birthday: map['birthday']?.toString(),
      gender: map['gender']?.toString(),
      heightCm: _toDouble(map['height_cm']),
      weightKg: _toDouble(map['weight_kg']),
      chronicConditions: map['chronic_conditions']?.toString(),
      email: map['email']?.toString(),
      phone: map['phone']?.toString(),
      updatedAt: _toInt(
        map['updated_at'],
        defaultValue: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  // =======================
  // Model → SQLite
  // =======================
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

  // =======================
  // 第一次登入用的空白 Profile
  // =======================
  factory UserProfile.empty(String uid, {String? email}) {
    return UserProfile(
      uid: uid,
      email: email,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}