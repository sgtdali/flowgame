---
tur: gorsel-tasarim
durum: oneri
guncelleme: 2026-10-20
---
# Node editör — görsel öneri v1

Kullanıcının game_design içindeki oyuna göre node editör mockup'ı oluşturma talebiyle hazırlandı. Bu bir görsel tasarım önerisidir; onaylı arayüz veya çalışan oyunun ekran görüntüsü değildir.

> [!note] Tarihsel öneri
> Prototip bu düzenden ayrıldı: sol kütüphane ve sağ ayrıntı paneli yok; makineler üretim ekranında (C) yapılır, envanterden ve alttaki hızlı erişimden yerleştirilir, kart ayrıntıları kartın üstünde ve sağ tık menüsündedir. Güncel arayüz: [[Yönetim/Uygulama Durumu#Arayüz]].

![[Ekler/node_editor_mockup_v1.png]]

## Gösterilen yön

- Solda makine kütüphanesi, ortada sonsuz canvas, sağda seçili makinenin ayrıntıları.
- Kartlarda makine görseli, reçete, çevrim ilerlemesi, stok ve durum.
- CNC örneği: 100 iş / 20 iş/sn = 5 saniye; 2 demir çubuktan 1 dişli; kapasite 12/dk.
- Dişli çıkışının iki tüketiciye otomatik 6/6 paylaşılması; araştırma tarafında girdi darboğazının görünmesi.
- Bağlantılarda ürün ve hız etiketleri; metal girdiler, bobin ve dişli için ayrı renkler.

## Yorum sınırı

Makine çizimleri, yan panel, kütüphane düzeni, kontrol yerleşimleri ve araştırma görünümü öneridir. Hadde, bobin, pres ve montaj zincirinin bütün reçeteleri onaylanmış değildir. Tampon sayı ve hızları örnektir. Ürünlerin kaynak tarafı ekran dışında bırakılmıştır.

Görseldeki araştırma satırları gelen / tam kapasite talebi olarak düşünülmüştür; üretilen yazıda birim biçimi `6 / 12 dk` gibi görünebilir. Uygulamada bunlar açıkça `Gelen 6/dk · İhtiyaç 12/dk` yazılmalıdır. Görsel, işleyen simülasyon verisi değildir.

## Kaynaklar

[[Tasarım/Makine Kartları]], [[Tasarım/Ana Proje ve Ürün Dağıtımı]], [[Tasarım/Araştırma Ekonomisi]], [[Tasarım/Arayüz ve Büyük Ağ Yönetimi]].

Yerleşik `image_gen` ile üretildi; levha hattını araştırmaya bağlayan hedefli bir düzeltme yapıldı. Üretim istemi: [[Ekler/node_editor_mockup_v1.prompt]].
