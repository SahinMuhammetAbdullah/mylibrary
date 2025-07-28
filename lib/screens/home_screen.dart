import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_library/services/book_service.dart';
import 'package:my_library/widgets/book_card.dart';
import 'package:my_library/screens/search_screen.dart';
import 'package:my_library/screens/book_detail_screen.dart';
import 'package:my_library/helpers/data_notifier.dart'; 
// StatefulWidget'a dönüştürüyoruz ki initState ve dispose kullanabilelim.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();
    // Global veri değişikliği bildirimini dinlemeye başla.
    dataChangeNotifier.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    // Bellek sızıntılarını önlemek için dinleyiciyi kaldır.
    dataChangeNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  // Bildirim geldiğinde bu metot çalışır.
  void _onDataChanged() {
    if (mounted) {
      // BookService'in kütüphane listesini yeniden yüklemesini tetikle.
      // Bu, provider'ı dinleyen tüm widget'ları (bu ekran dahil) güncelleyecektir.
      context.read<BookService>().loadLibraryBooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 'watch' kullanmak, BookService'deki değişikliklerin (loadLibraryBooks sonrası)
    // bu ekranı otomatik olarak yeniden çizmesini sağlar.
    final bookService = context.watch<BookService>();
    final books = bookService.libraryBooks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitaplığım'),
      ),
      body: bookService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : books.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Kitaplığınızda henüz kitap yok.\nArama yaparak eklemeye başlayın!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return BookCard(
                      book: book,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookDetailScreen(bookId: book.id),
                          ),
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        ),
        tooltip: 'Yeni Kitap Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }
}