---
tur: karar-defteri
durum: etkin
guncelleme: 2026-10-23
---
# Karar defteri

Kimlikler kalıcıdır. Kaynak metnin konuşma tarihleri bilinmiyor; aktarım tarihi 2026-10-20'dir.

## K-001 — Doğrudan ürün tüketen araştırma

- **Durum:** Yerine geçti → K-008 (2026-10-22).
- **Karar:** Araştırmalar gerçek üretim ürünlerini tüketir; B modeli seçilmiştir.
- **Kaynak:** [[Kaynaklar/01 - Aktarılan Sohbet]] başlangıcı: “Araştırma tüketim modeli olarak B: Doğrudan ürün tüketen araştırmalar seçiyorum.”
- **Alternatif:** Bilim puanı veya ayrı bilim paketi üzerinden ilerleme.
- **Gerekçe:** Üretim zincirinin çıktısını teknolojik ilerlemeye bağlamak. Bu gerekçe konuşmadaki tasarım açıklamasıdır; kullanıcının ayrıca ayrıntılı gerekçe beyanı yoktur.
- **Sınır:** Deney sayıları, tüketim anı, laboratuvar paralelliği ve araştırma değiştirme kuralları ayrıca onaylanmamıştır.
- **Asıl not:** [[Tasarım/Araştırma Ekonomisi]].

## K-002 — Sonsuz canvas üzerinde üretim kartları

- **Durum:** Onaylı yön.
- **Karar:** Üretim, sonsuz canvas üzerine yerleştirilen ve birbirine bağlanan node tabanlı kartlarla tasarlanır.
- **Kaynak:** [[Kaynaklar/01 - Aktarılan Sohbet]] içindeki sonsuz canvas tartışması ve “üretimi node based kartlarda yapmayı hayal ediyordum canvas üzerinde” açıklaması.
- **Alternatif:** Fiziksel makine binalarının coğrafi yerleşimini ana oynanış yapmak.
- **Gerekçe:** Kullanıcının ifade ettiği görsel çalışma ve üretim kurma biçimi.
- **Sınır:** Canvas konumunun ekonomik konumdan ayrılması henüz öneri modelidir.
- **Asıl not:** [[Tasarım/Makine Kartları]].

## K-003 — Kartlar makine olacak

- **Durum:** Onaylı.
- **Karar tarihi:** 2026-10-20.
- **Karar:** Kartlar makine türlerini temsil eder: CNC, torna, pres, fırın gibi.
- **Kaynak:** [[Kaynaklar/02 - Bu Sohbetteki Kararlar]]: “kartlar makine olacak”.
- **Alternatif:** Prosesleri temsil eden soyut döküm/haddeleme/işleme kartları.
- **Gerekçe:** Kullanıcının açık seçimi. Tatmin veya gerçekçilik gerekçesi ayrıca kullanıcıya atfedilmez.
- **Sonuç:** Uygun reçetenin makine kartına atanması, bu kararın önerilen çalışma modelidir.
- **Sınır:** Bir kartın tek makine veya makine grubu olması açık kalmıştır.
- **Asıl not:** [[Tasarım/Makine Kartları]].

## K-004 — Yaşayan Obsidian vault

- **Durum:** Onaylı çalışma biçimi.
- **Karar tarihi:** 2026-10-20.
- **Karar:** Tasarım klasörde Obsidian vault olarak tutulur; Canvas ve Markdown birlikte kullanılır; ayrıntılı bilgi aktarılır ve zamanla geliştirilir.
- **Kaynak:** [[Kaynaklar/02 - Bu Sohbetteki Kararlar]].
- **Sonuç:** Konu notları, karar defteri, açık sorular, kaynak kaydı, şablonlar ve üç canvas oluşturulur.
- **Sınır:** Bu düzen oyun mekaniklerinin tamamının onaylandığı anlamına gelmez.

## K-005 — İş miktarı ve makine işleme hızıyla üretim

- **Durum:** Onaylı; küçük prototipte uygulandı ve otomatik doğrulandı. Oynanış dengesi doğrulanmadı. Bkz. [[Yönetim/Uygulama Durumu]].
- **Karar tarihi:** 2026-10-20.
- **Karar:** Reçete çevrim başına girdi, çıktı ve gereken işi tanımlar. Makinenin hızı işleme birimi/sn cinsindendir. Çevrim süresi gereken iş / makinenin işleme hızı ile hesaplanır. Makine ayrıca reçeteye uygun olmalıdır.
- **Çevrim:** Küçük giriş/çıkış tamponları; bütün girdiler ve yeterli çıkış alanı hazırsa başlama; girdileri başta tüketme; çıktıları iş bitince üretme; koşullar uygunsa otomatik tekrar. Çıktı zorunlu bir adet değildir.
- **Kaynak:** [[Kaynaklar/02 - Bu Sohbetteki Kararlar]] içindeki çevrim önerisinin kabulü, kullanıcının 100 iş / 20 hız örneği ve “tamamdır bu sistemi kayıt altına alalım” talebi.
- **Alternatif:** Makineden bağımsız sabit reçete süresi veya bütün ürünler için aynı adet/sn değeri.
- **Gerekçe:** Hız hem reçetenin iş yükünden hem makinenin kapasitesinden doğar; daha hızlı uygun makine aynı reçeteyi daha kısa sürede tamamlar.
- **Örnek:** 2 demir çubuk + 100 iş; 20 iş/sn uygun makine → 5 saniyede 1 dişli. Sayılar ve terimler örnektir.
- **Sınır:** İşleme birimi fiziksel ürün değildir. Enerji, tampon boyutları, gruplama, reçete paylaşımı, iptal ve yan ürün bertarafı kararlaştırılmadı. Laboratuvarlara bu hız modelinin uygulanması ayrıca onaylanmadı.
- **Asıl not:** [[Tasarım/Makine Kartları#Onaylı üretim modeli — K-005]].
- **Önceki öneriye etkisi:** Üretim makinelerinde sabit reçete süresi anlatımı, iş ve makine hızıyla hesaplanan süre olarak netleştirildi. Araştırma deney süreleri bu kararla değiştirilmez.

## K-006 — Otomatik eşit ürün paylaşımı

- **Durum:** Onaylı; küçük prototipte uygulandı ve otomatik doğrulandı. Oynanış dengesi doğrulanmadı. Bkz. [[Yönetim/Uygulama Durumu]].
- **Tarih:** 2026-10-20.
- **Karar:** Aynı ürün çıkışı, ürünü kabul edebilen bağlı tüketiciler arasında otomatik eşit paylaşılır. Oyuncu hatlara oran veya hız girmek zorunda değildir.
- **Dolu tampon:** Giriş tamponu dolu tüketici pay almaz; kullanılabilir ürün diğer kabul edebilen tüketicilere dağıtılır. Hepsi doluysa çıkış tamponu birikir; çevrimin çıktısına yer kalmayınca yeni üretim başlamaz (K-005).
- **Kaynak:** [[Kaynaklar/02 - Bu Sohbetteki Kararlar]]; kullanıcının “Otomatik paylaşım:” seçimi ve eşit paylaşım örneğine “evet” cevabı.
- **Alternatif:** Oyuncunun elle oran, hız veya öncelik girmesi.
- **Gerekçe:** Ağ bağlantıları kurulduktan sonra temel ürün paylaşımını sistem yürütür.
- **Sınır:** Tekil ürün sıralaması, zaman adımı, çoklu üretici, taşıma kapasitesi ve gecikme kuralları seçilmedi. İleri öncelik araçları onaylanmadı. Karar küresel ağ optimizasyonu anlamına gelmez.
- **Asıl not:** [[Tasarım/Ana Proje ve Ürün Dağıtımı#Onaylı otomatik eşit paylaşım — K-006]].
- **Önceki öneriye etkisi:** Paylaşım modelinin açık olduğu anlatımı kapandı. Tarihsel 40/60/20 motor örneği temel dağıtım algoritması değildir.

## K-007 — 24 ürünlük üretim ağı ve 9 araştırmalık teknoloji ağacı ilk taslağı

- **Durum:** Onaylı ilk taslak.
- **Tarih:** 2026-10-20.
- **Karar:**
  1. 5 katmanlı **24 ilişkili üründen** oluşan üretim ağı (4 hammadde, 6 temel metalürji/malzeme, 6 temel imalat ve yan ürün, 5 mekanik/elektromekanik alt sistem, 3 ileri endüstriyel ürün) ve bunları işleyen makine türleri (`Ergitme Fırını`, `Çelik Fırını`, `Haddehane`, `Pres`, `Torna`, `CNC`, `Dökümhane`, `Tel Çekme / Sarım Makinesi`, `Montaj İstasyonu`) ilk taslak olarak seçildi.
  2. **Kalite sistemi (A/B/C):** Bu aşamada kapsam dışı bırakıldı ("kaliteye gerek yok şu an").
  3. **Teknoloji ağacı ilk taslağı:** 24 ürüne bağlı, Kademe 0 başlangıç durumundan 3 paralel kolla açılan **9 araştırmalık** (`A-01` – `A-09`) araştırma ağı ilk taslak olarak kaydedildi.
- **Kaynak:** [[Kaynaklar/02 - Bu Sohbetteki Kararlar]]; kullanıcının “1 2 uygun 3 kaliteye gerek yok şu an. ayrıca bu 24 ürüne bağlı ufak bir araştırma ağı da tasarla” ve “bunları dökümanlara ilk taslak olarak kayıt et. bana çizdiğim şemalarıda içersin. güzelce yaz” ifadeleri.
- **Gerekçe:** Ürünlerin ortak ara girdiler üzerinden paylaşım kararları (K-006) üretmesi, alternatif yöntemlere (`Dişli` ve `Gövde` için talaşlı/pres vs. döküm) ve yan ürün geri kazanımına (`Metal Talaşı`) zemin hazırlaması.
- **Sınır:** İlk taslak niteliğindedir. Reçetelerin girdi/çıktı sayıları, gereken iş miktarları (K-005), makine hızları, araştırma deney sayıları/süreleri ve montaj makinelerinin tek veya üç ayrı makine türü olması henüz sabitlenmemiştir.
- **Asıl notlar:** [[Tasarım/Ürün ve Üretim Ağı]], [[Tasarım/Teknoloji Ağacı]].
- **Değişiklik:** K-017 ile aynı ürüne alternatif yöntem (ör. döküm dişli vs CNC dişli) yerine "tek reçete ve farklı ürünler" (Cast Iron Gear vs Steel Gear) ilkesi benimsendi.

## K-008 — Kademeli laboratuvarlar ve depolanabilir araştırma puanı

- **Durum:** Onaylı; K-001'in yerine geçer.
- **Tarih:** 2026-10-22.
- **Karar:**
  1. Laboratuvarlar kademelidir. Her laboratuvar araştırmadan bağımsız olarak hep aynı ürünleri tüketir ve kendi kademesinin araştırma puanını üretir (Laboratuvar 1 → Kademe 1 puanı, Laboratuvar 2 → Kademe 2 puanı …). Üst laboratuvar alttakinden farklı ürünler ister.
  2. Araştırmanın fiyatı kademe puanlarıyla yazılır; bir araştırma birden fazla kademenin puanını isteyebilir.
  3. Puanlar depolanabilir. Laboratuvarların ürettiği puan depoda birikir; aktif araştırma eksik kalan fiyatını depodan çeker.
- **Kaynak:** Kullanıcı oyunu denedikten sonra her araştırmada ağı yeniden kurmanın can sıkıcı olduğunu söyledi ve “verdiğimiz kararı boş ver” dedi. Modeli kendisi tarif etti: “lab 1 olcak. 2 ürün isticek hep. ve çıktı olarak resarch point kademe1 gibi bişey verecek … kademe 1 ve kademe 2 resarch pointlerde araştırmamı yapılacak”; onayı: “tamam uygula ama puan depolanabilir olsun.”
- **Gerekçe:** Oyuncunun laboratuvara kurduğu hattın araştırma değişince bozulmaması; araştırma ağacının kademe puanları üzerinden birbirine bağlı kalması.
- **Sınır:** Laboratuvar girdileri, puan fiyatları ve laboratuvarların hangi araştırmayla açıldığı ilk denemedir; dengelenmemiştir. Puan deposunun bir üst sınırı yoktur.
- **Asıl not:** [[Tasarım/Araştırma Ekonomisi]].

## K-009 — Reçete gelen ürüne göre belirlenir

- **Durum:** Onaylı.
- **Tarih:** 2026-10-22.
- **Karar:** Girdileri birbirinden farklı reçeteleri olan makinelerde (ör. ergitme fırını) oyuncu reçete seçmez; makine bağlanan ürüne göre üreteceğini belirler. Boş makinenin tek bir genel girişi olur. Aynı girdiden farklı ürün yapan makinelerde (haddehane, CNC, dökümhane) kartın tıklanmasıyla açılan simgeli reçete ekranından ürün seçilir; ekran ürünün girdilerini de gösterir.
- **Kaynak:** “bunu oyuncu seçmesin. ancak gelen ürüne göre otomatik olarak üretilecek ürün belirlenmiş olsun”; aynı girdili makineler için “tıklayınca recipe ekranı çıksın … oyuncu bir ürün üretmek için nelere ihtiyacı olduğunu da ordan görmüş olur”; boş makine için “Tek genel giriş” seçimi.
- **Asıl not:** [[Tasarım/Makine Kartları]].
- **Değişiklik:** Fırınlar (ergitme ve çelik fırını) için K-016 ile değişti: girdileri farklı olsa da fırınlarda reçeteyi oyuncu seçer. Diğer makineler için kural geçerli.

## K-010 — Hammadde kaynakları sınırlıdır

- **Durum:** Onaylı.
- **Tarih:** 2026-10-23.
- **Karar:** Madenler (demir, bakır, kömür, kuvars) oyun başında birer adet kurulabilir. Her makine türü veride bir kurulum sınırı taşıyabilir; sınırı olmayan makineler serbesttir.
- **Kaynak:** “hammedde kaynakalrının sınırsız olması oyunun balansını yapmayı imkansız hale getiriyor. madenler 1 er adet kurulabilmeli en azından oyun başında”.
- **Gerekçe:** Sınırsız hammadde dengelemeyi imkânsız kılıyor.
- **Açık:** Sınırın sonradan araştırmalarla artırılması kullanıcının “belki” dediği bir yöndür; karar değildir, uygulanmadı. Serbest modda (tümünü aç) sınır uygulanmaz. İzleyen soru: S-021.
- **Asıl not:** [[Tasarım/Envanter ve El Üretimi]].

## K-011 — Oyuncu envanteri, malzemeli kurulum ve el üretimi

- **Durum:** Onaylı.
- **Tarih:** 2026-10-23.
- **Karar:**
  1. Ekranın altı oyuncunun envanteridir; envanterde hem ürünler hem kurulmamış makineler tutulur.
  2. Makineler malzemeyle üretilir; envanterdeki makine tuvale yerleştirilir. Kaldırılan makine içindekilerle birlikte envantere döner.
  3. Üretilen ürün envantere kendiliğinden geçmez. Oyuncu isterse makine kartında biriken çıktıyı ya da ağa bağlanan Depo kartında biriken ürünü envantere alır.
  4. Oyuncu üretim (reçete) ekranından el ile üretim yapar; el üretimi süreli bir kuyruktur ve makinelerden yavaştır.
  5. Hammadde el ile çıkarılamaz; oyuncu bir başlangıç kitiyle başlar.
- **Kaynak:** “alt taraf oyuncunun inventorysi gibi olacak. ve kurulacak node lar malzeme isteyecek. oyuncu malzemeleri de node larıda bu inventery de tutabilecek. ve kendisi de recipe ekranından craft yapabilecek.” Seçimler: ürünün envantere girişi için “ikiside ancak otomatik inventory e geçmeyecek oyuncu kartta birikmiş çıktıyı ordan inventorysine isterse alacak. aynı şekilde depodan da”; el üretimi “Süreli kuyruk”; hammadde “Hayır, başlangıç kiti”; silinen kart “Envantere döner”.
- **Sınır:** Kurulum maliyetleri, el üretimi hızı (10 iş/sn, makineler 20), makine yapım süresi (5 sn), hangi makinelerin reçetelerinin el ile yapılabildiği (haddehane, pres, torna, CNC, tel sarım, montaj) ve başlangıç kiti ilk denemedir; dengelenmemiştir. Envanterin yuva sınırı yoktur. Depo ürün başına 100 tutar.
- **Asıl not:** [[Tasarım/Envanter ve El Üretimi]].
- **Değişiklik:** 1. madde K-012 ile değişti: alttaki çubuk artık envanterin tamamı değil, 10 yuvalı hızlı erişimdir; envanterin tamamı ayrı pencerededir. Diğer maddeler geçerli.

## K-012 — Hızlı erişim çubuğu ve envanter penceresi

- **Durum:** Onaylı.
- **Tarih:** 2026-10-23.
- **Karar:**
  1. Alttaki çubuk hızlı kullanım içindir ve sabit 10 yuvadır.
  2. Envanterin tamamı ayrı açılan, geniş bir penceredir ve bir tuşla açılır.
  3. İki görünüm aynı envanteri paylaşır; oyuncu envanterdeki istediği öğeyi alttaki hızlı erişime sabitler.
- **Kaynak:** “bu alttaki inentory hızlı kullanım için olsun ve sabit 10 ürün alıyor olsun. esas inventory başka açılan bir pencere olsun o geniş olsun. oyuncu istedğini altta hızlıya alabiliyor olsun. yani ikisi aynı inventory i paylaşacak ama oyuncu istediğini alta sabitleyebiliyor olacak ölye düşün. birde inventory açma tuşu koyman lazım tabi”
- **Sınır:** Kullanıcının seçmediği, prototipte asistanın koyduğu ayrıntılar: açma tuşu I; yuvalar 1-9 ve 0 tuşlarıyla kullanılır (makine yerleştirir); sabitleme sürükle-bırak, sağ tık ya da pencerede öğenin üstündeyken numara tuşuyla yapılır; sayısı sıfıra inen öğe yuvasında soluk kalır; yeni gelen öğe boş yuva varsa ilk boş yuvaya kendiliğinden girer; başlangıç kiti çubuğa dizilir. Bunlar değiştirilebilir.
- **Asıl not:** [[Tasarım/Envanter ve El Üretimi]].

## K-013 — Oyun boş tuvalle başlar

- **Durum:** Onaylı.
- **Tarih:** 2026-10-23.
- **Karar:** Oyunun başında tuvalde hiç makine kartı yoktur; oyuncu ilk makineleri başlangıç kitiyle kendisi üretip yerleştirir.
- **Kaynak:** “tamam şimdi oyunun başlangıcını boşalt. canvasda node olmasın”.
- **Önceki duruma etkisi:** Prototipte hazır kurulu gelen 8 kartlık başlangıç ağı kaldırıldı; bu ağ bir uygulama seçimiydi, kullanıcı kararı değildi.
- **Sınır:** Başlangıç kiti değişmedi (20 çelik levha, 10 bağlantı elemanı, 10 çelik külçe; Bakır madeni, Kuvars ocağı, Depo). Kitin bu başlangıç için dengesi açıktır.
- **Asıl not:** [[Tasarım/Envanter ve El Üretimi]].

## K-014 — Envanterden makine girişine elle malzeme konur

- **Durum:** Onaylı.
- **Tarih:** 2026-10-23.
- **Karar:** Oyuncu envanterdeki bir ürünü, uygunsa bir makine kartının girişine bırakabilir. Böylece ağa bağlı olmayan makineler de elle çalıştırılabilir.
- **Kaynak:** “inventory den node ların input kısımlarına da eğer uygunsa malzeme bırakabiliyor olmalıyız. böylece oyuncu ağ ile bağlı olmayan makineleri de manuel çalıştırabilir”
- **Sınır:** Prototip ayrıntıları kullanıcı kararı değildir: sürükle-bırak; varsayılan olarak girişe sığdığı kadar, Shift ile 1 adet; reçetesini gelen ürüne göre seçen makinede elle konan ürün de reçeteyi belirler; depo her ürünü alır.
- **Asıl not:** [[Tasarım/Envanter ve El Üretimi]].

## K-015 — Makine kartında ürün kutuları ve üretilen ürün

- **Durum:** Onaylı.
- **Tarih:** 2026-10-23.
- **Karar:**
  1. Kartlarda ürünlerin göründüğü yer çerçeveli bir kutudur. Kutu 0 iken boştur; ürün geldikçe simgesi ve adedi görünür. Depolar dahil bar kullanılmaz, sayı gösterilir.
  2. Kartta makinenin ne ürettiği görünür; bu bilgi çıktı kutusunda değil, ayrı bir yerde durur.
  3. Seçili reçetenin girdileri boş giriş kutularında saydamlaştırılmış simge olarak görünür; oyuncu hangi kutuya kaç tür malzeme gireceğini görür. Silüet ayırt edilemediği için saydam simge seçildi.
- **Kaynak:** “bu node lardaki ürünlerün göründüğü kısım görseldeki gibi bir alan içerisinde görünsün. depolarda barşeklinde olmasın. sayı olsun. 0 iken bu kutular boş olsun”; “üretilecek ürünün ne olduğu görünmeli ama bu biraz önce yaptığımız doplanabilir çıktı tarafında olmamalı”; “seçilen reçeteye göre input kısmındaki malzemelerin görüntüğü yerde o malzemenin silüeti olsun”; “siluet değilde saydamlaştırılmış mı yapsak”.
- **Sınır:** Prototipte üretilen ürün kart başlığında, adın sağında simge ve adla gösterilir; kutu 40 px, saydamlık %30, dolu tamponda çerçeve altın rengidir. Bunlar uygulama seçimidir.
- **Asıl not:** [[Tasarım/Makine Kartları]].

## K-016 — Fırınlarda reçeteyi oyuncu seçer

- **Durum:** Onaylı; K-009'un fırınlarla ilgili kısmının yerine geçer.
- **Tarih:** 2026-10-23.
- **Karar:** Ergitme fırını ve çelik fırınında reçete, aynı girdili makinelerde olduğu gibi oyuncu tarafından reçete ekranından seçilir. Gelen ürün fırının reçetesini değiştirmez.
- **Kaynak:** “fırınlardada reçete seçilebilir olsun. bu kararı ben vermiştim ama değiştiriyorum şimdi.”
- **Sınır:** Pres, tel sarım ve montaj istasyonunda K-009'daki otomatik seçim sürer.
- **Asıl not:** [[Tasarım/Makine Kartları]].

## K-017 — Tek reçete ve farklı ürün ilkesi

- **Durum:** Onaylı; K-007'deki "aynı ürüne alternatif üretim yöntemi" yaklaşımının yerine geçer.
- **Tarih:** 2026-10-23.
- **Karar:**
  1. **Her ürünün tek bir ana tarifi/reçetesi vardır:** Hurda geri kazanım gibi döngüsel yan durumlar haricinde, aynı ürün için birden fazla alternatif üretim yolu tanımlanmaz.
  2. **Farklı yöntemler veya hammaddeler farklı ürünler üretir:** Aynı parça ailesi olsa bile, döküm veya talaşlı imalat gibi farklı yöntemlerden ya da pik demir vs. çelik gibi farklı alaşımlardan gelen çıktılar ayrı ürün kimliklerine sahip olur (Örn: `Cast Iron Gear` ve `Steel Gear`; `Cast Iron Housing` ve `Steel Housing`). Her birinin kendi tekil reçetesi bulunur.
  3. **Demir ve çelik kollarının net ayrımı:**
     - `Iron Ingot` kömürsüz eritilir (`2x Iron Ore -> 2x Iron Ingot` Ergitme Fırınında).
     - `Steel Ingot` kömür katkısıyla üretilir (`2x Iron Ore + 1x Coal -> 2x Steel Ingot` Çelik Fırınında).
     - Hurda geri dönüşümü: `2x Metal Scrap -> 1x Iron Ingot`, `2x Metal Scrap + 1x Coal -> 1x Steel Ingot`.
     - Demir ara mamulleri: `Iron Plate` (`1x Iron Ingot -> 1x Iron Plate`), `Iron Rod` (`1x Iron Ingot -> 2x Iron Rod`), `Iron Pipe` (`1x Iron Plate -> 1x Iron Pipe`).
- **Kaynak:** Kullanıcının “Cast Iron Gear Steel Gear zaten 2 farklı ürün oluyor. bunlarında kendi tarifleri oluyor... her ürünün tek tarifi olsun. zaten Cast Iron Gear Steel Gear farklı ürünler olduğu için bunlarında kendi tarifleri olacak. dökümanları bu şekilde güncelle” yönlendirmesi.
- **Gerekçe:** Ürün zincirini zengin ve detaylı kılarken makinelerin aynı ürün için gereksiz çoklu tariflerle karmaşıklaşmasını önlemek.
- **Asıl notlar:** [[Tasarım/Ürün ve Üretim Ağı]], [[Tasarım/Prosesler Kalite ve Yan Ürünler]].

## Henüz karar olmayan yönler

| Konu | Kanıt düzeyi | Ayrıntı |
|---|---|---|
| Alternatif proses dengeleri | Kullanıcı olumlu karşılamış | K-017 ile farklı ürünler (Cast Iron vs Steel) üzerinden tekil tarifler belirlendi; nihai tüketici/performans dengeleri açık. |
| Bölgesel kaynak ve lojistik | Kullanıcı temkinli olumlu karşılamış | Bölge sistemi ve maliyetler kesinleşmemiş. |
| Aynı kartta paralel makineler | Asistan önerisi | Kullanıcı seçimi yok. |
| Ana proje ve ürünlerin üç tüketiciye ayrılması | Asistan önerisi | Ana hedef ve tüketim üçgeni açık; genel paylaşım kuralı K-006 ile onaylı. |
| Para kullanmama | Asistan önerisi | Kesin ekonomi kararı değil. |
