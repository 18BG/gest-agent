/// Modèle client pour l'agent Wave
class Client {
  final String id;
  final String name;
  final String phone;
  double totalDebt;
  final String userId;
  final DateTime createdAt;

  Client({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalDebt,
    required this.userId,
    required this.createdAt,
  });

  /// Crée un Client depuis un record PocketBase
  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      totalDebt: (json['totalDebt'] as num).toDouble(),
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['created'] as String),
    );
  }

  /// Convertit en Map pour PocketBase (création)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'totalDebt': totalDebt,
      'userId': userId,
    };
  }

  /// Convertit en Map complet (incluant id et created)
  Map<String, dynamic> toFullJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'totalDebt': totalDebt,
      'userId': userId,
      'created': createdAt.toIso8601String(),
    };
  }

  /// Crée une copie avec des modifications
  Client copyWith({
    String? id,
    String? name,
    String? phone,
    double? totalDebt,
    String? userId,
    DateTime? createdAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      totalDebt: totalDebt ?? this.totalDebt,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Client(id: $id, name: $name, phone: $phone, totalDebt: $totalDebt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Client &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          phone == other.phone &&
          totalDebt == other.totalDebt &&
          userId == other.userId;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      phone.hashCode ^
      totalDebt.hashCode ^
      userId.hashCode;
}
