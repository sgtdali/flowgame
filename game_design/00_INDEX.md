# Oyun Tasarımı Kaydı

**Son güncelleme:** 21.09.2026  
**Sahibi:** Oyun Tasarımı  
**İlgili belgeler:** [Vizyon ve kapsam](01_VIZYON_VE_KAPSAM.md), [Ana oynanış döngüsü](02_ANA_OYNANIS_DONGUSU.md), [İlerleme ve açılışlar](03_ILERLEME_VE_ACILISLAR.md), [Tasarım ilkeleri](04_TASARIM_ILKELERI.md), [Açık konular](05_ACIK_KONULAR.md), [Ürünler ve tarifler](06_URUNLER_VE_TARIFLER.md)

## Amaç

Bu klasör, oyunun yalnızca güncel fikrini, kapsamını ve tasarımsal kararlarını
tutan tek kaynaktır. Her dosya yalnızca bugün geçerli olan ifadeleri içerir;
karar geçmişi, uygulama notu ve test kanıtı tutulmaz.

## Dosya sorumlulukları

| Dosya | Sorumluluğu |
|---|---|
| `01_VIZYON_VE_KAPSAM.md` | Oyuncuya verilen söz, tema, hedef deneyim, kapsam ve kapsam dışı alanlar |
| `02_ANA_OYNANIS_DONGUSU.md` | Oyuncunun tekrar eden eylemleri, kaynak-yatırım ilişkisi ve karar noktaları |
| `03_ILERLEME_VE_ACILISLAR.md` | Büyük aşamalar, açılışların faydası ve sistemlerin birleşmesi |
| `04_TASARIM_ILKELERI.md` | Yeni fikirleri değerlendiren tasarım filtreleri ve kısıtlar |
| `05_ACIK_KONULAR.md` | Henüz karara bağlanmamış tekil konular |
| `06_URUNLER_VE_TARIFLER.md` | Ürünler, üretim girdileri, kullanım alanları ve araştırma açılışları |

## Kullanım kuralları

1. Tasarım modunda önce bu dosyayı, sonra ilgili konu dosyasını oku.
2. Bir kararın yalnızca ilgili konu dosyasında tek bir güncel ifadesi bulunur.
3. Dosyalar çelişirse kayıt değiştirilmez; kullanıcıya çelişki raporlanır.
4. Açık konu çözüldüğünde kalıcı dosyaya taşınır ve açık konular listesinden
   silinir.
5. Dosya değişiklikleri yalnızca kullanıcının açık `onay`, `kaydet` veya
   `uygula` komutuyla yapılır.

## Otorite sınırı

Tasarım modunda bu klasör tek tasarım kaynağıdır. Kod, veri kaynağı, test,
ölçüm veya eski belge mevcut tasarım kararını değiştirme yetkisine sahip
değildir; yalnızca tasarımla uygulama arasında fark olduğunu gösterebilir.
