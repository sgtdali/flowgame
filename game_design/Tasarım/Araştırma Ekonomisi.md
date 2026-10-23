---
tur: sistem
durum: karma
guncelleme: 2026-10-23
---
# Araştırma ekonomisi

## Onaylı model: kademeli laboratuvar ve puan deposu (K-008)

Laboratuvarlar kademelidir ve araştırmadan bağımsız olarak hep aynı ürünleri tüketir. Her laboratuvar kendi kademesinin araştırma puanını üretir; puanlar depoda birikir. Araştırmanın fiyatı kademe puanlarıyla yazılır ve aktif araştırma eksik kalan puanı depodan çeker. Araştırma değiştirmek laboratuvar hatlarını bozmaz.

Prototipteki ilk deneme (dengelenmemiş):

| Laboratuvar | Sürekli tükettiği | Ürettiği | Açılış |
|---|---|---|---|
| Laboratuvar 1 | çelik levha + bağlantı elemanı | Kademe 1 puanı | Başlangıç |
| Laboratuvar 2 | dişli + bakır tel + endüstriyel cam | Kademe 2 puanı | AL-02 |
| Laboratuvar 3 | devre kartı + bobin + mil | Kademe 3 puanı | AL-03 |
| Laboratuvar 4 | elektrik motoru + mikroçip + hidrolik silindir | Kademe 4 puanı | AL-05 (K-025) |

Laboratuvarlar puanları ağ bağlantılarıyla gelen ürünlerden üretir; oyuncunun envanteri (K-011) laboratuvarı kendiliğinden beslemez.

Fiyatlar 63 araştırmanın her biri için [[Tasarım/Teknoloji Ağacı]] notunda; ilk araştırmalar 20–40 K1, son araştırmalar K3 ve K4 ister (Kurucu Çekirdek 100 K4).

## Tarihsel: doğrudan ürün tüketen araştırma (K-001)

Önceki onaylı seçim, **gerçek endüstriyel ürünleri doğrudan tüketen araştırmalardı** (K-001); K-008 ile yerine geçti. Oyuncu her araştırmada laboratuvar hattını yeniden kurmak zorunda kaldığı için bırakıldı. Araştırmayı çok malzemeli deneylere ayırmak, aşağıdaki laboratuvar davranışları ve bütün sayılar öneridir.

Önerilen modelde araştırmanın bir deney reçetesi, deney süresi ve gerekli deney sayısı olur. Laboratuvar, bir deneyin bütün girdileri hazırsa deneyi başlatır; girdiler deney başında birlikte tüketilir. Tamamlanan deney ilerlemeyi artırır. Malzeme eksikse deney başlamaz; yalnızca bir girdiyi tüketerek beklemez.

Araştırma merkezi canvas üzerinde gerçek bir tüketici düğümdür. Ürünlerin ağ bağlantılarıyla ulaşması önerilir. Bütün haritadan otomatik malzeme çeken sınırsız global envanter önerilmemiştir.

## Örnek: Endüstriyel Otomasyon I

| Alan | Örnek değer |
|---|---|
| Deney girdileri | 2 dişli + 3 bakır bobin + 1 çelik levha |
| Deney sayısı | 60 |
| Tek laboratuvar deney süresi | 10 saniye |
| Örnek ödül | Otomatik montaj tesisi ve iki reçete |
| Toplam tüketim | 120 dişli + 180 bobin + 60 levha |

Bu isim ve miktarlar onaylı içerik kataloğu değildir.

## Kapasite ile tedarik ilişkisi

Bir laboratuvar dakikada altı deney tamamlar. Tam kapasite talebi 12 dişli/dk, 18 bobin/dk ve 6 levha/dk olur. Kesintisiz tedarikle 60 deney 10 dakikada biter. İki laboratuvar 24 dişli/dk, 36 bobin/dk ve 12 levha/dk beslenirse aynı araştırma yaklaşık 5 dakikada biter.

Bobin tedariki 8/dk ise 180 bobin için uzun dönem malzeme alt sınırı 22,5 dakikadır. Bu, sıfır başlangıç stoku ve diğer girdilerin yeterli olduğu idealize akış hesabıdır; gerçek son deneyin bitiş zamanı ürünlerin geliş anına ve deney yürütmesine bağlıdır. İlk araştırmanın hedef süresi olarak kullanılmaz.

Genel hesap: deney/dk kapasitesi `laboratuvar sayısı × 60 / deney süresi (sn)`; malzeme sınırı her ürün için `gelen ürün/dk / deney başına tüketim` olur. Uzun dönem deney hızı bunların en küçüğünü aşamaz. Tampon stoklar ve kesintili teslimatlar kısa vadede sonucu değiştirir.

## Eski üretim hatlarını koruma önerileri

1. Eski ürünler sonraki araştırmalarda yeniden kullanılır. Her araştırmanın tamamen farklı ürün istemesi önlenir. Zorunlu bir yeniden kullanım yüzdesi belirlenmemiştir.
2. Araştırma değişince bağlantılar silinmez. Gerekli olmayan ürünlerin küçük tamponlarda tutulması, tamponlar dolunca bağlı üretimin durması önerilmiştir. Taşıma kabulü ve stok ayrıntısı açık kalır.
3. Oyuncu araştırma değiştirebilir. Tamamlanan deneyler korunur; başlamış deney biter, sonra yeni araştırmaya geçilir. Bu öneride son malzemelerin ayrılması ve eşzamanlı laboratuvar geçişi ayrıca tanımlanmalıdır.

## Dengeleme ilkeleri önerisi

- Ek laboratuvar yalnızca yeterli tedarikle hız kazandırır.
- Sıradan araştırmalarda zorunlu süre sınırı bulunmaz; yavaş üretim ilerlemeyi durdurmaz.
- Her yeni araştırma yalnızca daha büyük toplam sayı istememeli; yeni zincir, daha yüksek hız veya ortak ürün paylaşımı gibi anlamlı bir problem getirmeli.
- İlk yarım saatte oyuncu birkaç kez kurma → besleme → açılım döngüsü yaşayabilmeli.
- Bekleme sırasında başka üretim ve hedefler üzerinde çalışabilmeli.
- Kararlı üretim hızı gereksinimi, kullanılacaksa ileri kalifikasyon veya proje aşamalarında seçici uygulanmalı.

## Gösterilecek durumlar

Araştırma ekranında tamamlanan deney, çalışan laboratuvar, gerçek giriş hızı, tam kapasite talebi, darboğaz ve koşullu kalan süre gösterilmesi önerilir. “Tam kapasite ihtiyacı” ile “malzeme eksikliğinden yavaşlamış mevcut tüketim” birbirine karıştırılmamalıdır.

Örnekte 24/60 deney tamamlandıysa 36 deney için 108 bobin kalır. 8 bobin/dk ile malzeme alt sınırı 13,5 dakikadır. Stoklar, çalışan deneyler ve lojistik akışı gerçek tahmini değiştirebilir.

İlgili ürün satırından onu besleyen üretim ve taşıma hatları vurgulanabilir. Bkz. [[Tasarım/Arayüz ve Büyük Ağ Yönetimi]].

## Araştırma sonrası ekonomi

Bütün teknolojiler bitince tüketimin durması riski bulunur. Tekrarlanabilir endüstriyel araştırmalar ve yeniden yapılabilen büyük projeler önerilmiştir. Sürekli büyüyen verimlilik bonuslarının dengeyi bozma riski var. Bu sistemler ilk prototip kapsamına önerilmemiştir.

Bağlantılar: [[Tasarım/Teknoloji Ağacı]], [[Tasarım/Ana Proje ve Ürün Dağıtımı]], [[Tasarım/Simülasyon İlkeleri]].
