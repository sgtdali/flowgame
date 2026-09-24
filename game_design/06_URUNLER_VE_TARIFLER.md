# Ürünler ve Tarifler

**Son güncelleme:** 21.09.2026  
**Sahibi:** Oyun Tasarımı  
**İlgili belgeler:** [Vizyon ve kapsam](01_VIZYON_VE_KAPSAM.md), [İlerleme ve açılışlar](03_ILERLEME_VE_ACILISLAR.md), [Tasarım ilkeleri](04_TASARIM_ILKELERI.md), [Açık konular](05_ACIK_KONULAR.md)

## Amaç

Bu dosya, oyundaki ürünlerin ve aralarındaki üretim ilişkilerinin tek güncel
kaynağıdır. Ürün tarifleri, birleşme noktaları ve araştırma açılışları burada
birlikte tutulur; böylece üretim zincirinin bütünü tek yerden okunabilir.

Mevcut demir-mekanik zinciri, oyunun ana teması veya bütün ilerleme omurgası
değil; geniş sanayi ağı içinde korunmuş bir ürün ailesi adayıdır. Genel sanayi
aileleri kararlaştırılmadan bu zincir `Gearbox` sonrasına genişletilmez.

## Kayıt kuralları

- Her ürün bu dosyada yalnızca bir kez tanımlanır.
- Kararlaştırılmamış bilgi `Karar verilmedi` olarak yazılır; varsayımla
  doldurulmaz.
- Bir tarifte girdi miktarı belirtilmediyse üretim oranı kararlaştırılmış
  sayılmaz.
- Bir ürünün farklı tarifleri varsa her tarif ayrı satırda gösterilir.
- Araştırma adı ile açtığı ürün veya tarif açıkça eşleştirilir.
- Üretici node yalnızca ürünü tanımlamak için kaydedilir; node davranışının
  ayrıntıları bu dosyanın kapsamı değildir.
- Girdi miktarı, dönüşüm oranı, üretim hızı, fiyat, maliyet, kapasite ve süre
  ekonomi modellemesidir; bu dosyada kararlaştırılmaz.

## Ürün ağı

```text
Iron Mine -> Raw Ore -> Iron Ore Extractor -> Iron Ore -> Smelting -> Iron Ingot
Generator -> Electricity
Iron Ingot + Electricity -> Electric Rolling Mill -> Iron Plate
Iron Plate -> Machine Shop -> Iron Gear
Iron Plate + Iron Gear -> Assembly Workshop -> Gearbox
```

## Ürün kayıtları

### Raw Ore

- **Sınıf:** Hammadde
- **Girdiler:** Yok
- **Üreten node:** `Iron Mine`
- **Kullanıldığı ürün:** `Iron Ore`
- **Satılabilirlik:** Satılamaz
- **Açan araştırma:** Başlangıçta açık
- **Zincirdeki amacı:** Demir-mekanik ürün ailesinin işlenmemiş ilk girdisidir.

### Iron Ore

- **Sınıf:** Ara ürün
- **Girdiler:** `Raw Ore`
- **Üreten node:** `Iron Ore Extractor`
- **Kullanıldığı ürün:** `Iron Ingot`
- **Satılabilirlik:** Satılabilir
- **Açan araştırma:** Başlangıçta açık
- **Zincirdeki amacı:** İlk işlenmiş ve satılabilir maden ürünüdür.

### Iron Ingot

- **Sınıf:** Ara ürün
- **Girdiler:** `Iron Ore`
- **Üreten node:** `Smelting`
- **Kullanıldığı ürün:** `Iron Plate`
- **Satılabilirlik:** Satılabilir
- **Açan araştırma:** Başlangıçta açık
- **Zincirdeki amacı:** Demir-mekanik ürün ailesinin temel işlenmiş metal
  ürünüdür.

### Electricity

- **Sınıf:** Enerji
- **Ürün girdileri:** Yok
- **Üreten node:** `Generator`
- **Kullanıldığı ürün:** `Iron Plate`
- **Satılabilirlik:** Satılabilir
- **Açan araştırma:** `Electrification`
- **Zincirdeki amacı:** Önce bağımsız değer sağlayan, sonra demir koluyla
  birleşen ikinci ana üründür.

### Iron Plate

- **Sınıf:** Ara ürün
- **Girdiler:** `Iron Ingot` ve `Electricity`
- **Üreten node:** `Electric Rolling Mill`
- **Kullanıldığı ürünler:** `Iron Gear` ve `Gearbox`
- **Satılabilirlik:** Satılabilir
- **Açan araştırma:** `Electric Rolling`
- **Zincirdeki amacı:** Demir ve elektrik kollarının ilk birleşme ürünüdür.

### Iron Gear

- **Sınıf:** Ara ürün
- **Girdiler:** `Iron Plate`
- **Üreten node:** `Machine Shop`
- **Kullanıldığı ürün:** `Gearbox`
- **Satılabilirlik:** Satılabilir
- **Açan araştırma:** `Machining`
- **Zincirdeki amacı:** Mekanik ürün kolunu başlatan işlenmiş parçadır.

### Gearbox

- **Sınıf:** Ara ürün ve satış ürünü
- **Girdiler:** `Iron Plate` ve `Iron Gear`
- **Üreten node:** `Assembly Workshop`
- **Kullanıldığı ürün:** Karar verilmedi
- **Satılabilirlik:** Satılabilir
- **Açan araştırma:** `Mechanical Assembly`
- **Zincirdeki amacı:** Erken mekanik ürün kolunun mevcut son ürünüdür;
  gelecekte ileri bir ürünün girdisi olabilir.

## Araştırma açılışları

| Araştırma | Açtığı node | Açtığı ürün veya tarif |
|---|---|---|
| Başlangıçta açık | `Iron Mine`, `Iron Ore Extractor`, `Smelting` | `Raw Ore`, `Iron Ore`, `Iron Ingot` |
| `Electrification` | `Generator` | `Electricity` |
| `Electric Rolling` | `Electric Rolling Mill` | `Iron Ingot + Electricity -> Iron Plate` |
| `Machining` | `Machine Shop` | `Iron Plate -> Iron Gear` |
| `Mechanical Assembly` | `Assembly Workshop` | `Iron Plate + Iron Gear -> Gearbox` |
