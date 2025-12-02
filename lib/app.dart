import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'utils/constants.dart';

/// Main application widget - Simple MaterialApp
class WaveAgentApp extends StatefulWidget {
  const WaveAgentApp({super.key});

  @override
  State<WaveAgentApp> createState() => _WaveAgentAppState();
}

class _WaveAgentAppState extends State<WaveAgentApp> {
  bool _isInitialized = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialiser PocketBase avec l'URL depuis les constantes
    await DatabaseService.instance.init(AppConstants.pocketbaseUrl);

    // Vérifier si une session existe
    final hasSession = await AuthService.instance.checkSession();

    setState(() {
      _isInitialized = true;
      _isLoggedIn = hasSession;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wave Agent',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: _buildHome(),
    );
  }

  /// Construit le thème simple de l'application
  /// Design sobre: bleu Wave #00A8E8, gris, blanc
  ThemeData _buildTheme() {
    return ThemeData(
      // Utiliser Material 3
      useMaterial3: true,
      
      // Color scheme basé sur les couleurs Wave
      colorScheme: ColorScheme.light(
        primary: WaveColors.primary,
        onPrimary: WaveColors.white,
        secondary: WaveColors.primaryDark,
        onSecondary: WaveColors.white,
        surface: WaveColors.white,
        onSurface: WaveColors.textPrimary,
        error: WaveColors.error,
        onError: WaveColors.white,
      ),
      
      // Fond blanc propre
      scaffoldBackgroundColor: WaveColors.white,
      
      // AppBar simple - bleu Wave avec texte blanc
      appBarTheme: const AppBarTheme(
        backgroundColor: WaveColors.primary,
        foregroundColor: WaveColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      
      // Boutons élevés - bleu Wave
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WaveColors.primary,
          foregroundColor: WaveColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Boutons texte - bleu Wave
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: WaveColors.primary,
        ),
      ),
      
      // FAB - bleu Wave
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: WaveColors.primary,
        foregroundColor: WaveColors.white,
      ),
      
      // Cards simples - fond blanc, ombre subtile
      cardTheme: CardThemeData(
        color: WaveColors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      // Champs de saisie - bordure grise, focus bleu Wave
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WaveColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: WaveColors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: WaveColors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: WaveColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: WaveColors.error),
        ),
        labelStyle: const TextStyle(color: WaveColors.textSecondary),
      ),
      
      // Dividers - gris clair
      dividerTheme: const DividerThemeData(
        color: WaveColors.greyLight,
        thickness: 1,
      ),
      
      // Bottom navigation - sobre
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: WaveColors.white,
        selectedItemColor: WaveColors.primary,
        unselectedItemColor: WaveColors.greyDark,
        elevation: 8,
      ),
      
      // SnackBar - sobre
      snackBarTheme: SnackBarThemeData(
        backgroundColor: WaveColors.textPrimary,
        contentTextStyle: const TextStyle(color: WaveColors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // ListTile - sobre
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildHome() {
    if (!_isInitialized) {
      // Écran de chargement pendant l'initialisation
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: WaveColors.primary,
          ),
        ),
      );
    }

    // Afficher LoginScreen ou HomeScreen selon l'état de connexion
    return _isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}
