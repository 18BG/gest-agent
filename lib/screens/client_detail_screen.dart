import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/operation.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../widgets/operation_tile.dart';
import 'edit_operation_screen.dart';

// Import pour DatabaseException
export '../services/database_service.dart' show DatabaseException;

/// Écran détail client - affiche infos, dette, historique et paiements
/// Requirements: 4.3, 4.4
class ClientDetailScreen extends StatefulWidget {
  final Client client;

  const ClientDetailScreen({super.key, required this.client});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  late Client _client;
  List<Operation> _clientOperations = [];
  bool _isLoading = true;
  bool _isPaymentFormVisible = false;
  final TextEditingController _paymentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _client = widget.client;
    _loadClientData();
  }

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  /// Charge les données du client et son historique d'opérations
  Future<void> _loadClientData() async {
    setState(() => _isLoading = true);

    try {
      // Recharger le client pour avoir la dette à jour
      final updatedClient = await DatabaseService.instance.getClient(_client.id);
      if (updatedClient != null) {
        _client = updatedClient;
      }

      // Charger les opérations du client (incluant les paiements)
      final allOperations = await DatabaseService.instance.getOperations();
      final clientOps = allOperations
          .where((op) => op.clientId == _client.id)
          .toList();

      if (mounted) {
        setState(() {
          _clientOperations = clientOps;
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
        _showError('Erreur de chargement');
      }
    }
  }

  /// Formate un montant en FCFA
  String _formatAmount(double amount) {
    final formatted = amount.abs().toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
    return '$formatted FCFA';
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

  /// Affiche un message de succès
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: WaveColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Affiche/masque le formulaire de paiement (Requirement 4.4 - 15.4, 15.5)
  void _togglePaymentForm() {
    setState(() {
      _isPaymentFormVisible = !_isPaymentFormVisible;
      if (!_isPaymentFormVisible) {
        _paymentController.clear();
      }
    });
  }

  /// Enregistre un paiement de dette (Requirement 4.4)
  /// Crée une opération de type paiementClient et met à jour la dette
  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_paymentController.text) ?? 0;
    if (amount <= 0) {
      _showError('Montant invalide');
      return;
    }

    if (amount > _client.totalDebt) {
      _showError('Le montant dépasse la dette');
      return;
    }

    try {
      // Créer une opération de type paiementClient
      final operation = Operation(
        id: '',
        clientId: _client.id,
        type: OperationType.paiementClient,
        amount: amount,
        isPaid: true, // Toujours payé car c'est un paiement reçu
        userId: DatabaseService.instance.currentUserId ?? '',
        createdAt: DateTime.now(),
      );

      await DatabaseService.instance.createOperation(operation);

      // Mettre à jour la dette du client
      final newDebt = (_client.totalDebt - amount).clamp(0.0, double.infinity);
      await DatabaseService.instance.updateClientDebt(_client.id, newDebt);

      // Notification de confirmation
      await NotificationService.instance.showOperationConfirmation(
        operationType: 'Paiement Client',
        amount: amount,
        clientName: _client.name,
      );

      _showSuccess('Paiement enregistré');
      _paymentController.clear();
      setState(() => _isPaymentFormVisible = false);

      // Recharger les données
      await _loadClientData();
    } on DatabaseException catch (e) {
      _showError(e.userMessage);
    } catch (e) {
      _showError('Erreur lors de l\'enregistrement');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaveColors.greyLight,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_client.name),
      backgroundColor: WaveColors.primary,
      foregroundColor: WaveColors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadClientData,
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
      onRefresh: _loadClientData,
      color: WaveColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Infos client et dette (15.2)
            _buildClientInfoCard(),
            const SizedBox(height: 16),
            // Bouton paiement (15.4)
            _buildPaymentButton(),
            // Formulaire paiement (15.5)
            if (_isPaymentFormVisible) ...[
              const SizedBox(height: 16),
              _buildPaymentForm(),
            ],
            const SizedBox(height: 24),
            // Historique opérations (incluant les paiements) (15.3)
            _buildOperationsHistory(),
          ],
        ),
      ),
    );
  }

  /// Card avec infos client et dette totale (Requirement 4.3 - 15.2)
  Widget _buildClientInfoCard() {
    final hasDebt = _client.totalDebt > 0;

    return Container(
      padding: const EdgeInsets.all(20),
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
          // Avatar et nom
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: WaveColors.primary.withValues(alpha: 0.1),
                child: Text(
                  _client.name.isNotEmpty ? _client.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: WaveColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _client.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: WaveColors.greyDark),
                        const SizedBox(width: 4),
                        Text(
                          _client.phone,
                          style: const TextStyle(
                            fontSize: 14,
                            color: WaveColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          // Dette totale
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dette totale',
                style: TextStyle(
                  fontSize: 16,
                  color: WaveColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hasDebt 
                      ? WaveColors.error.withValues(alpha: 0.1) 
                      : WaveColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hasDebt ? _formatAmount(_client.totalDebt) : 'À jour',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: hasDebt ? WaveColors.error : WaveColors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bouton pour enregistrer un paiement (Requirement 4.4 - 15.4)
  Widget _buildPaymentButton() {
    if (_client.totalDebt <= 0) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _togglePaymentForm,
        icon: Icon(_isPaymentFormVisible ? Icons.close : Icons.payment),
        label: Text(_isPaymentFormVisible ? 'Annuler' : 'Enregistrer paiement'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isPaymentFormVisible ? WaveColors.grey : WaveColors.primary,
          foregroundColor: WaveColors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  /// Formulaire de paiement (Requirement 4.4 - 15.5)
  Widget _buildPaymentForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WaveColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WaveColors.primary.withValues(alpha: 0.3)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Montant du paiement',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _paymentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Entrez le montant',
                suffixText: 'FCFA',
                filled: true,
                fillColor: WaveColors.greyLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: WaveColors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: WaveColors.primary, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un montant';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Montant invalide';
                }
                if (amount > _client.totalDebt) {
                  return 'Le montant dépasse la dette (${_formatAmount(_client.totalDebt)})';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Dette actuelle: ',
              style: TextStyle(
                fontSize: 12,
                color: WaveColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WaveColors.success,
                  foregroundColor: WaveColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Confirmer le paiement',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ouvre l'écran de modification d'une opération
  Future<void> _editOperation(Operation operation) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditOperationScreen(operation: operation)),
    );
    if (result == true) _loadClientData();
  }

  /// Supprime une opération avec confirmation
  /// Si c'est un paiementClient, réajuste la dette du client
  Future<void> _deleteOperation(Operation operation) async {
    final isPaiement = operation.type.isPaiementClient;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'opération ?'),
        content: Text(
          '${operation.type.label} - ${operation.amount.toStringAsFixed(0)} FCFA'
          '${isPaiement ? '\n\nLa dette du client sera réajustée.' : ''}'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: WaveColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await DatabaseService.instance.deleteOperation(operation.id);
      
      // Si c'était un paiement client, réajuster la dette
      if (isPaiement && operation.clientId != null) {
        final newDebt = _client.totalDebt + operation.amount;
        await DatabaseService.instance.updateClientDebt(operation.clientId!, newDebt);
      }
      
      _showSuccess('Opération supprimée');
      _loadClientData();
    } on DatabaseException catch (e) {
      _showError(e.userMessage);
    } catch (e) {
      _showError('Erreur lors de la suppression');
    }
  }

  /// Historique des opérations du client (Requirement 4.3 - 15.3)
  Widget _buildOperationsHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Historique des opérations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_clientOperations.length} opération(s)',
              style: const TextStyle(fontSize: 14, color: WaveColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_clientOperations.isEmpty)
          _buildEmptyOperations()
        else
          ..._clientOperations.map((op) => OperationTile(
            operation: op,
            onEdit: () => _editOperation(op),
            onDelete: () => _deleteOperation(op),
          )),
      ],
    );
  }

  /// État vide - aucune opération
  Widget _buildEmptyOperations() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: WaveColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: WaveColors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'Aucune opération',
              style: TextStyle(
                fontSize: 14,
                color: WaveColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
