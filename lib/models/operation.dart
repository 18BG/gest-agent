/// Types d'opérations possibles
enum OperationType {
  venteCredit,
  transfert,
  depotUv,
  retraitUv,
  approvisionnementUv,    // Approvisionnement en UV (augmente UV)
  approvisionnementEspece, // Approvisionnement en espèces (augmente espèces)
  paiementClient;         // Paiement de dette par un client (augmente espèces)

  String get label {
    switch (this) {
      case OperationType.venteCredit:
        return 'Vente Crédit';
      case OperationType.transfert:
        return 'Transfert';
      case OperationType.depotUv:
        return 'Dépôt UV';
      case OperationType.retraitUv:
        return 'Retrait UV';
      case OperationType.approvisionnementUv:
        return 'Appro. UV';
      case OperationType.approvisionnementEspece:
        return 'Appro. Espèces';
      case OperationType.paiementClient:
        return 'Paiement Client';
    }
  }

  /// Indique si c'est un type d'approvisionnement
  bool get isApprovisionnement =>
      this == OperationType.approvisionnementUv ||
      this == OperationType.approvisionnementEspece;

  /// Indique si c'est un paiement client
  bool get isPaiementClient => this == OperationType.paiementClient;

  static OperationType fromString(String value) {
    return OperationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OperationType.transfert,
    );
  }
}

/// Modèle opération pour l'agent Wave
class Operation {
  final String id;
  final String? clientId;
  final OperationType type;
  final double amount;
  final bool isPaid;
  final String userId;
  final DateTime createdAt;

  Operation({
    required this.id,
    this.clientId,
    required this.type,
    required this.amount,
    required this.isPaid,
    required this.userId,
    required this.createdAt,
  });

  /// Crée une Operation depuis un record PocketBase
  factory Operation.fromJson(Map<String, dynamic> json) {
    return Operation(
      id: json['id'] as String,
      clientId: json['clientId'] as String?,
      type: OperationType.fromString(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      isPaid: json['isPaid'] as bool,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['created'] as String),
    );
  }

  /// Convertit en Map pour PocketBase (création)
  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'type': type.name,
      'amount': amount,
      'isPaid': isPaid,
      'userId': userId,
    };
  }

  /// Convertit en Map complet (incluant id et created)
  Map<String, dynamic> toFullJson() {
    return {
      'id': id,
      'clientId': clientId,
      'type': type.name,
      'amount': amount,
      'isPaid': isPaid,
      'userId': userId,
      'created': createdAt.toIso8601String(),
    };
  }

  /// Crée une copie avec des modifications
  Operation copyWith({
    String? id,
    String? clientId,
    OperationType? type,
    double? amount,
    bool? isPaid,
    String? userId,
    DateTime? createdAt,
  }) {
    return Operation(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Operation(id: $id, type: ${type.name}, amount: $amount, isPaid: $isPaid)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Operation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          clientId == other.clientId &&
          type == other.type &&
          amount == other.amount &&
          isPaid == other.isPaid &&
          userId == other.userId;

  @override
  int get hashCode =>
      id.hashCode ^
      clientId.hashCode ^
      type.hashCode ^
      amount.hashCode ^
      isPaid.hashCode ^
      userId.hashCode;
}
