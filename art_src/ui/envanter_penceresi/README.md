# Envanter ve üretim penceresi: LibreSprite kaynakları

Oyundaki envanter penceresinin (`app/craft_screen.gd`, `app/inventory_slot.gd`) elle çizilmiş
görsellerinin kaynakları. Bir görseli değiştirmek için buradaki dosyayı LibreSprite'ta aç,
düzenle, sonra sağdaki oyun dosyasının üzerine dışa aktar (File > Export, aynı ad ve boyut).

Birden çok katmanlı dosyalarda her katman ayrı bir oyun dosyasıdır (normal, hover, pressed).

| Kaynak | Katman | Oyun dosyası (`app/art/ui/`) | Oyunda nerede | Not |
|---|---|---|---|---|
| `bg1.ase` | | `craft_header_bg.png` | Pencerenin üst başlık bandı | 9-slice 5 px |
| `capraz_cekic.ase` | | `craft_title_icon.png` | "Inventory and Crafting" yazısının solundaki ikon | 32x32, 1:1 |
| `carpi.ase` | normal / hover / pressed | `close_normal.png` / `close_hover.png` / `close_pressed.png` | Sağ üstteki kapatma (çarpı) düğmesi | 32x32 |
| `Sprite-0004.ase` | | `craft_window_frame.png` | Pencerenin dış kenarlığı | 9-slice 9 px |
| `desen_kullanici.png` | | `craft_body_bg.png` | Pencerenin koyu zemin dokusu | 1114x714, 1:1 (blur, jumble, blur ile yapıldı) |
| `cerceve2.ase` | | `craft_items_frame.png` | Machines, Products, Crafting Queue ve Quick Bar bölümlerinin çerçevesi | 9-slice 9 px |
| `machines_icon.ase` | | `machines_icon.png` | Machines ve Crafting Queue başlığındaki dişli | 24x24, 1:1 |
| `product_icon.ase` | | `products_icon.png` | Products başlığındaki kutu | Kaynak 25x26, oyunda 23x24'e küçültülüp 24x24'e konuldu |
| `yildirim.ase` | | `quick_icon.png` | Quick Bar başlığındaki yıldırım | Kaynak 21x28, oyunda 18x24'e küçültüldü |
| `icon_background.ase` | | `icon_slot_bg.png` | Envanter ve Quick Bar kutularının arka planı | 48x48, 9-slice 8 px |
| `envanter_arka_sag.ase` | tüm katmanlar birlikte | `craft_flow_bg.png` | Akış haritası alanının zemini (ızgara, robot, ev, kenarlık) | 784x463, 9-slice 12 px |
| `kenarlık3.ase` | | `flow_center_frame.png` | Akış haritasının ortasındaki büyük kart | 9-slice 24 px |
| `kenarlık2.ase` | | `flow_card_frame.png` | Akış haritasında soldaki Inputs ve sağdaki Used in kartları | 9-slice 8 px |
| `baslik_kenarlik.ase` | | `flow_pill.png` | Akış haritasındaki "Inputs" ve "Used in" etiketleri | 9-slice 8 px |
| `recipe_ust.ase` | | `recipe_top.png` | Ortadaki karttaki "Recipe" başlık şeridi | 9-slice 9 px |
| `recipe_alt.ase` | | `recipe_bottom.png` | Recipe bölümünün gövdesi | 9-slice 9 px |
| `craft_kenarlik.ase` | normal / hover / pressed | `craft_button.png` / `craft_button_hover.png` / `craft_button_pressed.png` | CRAFT düğmesi | 9-slice 10 px |
| `place_kenarlik.ase` | normal / hover / pressed | `place_button.png` / `place_button_hover.png` / `place_button_pressed.png` | PLACE düğmesi | craft_kenarlik'in amber renkli kopyası, 9-slice 10 px |

`products_icon.png` ve `quick_icon.png` dışa aktarıldıktan sonra küçültülüyor; bu ikisini
değiştirince küçültmeyi tekrar yapmak gerekir (ya da ikonu doğrudan 24 px yüksekliğinde çiz).
