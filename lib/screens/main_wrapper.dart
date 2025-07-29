import 'package:flutter/material.dart';
import 'package:my_library/screens/all_notes_screen.dart';
import 'package:my_library/screens/home_screen.dart';
import 'package:my_library/screens/stats_screen.dart';
import 'package:my_library/services/connectivity_service.dart';


class MainWrapper extends StatefulWidget {
  final Function(ThemeMode) changeTheme;
  const MainWrapper({super.key, required this.changeTheme});
  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // YENİ: İnternet dinleme servisini başlat
    ConnectivityService.instance.initialize();
    _pages = <Widget>[
      const HomeScreen(),
      const AllNotesScreen(),
      const StatsScreen(),
    ];
  }

  @override
  void dispose() {
    // YENİ: Servisi temizle
    ConnectivityService.instance.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() { _selectedIndex = index; });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // YENİ: İnternet durumunu dinleyen ve banner gösteren widget
          ValueListenableBuilder<bool>(
            valueListenable: ConnectivityService.instance.isConnected,
            builder: (context, isConnected, child) {
              // Eğer bağlı değilse, bir banner göster.
              if (!isConnected) {
                return Material(
                  child: Container(
                    width: double.infinity,
                    color: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: const Text(
                      'İnternet bağlantısı yok',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }
              // Bağlıysa, hiçbir şey gösterme.
              return const SizedBox.shrink();
            },
          ),
          // Uygulamanın geri kalanı
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: _pages),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Kitaplık'),
          BottomNavigationBarItem(
              icon: Icon(Icons.note_alt_outlined),
              activeIcon: Icon(Icons.note_alt),
              label: 'Notlar'),
          BottomNavigationBarItem(
            icon: Icon(Icons.query_stats_outlined),
            activeIcon: Icon(Icons.query_stats),
            label: 'Okumalar',
          ),
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
