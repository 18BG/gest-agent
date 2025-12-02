import 'package:flutter/material.dart';
import '../models/client.dart';

/// Widget réutilisable pour afficher une ligne de client dans une liste
/// Requirements: 4.2
class ClientTile extends StatelessWidget {
  final Client client;
  final VoidCallback? onTap;

  const ClientTile({
    super.key,
    required this.client,
    this.onTap,
  });

  /// Formate un montant en FCFA
  String _formatAmount(double amount) {
    final formatted = amount.abs().toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
    return '$formatted FCFA';
  }

  @override
  Widget build(BuildContext context) {
    final hasDebt = client.totalDebt > 0;

    return GestureDetector(
      onTap: onTap,
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
            // Avatar avec initiale
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasDebt
                    ? Colors.orange.shade100
                    : Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  client.name.isNotEmpty
                      ? client.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: hasDebt
                        ? Colors.orange.shade800
                        : Colors.green.shade800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Infos client
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    client.phone,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Dette ou statut
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hasDebt ? 'Dette: ${_formatAmount(client.totalDebt)}' : 'À jour',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: hasDebt ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            // Flèche
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
