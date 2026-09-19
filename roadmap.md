# Iron & Ember — Geliştirme yol haritası

Son güncelleme: 16 Eylül 2026

Ürün yönü: [ANLAYIS.md](ANLAYIS.md). Bu plan mevcut üç aşamalı prototipi sağlamlaştırır; tüm maddeler için peşinen uygulama yetkisi veya kesin teslim tarihi oluşturmaz.

## 1. Şimdi ne yapmalıyız?

**Yeni node eklemeyi durdurup mevcut demir → elektrik → birleşme akışını aynı başlangıçtan ölçülebilir ve güvenilir hâle getirmeliyiz.**

Üç aşama içerik ve kod düzeyinde mevcut. Ancak `iron_progression_test.gd` yeni araştırma ön koşullarını ve güç ihtiyacını izlemiyor. Market geliştirmesiyle ilgili belge/kod farkı da var. Bu nedenle mevcut tabloya bakarak ilk birleşmenin dengeli olduğu söylenemez.

İlk somut teslim: aynı başlangıçtan üç aşamayı gerçek oyun kurallarıyla tamamlayan ölçüm ve doğruluk paketi. Bundan sonra sınırlı denge ayarı ve tek odaklı oynanış turu gelir.

## 2. Çalışma sırası

| Öncelik | Paket | Şimdiki durum | Çıkış koşulu |
|---|---|---|---|
| P0 | Mevcut davranışı ve karar farklarını sabitle | Tamamlandı (DESIGN.md "Paket A") | İçerik/kurallar tek karşılaştırma tablosunda |
| P0 | Güç, para, kayıt doğruluğu | Tamamlandı — `godot --headless ... sim_test.gd` çalıştırıldı, 35/35 kontrol geçti | Temel senaryolar otomatik doğrulanmış |
| P0 | Üç aşamalı ilerleme ölçümü | Tamamlandı — `iron_progression_test.gd` yeniden yazıldı ve çalıştırıldı, 5 rota da otomasyona ulaştı | Geçerli stratejiler aynı başlangıçtan tamamlanıyor |
| P1 | İlk bölümün ekonomik dengesi | Her iki bulgu da giderildi ve yeniden ölçüldü: Eritme yeniden tasarlandı (6 cevher → 1 külçe, süresiz, doğrudan madene bağlı), Jeneratör `max_instances=1` ile sınırlandı. "Karma" artık ölçülen en iyi strateji (1.738 altın/dk). Yan etki: açılışa varış süresi ~3× uzadı (bkz. DESIGN.md), henüz ayrıca ayarlanmadı | Küçük yatırım ve büyük açılış ödülü ölçülmüş |
| P1 | Hedef/gelir/güç okunabilirliği | Arayüz mevcut, kullanıcı doğrulaması yok | Oyuncu hedefi ve güçlenmeyi açıklayabiliyor |
| P1 | Kısa oynanış doğrulaması | Yeni üç aşama için açık | Hedeflenen ödül hissi değerlendirilmiş |
| P2 | Sonraki büyük açılış tasarımı | Henüz seçilmedi | Bağlantılı yeni olanak açıkça onaylanmış |
| P3 | Uzun oyun, prestij, çevrimdışı ilerleme | Ertelendi | İlk bölüm başarılı ve ihtiyaç gösterilmiş |

P0 çalışmalarında mevcut kullanıcı değişiklikleri geri alınmaz. Eski silinmiş dosyaları sırf eski testleri geçirmek için geri getirmek çözüm değildir.

## 3. Paket A — Mevcut davranış sözleşmesi

**Durum: Tamamlandı.** Sonuç DESIGN.md'de "Paket A — current behavior
contract" başlığı altında. Jeneratör adet sınırı bilinçli olarak açık
bırakıldı (Paket C/D'nin ölçümünü bekliyor); diğer maddeler karara bağlandı.

### Yapılacaklar

- Başlangıç parası, açık node'lar, yapı fiyatları, kaynak adet sınırları ve reçeteleri çıkar.
- Üç araştırmanın ön koşullarını ve kullanılabilir hâle gelme maliyetlerini listele.
- Manuel/otomatik tahsilatın kasa, market bakiyesi ve satış hızıyla ilişkisini yaz.
- Market satış geliştirmesi için tasarım niyeti ile güncel `sevkiyat.tres` farkını çöz: mevcut niyetin uygulanması mı, değiştirilmesi mi olduğu kayda geçsin. Eski +%100, sonraki +%20 ve devre dışı durumları karıştırılmasın.
- Jeneratör adet sınırını karar noktası olarak ele al. Sınırsız kopyalama, geliştirme ve hadde yatırımıyla karşılaştırılmadan yeni sınır uydurma.
- Güç birimini tanımla: kapasite, tick süresi, teslim edilen enerji karşılığı ve satış kesri. Oyuncu kW görüyorsa fiyat birimi de anlaşılır olsun.
- Güç paylaşımında birden fazla üretim tüketicisinin sırasını belgeleyip arayüzle çelişmediğini kontrol et.

### Çıkış koşulu

Bir araştırmanın satın alınmasıyla fiilen üretime başlaması farklı olaylar olarak tanımlanmış; test ve arayüz aynı kuralları kullanıyor olmalı.

## 4. Paket B — Ekonomi ve güç doğruluğu

**Durum: Tamamlandı, gerçekten çalıştırıldı.** Aşağıdaki 11 senaryonun
tamamı `tools/sim_test.gd`'de ayrı test fonksiyonları olarak var (13
fonksiyon, 26 yeni kontrol — bazı senaryolar iki fonksiyona bölündü). Yazarken
gerçek bir hata da bulundu ve düzeltildi: `FactorySim._run_powered_producer`'da
`energy_ticks` çıktı TIKALI olduğunda sınırsız birikiyordu (bkz.
`_test_power_blocked_output_does_not_overflow_energy`); tıkanıklık açılınca
bu, gerçekte karşılığı olmayan birden fazla parçanın bir anda boşalmasına yol
açardı. Düzeltme `progress_ticks`'in zaten kullandığı "eşiği aşma" desenine
uyduruldu.

Kullanıcı `C:\Users\tvural.REPKON\Desktop\Godot_v4.6.1-stable_win64.exe`'yi
gösterdi. Çalıştırıldı:

```powershell
godot --headless --path . --script res://tools/sim_test.gd
```

İlk koşumda 34/35 geçti; tek KALDI (`consumed_total` bir üretici istasyonda
sıfır çıktığı için) test kodundaki YANLIŞ varsayımdı — `consumed_total`
tasarım gereği yalnızca Sevkiyat/Ar-Ge Laboratuvarı'nda anlamlı, üretici
istasyonlarda hiç artmıyor (bkz. `SimStation.consumed_total`
dokümantasyonu). Kontrol düzeltildi (yalnızca `produced_total > 0` bakıyor),
ikinci koşumda **35/35 kontrol geçti**.

Mevcut `tools/sim_test.gd` referans hattında jeneratör/hadde bağlantıları içeriyor. Bu, aşağıdaki bütün özel senaryoların test edildiği anlamına gelmez. Test kapsamını incele; gerekli eksikleri hedefli tamamla.

| Senaryo | Doğrulanacak davranış | Kapsayan test fonksiyonu |
|---|---|---|
| Yalnız jeneratör ve satış | Demir olmadan gelir; kapasite sınırına uygun satış | `_test_power_solo_generator_sale` |
| Tam güçlü hadde | Reçeteye uygun külçe tüketimi ve levha üretimi | `_test_power_full_mill_produces` |
| Kısmi / sıfır güç | Orantılı yavaşlama / ilerlememe; sahte ürün yok | `_test_power_zero_power_no_progress`, `_test_power_partial_slows_proportionally` |
| Külçe yok | Güç tüketimi veya satış fırsatı kaybı kuralla tutarlı | `_test_power_no_ingots_frees_capacity_for_sale` |
| Çıktı tıkalı | Üretim/güç isteği tutarlı, tampon taşması yok | `_test_power_blocked_output_does_not_overflow_energy` (regresyon bulundu ve düzeltildi) |
| Satış ve üretim birlikte | Ayrılan toplam güç kaynak kapasitesini aşmıyor | `_test_power_production_and_sale_share_capacity` |
| Çoklu tüketici/satış noktası | Bağlantı çoğaltarak güç veya para yaratılmıyor | `_test_power_multiple_sale_points_split_not_duplicate`, `_test_power_consumer_cannot_double_connect` |
| Bağlantı değişimi | Eski bağlantı tüketmeye/satmaya devam etmiyor | `_test_power_disconnect_stops_delivery` |
| Tekrar tahsilat | Para ikinci kez eklenmiyor | `_test_power_collect_does_not_double` |
| Otomasyona geçiş | Birikmiş para bir kez aktarılıyor, satış hızı tıklamadan etkilenmiyor | `_test_power_automation_transition_sweeps_once` |
| Kaydet/yükle | Yarım üretim ve satış kesri dahil kesintisiz koşuma eşdeğer | `_test_power_save_load_mid_batch` (mevcut `_test_save_load` da güç bağlantılarını zaten içeriyor) |

Zaman ölçeği değişince ekonomi aynı oyun süresi için aynı sonucu vermeli. Tick çözünürlüğü değişimi desteklenecekse güç/enerji hesabının tick hızına bağımlılığı ayrıca test edilir; desteklenmiyorsa varsayım açıkça sabitlenir.

### Kayıt geçişi

- Eski kayıt açılabiliyor diye kayıpsız sayma.
- Kaldırılan istasyon ve ürünleri envanterle; kullanıcıya görünür özet/iade/dönüştürme politikasını belirle.
- Eski güçsüz hadde kaydının yeni kurallarda nasıl çalışabilir hâle geleceğini tanımla.
- Geçişi iki kez uygulamak fazladan para veya araştırma kazandırmamalı.
- Kaynak kaydı yerinde ezmeden bir kopyayla doğrula.

Çıkış: çalıştırılan komut, kontrol sayısı, sonuç ve kapsamı kayıtlı olmalı.

**Sonuç: `godot --headless --path . --script res://tools/sim_test.gd`
çalıştırıldı, 35/35 kontrol geçti** (bkz. yukarısı). Kapsam: determinizm,
kaydet/yükle (malzeme VE güç), eski tarım kaydı göçü, tıkanma/geri tıkanma,
aç/tıkalı ayrımı, ve bu paketin 11 güç senaryosu. Kaydet/yükle testleri artık
jeneratör/hadde/borsa bağlantılarını ve yarım enerji birikimini de kapsıyor.
Kapsam DIŞI kalanlar: gerçek kayıt dosyasından (kullanıcının eski bir
`.json` kaydından) yükleme denenmedi, yalnızca `to_dict()`/`from_dict()`
bellek içi JSON gidiş-dönüşü test edildi; "kaldırılan istasyon/ürünlerin
kullanıcıya görünür özet/iade politikası" tanımlanmadı (şu an sessizce
atılıyorlar, bir bildirim yok).

## 5. Paket C — Gerçek üç aşamalı ilerleme aracı

**Durum: Tamamlandı, gerçekten çalıştırıldı.** `tools/iron_progression_test.gd`
tamamen yeniden yazıldı ve `godot --headless --path . --script
res://tools/iron_progression_test.gd` ile koşturuldu. Beş rota (Biriktir,
Maden odaklı, Borsa odaklı — eski "Satış odaklı"nın yerine, bkz. Paket A —
Karma, Jeneratör çoğalt) da aynı başlangıçtan Elektrifikasyon → Elektrikli
Hadde → Otomasyon sırasını tamamladı, hiçbiri tıkanmadı. Tam tablo ve iki
somut bulgu (madenin sürdürülebilir gelire etkisi ~0; sınırsız jeneratör
çoğaltma tek başına diğer her stratejinin ~2 katı gelir veriyor) DESIGN.md'de
"Paket C — measured three-stage progression" başlığı altında.

Kapsam dışı kalan: aşağıdaki "Karşılaştırılacak stratejiler" listesindeki
"Elektrik odaklı" ve "Birleşmeye yönel" ayrı rota olarak koşulmadı (zorunlu
sıra zaten her rotada iki kolu da açıp birleştiriyor); özellikle
**birleşmenin ayrı-satışa göre avantajını izole ölçen bir "haddesiz" karşı
rota henüz yok** — bu, Paket D'nin ilk açık işi olarak aşağıda not edildi.

### Mevcut aracın önce giderilecek uyumsuzlukları (ÇÖZÜLDÜ)

`tools/iron_progression_test.gd` içinde:

- `OPENING_TOTAL` yalnız eski hadde açılışı toplamını içeriyor.
- PRESLEME araştırması elektrifikasyon alınmadan deneniyor.
- Sürdürülebilir gelir ölçümünde haddeye jeneratör bağlanmıyor.
- Otomasyon araştırması alınmadan `auto_collect` açılıyor.
- Satış yatırımı etkin olmayan markette deneniyor.
- `longest_wait_ticks` tahsilatlar arası süreyi ölçüyor; oyuncunun anlamlı karar bekleme süresini değil. Bu metriği karar ritmi diye raporlama.

### Araç nasıl çalışmalı?

- Gerçek `FactorySim`, `ProgressionState`, kataloglar ve güncel maliyetler kullanılsın.
- Geçerli araştırma/kaynak sınırı/bağlantı/harcama kuralları atlanmasın.
- Aynı başlangıçtan çalışsın; yeni oyun ve eski kayıt senaryoları ayrı olsun.
- Tahsilat aralığı yapılandırılabilir olsun. Aralığın oyun saniyesi mi gerçek saniye mi olduğu açıkça yazılsın.
- Oyuncu işlem süresi varsayımı kullanılacaksa simülasyon bu sırada da aksın; süreyi sonradan iki kez ekleme.
- Geçersiz plan, ilerleme yokluğu veya süre sınırında açıklayıcı biçimde dursun. Bozuk hatta dakikalarca koşup sonucu denge bulgusu sayma.
- Tarih, içerik parametreleri, senaryo adı ve başlangıç durumu rapora yazılsın. Deterministik sonuç tekrar üretilebilsin.

### Karşılaştırılacak stratejiler

| Strateji | Davranış |
|---|---|
| Biriktir | Zorunlu yapı ve açılışlar dışında küçük yatırım yok |
| Maden odaklı | Uygun seviyeye kadar üretim yatırımı, sonra biriktirme |
| Satış odaklı | Etkinleştirilen satış yatırımını kullanma, sonra biriktirme |
| Karma | Küçük yatırımları farklı sıralarla alma ve durma noktası seçme |
| Elektrik odaklı | İkinci kol açıldıktan sonra jeneratör/satış yatırımı |
| Birleşmeye yönel | İki kolu çalıştırıp haddeye biriktirme |

Jeneratör çoğaltma geçerliyse ayrıca aday olmalı; araca alınmayarak ekonomik üstünlüğü gizlenmemeli. Bütün kombinasyonların sonsuz taranması değil, açık ve sınırlı plan kümesi hedeflenir.

### Kaydedilecek olaylar

1. İlk ürün satışı ve ilk tahsilat.
2. Her küçük geliştirme: zamanı, bedeli, seviye, bakiye.
3. Elektrifikasyonun satın alınması.
4. Jeneratör ve satış noktasının kurulması, ilk elektrik satışı.
5. Hadde araştırmasının satın alınması ve tesisin kurulması.
6. İlk levha satışı ve yerleşmiş birleşik gelir.
7. Otomasyonun alınması ve otomasyondan sonraki tahsilat davranışı.

Tek tabloda toplam harcama, açılış/çalışmaya başlama zamanı, her kolun geliri, güç dağılımı ve toplam gelir gösterilsin. Oyun süresi ile 4× karşılığı ayrı sütunlar olsun. Kullanıcı süreleriyle karşılaştırmada aynı başlangıç, hedef ve hız tanımı sağlansın.

### Çıkış koşulu

En az bir geçerli rota üç aşamayı ve otomasyonu tamamlıyor; farklı yatırım planları aynı hedeflere göre karşılaştırılıyor; başarısız koşumlar ekonomik denge başarısı olarak sunulmuyor.

**Sağlandı: 5/5 rota tamamlandı, hiçbiri tıkanmadı.** Not: araç şu an
tıkanma durumunu da doğru raporluyor (`stall_reason` ile) ama bu turda hiç
tetiklenmedi — tıkanma yolunun kendisi ayrıca test edilmedi (örn. tavan çok
düşük ayarlansaydı ne olurdu). Kabul edilebilir bir sınır olarak not edilir.

## 6. Paket D — Denge ayarı

İlk hedef süre sabitlemek değil, doğru ekonomik ilişkileri sağlamaktır.

### Sağlanacak ilişkiler

- Birkaç erken yatırım, hazırlık dahil büyük hedefe varışı hızlandırabilir.
- Bütün seviyeleri almak her durumda en iyi yol değildir.
- Hiç küçük yatırım almadan ilerlemek mümkündür; yapay zaman kapısı veya zorunlu geliştirme şartı yatırım avantajı diye sayılmaz.
- Elektrik kolu kendi başına hissedilir gelir sağlar.
- Hadde, aynı kaynakları ayrı satmaya göre sürdürülebilir toplam gelir avantajı sağlar.
- Otomasyon rahatlatır; gücü artıran büyük açılışın yerine geçmez.
- Jeneratör çoğaltmak veya elektrik fiyatını geliştirmek, haddeciliği sürekli anlamsızlaştırıyorsa bu durum açıkça raporlanır.

### Hesaplar

```text
Geri dönüş süresi ≈ yatırım maliyeti / gerçek ek gelir hızı
Hedefe net zaman kazancı = yatırımsız hedef süresi − yatırımlı hedef süresi
Birleşme kazancı = yerleşmiş birleşik gelir − eşdeğer ayrı satış geliri
```

Geri dönüş hesabı karar için yardımcıdır; asıl karşılaştırma bütün hazırlık ve harcamaları içeren gerçek senaryodur. Tampon dolumu/boşalması ölçüm penceresinden ayrılmalı, aynı altyapı seviyeleri karşılaştırılmalıdır.

### Arama yöntemi

1. Mevcut değerlerle başlangıç raporu üret.
2. Küçük yatırım taban maliyeti/artışı, açılış ve yapı maliyetleri, elektrik fiyatı ve hadde dönüşüm değerlerini dar aralıklarda tara.
3. Önce sadece gerekli parametreleri değiştir; bütün ekonomiyi aynı anda oynatma.
4. Birkaç iyi adayı farklı tahsilat aralıkları ve küçük yatırım sıralarıyla yeniden değerlendir.
5. Uygun aday yoksa “en küçük/en büyük” değeri otomatik başarılı ilan etme; çatışan koşulu açıkla.
6. Seçilen değerleri uygula, aynı senaryoyu yeniden çalıştır ve raporla eşleşmesini doğrula.

%20–35 gibi sabit bir avantaj bandı bağlayıcı değildir. Büyük kazanç tek başına yanlış değildir; kazancın bedeli, süresi, sürdürülebilirliği ve büyük açılış hissi birlikte değerlendirilir.

Çıkış: mevcut ve önerilen değerler, alternatifler ve gerekçe kayıtlı; sayıların keyfi kanıtlamadığı açık.

## 7. Paket E — Oyuncunun hedefi ve sonucu okuması

### Görünmesi gerekenler

- Harcanabilir kasa ve tahsil edilebilir para ayrı.
- Gerçek toplam gelir/dk; gerektiğinde demir ve elektrik katkısı.
- Madenin mevcut ve sonraki kapasitesi, geliştirme bedeli.
- Jeneratörün toplam gücü, üretime verilen ve satışa giden güç.
- Haddenin güç/malzeme bekleme durumu; gerçek çıktı hızı.
- Sıradaki büyük açılışın işlevi, kilit bedeli ve ek kurulum bedeli.
- Açılış sonrası kalıcı fark; kararsız/geçici akışsa bunu belirten sunum.

Yeni bir muhasebe ekranını zorunlu kılma. Oyuncu temel yatırım kararını mevcut node'lar ve kısa bir hedef görünümüyle verebilmeli.

### Küçük kullanılabilirlik hedefi

Oyuncu şu üç soruyu cevaplayabilmeli:

1. Şu an hangi büyük hedefe hazırlanıyorum?
2. Bu küçük yatırımı yaparsam ne değişiyor?
3. Haddeyi çalıştırınca iki kolum birlikte ne kazandırdı?

Çıkış: çalışan panel bulunması değil, gerçek oynanışta bu bilgilerin anlaşılması. Tarayıcı veya uygulama kontrolü bu belgeyle ayrıca talep edilmiş sayılmaz.

## 8. Paket F — Tek odaklı oynanış turu

Otomatik araçlar sayısal açıdan zayıf adayları eledikten sonra kullanıcıya bir aday sunulur. Her ufak sayı değişiminde tekrar 15 dakika oynama talep edilmez.

Yerel olay günlüğü veya kısa elle notlarla şunlar kaydedilsin:

- İlk yatırım isteği ne zaman doğdu?
- Elektrik kolu açıldığında “yeni gelir kaynağı kazandım” hissi oluştu mu?
- Oyuncu birleşmeden önce ikinci kolun bağımsız faydasını gördü mü?
- Hadde çalışınca gelir artışını fark etti mi?
- Tahsilat etkileşim mi verdi, tekrarlı yük mü oldu?
- Beklerken hedef çekici miydi, yoksa ilerleme belirsiz miydi?

### Sonuca göre hareket

| Gözlem | Önce incelenecek konu |
|---|---|
| Açılışı aldı ama kuramadı | Toplam kurulum bedeli ve görünürlüğü |
| Hadde kuruldu, kazanç görünmedi | Güç/malzeme/satış fırsat maliyeti ve gerçek gelir |
| Jeneratör açıldıktan hemen sonra ikinci kol fark edilmeden geçildi | Açılışlar arası ekonomik mesafe ve ödül sunumu |
| Sadece tahsilat tıklaması bekleniyor | Yatırım erişimi ve otomasyon zamanlaması |
| Tek gelir yöntemi bütün diğerlerini eziyor | Strateji karşılaştırması ve yatırım ufku |
| Büyük açılış güçlü hissettirdi, devam merakı oluştu | Sonraki büyük aşamanın tasarımına geç |

Kullanıcı keyfi tek turda evrensel kanıt sayılmaz; ancak mevcut prototipin bir sonraki kararına yeterli somut geri bildirim verebilir.

## 9. Paket G — İlk bölümden sonra ne tasarlanabilir?

Bu bölüm **onaylanmamış seçeneklerdir**; otomatik uygulama listesi değildir.

En güçlü araştırılacak yön: demir + elektrikle üretilen bir sanayi parçasının, önceki maden veya jeneratörün teknolojik gelişimine katkı vermesi.

```text
Demir kolu + elektrik kolu
          ↓
Birleşik işleme
          ↓
Gelecekte seçilecek sanayi ürünü
          ↓
Mevcut üretim kaynaklarına kalıcı fayda
```

Ürün adı, tüketim modeli, araştırma puanı veya bir yükseltme malzemesi olması henüz seçilmedi. Amaç her ürünü yeni stok takibine çevirmek değildir.

Yeni aşama tasarımına geçmeden önce:

- İlk üç aşama ölçülmüş ve oynanmış olsun.
- Yeni ödülün mevcut işletmeyle bağı açık olsun.
- Yeni para birimi veya sektör eklemek gerekip gerekmediği sorgulansın.
- Oyuncuya getirilen yeni takip yükü, kazanılan olanakla gerekçelendirilsin.
- Tasarım kullanıcıyla netleşmeden kapsamlı içerik veya kod yazılmasın.

## 10. Şimdilik yapılmayacaklar

- Tarım/odunculuk/işçi/gıda sistemini geri getirmek.
- Ayrı yakıt sektörü, elektrik şebekesi kayıpları veya ayrıntılı gerçekçilik.
- Aynı ürüne alternatif reçete deneyini yeniden başlatmak.
- Her aşamada zorunlu hat optimizasyonu hedeflemek.
- Yalnızca araştırma miktarını artırarak oyun süresi uzatmak.
- AGI benzeri çok girdili final, prestij veya çevrimdışı sistem eklemek.
- Tüm görselleri/markayı yeniden yapmak veya eski içerik sayısına ulaşmaya çalışmak.
- Önceden belirlenmiş 60 dakika veya videolardaki 7–8 dakikayı doğrulanmış hedef kabul etmek.

## 11. İzlenebilirlik ve teslim standardı

Her paket sonunda kısa kayıt tutulur:

| Alan | İçerik |
|---|---|
| Değişiklik | Hangi oyuncu sorunu çözüldü? |
| Parametreler | Önceki/yeni değerler ve gerekçe |
| Senaryo | Başlangıç, hedef, yatırım politikası, tahsilat aralığı |
| Ölçüm | Oyun zamanı, 4× karşılığı, sürdürülebilir gelir |
| Doğrulama | Gerçekten çalıştırılan komutlar ve sonuçları |
| Sınır | Test edilmeyen veya yalnız varsayılan konu |
| Sonraki karar | Devam etmek için hangi kanıt eksik? |

Mevcut araç adları:

```powershell
godot --headless --path . --script res://tools/sim_test.gd
godot --headless --path . --script res://tools/iron_progression_test.gd
```

İkisi de çalıştırıldı. `sim_test.gd`: 35/35 kontrol geçti (bkz. Paket B).
`iron_progression_test.gd`: yeniden yazıldı, 5/5 rota Otomasyona ulaştı,
tıkanma yok (bkz. Paket C). Kullanılan yürütücü:
`C:\Users\tvural.REPKON\Desktop\Godot_v4.6.1-stable_win64.exe`.

## 12. Tamamlanma kontrol listesi

- [x] Oyun yönü ve kapsam kullanıcıyla netleşti.
- [x] Tasarım anlayışı ve yol haritası kök klasörde kayda geçti.
- [x] Üç aşamanın içerik/kod karşılıkları okuma üzerinden tespit edildi.
- [x] Satış geliştirmesi ve güç birimi farkları çözüldü; jeneratör sınırı bilinçli olarak açık bırakıldı (bkz. DESIGN.md).
- [x] Güç/para/kayıt senaryoları doğrulandı (`sim_test.gd`, 35/35 kontrol geçti).
- [x] İlerleme aracı güncel üç aşamayı izliyor (`iron_progression_test.gd` yeniden yazıldı ve çalıştırıldı).
- [x] Aynı başlangıçtan strateji karşılaştırması üretildi (5 rota, bkz. DESIGN.md).
- [ ] Birleşmenin sürdürülebilir avantajı ölçüldü — EKSİK: haddeyi hiç kurmayan, yalnızca külçe+elektriği ayrı satan bir 6. "karşı rota" henüz yok; mevcut 5 rotanın hepsi haddeyi zorunlu olarak kuruyor, o yüzden "birleşme ayrı satışa göre ne kadar iyi" izole ölçülmedi.
- [ ] Hedef ve güç paylaşımı oyuncuya anlaşılır gösteriliyor.
- [ ] İlk üç aşama kullanıcı tarafından oynandı ve değerlendirildi.
- [ ] Sonraki büyük açılış ayrıca seçildi.
