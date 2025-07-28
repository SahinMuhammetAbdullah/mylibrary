import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <<< HATA İÇİN EKLENEN IMPORT
import 'package:provider/provider.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import '../services/book_service.dart';
import '../services/open_library_service.dart';
import 'book_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _apiService = OpenLibraryService();
  List<ApiBookSearchResult> _searchResults = [];
  bool _isLoading = false;
  String _message = 'Aramak için kitap veya yazar adı girin.';
  Timer? _debounce;
  final Set<String> _addingKeys = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (_searchController.text.length >= 3) {
        _performSearch(_searchController.text);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _message = '';
      _searchResults = [];
    });
    try {
      final results = await _apiService.searchBooks(query);
      if (mounted)
        setState(() {
          _searchResults = results;
          if (results.isEmpty)
            _message = 'Aramanızla eşleşen sonuç bulunamadı.';
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _message = 'Bir hata oluştu: ${e.toString()}';
        });
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  Future<void> _scanBarcode() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#D4AF37', // Vurgu rengimiz
          'İptal',
          true,
          ScanMode.BARCODE);
    } on PlatformException {
      // Eğer kullanıcı izin vermezse veya bir platform hatası olursa burası çalışır.
      barcodeScanRes = 'Platform hatası.';
      // İsteğe bağlı olarak kullanıcıya bir mesaj gösterebilirsiniz.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Barkod okuyucu başlatılamadı. Kamera izniniz var mı?')),
        );
      }
    }

    if (!mounted || barcodeScanRes == '-1') {
      return;
    }

    _searchController.text = barcodeScanRes;
    _performSearch(barcodeScanRes);
  }

  Future<void> _addBook(ApiBookSearchResult book) async {
    if (_addingKeys.contains(book.workKey)) return;
    setState(() => _addingKeys.add(book.workKey));
    final bookService = context.read<BookService>();
    final success = await bookService.addBookFromApi(book);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? "'${book.title}' kütüphaneye eklendi!"
              : "'${book.title}' zaten kütüphanede."),
          backgroundColor: success ? Colors.green : Colors.orange,
        ),
      );
      setState(() => _addingKeys.remove(book.workKey));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'Kitap veya yazar ara...', border: InputBorder.none),
          onSubmitted: (query) => _performSearch(query),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanBarcode,
            tooltip: 'Barkod Tara',
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_searchResults.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final book = _searchResults[index];
          final isAdding = _addingKeys.contains(book.workKey);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => BookDetailScreen(apiBook: book)));
              },
              leading: book.coverId != null
                  ? Image.network(
                      'https://covers.openlibrary.org/b/id/${book.coverId}-S.jpg',
                      fit: BoxFit.cover)
                  : Icon(Icons.book_outlined,
                      color: Theme.of(context).colorScheme.secondary),
              title: Text(book.title),
              subtitle: Text(book.authors.join(', ')),
              trailing: isAdding
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: Theme.of(context).colorScheme.primary,
                      tooltip: 'Kütüphaneye Ekle',
                      onPressed: () => _addBook(book),
                    ),
            ),
          );
        },
      );
    }
    return Center(
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall)));
  }
}
