import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/operation.dart';
import '../models/client.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

// Import pour DatabaseException
export '../services/database_service.dart' show DatabaseException;

/// Écran d'ajout d'opération
/// Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 6.1
class AddOperationScreen extends StatefulWidget {
  const AddOperationScreen({super.key});

  @override
  State<AddOperationScreen> createState() => _AddOperationScreenState();
}

class _AddOperationScreenState extends State<AddOperationScreen> {
  // Contrôleurs de formulaire
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  // État du formulaire
  OperationType _selectedType = OperationType.depotUv;
  Client? _selectedClient;
  bool _isPaid = true;
  bool _isLoading = false;
  bool _isLoadingClients = true;

  // Liste des clients disponibles
  List<Client> _clients = [];

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// Charge la liste des clients depuis PocketBase
  Future<void> _loadClients() async {
    try {
      final clients = await DatabaseService.instance.getClients();
      if (mounted) {
        setState(() {
          _clients = clients;
          _isLoadingClients = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingClients = false);
      }
    }
  }


  /// Enregistre l'opération
  Future<void> _saveOperation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text.replaceAll(' ', ''));
      final userId = AuthService.instance.currentUser?.id ?? '';

      // Pour les approvisionnements: pas de client, toujours payé
      final isAppro = _selectedType.isApprovisionnement;
      
      final operation = Operation(
        id: '', // Sera généré par PocketBase
        clientId: isAppro ? null : _selectedClient?.id,
        type: _selectedType,
        amount: amount,
        isPaid: isAppro ? true : _isPaid,
        userId: userId,
        createdAt: DateTime.now(),
      );

      // Créer l'opération dans PocketBase
      await DatabaseService.instance.createOperation(operation);

      // Si c'est une dette (pas un approvisionnement), mettre à jour la dette du client
      if (!isAppro && !_isPaid && _selectedClient != null) {
        final newDebt = _selectedClient!.totalDebt + amount;
        await DatabaseService.instance.updateClientDebt(
          _selectedClient!.id,
          newDebt,
        );

        // Vérifier le seuil de dette et notifier si nécessaire (Requirement 6.2)
        final updatedClient = _selectedClient!.copyWith(totalDebt: newDebt);
        await NotificationService.instance.checkDebtThreshold(updatedClient);
      }

      // Notification de confirmation (Requirement 6.1)
      await NotificationService.instance.showOperationConfirmation(
        operationType: _selectedType.label,
        amount: amount,
        clientName: isAppro ? null : _selectedClient?.name,
      );

      if (mounted) {
        _showSuccess('Opération enregistrée avec succès');
        Navigator.pop(context, true); // Retourne true pour indiquer un succès
      }
    } on DatabaseException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.userMessage);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Erreur lors de l\'enregistrement');
      }
    }
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

  /// Valide le montant
  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un montant';
    }
    final cleanValue = value.replaceAll(' ', '');
    final amount = double.tryParse(cleanValue);
    if (amount == null) {
      return 'Montant invalide';
    }
    if (amount <= 0) {
      return 'Le montant doit être supérieur à 0';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaveColors.greyLight,
      appBar: AppBar(
        title: const Text('Nouvelle opération'),
        backgroundColor: WaveColors.primary,
        foregroundColor: WaveColors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type d'opération (Requirement 3.1)
              _buildTypeDropdown(),
              const SizedBox(height: 20),

              // Montant (Requirement 3.2)
              _buildAmountField(),
              const SizedBox(height: 20),

              // Client optionnel - masqué pour les approvisionnements
              if (!_selectedType.isApprovisionnement) ...[
                _buildClientDropdown(),
                const SizedBox(height: 20),

                // Checkbox payé/dette (Requirement 3.4)
                _buildPaidCheckbox(),
                const SizedBox(height: 32),
              ] else ...[
                // Info pour les approvisionnements
                _buildApprovisionnementInfo(),
                const SizedBox(height: 32),
              ],

              // Bouton enregistrer (Requirement 3.5, 6.1)
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }


  /// Dropdown pour le type d'opération (Requirement 3.1)
  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type d\'opération',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: WaveColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
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
          child: DropdownButtonFormField<OperationType>(
            initialValue: _selectedType,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
            ),
            items: OperationType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Row(
                  children: [
                    Icon(
                      _getTypeIcon(type),
                      color: WaveColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(type.label),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedType = value);
              }
            },
          ),
        ),
      ],
    );
  }

  /// Icône pour chaque type d'opération
  IconData _getTypeIcon(OperationType type) {
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

  /// Champ montant avec validation (Requirement 3.2)
  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Montant (FCFA)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: WaveColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
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
          child: TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              hintText: '0',
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
              suffixText: 'FCFA',
            ),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            validator: _validateAmount,
          ),
        ),
      ],
    );
  }

  /// Dropdown pour sélectionner un client (Requirement 3.3)
  Widget _buildClientDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Client (optionnel)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: WaveColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
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
          child: _isLoadingClients
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : DropdownButtonFormField<Client?>(
                  initialValue: _selectedClient,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                    hintText: 'Sélectionner un client...',
                  ),
                  items: [
                    const DropdownMenuItem<Client?>(
                      value: null,
                      child: Text('Aucun client'),
                    ),
                    ..._clients.map((client) {
                      return DropdownMenuItem(
                        value: client,
                        child: Text(
                          client.totalDebt > 0
                              ? '${client.name} (${client.totalDebt.toStringAsFixed(0)} FCFA)'
                              : client.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedClient = value);
                  },
                ),
        ),
      ],
    );
  }


  /// Checkbox "Opération payée" (Requirement 3.4)
  Widget _buildPaidCheckbox() {
    return Container(
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
      child: CheckboxListTile(
        value: _isPaid,
        onChanged: (value) {
          setState(() => _isPaid = value ?? true);
        },
        title: const Text('Opération payée'),
        subtitle: Text(
          _isPaid
              ? 'Le client a payé immédiatement'
              : 'Cette opération sera ajoutée comme dette',
          style: TextStyle(
            fontSize: 12,
            color: _isPaid ? WaveColors.success : WaveColors.warning,
          ),
        ),
        activeColor: WaveColors.primary,
        controlAffinity: ListTileControlAffinity.leading,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Info pour les approvisionnements
  Widget _buildApprovisionnementInfo() {
    final isUv = _selectedType == OperationType.approvisionnementUv;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WaveColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WaveColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isUv ? Icons.add_card : Icons.account_balance_wallet,
            color: WaveColors.primary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUv ? 'Approvisionnement UV' : 'Approvisionnement Espèces',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  isUv
                      ? 'Augmente votre solde UV disponible'
                      : 'Augmente votre solde espèces disponible',
                  style: const TextStyle(fontSize: 12, color: WaveColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bouton enregistrer avec feedback (Requirement 3.5, 6.1)
  Widget _buildSaveButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveOperation,
        style: ElevatedButton.styleFrom(
          backgroundColor: WaveColors.primary,
          foregroundColor: WaveColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: WaveColors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Enregistrer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
