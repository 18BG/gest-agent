import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/client.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

// Import pour DatabaseException
export '../services/database_service.dart' show DatabaseException;

/// Écran d'ajout de client
/// Requirements: 4.1
class AddClientScreen extends StatefulWidget {
  const AddClientScreen({super.key});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  // Contrôleurs de formulaire
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // État
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Enregistre le client (Requirement 4.1)
  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = AuthService.instance.currentUser?.id ?? '';

      final client = Client(
        id: '', // Sera généré par PocketBase
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        totalDebt: 0.0, // Nouveau client sans dette
        userId: userId,
        createdAt: DateTime.now(),
      );

      // Créer le client dans PocketBase
      await DatabaseService.instance.createClient(client);

      if (mounted) {
        _showSuccess('Client ajouté avec succès');
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

  /// Valide le nom (Requirement 4.1)
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer le nom du client';
    }
    if (value.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    return null;
  }

  /// Valide le numéro de téléphone (Requirement 4.1)
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer le numéro de téléphone';
    }
    // Format sénégalais: 7X XXX XX XX (9 chiffres)
    final cleanPhone = value.replaceAll(RegExp(r'\s+'), '');
    if (cleanPhone.length < 8) {
      return 'Numéro de téléphone invalide (8 chiffres minimum)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaveColors.greyLight,
      appBar: AppBar(
        title: const Text('Nouveau client'),
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
              // Champ nom (Requirement 4.1)
              _buildNameField(),
              const SizedBox(height: 20),

              // Champ téléphone (Requirement 4.1)
              _buildPhoneField(),
              const SizedBox(height: 32),

              // Bouton enregistrer
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Champ nom du client (Requirement 4.1)
  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nom du client',
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
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Ex: Mamadou Diop',
              prefixIcon: Icon(Icons.person_outline),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
            ),
            validator: _validateName,
          ),
        ),
      ],
    );
  }

  /// Champ téléphone du client (Requirement 4.1)
  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Numéro de téléphone',
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
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d\s]')),
            ],
            decoration: const InputDecoration(
              hintText: 'Ex: 77 123 45 67',
              prefixIcon: Icon(Icons.phone_outlined),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
            ),
            validator: _validatePhone,
          ),
        ),
      ],
    );
  }

  /// Bouton enregistrer
  Widget _buildSaveButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveClient,
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
