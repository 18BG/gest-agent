import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import 'login_screen.dart';

/// Écran des paramètres
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      backgroundColor: WaveColors.greyLight,
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: WaveColors.primary,
        foregroundColor: WaveColors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info utilisateur
          _buildUserCard(context, user?.name ?? 'Agent', user?.email ?? ''),
          const SizedBox(height: 24),
          
          // Section Compte
          _buildSectionTitle('Compte'),
          _buildMenuItem(
            context,
            icon: Icons.logout,
            title: 'Déconnexion',
            onTap: () => _logout(context),
          ),
          const SizedBox(height: 24),
          
          // Section Données
          _buildSectionTitle('Données'),
          _buildMenuItem(
            context,
            icon: Icons.delete_sweep,
            title: 'Réinitialiser les données',
            subtitle: 'Supprimer toutes les opérations et clients',
            color: WaveColors.warning,
            onTap: () => _resetData(context),
          ),
          _buildMenuItem(
            context,
            icon: Icons.delete_forever,
            title: 'Supprimer mon compte',
            subtitle: 'Action irréversible',
            color: WaveColors.error,
            onTap: () => _deleteAccount(context),
          ),
          const SizedBox(height: 24),
          
          // Section À propos
          _buildSectionTitle('À propos'),
          _buildMenuItem(
            context,
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '1.0.0',
            onTap: null,
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, String name, String email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WaveColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: WaveColors.primary.withValues(alpha: 0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: WaveColors.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(fontSize: 14, color: WaveColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: WaveColors.textSecondary)),
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? color,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: WaveColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: color ?? WaveColors.textPrimary),
        title: Text(title, style: TextStyle(color: color ?? WaveColors.textPrimary)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing: onTap != null ? const Icon(Icons.chevron_right, color: WaveColors.grey) : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }


  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Déconnexion')),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await AuthService.instance.logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _resetData(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser les données ?'),
        content: const Text('Toutes vos opérations et clients seront supprimés.\n\nCette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: WaveColors.error),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        // Supprimer toutes les opérations
        final operations = await DatabaseService.instance.getOperations(limit: 1000);
        for (final op in operations) {
          await DatabaseService.instance.deleteOperation(op.id);
        }
        
        // Supprimer tous les clients
        final clients = await DatabaseService.instance.getClients();
        for (final client in clients) {
          await DatabaseService.instance.deleteClient(client.id);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Données réinitialisées'), backgroundColor: WaveColors.success),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de la réinitialisation'), backgroundColor: WaveColors.error),
          );
        }
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le compte ?'),
        content: const Text('Votre compte et toutes vos données seront définitivement supprimés.\n\nCette action est IRRÉVERSIBLE.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: WaveColors.error),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      // Pour l'instant, juste déconnecter (la suppression de compte nécessite une API côté serveur)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contactez l\'administrateur pour supprimer votre compte'), backgroundColor: WaveColors.warning),
      );
    }
  }
}
