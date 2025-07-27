import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart' as app_models;
import '../services/book_service.dart';

class BookDetailScreen extends StatefulWidget {
  final int bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late Future<void> _loadDataFuture;
  app_models.Book? _book;
  List<app_models.Note> _notes = [];
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

  Future<void> _loadData() async {
    final bookService = context.read<BookService>();
    final bookResult = await bookService.getBookDetailsById(widget.bookId);
    if (bookResult != null) {
      final notesResult = await bookService.getNotesForBook(widget.bookId);
      if (mounted) {
        setState(() {
          _book = bookResult;
          _notes = notesResult;
        });
      }
    }
  }
  
  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty || _book == null) return;
    
    final bookService = context.read<BookService>();
    await bookService.addNoteForBook(_noteController.text.trim(), _book!.id);
    _noteController.clear();
    FocusScope.of(context).unfocus(); // Klavyeyi kapat
    
    // Not listesini yenile
    final updatedNotes = await bookService.getNotesForBook(_book!.id);
    if (mounted) {
      setState(() {
        _notes = updatedNotes;
      });
    }
  }
  
  Future<void> _deleteNote(int noteId) async {
    final bookService = context.read<BookService>();
    await bookService.deleteNote(noteId);
    
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not silindi."), duration: Duration(seconds: 2))
    );

    // Not listesini yerel olarak güncelle
    if (mounted) {
      setState(() {
        _notes.removeWhere((note) => note.id == noteId);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _loadDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _book == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }
          
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoChips(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Açıklama'),
                      _buildDescription(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Notlarım'),
                      _buildAddNoteForm(),
                      const SizedBox(height: 16),
                      _buildNotesList(),
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
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      elevation: 1,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
        title: Text(
          _book!.name ?? 'Başlık Yok',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, shadows: [
            Shadow(color: Colors.black.withOpacity(0.7), blurRadius: 4)
          ]),
        ),
        background: _book!.coverUrl != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(_book!.coverUrl!, fit: BoxFit.cover),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                      ),
                    ),
                  ),
                ],
              )
            : Container(color: theme.colorScheme.secondary),
      ),
    );
  }

  Widget _buildInfoChips() {
    final allChips = [
      ..._book!.subjects.map((s) => Chip(label: Text(s.name), avatar: const Icon(Icons.label_outline))),
      ..._book!.publishers.map((p) => Chip(label: Text(p.name), avatar: const Icon(Icons.business_outlined))),
    ];

    if (allChips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: allChips,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
  
  Widget _buildDescription() {
    final description = _book!.description?.trim();
    if (description == null || description.isEmpty) {
      return const Text("Bu kitap için açıklama bulunmuyor.", style: TextStyle(fontStyle: FontStyle.italic));
    }
    return Text(description, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5));
  }

  Widget _buildAddNoteForm() {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  hintText: 'Bu kitap hakkında bir not ekle...',
                  border: InputBorder.none,
                ),
                maxLines: null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_comment_outlined),
              onPressed: _addNote,
              color: theme.colorScheme.primary,
            )
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotesList() {
    if (_notes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: Text("Henüz not eklenmemiş.")),
      );
    }
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
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(note.text),
            ),
          ),
        );
      },
    );
  }
}
