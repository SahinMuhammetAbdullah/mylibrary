import 'package:flutter/foundation.dart';

/// Uygulama genelinde veri değişikliklerini bildirmek için kullanılan basit bir ValueNotifier.
/// Bir not eklendiğinde, kitap silindiğinde vb. bu notifier tetiklenir.
/// İlgili ekranlar bunu dinleyerek kendilerini güncelleyebilir.
final ValueNotifier<int> dataChangeNotifier = ValueNotifier(0);

/// dataChangeNotifier'ı dinleyen widget'ları haberdar etmek için bu fonksiyonu çağırın.
/// Değeri basitçe bir artırarak dinleyicileri tetikler.
void notifyDataChanged() {
  dataChangeNotifier.value++;
}