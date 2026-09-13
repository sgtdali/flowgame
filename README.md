# Üretim Akışı Editörü

ReactFlow benzeri, düğüm tabanlı bir üretim akışı editörü. Godot 4.6 `GraphEdit`
üzerine kurulu.

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

Alt çubuk istasyon/bağlantı sayısını ve **darboğazı** gösterir
(en yüksek etkin çevrim süresi = süre / kapasite).

## Yapı

Klasörler dosya türüne göre değil, **özelliğe göre** ayrılmıştır.

```
data/
  block_type.gd        İstasyon arketipi (Resource)
  block_catalog.gd     Tüm arketiplerin tek kayıt noktası (preload)
  block_types/*.tres   10 istasyon tanımı — yeni tür eklemek için buraya bak
features/
  flow_editor/         ORKESTRATÖR — bileşenleri birbirine bağlar
  flow_canvas/         GraphEdit tuvali + tek bir blok (GraphNode)
  block_palette/       Sol panel: eklenebilir istasyonlar
  block_inspector/     Sağ panel: seçili istasyonun parametreleri
```

### Mimari kuralı

Sinyal **yukarı**, çağrı **aşağı**. Palet, tuval ve denetçi birbirini tanımaz;
hepsi `flow_editor.gd` üzerinden konuşur. Bir bloğun verisinin sahibi daima
bloğun kendisidir — denetçi paneli bloğa doğrudan yazmaz, istek tuval üzerinden
geçer.

## Yeni istasyon türü eklemek

1. `data/block_types/` içine yeni bir `.tres` kopyala, alanları doldur.
2. `data/block_catalog.gd` içine `preload` satırını ve `_ORDER` listesine ekle.

Palet ve denetçi kendiliğinden günceller.

## Kayıt biçimi

Düz JSON (`version`, `blocks`, `connections`). Konum `Vector2` yerine ayrı
`x`/`y` float olarak yazılır — JSON'da tip kaybı olmaması için. Bağlantılar
yüklenirken dosyadaki adlara değil, ad eşleme tablosuna göre kurulur.
