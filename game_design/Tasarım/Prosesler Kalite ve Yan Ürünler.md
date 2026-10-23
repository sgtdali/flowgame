---
tur: sistem
durum: yon-olarak-olumlu
guncelleme: 2026-10-23
---
# Prosesler, kalite ve yan ürünler

## Tasarım amacı

Farklı üretim yöntemlerinin ve hammadde kollarının farklı sonuçlar üretmesi hedeflenmektedir.

**K-017 Tek Reçete ve Farklı Ürün Kararı:**
K-007'de daha önce sunulan "aynı ürüne (ör. Dişli) birden fazla alternatif yöntem tanımlama" yaklaşımı **K-017** ile güncellenmiştir:
- Her ürünün **tek bir ana tarifi** vardır.
- Farklı proseslerden (ör. Talaşlı İmalat vs. Döküm) veya farklı hammaddelerden (Demir vs. Çelik) gelen ürünler **farklı ürünler** olarak ayrılmıştır:
  - `Cast Iron Gear` (Dökümhane: Iron Ingot)
  - `Steel Gear` (CNC: Steel Rod)
  - `Cast Iron Housing` (Dökümhane: Iron Ingot)
  - `Steel Housing` (Pres: Steel Plate + Fasteners)
- Böylece makinelerde çoklu tarif karmaşası yaşanmaz; ürün çeşitliliği ve zincir derinliği artar.

## Yöntem karşılaştırması: Döküm ve Talaşlı İmalat

| Özellik | Döküm Yöntemi (`Cast Iron`) | Talaşlı / Pres Yöntemi (`Steel`) |
|---|---|---|
| **Hammadde** | `Iron Ingot` (kömürsüz eritme) | `Steel Ingot` (demir cevheri + kömür) |
| **İmalat Makinesi** | `Dökümhane` | `CNC`, `Torna`, `Pres` |
| **Ürün Örnekleri** | `Cast Iron Gear`, `Cast Iron Housing` | `Steel Gear`, `Steel Housing`, `Fasteners` |
| **Yan Ürün** | Talaş çıkmaz | `Metal Scrap` (talaş/hurda) çıkar |
| **Rolü** | Hızlı, kütleli, doğrudan döküm parçalar | Yüksek hassasiyet ve mukavemet gerektiren mekanizmalar |

## Yan ürün ekonomisi (Metal Talaşı / Hurda)

`Torna` ve `CNC` operasyonlarından talaş olarak çıkan `Metal Scrap`, geri dönüşümle fırınlara yönlendirilir:
- Ergitme Fırını: `2x Metal Scrap -> 1x Iron Ingot` (cevher tasarrufu)
- Çelik Fırını: `2x Metal Scrap + 1x Coal -> 1x Steel Ingot` (cevher tasarrufu)

Bu döngü, oyuncuya talaşı biriktirip fırın hattına geri besleyerek hammadde tüketimini optimize etme kararı sunar.

Bkz. [[Tasarım/Ürün ve Üretim Ağı]], [[Tasarım/Makine Kartları]], [[Tasarım/Prototip ve Doğrulama]].
