---
tur: yonetim
durum: etkin
guncelleme: 2026-10-20
---
# Çalışma düzeni

## Vault'un amacı

Bu klasör zamanla güncellenen tasarımın çalışma alanıdır. Her konuşmanın yeni bir uzun tasarım dokümanı üretmesi yerine mevcut konu notları geliştirilir. Ham konuşma, güncel kural, karar gerekçesi ve açık soru birbirinden ayrılır.

## Bilgi durumları

| Durum | Anlamı |
|---|---|
| Onaylı | Kullanıcının açıkça seçtiği karar; dayanağı karar defterinde bulunur. |
| Yön olarak olumlu | Kullanıcı yaklaşımı olumlu karşılamıştır; ayrıntılar kesinleşmemiştir. |
| Öneri | Tartışmaya açık model, kabul edilmiş kural değildir. |
| Açık | Seçim yapılmamıştır veya ayrıntı eksiktir. |
| Varsayım | Çalışma için kullanılan geçici kabul; açıkça işaretlenir. |
| Tarihsel | Önceki konuşma veya terk edilmiş yaklaşım; güncel otorite değildir. |
| Karma | Aynı notta farklı durumlarda bilgiler vardır; bölüm açıklamaları esas alınır. |

“Onaylı” ile “oynanışta doğrulandı” farklıdır. Bir karar onaylı olup hiç test edilmemiş olabilir. Test sonucu varsa yöntemi, tarihi ve kanıtı ayrıca kaydedilir.

## Güncelleme akışı

1. Yeni fikir konuşulunca ilgili konu notuna **öneri** olarak ekle; gerekirse açık soruya bağla.
2. Kullanıcı açık seçim yaptığında karar defterine sabit kimlikli kayıt ekle.
3. Kararın asıl konu notunu ve gerekiyorsa güncel tasarım özetini güncelle.
4. Çözülen açık soruyu karar kimliğiyle kapat. Eski kararı sessizce silme; “yerine geçti” bağlantısı kur.
5. Canvas'taki kısa özet veya bağlantı etkilendiyse onu da güncelle.
6. Anlamlı değişikliği değişiklik günlüğüne tek satırla kaydet.

Kullanıcının doğrudan “aktar”, “kaydet”, “uygula” veya dosyaları güncelleme talebi, o aktarımı yapmak için yetkilendirmedir. Tartışma sırasında asistanın önerisi kullanıcı kararı gibi yazılmaz.

## Dosya ve bağlantı kuralları

- Bir konunun ayrıntısı tek Markdown notunda tutulur; tekrar yerine wikilink kullanılır.
- Not başında `tur`, `durum`, `guncelleme` alanları bulunur. Tarih, son anlamlı düzenleme tarihidir.
- Dosya taşırken veya ad değiştirirken Markdown bağlantıları ve canvas `file` yolları birlikte güncellenir.
- Canvas dosya yolları vault köküne göredir; Windows'a özel mutlak yol yazılmaz.
- `Kaynaklar/01 - Aktarılan Sohbet.md` ham kayıttır. Yeni kurallarla yeniden yazılmaz.
- `Şablonlar` klasörü Obsidian'ın yerleşik Templates eklentisine tanımlıdır. Harici eklenti gerekmez.

## Canvas ile çalışma

Ana pano bir konu haritasıdır. Alt panolar sistemlerin ilişkilerini gösterir. Dosya kartı doğrudan asıl nota açılır; metin kartları açıklama ve sorular içindir. Bağlantı okları tasarım ilişkisini anlatır, kendi başına simülasyon kuralı sayılmaz.

Serbest fikirleri “öneri” veya “açık” diye etiketle. Özellikle örnek üretim zincirini onaylı reçete kataloğu sanma. Canvas düzeni otomatik yeniden üretilmeyecek; elle yerleştirdiğin kartlar korunarak düzenlenmelidir.

## Birlikte düzenleme ve koruma

Aynı canvas'ı Obsidian ve dışarıdaki bir dosya düzenleyicisinde eşzamanlı değiştirmek kayba yol açabilir. Dışarıdan düzenleme yapılacağı sırada ilgili pano üzerinde eşzamanlı elle çalışma yapma. Obsidian otomatik kaydı sürüm yedeği yerine geçmez. Büyük değişikliklerden önce klasör kopyası veya kullanıcı tarafından seçilmiş bir sürümleme yöntemi kullan.

## Kapsam

Bu alan tasarım içindir. Buradaki kabul bir kod geliştirme emri değildir. Uygulama planlanırken ayrı kapsam ve doğrulama kanıtı yazılır. Mevcut eski oyun kodunun veya eski şehir ekonomisinin yeni tasarımda geçerli olduğu varsayılmaz.
