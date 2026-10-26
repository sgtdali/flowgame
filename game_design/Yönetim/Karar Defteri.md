---
tur: karar-defteri
durum: etkin
guncelleme: 2026-10-26
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
- **Değişiklik (2026-10-26):** K-043 ile tuval sınırlı bir haritaya dönüştü; kartlar yine serbestçe yerleşir ve bağlanır.
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
- **Değişiklik:** K-035 ile aktarım anlık olmaktan çıktı: ürün bağlantı boyunca taşınır, hedefe varınca sayılır. Eşit paylaşım aynen geçerli; payı alan tüketicinin yolunun girişi boş olmalıdır.

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
- **Genişleme:** K-021 ile ağ beş modüle ve 55 ürüne genişletildi.
- **Değişiklik:** 9 araştırmalık ağacın yerine K-025 ile 63 araştırmalık ağaç geçti; montaj ayrımı K-022 ile kapandı.

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
- **Açık:** Sınırın sonradan araştırmalarla artırılması kullanıcının “belki” dediği bir yöndü; K-025 ile maden genişletme araştırmaları onaylandı. Serbest modda (tümünü aç) sınır uygulanmaz.
- **Değişiklik (2026-10-26):** K-043 ve K-044 ile madenlerin sınırını haritadaki yataklar belirler: her yatağa bir maden, her kaynaktan 3 yatak. Tür başına “birer adet” sınırı kalktı; yatak sınırı serbest modda da geçerlidir.
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
- **Değişiklik:** 2. madde K-026 ile değişti: envanterin tamamı ile el üretimi artık tek penceredir (I ya da C). Diğer maddeler geçerli.

## K-013 — Oyun boş tuvalle başlar

- **Durum:** Onaylı.
- **Tarih:** 2026-10-23.
- **Karar:** Oyunun başında tuvalde hiç makine kartı yoktur; oyuncu ilk makineleri başlangıç kitiyle kendisi üretip yerleştirir.
- **Kaynak:** “tamam şimdi oyunun başlangıcını boşalt. canvasda node olmasın”.
- **Önceki duruma etkisi:** Prototipte hazır kurulu gelen 8 kartlık başlangıç ağı kaldırıldı; bu ağ bir uygulama seçimiydi, kullanıcı kararı değildi.
- **Sınır:** Başlangıç kiti değişmedi (20 çelik levha, 10 bağlantı elemanı, 10 çelik külçe; Bakır madeni, Kuvars ocağı, Depo). Kitin bu başlangıç için dengesi açıktır.
- **Asıl not:** [[Tasarım/Envanter ve El Üretimi]].
- **Değişiklik:** K-033 ile değişti: oyun bir Demir madeni ve bir Ergitme fırını kurulu başlar.

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

## K-018 — Ana proje: Son Fabrika ve Kurucu Çekirdek

- **Durum:** Onaylı.
- **Tarih:** 2026-10-23.
- **Karar:**
  1. Oyunun hikâyesi **Son Fabrika**'dır: endüstriyel çöküşten sonra oyuncu hayatta kalan son otomatik sanayi sistemini yönetir ve dünyanın sanayisini yeniden başlatacak **Kurucu Çekirdek**'i (`Founding Core`) üretir.
  2. Kurucu Çekirdek **ayrı bir üründür**: endüstri modülleri montajda birleşip çekirdeği yapar, ana proje terminali yalnızca çekirdeği kabul eder.
  3. Modüller: Metalürji, Hassas Mekanik, Elektrik, Elektronik ve Otomasyon. Kimya modülü yeni hammaddelerle ileride eklenecek.
  4. Final proje her modülden çok sayıda ister ve zor tamamlanır; oyuncu fabrikayı genişletmek, çok sayıda hat kurmak ve adetleri yükseltmek zorunda kalır. Ürünlerin açılması araştırmaya bağlıdır.
  5. Exodus senaryosu, hammaddeler genişletilirse kullanılmak üzere fikir olarak saklanır.
- **Kaynak:** Kullanıcı dört senaryoyu paylaştı ve “son fabrika olsun. ama exodus u da bi yere not edelim” dedi; modül tablosu için “Modül tablosu uygun”; “final proje çok fazla maleme istemeli her modülden. yani zor tamamlanmalı ki oyuncu fabrikayı genişletme ihtiyacı duysun. zaten araştırma ile açılacak”; çekirdek için “Ayrı bir ürün” seçimi ve yapıya “uygundur”.
- **Sınır:** Çekirdeğin ve modüllerin adetleri (prototipte her modülden 4) denenmemiş örneklerdir. Asistanın önerdiği 30–40 ürün sınırını kullanıcı “30 40 ı boş ver. önemli değil o” diyerek reddetti; ürün sayısı sınırı yok.
- **Asıl notlar:** [[Tasarım/Ana Proje ve Ürün Dağıtımı]], [[Tasarım/Ürün ve Üretim Ağı]].

## K-019 — Kollar birbirine bağlı olur

- **Durum:** Onaylı.
- **Tarih:** 2026-10-23.
- **Karar:** Modüllerin ürün kolları (demir, çelik, bakır, kuvars) birbirinden tamamen bağımsız olmaz; bazı reçeteler iki ayrı koldan malzeme ister.
- **Kaynak:** “ürünler için modüllerimiz var evet ama bunlarında birbirinden tamamen bağımsız kollar olmasını istemiyorum. bazı recipe lerde 2 koldan malzeme istese iyi olabilir”.
- **Sınır:** Uygulamada izlenen “kademe 4 ve üstü montajlar en az iki koldan malzeme ister” ölçütü asistan önerisidir, ayrıca onaylanmadı.
- **Asıl not:** [[Tasarım/Ürün ve Üretim Ağı]].

## K-020 — Makine üreten makineler

- **Durum:** Onaylı; K-024 (Makine Fabrikası) ile uygulandı.
- **Tarih:** 2026-10-23.
- **Karar:** Şu an elle üretilen makine kartlarını üreten makine kartları da olacak. Oyuncu başta elle yaptığını bir süre sonra otomatikleştirir; final projeyi bitirmek için çok sayıda üretim hattı kurması gerekir.
- **Kaynak:** “kartlar şu an elle craft ediliyor ya bunları craft eden kartlarda olacak. yani makine üreten makineler gibi. yani oyuncu aslında ilk başta elle yaptığını bir süre sonra otomatikleştirebilecek ve final projeyi bitirmesi için fazla sayıda üretim hatları kurup adetlerini yükseltmesi gerekecek.”
- **Sınır:** Hangi kartın hangi makineyi ürettiği, araştırmayla açılışı ve çıktının envantere mi tuvale mi gittiği açık. Kullanıcı reçete tasarımı sırasında makineleri bilerek erteledi (“şu an makinelere önemli dğeil onlara bakmıyoruz. sadece reçeteler.”).
- **Asıl not:** [[Tasarım/Envanter ve El Üretimi]].

## K-021 — Beş modülün reçete taslağı

- **Durum:** Onaylı ilk taslak; K-007'deki 24 ürünlük ağı genişletir.
- **Tarih:** 2026-10-23.
- **Karar:** Kurucu Çekirdek'in beş modülü ve onlara giden ara ürünler, kullanıcının adım adım onayladığı tariflerle tanımlandı (31 yeni ürün, toplam 55). Başlıcaları:
  - **Demir kolu:** `Iron Plate`'ten `Iron Pipe` ve `Electrical Cabinet`; `Cast Iron Gear` ve `Cast Iron Housing` ayrı ürünler. PLC'deki çelik levha yerine `Electrical Cabinet` girer.
  - **Metalürji:** Valve, Tank, Iron Frame, Hydraulic Cylinder, Pump, Hydraulic Power Unit, Hydraulic Press Unit → Metallurgy Module.
  - **Hassas Mekanik:** Gearbox çelik gövde yerine `Cast Iron Housing` ister; Precision Spindle ve Linear Guide → Precision Mechanics Module.
  - **Elektrik:** Cable, Laminated Core, Transformer, Switchgear → Electrical Module.
  - **Elektronik:** Silicon, Microchip, Display, Control Computer → Electronics Module.
  - **Otomasyon:** Robot Arm, Conveyor Line; PLC ile birlikte → Automation Module.
- **Kaynak:** Her adımda kullanıcı onayı: Electrical Cabinet için “tamam bunu da önerdiğin gibi yapabilirsin”, metalürji için “tamamdır işle”, hassas mekanik için “tamamdır”, elektrik için “tamamdır”, elektronik için “evet”, otomasyon için “devam”. Precision Spindle'da bobin yerine elektrik motoru kullanılması (montaj istasyonunun iki reçeteyi ayırt edebilmesi için) asistan değişikliğidir; kullanıcı ardından Elektrik modülüne geçti.
- **Sınır:** Adetler ve iş miktarları ilk tahmindir. Yeni reçetelerin makine ve araştırma atamaları asistan seçimidir, makineler ayrıca ele alınacak.
- **Asıl not:** [[Tasarım/Ürün ve Üretim Ağı]].

## K-022 — Makine düzeni

- **Durum:** Onaylı.
- **Tarih:** 2026-10-23.
- **Karar:**
  1. Torna ve CNC tek makinede birleşir: **Tezgâh Atölyesi** (`Machine Shop`) mil, dişli ve rulman yapar.
  2. Çelik fırını kalkar; çelik ve hurdadan çelik **Ergitme Fırını**'nda yapılır.
  3. Montaj işin türüne göre ayrılır: **Mekanik Montaj**, **Elektrik Montaj**, **Elektronik Montaj**, **Robotik Montaj**; beş modül ve Kurucu Çekirdek ayrı ve büyük bir **Modül Tesisi**'nde yapılır.
- **Kaynak:** “torna ve cnc i birleştirebiliriz. buna güzel bir isim bulursun. ama cnc gibi fazla teknik olmasın. çelik fırınına da gere kyok gibi orda ergitme ile birleşsin.”; güncel makine tablosuna “işle evet”.
- **Sınır:** Montajın dörde bölünmesi ve Modül Tesisi asistan önerisiydi, kullanıcı tabloyla onayladı. “Tezgâh Atölyesi” adı asistan seçimidir. Reçetelerin makinelere dağılımı [[Tasarım/Makine Kartları]] notundadır. K-007'nin açık bıraktığı montaj ayrımı böylece kapandı.
- **Asıl not:** [[Tasarım/Makine Kartları]].

## K-023 — Kurulum bedelleri ve başlangıç kiti

- **Durum:** Onaylı ilk değerler.
- **Tarih:** 2026-10-23.
- **Karar:**
  1. Başlangıç makineleri (madenler, fırın, haddehane, pres, depo, talaş imha) demirden kurulur; sonraki makineler açıldıkları aşamanın ürünlerini ister.
  2. Bir makine yalnızca açıldığı anda yapılabilen şeyleri ister.
  3. Başlangıç kiti: 30 Iron Plate, 20 Iron Rod, 6 Steel Plate, 6 Fastener; Bakır Madeni, Kuvars Ocağı ve Depo.
- **Kaynak:** Bedel tablosu ve kit önerisine “uygun”.
- **Sınır:** Adetler ilk tahmindir; bedellerin listesi `data/prototype.json` içindedir.
- **Asıl not:** [[Tasarım/Envanter ve El Üretimi]].

## K-024 — Makine Fabrikası

- **Durum:** Onaylı; K-020'nin uygulaması.
- **Tarih:** 2026-10-23.
- **Karar:** Makineleri tek bir **Makine Fabrikası** kartı üretir. Oyuncu hangi makinenin üretileceğini reçete ekranından seçer; girdiler o makinenin kurulum bedelidir. Biten makine kartta az sayıda birikir, kart bir Depo'ya bağlanırsa depoda birikir; oyuncu oradan envantere alır. Fabrika erken bir araştırmayla açılır.
- **Kaynak:** Soru kartında “Tek Makine Fabrikası (Önerilen)”, “kartta birikir az miktarda bağlanırsa depoda birikebilir”, “Erken bir araştırmayla (Önerilen)”.
- **Sınır:** Kurulum sınırı olan makineleri (madenler) üretmemesi, çıktı kapasitesinin 3 olması, bedeli ve açılan araştırma (AL-01) asistan seçimidir.
- **Asıl not:** [[Tasarım/Envanter ve El Üretimi]].

## K-025 — 63 araştırmalık teknoloji ağacı

- **Durum:** Onaylı ilk taslak; K-007'deki 9 araştırmalık ağacın yerine geçer.
- **Tarih:** 2026-10-23.
- **Karar:**
  1. Araştırma sayısı en az 40–50 olur; onaylanan taslak 9 kolda 63 araştırmadır: Demir ve hidrolik (DM), Çelik ve mekanik (MK), Bakır ve elektrik (EL), Kuvars ve elektronik (EK), Otomasyon ve final (OT), Altyapı ve laboratuvar (AL), Maden genişletme (MD), Verim (VR), Kapasite (LJ).
  2. Açılış araştırmaları bir ya da iki ürün açar; kollar birbirini ön koşul olarak ister (K-019).
  3. Maden sınırı araştırmayla artar (her maden için II ve III); hız ve kapasite araştırmaları değer değiştirir. **Değişiklik (2026-10-26):** K-043 ile maden sınırını yataklar belirlediği için maden genişletme araştırmaları geçici olarak madeni %25 hızlandırır; yeni işlevi açık (S-031).
  4. Dördüncü puan kademesi (K4) ve onu üreten Laboratuvar 4 eklenir.
- **Kaynak:** “oyunumuzda sadece toplam 9 tane mi araştırma var. bunun en az 40 50 falan olması lazım”; araştırma türleri önerisine “Anlastik devam et”; 63 araştırmalık tabloya “Tablo uygun”.
- **Sınır:** Bedeller, etki oranları ve Laboratuvar 4'ün girdileri ilk tahmindir. Araştırmaların tam listesi [[Tasarım/Teknoloji Ağacı]] notundadır.
- **Asıl not:** [[Tasarım/Teknoloji Ağacı]].

## K-026 — Envanter ve el üretimi tek pencerede

- **Durum:** Onaylı; K-012'nin 2. maddesinin yerine geçer.
- **Tarih:** 2026-10-24.
- **Karar:** Envanter penceresi ile üretim ekranı birleşir. Sol tarafta oyundaki bütün öğeler durur: elde olanlar adediyle, olmayanlar soluk görünür; böylece oyuncu bütün öğeleri ve nasıl yapıldıklarını buradan görür. Sağ tarafta seçilen öğe üretilir. I ve C aynı pencereyi açar.
- **Kaynak:** “tamam şimdi bu inventory ile craft ekranını birleştirebiliriz bence 2 bölümlü olur sol tarafta envanter olur. orda tüm itemlar olur var olanlar kaç adet olduğu ile beraber görünür var olmayanlar opaklığı düşük şekilde görünür hem böylece oyuncu tüm itemler ve nasıl craft edildiğini rdan görür. sağ tarafta craft etme olur basınca craft edilir.”
- **Sınır:** Asistan seçimleri: kategori sekmeleri kalktı; araştırılmamış öğelerde asma kilit; makine çift tıkla yerleştirilir; "Kullanıldığı yerler" listesi; alt çubuktaki iki düğme tek düğmeye indi. Pencerenin düzeni K-028 ile akış haritası oldu.
- **Asıl not:** [[Tasarım/Envanter ve El Üretimi]].

## K-027 — Aydınlık arayüz paleti: Kum taşı

- **Durum:** Onaylı.
- **Tarih:** 2026-10-24.
- **Karar:** Koyu mavi tema bırakılır; arayüz aydınlık ama cart olmayan bir paletle boyanır. Oyun içinde karşılaştırılan üç paletten A seçildi: bej tuval, kâğıt rengi kart ve paneller, petrol yeşili ve bakır vurgu.
- **Kaynak:** “Oyundaki bu karanlik mavi teami icimi bayiyor daha boyle aydinlik ama cart olmayan tenk paleti lazim bize pempe falan gibi cart renkler olmaz tabi ama boyle koyu karanlik da olmamali”; “Once basit bir menu icin 3 unude uygulayip yan yana gorselini ver bana goreyim”; karşılaştırmadan sonra “A olsun”.
- **Sınır:** Renk tonları asistan seçimidir. Makine çizimleri değişmedi; Zincir Editörü (oyun dışı araç) koyu kaldı.
- **Asıl not:** [[Tasarım/Arayüz ve Büyük Ağ Yönetimi]].

## K-028 — Envanter penceresi akış haritası düzeninde

- **Durum:** Onaylı.
- **Tarih:** 2026-10-24.
- **Karar:**
  1. Codex'e ürettirilen dört alternatiften D (akış haritası) uygulanır: seçilen öğe ortada, girdileri solda, kullanıldığı yerler sağda durur ve çizgilerle bağlanır.
  2. Kullanıldığı yerler 6 karta kadar olduğu gibi gösterilir. Fazlası kaydırılır; kaydırma serbest değildir, kartlar birer adım kayar ve çizgiler görünen kartlara gider.
- **Kaynak:** “şimdi bizim envantör menüsü var ya bunun screenshotunu çekip codex e cli üzerinden ver … ondan 1 görsel içerisinde 4 alternatif içerecek şekilde görsel oluşturmasını iste”; “D alternatifini (akış haritası) oyuna uygula”; “bence orası 6 ürüne kadar normal göstersin. görseldeki gibi yani. bir önceki gibi. 6 üründen fazla ise aşağı kaydırmalı olsun kaydırmada free olmasın flow oklarına gelecek şekilde step step aşağı kaysın”.
- **Sınır:** Makineleri ayrı bir simge bloğunda toplayan ara deneme “yok böyle olmadı” ile geri alındı. Fare tekerleği ve ok düğmeleri, aralık göstergesi ("3-8 / 17") ve 5 sütunlu sol liste asistan seçimidir. Konsept görseli `art_src/konsept/` altındadır.
- **Asıl not:** [[Tasarım/Envanter ve El Üretimi]].

## K-029 — Elle ve makinede aynı iş miktarı, simgeyle gösterilir

- **Durum:** Onaylı; K-005'teki üretim modelinin arayüzdeki karşılığı.
- **Tarih:** 2026-10-24.
- **Karar:** Üretimde elle ve makinede ayrımı yapılmaz. Her reçetenin kendine ait sabit bir iş gereksinimi vardır; el ve makineler yalnızca iş güçleriyle ayrılır. Pencere bu sayıyı yazıyla değil uygun bir simgeyle gösterir.
- **Kaynak:** “bu üretiminde elle üretim makine üretim diye bir farkı olmaması lazım. zaten makinelerin craft gücü var. elle üretiminde bir kraft gücü var. yani recipelerin craft gereksinimin yazması lazım ve bu ellede olsa makinede olsa sabit bir değer her ürünün kendisi için”; “gereken iş gibi text ile anlatmayalım bunu da iconla alatalım uygun bir icon ile”.
- **Sınır:** Simge, oyunda üretimi temsil eden çekiçtir (asistan seçimi). Bazı reçetelerin el ile yapılamaması (K-011 sınırı) değişmedi.
- **Asıl not:** [[Tasarım/Envanter ve El Üretimi]].

## K-030 — Oyun İngilizce; font ve pencere malzemesi

- **Durum:** Onaylı.
- **Tarih:** 2026-10-24.
- **Karar:**
  1. Oyundaki bütün metinler İngilizcedir.
  2. Font seçimi asistana bırakıldı.
  3. Envanter penceresine malzeme hissi verilir ve araştırılmamış makineler birbirinden ayırt edilir; önce gösterilip sonra onaylandı.
- **Kaynak:** Arayüz eleştirisine “1. herşey ingilizce olacak. 2. bunu sen çöz. 3 için bişi yapma şu an. 4 ve 5 için 1 ve 2 yi yaptıktan sonra 1 ve 2 ve mevcut yapıyı bozmadan yapıp bana göster önce.”; fontların indirilmesine “Evet, Pixelify Sans ve Nunito fontlarını indir ve uygula”; gösterimden sonra “4 ve 5 kalsın, hepsini commit push yap”.
- **Sınır:** Asistan seçimleri: başlıklarda Pixelify Sans, metinde Nunito (ikisi de OFL, `app/fonts`); perçinli pencere kenarı, başlık bandı ve ızgaralı harita zemini; kilitli makinelerde yer tutucu çizim yerine kategori simgesi. Araştırma kodları (DM, MK…), Zincir Editörü ve tasarım belgeleri Türkçe kaldı. Kart hiyerarşisinin sadeleştirilmesi ertelendi.
- **Asıl not:** [[Tasarım/Arayüz ve Büyük Ağ Yönetimi]].

## K-031 — Envanter penceresi sabit boyutlu; kuyruk en fazla 5 farklı öğe

- **Durum:** Onaylı.
- **Tarih:** 2026-10-24.
- **Karar:**
  1. Ortadaki büyük öğe resmi 64 px'tir.
  2. Envanter penceresinin boyutu sabittir ve sağ üstte kapatma düğmesi vardır (asistanın önerisi onaylandı).
  3. El üretimi kuyruğu en fazla 5 farklı öğe alır; aynı öğe kendi grubuna eklenir.
- **Kaynak:** “bizim bu menüdeki item iconları kaç piksel yer kaplıyor” sorusundan sonra “64 yap.”; “peki bu menünün boyutu değişken mi” sorusuna verilen öneriye “evet. dediğin gibi olsun. ayrıca üretim sırasına dediğini yapmana gerek yok maks 5 farklı ürün olacak şekide sınırlayalım kuyruğu ölye çokda kuyruk ypaılamasın oyunda”.
- **Sınır:** Asistan seçimleri: pencere 1120x720; aynı öğenin grubu kuyrukta tek kart görünür.
- **Asıl not:** [[Tasarım/Envanter ve El Üretimi]].

## K-032 — Envanter penceresinin elle çizilmiş görünümü

- **Durum:** Onaylı.
- **Tarih:** 2026-10-24 – 2026-10-25.
- **Karar:** Envanter penceresinin bütün görselleri kullanıcının LibreSprite'ta çizdiği parçalardan yapılır: pencere çerçevesi ve zemin dokusu, başlık bandı ve ikonları, Machines ve Products bölümleri, akış alanının zemini, giriş/kullanım kartları ve etiketleri, ortadaki kart ve Recipe bölümü, CRAFT ve PLACE plakaları (normal, hover, pressed), kapatma düğmesi. Crafting Queue akış alanının altına, Quick Bar pencerenin altına kendi çerçeveli bölümlerinde taşınır; boş kuyruk yazı yerine boş yuvalar gösterir. Bütün kaynak dosyalar oyunun klasöründe tutulur.
- **Kaynak:** Adım adım verilen yönergeler, örneğin “bg1 yi oyundaki envantor menüsünde bu bölüme oy 5x5 9 slice”; “cervece2 yi görseldeki böümün çerveesi ve bachground u yap. 9 slice 9 piksel”; “crafting queu yi bu şekilde sağdaki ekraın altına koy. ve arka planına bu produt bölümlerinin arka planından yap.”; “bu bölümde hiç craft yokken yazı yazmasın böyle boş slotlar dursun”; “craft ve place dğümeleri yan yana olsun place düğmesi olanlarda”; “şu an oyuna koyduğuz libre çalışmalarını oyunun kendi klasörü içerisinde uygun bi yere alırmısın … ama hiç atlamaman lazım”.
- **Sınır:** Piksel aralıkları ve 9-slice payları kullanıcının tek tek verdiği değerlerdir; dosyaların oyundaki karşılıkları `art_src/ui/envanter_penceresi/README.md` içindedir. Akış haritasının içindeki 5 px'lik bağlantı çizgileri (kenar 3d3b3d, orta 399195, aradaki ton bu ikisinin ortalaması) de bu çalışmada seçildi. PLACE plakasının amber renkleri, hover ve pressed tonları asistan seçimidir.
- **Asıl not:** [[Tasarım/Envanter ve El Üretimi]].

## K-033 — Oyun demir madeni ve ergitme fırını kurulu başlar

- **Durum:** Onaylı; K-013'ün yerine geçer.
- **Tarih:** 2026-10-25.
- **Karar:** Yeni oyunda tuvalde bir Demir madeni ve bir Ergitme fırını kurulu gelir; oyuncu bunları üretmek zorunda kalmaz.
- **Kaynak:** “bide oyun başı demir ve eritme açık olsun. envanterde olsun yani direk kurabiliyim hatta bu 2 si kurulu gelsin.”
- **Sınır:** Asistan seçimleri: madenden fırına bağlantı hazır gelir, fırın Iron Ingot yapar; Reset de aynı başlangıca döner. İkisi zaten başlangıçta açık makinelerdi. Demir madeninin kurulum sınırı 1 olduğundan envantere ayrıca maden konmadı; başlangıç kiti değişmedi.
- **Asıl not:** [[Tasarım/Envanter ve El Üretimi]].

## K-034 — Tuvaldeki bağlantı çizgilerinin görünümü

- **Durum:** Onaylı.
- **Tarih:** 2026-10-25.
- **Karar:**
  1. Bağlantılar 16 px kalınlığındadır: her iki yanda 4 px kenar (dıştan içe 0e0c0a, 1e2225, 787b80, 3d3f45), ortada 8 px (dıştan içe 52524f, 645e59, 716c61, 716b60, aynalı).
  2. Çizgi boyunca her 20 px'de bir 2 px'lik dik çizgi vardır. Dik çizgi yalnızca ortadaki 8 px'i keser, kenarlara dokunmaz; köşelerde çizilmez.
  3. Dik çizginin her pikseli, altına denk gelen rengin bir tık koyusudur.
- **Kaynak:** “toplam 14 piksel olacak. 4 piksel kenarlık iki taraftandan olacak. bu 4 piksel dıştan içe : 0e0c0a, 1e2225, 787b80, 3d3f4. ortadaki 8 piksel ise dıştan içe 52524f, 645e59, 716c61, 716b60 olacak 4 4 şeklinde” (toplamın 16 px, son kenar renginin 3d3f45 olduğu soruyla netleşti); “0e0c0a bu renk ile çizgilerin dikeyine 2 piksellik izgiler arabilir misin? her 20 pikselde 1”; köşelerdeki taşmaya “bunun olmaması lazım”; “bunun 8 olması lazım yani 4 4 kenarları kesmesin”; “bunuda 8 renk yapalım bence. denk geldiği yerdekinin bi tık koyusu olsun”.
- **Sınır:** Asistan seçimleri: “bir tık koyu” %20 koyulaştırma; çizgileri Godot yerine oyunun kendisi çizer, sürükleme önizlemesi de aynı stildedir. Envanter penceresindeki akış haritası çizgileri bundan ayrıdır (K-032).
- **Asıl not:** [[Tasarım/Arayüz ve Büyük Ağ Yönetimi]].

## K-035 — Ürünler bağlantı boyunca gerçekten taşınır

- **Durum:** Onaylı; K-006'daki anlık aktarımın yerine geçer, eşit paylaşım kuralı aynen geçerli.
- **Tarih:** 2026-10-25.
- **Karar:**
  1. Ürün, 8x8 görüntüsüyle çizginin ortasında kaynaktan hedefe ilerler. Hedefteki sayı ürün yolun sonuna varınca artar; bu bir animasyon değil, simülasyonun kendisidir.
  2. Bağlantı silinince üzerindeki ürünler kaynağın çıkışına döner; çıkış kapasitesini aşan kısım kaybolur.
- **Kaynak:** “malzemelerin bu 8 piksellik genişlikte akışını yapman lazım. yani malzemenin 8x8 piksellik görüntüsü gerçekten çizgi üzerinde aksın ve hedef node a ulaşınca ordaki sayı 1 artsın. gerçek olacak yani sırf animasyon değil”; “çıkış kapasitesinin üstündeki malzeme direk kaybolsun”.
- **Sınır:** Asistan seçimleri: hız 60 px/sn, ürünler arası en az 10 px; yolun uzunluğu tuvaldeki çizgiden alınır; hedef doluysa ürünler yolun sonunda sıraya girer, yolun girişi doluysa kaynak yeni ürün göndermez; kaynak makine silinirse ya da reçetesi değişip ürünü artık üretmezse yoldaki ürün kaybolur; simge 32 px'lik ürün simgesinden küçültülür. Kayıt yoldaki ürünleri saklar.
- **Asıl not:** [[Tasarım/Ana Proje ve Ürün Dağıtımı]].

## K-036 — Bağlantılar üst üste binmez, kartların etrafından dolaşır

- **Durum:** Onaylı.
- **Tarih:** 2026-10-25.
- **Karar:** İki bağlantı çizgisi hiçbir yerde üst üste binmez; yan yana gidebilir, dik açıyla kesişirse biri diğerinin üstünden köprü gibi geçer. Çizgiler kartların arkasından geçmez, etraflarından dolaşır.
- **Kaynak:** “sağdan sola veya yukardan aşağıya çizilen çizgiler normalde godot editöründe üst üste biniyor. bizde bunun olamaması lazım. üstünden atlayıp köprü gibi geçebilir yanyana da gidebilir ama üstü üstüe binememsi lazım”; “Evet, çizgiler kartların arkasından da geçmesin, kartların etrafından dolaşsın.”
- **Sınır:** Asistan seçimleri: aynı çıkıştan (ya da aynı girişe) giden bağlantılar tek bant gibi birleşebilir; çizgi kartla arasında 4 px bırakır; yol bulunamazsa (kart bir portu kapatıyorsa) basit köşeli yol çizilir.
- **Asıl not:** [[Tasarım/Arayüz ve Büyük Ağ Yönetimi]].

## K-037 — Büyük ağda yol hesabı: yerel, parça parça, tuval koordinatında

- **Durum:** Onaylı.
- **Tarih:** 2026-10-26.
- **Karar:** 500 kartlık bir ağda bir kartı oynatmak oyunu kasmamalıdır. Önerilen dört çözümden üçü uygulanır: (1) her çizgi yalnız çevresindeki kartlarla küçük bir ızgarada hesaplanır; (2) kart oynayınca yalnız etkilenen çizgiler yeniden hesaplanır; (4) yollar tuval koordinatında saklanır, yakınlaştırma ve kaydırma yeniden hesap yaptırmaz. (3) sürüklerken seyrek hesaplama uygulanmaz, ileride gerekirse diye not edilir.
- **Kaynak:** “bu sistemde 500 tane kart olursa ne olacak peki ? kasma olur bu 1 kartı harehet ettirdik diye”; “1 2 4 okey 3 ü yapmayalım desem performansı yeterince arttırmış olmaz mıyız?”; “tamam planın güzel anlaştık yap”; “bu soruna uygulamadığımız biz çözüm vardı ya onu bir yere not et ilerde lazım olur belki”.
- **Sınır:** Ölçüm sade test kartlarıyla yapıldı (500 kart, 936 bağlantı: sürüklerken kare başına ortalama 11 ms, en kötü 19 ms); gerçek oyun kartlarıyla ölçülmedi. Ertelenen 3. çözüm [[Tasarım/Arayüz ve Büyük Ağ Yönetimi#Ertelenen çözüm: sürüklerken seyrek hesaplama|Arayüz ve büyük ağ yönetimi]] notundadır.
- **Asıl not:** [[Tasarım/Arayüz ve Büyük Ağ Yönetimi]].

## K-038 — Kartlardaki makine görseli 256 px

- **Durum:** Onaylı; kart standardındaki 128 px'in yerine geçer.
- **Tarih:** 2026-10-26.
- **Karar:** Makine kartındaki görsel alanı 256x256 px'tir.
- **Kaynak:** “128 küçük kaldı bu iş için ya bi büğü ne olabilir?”; seçenekler anlatıldıktan sonra “256 deneyelim birde”; denemeden sonra “256 kalsın, commit ve push yap.”
- **Sınır:** Asistan seçimleri: 128 px'lik eski görseller tam 2 kat büyütülerek gösterilir (yer tutucular yeniden çizilmedi); kart sheet'inin kare boyutu sheet genişliği / 4'tür, satır sayısı serbesttir. Başlangıçtaki ve örnek ağdaki kart aralıkları büyütüldü (yatay 480, dikey 360 px). Kart büyüklüğünün oynanışa etkisi (aynı ekranda daha az kart) denenmedi.
- **Asıl not:** [[Tasarım/Makine Kartları]].

## K-039 — Bağlantı noktası durumunu renkle gösterir

- **Durum:** Onaylı.
- **Tarih:** 2026-10-26.
- **Karar:**
  1. Kartın her giriş ve çıkış portu 24x24 px'lik bir çemberdir: dıştan içe 1 px siyah, siyaha doğru koyulaşan iki bej halka, 2 px f3eee4 halka ve ortada durum rengi.
  2. Üç durum vardır: bağlı değil turuncu; bağlı ve akış yolunda yeşil; bağlı ama parça alamıyor kırmızı.
- **Kaynak:** “siyak ile 24x24 çember çiz 1 piksel”; “içe doğru bej rengini tonları ile 1 piksel koyu 1 piksek daha açık sonra beya olacak şekilde”; “beyaz yerine f3eee4 bunu yap ve siyaha doğru bu renk koyulaşarak gitsin”; “f3eee4 bu renk 2 piksel çapda dursun kalan orta bölümü … bağlı ve parça alamıyorsa kırmızı, bağlı ve akış okeyse yeşil bağlı değilken turuncu olsun”; köşeli görünüme önerilen düzeltmeler için “tamam a b yap bakalım”; “4. durum yokmuş 3 yeterli oyuna koy bakalım”.
- **Sınır:** Asistan seçimleri: renkler (turuncu e8902f, yeşil 6aa84f, kırmızı d0523f, halkalar a89c86 ve d6cdbd), halkaların merkezden uzaklığa göre çizilmesi ve ara tonlar; kırmızının anlamı: giriş için makine bu girdiyi bekliyor ve tamponda yeterli yok, çıkış için çıkış tamponu dolu. Çember kartın kenarına ortalanır ve kartın üstünde çizilir. Çevrimler arasında kısa süre kırmızıya dönebilir; bekletme eklenmedi.
- **Asıl not:** [[Tasarım/Makine Kartları]].

## K-040 — Malzeme kutuları bağlantı çemberinin 2 px içinde

- **Durum:** Onaylı.
- **Tarih:** 2026-10-26.
- **Karar:** Kartın giriş ve çıkış kutuları bağlantı çemberinin bittiği yerden 2 px boşlukla başlar.
- **Kaynak:** “bu kartlardaki malzeme alanlarını koyduğumuz yuvarlarklarla sınır olacak şekilde ayarlayalim ama aralarında da 2 piksel boşluk olsun”.
- **Sınır:** Asistan seçimi: “+” düğmesine yer kalsın diye kartın yan sütunları 64'ten 80 px'e çıktı; kart 416 px genişliğindedir.
- **Asıl not:** [[Tasarım/Makine Kartları]].

## K-041 — Kart tek çerçevede, başlık çerçevenin içinde

- **Durum:** Onaylı yön; görsel geçici, kullanıcı kart için ayrı çerçeve çizecek.
- **Tarih:** 2026-10-26.
- **Karar:** Kartın tamamı tek bir çerçevenin içindedir; koyu başlık şeridi çerçevenin içinde durur ve çerçevenin kenarına dayanır.
- **Kaynak:** “ana akıştaki node larada bu bölümdeki kenarlığı koyalım. ana akıştaki başıklara da recipe deki başlık kenarlığını koyalım”; “böyle değil node çerçevesi komple çerçeve olcak. başlık onun bi içinde olacak”; “bu bölümde üst ve sağ solda bej renkler kaldı. başığın buraya dayanması lazım”; sonuçtan sonra “bu olmuyor bunu ayrıca çizmem lazım sanırım”.
- **Sınır:** Şu anki görseller envanter penceresinden ödünçtür (`flow_center_frame.png`, `recipe_top.png`); başlık şeridi üst köşe vidalarını örter. Kullanıcı için kartın ölçüleriyle 416x327 px'lik bir şablon hazırlandı (Downloads'ta `node_frame_sablon.png`). Seçili kartta çerçevenin dışına teal çizgi asistan seçimidir.
- **Asıl not:** [[Tasarım/Makine Kartları]].

## K-042 — Kullanıcı çizimi makine görselleri ve hareketleri

- **Durum:** Onaylı.
- **Tarih:** 2026-10-26.
- **Karar:**
  1. Ergitme fırını, Demir madeni ve Bakır madeni kullanıcının çizimlerinden yapılır; çizim 256 px'e sığdırılır, ortalanır ve çevresine 1 px siyah çizgi çekilir.
  2. Fırında yalnız ağızdaki alev hareket eder. Demir madeninde girişteki vagon tünele girip çıkar.
  3. Bakır madeni, Demir madeninin kopyasında yalnız cevher renklerinin bakıra çevrilmesidir; kayalar boyanmaz.
  4. Yeni görseller kullanıcı onaylamadan oyuna konmaz.
- **Kaynak:** “bunu nasıl yapcaz” sorusundan sonra “Küçült, 128'e sığdır” (sonra K-038 ile 256); “görünüyü ortala librede”; “bütün çevreyi 1 piksel siyah ile dolan”; “buna animasyon ekleyebilir misi? sadece göbekteki aleve versen yeterli”; “iron_mine daki backgorund olan beyaz lara silerek gerçek backgroynd yap”; “256'lık dosyada çalışmak (önerim): bunu yap”; “buna inmasyon yap girişteki cart içeri dışarı yapsın”; “oyuna hemen koyma bi okey diyelim önce”; “iron mine ın 256 lık olanını librede çoğaltıp sadece ilgili renkleri değiştirerek becerebilir misin”; kayalara eklenen bakırdan sonra “son yaptıklarını geri al üst sağ boya olmasın”; “256 256 döndür çevreyi siyah olsun animasyonu yap oyuna koy”.
- **Sınır:** Asistan seçimleri: Lanczos küçültme; fırın alevinin 12, madenlerin 32 karelik döngüsü (10 FPS); vagon tünele girerken küçülür, kararır ve sağdaki direğin arkasına geçer, arkasında kalan zemin raylar boyunca uzatılarak dolduruldu; madenlerde fenerlerin titremesi; bakır tonları. Kaynak çizimler henüz `art_src` altına alınmadı.
- **Asıl not:** [[Tasarım/Makine Kartları]].

## K-043 — Sınırlı harita ve kaynak yatakları

- **Durum:** Onaylı yön; ayrıntılar ilk taslak.
- **Tarih:** 2026-10-26.
- **Karar:**
  1. Sonsuz tuval, 500–600 kartın sığacağı büyüklükte sınırlı bir haritaya dönüşür.
  2. Haritada kaynak yatakları vardır; madenler yalnızca kendi türlerinin boş bir yatağına kurulur, her yatağa bir maden. Kaç maden kurulabileceğini yatak sayısı belirler.
  3. Mesafe bilerek bedelsizdir; taşıma oyuncunun işi olmaz (konveyör, hat planlama yok). Yatakların konumu yerleşimi kendiliğinden şekillendirir.
  4. Haritanın araştırmayla genişlemesi ileride değerlendirilir; arazi engelleri (nehir, dağ gibi geçilmez yerler) düşünülmüyor.
- **Kaynak:** “bu sonsuz canvas var ya. bunu bir map e dönüştürsek 500 600 kart yerleşcek şekilde büyütmek m”; seçeneklere “esas 1 numarayı düşünüyorum. 2 de iyi fikirmiş belki sora değerlendiririz 3 ü düşünmüyorum.”; mesafe bedeline “1 önemli değil yani mesefa aslında önemli değil olacak yine ama yatakların konumları zaten belirleyici olacak. çünkü konveyörleri de işin için katınca zaten dandik bir factorio ya doğru gidecek taşıma işini oyuncuya vermeyerek mekanikler kurma düşüncem var şu an .2. önerinde doğru. diğerlerine yaptıkça bakcaz artık”; “tamam hepsini yap bi görelim sonra gerekli yerleri revize ederiz”.
- **Sınır:** Asistan seçimleri: harita 20.000×12.000 px; yeni maden görünümün ortasına en yakın boş yatağa kurulur ve görünüm oraya kayar; sürüklenen maden aynı türün boş yatağına bırakılırsa taşınır, yoksa kendi yatağına döner; kartlar haritanın dışına çıkamaz; en fazla %8'e uzaklaşılır, mini harita açıktır; yataklar tükenmez; kayıtta her madenin yatağı saklanır, eski kayıtlardaki madenler en yakın boş yatağa yerleşir. Diğer makinelerin yatakların üstüne kurulması engellenmedi.
- **Asıl not:** [[Tasarım/Bölgeler ve Lojistik]].

## K-044 — Her maden ayrı bir dağda: 4 kaynak × 3 dağ

- **Durum:** Onaylı.
- **Tarih:** 2026-10-26.
- **Karar:** Yataklar dağ olarak çizilir ve her maden ayrı bir dağdadır. Dört kaynaktan (demir, kömür, bakır, kuvars) üçer tane, toplam 12 dağ vardır; dağlar birbirine yakın değildir.
- **Kaynak:** “tamamdır şimdi bunu oyuna koy bakalım bu dağ madenleri temsil edecek. yani her maden ayrı bir dağda olacak bu arada şu an çok maden var. 4 kaynak 3 taneden 12 maden olacak yani 12 dağ olacak. ve bunlarda birbirine yağın olmasın”.
- **Sınır:** Dağ görseli kullanıcının `dag2` çizimidir (pembe zemini betikle temizlendi, 647×504 px); 12 dağın hepsi aynı görseli kullanır. Asistan seçimleri: dağların yerleri (en yakın iki dağ arası 3.054 px), dağın altında cevher renginde, simgeli ve adlı etiket, başlangıçtaki demir madeninin ilk demir dağında olması.
- **Asıl not:** [[Tasarım/Bölgeler ve Lojistik]].

## K-045 — Harita süsleri: orman, tepe ve nehir

- **Durum:** Onaylı.
- **Tarih:** 2026-10-26.
- **Karar:**
  1. Haritada ormanlar vardır: kullanıcının ağacı rastgele küçük, normal ya da büyük; çalılar ormanların içinde. Kullanıcının `dag3` çizimi süs tepesi olarak dağıtılır.
  2. Haritayı bir nehir geçer. Nehir, kullanıcının nehir çiziminden çıkarılan su dokusu ve kayalarla oyunda bir yol boyunca kurulur; resim olduğu gibi tekrarlanmaz.
  3. Süsler (ağaç, çalı, tepe, nehir) hiçbir şeyi engellemez.
- **Kaynak:** Ağaç için “36 renge düşür”, “opaklığı 100 yap. sonra bunu oyundaki haritaya koy”, “çalı sayısını arttır agaçlarıda random büyük küçük normal yap.”; çalı için “ormanların içinde olsun bu”; tepe için seçeneklerden “Süs tepesi”; nehir için seçeneklere “valla sen bu 2 yi yap sana helal olsun”.
- **Sınır:** Asistan seçimleri: ağaç boyları %70 / %100 / %135 (aynı 36 renk); 288 ağaç ve 922 çalının yerleri; 28 tepe; nehrin yolu ve genişliği, kum dokusu (kullanıcı çiziminden değil, asistanın çizdiği bej doku), su dokusunun akması, kıyıdaki 45 kaya. Nehrin engel olup olmayacağı sorulmadı; şimdilik süs (S-030). Görsellerdeki pembe zeminin betikle temizlenmesi, kullanıcının “dag2 de arka plan daha pembemsi belki ayıt etmek senin için daha kolay olur” önerisiyle başladı.
- **Asıl not:** [[Tasarım/Arayüz ve Büyük Ağ Yönetimi]].

## Henüz karar olmayan yönler

| Konu | Kanıt düzeyi | Ayrıntı |
|---|---|---|
| Alternatif proses dengeleri | Kullanıcı olumlu karşılamış | K-017 ile farklı ürünler (Cast Iron vs Steel) üzerinden tekil tarifler belirlendi; nihai tüketici/performans dengeleri açık. |
| Bölgesel kaynak ve lojistik | Kullanıcı temkinli olumlu karşılamış | Bölge sistemi ve maliyetler kesinleşmemiş. |
| Aynı kartta paralel makineler | Asistan önerisi | Kullanıcı seçimi yok. |
| Ürünlerin üç tüketiciye ayrılması | Asistan önerisi | Ana hedef K-018 ile seçildi; araştırma, genişleme ve proje arasındaki tüketim üçgeni öneri olarak kalıyor. Genel paylaşım kuralı K-006 ile onaylı. |
| Para kullanmama | Asistan önerisi | Kesin ekonomi kararı değil. |
