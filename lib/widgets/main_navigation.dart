import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/jugadores/jugadores_list_screen.dart';
import '../screens/sesiones/sesiones_list_screen.dart';
import '../screens/config/categorias_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  void _navigateTo(int index) => setState(() => _index = index);

  late final List<Widget> _screens = [
    DashboardScreen(onNavigate: _navigateTo),
    const JugadoresListScreen(),
    const SesionesListScreen(),
    const CategoriasScreen(),
  ];

  static const _items = [
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
    BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Jugadores'),
    BottomNavigationBarItem(icon: Icon(Icons.sports_basketball_outlined), activeIcon: Icon(Icons.sports_basketball), label: 'Sesiones'),
    BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Config'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _navigateTo,
        items: _items,
      ),
    );
  }
}
