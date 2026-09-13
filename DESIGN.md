# Fabrika Oyunu — Tasarım Belgesi

> Durum: **onaylandı**, uygulamaya hazır.
> Motor: Godot 4.6.1 · Hedef: Windows masaüstü, tek oyuncu

---

## 1. Anlayış Özeti

- **Ne kuruyoruz:** Node tabanlı bir fabrika oyunu. Oyuncu üretim hattını graf olarak
  kurar, hat gerçek zamanlı çalışır, ürün satılır, gelirle araştırma ağacından yeni
  istasyon ve ürünler açılır.
- **Neden var:** Asıl haz kaynağı **tıkanmayı çözmek**. Kuyruklar dolar, istasyonlar aç
  kalır, oyuncu darboğazı görür ve hattı yeniden tasarlar. Oyun bu döngü etrafında döner.
- **Kim için:** Ön bilgi gerektirmeyen jenerik fabrika dili (cevher → külçe → levha →
  montaj). Alan uzmanlığı gerekmez.
- **Nasıl çalışır:** Sabit tick'li ayrık parça simülasyonu. Her istasyonun kuyruğu ve
  ilerlemesi var. Reçeteler çoklu girdi → çıktı alabilir, yani ürün ağacı dallanır.
- **İlerleme:** Erken oyun parayla. Finalde Ar-Ge Laboratuvarı devreye girer; son
  araştırma para değil, laboratuvara **akıtılan ürün** ister.
- **Tavan:** İstasyon slotu limiti. Kademeli gelişimin motoru — "yeni istasyon mu, daha
  verimli istasyon mu" tercihi.
- **MVP hedefi:** Oyuncunun içeriği tüketmesi **en fazla 60 dakika**.

### Explicit non-goals

Offline kazanç · dinamik pazar · sözleşme/sipariş sistemi · enerji şebekesi ·
çoklu reçete seçici · birden fazla fabrika/harita · bitiş koşulu · iflas/başarısızlık ·
ses · çoklu dil desteği.

---

## 2. Varsayımlar

| # | Varsayım | Yanlışsa etkisi |
|---|---|---|
| V1 | Tek oyuncu, yerel, Windows masaüstü. Ağ yok. | Düşük |
| V2 | Tick hızı 10/sn, hedef 60 FPS, geç oyunda ~80 istasyon tavanı. | Orta |
| V3 | Parçalar ayrı node değil, kuyruklarda **sayaç**. Binlerce parça bedava. | **Yüksek** — performansın tamamı buna dayanıyor |
| V4 | Simülasyon deterministik: aynı kayıt + aynı tick = aynı sonuç. | **Yüksek** — offline ve test bunu gerektiriyor |
| V5 | İçerik veri güdümlü (`.tres`): yeni ürün/reçete/araştırma = dosya işi, kod değil. | Orta |
| V6 | Arayüz Türkçe, i18n altyapısı yok. | Düşük |
| V7 | Tek fabrika, tek harita. | Orta |

---

## 3. Karar Günlüğü

| # | Karar | Değerlendirilen alternatifler | Gerekçe |
|---|---|---|---|
| D1 | **Ayrık parça + tick** simülasyonu | Oran/throughput tabanlı; parti/sipariş tabanlı | Tıkanma ve kuyruk oyunun kalbi. Oran modeli sonucu doğru verir ama hissettirmez — oyun tabloya bakmaya döner. |
| D2 | **Çoklu girdi → çıktı** reçeteler | Tek girdi→tek çıktı; tipsiz tek "parça" | Ürün ağacının dallanması buna bağlı. Diğerlerinin üst kümesi olduğu için sonradan geçmek çekirdek yeniden yazımı demek. |
| D3 | **Aktif + duraklatmalı** zaman | Idle/offline; hibrit | Tıkanma yönetimi dikkat ister. Deterministik tick sayesinde offline'ı sonradan eklemek ucuz; tersi zor. |
| D4 | **Sabit fiyatlı satış node'u** | Sözleşme/sipariş; dinamik pazar | "Daha çok akıt = daha çok para" bağını doğrudan hissettirir. Diğer katmanlar bunun üstüne konabilir. |
| D5 | **Önce para, sonra Ar-Ge** | Sadece para; baştan Ar-Ge puanı | Basit başlar, derinleşir. Sadece para olursa araştırma bir bekleme sayacına döner; baştan Ar-Ge ise ilk 10 dakikayı boğar. |
| D6 | **İstasyon slotu limiti** | Enerji şebekesi; kısıt yok | Kademeli gelişimin doğrudan karşılığı. GraphEdit sonsuz tuval olduğu için fiziksel alan kısıtı bu yapıya ters. |
| D7 | **Jenerik fabrika teması** | Sanayi teması + oyunlaşmış sunum; fantastik dünya | Ön bilgi gerektirmez, ürün ağacı sezgisel dallanır. Ayrıca önceki içeriğin silinmesi gerekiyordu (D17). |
| D8 | **Simülasyon ayrı model** (`RefCounted`), GraphEdit sadece vitrin | Node'ların kendisi simüle etsin | Headless test, determinizm garantisi, offline yolu açık. Alternatif simülasyonu arayüze çivilerdi. |
| D9 | `progress` **int tick**, float değil | Float delta birikimi | Float birikimli yuvarlama hatası yapar; saatler sonra iki aynı kayıt farklı sonuç verir. |
| D10 | İstasyon kimliği **int id**, GraphEdit düğüm adı değil | Düğüm adını kimlik saymak | "İsim = kimlik" varsayımı bu projede zaten bir bağlantı kaybı hatasına yol açtı. |
| D11 | **İki fazlı tick** (üret → taşı) | Tek fazlı döngü | Tek fazda sonuç istasyon sırasına bağlı olurdu. İki faz "bir tick = bir adım" garantisi verir. |
| D12 | Fire **sayaçlı**, rastgele değil | Seed'li RNG | Determinizm bedavaya gelir; oyuncu örüntüyü öğrenip plan yapabilir. Rastgelelik burada haksızlık hissi üretir. |
| D13 | Portlar **reçeteden türer** | `BlockType`'ta elle port etiketleri | Tek gerçek kaynağı. Montaj'ın iki girişi olması reçetesinden gelir. |
| D14 | `ResearchNode.requires` = **id listesi** | `Array[ResearchNode]` referansı | Godot resource zincirleri derinleşince kırılgan. Id ile gevşek bağlamak düzenlemeyi de ucuzlatır. |
| D15 | Para **int** | Float para | Birikimli yuvarlama hatası. |
| D16 | Ar-Ge MVP **finalinde tek araştırma** | MVP'de hiç yok; baştan itibaren var | En belirsiz mekaniği gerçek oyunda test eder, kapsamı şişirmeden. MVP'ye doruk noktası verir. |
| D17 | Önceki savunma sanayi içeriği **silindi** | Saklamak / "gerçekçi mod" olarak tutmak | Kullanıcı talebi; kamuya açık paylaşımın hukuki riski. |
| D18 | MVP'de **bitiş koşulu yok** | Kazanma ekranı | Sonraya bırakıldı, henüz netleşmedi. |
| D19 | Başarısızlık yok, **sadece yavaşlama** | İflas / oyun sonu | Kurcalama hissini korur. |

---

## 4. Tasarım

### 4.1 Katmanlar

```
SUNUM      GraphEdit · FlowBlock · Palet · Araştırma paneli · Üst bar
           (hiçbir şeye sahip değil, sadece yansıtır)
              ↑ sinyal              ↓ komut
ORKESTRA   GameController
              ↑ sinyal              ↓ komut
MANTIK     FactorySim · Economy · ResearchTree      ← gerçeğin sahibi
VERİ       ItemType · Recipe · BlockType · ResearchNode  (.tres)
```

Kural: **sinyal yukarı, çağrı aşağı.** Sunum katmanı veriyi asla doğrudan değiştirmez.
Simülasyon `Node` değil `RefCounted` — sahne ağacında yaşamaz, `_process` kullanmaz.

### 4.2 Simülasyon çekirdeği

```gdscript
class SimStation:                 # RefCounted
    var id: int                   # kalıcı kimlik
    var type: BlockType
    var recipe: Recipe
    var input: Dictionary         # item_id -> adet
    var output: Dictionary
    var progress_ticks: int
    var next_output_link: int     # round-robin sayacı

class SimLink:
    var from_id: int;  var from_port: int
    var to_id: int;    var to_port: int
```

**Tıkanma mekaniği:** `output` dolu bir istasyon yeni üretime başlayamaz. Dolu çıktı →
istasyon durur → ondan öncekinin çıktısı dolar → tıkanma zincir boyunca geriye yürür.
Oyuncunun göreceği ve çözeceği şey bu.

### 4.3 Tick döngüsü

```gdscript
func tick() -> void:
    _tick_count += 1
    _phase_produce()    # üret / ilerlet
    _phase_transfer()   # çıktıdan komşunun girdisine taşı
```

**Üretim fazı** (her istasyon):
- Üretim sürüyorsa `progress_ticks += 1`; dolduğunda çıktı `output`'a düşer
- Boştaysa **ve** girdi reçeteyi karşılıyorsa **ve** çıktıda yer varsa → girdiyi tüket,
  üretime başla
- Kaynak istasyon girdi istemez, sabit aralıkla üretir
- Sevkiyat girdiyi yutar ve `Economy`'ye satışı bildirir

**Taşıma fazı:** her çıkış portundaki bağlantılar **round-robin** denenir. Bir çıkışta iki
bağlantı varsa yük kendiliğinden dengelenir, determinizm bozulmaz.

**Neden iki faz:** Tek fazda id'si küçük zincirler bir tick'te baştan sona akar, büyükler
beklerdi. İki faz "bir tick'te her ürün en fazla bir adım ilerler" garantisi verir.

**Hız kontrolü:**
```gdscript
_accumulator += delta * TICKS_PER_SECOND * speed   # temel 10 tick/sn
while _accumulator >= 1.0 and processed < MAX_PER_FRAME:
    sim.tick(); _accumulator -= 1.0; processed += 1
```
`MAX_PER_FRAME` tavanı zorunlu — yoksa bir kare takıldığında tick borcu birikir ve oyun
kendini daha da yavaşlatarak geri dönemez hâle gelir.

### 4.4 Veri modeli

```gdscript
class_name ItemType extends Resource
    id, display_name, color, icon_char
    base_price: int               # int — float para yuvarlama hatası yapar

class_name Recipe extends Resource
    inputs:  Array[RecipeSlot]    # RecipeSlot = { item: ItemType, count: int }
    outputs: Array[RecipeSlot]
    duration_ticks: int

class_name ResearchNode extends Resource
    requires: PackedStringArray   # id listesi (Resource referansı değil)
    cost_money: int
    cost_items: Array[RecipeSlot] # doluysa Ar-Ge Lab gerektirir
    unlocks_blocks: Array[BlockType]
    slot_bonus: int
```

`BlockType` sadeleşir: kimlik, görsel, maliyet ve **bir reçete referansı** tutar. Port
etiketleri reçeteden türetilir.

### 4.5 MVP içeriği

**Ürün ağacı — 6 kademe**

| Ürün | Reçete | Fiyat |
|---|---|---|
| Cevher | (Maden Ocağı üretir) | — |
| Külçe | 2 Cevher | 10₺ |
| Levha | 1 Külçe | 28₺ |
| Çubuk | 1 Levha | 26₺ |
| Vida | 1 Çubuk → 2 Vida | 20₺ |
| **Gövde** | 2 Levha + 3 Vida | **150₺** |

**Araştırma sırası — 10 düğüm**

Presleme → Fabrika Genişlemesi I → Haddeleme → Kesim → Fabrika Genişlemesi II →
Ara Depo → **Montaj** → Kalite Kontrol → Geri Dönüşüm + Ar-Ge Lab →
**Otomasyon II** (150 × Gövde ister)

Slotlar: başlangıç **5** → Genişleme I **9** → Genişleme II **14**

> Bu sayılar başlangıç tahminidir. Nihai değerler §4.8'deki denge koşumuyla ölçülerek
> belirlenecek — elle tahmin edilmeyecek.

### 4.6 Sunum katmanı

`FlowBlock` artık sim id tutar ve her kare durumunu okur: ilerleme çubuğu, giriş/çıkış
kuyruk sayaçları, `TIKALI` rozeti. Palet sadece açılmış istasyonları gösterir, kilitliler
soluk durur. Üst bara para / slot (7/9) / hız kontrolü girer. Araştırma paneli yeni.

Güncelleme **tek bir döngüden** yapılır: `GameController` her karede sim'i okuyup
FlowBlock'lara yazar — 80 node'un her birine ayrı `_process` konmaz. `Label.text` yazmak
pahalı olduğundan (font shaping) değer değişmediyse yazılmaz.

Kablolarda akan noktalar MVP kapsamı dışında.

### 4.7 Kaydetme

Mevcut JSON şeması genişler: sim durumu (kuyruklar, progress, tick sayacı), para ve
açılmış araştırmalar eklenir. `FORMAT_VERSION` zaten mevcut, geriye dönük kırılma olmaz.
Konumlar `Vector2` yerine ayrı `x`/`y` float olarak yazılmaya devam eder.

### 4.8 Test stratejisi

- **Denge koşumu:** bir hat kur, 36.000 tick (≈1 saat) koştur, gelir/dk ve ürün/dk ölç.
  "Oyuncu Montaj'a kaç dakikada ulaşır?" sorusunu elle oynamadan bir script cevaplar.
- **Determinizm testi:** aynı kayıt + 10.000 tick → aynı durum hash'i.
- **Kaydet/yükle turu:** mevcut testin sim durumunu da kapsayacak şekilde genişletilmesi.

Bu koşumların mümkün olması, D8'i (ayrı simülasyon modeli) seçmemizin asıl getirisidir.

---

## 5. MVP tempo taslağı (60 dakika)

| Dakika | Ne olur | Yeni gelen |
|---|---|---|
| 0–5 | Maden Ocağı → Eritme → Sevkiyat. Külçe sat, para aksın. | temel döngü |
| 5–15 | Pres açılır, Levha külçeden değerli. **İlk darboğaz:** Eritme yetişmiyor. | zincir uzatma |
| 15–25 | İkinci Eritme al → **slot dolar.** Fabrika genişlemesi araştır. | kıtlık |
| 25–40 | Hadde + Kesim. **Montaj açılır** — iki ayrı hattı birleştirmek. | asıl tasarım problemi |
| 40–50 | Kalite Kontrol + Geri Dönüşüm. Fire çıkar, geri besleme hattı kur. | döngüsel graf |
| 50–60 | **Ar-Ge Laboratuvarı.** Son araştırma para değil, akıtılan ürün ister. | ikinci döngü |

---

## 6. Riskler

| Risk | Azaltma |
|---|---|
| **60 dk tempo ilk denemede tutmaz** (en büyük risk) | Tüm süre/fiyat sayıları tek yerde; headless koşumla ölç, tahmin etme |
| Tıkanma sinir bozucu olabilir | Tıkalı istasyon net işaretlenir; oyuncu **neden** tıkandığını görmeli |
| Montaj öğrenme eşiği — MVP'nin zirvesi, kavranmazsa oyun orada biter | Montaj açılınca örnek düzen ipucu göster |
| GraphEdit 80+ node'da yavaşlayabilir | Sim zaten ayrı; sıkışırsak sadece görsel kısılır, oyun bozulmaz |

---

## 7. Mevcut durum (bu tasarımdan önce hazır olan)

GraphEdit tuvali, sürükle-bırak palet, `BlockType` resource sistemi, parametre denetçisi,
JSON kaydet/yükle, darboğaz özeti. Mimari zaten "sinyal yukarı / çağrı aşağı" kuralına
uygun — simülasyon katmanı bunun **altına** girecek, üstüne değil.
