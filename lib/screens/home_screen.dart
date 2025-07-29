import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_library/services/book_service.dart';
import 'package:my_library/widgets/book_card.dart';
import 'package:my_library/screens/search_screen.dart';
import 'package:my_library/screens/book_detail_screen.dart';
import 'package:my_library/helpers/data_notifier.dart'; 
import 'package:my_library/models/models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Arama durumu için state değişkenleri
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    dataChangeNotifier.addListener(_onDataChanged);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    dataChangeNotifier.removeListener(_onDataChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      context.read<BookService>().loadLibraryBooks();
    }
  }

  // Arama modunu açıp kapatan metotlar
  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  // Arama çubuğunu oluşturan yardımcı metot
  AppBar _buildSearchAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _stopSearch,
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Kütüphanede ara...',
          border: InputBorder.none,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (_searchController.text.isEmpty) {
              _stopSearch();
            } else {
              _searchController.clear();
            }
          },
        )
      ],
    );
  }

  // Normal AppBar'ı oluşturan yardımcı metot
  AppBar _buildNormalAppBar() {
    return AppBar(
      title: const Text('Kitaplığım'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _startSearch,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookService = context.watch<BookService>();
    
    // Arama sorgusuna göre kitap listesini filtrele
    final List<Book> allBooks = bookService.libraryBooks;
    final List<Book> filteredBooks = _searchQuery.isEmpty
        ? allBooks
        : allBooks.where((book) {
            final titleLower = book.name?.toLowerCase() ?? '';
            final authorLower = book.authorString.toLowerCase();
            final searchLower = _searchQuery.toLowerCase();
            return titleLower.contains(searchLower) || authorLower.contains(searchLower);
          }).toList();

    return Scaffold(
      // Arama durumuna göre AppBar'ı değiştir
      appBar: _isSearching ? _buildSearchAppBar() : _buildNormalAppBar(),
      body: bookService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredBooks.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      allBooks.isEmpty
                          ? 'Kitaplığınızda henüz kitap yok.\nArama yaparak eklemeye başlayın!'
                          : 'Aramanızla eşleşen kitap bulunamadı.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: filteredBooks.length,
                  itemBuilder: (context, index) {
                    final book = filteredBooks[index];
                    return BookCard(
                      book: book,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => BookDetailScreen(bookId: book.id)));
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen())),
        tooltip: 'Yeni Kitap Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }
}
