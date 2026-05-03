class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final bool isActive;
  final String? avatar;
  final String? bio;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? address;
  final String? city;
  final String? country;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? trainingFrequency;
  final List<int>? trainingDays;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    this.avatar,
    this.bio,
    this.phone,
    this.dateOfBirth,
    this.address,
    this.city,
    this.country,
    required this.createdAt,
    required this.updatedAt,
    this.trainingFrequency,
    this.trainingDays,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? 'Unknown',
      role: json['role'] ?? 'USER',
      isActive: json['isActive'] ?? true,
      avatar: json['avatar'],
      bio: json['bio'],
      phone: json['phone'],
      dateOfBirth: json['dateOfBirth'] != null 
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      address: json['address'],
      city: json['city'],
      country: json['country'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      trainingFrequency: json['trainingFrequency'],
      trainingDays: json['trainingDays'] != null 
          ? List<int>.from(json['trainingDays']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'isActive': isActive,
      'avatar': avatar,
      'bio': bio,
      'phone': phone,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'address': address,
      'city': city,
      'country': country,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'trainingFrequency': trainingFrequency,
      'trainingDays': trainingDays,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    bool? isActive,
    String? avatar,
    String? bio,
    String? phone,
    DateTime? dateOfBirth,
    String? address,
    String? city,
    String? country,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? trainingFrequency,
    List<int>? trainingDays,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      trainingFrequency: trainingFrequency ?? this.trainingFrequency,
      trainingDays: trainingDays ?? this.trainingDays,
    );
  }

  String get fullAddress {
    final parts = [address, city, country].where((part) => part?.isNotEmpty ?? false);
    return parts.join(', ');
  }

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    final difference = now.difference(dateOfBirth!);
    return (difference.inDays / 365).floor();
  }
}

class UpdateProfileRequest {
  final String? name;
  final String? bio;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? address;
  final String? city;
  final String? country;
  final int? trainingFrequency;
  final List<int>? trainingDays;

  UpdateProfileRequest({
    this.name,
    this.bio,
    this.phone,
    this.dateOfBirth,
    this.address,
    this.city,
    this.country,
    this.trainingFrequency,
    this.trainingDays,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (bio != null) 'bio': bio,
      if (phone != null) 'phone': phone,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
      if (trainingFrequency != null) 'trainingFrequency': trainingFrequency,
      if (trainingDays != null) 'trainingDays': trainingDays,
    };
  }
}