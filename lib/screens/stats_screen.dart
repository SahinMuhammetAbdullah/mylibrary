import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_library/models/models.dart';
import 'package:my_library/services/book_service.dart';
import 'package:my_library/helpers/data_notifier.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late Future<StatsData> _statsFuture;
  late TabController _tabController;

  // Hangi sekmenin hangi periyoda karşılık geldiğini tutan bir liste
  final List<StatsPeriod> _periods = [
    StatsPeriod.today,
    StatsPeriod.week,
    StatsPeriod.month,
    StatsPeriod.year,
    StatsPeriod.allTime,
  ];

  @override
  void initState() {
    super.initState();
    // TabController'ın uzunluğunu 5'e çıkarıyoruz
    _tabController = TabController(length: 5, vsync: this);
    // Sekme değişimlerini dinlemek için bir listener ekliyoruz
    _tabController.addListener(_onTabChanged);
    // Başlangıçta "Tüm Zamanlar" seçili olsun
    _tabController.index = 4;
    _loadStats(StatsPeriod.allTime);
    dataChangeNotifier.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    dataChangeNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      // Mevcut seçili sekmeye göre istatistikleri yeniden yükle
      _loadStats(_periods[_tabController.index]);
    }
  }

  // Sekme değiştiğinde çalışan metot
  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      // Değişen sekmeye göre istatistikleri yükle
      _loadStats(_periods[_tabController.index]);
    }
  }

  void _loadStats(StatsPeriod period) {
    if (mounted) {
      setState(() {
        _statsFuture = context.read<BookService>().getStats(period: period);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("İstatistiklerim"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, // Sekmelerin sığması için kaydırılabilir yap
          tabs: const [
            Tab(text: "Bugün"),
            Tab(text: "Bu Hafta"),
            Tab(text: "Bu Ay"),
            Tab(text: "Bu Yıl"),
            Tab(text: "Tüm Zamanlar"), // Yeni sekme
          ],
        ),
      ),
      body: FutureBuilder<StatsData>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text("İstatistikler yüklenemedi: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Veri bulunamadı."));
          }

          final stats = snapshot.data!;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child:  GridView(
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
              // ALttaki büyük sayılar için TabBarView
              Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Bu Periyotta Okunan Kitap",
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 16),
                          Text(stats.booksRead.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
              ),
            ],
          );
        },
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
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.dividerColor)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(number.toString(),
                style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(label,
                style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
