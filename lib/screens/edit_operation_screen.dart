import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/operation.dart';
import '../models/client.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

/// Écran de modification d'une opération existante
class EditOperationScreen extends StatefulWidget {
  final Operation operation;

  const EditOperationScreen({super.key, required this.operation});

  @override
  State<EditOperationScreen> createState() => _EditOperationScreenState();
}

class _EditOperationScreenState extends State<EditOperationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  late OperationType _selectedType;
  Client? _selectedClient;
  late bool _isPaid;
  bool _isLoading = false;
  bool _isLoadingClients = true;
  List<Client> _clients = [];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.operation.type;
    _isPaid = widget.operation.isPaid;
    _amountController.text = widget.operation.amount.toStringAsFixed(0);
    _loadClients();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    try {
      final clients = await DatabaseService.instance.getClients();
      if (mounted) {
        setState(() {
          _clients = clients;
          _isLoadingClients = false;
          // Trouver le client associé à l'opération
          if (widget.operation.clientId != null) {
            _selectedClient = clients.where((c) => c.id == widget.operation.clientId).firstOrNull;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingClients = false);
    }
  }


  Future<void> _saveOperation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text.replaceAll(' ', ''));

      final updatedOperation = widget.operation.copyWith(
        type: _selectedType,
        amount: amount,
        isPaid: _isPaid,
        clientId: _selectedClient?.id,
      );

      await DatabaseService.instance.updateOperation(updatedOperation);

      if (mounted) {
        _showSuccess('Opération modifiée');
        Navigator.pop(context, true);
      }
    } on DatabaseException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.userMessage);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Erreur lors de la modification');
      }
    }
  }

  Future<void> _deleteOperation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'opération ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: WaveColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await DatabaseService.instance.deleteOperation(widget.operation.id);

      if (mounted) {
        _showSuccess('Opération supprimée');
        Navigator.pop(context, true);
      }
    } on DatabaseException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.userMessage);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Erreur lors de la suppression');
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: WaveColors.success),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: WaveColors.error),
    );
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) return 'Veuillez entrer un montant';
    final amount = double.tryParse(value.replaceAll(' ', ''));
    if (amount == null || amount <= 0) return 'Montant invalide';
    return null;
  }

  IconData _getTypeIcon(OperationType type) {
    switch (type) {
      case OperationType.depotUv: return Icons.arrow_downward;
      case OperationType.retraitUv: return Icons.arrow_upward;
      case OperationType.transfert: return Icons.swap_horiz;
      case OperationType.venteCredit: return Icons.phone_android;
      case OperationType.approvisionnementUv: return Icons.add_card;
      case OperationType.approvisionnementEspece: return Icons.account_balance_wallet;
      case OperationType.paiementClient: return Icons.payments;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaveColors.greyLight,
      appBar: AppBar(
        title: const Text('Modifier l\'opération'),
        backgroundColor: WaveColors.primary,
        foregroundColor: WaveColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isLoading ? null : _deleteOperation,
            tooltip: 'Supprimer',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTypeDropdown(),
              const SizedBox(height: 20),
              _buildAmountField(),
              const SizedBox(height: 20),
              // Masquer client et payé pour les approvisionnements
              if (!_selectedType.isApprovisionnement) ...[
                _buildClientDropdown(),
                const SizedBox(height: 20),
                _buildPaidCheckbox(),
                const SizedBox(height: 32),
              ] else
                const SizedBox(height: 12),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Type d\'opération', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: WaveColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: WaveColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: DropdownButtonFormField<OperationType>(
            value: _selectedType,
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), border: InputBorder.none),
            items: OperationType.values.map((type) => DropdownMenuItem(
              value: type,
              child: Row(children: [Icon(_getTypeIcon(type), color: WaveColors.primary, size: 20), const SizedBox(width: 12), Text(type.label)]),
            )).toList(),
            onChanged: (value) { if (value != null) setState(() => _selectedType = value); },
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Montant (FCFA)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: WaveColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: WaveColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(hintText: '0', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), border: InputBorder.none, suffixText: 'FCFA'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            validator: _validateAmount,
          ),
        ),
      ],
    );
  }

  Widget _buildClientDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Client (optionnel)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: WaveColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: WaveColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: _isLoadingClients
              ? const Padding(padding: EdgeInsets.all(16), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
              : DropdownButtonFormField<Client?>(
                  value: _selectedClient,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), border: InputBorder.none, hintText: 'Sélectionner un client...'),
                  items: [
                    const DropdownMenuItem<Client?>(value: null, child: Text('Aucun client')),
                    ..._clients.map((client) => DropdownMenuItem(value: client, child: Text(client.name, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (value) => setState(() => _selectedClient = value),
                ),
        ),
      ],
    );
  }

  Widget _buildPaidCheckbox() {
    return Container(
      decoration: BoxDecoration(
        color: WaveColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: CheckboxListTile(
        value: _isPaid,
        onChanged: (value) => setState(() => _isPaid = value ?? true),
        title: const Text('Opération payée'),
        subtitle: Text(_isPaid ? 'Le client a payé' : 'Dette', style: TextStyle(fontSize: 12, color: _isPaid ? WaveColors.success : WaveColors.warning)),
        activeColor: WaveColors.primary,
        controlAffinity: ListTileControlAffinity.leading,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveOperation,
        style: ElevatedButton.styleFrom(backgroundColor: WaveColors.primary, foregroundColor: WaveColors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: WaveColors.white, strokeWidth: 2))
            : const Text('Enregistrer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
