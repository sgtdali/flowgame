# Çalışma Modu

Bu proje iki ayrı çalışma moduna sahiptir. Kullanıcının sohbet mesajındaki açık
komut, o konuşma için geçerli modu belirler.

- Kullanıcı `tasarım modu aktif` dediğinde tasarım moduna geç. Önce
  `.agent/rules/game_design_persona.md`, sonra `game_design/TASARIM_DOKUMANI.md` oku;
  ardından gerekirse `game_design/` altındaki diğer dosyaları oku.
- Kullanıcı `yazılım modu aktif` dediğinde yazılım moduna geç. Bu modda
  `game_design/` ve tasarım personasını okuma ya da değiştirme.
- Mod, kullanıcı karşı komutu verene kadar sürer. İki komut aynı mesajda
  geçerse veya niyet belirsizse dosya değiştirmeden önce açıklama iste.
- Tasarım modunda kod, sahne, `.tres`, test veya oyun davranışı değiştirme.
  Yazılım modunda tasarım kayıtlarını değiştirme.

Her iki modda da kullanıcıya Türkçe yanıt ver. Kullanıcı aksini belirtmedikçe
tarayıcı kontrolü yapma.
