# Fabrika Oyunu

Düğüm tabanlı bir fabrika oyunu: üretim hattını graf olarak kur, çalıştır, sat,
araştırma ağacından yeni istasyon ve ürünler aç. Godot 4.6 `GraphEdit` üzerine kurulu.

Tasarım ve karar günlüğü: [DESIGN.md](DESIGN.md)

> Durum: **Faz 3 tamam.** Hat gerçek zamanlı çalışıyor: ilerleme çubukları,
> kuyruk sayaçları, AÇ/TIKALI rozetleri, duraklat ve hız kontrolü.
> Henüz yok: para ile istasyon satın alma, araştırma ağacı, slot limiti (Faz 4).

## Çalıştırma

Godot 4.6 ile `project.godot` dosyasını aç, **F5**.

## Kullanım

| İşlem | Nasıl |
|---|---|
| İstasyon ekle | Sol paletten tıkla **veya** tuvale sürükle-bırak |
| Bağla | Bir istasyonun sağ portundan diğerinin sol portuna sürükle |
| Bağlantıyı kaldır | Bağlantıya **sağ tık** |
| Sil | İstasyonu seç, **Delete** |
| Parametre düzenle | İstasyonu seç, sağ panelden değiştir |
| Otomatik hizala | Üst bardaki **Otomatik Diz** |
| Kaydet / Yükle | Üst bar — `.json` olarak |

Alt çubuk kaç istasyonun **tıkalı** ve kaç tanesinin **aç** olduğunu gösterir.
Bu ikisi birbirinin tersi problemdir:

- **AÇ** — girdisi gelmiyor, suç **önceki** istasyonda (kenarlık sarı)
- **TIKALI** — çıktısını boşaltamıyor, suç **sonraki** istasyonda (kenarlık kırmızı)

## Yapı

Klasörler dosya türüne göre değil, **özelliğe göre** ayrılmıştır.

```
common/
  game_config.gd       Denge sayılarının TEK yeri (tick hızı, slot, para)
data/
  item_type.gd         Ürün türü (Resource)
  recipe.gd            Girdi -> çıktı + süre (tick)
  recipe_slot.gd       "Levha × 2"
  block_type.gd        İstasyon arketipi; portları reçetesinden türetir
  research_node.gd     Araştırma kilidi (içeriği Faz 4'te)
  block_catalog.gd     Arketiplerin tek kayıt noktası (preload)
  items/*.tres         7 ürün
  recipes/*.tres       8 reçete
  block_types/*.tres   10 istasyon
features/
  game/                ORKESTRATÖR — simülasyonu sahiplenir, tick'i sürer
  flow_canvas/         GraphEdit tuvali + tek bir blok (GraphNode)
  block_palette/       Sol panel: eklenebilir istasyonlar
  block_inspector/     Sağ panel: seçili istasyonun bilgileri
sim/
  factory_sim.gd       Tick döngüsü, tıkanma, kayıt. Sahne ağacının dışında.
  sim_station.gd       Bir istasyonun durumu: tamponlar, ilerleme, AÇ/TIKALI
  sim_link.gd          İki istasyon arasındaki bağlantı
tools/
  gen_content.gd       İçerik .tres'lerini üreten önyükleme aracı
  sim_test.gd          Determinizm, kaydet/yükle, tıkanma ve denge koşumu
```

## Testler

```bash
godot --headless --path . --script res://tools/sim_test.gd
```

### Mimari kuralı

Sinyal **yukarı**, çağrı **aşağı**. Palet, tuval ve denetçi birbirini tanımaz;
hepsi `flow_editor.gd` üzerinden konuşur. Bir bloğun verisinin sahibi daima
bloğun kendisidir — denetçi paneli bloğa doğrudan yazmaz, istek tuval üzerinden
geçer.

## Yeni istasyon türü eklemek

1. Gerekiyorsa `data/items/` altına yeni ürün, `data/recipes/` altına reçete ekle
   (Godot editöründe sağ tık -> New Resource).
2. `data/block_types/` altına yeni istasyon `.tres`'i ekle, reçetesini bağla.
3. `data/block_catalog.gd` içine `preload` satırını ve `_ORDER` listesine ekle.

Palet, portlar ve denetçi kendiliğinden güncellenir — port etiketleri reçeteden
türetilir, elle yazılmaz.

Toplu değişiklik için `tools/gen_content.gd` kullanılabilir, ama **dikkat:**
o araç mevcut dosyaların üzerine yazar ve Inspector'da elle yapılan ayarları siler.

```bash
godot --headless --path . --script res://tools/gen_content.gd
```

## Kayıt biçimi

Düz JSON (`version`, `blocks`, `connections`). Konum `Vector2` yerine ayrı
`x`/`y` float olarak yazılır — JSON'da tip kaybı olmaması için. Bağlantılar
yüklenirken dosyadaki adlara değil, ad eşleme tablosuna göre kurulur.
