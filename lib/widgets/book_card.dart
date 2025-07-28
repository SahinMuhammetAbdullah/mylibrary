import 'package:flutter/material.dart';
import 'package:my_library/models/models.dart'
    as app_models; // Neredeyse tüm dosyalar için;

/// Ana ekranda tek bir kitabı temsil eden kart widget'ı.
/// Kitabın durumuna göre ilerleme çubuğu ve durum etiketi gösterir.
class BookCard extends StatelessWidget {
  final app_models.Book book;
  final VoidCallback onTap;

  const BookCard({super.key, required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analytics = book.analytics;
    double progress = 0.0;

    // İlerleme yüzdesini hesapla, 0'a bölünme hatasını önle
    if (analytics != null && book.totalPages != null && book.totalPages! > 0) {
      // Değerin 0.0 ile 1.0 arasında kalmasını garanti et
      progress = (analytics.currentPage / book.totalPages!).clamp(0.0, 1.0);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // --- Kitap Üst Bilgisi (Kapak, Başlık, Yazar) ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kitap Kapağı
                  SizedBox(
                    width: 70,
                    height: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: book.coverUrl != null
                          ? Image.network(
                              book.coverUrl!,
                              fit: BoxFit.cover,
                              // Resim yüklenemezse veya URL bozuksa gösterilecek fallback
                              errorBuilder: (_, __, ___) => Container(
                                color: theme.colorScheme.secondary,
                                child: Icon(Icons.book_outlined,
                                    color: theme.colorScheme.primary, size: 40),
                              ),
                            )
                          // Kapak URL'si hiç yoksa gösterilecek placeholder
                          : Container(
                              color: theme.colorScheme.secondary,
                              child: Icon(Icons.book_outlined,
                                  color: theme.colorScheme.primary, size: 40),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Kitap Bilgileri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // Bu Column'un yüksekliği artık içeriğine göre belirlenecek.
                      children: [
                        Text(
                          book.name ?? 'Başlık Yok',
                          style: theme.textTheme.titleMedium,
                          maxLines: 2, // En fazla 2 satır göster
                          overflow: TextOverflow.ellipsis, // Sığmazsa ... koy
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.authorString,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8), // Durum çipi için boşluk
                        // Durum Etiketi
                        _buildStatusChip(
                            context, analytics?.status ?? 'wishlist'),
                      ],
                    ),
                  )
                ],
              ),
              // --- İlerleme Çubuğu Bölümü ---
              // Sadece 'reading' veya 'completed' durumunda gösterilir
              if (analytics != null &&
                  (analytics.status == 'reading' ||
                      analytics.status == 'completed'))
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: theme.scaffoldBackgroundColor,
                        color: theme.colorScheme.primary,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sayfa ${analytics.currentPage}/${book.totalPages ?? '?'}',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            '%${(progress * 100).toStringAsFixed(0)}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Kitabın durumuna göre renkli bir etiket (Chip) oluşturan yardımcı metot.
  Widget _buildStatusChip(BuildContext context, String status) {
    final theme = Theme.of(context);
    Color chipColor;
    Color textColor;
    String label;

    switch (status) {
      case 'reading':
        chipColor = theme.colorScheme.primary.withOpacity(0.2);
        textColor = theme.colorScheme.primary;
        label = 'Okuyorum';
        break;
      case 'completed':
        chipColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green.shade700;
        label = 'Okundu';
        break;
      default: // 'wishlist' veya tanımsız durumlar için
        chipColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange.shade800;
        label = 'Okuma Listesi';
        break;
    }

    return Chip(
      label: Text(label,
          style: TextStyle(
              color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
