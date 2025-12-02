import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/client.dart';
import '../utils/constants.dart';
import '../widgets/client_tile.dart';
import 'add_client_screen.dart';
import 'client_detail_screen.dart';

// Import pour DatabaseException
export '../services/database_service.dart' show DatabaseException;

/// Écran liste des clients - triés par dette décroissante
/// Requirements: 4.2
class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  // État
  List<Client> _allClients = [];
  List<Client> _filteredClients = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Charge les clients depuis PocketBase
  /// Applique le tri par dette décroissante (Requirement 4.2 - 13.3)
  Future<void> _loadClients() async {
    setState(() => _isLoading = true);

    try {
      final clients = await DatabaseService.instance.getClients();
      if (mounted) {
        // Tri explicite par dette décroissante (13.3)
        final sortedClients = _sortByDebtDescending(clients);
        setState(() {
          _allClients = sortedClients;
          _filteredClients = sortedClients;
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
        _showError('Erreur de chargement des clients');
      }
    }
  }


  /// Filtre les clients par nom ou téléphone (Requirement 4.2 - barre de recherche)
  /// Maintient le tri par dette décroissante après filtrage (Requirement 4.2 - 13.3)
  void _filterClients(String query) {
    if (query.isEmpty) {
      setState(() => _filteredClients = _sortByDebtDescending(_allClients));
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      final filtered = _allClients.where((client) {
        return client.name.toLowerCase().contains(lowerQuery) ||
            client.phone.contains(query);
      }).toList();
      _filteredClients = _sortByDebtDescending(filtered);
    });
  }

  /// Trie les clients par dette décroissante (plus grande dette en premier)
  /// Requirement 4.2 - 13.3
  List<Client> _sortByDebtDescending(List<Client> clients) {
    final sorted = List<Client>.from(clients);
    sorted.sort((a, b) => b.totalDebt.compareTo(a.totalDebt));
    return sorted;
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

  /// Navigation vers l'écran d'ajout de client (Requirement 4.1)
  void _navigateToAddClient() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddClientScreen()),
    );
    
    // Recharger la liste si un client a été ajouté
    if (result == true) {
      _loadClients();
    }
  }

  /// Navigation vers le détail d'un client (Requirement 4.3)
  void _navigateToClientDetail(Client client) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientDetailScreen(client: client),
      ),
    );
    // Recharger la liste au retour (la dette peut avoir changé)
    _loadClients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaveColors.greyLight,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Clients'),
      backgroundColor: WaveColors.primary,
      foregroundColor: WaveColors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadClients,
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
      onRefresh: _loadClients,
      color: WaveColors.primary,
      child: Column(
        children: [
          // Barre de recherche (Requirement 4.2 - 13.2)
          _buildSearchBar(),
          // Liste des clients
          Expanded(
            child: _filteredClients.isEmpty
                ? _buildEmptyState()
                : _buildClientsList(),
          ),
        ],
      ),
    );
  }

  /// Barre de recherche simple (13.2)
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: WaveColors.white,
      child: TextField(
        controller: _searchController,
        onChanged: _filterClients,
        decoration: InputDecoration(
          hintText: 'Rechercher un client...',
          prefixIcon: const Icon(Icons.search, color: WaveColors.greyDark),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: WaveColors.greyDark),
                  onPressed: () {
                    _searchController.clear();
                    _filterClients('');
                  },
                )
              : null,
          filled: true,
          fillColor: WaveColors.greyLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  /// État vide - aucun client
  Widget _buildEmptyState() {
    final isSearching = _searchController.text.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.people_outline,
            size: 64,
            color: WaveColors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'Aucun client trouvé' : 'Aucun client',
            style: const TextStyle(
              fontSize: 16,
              color: WaveColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Essayez une autre recherche'
                : 'Ajoutez votre premier client',
            style: const TextStyle(
              fontSize: 14,
              color: WaveColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Liste des clients triée par dette décroissante (13.3)
  Widget _buildClientsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredClients.length,
      itemBuilder: (context, index) {
        final client = _filteredClients[index];
        return ClientTile(
          client: client,
          onTap: () => _navigateToClientDetail(client),
        );
      },
    );
  }

  /// FAB pour ajouter un client (13.4)
  Widget _buildFAB() {
    return FloatingActionButton(
      heroTag: 'clients_fab',
      onPressed: _navigateToAddClient,
      backgroundColor: WaveColors.primary,
      foregroundColor: WaveColors.white,
      child: const Icon(Icons.add),
    );
  }
}
