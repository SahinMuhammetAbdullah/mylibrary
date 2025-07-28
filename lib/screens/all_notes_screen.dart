import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:my_library/helpers/data_notifier.dart';
import 'package:my_library/services/book_service.dart';

class AllNotesScreen extends StatefulWidget {
  const AllNotesScreen({super.key});

  @override
  State<AllNotesScreen> createState() => _AllNotesScreenState();
}

class _AllNotesScreenState extends State<AllNotesScreen> {
  late Future<List<Map<String, dynamic>>> _notesFuture;
  bool _sortByDate = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    dataChangeNotifier.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    dataChangeNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      _loadNotes();
    }
  }

  void _loadNotes() {
    final bookService = context.read<BookService>();
    final String orderBy = _sortByDate
        ? 'n.n_createdAt DESC'
        : 'bookTitle ASC, n.n_createdAt DESC';

    setState(() {
      _notesFuture = bookService.getAllNotesWithBookInfo(orderBy: orderBy);
    });
  }

  void _toggleSort() {
    setState(() {
      _sortByDate = !_sortByDate;
      _loadNotes();
    });
  }

  List<dynamic> _groupNotes(List<Map<String, dynamic>> notes) {
    if (notes.isEmpty) return [];
    final List<dynamic> groupedList = [];
    String? lastHeader;
    for (var note in notes) {
      String currentHeader;
      if (_sortByDate) {
        final date = DateTime.parse(note['n_createdAt']);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        if (date.isAfter(today)) {
          currentHeader = "Bugün";
        } else if (date.isAfter(yesterday)) {
          currentHeader = "Dün";
        } else {
          currentHeader = DateFormat('d MMMM yyyy', 'tr_TR').format(date);
        }
      } else {
        currentHeader = note['bookTitle'];
      }
      if (currentHeader != lastHeader) {
        groupedList.add(currentHeader);
        lastHeader = currentHeader;
      }
      groupedList.add(note);
    }
    return groupedList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tüm Notlarım'),
        actions: [
          Tooltip(
            message:
                _sortByDate ? "Kitap Adına Göre Sırala" : "Tarihe Göre Sırala",
            child: IconButton(
                icon: Icon(_sortByDate
                    ? Icons.book_outlined
                    : Icons.calendar_today_outlined),
                onPressed: _toggleSort),
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _notesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text(
                    'Notlar yüklenirken bir hata oluştu:\n${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Henüz hiç not almadınız.'));
          }
          final groupedNotes = _groupNotes(snapshot.data!);
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: groupedNotes.length,
            itemBuilder: (context, index) {
              final item = groupedNotes[index];
              if (item is String) {
                return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(item,
                        style: Theme.of(context).textTheme.titleLarge));
              }

              final note = item as Map<String, dynamic>;
              final noteDate = DateFormat('dd.MM.yyyy', 'tr_TR')
                  .format(DateTime.parse(note['n_createdAt']));

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(note['n_text'],
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(height: 1.4)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment
                            .end, // Çocukları satırın sonuna yasla
                        children: [
                          // Expanded, Text'in mevcut tüm yatay alanı kullanmasını sağlar,
                          // böylece textAlign: TextAlign.right düzgün çalışır.
                          Expanded(
                            child: Text(
                              _sortByDate ? "'${note['bookTitle']}'" : noteDate,
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign
                                  .right, // Metni kutunun içinde sağa yasla
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
