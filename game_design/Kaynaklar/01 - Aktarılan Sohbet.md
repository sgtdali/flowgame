
Daha eski mesajlar yükleniyor…
Araştırma tüketim modeli olarak B: Doğrudan ürün tüketen araştırmalar seçiyorum. Bunu üretim zinciri oyunumuzun araştırma ekonomisi olarak ayrıntılı tasarlayalım.

Worked for 2m 9s
Üretim Zinciri Oyunu — Araştırma Ekonomisi v1.0
Seçilen model: B — Gerçek endüstriyel ürünleri doğrudan tüketen araştırmalar

Bence bu sistem, oyunumuzun temel mekaniklerinden biri olabilir. Çünkü çözmemiz gereken şey yalnızca teknolojilerin nasıl açılacağı değil, oyuncunun neden 5 dişli/dakika üretmekle yetinmeyip 500 dişli/dakika üreten bir endüstri kurmak isteyeceği.

Araştırmayı buna göre tasarlayacağız.

1. Temel kuralımız
Araştırma merkezleri, oyuncunun ürettiği gerçek parçaları kullanarak deneyler gerçekleştirecek.

Bilim puanı veya bilim paketi üretmeyeceğiz. Her araştırmanın kendine ait bir malzeme listesi ve deney süresi olacak.

Örneğin:

MEKANİK TEKNOLOJİLER

Endüstriyel Otomasyon I
Araştırma
Otomatik montaj sistemleri için mekanik dayanım ve kontrol deneyleri gerçekleştir.

Her deney için:

Dişli

2 adet

Bakır bobin

3 adet

Çelik levha

1 adet

Gerekli deney

60

Tek laboratuvarda deney süresi

10 saniye

Ödül: Otomatik Montaj Tesisi

Yeni tesis türü ve iki üretim reçetesi

Araştırmayı tamamlamak için toplam 120 dişli, 180 bakır bobin ve 60 çelik levha gerekiyor.

Ama burada önemli bir ayrıntı var.

Laboratuvar bu ürünleri tek seferde teslim almıyor.

Her 10 saniyede bir deney yapıyor ve o deneyin malzemelerini tüketiyor. Ancak malzemelerin tamamı mevcutsa deney başlayabiliyor.

Dolayısıyla laboratuvarın ne kadar hızlı çalışacağı, oyuncunun üretim ağının ne kadar malzeme sağlayabildiğine bağlı.

2. Mass production nasıl ortaya çıkıyor?
Yukarıdaki araştırmayı ele alalım.

Bir laboratuvarın tam kapasiteyle çalışması için dakikada şu ürünler gerekiyor:

Ürün

Gerekli üretim hızı

Dişli

12/dk

Bakır bobin

18/dk

Çelik levha

6/dk

Tedarik bu hızları karşılıyorsa araştırma 10 dakikada tamamlanır.

Ama oyuncu dakikada yalnızca 8 bakır bobin üretebiliyorsa, diğer iki malzemesi yeterli olsa bile araştırma yaklaşık 22,5 dakika sürer.

Oyuncunun çözmesi gereken problem açık:

Bakır bobin üretimini büyütmeliyim.

Diyelim ki onu da 18/dakikaya çıkardı. Artık laboratuvar tam kapasitede çalışıyor.

Sonra ikinci laboratuvarı inşa ediyor.

Bu kez gerekli üretim:

Ürün

1 laboratuvar

2 laboratuvar

Dişli

12/dk

24/dk

Bakır bobin

18/dk

36/dk

Çelik levha

6/dk

12/dk

İki laboratuvar yeterli malzemeyle çalışırsa aynı araştırma 5 dakikada tamamlanır.

Araştırma süresi karşılaştırması

Bakır bobin darboğazı

22,5 dk

1 laboratuvar, tam tedarik

10 dk

2 laboratuvar, tam tedarik

5 dk

Sabit üretim hızları ve kesintisiz tedarik varsayımıyla teorik süreler; ilk araştırmaların hedef süresi olarak düşünülmemeli.
Bu tam olarak istediğimiz teşvik mekanizması:

Daha fazla üretim → daha hızlı araştırma → daha gelişmiş üretim teknolojileri → daha karmaşık araştırmalar.

Ancak önemli bir tasarım kararı alıyorum: Araştırmaların hiçbirinde zorunlu zaman sınırı olmayacak. Yavaş fabrika da araştırma yapabilecek. Oyuncu daha hızlı ilerlemek istediği için üretimini artıracak.

Gerçek bir fark da burada ortaya çıkıyor. Factorio standart bilim paketleri tüketiyor; Satisfactory ise MAM araştırmalarında doğrudan belirli ürünler kullanıyor. Bizim sistemimiz bunların farklı bir birleşimi olacak: ürün bazlı malzeme gereksinimleri ve sürekli, kapasiteye bağlı araştırma tüketimi. 

Factorio Wiki
+1

3. Araştırma değişince eski üretim hatlarına ne olacak?
Bence B modelinin en tehlikeli noktası bu.

Diyelim ki oyuncu Otomasyon I araştırmasını bitirdi. Artık dişli, bakır bobin ve çelik levha istemiyoruz.

Sonraki araştırma Hidrolik Sistemler olsun; bu kez çelik boru, pompa gövdesi ve conta istiyor.

Oyuncu her araştırmada bütün üretim ağını yeniden düzenlemek zorunda kalırsa oyun bir süre sonra eziyete dönüşür.

Bunu üç kuralla çözeceğiz.

Kural A — Eski ürünler gelecekte yeniden kullanılacak
Araştırmalar tamamen birbirinden bağımsız malzeme listelerine sahip olmayacak.

Örneğin teknoloji ağacı şöyle gelişebilir:

Başlangıç Endüstrisi

Demir levha · Bakır tel · Bağlantı elemanları

Mekanik İşleme

Demir levha + bağlantı elemanları

Dişli üretimini açar

Çelik Üretimi

Demir levha + kömür

Çelik levhayı açar

Elektromekanik

Dişli + bakır tel

Bakır bobin üretimini açar

Endüstriyel Otomasyon I

Dişli + bakır bobin + çelik levha

Otomatik montaj tesisini açar

Dişli üretim hattı tek araştırmadan sonra gereksiz hale gelmiyor. Sonraki araştırmaların da girdisi oluyor.

Hedefimiz araştırmaların önemli bir kısmında daha önce kurulan üretim kapasitesini yeniden kullanmak. Ancak bunu kesin bir yüzdeye bağlamak yerine oynanış testlerinde ölçmeliyiz.

Kural B — Araştırma merkezi bir ürün dağıtım ağına bağlanacak
Araştırma merkezi, sonsuz canvas üzerinde gerçek bir düğüm olacak.


Birden fazla üretim hattının ortak araştırma merkezini beslemesi. Temsili bağlantı şeması.
Başlangıçta oyuncu bağlantıları elle kuracak. Gelişmiş lojistik teknolojileri açıldığında dağıtıcı düğümler, ürün filtreleri ve ortak malzeme hatları kullanabilecek.

Bir araştırma bittiğinde bağlantılar silinmeyecek.

Araştırma merkezinin kabul ettiği ürünler değişecek. Kullanılmayan hatların ürünleri küçük tamponlarda birikecek; tamponlar dolduğunda üretim duracak.

Bu sayede oyuncu yeni araştırma için yalnızca eksik üretim zincirlerini ekleyebilir.

Burada sınırsız, bütün haritadan malzeme ışınlayan bir global envanter kullanmamayı öneriyorum. Çünkü bağlantı ekonomisi ve lojistik optimizasyonu anlamını kaybeder.

Kural C — Araştırma değiştirmek ceza yaratmayacak
Oyuncu istediği zaman araştırmasını değiştirebilmeli.

Tamamlanan deneylerin ilerlemesi korunacak. Laboratuvarda başlamış bir deney tamamlanacak, ardından yeni araştırmaya geçilecek.

Böylece oyuncu aynı anda birkaç üretim zincirini geliştirebilir ve araştırma sırasını istediği gibi planlayabilir.

4. Teknoloji ağacının yapısı
Teknoloji ağacını tek bir uzun koridor şeklinde yapmamalıyız.

Oyuncu bazı teknolojileri farklı sıralarda açabilmeli.

Ben beş ana araştırma alanı öneriyorum.

Alan

Açtığı yetenekler

Örnek araştırma ürünleri

Metalürji

Alaşımlar, gelişmiş işleme

Levha, mil, alaşım

Mekanik

Dişli, rulman, motor, makine

Dişli, gövde, rulman

Kimya

Plastik, asit, reçine

Kimyasallar, tank, boru

Elektronik

Devre, sensör, kontrol

Bobin, devre kartı, sensör

Endüstriyel Sistemler

Otomasyon, verimlilik, lojistik

Motor, kontrol ünitesi, hassas parça

Alanlar taslak sınıflandırmadır. Her araştırmanın maliyet ve ön koşulları ayrıca belirlenecek.

Üç çeşit teknoloji ödülü yeterli olur.

Yeni yetenek: Daha önce üretemediğin bir ürünün veya kullanamadığın bir tesisin kilidi açılır.

Üretim iyileştirmesi: Mevcut tesiste kapasite artar, hammadde tüketimi azalır veya alternatif reçete açılır.

Ağ yönetimi: Dağıtıcı, filtre, önceliklendirme ve otomatik kapasite kontrolü gibi araçlar açılır.

Üçüncüsü özellikle önemli. Çünkü oyun ilerledikçe yalnızca daha fazla ürüne değil, o ürünleri yönetebilecek daha gelişmiş araçlara ihtiyaç duyacaksın.

5. Oyuncu istediği araştırmayı seçebilecek mi?
Tamamen serbest değil; ama doğrusal da değil.

Başlangıç teknolojileri basit olacak. Birden fazla araştırma kolu açıldığında oyuncu hangisine yatırım yapacağını seçebilecek.

Örneğin elektrik motorları üretebilmek için belirli mekanik ve elektronik teknolojiler gerekli olacak. Ancak gelişmiş kimya araştırmalarının tamamını önceden bitirmek gerekmeyecek.

Çok önemli bir dengeleme kuralımız olmalı:

Hiçbir araştırma, yalnızca kendi açacağı teknolojiyle üretilebilen bir ürünü isteyemez.

Bu tür döngüsel kilitlenmeleri otomatik test edeceğiz.

Ayrıca teknoloji ağacında oyuncunun henüz açamadığı ürünlerin gelecekte neden gerekli olacağı görülebilmeli. Böylece yeni araştırmalar sürpriz yaratırken oyuncunun uzun vadeli plan kurmasını da engellemez.

6. Araştırma ve ana proje arasındaki ilişki
Burada daha önce konuştuğumuz dört hikâye senaryosunu aynı altyapıyla destekleyebiliriz.

Örneğin Son Fabrika senaryosundaki Kurucu Çekirdek'i ele alalım.

Araştırma oyuncuya motor teknolojisini açtı. Oyuncu motor üretmeye başladı.

Motorlar artık üç farklı amaç için kullanılabiliyor:

Elektrik Motoru Üretimi

120 adet/dk

Araştırma

40/dk
Yeni teknoloji

Ana Proje

60/dk
Kurucu Çekirdek

Makine Yapımı

20/dk
Yeni üretim tesisi

Bu üç ihtiyacın aynı anda bulunması önemli.

Oyuncu bütün motorları araştırmaya gönderirse ana projesi ilerlemeyebilir.

Ana projeye öncelik verirse yeni teknolojileri daha yavaş açabilir.

Yeni makineler kurmak isterse ürettiği motorların bir kısmını genişlemeye ayırmalıdır.

Böylece oyuncunun önüne gerçek bir karar çıkar:

Mevcut üretimimi büyütmek için mi kullanayım, teknolojimi geliştirmek için mi, yoksa nihai hedefe ulaşmak için mi?

Bu aynı zamanda oyunumuzun yalnızca bir üretim hesaplayıcısı olmasını engelleyebilecek en güçlü mekaniklerden biri.

7. Araştırma ekonomisini dengelemek için kurallar
Her yeni araştırmada sadece gereken malzeme miktarlarını iki katına çıkarmak istemiyorum. Bu, sonunda bekleme süresini artırmaktan başka bir işe yaramaz.

Bunun yerine araştırma zorluğunu üç farklı şekilde artırabiliriz.

Zorluk kaynağı

Oyuncunun çözmesi gereken problem

Yeni malzeme

Yeni bir üretim zinciri kurmak

Daha yüksek tüketim hızı

Mevcut zinciri ölçeklendirmek

Ortak malzeme ihtiyacı

Sınırlı kapasiteyi araştırmalar ve ana proje arasında dağıtmak

İyi bir araştırma bunlardan en az birini anlamlı hale getirmeli.

Ayrıca dengelemede şu ilkeleri kullanacağım:

İlk araştırmalar hızlı olmalı. Oyuncu ilk yarım saatinde üretim zinciri kurma, laboratuvar besleme ve teknoloji açma döngüsünü birkaç kez deneyimlemeli.

Orta oyun araştırmaları yeni problemler doğurmalı. Yeterli üretimi olan oyuncu bir araştırmada dakikalarca boş boş beklemek zorunda kalmamalı. Beklerken başka bir üretim zinciri veya ana proje üzerinde çalışabilmeli.

Laboratuvar sayısı tek başına araştırmayı hızlandırmamalı. Ek laboratuvar ancak yeterli miktarda malzeme tedarik ediliyorsa fayda sağlamalı.

Zorunlu üretim hızı şartları nadir olmalı. İleri teknoloji kalifikasyonlarında ve ana projenin bazı aşamalarında kararlı üretim kapasitesi aranabilir. Ancak sıradan araştırmaların hepsine böyle eşikler koyarsak sistem gereksiz yere katılaşır.

8. Araştırma ekranı nasıl çalışmalı?
Oyuncu araştırma seçtiğinde sadece "120 dişli gerekli" görmemeli.

Asıl önemli bilgi, sisteminin bu araştırmayı ne kadar hızlı besleyebildiği.

AKTİF ARAŞTIRMA

Endüstriyel Otomasyon I
Darboğaz
Deneyler tamamlandı

24 / 60

Ürün

Gelen/dk

İhtiyaç/dk

Durum

Dişli	12	12	
Yeterli

Bakır bobin	8	18	
Eksik

Çelik levha	6	6	
Yeterli

Tahmini kalan süre

13,5 dk
En büyük darboğaz: Bakır bobin

Mevcut 8/dk tedarik hızını 18/dk seviyesine çıkarırsan tek laboratuvarın tam kapasiteye ulaşabilir.

Bu ekran örneğinde giriş hızları sabit, stok tamponları ihmal edilmiş ve tamamlanan deney sayısı 24 kabul edilmiştir. Gerçek oyunda tahmin son dönemlerdeki tedarik akışına göre güncellenecek.
Buradaki benim için en önemli özellik: Oyuncu darboğazın nerede olduğunu bulmak için bütün canvas'ı dolaşmak zorunda kalmamalı.

Bakır bobin satırına tıkladığında onu üreten ve taşıyan ilgili hatlar haritada vurgulanmalı.

Bu, yüzlerce ürün ve binlerce bağlantıya ulaştığımızda çok değerli olacak.

9. İlk prototipte ne yapacağız?
Bütün araştırma ekonomisini tek seferde geliştirmek hata olur.

Önce şu kapsam yeterli:

Sistem

İlk prototip

Araştırma sayısı

8

Teknoloji alanı

3

Ürün türü

15–20

Laboratuvar

1 tür, çoğaltılabilir

Araştırma tüketimi

Çok malzemeli deneyler

Aktif araştırma

Aynı anda 1

Araştırma değiştirme

Var, ilerleme korunur

Araştırma ekranı

Giriş hızı, talep, darboğaz

Üretim akışı

Gerçek düğüm bağlantıları

Ana proje tüketimi

1 küçük proje aşaması

Sonsuz araştırmalar

Henüz yok

Kod ajanlarına simülasyonu arayüzden bağımsız yaptırmalıyız. Deneylerin yalnızca bütün gerekli girdiler mevcutken başlaması, hiçbir malzemenin yoktan oluşmaması, iki laboratuvarın aynı stokları iki kez kullanamaması ve araştırma ilerlemesinin kayıt sırasında korunması gibi koşullar otomatik test edilmeli.

Özellikle teknoloji ön koşulları ve malzeme reçeteleri veri dosyalarından okunmalı. Böylece ileride 200 ürün eklemek için temel kodu sürekli değiştirmeye gerek kalmaz.

10. Henüz çözmediğimiz bir konu: Araştırma bittiğinde tüketim de bitiyor
Bence bu, ilerleyen aşamada ele almamız gereken en büyük konu.

100 araştırmanın tamamı açıldığında araştırma merkezleri duracak. Eğer ana proje de bitmişse üretim ekonomisinin büyük kısmında artık zorunlu tüketici kalmayabilir.

Factorio bunu tekrarlanabilir teknolojilerle de destekliyor. 

Factorio Wiki

Bizde ana zafer hedefinden sonra şu sistem çalışabilir:

Tekrarlanabilir endüstriyel araştırma programları.

Örneğin Hassas İmalat VIII araştırması, gelişmiş mekanik ürünleri tüketerek belirli tesislerde küçük verimlilik artışları sağlayabilir. Araştırmanın sonraki seviyeleri daha fazla endüstriyel kapasite isteyebilir.

Ama burada dikkatli olmamız gerekiyor: Sürekli artan verimlilik bonusları oyunun dengesini bozabilir. Sonsuz oyunun esas motivasyonunu yalnızca sayısal bonuslara bağlamak da doğru olmaz.

Bu nedenle ileri araştırmaların yanında tekrar üretilebilen büyük endüstriyel projeler bulunmasını daha uygun görüyorum.

Sonuç: Şu anda önerdiğim araştırma ekonomisi
Temel araştırma modelimiz netleşti

Tasarım önerisi v1.0 — henüz oynanışla doğrulanmadı

Üretim zincirleri

Endüstriyel parçalar ve ara ürünler

Araştırma

Teknoloji açar

Ana proje

Zafere ilerler

Altyapı

Fabrikayı büyütür

Daha gelişmiş ve daha büyük üretim zincirleri

Bu modelde ürünleri satarak para kazanmana gerek yok. Her parçanın değeri, fabrikanın gelişimine, araştırmaya veya nihai projeye yaptığı katkıdan geliyor.

Benim değerlendirmem: Bu araştırma sistemi, senin istediğin üretim zinciri oyununu taşımaya aday güçlü bir temel. Özellikle araştırma girdilerinin değişmesi, eski üretim hatlarının yeniden kullanılabilmesi ve üretimin araştırma, ana proje ve altyapı arasında paylaşılması stratejik derinlik yaratabilir.

Ancak henüz bir tasarımın çalışacağını değil, nasıl çalışmasını istediğimizi tanımladık.

Bir sonraki aşamada artık yalnızca araştırmayı değil, oyuncunun sıfırdan başlayıp ilk büyük endüstriyel teknolojiyi açmasına kadar geçirdiği 60 dakikayı tasarlamak en verimli adım olur. Hangi malzemeyi ilk üreteceği, araştırmaya ilk neyi teslim edeceği, ilk hangi darboğazla karşılaşacağı ve ilk anlamlı otomasyon başarısını nasıl elde edeceği bu sistemin eğlenceli olup olmayacağını gösterecek.

Peki guzel gidiyoruz ancak aklima bir sey takildi bu su an factorio nun konveyorsuz hali oldu resmen

Worked for 59s
Evet. Şu an tasarladığımız oyun neredeyse Factorio'nun konveyörsüz versiyonu oldu. Üstelik bu, düşündüğünden daha büyük bir problem.

Çünkü Factorio'da oyuncunun yaptığı en önemli işlerden biri fabrikasını fiziksel olarak tasarlamak. Makinelerin yerleşimi, konveyörler, lojistik ve alan yönetimi oyunun temel bulmacasını oluşturuyor.

Biz bunları kaldırdık ama yerine aynı derecede güçlü bir mekanik koymadık.

Şu an elimizde:

Factorio

Bizim oyun

Makineler yerleştir

Üretim düğümleri yerleştir

Konveyörlerle bağla

Çizgilerle bağla

Üretim reçeteleri

Üretim reçeteleri

Bilim paketlerini üret

Araştırma malzemelerini üret

Teknoloji aç

Teknoloji aç

Roket yap

Büyük endüstriyel projeyi tamamla

Yani oyunu sadeleştirirken oynanışın önemli bir bölümünü kaybetmiş olabiliriz.

Ancak ben üretim zinciri fikrinden vazgeçmezdim. Çünkü burada farklılaşabileceğimiz bir alan var.

Bence oyunun merkezi, üretim reçetelerini seçmek değil, üretim proseslerini tasarlamak olmalı
Factorio sana genellikle bir ürünün nasıl üretileceğini söylüyor. Sen de bu üretimi fiziksel olarak organize ediyorsun.

Bizim oyunumuzda ise oyuncu bir ürünü hangi yöntemlerle, hangi kalitede ve ne kadar verimli üreteceğini belirleyebilir.

Örneğin: Dişli üretimi
Oyuncunun dakikada 100 dişli üretmesi gerekiyor.

Ama elinde iki farklı üretim yöntemi var.

Yöntem A — Talaşlı İmalat

Yüksek kalite
Çelik Çubuk → CNC İşleme → Dişli
Çıktı

10/dk

Kalite

A

Yan ürün

Metal talaşı

Yöntem B — Döküm ve Son İşleme

Yüksek kapasite
Ergitme → Döküm → Taşlama → Dişli
Çıktı

30/dk

Kalite

B

Yan ürün

Döküm firesi

Değerler oyun dengesi için oluşturulmuş örnekler; gerçek imalat verileri değil.
Başlangıçta oyuncu yöntem A'yı kullanıyor.

Sonra araştırma yaparak yöntem B'yi açıyor. Daha hızlı dişli üretebiliyor ama kalitesi düşük olduğu için her üründe kullanamıyor.

İleride yeni bir araştırma ile ısıl işlem açılıyor. Bu işlem belirli koşullarda yöntem B'nin ürettiği dişlileri A kalitesine yükseltebiliyor.

Fakat ısıl işlem enerji ve başka malzemeler tüketiyor.

Şimdi oyuncunun çözmesi gereken gerçek bir problem oluşuyor:

Daha fazla CNC tezgâhı mı kurayım? Döküm hattı ve ısıl işlem tesisi mi kurayım? Yoksa ikisini farklı ürünler için birlikte mi kullanayım?

Bu kararlar onlarca farklı ürün arasında birbirine bağlanabilir.

Üç temel mekanik
Bence oyunumuza Factorio'dan farklı bir kimlik kazandırabilecek üç mekanik şu:

1. Alternatif prosesler: Aynı ürün birden fazla yöntemle üretilebilir. Yöntemlerin kapasite, kaynak tüketimi ve çıktı kalitesi farklıdır.

2. Yan ürün ekonomisi: Bir prosesin firesi başka bir prosesin girdisi olabilir. Endüstriler birbirini besler. Oyuncu kapalı döngü üretim sistemleri tasarlayabilir.

3. Ürün spesifikasyonları: Araştırmalar ve ana proje her zaman herhangi bir dişli istemez. Bazen belirli kalitede bir dişli, belirli saflıkta bir kimyasal veya belirli özellikte bir alaşım gerektirir.

Bunun gerçekçi bir mühendislik simülasyonu olması şart değil. A/B/C kalite sınıfları ve basitleştirilmiş proses kuralları yeterli olabilir.

Böylece oynanışın farkı ne olur?
Factorio'nun ana sorusu

Bizim oyunun ana sorusu

Bu ürünü nasıl otomatik üretirim?

Bu ürünü hangi prosesle üretmeliyim?

Makineleri nasıl yerleştirmeliyim?

Üretim yöntemlerini nasıl birleştirmeliyim?

Konveyörleri nasıl düzenlemeliyim?

Kapasite, kalite ve yan ürünleri nasıl dengelemeliyim?

Üretim hızını nasıl artırırım?

Üretim sistemimi nasıl daha verimli hale getiririm?

Elbette Factorio'da da alternatif süreçler, kalite ve geri dönüşüm gibi mekanikler bulunuyor. Dolayısıyla bu üç özelliğin varlığı tek başına özgünlük sağlamaz.

Farklılaşma şansımız, bu kararları yardımcı mekanikler olmaktan çıkarıp oyunun asıl oynanışı haline getirmekte.

Ama bunun bir bedeli var
Bu yaklaşım, basitçe sabit reçetelerden oluşan üretim zincirleri kurmaktan daha zor.

Özellikle ürün kalitesini, proses seçeneklerini ve yan ürünleri aynı anda dengelemek önemli bir tasarım ve test yükü oluşturur.

Bu nedenle ilk deneyde 200 ürün yerine 10–15 ürün, birkaç alternatif proses ve yalnızca üç kalite sınıfı kullanırdım.

Benim geldiğim nokta şu:

Factorio, büyük ölçüde fabrika yerleşimi ve otomasyonu üzerine bir oyun.

Biz ise endüstriyel proses tasarımı ve üretim ekonomisi üzerine bir oyun yapabiliriz.

Sonsuz 2D canvas, kapsamlı teknoloji ağacı, doğrudan ürün tüketen araştırmalar ve büyük bir nihai hedef yine mevcut olur.

Ama oyuncunun ustalaşmaya çalıştığı şey konveyör yerleşimi değil, birbirine bağımlı üretim proseslerinin tasarımı olur.

Sence bu fark yeterince ilgi çekici mi? Çünkü bence burada belirleyeceğimiz şey oyunun yalnızca bir özelliği değil, bütün kimliği.

Cok guzel fikir. Son aklimdaki sey ise factorioda oyuncunun bir haritasi var kaynaklar haritada daginik aslinsa miktar plarak cok kisitlayici olmasada konum olarak kaynak erisimi kisitli bu yuzden gorece cok sayida tesis kursada  belli bir oranda kurulum yapiliyor. Oyun sayisal olarak oyuncuya bir kisit koymasada mekansal plarak bir kisit koyuyor oyunun ilerleyen safhalarinda tren ile beraber uzaklara erisim ve daha fazla hammadde daha fazla uretim tesisi sansi oluyor. Simdi bizde boyle bir mekansallik yok. Sonsuz canvas. Bu konu nasil olacak

Worked for 1m 28s
Bence oyunun tasarımındaki en önemli eksik mekaniklerden birini daha buldun. Üstelik bu sorun çözülmezse, az önce konuştuğumuz alternatif üretim prosesleri de anlamını büyük ölçüde kaybedebilir.

Çünkü sonsuz canvas üzerinde oyuncu istediği kadar tesis kurabiliyorsa ve bütün kaynaklara sınırsız erişebiliyorsa, bir darboğazın çözümü çok basit hale gelir:

Yeterince üretmiyor musun? 10 tesis daha kur.

Factorio'da bunu yapmak her zaman kolay değil. Yeni bir maden yatağına ulaşmak, oradan malzeme taşımak, mevcut altyapıyı genişletmek ve bütün bunları fiziksel dünyaya sığdırmak gerekiyor.

Bizim oyunumuzda ise bu fiziksel sınırlamalar yok.

Ama bence çözüm, 2D sonsuz canvas'tan vazgeçmek değil.

Harita üzerindeki mekânsal kısıtların yerine, endüstriyel ağın yapısından doğan kısıtlar koyabiliriz.

Yani oyuncu istediği kadar çalışma alanına sahip olacak ama istediği üretim kapasitesini, istediği noktada ve istediği yöntemle kullanamayacak.

1. Çözüm önerim: Endüstriyel bölgeler ve lojistik kapasite
Oyuncunun sonsuz canvas'ını koruyalım. Ancak canvas üzerindeki konumla, üretim tesisinin ekonomik olarak bulunduğu yer birbirinden farklı olsun.

Canvas bir harita değil, oyuncunun sanayi sistemini tasarladığı çalışma alanı.

Oyun dünyasında ise farklı kaynaklara sahip endüstriyel bölgeler var.

Örnek: Üç endüstriyel bölge

Demir Havzası

Cevher çıkarma kapasitesi: 30/dk

Maden, dökümhane ve işleme tesisleri kurulabilir.

Taşıma: 8 birim/dk

Merkez Sanayi

Makine üretimi, montaj, araştırma

Yerel maden kaynağı bulunmuyor.

Taşıma: 5 birim/dk

Kimya Bölgesi

Hidrokarbon kaynağı: 20/dk

Kimyasal ve polimer üretim prosesleri için avantajlı.

Bölgeler haritada çizilmiş coğrafi alanlar olmak zorunda değil. Sonsuz canvas üzerinde çerçevelenmiş üretim grupları olarak temsil edilebilir.
Oyuncu hâlâ sonsuz canvas üzerinde istediği gibi düğümler düzenliyor. Ama bir tesis belirli bir bölgeye ait oluyor.

Bir bölgedeki hammaddeyi diğerine ulaştırmak için iki bölge arasında taşıma kapasitesi kurması gerekiyor.

Ekranda düğümlerin birbirine yakın çizilmesi, taşıma maliyetini ortadan kaldırmıyor. Çünkü bu çizim gerçek coğrafi uzaklığı temsil etmiyor.

Bu ayrım önemli.

2. Bu sistem oyuncuya nasıl stratejik karar verdirir?
Diyelim ki araştırma merkezinin dakikada 12 çelik levhaya ihtiyacı var.

Demir Havzası'nda dakikada 30 cevher çıkarabiliyorsun.

İki cevherden bir çelik levha üretilebildiğini varsayalım.

Ancak Demir Havzası ile Merkez Sanayi arasındaki taşımacılık kapasitesi yalnızca 8 birim/dakika.

Oyuncunun üç seçeneği var:

A — Cevheri doğrudan merkeze gönder

Merkezde çelik üret.

Ulaşan cevher

8/dk

Elde edilen çelik

4/dk

B — Çeliği maden bölgesinde üret

Eritme ve levha üretimini Demir Havzası'na taşı.

Yerel çelik üretimi

15/dk

Merkeze ulaşan çelik

8/dk

C — Taşıma altyapısını geliştir

Yerel çelik üretimini koru, nakliye kapasitesini 8'den 16'ya yükselt.

Yerel çelik üretimi

15/dk

Merkeze ulaşabilen çelik

15/dk

Bu örnekte üç farklı yatırım kararı oluştu:

Yerel üretim tesislerini büyütmek.

Ürünü hammadde olarak değil, işlenmiş halde taşımak.

Lojistik altyapısına yatırım yapmak.

Üstelik daha sonra araştırma merkezi çelik yerine çelikten üretilmiş hassas dişliler istemeye başlayabilir.

Bu kez dişlileri merkezde mi üretmelisin, yoksa maden bölgesinde işleyip daha az taşıma kapasitesi mi tüketmelisin?

Bence bu, fiziksel konveyörler olmadan da güçlü bir lojistik optimizasyon problemi yaratabilir.

3. Factorio'nun trenlerinin karşılığı bizde ne olacak?
Factorio'da oyuncu yeni kaynaklara erişmek ve uzak mesafelerden yüksek miktarda malzeme taşımak için demiryolları kullanabiliyor. 

Factorio

Bizde aynı ilerleme hissini bölgeler arası endüstriyel taşımacılık teknolojileri sağlayabilir.

Oyun aşaması

Lojistik sistemi

Yeni imkân

Başlangıç

Temel yük bağlantıları

Az sayıda ürünü bölgeler arasında aktarmak

Erken oyun

Yük terminali

Daha yüksek taşıma kapasitesi

Orta oyun

Toplu taşımacılık

Büyük miktardaki hammaddeleri ekonomik olarak taşımak

İleri oyun

Otomatik dağıtım ağı

Birden fazla bölgenin kaynaklarını talebe göre paylaşmak

Geç oyun

Entegre lojistik merkezleri

Karmaşık çok bölgeli sanayiyi otomatik yönetmek

Bunların sadece taşıma kapasitesini artıran yükseltmeler olmasını istemiyorum.

Örneğin otomatik dağıtım teknolojisi açıldığında, oyuncu bir bakır kaynağının ürünlerini üç ayrı üretim bölgesi arasında otomatik paylaştırabilecek.

Böylece teknolojik ilerleme yalnızca daha büyük sayılar değil, oyuncuya yeni kontrol yetenekleri kazandırır.

Benzer bir soyutlama örneği shapez 2 oyununda da var: Kaynaklar tükenmiyor, yapıların kurulumu ücretsiz; fakat platformlar arası aktarım ve taşıma kapasitesi yine önem taşıyor. Bizde bunun fiziksel bant yerleşimi yerine bölgesel ağ seviyesinde çalışmasını hedeflerdim. 

1.0 Release out April 23rd
+1

4. Sadece lojistik yeterli mi?
Bence değil.

Oyuncunun sınırsız tesis kurmasını engellemek istemiyoruz. Ama sınırsız tesis kurmanın otomatik olarak en iyi çözüm olmasını da istemiyoruz.

Bu nedenle üç doğal kısıt kullanabiliriz.

Kısıt

Etkisi

Çözümü

Hammadde erişimi

Her bölge aynı kaynaklara sahip değil

Yeni kaynak bölgelerine erişmek

Lojistik kapasitesi

Bölgeler arasında sınırsız ürün taşınamıyor

Bağlantıları ve terminalleri geliştirmek

Proses altyapısı

Bazı prosesler ek enerji, soğutma veya özel altyapı gerektiriyor

Uygun sanayi altyapısı kurmak

Üçüncüyü özellikle oyunun ileri aşamaları için düşünüyorum.

Örneğin gelişmiş bir kimyasal proses, yalnızca fabrikanın varlığıyla çalışmasın. Belirli bir endüstriyel altyapı da gerektirsin.

Ancak başlangıçta bu üç kısıtı birden oyuncuya yüklememeliyiz. İlk prototipte kaynak erişimi ve lojistik kapasitesi yeterli.

5. Sonsuz canvas nasıl korunacak?
Bu tasarımda iki ayrı kavram olacak:

Canvas: Oyuncunun üretim düğümlerini düzenlediği sınırsız çalışma alanı.

Endüstriyel bölge: Tesislerin hangi kaynaklara ve lojistik bağlantılara eriştiğini belirleyen ekonomik konum.

Bir tesisin canvas üzerindeki yerini değiştirmek onun bölgesini değiştirmeyecek. Başka bölgede üretim yapmak için oraya yeni bir tesis kurmak veya tesisi gerçekten transfer etmek gerekecek.

Bu sayede:

Sonsuz canvas üzerinde yerleşim özgürlüğü devam eder.

Çizgiler fiziksel konveyör simülasyonuna dönüşmez.

Kaynaklara erişim kısıtlı kalır.

Endüstriyel bölgeler arası lojistik anlamlı olur.

Büyük üretim ağları kurulabilir.

Ayrıca onlarca aynı tesis düğümü oluşturmak yerine, tesis gruplarını tek bir düğüm altında toplayabileceğiz. Örneğin bir çelik üretim düğümü 8 paralel tesis barındırabilir. Bu özellik, ileri safhada canvas'ın okunabilirliğini korumak için önemli.

6. Oyuncunun ilerleme hissi nasıl değişecek?
Başlangıç — Tek sanayi merkezi

Oyuncu birkaç yerel kaynağa erişir. Basit metalürji ve mekanik üretim zincirleri oluşturur.

İlk genişleme — Kaynak darboğazı

Daha ileri araştırmalar mevcut kaynağın sağlayabileceğinden fazla malzeme gerektirir. Oyuncu yeni bir kaynak bölgesini sisteme bağlar.

Orta oyun — Bölgesel uzmanlaşma

Her bölgede aynı üretimi yapmak verimsiz hale gelebilir. Oyuncu bazı bölgelerde hammadde işleme, bazılarında hassas üretim yapmaya başlar.

İleri oyun — Entegre endüstri

Kimya, metalürji, elektronik ve mekanik üretimler farklı bölgelerde birbirine bağlanır. Oyuncu taşıma kapasitesini ve ürün dağıtımını optimize eder.

Geç oyun — Endüstriyel imparatorluk

Ana projeyi beslemek için çok sayıda bölge ve karmaşık üretim prosesi birlikte çalışır. Oyuncunun esas görevi sistemin tamamını yönetmektir.

Böylece oyunun başındaki problemle sonundaki problem aynı olmayacak.

Başlangıçta bir dişliyi nasıl üretirim? diye düşünen oyuncu, ileri safhada beş farklı bölgenin girdilerini en verimli biçimde nasıl birleştiririm? sorusuyla karşılaşacak.

7. Peki bu oyun geliştirmeyi yeniden aşırı karmaşık hale getirir mi?
Burada dikkatli olmalıyız. Bu yaklaşım yeni bir simülasyon katmanı getiriyor.

Ancak fiziksel dünya koordinatları, yol bulma, araç animasyonları, konveyör çarpışmaları veya gerçek tren hareketleri gerektirmiyor.

Teknik olarak her bölge bir veri nesnesi olabilir:

Hangi kaynaklara sahip?

Hangi tesisleri barındırıyor?

Ne kadar ürün üretiyor ve tüketiyor?

Hangi bölgelere bağlı?

Bu bağlantıların kapasitesi ne?

Bölgeler arası malzeme akışı, sabit zaman adımlarıyla çalışan bir üretim ve taşıma simülasyonunda hesaplanabilir.

Bu, yine ciddi bir yazılım ve dengeleme işi. Fakat fiziksel fabrika simülasyonuna göre kapsamı daha kontrollü tutma ihtimali yüksek.

İlk deneyde yalnızca 2 bölge, 3 kaynak ve kapasitesi sınırlı tek bir bölgeler arası bağlantı kullanırdım. Bu bile yerel üretim ile merkezî üretim arasında gerçek bir tercih oluşturup oluşturmadığını göstermeye yeter.

Benim önerdiğim oyun kimliği artık daha net
Oyunumuzun üç büyük tasarım sütunu oluştu.

1. Derin üretim prosesleri

Alternatif üretim yöntemleri, kalite sınıfları, yan ürünler ve birbirine bağımlı yüzlerce üretim reçetesi.

2. Bölgesel üretim ve lojistik

Kaynak erişimi, yerel üretim avantajları, bölgeler arası sınırlı taşıma kapasitesi ve gelişen lojistik teknolojileri.

3. Üretimi tüketen araştırmalar ve ana proje

Malzeme tüketen deneyler, yeni teknoloji açılımları ve Factorio'nun roketine karşılık gelen büyük bir nihai hedef.

Benim bu aşamada en önemli tasarım ilkem şu olurdu:

Oyuncu istediği kadar tesis kurabilsin. Ama başarıyı tesis sayısı değil, hangi prosesi nerede kurduğu, hangi kaynaklara erişebildiği ve endüstriyel bölgelerini ne kadar iyi bütünleştirdiği belirlesin.

Burada bir uyarım var: Artık basit bir node tabanlı üretim oyunundan biraz uzaklaştık. Sade bir arayüze sahip ama ciddi derinliği olan endüstriyel strateji oyunu tasarlıyoruz. Altı aylık hedefi korumak için ilk sürümde özellikle bölgesel simülasyonu basit tutmamız gerekecek.

Ve bu modeli test ederken bakacağımız en kritik şey şu: Oyuncu kapasite sorunu yaşadığında yalnızca yeni tesis eklemek yerine, üretim yöntemi veya bölgeler arası iş bölümünü değiştirmeyi anlamlı bir seçenek olarak görüyor mu?

Bunu başarabilirsek, fiziksel bir harita olmadan da güçlü bir endüstriyel optimizasyon oyunu elde etme ihtimalimiz var.

Peki fena fikir degil. Son olara suna bakarmisin https://store.steampowered.com/app/3679930/Factory_Planner/

Worked for 41s
Factory Planner — Bizim oyun fikriyle karşılaştırma
Factory Planner
19 Ocak 2026 · Erken Erişim · Lebleby Games

Bu oyuna bakmamız çok iyi oldu. Çünkü Factory Planner, bizim ilk düşündüğümüz node tabanlı üretim oyununun oldukça yakın bir örneği.

Üstelik yalnızca görüntüsü değil; üretim zincirleri, teknoloji ağacı, enerji yönetimi ve otomasyon sistemi de benziyor.

Factory Planner on Steam
Factory Planner | Lebleby Games
Buy Factory Planner PC Steam - Instant Download - WinGameStore
Erken erişim
387 Steam değerlendirmesi · %70 olumlu

Steam'de 19 Ocak 2026'da yayınlanmış. Şu anda yaklaşık %70 olumlu değerlendirme oranına sahip. Bu, konseptin oyuncu bulabildiğini gösteriyor ama satış başarısını kanıtlamıyor. 

Steam Store

1. Factory Planner'da oyuncu ne yapıyor?
Maden, üretim, depolama ve enerji kartlarını çalışma alanına yerleştiriyor.

Kartların giriş ve çıkışlarını birbirine bağlıyor.

Katı malzeme, sıvı ve elektrik akışını yönetiyor.

Üretim reçeteleri seçiyor ve makineleri geliştiriyor.

Teknoloji ağacından yeni kaynaklar ve üretim kabiliyetleri açıyor.

Mühendis kartlarıyla tesislerin verimliliğini artırıyor.

Görevleri ve gelen siparişleri tamamlayarak ilerliyor.

Bunlar geliştiricinin Steam'de açıkladığı mevcut mekanikler. 

Steam Store

Yani Factory Planner, Factorio'nun fabrika yerleşimini kartlara ve bağlantı çizgilerine taşıyan bir yaklaşım kullanıyor.

2. Bizim tasarımla ne kadar benziyor?
Özellik

Factory Planner

Bizim tasarım

Serbest 2D çalışma alanı

Var

Var

Düğümlerle üretim

Kart tabanlı

Tesis tabanlı

Malzeme bağlantıları

Var

Var

Karmaşık üretim zincirleri

Var

Var

Teknoloji ağacı

Var

Var

Enerji yönetimi

Var

Henüz kararlaştırılmadı

Ürün siparişleri

Var

Şu an planlamıyoruz

Alternatif endüstriyel prosesler

Reçete seçimi var

Temel oynanış olmasını istiyoruz

Kalite / proses özellikleri

Merkezî bir mekanik olarak doğrulanmadı

Planlıyoruz

Yan ürün ekonomisi

Bazı çok çıktılı süreçler olabilir; kapsamı doğrulanmadı

Temel sistem olarak planlıyoruz

Kaynaklara bölgesel erişim

Keşif sistemi var

Bölgesel kaynak ve lojistik planlıyoruz

Büyük, somut zafer hedefi

Görevler/HUB ilerlemesi var

Hikâyeye bağlı ana proje planlıyoruz

Buradaki gerçek şu: Yalnızca kartlar yerine daha güzel tesis düğümleri koyarsak ve 200 farklı ürün eklersek yeterince farklı bir oyun yaratmış olmayız.

Asıl ayrışma üretim prosesleri, bölgesel kaynak ekonomisi ve oyuncunun verdiği endüstriyel kararlar üzerinden olmalı.

3. Oyuncu yorumları bizim için özellikle değerli
Olumlu yorumlarda oyuncular kartları bağlayarak fabrika oluşturmayı, otomasyon kurmayı ve üretimi büyütmeyi seviyor. Fakat olumsuz yorumlarda tekrar eden bazı sorunlar var.

Bunlar tek tek oyuncu görüşleri; herkesin aynı sorunları yaşadığını söyleyemeyiz.

Oyuncu şikâyeti

Bizim için çıkarım

Geç oyunda yüzlerce kart arasında kaybolmak

Büyük üretim ağları katlanabilir ve gruplandırılabilir olmalı

Üretim hızlarını ve darboğazları görememek

Her hat için giriş/çıkış ve verimlilik istatistikleri gerekli

Aynı üretim hattını tekrar tekrar elle kurmak

Blueprint, kopyalama ve tesis grupları şart

Çok sayıda ürünün aynı tekrarlı işlemleri gerektirmesi

Yeni ürünler farklı stratejik kararlar doğurmalı

Araştırma ve HUB ilerlemesinin fazla doğrusal olması

Birden fazla araştırma yolu sunulmalı

Görevler bitince tatmin edici bir son olmaması

Büyük ana hedef ve zafer anı gerekli

Özellikle 61,8 saat oynamış bir kullanıcının değerlendirmesinde geç oyun karmaşası, yetersiz üretim verileri, tekrar eden işlemler ve tatmin edici bir final bulunmaması ayrıntılı anlatılıyor. 

steamcommunity.com

Bence bu yorumlar, bizim bugün üzerinde durduğumuz iki temel sorunun — oyuncu motivasyonu ve büyük ağların yönetilebilirliği — ne kadar önemli olduğunu doğruluyor.

4. Geliştiricinin yaşadığı teknik sorun da önemli
Factory Planner geliştiricisi 8 Eylül 2026 tarihli duyurusunda, mevcut teknik altyapılarının çok sayıda kartı güvenilir biçimde destekleyemediğini ve oyunu yeni bir temel üzerinde yeniden geliştirmek zorunda kaldıklarını açıkladı.

Yeni sistemde teorik olarak 5.000 karta kadar alan sağlanacağını belirtiyorlar. Ayrıca doğrudan elektrik kablosu çekme zorunluluğunu azaltmak, dağıtıcıları iyileştirmek ve mühendis yönetimini basitleştirmek gibi değişiklikler planlıyorlar. Bunlar duyurulan çalışmalar; tamamının canlı sürümde olduğunu doğrulamadım. 

steamcommunity.com

Bu bizim için ciddi bir uyarı.

Senin hedefin birkaç yüz değil, belki binlerce tesisin yer aldığı bir üretim ağı.

Dolayısıyla Godot'ta:

Simülasyon hesaplamaları görsel düğümlerden bağımsız olmalı.

Aynı türdeki paralel tesisler gruplanabilmeli.

Ekran dışında kalan binlerce tesisin görsel güncellemeleri gereksiz yere yapılmamalı.

1.000, 5.000 ve 10.000 tesisli otomatik performans testleri erkenden hazırlanmalı.

Son madde bir kapasite vaadi değil; mimarinin ne kadar ölçeklenebildiğini belirlemek için test hedefi.

5. Peki bizim oyunun gerçek farkı ne olmalı?
Bence daha fazla ürün, daha uzun teknoloji ağacı veya farklı kart tasarımları yeterli değil.

Factory Planner'da oyuncu ağırlıklı olarak üretim hatlarını kurup çalıştırıyor. Bizim oyunumuzda ise üretim sisteminin nasıl tasarlanacağına karar vermesi ana mekanik olmalı.

Şöyle bir karşılaştırma yapalım.

Oyuncudan dakikada 100 adet yüksek kaliteli dişli üretmesini istiyoruz.

Factory Planner benzeri yaklaşımda ağırlık, gerekli tesisleri ve bağlantıları oluşturmakta.

Bizim hedeflediğimiz yaklaşımda ise şu seçenekler ortaya çıkmalı:

Hedef: 100 adet/dk A kalite dişli

Strateji

Avantaj

Bedel

CNC işleme

Yüksek kalite

Düşük kapasite, fazla talaş

Döküm + ısıl işlem

Yüksek kapasite

Daha fazla enerji ve proses

Dövme + son işleme

Daha az hammadde kaybı

Özel altyapı gerektirir

Aynı zamanda oyuncu karar vermeli:

Bu ürünleri hangi sanayi bölgesinde üretmeliyim?

Hangi kaynak yatağını kullanmalıyım?

Yan ürünleri başka proseslerde değerlendirebilir miyim?

Aynı üretimi besleyen başka araştırmalar var mı?

Böylece oyuncunun esas çözmeye çalıştığı bulmaca bağlantıları kurmak değil, endüstriyel üretim mimarisini oluşturmak olur.

Bu farklılaşmanın henüz prototiple doğrulanmadığını da vurgulayayım. Ayrıca alternatif reçeteler tek başına yeni bir mekanik değil. Onları stratejik kararların merkezine koymamız gerekiyor.

6. Bu araştırmadan sonra değiştireceğim üç karar
Birincisi: Her makine için ayrı düğüm zorunlu olmasın.

Oyuncu bir düğümde 1 CNC tezgâhı da yönetebilsin, 50 CNC tezgâhından oluşan üretim hücresi de. İsterse ayrıntılarına girebilsin.

İkincisi: Her ürüne yeni bir üretim zinciri kurmak zorunda kalmasın.

Mevcut tesisler farklı proseslerde yeniden kullanılabilsin. Makine kapasiteleri farklı ürünler arasında paylaştırılabilsin. Bu, tekrar eden inşa işlerini azaltır.

Üçüncüsü: Her yeni teknoloji yalnızca yeni bir ürün açmasın.

Bazen tamamen yeni bir üretim yöntemi açarak oyuncunun önceden kurduğu endüstriyi daha iyi hale getirmesine imkân versin.

Bu üçü, senin istediğin çok katmanlı üretim zincirini büyütürken oyunun yalnızca kart çoğaltma işine dönüşmesini önleyebilir.

Son değerlendirmem
Factory Planner'ın varlığı beni bu projeden vazgeçirmez, fakat rekabeti düşündüğümüzden daha ciddi hale getiriyor.

Çünkü node tabanlı, üretim zinciri ağırlıklı, sınırsız çalışma alanında oynanan bir oyun zaten piyasada bulunuyor.

Bu nedenle oyuncuya şu iki oyunun farkını kolayca anlatabilmeliyiz:

Factory Planner: Üretim makinelerini bağlayarak çalışan bir fabrika kur.

Bizim oyun: Alternatif endüstriyel prosesleri tasarla, sanayi bölgelerini birbirine bağla ve devasa bir üretim ekonomisini yönet.

Ben şu aşamada tek bir şeyi kesinlikle yapmazdım: Factory Planner'daki bütün özellikleri alıp üzerine araştırma, kalite, bölgeler ve yan ürün eklemeye kalkışmak. Bu bizi yine yıllarca sürecek bir projeye sokar.

Bunun yerine ilk prototipte yalnızca tek bir ürünün üç farklı yöntemle üretilebildiği ve bu yöntemler arasında gerçek stratejik tercihler oluştuğu sistemi test ederdim.

Çünkü o deney eğlenceli değilse, 200 ürün ve 5.000 tesis eklemek oyunu kurtarmayacak.

Benim vardığım sonuç: Oyunun özgünlüğü sonsuz canvas'tan değil, oyuncunun bir endüstri mühendisi gibi üretim sistemlerini tasarlayabilmesinden gelmeli.

Tesis derken bende uretimi node based kartlarda yapmayi hayal ediyordum canvas uzerinde aslinda
O zaman aynı şeyi düşünüyoruz. Benim “tesis” derken kastettiğim de aslında canvas üzerine yerleştirilen node tabanlı üretim kartlarıydı. Fiziksel fabrika binaları değil.

Yani görsel olarak Factory Planner tarzına oldukça yakın bir oyun hayal ediyoruz.

Benim kafamda şöyle bir yapı var
Örnek üretim zinciri

Demir Madeni

Cevher üretimi · 40/dk

Çelik Üretimi

Reçete: Elektrik ark ocağı

Çelik: 16/dk

Cüruf: 3/dk

CNC İşleme

Dişli: 8/dk

Talaş: 2/dk

Haddeleme

Levha: 12/dk

Çıktı: B kalite

Şematik örnek; gerçek oyunda bunlar sonsuz canvas üzerinde oyuncunun taşıyıp bağlayabileceği kartlar olacak.
Ancak burada benim tasarıma eklemek istediğim bir özellik var.

Bir kart = Bir makine olmak zorunda değil
Mesela oyuncu CNC İşleme kartı koydu.

Başlangıçta bu kart tek bir CNC tezgâhını temsil edebilir. Ancak oyuncu aynı kartın kapasitesini artırarak 10 veya 50 paralel CNC'den oluşan bir üretim grubu oluşturabilir.

CNC İşleme

10 paralel tezgâh
Proses

Dişli frezeleme

Kapasite

80 dişli/dk

Çelik tüketimi

100/dk

Yan ürün

20 talaş/dk

Bu kart aynı tipteki 10 makinenin üretimini toplu olarak temsil ediyor. İstersen farklı reçeteler için başka CNC kartları açabiliyorsun.

Böylece binlerce makineyi tek tek yerleştirmek zorunda kalmadan devasa üretim zincirleri oluşturabiliriz.

Ama bazı durumlarda oyuncu iki ayrı CNC kartı kullanmak isteyebilir. Örneğin birinde dişli, diğerinde mil üretmek için.

Factory Planner'dan farkımız ne olacak?
Bence görsel yaklaşımımızın benzemesinde sorun yok. Farklılığımız üç temel mekanikte ortaya çıkmalı:

Mekanik

Bizim yaklaşımımız

Alternatif prosesler

Aynı ürünü farklı üretim yöntemleriyle yapabilmek

Yan ürünler ve kalite

Atıkları değerlendirmek, farklı spesifikasyonlarda ürün üretmek

Bölgesel üretim

Kartların ekonomik bölgelere ait olması ve bölgesel lojistik sınırları

Örneğin iki çelik üretim kartı canvas üzerinde yan yana durabilir ama biri Demir Havzası'na, diğeri Merkez Sanayi'ye ait olabilir.

Bu durumda çizgi çekmek fiziksel yakınlık anlamına gelmez. Farklı bölgelerdeki kartlar arasında taşıma kapasitesi gerekir.

Ancak önemli bir tasarım kararı daha ortaya çıktı.

Bizim oyunumuzda bir kart:

A — Makine kartı mı olmalı? CNC tezgâhı, döküm ocağı, pres, torna gibi makineleri yerleştirir ve bunlara reçeteler atarsın.

B — Proses kartı mı olmalı? Döküm, haddeleme, talaşlı imalat, kimyasal ayrıştırma gibi üretim operasyonlarını yerleştirirsin. Makine sayısı ve teknik altyapı kartın özellikleri arasında bulunur.

Ben A'ya daha yakınım ama makine gruplandırma özelliğiyle birlikte. Çünkü CNC, pres, döküm ocağı gibi somut makineleri kurmak ve zamanla kapasitelerini büyütmek, yalnızca soyut proses kutularını bağlamaktan daha tatmin edici olabilir.

Bu seçim önemli; çünkü üretim zincirlerinin karmaşıklığı, kartların nasıl çalıştığına bağlı olacak.




Sohbet silindi

