import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import 'welcome_screen.dart';

/// Écran d'inscription en 3 étapes
/// Step 1: Nom, Prénom, Téléphone
/// Step 2: Créer PIN (5 chiffres)
/// Step 3: Confirmer PIN
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final PageController _pageController = PageController();
  
  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  
  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Valider step 1
      if (_firstNameController.text.trim().isEmpty ||
          _lastNameController.text.trim().isEmpty ||
          _phoneController.text.replaceAll(' ', '').length <8) {
        _showError('Veuillez remplir tous les champs correctement');
        return;
      }
    } else if (_currentStep == 1) {
      // Valider step 2
      if (_pinController.text.length != 5) {
        _showError('Le code PIN doit contenir 5 chiffres');
        return;
      }
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _register() async {
    // Valider confirmation PIN
    if (_confirmPinController.text != _pinController.text) {
      _showError('Les codes PIN ne correspondent pas');
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.instance.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      pin: _pinController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      // Naviguer vers la page de bienvenue
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WelcomeScreen(
            firstName: _firstNameController.text.trim(),
          ),
        ),
      );
    } else {
      _showError(result.userMessage);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: WaveColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WaveColors.textPrimary),
          onPressed: _previousStep,
        ),
        title: Text(
          'Étape ${_currentStep + 1}/3',
          style: const TextStyle(
            color: WaveColors.textSecondary,
            fontSize: 14,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),
            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index <= _currentStep
                    ? WaveColors.primary
                    : WaveColors.greyLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Step 1: Informations personnelles
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.person_add_outlined,
            size: 64,
            color: WaveColors.primary,
          ),
          const SizedBox(height: 24),
          const Text(
            'Créer votre compte',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: WaveColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Entrez vos informations personnelles',
            style: TextStyle(
              fontSize: 14,
              color: WaveColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Prénom
          TextFormField(
            controller: _firstNameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              label: 'Prénom',
              hint: 'Mamadou',
              icon: Icons.person_outline,
            ),
          ),
          const SizedBox(height: 16),
          
          // Nom
          TextFormField(
            controller: _lastNameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              label: 'Nom',
              hint: 'Diallo',
              icon: Icons.person_outline,
            ),
          ),
          const SizedBox(height: 16),
          
          // Téléphone
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9\s]')),
            ],
            decoration: _inputDecoration(
              label: 'Numéro de téléphone',
              hint: '77 123 45 67',
              icon: Icons.phone_outlined,
            ),
          ),
          const SizedBox(height: 32),
          
          _buildNextButton('Continuer'),
        ],
      ),
    );
  }

  /// Step 2: Créer PIN
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.lock_outline,
            size: 64,
            color: WaveColors.primary,
          ),
          const SizedBox(height: 24),
          const Text(
            'Créez votre code PIN',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: WaveColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Choisissez un code à 5 chiffres\nque vous n\'oublierez pas',
            style: TextStyle(
              fontSize: 14,
              color: WaveColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          
          // PIN input
          TextFormField(
            controller: _pinController,
            obscureText: _obscurePin,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 5,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 16,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            decoration: InputDecoration(
              counterText: '',
              hintText: '•••••',
              hintStyle: TextStyle(
                fontSize: 32,
                letterSpacing: 16,
                color: Colors.grey.shade300,
              ),
              suffixIcon: IconButton(
                icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 32),
          
          _buildNextButton('Continuer'),
        ],
      ),
    );
  }

  /// Step 3: Confirmer PIN
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.verified_user_outlined,
            size: 64,
            color: WaveColors.primary,
          ),
          const SizedBox(height: 24),
          const Text(
            'Confirmez votre code PIN',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: WaveColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Retapez votre code pour confirmer',
            style: TextStyle(
              fontSize: 14,
              color: WaveColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          
          // Confirm PIN input
          TextFormField(
            controller: _confirmPinController,
            obscureText: _obscureConfirmPin,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 5,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 16,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            onFieldSubmitted: (_) => _register(),
            decoration: InputDecoration(
              counterText: '',
              hintText: '•••••',
              hintStyle: TextStyle(
                fontSize: 32,
                letterSpacing: 16,
                color: Colors.grey.shade300,
              ),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPin ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 32),
          
          _buildCreateAccountButton(),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  Widget _buildNextButton(String text) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: WaveColors.primary,
          foregroundColor: WaveColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildCreateAccountButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
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
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(WaveColors.white),
                ),
              )
            : const Text(
                'Créer mon compte',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
