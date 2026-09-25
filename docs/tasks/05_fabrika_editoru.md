# Görev 05 — Fabrika içi düğüm editörü (sabit fabrikanın yerine)

Mod: **yazılım modu**. Kaynak: tasarım belgesi → "Fabrika içi" (mevcut editör, kapılar ve
hatlar, fabrika stokları, haritadan fabrikaya geçiş), "Stok ve kabul", "Geliştirme sırası 5".
Bu dosya gereken kısıtları içerir.

## Kapsam

Var: arsaya tarifsiz fabrika kurma, fabrikanın içini Iron & Ember düğüm editörüyle kurma,
giriş/çıkış kapıları, fabrika giriş ve çıkış stokları, tam ekran fabrika görünümü,
haritada fabrika özeti ve uyarı işareti.
Yok: enerji/jeneratör, şablon kaydetme, fabrika seviyesi, birleştirici ayrı düğümü
(iki girdili tarifler zaten işleyicide), hat panelinde yük oranı arayüzü, kaydetme.

Hedef: oyuncu Area1'de **orman → fabrika (içinde Sawmill) → City A** zincirini editörle
kurup para kazanabilir.

## Tasarım kısıtları

- **Mevcut editör:** Iron & Ember'in düğüm editörü (`FlowCanvas`, `FlowBlock`, palet) ve
  parça simülasyonu (`FactorySim`) kullanılır; mallar düğümler arasında tek tek akar.
  Yalnızca genel bloklar alınır: işleyici, ayırıcı, depo. Maden, satış ve ticaret blokları
  alınmaz. Tarifler yeni oyunun mallarıyla kurulur.
- **Kurulum:** arsaya fabrika kurmak yalnızca bedeli öder (300); tarif seçilmez, içi boş gelir.
  Bakım 3/dk.
- **Kabul:** fabrika her malı kabul eder.
- **Fabrika stokları:** her mal için ayrı **giriş stoğu** ve **çıkış stoğu** (her biri 50).
  Hatlar giriş stoğuna koyar; fabrikadan çıkan hatlar yalnızca çıkış stoğundan alır.
  Kullanılmayan malın giriş stoğu dolunca o mal taşınmaz, payı diğer mallara geçer.
- **Kapılar:** her mal için bir kapı. Bir hat fabrikaya mal getirmeye başlayınca o malın
  giriş kapısı kendiliğinden belirir. Çıkış kapılarını ve işleyicileri oyuncu yerleştirir.
  Çıkış stoğu dolunca çıkış kapısı mal almaz; parçalar içeride birikir, işleyiciler durur.
  Giriş kapısı doğrudan çıkış kapısına bağlanabilir (aktarma).
- **Girip çıkma:** arsa panelinde "Open factory" → editör tam ekran, harita gizlenir;
  "Back to map" ya da Esc ile dönülür.
- **Zaman:** tek oyun saati; fabrikadayken harita da çalışır. Hız düğmeleri editörde de görünür.
- **Haritadaki özet:** arsa panelinde her mal için giren ve çıkan birim/dk; girdisi eksik ya da
  çıkışı dolu fabrikanın harita simgesinde uyarı işareti.
- Arayüz metinleri İngilizce.

## Uygulama kararları (onay bekliyor)

- **K1 — Eski koda dokunmama:** Iron & Ember dosyaları (`factory_sim.gd`, `flow_canvas.gd`,
  `flow_block.gd`, `block_palette`, `game_controller.gd`) değiştirilmez. Kapı davranışı
  `FactorySim`'den türeyen yeni bir sınıfta, kapı görünümü `FlowBlock`'u saran/türeyen yeni
  bir dosyada yazılır. Eski oyun (`game.tscn`) çalışmaya devam eder.
- **K2 — Mal türleri birleşir:** haritadaki `Good`, Iron & Ember'in `ItemType`'ından türer.
  Böylece Logs, Lumber gibi mallar düğüm editöründe doğrudan kullanılır; ikinci bir mal listesi
  tutulmaz.
- **K3 — Palet (ilk sürüm):** Sawmill (1 Logs → 1 Lumber, 10/dk), Mill (2 Wheat → 1 Flour,
  10/dk), Splitter (1 giriş, 2 çıkış), Depot (tampon, 200) ve her mal için bir
  "Output: <mal>" kapısı. Jeneratör yok (enerji sonraki kademede).
- **K4 — Blok maliyeti yok:** editörde blok koymak bedava; tek bedel arsaya fabrika kurmak (300).
- **K5 — Giriş kapısı silinmez:** kendiliğinden gelen giriş kapısı oyuncu tarafından silinemez,
  taşınabilir. Çıkış kapısı ve diğer bloklar silinebilir.
- **K6 — Uyarı işareti:** fabrikanın bir çıkış stoğu doluysa ya da içindeki bir işleyici
  girdi bekliyorsa haritadaki simgede uyarı yanar. Hiç işleyicisi olmayan boş fabrika uyarı vermez.
- **K7 — Sabit fabrika kalkar:** kurarken tarif seçme ve `ProcessRecipe` kaldırılır; akış
  testi yeni fabrikaya göre güncellenir.
- **K8 — Parça saati:** fabrika içi simülasyon oyun saatine bağlanır: oyun saniyesi başına
  10 adım (Iron & Ember'deki hız). Duraklatınca durur, x4'te dört kat koşar.

## Teknik yaklaşım

1. **Veri** (`data/`): `Good` → `ItemType`'tan türer. Iron & Ember `Recipe`/`RecipeSlot`/
   `BlockType` sınıflarıyla yeni `.tres`'ler: `data/factory_recipes/`, `data/factory_blocks/`
   (Sawmill, Mill, Splitter, Depot). Kapı blokları kodla değil veriyle tanımlanır
   (kapı türü + mal). `MapConfig`'e: fabrika paleti, fabrika içi adım hızı.
2. **Fabrika içi simülasyon** (`sim/`): `factory_interior.gd` — bir fabrikanın parça
   simülasyonu, giriş/çıkış stokları ve kapılar. `FactorySim`'den türer, yalnızca kapıların
   adımını ekler. Arayüzsüz, headless test edilir.
3. **Harita entegrasyonu:** `factory_sites.gd` ve `map_flow_sim.gd` — tarifsiz fabrika,
   her malı kabul, giriş/çıkış stokları, fabrika içinin oyun saatiyle adımlanması, dakikalık
   giren/çıkan ölçümü, uyarı durumu.
4. **Arayüz** (`features/factory/`): tam ekran fabrika görünümü (FlowCanvas + palet +
   "Back to map"), kapı bloklarının görünümü; harita üst çubuğu (para, hız) üstte kalır.
   Arsa panelinde "Open factory", giren/çıkan satırları; harita simgesinde uyarı.
   Hiçbir yeni dosya 300 satırı geçmez.

## Adımlar (her biri ayrı teslim)

1. Veri: `Good`'un `ItemType`'tan türemesi, fabrika tarifleri ve blokları, kapı verisi.
   Mevcut testler geçer.
2. Fabrika içi simülasyon. Test `tools/factory_test.gd`: giriş stoğundaki Logs giriş
   kapısından Sawmill'e akar; Sawmill 10/dk Lumber üretir; çıkış kapısı çıkış stoğuna koyar;
   çıkış stoğu 50'de dolunca Sawmill durur (tıkanma); Mill 2 Wheat → 1 Flour; Splitter iki
   kola böler; giriş → çıkış doğrudan aktarma çalışır; aynı kurulum aynı sonucu verir.
3. Harita entegrasyonu: tarifsiz fabrika kurma, her malı kabul, iki stok, giriş kapısının
   kendiliğinden gelmesi, dakikalık giren/çıkan, uyarı. `flow_test.gd` güncellenir:
   orman → fabrika → köy zinciri editörle kurulmuş fabrikayla para kazandırır.
4. Arayüz: "Open factory" / "Back to map" / Esc, tam ekran editör, palet, kapı görünümü,
   hız düğmeleri görünür; arsa panelinde giren/çıkan; harita simgesinde uyarı.

## Kabul ölçütü

- Area1'de ormandan arsaya hat, arsaya fabrika, fabrikadan City A'ya hat kurulunca; fabrikayı
  açıp Logs giriş kapısını bir Sawmill'e, Sawmill'i bir "Output: Lumber" kapısına bağlayınca
  para birkaç dakika içinde artmaya başlıyor.
- Fabrikadan çıkış hattı yokken çıkış stoğu doluyor, içeride Sawmill duruyor ve haritada
  fabrika simgesinde uyarı yanıyor.
- Fabrikanın içindeyken üst çubukta para ve hız düğmeleri çalışıyor; haritaya dönünce
  hatlar çalışmaya devam etmiş oluyor.
- `factory_test.gd`, `flow_test.gd` ve tüm mevcut testler geçer (sim_test'teki 2 eski
  "Tikanma" hatası önceden de vardı). Eski oyun sahnesi hâlâ açılıyor.
