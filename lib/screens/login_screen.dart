import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

/// Écran de connexion avec téléphone + PIN
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePin = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await AuthService.instance.login(
      _phoneController.text.trim(),
      _pinController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
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

  void _navigateToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 48),
                  _buildPhoneField(),
                  const SizedBox(height: 16),
                  _buildPinField(),
                  const SizedBox(height: 32),
                  _buildLoginButton(),
                  const SizedBox(height: 24),
                  _buildSignupLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: WaveColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.waves,
            size: 48,
            color: WaveColors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Wave Agent',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: WaveColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Connectez-vous pour continuer',
          style: TextStyle(
            fontSize: 14,
            color: WaveColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9\s]')),
      ],
      decoration: InputDecoration(
        labelText: 'Numéro de téléphone',
        hintText: '77 123 45 67',
        prefixIcon: const Icon(Icons.phone_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Veuillez entrer votre numéro';
        }
        final digits = value.replaceAll(' ', '');
        if (digits.length < 8) {
          return 'Numéro invalide';
        }
        return null;
      },
    );
  }

  Widget _buildPinField() {
    return TextFormField(
      controller: _pinController,
      obscureText: _obscurePin,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      maxLength: 5,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(5),
      ],
      onFieldSubmitted: (_) => _login(),
      decoration: InputDecoration(
        labelText: 'Code PIN',
        hintText: '•••••',
        prefixIcon: const Icon(Icons.lock_outlined),
        counterText: '',
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer votre code PIN';
        }
        if (value.length != 5) {
          return 'Le code PIN doit contenir 5 chiffres';
        }
        return null;
      },
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
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
                'Se connecter',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildSignupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Pas encore de compte ?',
          style: TextStyle(color: WaveColors.textSecondary),
        ),
        TextButton(
          onPressed: _navigateToSignup,
          child: const Text(
            'Créer un compte',
            style: TextStyle(
              color: WaveColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
