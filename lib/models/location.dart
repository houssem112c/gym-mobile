class GymLocation {
  final String id;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final String? address;
  final String? phone;
  final String? email;
  final String? hours;
  final bool isActive;
  final int order;

  GymLocation({
    required this.id,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    this.address,
    this.phone,
    this.email,
    this.hours,
    required this.isActive,
    required this.order,
  });

  factory GymLocation.fromJson(Map<String, dynamic> json) {
    return GymLocation(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      hours: json['hours'],
      isActive: json['isActive'],
      order: json['order'],
    );
  }
}
