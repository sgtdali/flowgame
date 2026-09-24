# CLAUDE.md

@AGENTS.md

Yukarıdaki çalışma modu kuralları (tasarım modu / yazılım modu) Claude Code için de aynen geçerlidir.

## Proje

- Motor: Godot 4.6, dil: GDScript. Tipli değişken kullan (`untyped_declaration` uyarısı açık).
- Ana sahne: `res://features/worldmap/WorldMap.tscn` (eski Iron & Ember sahnesi `res://features/game/game.tscn` duruyor, açılışta açılmıyor)
- Klasör düzeni:
  - `features/<özellik>/` → sahne + o sahnenin görüntü/etkileşim scriptleri
  - `data/` → Resource sınıfları, `data/<tür>/*.tres` → veri
  - `sim/` → arayüzsüz oyun kuralları ve simülasyon
  - `common/` → paylaşılan yardımcılar
  - `tools/` → headless test ve üretim scriptleri
- Görevler `docs/tasks/` altında durur. Kullanıcı bir görev dosyası verdiğinde önce onu oku.

## Kod kuralları

- Oyun kuralı (para, kilit açma, talep, üretim) `sim/` veya `data/` içinde yazılır; `features/` altındaki UI kodu kural hesaplamaz, sadece gösterir ve çağırır.
- Yeni bir script 300 satırı geçecekse böl. `sim/factory_sim.gd` ve `features/game/game_controller.gd` zaten büyük: bunlara yeni sorumluluk ekleme, yeni dosya aç.
- Yeni oyun verisi: önce `data/` altında Resource sınıfı, sonra `.tres` dosyaları. Sayıları koda gömme.
- Godot komut satırında (PATH'te) yok; aramadan şu dosyayı kullan (çıktıyı terminale basan konsol sürümü):
  `C:\Users\tvural.REPKON\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe`
  Aşağıdaki komutlarda `godot` yerine bu yolu yaz.
- Mevcut testleri bozma. Her görevin sonunda çalıştır:
  - `godot --headless --path . --script res://tools/sim_test.gd`
  - `godot --headless --path . --script res://tools/iron_progression_test.gd`
  - Görevin kendi testi varsa onu da.

## Kullanıcıyla çalışma

- Kullanıcı kod bilmiyor. Her adımın sonunda Türkçe, kod içermeyen kısa bir özet yaz:
  1. Ne değişti (1–3 madde)
  2. Godot'da neyi açıp neye tıklayarak test edeceği
  3. Bilinen eksik ya da sonraki adım
- Görevleri küçük adımlarla yap; bir adım bitmeden sonrakine geçme.
- Adım çalışıp kullanıcı onaylayınca commit öner; commit'i kullanıcı onayıyla at.
- Emin olmadığın bir tasarım konusunda varsayım yapma, sor.
