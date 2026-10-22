---
tur: teknik-tasarim
durum: karma
guncelleme: 2026-10-20
---
# Simülasyon ilkeleri

## Teknik yön önerisi

Üretim ve taşıma simülasyonu görsel kartlardan bağımsız tutulmalı. Bir kartın ekrandan çıkması üretimin durmasına neden olmamalı; ekran dışındaki kartların görsel güncellemeleri gerektiğinde azaltılabilmeli. Bu bir mimari öneridir, mevcut uygulama incelemesi değildir.

Godot kaynak konuşmada teknik aday olarak geçer. Bu vault kurulurken oyun motoru kurulmadı, kod çalıştırılmadı ve performans ölçülmedi.

## Veriyle tanımlanacak olası kavramlar

| Kavram | Önerilen bilgi |
|---|---|
| Ürün | Kimlik, gerekiyorsa kalite/spesifikasyon ve yük katsayısı |
| Makine türü | Uygun reçeteler ve işleme hızı (işleme birimi/sn); K-005 onaylı |
| Makine kartı | Bölge, reçete, varsa makine sayısı, stok ve durum |
| Üretim reçetesi | Girdiler, çıktılar, gereken iş; süre gereken iş / uygun makinenin işleme hızı ile hesaplanır (K-005). Altyapı ayrıca seçilecek. |
| Araştırma | Ön koşullar, deney reçetesi, deney sayısı, ödüller |
| Bölge | Kaynak erişimi, tesisler ve altyapı |
| Taşıma bağlantısı | Uçlar, kapasite, paylaşım ve varsa teslimat gecikmesi |
| Ana proje | Aşamalar ve ürün ihtiyaçları |

Bu tablo kesin dosya şeması değildir. Ürün, reçete ve teknoloji eklemek temel algoritmayı değiştirmeyi gerektirmeyecek veri düzeni hedeflenir.

## Ürün ve işlem bütünlüğü

Bir işlem başlamadan bütün gerekli girdiler kontrol edilir; ayırma/tüketme tek tutarlı işlem olarak yapılır. Paylaşılan stoklarda aynı ürün iki iş tarafından kullanılamaz. Süre tamamlanınca çıktı bir kez üretilir. Sıfır veya negatif süre/miktar gibi veri hataları reddedilmelidir.

Çok laboratuvarlı araştırmada kalan gerekli deney sayısından fazla işe başlanması önlenmelidir. Araştırma değişimi sırasında çalışan işin hangi araştırmaya ait olduğu ve ayrılmış malzemeleri açık tutulmalıdır. Stok, kapasite ve ilerleme negatif olamaz.

Üretim makinelerinde tamponlu çevrim ve çıktı alanı yoksa yeni işe başlamama K-005 ile onaylandı. Ayrıntılar [[Tasarım/Makine Kartları#Onaylı üretim modeli — K-005]] içinde tutulur. Tampon boyutları ve yan ürün bertarafı açık kalır. Paralel işlerin aynı çıkış alanını iki kez kullanmasını önleyecek yöntem, gruplama ve uygulama aşamasında tanımlanmalıdır; bu bir teknik gereksinimdir, seçilmiş algoritma değildir.

## Zaman ve akış

Bölgeler arası malzeme akışının sabit adımlarla hesaplanması kaynak konuşmada önerilmiştir. Adım uzunluğu, kesirli ürünler, taşıma gecikmesi ve eşzamanlılık kuralları belirlenmemiştir. Büyük zaman adımının fazla üretim veya kapasite aşımı yaratmaması gerekir.

Kart yerleşim koordinatları ile ekonomik bölge, bölgesel model seçilirse ayrı tutulmalıdır. Canvas konum değişikliği simülasyonda bedelsiz lojistik transferine dönüşmemelidir.

## Kayıt ve ölçek

Kayıtların kart bağlantılarını, stokları, araştırma ilerlemesini ve çalışan işleri koruması önerilir. Kayıt sürümleme/göç planı henüz seçilmedi. İlk küçük prototipte gereken güvenilirlik tanımlanmalıdır.

Simülasyon süresi, görsel güncelleme süresi, bellek ve ekranda görünen kart sayısı ayrı ölçülmeli. Toplu kartların simülasyonla eşdeğerliği gruplanmamış örnekle kontrol edilebilir. Ölçüm olmadan binlerce kart desteklendiği iddia edilmemelidir.

## Kapsam ve işletim varsayımı

Şimdilik yerel, tek kişinin dosyalardan düzenlediği tasarım alanı kuruldu. Çok oyunculu oyun, bulut eşitleme veya hesap sistemi talep edilmedi. Bunlar oyun ürünü için kesin dışlama kararı değildir. Gizli anahtarlar ve kişisel veriler tasarım kaynaklarına eklenmemelidir. Sürüm yedeği yöntemi kullanıcı tarafından ayrıca seçilebilir.

Bkz. [[Tasarım/Prototip ve Doğrulama]], [[Tasarım/Teknoloji Ağacı]].
