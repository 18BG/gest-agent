/// Modèle paiement de dette pour l'agent Wave
class Payment {
  final String id;
  final String clientId;
  final double amount;
  final String userId;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.clientId,
    required this.amount,
    required this.userId,
    required this.createdAt,
  });

  /// Crée un Payment depuis un record PocketBase
  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      amount: (json['amount'] as num).toDouble(),
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['created'] as String),
    );
  }

  /// Convertit en Map pour PocketBase (création)
  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'amount': amount,
      'userId': userId,
    };
  }

  /// Convertit en Map complet (incluant id et created)
  Map<String, dynamic> toFullJson() {
    return {
      'id': id,
      'clientId': clientId,
      'amount': amount,
      'userId': userId,
      'created': createdAt.toIso8601String(),
    };
  }

  /// Crée une copie avec des modifications
  Payment copyWith({
    String? id,
    String? clientId,
    double? amount,
    String? userId,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      amount: amount ?? this.amount,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Payment(id: $id, clientId: $clientId, amount: $amount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Payment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          clientId == other.clientId &&
          amount == other.amount &&
          userId == other.userId;

  @override
  int get hashCode =>
      id.hashCode ^ clientId.hashCode ^ amount.hashCode ^ userId.hashCode;
}
