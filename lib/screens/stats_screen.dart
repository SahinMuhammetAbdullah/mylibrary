import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_library/models/models.dart' as app_models;
import 'package:my_library/services/book_service.dart';
import 'package:my_library/helpers/data_notifier.dart'; 

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  late Future<app_models.StatsData> _statsFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStats();
    // Global veri değişikliği bildirimini dinlemeye başla.
    dataChangeNotifier.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Bellek sızıntılarını önlemek için dinleyiciyi kaldır.
    dataChangeNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  // Bildirim geldiğinde bu metot çalışır.
  void _onDataChanged() {
    if (mounted) {
      // İstatistikleri yeniden yükleyerek ekranı güncelle.
      _loadStats();
    }
  }
  
  // İstatistikleri yükleme işlemini ayrı bir metoda taşıdık.
  void _loadStats() {
    if(mounted) {
      setState(() {
        _statsFuture = context.read<BookService>().getStats();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("İstatistiklerim"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Bugün"),
            Tab(text: "Bu Hafta"),
            Tab(text: "Bu Ay"),
            Tab(text: "Bu Yıl"),
          ],
        ),
      ),
      body: FutureBuilder<app_models.StatsData>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("İstatistikler yüklenemedi: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Veri bulunamadı."));
          }

          final stats = snapshot.data!;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StatCard(number: stats.totalBooks, label: 'Toplam Kitap'),
                    _StatCard(number: stats.booksRead, label: 'Okunan Kitap'),
                    _StatCard(number: stats.pagesRead, label: 'Okunan Sayfa'),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStatsDetail("Bugün Okunan Kitap", stats.booksReadByPeriod['daily'] ?? 0),
                    _buildStatsDetail("Bu Hafta Okunan Kitap", stats.booksReadByPeriod['weekly'] ?? 0),
                    _buildStatsDetail("Bu Ay Okunan Kitap", stats.booksReadByPeriod['monthly'] ?? 0),
                    _buildStatsDetail("Bu Yıl Okunan Kitap", stats.booksReadByPeriod['yearly'] ?? 0),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsDetail(String title, int count) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Text(count.toString(), style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final int number;
  final String label;
  const _StatCard({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.dividerColor)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(number.toString(), style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(label, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
