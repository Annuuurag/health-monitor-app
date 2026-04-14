class UserProfile {
  const UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.emergencyContact,
  });

  final String name;
  final int age;
  final String gender;
  final int heightCm;
  final int weightKg;
  final String emergencyContact;

  factory UserProfile.defaults() {
    return const UserProfile(
      name: 'Anurag Sharma',
      age: 22,
      gender: 'Male',
      heightCm: 174,
      weightKg: 69,
      emergencyContact: '+91 98765 43210',
    );
  }

  UserProfile copyWith({
    String? name,
    int? age,
    String? gender,
    int? heightCm,
    int? weightKg,
    String? emergencyContact,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'emergencyContact': emergencyContact,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? 'Anurag Sharma',
      age: json['age'] as int? ?? 22,
      gender: json['gender'] as String? ?? 'Male',
      heightCm: json['heightCm'] as int? ?? 174,
      weightKg: json['weightKg'] as int? ?? 69,
      emergencyContact:
          json['emergencyContact'] as String? ?? '+91 98765 43210',
    );
  }
}
