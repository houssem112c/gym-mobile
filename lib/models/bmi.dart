enum Gender {
  male,
  female,
}

enum BmiStatus {
  ok,
  caution,
  notOk,
}

class BmiRecord {
  final String id;
  final String userId;
  final int age;
  final Gender gender;
  final double height; // in meters
  final double weight; // in kilograms
  final double bmiValue;
  final String category;
  final BmiStatus status;
  final String? notes;
  final String? recommendations;
  final DateTime createdAt;
  final DateTime updatedAt;
  final BmiUser? user;

  BmiRecord({
    required this.id,
    required this.userId,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.bmiValue,
    required this.category,
    required this.status,
    this.notes,
    this.recommendations,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory BmiRecord.fromJson(Map<String, dynamic> json) {
    return BmiRecord(
      id: json['id'],
      userId: json['userId'],
      age: json['age'],
      gender: _parseGender(json['gender']),
      height: json['height'].toDouble(),
      weight: json['weight'].toDouble(),
      bmiValue: json['bmiValue'].toDouble(),
      category: json['category'],
      status: _parseStatus(json['status']),
      notes: json['notes'],
      recommendations: json['recommendations'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      user: json['user'] != null ? BmiUser.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'age': age,
      'gender': _genderToString(gender),
      'height': height,
      'weight': weight,
      'bmiValue': bmiValue,
      'category': category,
      'status': _statusToString(status),
      'notes': notes,
      'recommendations': recommendations,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'user': user?.toJson(),
    };
  }

  static Gender _parseGender(String genderStr) {
    switch (genderStr.toUpperCase()) {
      case 'MALE':
        return Gender.male;
      case 'FEMALE':
        return Gender.female;
      default:
        return Gender.male;
    }
  }

  static BmiStatus _parseStatus(String statusStr) {
    switch (statusStr.toUpperCase()) {
      case 'OK':
        return BmiStatus.ok;
      case 'CAUTION':
        return BmiStatus.caution;
      case 'NOT_OK':
        return BmiStatus.notOk;
      default:
        return BmiStatus.notOk;
    }
  }

  static String _genderToString(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'MALE';
      case Gender.female:
        return 'FEMALE';
    }
  }

  static String _statusToString(BmiStatus status) {
    switch (status) {
      case BmiStatus.ok:
        return 'OK';
      case BmiStatus.caution:
        return 'CAUTION';
      case BmiStatus.notOk:
        return 'NOT_OK';
    }
  }
}

class BmiUser {
  final String id;
  final String email;
  final String name;

  BmiUser({
    required this.id,
    required this.email,
    required this.name,
  });

  factory BmiUser.fromJson(Map<String, dynamic> json) {
    return BmiUser(
      id: json['id'],
      email: json['email'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
    };
  }
}

class CreateBmiRequest {
  final int age;
  final Gender gender;
  final double height;
  final double weight;

  CreateBmiRequest({
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
  });

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'gender': BmiRecord._genderToString(gender),
      'height': height,
      'weight': weight,
    };
  }
}

class BmiCalculationResult {
  final double bmiValue;
  final String category;
  final BmiStatus status;
  final String? recommendations;
  final CreateBmiRequest input;

  BmiCalculationResult({
    required this.bmiValue,
    required this.category,
    required this.status,
    this.recommendations,
    required this.input,
  });

  factory BmiCalculationResult.fromJson(Map<String, dynamic> json) {
    return BmiCalculationResult(
      bmiValue: json['bmiValue'].toDouble(),
      category: json['category'],
      status: BmiRecord._parseStatus(json['status']),
      recommendations: json['recommendations'],
      input: CreateBmiRequest(
        age: json['input']['age'],
        gender: BmiRecord._parseGender(json['input']['gender']),
        height: json['input']['height'].toDouble(),
        weight: json['input']['weight'].toDouble(),
      ),
    );
  }
}