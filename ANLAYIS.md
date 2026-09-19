# Iron & Ember — Tasarım anlayışı

Son güncelleme: 16 Eylül 2026

Durum: Kullanıcıyla kararlaştırılan oyun yönü ve mevcut prototipin okuma üzerinden durum kaydı. Bu belge hazırlanırken oyun çalıştırılmadı, ekonomi testleri yürütülmedi ve oyun kodu değiştirilmedi.

İlgili belge: [Geliştirme yol haritası](ROADMAP.md).

## 1. Oyuncuya verilen söz

> Küçük bir demir işletmesi kurarım. Kazancımla küçük yatırımlar yaparım, büyük bir teknolojiyi sonunda açarım. Yeni üretim olanağım önce kendi başına kazandırır; sonra eski üretimimle birleşerek işletmemi belirgin biçimde güçlendirir.

Ana ödül cümlesi:

> Nihayet! Şimdi çok daha güçlü üretim yapıyorum ve bir sonraki büyük hedefe yaklaştım.

Oyun idle/incremental ağırlıklıdır. Node tabanlı akış, üretim olanaklarını görünür ve birbirine bağlanabilir yapar. Sürekli mikro yönetim, her aşamada yeniden fabrika kurma veya oyuncuyu zorunlu optimizasyona sürükleme ana amaç değildir.

Beklemek doğal bir parçadır. Anlamsız bekleme ile hedefe doğru birikim farklıdır: oyuncu neyi beklediğini, açılınca ne kazanacağını ve elindeki parayla daha erken ulaşma olasılığını anlamalıdır.

## 2. Tema ve kapsam

Kararlaştırılan alan **demir merkezli sanayi işletmesi**dir. Başlangıç küçük bir maden ve eritme hattıdır; orta çağda kalma zorunluluğu yoktur. İşletme mekanikleşme ve elektrifikasyon üzerinden büyüyebilir.

- Demir ana malzeme alanıdır.
- Elektrik ikinci bağımsız üretim ve gelir koludur; ayrıca demir işleme kapasitesi sağlar.
- Tarım, odunculuk ve ilgisiz sektörlerle yatay genişleme hedeflenmez.
- İşçi, işe alma, gıda ve açlık yönetimi aktif tasarımdan çıkarılmıştır.
- Jeneratör için ayrı yakıt madenciliği veya yakıt stok yönetimi ilk kapsamda yoktur.
- Gerçek sanayi tema ve içerik kaynağıdır; bütün fiziksel süreçleri birebir modellemek zorunlu değildir.
- Oyun adı şimdilik Iron & Ember olarak kalır. Yeni marka adı kararlaştırılmadı.
- Oyun arayüzü mevcut İngilizce dilini korur; tasarım belgeleri Türkçedir.

## 3. Birbirini tamamlayan üç gelişim ölçeği

| Ölçek | Oyuncunun eylemi | Beklenen karşılık |
|---|---|---|
| Kısa vadeli | Geliri tahsil et, erişilebilir bir geliştirme al | Aynı işletmede okunabilir küçük kazanç |
| Büyük açılış | Yeni kapasite/üretim kolunun kilidini aç ve kur | Önceden sahip olmadığı gelir olanağı |
| Birleşme | İki mevcut kolu ortak bir tesiste kullan | Önceki yatırımların birlikte daha değerli olması |

Küçük geliştirmelerin maliyetleri katlanabilir; getirileri aynı hızda katlanmak zorunda değildir. Erken seviyeler cazipken ileri seviyelerde biriktirip yeni aşamaya geçmek anlam kazanmalıdır.

Büyük açılış sırf yeni bir ürün adı, yeni kutu veya gizlenmiş bir satış çarpanı değildir. Yeni bir bağımsız kapasite, eski sistemle yeni ilişki veya işletmenin önceki sınırlarını değiştiren bir olanak sağlamalıdır.

Her node'un karmaşık tercih sunması gerekmez. Fakat her büyük aşamanın üretim ağı içindeki görevi açıklanabilmelidir.

## 4. Kararlaştırılmış ilk üç aşama

### Aşama A — Demir kolu

```text
Iron Mine → Smelting → Market / Collect
```

Oyuncu cevheri çıkarır, külçeye dönüştürür ve satar. Satış geliri erken oyunda markette birikir; tahsil edildiğinde harcanabilir kasaya geçer.

- Ana kapasite yatırımı madendedir.
- Satış değeri geliştirmesi kısa vadeli ikinci yatırım seçeneği olarak tasarlanmıştır; güncel uygulama farkı Bölüm 10'da kayıtlıdır.
- İlk birkaç yatırımın faydası, görünmeyen ara işlem kapasitesine takılıp kaybolmamalıdır.
- Kısa hat hedefi yaklaşık 3–5 node'dur. Tahsilat aynı node üzerindeyse sırf dört kutu olsun diye yeni node eklenmez.
- Kaynak node sayısı sınırlı olur; mevcut kaynağı geliştirmek temel büyüme yoludur. Madenin mevcut sınırı birdir.

### Aşama B — Bağımsız elektrik kolu

```text
Generator → Power Exchange / Collect
```

Elektrifikasyon yeni gelir kolunu açar. Jeneratör demir ürünlerine ihtiyaç duymadan elektrik üretir ve bu kapasite satılabilir.

Bu aşamanın ödülü, önceki hattı bırakmadan ikinci bir işletme edinmektir. Oyuncu bu kolu kendi başına çalışırken görme fırsatı bulmalıdır. Sadece araştırma ağacında elektrifikasyon satın almak, bu deneyimi yaşadığı anlamına gelmez.

Elektrik stok ürünü değildir. Üretim ve tüketim kapasitesi olarak gösterilir. Kullanılmayan güç yalnızca bağlı satış noktasında satılabilir; bağlantısız kapasite para veya gelecekte kullanılacak elektrik biriktirmez.

### Aşama C — İlk birleşme

```text
Smelting ── külçe ──┐
                    ├─ Electric Rolling Mill → Levha satışı
Generator ── güç ───┘
     └─ kullanılmayan kapasite → Power Exchange
```

Elektrikli hadde külçe ve güç alır, levha üretir. Burada levhanın anlamı yalnızca farklı satış etiketi değildir: iki bağımsız yatırım ilk kez aynı üretime katkı sağlar.

- Külçe tüketilen malzemedir; elektrik çalışma kapasitesidir.
- Sıfır güçte hadde ilerlemez. Yetersiz güçte üretim orantılı yavaşlar.
- Tam gereksinimin üzerindeki güç otomatik olarak sınırsız hız sağlamaz.
- Külçe olmadan elektrik tek başına ürün üretemez.
- Çalışabilen tesis önce gereken gücü alır, kalan kapasite satışa gider.
- Tek kapasite aynı anda hem tamamen satılamaz hem tamamen üretimde kullanılamaz.
- İlk kapsamda manuel güç oranları veya karmaşık öncelik menüleri yoktur.
- Oyuncu bağlantıyı kesip ayrı satışa dönebilir.

Birleşme kazancı aynı maden, jeneratör ve geliştirme seviyelerinde ayrı satışla karşılaştırılır:

```text
Ayrı gelir = külçe satışı + elektrik satışı
Birleşik gelir = levha satışı + kalan elektriğin satışı + varsa kalan külçe satışı
Birleşme avantajı = birleşik gelir − ayrı gelir
```

Levhanın külçeden pahalı olması tek başına yeterli değildir. Tüketilen elektriğin vazgeçilen satış geliri ve tesis yatırımı da hesaba katılır.

## 5. Tahsilat, otomasyon ve araştırmanın görevi

Tahsilat, oyuncuya başlangıçta doğrudan etkileşim ve yeniden yatırım anı verir. Satış hızını hesaplayan sayaç, tahsilat tıklamasını yeni satış saymamalıdır.

Otomasyon oyuncunun daha önce yaptığı işi devralan rahatlama ödülüdür. Tek başına büyük üretim sıçramasının yerine geçmez. Gereksiz sık tahsilat istemek oyun derinliği sayılmaz.

İlk üç aşamadaki teknolojiler para ile açılır. Açılış bedeli ile çalışır hâle getirme bedeli birlikte görünür olmalıdır. Örneğin jeneratör teknolojisini satın almak, jeneratör ve satış noktasını ücretsiz edinmek değildir.

Önceki malzeme teslimatlı araştırma deneyi, bu başlangıç için zorunlu değildir. Gelecekte ortak araştırma puanı veya malzemeli araştırmanın geri gelmesi kararlaştırılmadı. Yeni bir amaç varsa ayrıca değerlendirilecektir.

## 6. Kullanıcı oynanışından öğrendiklerimiz

Bu gözlemler farklı eski prototip sürümlerine aittir; güncel sürüm için ölçüm yerine geçmez.

| Bildirilen deneyim | Tasarıma etkisi |
|---|---|
| Gıda ve demir hatları kurulunca devam etmek için amaç hissedilmedi | Sıradaki hedef ve ödül görünür olmalı |
| İki girdili node açılınca çalışan hattı değiştirmek keyif verdi | Eski yatırımları yeni amaçta birleştirmek değerlidir |
| Tek hattı dönüştürerek malzemeli araştırmalar yaklaşık 5 gerçek dakikada, 4× hızda tamamlandı | Para araştırmaları alınmadığı için eski tüm-ağaç testleriyle doğrudan kıyaslanamaz |
| Bu turun çoğu bekleyerek geçti | Yalnızca araştırma miktarını büyütmek çözüm olarak kabul edilmedi |
| Araştırmanın neden yavaşladığı anlaşılamadı | Gerçek teslimat/gelir ve yetersiz kapasite okunabilir olmalı |
| İşçi bir kez atandıktan sonra hiç taşınmadı | İşçi taşıma ihtiyacı yapay biçimde üretilmeyecek; sistem kapsamdan çıkarıldı |
| Büyük açılış sonrası güçlenme hissi tercih edildi | Ana yön aktif fabrika bulmacası değil idle/incremental olarak seçildi |

Amaç oyuncuya mutlaka ikinci demir hattı kurdurmak veya belli bir optimizasyon davranışını zorlamak değildir. Yeni bağımsız kol ve birleşme, ilerleme ödülü olarak sunulur.

## 7. Referans oyundan alınan ilkeler ve sınırlar

Upload Labs wiki'sinde doğrudan okunan örnekler:

| Mekanik | Tasarımda öğrendiğimiz ilişki | Kaynak |
|---|---|---|
| Network hız, Processor Clock Speed sağlar | Malzeme/dosya ile işlem kapasitesi farklı şeylerdir | [Network](https://labs-wiki.enigmastudio.dev/en/nodes/network/network), [Processor](https://labs-wiki.enigmastudio.dev/en/nodes/cpu/processor) |
| Processing Seller işlem kapasitesini paraya çevirir | İkinci kapasite kendi başına gelir sağlar | [Processing Seller](https://labs-wiki.enigmastudio.dev/en/nodes/cpu/processing-seller) |
| Virus Scanner dosya ve Clock Speed alır | Bağımsız kollar sonradan birleşir | [Virus Scanner](https://labs-wiki.enigmastudio.dev/en/nodes/cpu/virus-scanner) |
| Dosya boyutu, kalite, satış değeri farklıdır | Her işlem aynı sonucu artırmak zorunda değildir | [Files](https://labs-wiki.enigmastudio.dev/en/guide/files) |
| Fabrika Router, CPU Core, GPU üretir | İleri üretim, önceki kapasite kaynaklarına bağlanabilir | [Factory](https://labs-wiki.enigmastudio.dev/en/nodes/factory/factory-assembler) |
| AGI farklı nöron türlerini oranlı biriktirip güç sağlar | Eski kollar geç oyunda ortak hedefte yeniden önem kazanabilir | [AGI](https://labs-wiki.enigmastudio.dev/en/hub/agi) |
| Coding ve Hacking diğer ekonomileri güçlendirir | Yeni sistem eski yatırımlara geri fayda verebilir | [Coding](https://labs-wiki.enigmastudio.dev/en/hub/coding), [Hacking](https://labs-wiki.enigmastudio.dev/en/hub/hacking) |

Wiki sürümleri ve bazı maliyetler tutarlı değildir. Ana sayfa 2.1.11 derken bazı içerikler 2.2'yi anlatır; araştırma sayfasında AGI için farklı maliyetler bulunur. Power hub erişilemedi. Bu kaynaklardan kesin denge sayısı veya eksiksiz açılış sırası kopyalanmaz.

NotebookLM video özetleri yararlı hipotezler sağlamıştır; zaman damgası eksikleri, rehber/oynanış ayrımı ve video kesmeleri nedeniyle süre ve nedensellik kanıtı değildir. Kaynakta görülen mekanik, kullanıcı oynanışı ve bizim tasarım önerimiz ayrı tutulur.

Referanstan şimdilik kopyalanmayacaklar: bütün yan sistemler, çok sayıda para birimi, altı girdili geç oyun hedefleri, prestij, çevrimdışı süre sistemi ve dev teknoloji ağacı.

## 8. Yeni büyük açılış için kabul soruları

1. Oyuncu daha önce yapamadığı neyi yapabilecek?
2. Kendi başına hangi faydayı sunuyor?
3. Önceki hangi sistemle birleşiyor?
4. Birleşince hangi eski yatırım değer kazanıyor?
5. Çalıştırmanın toplam maliyeti ve getirisi anlaşılır mı?
6. Yeni yük, kazanılan gücü ve rahatlığı gölgeliyor mu?

Her soruya mekanik eklemek gerekmez. Ancak ödülü açıklanamayan bir açılış, yalnızca içerik sayısını artırmak için eklenmez.

## 9. Karar günlüğü

| Karar | Durum | Gerekçe |
|---|---|---|
| Idle/incremental ana yön | Kesinleşti | Büyük açılışa ulaşma ve güçlenme ana tatmin |
| Demir merkezli sanayi + elektrik | Kesinleşti | Tematik bağlantı ve bağımsız kolların birleşmesi |
| Orta çağ zorunluluğunu kaldır | Kesinleşti | Teknolojik açılış alanını genişletmek |
| İşçi/gıda ve tarımı çıkar | Kesinleşti | Üretim ve yatırım odağını korumak |
| Demir → bağımsız elektrik → elektrikli hadde | Kesinleşti | Üç aşamalı ilk oynanabilir bölüm |
| Aynı ürüne iki alternatif reçete eklemek | Reddedildi | Kullanıcının istediği yeni aşama hissini karşılamadı |
| Sadece verim artışı sunan zenginleştirme ilk büyük açılışı | Reddedildi | Yeni olanak yerine eski işin çarpanı olarak kaldı |
| Sürekli kapasite yatırımı/optimizasyon zorunluluğu | Terk edildi | Idle yönüyle uyumsuz başarı ölçütü |
| Sabit %20–35 yatırım avantajı hedefi | Bağlayıcı değil | Mutlak zaman ve yatırım ufku daha önemli |
| Her açılışı malzemeyle araştırma | İlk kapsamdan çıkarıldı | Erken büyüme para üzerinden kurulacak |
| Geri beslemeli makine/parça üretimi | Gelecek hipotezi | Henüz ürün, maliyet veya açılış sırası seçilmedi |

## 10. Güncel uygulama fotoğrafı — 16 Eylül 2026

Bu bölüm kaynak kodunun okunmasına dayanır; testten geçti veya oynanışta iyi hissettirdi anlamına gelmez. Çalışma ağacında önceden yapılmış çok sayıda değişiklik vardır.

### Mevcut içerik

`data/block_catalog.gd` yedi aktif tür içerir: Iron Mine, Smelting Hearth, Generator, Power Exchange, Electric Rolling Mill, Splitter ve Market Stall.

`data/research_catalog.gd` üç teknoloji içerir:

| Teknoloji | Kilit bedeli | Ek kurulum | Ön koşul |
|---|---:|---:|---|
| Electrification | 1.100 | Generator 900 + Power Exchange 300 | Yok |
| Electrified Rolling | 1.600 | Electric Rolling Mill 900 | Electrification |
| Automation | 1.200 | Yok | Electrified Rolling |

Bu sayılar mevcut dosya değerleridir, önerilen/nihai denge değildir. Ortak hat ve marketin yeniden kullanımı kurulum maliyetini etkiler.

Maden: en fazla bir örnek, dört seviye, ilk geliştirme 150 ve maliyet büyümesi ×2, hedef hız artışı seviye başına +15 cevher/dk. Jeneratör: temel kapasite 40, seviye başına +15, ilk geliştirme 300 ve maliyet büyümesi ×2. Hadde tam kapasite için 24 güç birimi ister.

### Öncelikli tutarsızlıklar ve doğrulama boşlukları

1. **İlerleme testi eski akışı kullanıyor.** `tools/iron_progression_test.gd` elektrifikasyonu almadan PRESLEME açmaya çalışıyor. Hadde ölçümünde jeneratör veya güç bağlantısı kurmuyor. Ayrıca açılışta otomatik tahsilatı doğrudan etkinleştiriyor; güncel oyunda bunun ayrı araştırması var. Kaynak incelemesi bu uyumsuzlukları gösterir; test bu belge turunda çalıştırılmadı.
2. **Market geliştirmesi belgeyle uyuşmuyor.** README ve eski senaryolar satış yatırımı anlatıyor; `sevkiyat.tres` geliştirmeyi etkinleştirmiyor. `BlockType.upgradeable` varsayılanı false. Satış yatırım stratejisi güncel oynanabilir davranış sayılmamalı.
3. **Eski gelir tabloları güncel kanıt değil.** DESIGN.md aşama 2/3 sonuçlarını hesaplanmış ama simülasyonda doğrulanmamış olarak işaretliyor. Aynı belgedeki eski demir ölçümleri yeni enerji akışına taşınamaz.
4. **Reçete değişmiş.** Güncel `r_kulce.tres` girdi miktarı 1; önceki iki-cevher varsayımları ve bunlardan türetilen hızlar yeniden ölçülmeli.
5. **Güç birimi açıklığı eksik.** Sunum kW derken model tick başına birimler ve satış paketi kullanıyor. Güç, zamanla entegre edilen enerji ve muhasebe kesri tanımlanmalı. Bu, otomatik olarak fiziksel bir elektrik deposu olduğu anlamına gelmez.
6. **Kayıt uyumluluğu veri kaybı değildir denemez.** Kaldırılan türler yüklemede atlanıyor. Eski hadde güç bağlantısı olmadan durabilir. Kaydı açabilmek; bütün yatırım, ilerleme ve çalışabilirliği korumayı kanıtlamaz.
7. **İkinci kolu kullanma geçişi ekonomik olarak doğrulanmadı.** Araştırma ön koşulu, oyuncunun elektriği gerçekten kurup sattığını garanti etmez. Zorunlu zamanlayıcı eklemek yerine rota ve ekonomi incelenmeli.
8. **Jeneratör sayısı sınırı seçilmedi.** Kaynak node sınırı prensibi var; mevcut jeneratörde açık `max_instances` yok ve varsayılan sınırsız. Ucuz jeneratör çoğaltmanın birleşme hedefini anlamsızlaştırıp anlamsızlaştırmadığı ölçülmeli.

## 11. Açık kararlar ve çalışma varsayımları

Kesinleşmeyenler: toplam oyun süresi, gerçek zaman hızlarının rolü, jeneratör adet sınırı, otomasyonun tam zamanı, satış geliştirmesinin oranı/kapsamı, elektrik satış birimi, sonraki büyük açılış ve ileri araştırma modeli.

Mevcut çalışma varsayımları: tek oyuncu, yerel Windows/Godot projesi, ağ hesabı gerektirmeyen deneyim, deterministik simülasyon, veri güdümlü içerik, mümkün olduğunca tek ekonomik gerçek kaynağı. 60 FPS bir sunum hedefidir; bu turda ölçülmüş garanti değildir. İlk kapsam az sayıda node içerir; eski 80-node tavanı yeni tasarım kararı sayılmaz.

Kayıtların güvenli taşınması, işlemlerin tekrarında para çoğalmaması ve kesintisiz koşumla yüklenmiş koşumun aynı sonuç üretmesi temel güvenilirlik beklentileridir. Yeni ağ/telemetri servisi bu belgeyle yetkilendirilmez; ilerleme gözlemleri yerel kaydedilebilir.

## 12. Belge kullanımı

- Bu belge ürün niyeti ve kararların kaydıdır.
- [ROADMAP.md](ROADMAP.md) çalışma sırasını ve tamamlanma koşullarını tanımlar.
- [DESIGN.md](DESIGN.md) mevcut uygulama notudur; eski sayısal tabloları ayrıca doğrulamak gerekir.
- `.tres` ve simülasyon kodu mevcut davranışı gösterir; test raporu ölçümü gösterir. Tasarım niyetiyle uyuşmazlık bulunursa sessizce karar değiştirmek yerine fark kaydedilir.
- Yeni karar alındığında gerekçesi, uygulama durumu ve doğrulama kanıtı birlikte güncellenir. Gelecek hipotezi, onaylanmış kapsam gibi sunulmaz.
