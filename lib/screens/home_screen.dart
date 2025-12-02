import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/operation.dart';
import '../utils/constants.dart';
import 'add_operation_screen.dart';
import 'main_screen.dart';

// Import pour DatabaseException
export '../services/database_service.dart' show DatabaseException, DatabaseErrorType;

/// Écran d'accueil complet (avec navigation) - utilisé après login
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirige vers MainScreen qui gère la navigation
    return const MainScreen();
  }
}

/// Tab Accueil - Dashboard principal de l'agent (sans BottomNav)
/// Requirements: 2.1, 2.2, 2.3, 2.4, 2.5
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {

  // État des données
  double _uvBalance = 0;
  double _cashBalance = 0;
  double _totalDebts = 0;
  List<Operation> _recentOperations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Charge les données depuis PocketBase
  /// Utilise getAllBalances() pour récupérer UV, espèces et dettes en 1 requête
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Une seule requête pour tous les soldes (view côté serveur)
      final balances = await DatabaseService.instance.getAllBalances();
      final operations = await DatabaseService.instance.getOperations(limit: 5);

      if (mounted) {
        setState(() {
          _uvBalance = balances.uv;
          _cashBalance = balances.cash;
          _totalDebts = balances.debts;
          _recentOperations = operations;
          _isLoading = false;
        });
      }
    } on DatabaseException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.userMessage);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Erreur de chargement des données');
      }
    }
  }


  /// Affiche un message d'erreur
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: WaveColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final userName = AuthService.instance.currentUser?.name ?? 'Agent';
    return AppBar(
      title: Text('Bonjour, $userName'),
      backgroundColor: WaveColors.primary,
      foregroundColor: WaveColors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
          tooltip: 'Actualiser',
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: WaveColors.primary),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: WaveColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Soldes UV et Espèces (Requirement 2.1)
            _buildBalanceCards(),
            const SizedBox(height: 16),

            // Total des dettes (Requirement 2.2)
            _buildDebtsCard(),
            const SizedBox(height: 24),

            // Dernières opérations (Requirement 2.5)
            _buildRecentOperations(),
          ],
        ),
      ),
    );
  }


  /// Cartes des soldes UV et Espèces (Requirement 2.1)
  Widget _buildBalanceCards() {
    return Row(
      children: [
        Expanded(
          child: _buildBalanceCard(
            title: 'UV',
            amount: _uvBalance,
            icon: Icons.account_balance_wallet,
            color: WaveColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBalanceCard(
            title: 'Espèces',
            amount: _cashBalance,
            icon: Icons.payments,
            color: WaveColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WaveColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: WaveColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatAmount(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: amount < 0 ? WaveColors.error : WaveColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Carte du total des dettes (Requirement 2.2)
  Widget _buildDebtsCard() {
    final hasDebts = _totalDebts > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WaveColors.white,
        borderRadius: BorderRadius.circular(12),
        border: hasDebts
            ? Border.all(color: WaveColors.warning.withValues(alpha: 0.3), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasDebts
                  ? WaveColors.warning.withValues(alpha: 0.1)
                  : WaveColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasDebts ? Icons.warning_amber : Icons.check_circle,
              color: hasDebts ? WaveColors.warning : WaveColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dettes clients',
                  style: TextStyle(
                    fontSize: 14,
                    color: WaveColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasDebts ? _formatAmount(_totalDebts) : 'Aucune dette',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: hasDebts ? WaveColors.warning : WaveColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  /// Liste des dernières opérations (Requirement 2.5)
  Widget _buildRecentOperations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dernières opérations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        if (_recentOperations.isEmpty)
          _buildEmptyOperations()
        else
          ..._recentOperations.map(_buildOperationTile),
      ],
    );
  }

  Widget _buildEmptyOperations() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: WaveColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long,
            size: 48,
            color: WaveColors.grey,
          ),
          SizedBox(height: 12),
          Text(
            'Aucune opération',
            style: TextStyle(
              color: WaveColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationTile(Operation operation) {
    final isPositive = operation.type == OperationType.retraitUv ||
        (operation.isPaid && operation.type != OperationType.depotUv);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WaveColors.white,
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
                  style: const TextStyle(
                    color: WaveColors.textSecondary,
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
                  color: isPositive ? WaveColors.success : WaveColors.textPrimary,
                ),
              ),
              if (!operation.isPaid)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: WaveColors.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Dette',
                    style: TextStyle(
                      fontSize: 10,
                      color: WaveColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

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


  /// Bouton flottant "Nouvelle opération" (Requirement 2.3)
  Widget _buildFAB() {
    return FloatingActionButton.extended(
      heroTag: 'home_fab',
      onPressed: () async {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const AddOperationScreen()),
        );
        // Recharger les données si une opération a été créée
        if (result == true) {
          _loadData();
        }
      },
      backgroundColor: WaveColors.primary,
      foregroundColor: WaveColors.white,
      icon: const Icon(Icons.add),
      label: const Text('Nouvelle opération'),
    );
  }

}
