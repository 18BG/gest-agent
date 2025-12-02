import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'operations_screen.dart';
import 'clients_screen.dart';
import 'settings_screen.dart';

/// Écran principal avec navigation BottomNav réelle
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Liste des écrans (lazy loading avec IndexedStack)
  final List<Widget> _screens = const [
    HomeTab(),
    OperationsScreen(),
    ClientsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: WaveColors.primary,
        unselectedItemColor: WaveColors.greyDark,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Opérations'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clients'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Paramètres'),
        ],
      ),
    );
  }
}
