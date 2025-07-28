import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart' as app_models; // Neredeyse tüm dosyalar için;
import '../services/book_service.dart';
import '../services/open_library_service.dart';

class BookDetailScreen extends StatefulWidget {
  final int? bookId;
  final ApiBookSearchResult? apiBook;

  const BookDetailScreen({super.key, this.bookId, this.apiBook})
      : assert(bookId != null || apiBook != null,
            'Either bookId or apiBook must be provided');

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late Future<void> _loadDataFuture;
  app_models.Book? _book;
  List<app_models.Note> _notes = [];
  bool _isBookInLibrary = false;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDataFuture = _loadData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _showDeleteConfirmationDialog() async {
    // Kitap kütüphanede değilse veya bilgileri henüz yüklenmediyse işlemi iptal et.
    if (!_isBookInLibrary || _book == null) return;

    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // Kullanıcının dışarı tıklayarak kapatmasını engelle
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Kitabı Sil'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    "'${_book!.name ?? 'Bu kitap'}' kütüphaneden kalıcı olarak silinecektir."),
                const SizedBox(height: 8),
                const Text('Bu işlem geri alınamaz. Emin misiniz?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Diyaloğu kapat
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sil'),
              onPressed: () async {
                // Silme işlemini başlat
                await context.read<BookService>().deleteBook(_book!.id);

                // Bu widget'ın hala "mounted" olduğunu kontrol et
                if (!mounted) return;

                Navigator.of(dialogContext).pop(); // Diyaloğu kapat
                Navigator.of(context).pop(); // Detay sayfasını kapat
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadData() async {
    final bookService = context.read<BookService>();
    app_models.Book? loadedBook;
    if (widget.bookId != null) {
      // Mod 1: Kütüphaneden gelen kitap (Sorunsuz Çalışan Kısım)
      loadedBook = await bookService.getBookDetailsById(widget.bookId!);
      if (loadedBook != null) {
        _isBookInLibrary = true;
        final notesResult = await bookService.getNotesForBook(loadedBook.id);
        if (mounted) _notes = notesResult;
      }
    } else if (widget.apiBook != null) {
      // Mod 2: Arama sonucundan gelen kitap
      final apiBookData = widget.apiBook!;
      final existingBook =
          await bookService.findBookInLibraryByWorkId(apiBookData.workKey);
      if (existingBook != null) {
        // Kitap zaten kütüphanede varmış, onun bilgilerini yükle.
        loadedBook = await bookService.getBookDetailsById(existingBook.id);
        if (loadedBook != null) {
          _isBookInLibrary = true;
          final notesResult = await bookService.getNotesForBook(loadedBook.id);
          if (mounted) _notes = notesResult;
        }
      } else {
        // Kitap kütüphanede yok, API'dan tüm detayları çek ve geçici bir nesne oluştur.
        _isBookInLibrary = false;
        final details =
            await OpenLibraryService().getBookDetails(apiBookData.workKey);

        // Geçici Book nesnesini oluştururken tüm alanları ata.
        loadedBook = app_models.Book(
          id: -1,
          name: apiBookData.title,
          oWorkId: apiBookData.workKey,
          authors: apiBookData.authors
              .map((name) => app_models.Author(id: -1, name: name))
              .toList(),
          coverUrl: apiBookData.coverId != null
              ? 'https://covers.openlibrary.org/b/id/${apiBookData.coverId}-M.jpg'
              : null,
          description: details?.description,
          // === HATAYI DÜZELTEN SATIR ===
          totalPages: details?.totalPages,
          // ==============================
          publishDate: details?.publishDate,
          publishers: (details?.publishers ?? [])
              .map((name) => app_models.Publisher(id: -1, name: name))
              .toList(),
          subjects: (details?.subjects ?? [])
              .map((name) => app_models.Subject(id: -1, name: name))
              .toList(),
          people: (details?.people ?? [])
              .map((name) => app_models.Person(id: -1, name: name))
              .toList(),
          places: (details?.places ?? [])
              .map((name) => app_models.Place(id: -1, name: name))
              .toList(),
          times: (details?.times ?? [])
              .map((name) => app_models.Time(id: -1, name: name))
              .toList(),
        );
      }
    }
    if (mounted && loadedBook != null) {
      setState(() => _book = loadedBook);
    }
  }

  Future<void> _addBookToLibrary() async {
    if (widget.apiBook == null) return;
    final bookService = context.read<BookService>();
    await bookService.addBookFromApi(widget.apiBook!);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("'${widget.apiBook!.title}' kütüphaneye eklendi!")));
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _loadDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _book == null)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text("Hata: ${snapshot.error}"));
          if (_book == null)
            return const Center(child: Text("Kitap bulunamadı."));

          // CustomScrollView, tüm içeriği kaydırılabilir hale getirir.
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              // SliverToBoxAdapter ve Column yerine SliverList kullanıyoruz.
              // Bu, içeriğin ekranı aşması durumunda sorunsuzca kaydırılmasını sağlar.
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      _buildAuthorAndPublisherInfo(),
                      _buildSubjectsExpansionTile(),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Açıklama'),
                      _buildDescription(),
                      _buildDetailSection(
                          title: 'Kişiler',
                          chips: _book!.people
                              .map((p) => Chip(label: Text(p.name)))
                              .toList()),
                      _buildDetailSection(
                          title: 'Mekanlar',
                          chips: _book!.places
                              .map((p) => Chip(label: Text(p.name)))
                              .toList()),
                      _buildDetailSection(
                          title: 'Zamanlar',
                          chips: _book!.times
                              .map((p) => Chip(label: Text(p.name)))
                              .toList()),
                      const SizedBox(height: 24),
                      _buildNotesSection(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      elevation: 1,
      actions: [
        // Kütüphaneye Ekle Butonu (sadece kitap kütüphanede değilse görünür)
        if (!_isBookInLibrary)
          IconButton(
              icon: const Icon(Icons.add_circle),
              tooltip: 'Kütüphaneye Ekle',
              onPressed: _addBookToLibrary),

        // === YENİ: SİLME BUTONU (sadece kitap kütüphanedeyse görünür) ===
        if (_isBookInLibrary)
          IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Kitabı Sil',
              onPressed: _showDeleteConfirmationDialog),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
        title: Text(_book!.name ?? 'Başlık Yok',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, shadows: [
              Shadow(color: Colors.black.withOpacity(0.7), blurRadius: 4)
            ])),
        background: _book!.coverUrl != null
            ? Stack(fit: StackFit.expand, children: [
                Image.network(_book!.coverUrl!, fit: BoxFit.cover),
                DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8)
                    ])))
              ])
            : Container(color: Theme.of(context).colorScheme.secondary),
      ),
    );
  }

  Widget _buildAuthorAndPublisherInfo() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_book!.authors.isNotEmpty)
          Text(_book!.authorString,
              style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold)),

        const SizedBox(height: 8),

        // Wrap, Row'dan daha esnektir. Çocukları sığmazsa alt satıra kaydırır.
        Wrap(
          spacing: 16.0, // Yatay boşluk
          runSpacing: 8.0, // Dikey boşluk (alt satıra kayarsa)
          children: [
            if (_book!.publishers.isNotEmpty)
              _buildInfoItem(
                icon: Icons.business_outlined,
                text:
                    'Yayıncı: ${_book!.publishers.map((p) => p.name).join(', ')}',
              ),
            if (_book!.totalPages != null && _book!.totalPages! > 0)
              _buildInfoItem(
                icon: Icons.pages_outlined,
                text: '${_book!.totalPages} sayfa',
              ),
            if (_book!.publishDate != null && _book!.publishDate!.isNotEmpty)
              _buildInfoItem(
                icon: Icons.calendar_today_outlined,
                text: 'Yayın: ${_book!.publishDate}',
              ),
          ],
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  // Tekrarlanan kodu önlemek için yardımcı widget
  Widget _buildInfoItem({required IconData icon, required String text}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize
          .min, // Row'un sadece içindekiler kadar yer kaplamasını sağlar
      children: [
        Icon(icon, size: 16, color: theme.textTheme.bodySmall?.color),
        const SizedBox(width: 6),
        Flexible(child: Text(text, style: theme.textTheme.bodyLarge)),
      ],
    );
  }

  Widget _buildSubjectsExpansionTile() {
    if (_book!.subjects.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(title: const Text('Konular'), children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _book!.subjects
                    .map((s) => Chip(label: Text(s.name)))
                    .toList()))
      ]),
    );
  }

  Widget _buildDetailSection(
      {required String title, required List<Widget> chips}) {
    if (chips.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 16),
      _buildSectionTitle(title),
      Wrap(spacing: 8.0, runSpacing: 4.0, children: chips)
    ]);
  }

  Widget _buildSectionTitle(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge));

  Widget _buildDescription() {
    final description = _book!.description?.trim();
    if (description == null || description.isEmpty)
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text("Bu kitap için açıklama bulunmuyor.",
              style: TextStyle(fontStyle: FontStyle.italic)));
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(description,
            style:
                Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5)));
  }

  Widget _buildNotesSection() {
    if (!_isBookInLibrary) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Icon(Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary, size: 32),
                const SizedBox(height: 8),
                const Text(
                    'Not eklemek için bu kitabı\nkütüphanenize eklemelisiniz.',
                    textAlign: TextAlign.center)
              ])));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitle('Notlarım'),
      _buildAddNoteForm(),
      const SizedBox(height: 16),
      _buildNotesList()
    ]);
  }

  Widget _buildAddNoteForm() {
    final _noteFocusNode = FocusNode();
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 4),
          child: Row(children: [
            Expanded(
                child: TextField(
                    controller: _noteController,
                    focusNode: _noteFocusNode,
                    decoration: const InputDecoration(
                        hintText: 'Bu kitap hakkında bir not ekle...',
                        border: InputBorder.none),
                    maxLines: null)),
            IconButton(
                icon: const Icon(Icons.add_comment_outlined),
                onPressed: () async {
                  await _addNote();
                  _noteFocusNode.unfocus();
                },
                color: Theme.of(context).colorScheme.primary)
          ])),
    );
  }

  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty ||
        _book == null ||
        !_isBookInLibrary) return;
    final bookService = context.read<BookService>();
    await bookService.addNoteForBook(_noteController.text.trim(), _book!.id);
    _noteController.clear();
    final updatedNotes = await bookService.getNotesForBook(_book!.id);
    if (mounted) setState(() => _notes = updatedNotes);
  }

  Future<void> _deleteNote(int noteId) async {
    final bookService = context.read<BookService>();
    await bookService.deleteNote(noteId);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Not silindi.")));
    if (mounted)
      setState(() => _notes.removeWhere((note) => note.id == noteId));
  }

  Widget _buildNotesList() {
    if (_notes.isEmpty)
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Center(child: Text("Henüz not eklenmemiş.")));
    return ListView.builder(
      itemCount: _notes.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final note = _notes[index];
        return Dismissible(
          key: ValueKey(note.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _deleteNote(note.id),
          background: Container(
              color: Colors.red.shade700,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.only(bottom: 8),
              child: const Icon(Icons.delete, color: Colors.white)),
          child: Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(title: Text(note.text))),
        );
      },
    );
  }
}
