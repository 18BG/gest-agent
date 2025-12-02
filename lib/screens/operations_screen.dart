import 'package:flutter/material.dart';
import '../models/operation.dart';
import '../models/client.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../widgets/operation_tile.dart';
import 'edit_operation_screen.dart';

export '../services/database_service.dart' show DatabaseException;

/// Écran liste des opérations avec filtres
class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key});

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  List<Operation> _allOperations = [];
  List<Operation> _filteredOperations = [];
  List<Client> _clients = [];
  bool _isLoading = true;

  // Filtres
  OperationType? _selectedType;
  Client? _selectedClient;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final operations = await DatabaseService.instance.getOperations(limit: 200);
      final clients = await DatabaseService.instance.getClients();
      if (mounted) {
        setState(() {
          _allOperations = operations;
          _filteredOperations = operations;
          _clients = clients;
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

  void _applyFilters() {
    setState(() {
      _filteredOperations = _allOperations.where((op) {
        // Filtre par type
        if (_selectedType != null && op.type != _selectedType) return false;
        // Filtre par client
        if (_selectedClient != null && op.clientId != _selectedClient!.id) return false;
        // Filtre par date
        if (_dateRange != null) {
          if (op.createdAt.isBefore(_dateRange!.start) || 
              op.createdAt.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
            return false;
          }
        }
        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _selectedClient = null;
      _dateRange = null;
      _filteredOperations = _allOperations;
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: WaveColors.error));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: WaveColors.success));
  }

  Future<void> _editOperation(Operation op) async {
    final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => EditOperationScreen(operation: op)));
    if (result == true) _loadData();
  }

  Future<void> _deleteOperation(Operation op) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('${op.type.label} - ${op.amount.toStringAsFixed(0)} FCFA'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: WaveColors.error), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await DatabaseService.instance.deleteOperation(op.id);
      _showSuccess('Supprimé');
      _loadData();
    } catch (e) {
      _showError('Erreur');
    }
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      locale: const Locale('fr', 'FR'),
    );
    if (range != null) {
      _dateRange = range;
      _applyFilters();
    }
  }


  bool get _hasFilters => _selectedType != null || _selectedClient != null || _dateRange != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaveColors.greyLight,
      appBar: AppBar(
        title: const Text('Opérations'),
        backgroundColor: WaveColors.primary,
        foregroundColor: WaveColors.white,
        elevation: 0,
        actions: [
          if (_hasFilters)
            IconButton(icon: const Icon(Icons.clear), onPressed: _clearFilters, tooltip: 'Effacer filtres'),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterSheet, tooltip: 'Filtrer'),
        ],
      ),
      body: _isLoading ? _buildLoading() : _buildBody(),
    );
  }

  Widget _buildLoading() => const Center(child: CircularProgressIndicator(color: WaveColors.primary));

  Widget _buildBody() {
    return Column(
      children: [
        // Chips des filtres actifs
        if (_hasFilters) _buildActiveFilters(),
        // Liste
        Expanded(
          child: _filteredOperations.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredOperations.length,
                    itemBuilder: (ctx, i) {
                      final op = _filteredOperations[i];
                      return OperationTile(operation: op, onEdit: () => _editOperation(op), onDelete: () => _deleteOperation(op));
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: WaveColors.white,
      child: Wrap(
        spacing: 8,
        children: [
          if (_selectedType != null)
            Chip(
              label: Text(_selectedType!.label),
              onDeleted: () { _selectedType = null; _applyFilters(); },
              backgroundColor: WaveColors.primary.withValues(alpha: 0.1),
            ),
          if (_selectedClient != null)
            Chip(
              label: Text(_selectedClient!.name),
              onDeleted: () { _selectedClient = null; _applyFilters(); },
              backgroundColor: WaveColors.primary.withValues(alpha: 0.1),
            ),
          if (_dateRange != null)
            Chip(
              label: Text('${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}'),
              onDeleted: () { _dateRange = null; _applyFilters(); },
              backgroundColor: WaveColors.primary.withValues(alpha: 0.1),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 64, color: WaveColors.grey),
          const SizedBox(height: 16),
          Text(_hasFilters ? 'Aucun résultat' : 'Aucune opération', style: const TextStyle(fontSize: 18, color: WaveColors.textSecondary)),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtrer les opérations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            // Type
            const Text('Type', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<OperationType?>(
              value: _selectedType,
              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tous les types')),
                ...OperationType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))),
              ],
              onChanged: (v) { _selectedType = v; _applyFilters(); Navigator.pop(ctx); },
            ),
            const SizedBox(height: 16),
            // Client
            const Text('Client', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<Client?>(
              value: _selectedClient,
              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tous les clients')),
                ..._clients.map((c) => DropdownMenuItem(value: c, child: Text(c.name))),
              ],
              onChanged: (v) { _selectedClient = v; _applyFilters(); Navigator.pop(ctx); },
            ),
            const SizedBox(height: 16),
            // Date
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () { Navigator.pop(ctx); _selectDateRange(); },
                icon: const Icon(Icons.date_range),
                label: Text(_dateRange != null ? 'Modifier la période' : 'Filtrer par date'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
