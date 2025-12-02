import 'package:flutter/material.dart';
import '../models/operation.dart';
import '../utils/constants.dart';

/// Widget réutilisable pour afficher une ligne d'opération dans une liste
/// Requirements: 3.6
class OperationTile extends StatelessWidget {
  final Operation operation;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const OperationTile({
    super.key,
    required this.operation,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  /// Formate un montant en FCFA
  String _formatAmount(double amount) {
    final formatted = amount.abs().toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
    return '$formatted FCFA';
  }

  /// Formate la date/heure
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (date == today) {
      return 'Aujourd\'hui, $time';
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Hier, $time';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}, $time';
    }
  }

  /// Retourne l'icône selon le type d'opération
  IconData _getOperationIcon(OperationType type) {
    switch (type) {
      case OperationType.depotUv:
        return Icons.arrow_downward;
      case OperationType.retraitUv:
        return Icons.arrow_upward;
      case OperationType.transfert:
        return Icons.swap_horiz;
      case OperationType.venteCredit:
        return Icons.phone_android;
      case OperationType.approvisionnementUv:
        return Icons.add_card;
      case OperationType.approvisionnementEspece:
        return Icons.account_balance_wallet;
      case OperationType.paiementClient:
        return Icons.payments;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = operation.type == OperationType.retraitUv ||
        (operation.isPaid && operation.type != OperationType.depotUv);

    return GestureDetector(
      onTap: onTap ?? onEdit,
      onLongPress: _showActionsMenu(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icône du type
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: WaveColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getOperationIcon(operation.type),
                color: WaveColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Détails
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    operation.type.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDateTime(operation.createdAt),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Montant
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatAmount(operation.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isPositive ? Colors.green.shade700 : Colors.black87,
                  ),
                ),
                if (!operation.isPaid)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Dette',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            // Menu actions si callbacks fournis
            if (onEdit != null || onDelete != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: WaveColors.greyDark, size: 20),
                onSelected: (value) {
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Modifier')])),
                  if (onDelete != null)
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: WaveColors.error, size: 18), SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: WaveColors.error))])),
                ],
              ),
          ],
        ),
      ),
    );
  }

  VoidCallback? _showActionsMenu(BuildContext context) {
    if (onEdit == null && onDelete == null) return null;
    return () {
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onEdit != null)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Modifier'),
                  onTap: () { Navigator.pop(context); onEdit?.call(); },
                ),
              if (onDelete != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: WaveColors.error),
                  title: const Text('Supprimer', style: TextStyle(color: WaveColors.error)),
                  onTap: () { Navigator.pop(context); onDelete?.call(); },
                ),
            ],
          ),
        ),
      );
    };
  }
}
