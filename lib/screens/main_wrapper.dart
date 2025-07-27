import 'package:flutter/material.dart';
import 'home_screen.dart';

class MainWrapper extends StatefulWidget {
  final Function(ThemeMode) changeTheme;
  const MainWrapper({super.key, required this.changeTheme});
  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  // Placeholder screens for other tabs
  final List<Widget> _pages = [
    const HomeScreen(),
    const Scaffold(body: Center(child: Text("Notlar (Yapım Aşamasında)"))),
    const Scaffold(body: Center(child: Text("Profil (Yapım Aşamasında)"))),
  ];

  void _onItemTapped(int index) {
    setState(() { _selectedIndex = index; });
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Kitaplık'),
          BottomNavigationBarItem(icon: Icon(Icons.note_alt_outlined), activeIcon: Icon(Icons.note_alt), label: 'Notlar'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
