# Fabrika Oyunu — Tasarım Belgesi

> Durum: **Faz 1-4 uygulandı.** MVP oynanabilir.
> Motor: Godot 4.6.1 · Hedef: Windows masaüstü, tek oyuncu

---

## 1. Anlayış Özeti

- **Ne kuruyoruz:** Node tabanlı bir fabrika oyunu. Oyuncu üretim hattını graf olarak
  kurar, hat gerçek zamanlı çalışır, ürün satılır, gelirle araştırma ağacından yeni
  istasyon ve ürünler açılır.
- **Neden var:** Asıl haz kaynağı **tıkanmayı çözmek**. Kuyruklar dolar, istasyonlar aç
  kalır, oyuncu darboğazı görür ve hattı yeniden tasarlar. Oyun bu döngü etrafında döner.
- **Kim için:** Ön bilgi gerektirmeyen jenerik fabrika dili (cevher → külçe → levha →
  montaj). Alan uzmanlığı gerekmez.
- **Nasıl çalışır:** Sabit tick'li ayrık parça simülasyonu. Her istasyonun kuyruğu ve
  ilerlemesi var. Reçeteler çoklu girdi → çıktı alabilir, yani ürün ağacı dallanır.
- **İlerleme:** Erken oyun parayla. Finalde Ar-Ge Laboratuvarı devreye girer; son
  araştırma para değil, laboratuvara **akıtılan ürün** ister.
- **Tavan:** İstasyon slotu limiti. Kademeli gelişimin motoru — "yeni istasyon mu, daha
  verimli istasyon mu" tercihi.
- **MVP hedefi:** Oyuncunun içeriği tüketmesi **en fazla 60 dakika**.

### Explicit non-goals

Offline kazanç · dinamik pazar · sözleşme/sipariş sistemi · enerji şebekesi ·
çoklu reçete seçici · birden fazla fabrika/harita · bitiş koşulu · iflas/başarısızlık ·
ses · çoklu dil desteği.

---

## 2. Varsayımlar

| # | Varsayım | Yanlışsa etkisi |
|---|---|---|
| V1 | Tek oyuncu, yerel, Windows masaüstü. Ağ yok. | Düşük |
| V2 | Tick hızı 10/sn, hedef 60 FPS, geç oyunda ~80 istasyon tavanı. | Orta |
| V3 | Parçalar ayrı node değil, kuyruklarda **sayaç**. Binlerce parça bedava. | **Yüksek** — performansın tamamı buna dayanıyor |
| V4 | Simülasyon deterministik: aynı kayıt + aynı tick = aynı sonuç. | **Yüksek** — offline ve test bunu gerektiriyor |
| V5 | İçerik veri güdümlü (`.tres`): yeni ürün/reçete/araştırma = dosya işi, kod değil. | Orta |
| V6 | Arayüz Türkçe, i18n altyapısı yok. | Düşük |
| V7 | Tek fabrika, tek harita. | Orta |

---

## 3. Karar Günlüğü

| # | Karar | Değerlendirilen alternatifler | Gerekçe |
|---|---|---|---|
| D1 | **Ayrık parça + tick** simülasyonu | Oran/throughput tabanlı; parti/sipariş tabanlı | Tıkanma ve kuyruk oyunun kalbi. Oran modeli sonucu doğru verir ama hissettirmez — oyun tabloya bakmaya döner. |
| D2 | **Çoklu girdi → çıktı** reçeteler | Tek girdi→tek çıktı; tipsiz tek "parça" | Ürün ağacının dallanması buna bağlı. Diğerlerinin üst kümesi olduğu için sonradan geçmek çekirdek yeniden yazımı demek. |
| D3 | **Aktif + duraklatmalı** zaman | Idle/offline; hibrit | Tıkanma yönetimi dikkat ister. Deterministik tick sayesinde offline'ı sonradan eklemek ucuz; tersi zor. |
| D4 | **Sabit fiyatlı satış node'u** | Sözleşme/sipariş; dinamik pazar | "Daha çok akıt = daha çok para" bağını doğrudan hissettirir. Diğer katmanlar bunun üstüne konabilir. |
| D5 | **Önce para, sonra Ar-Ge** | Sadece para; baştan Ar-Ge puanı | Basit başlar, derinleşir. Sadece para olursa araştırma bir bekleme sayacına döner; baştan Ar-Ge ise ilk 10 dakikayı boğar. |
| D6 | **İstasyon slotu limiti** | Enerji şebekesi; kısıt yok | Kademeli gelişimin doğrudan karşılığı. GraphEdit sonsuz tuval olduğu için fiziksel alan kısıtı bu yapıya ters. |
| D7 | **Jenerik fabrika teması** | Sanayi teması + oyunlaşmış sunum; fantastik dünya | Ön bilgi gerektirmez, ürün ağacı sezgisel dallanır. Ayrıca önceki içeriğin silinmesi gerekiyordu (D17). |
| D8 | **Simülasyon ayrı model** (`RefCounted`), GraphEdit sadece vitrin | Node'ların kendisi simüle etsin | Headless test, determinizm garantisi, offline yolu açık. Alternatif simülasyonu arayüze çivilerdi. |
| D9 | `progress` **int tick**, float değil | Float delta birikimi | Float birikimli yuvarlama hatası yapar; saatler sonra iki aynı kayıt farklı sonuç verir. |
| D10 | İstasyon kimliği **int id**, GraphEdit düğüm adı değil | Düğüm adını kimlik saymak | "İsim = kimlik" varsayımı bu projede zaten bir bağlantı kaybı hatasına yol açtı. |
| D11 | **İki fazlı tick** (üret → taşı) | Tek fazlı döngü | Tek fazda sonuç istasyon sırasına bağlı olurdu. İki faz "bir tick = bir adım" garantisi verir. |
| D12 | Fire **sayaçlı**, rastgele değil | Seed'li RNG | Determinizm bedavaya gelir; oyuncu örüntüyü öğrenip plan yapabilir. Rastgelelik burada haksızlık hissi üretir. |
| D13 | Portlar **reçeteden türer** | `BlockType`'ta elle port etiketleri | Tek gerçek kaynağı. Montaj'ın iki girişi olması reçetesinden gelir. |
| D14 | `ResearchNode.requires` = **id listesi** | `Array[ResearchNode]` referansı | Godot resource zincirleri derinleşince kırılgan. Id ile gevşek bağlamak düzenlemeyi de ucuzlatır. |
| D15 | Para **int** | Float para | Birikimli yuvarlama hatası. |
| D16 | Ar-Ge MVP **finalinde tek araştırma** | MVP'de hiç yok; baştan itibaren var | En belirsiz mekaniği gerçek oyunda test eder, kapsamı şişirmeden. MVP'ye doruk noktası verir. |
| D17 | Önceki savunma sanayi içeriği **silindi** | Saklamak / "gerçekçi mod" olarak tutmak | Kullanıcı talebi; kamuya açık paylaşımın hukuki riski. |
| D18 | MVP'de **bitiş koşulu yok** | Kazanma ekranı | Sonraya bırakıldı, henüz netleşmedi. |
| D19 | Başarısızlık yok, **sadece yavaşlama** | İflas / oyun sonu | Kurcalama hissini korur. |
| D21 | Fire, hurda kutusu doluysa **zarif bozulur** — parça sağlam geçer | İstasyonun kilitlenmesi (ilk davranış) | Faz 4 tempo koşumunda çıktı: Ret portu tıkanınca Kalite Kontrol elindeki hurdaya takılıp kalıyor, takıldığı için sağlam üretimi de duruyordu. Geri dönüşüm hattı bir döngü oluşturduğundan hurda hiç boşalmıyor ve fabrikanın TAMAMI kalıcı kilitleniyordu — gelir sıfıra düşüyor, oyuncunun çıkışı kalmıyordu. Artık tıkanma altında fire oranı düşer, hat ölmez. |
| D20 | İstasyon durumu **üç hâlli**: ÇALIŞIYOR / AÇ / TIKALI | Tek bir `blocked` bayrağı | Faz 2 denge koşumunda çıktı: AÇ ve TIKALI birbirinin **tersi** problem — aç kalan istasyonun suçlusu ÖNCEKİ, tıkananınki SONRAKİ istasyondur. Tek bayrakta birleştirmek oyunun asıl teşhis aracını kör ediyordu. |
| D22 | **Erken oyun araştırması ürün akıtmayla açılır**, Ar-Ge Sarayı ve Dağıtıcı oyunun başında kurulabilir | Erken oyunda da para; yalnızca finalde ürün maliyeti (eski durum) | Steam yorum analizi: "yeni unlock sadece yeni node olmamalı" ve tıkanmadan sonra oyuncunun elinde her zaman aktif bir optimizasyon problemi kalmalı. Ar-Ge Sarayı finale kadar kilitliyse ürün-maliyetli araştırma mekaniği ilk 50 dakika hiç denenmiyordu. Bina maliyeti 8000→450, Dağıtıcı 1400→350 — ikisi de artık `unlocked_at_start`. `Presleme` artık 40 cevher, yeni `Kalkan Zanaati` 25 levha, `Ara Depolama` 15 kalkan (yeni ürün: Külçe+Levha → Kalkan, iki üretim kolunun ilk birleştiği nokta) ister. Geç oyun zinciri (Haddeleme'den sonrası) parayla açılmaya devam ediyor. |
| D23 | **Kaynak rekabeti yeni içerik gerektirmez** — mevcut Dağıtıcı (ucuz/yavaş bölme) ve tekrar istasyon kurma (yatırımlı/üretken genişleme) zaten iki farklı stratejiyi destekliyor | Öncelik/oran ayarlı bölücü; kapasite artıran ayrı bir "geliştirme" mekaniği | `Kask Zanaati` ve `Kask Bantlama` (bkz. Levha/Külçe rekabeti) eklenirken YENİ bir sistem kurmak yerine var olan mekaniklerin doğal sonucuna güvenildi: Dağıtıcı round-robin böldüğü için toplam verimi ARTIRMAZ (ucuz+yavaş), ikinci Eritme/Pres kurmak parayla+işçiyle gerçek ek verim getirir (yatırımlı+üretken). Bu, hiçbir kod değişikliği gerektirmedi — yalnızca yeni talebin mevcut darboğazlara (Külçe, Levha) denk gelecek şekilde içerik tasarımı. |
| D24 | **Erken oyun ürün-maliyetleri `tools/balance_search.gd` ile ölçülüp ayarlandı** (Presleme 40→24 cevher, Kalkan Zanaati 25→15 levha, Kask Zanaati 35→60 kalkan; Kask Bantlama 20 kask sabit) | Elle oynayıp tahmin etmek; sabit bir kural (ör. "hep %25 kazanç") | Eski `progression_test.gd` bu araştırmaları hiç bilmiyordu (slot sistemi kalıntısıydı, derlenmiyordu) — yeniden yazmak yerine YENİ bir araç kuruldu çünkü soru farklıydı: "hangi strateji (bölerek/hedefli/ayrı hat) ne kadar sürede kazanıyor". Gerçek `FactorySim`+`ProgressionState` üzerinde üç strateji simüle edildi, iki senaryoda (normal/az sermaye) sınandı. Bulgu: Kask Bantlama'da MINIMUM'un dezavantajı MİKTARDAN bağımsız yapısal (Levha'yı iki atölye için art arda bölmek zorunda) — bu yüzden orada miktar büyütülmedi, en küçük aday tutuldu. Ayrıntı ve ham veri: `tools/balance_report.md` / `.json`. |
| D27 | **Erken oyun deneyi**: manuel market tahsilatı, Maden/Çiftlik kurulum sınırı (1), sade geliştirme sistemi, araştırma erişimi ilk geliştirmeye bağlı | Erken oyunda da otomatik satış+araştırma; sınırsız kaynak node'u | Hedef: oyuncu araştırmaya atlamadan önce "üret → tahsil et → geliştir → etkisini gör" döngüsünü yaşasın. **Tahsilat**: `FactorySim._run_sink` artık parayı `SimStation.accrued`'da biriktiriyor, `auto_collect` (Presleme'nin ödülü) açılana kadar kasaya (`revenue`) geçmiyor — satış hızı (`sold_counts`) bundan ETKİLENMİYOR. **Sınır**: `BlockType.max_instances` (Maden/Çiftlik=1) — GERÇEK istasyon sayısından hesaplanır, ayrı bir sayaç TUTULMAZ, bu yüzden silme/yükleme yolları yanlışlıkla aşamaz, eski kayıtlar budanmaz. **Geliştirme**: `SimStation.level`, reçete süresini `upgrade_duration_factor` ile çarpar (üretim HIZINI değiştirir, tampon kapasitesini değil — böylece "kaynak hızlanınca işleme sınırlayıcı olur" dinamiği gerçekleşir); yalnızca Gathering kategorisinde (Maden/Çiftlik) var — Eritme/Değirmen/Fırın gibi işleme atölyeleri bu deneyde YÜKSELTİLEMİYOR (bilinçli kısıtlama, işleme tarafı ilk deneyde sade kalsın diye), en fazla 3 seviye. **(D29'da Maden'in modeli katlanan-maliyet/toplamsal-hız olarak değişti, Çiftlik'in modeli AYNEN kaldı — kapsam dışıydı; ayrıntı D29'da.)** **Araştırma zamanlaması**: Ar-Ge Sarayı artık `unlocked_at_start` DEĞİL, `requires_first_upgrade` taşıyor — en az 1 geliştirme SATIN ALINMADAN açılmıyor; tek başına asla açılmayan bir oyuncu için 10 dakikalık bir zamanlayıcı GÜVENLİK AĞI var (birincil yol değil). Ölçüldü (`tools/intro_timing.gd`): kısa hatlar kurulunca artan parayla ilk geliştirme ANINDA karşılanabiliyor (0 sn) — tahsilat adımının BEKLENMESİ gerekmiyor, bu bilinçli bir gözlem, "ilk yatırım erişilebilir olsun" isteğiyle örtüşüyor ama tahsilat döngüsünü biraz atlanabilir kılıyor. Ar-Ge Sarayı'nın fiilen KURULMASI ~160-180 oyun-sn (~0.7-0.8 dk @4x) sürüyor, tahsilat aralığından (10-45 sn) neredeyse BAĞIMSIZ — üretim hızı, tıklama sıklığından daha belirleyici. **Bilinen sınır**: `tools/balance_lib.gd`'nin hedefli/ayrı hat stratejileri 2./3. Maden/Çiftlik KURARAK çalışıyordu — artık `max_instances` bunu engelliyor, bu araçlar bu turda güncellenmedi. **Düzeltme (aynı gün)**: Yükselt/Tahsil Et düğmeleri başta sağ paneldeki denetçideydi — oyuncunun her tıklama için önce düğümü seçip panele bakması gerekiyordu, ayrıca üst bara eklenen Market etiketi+değeri+düğmesi de bar'ın toplam genişliğini aşırıp sağ uçtaki hız/kaydet düğmelerini ekran dışına itti. İkisi de aynı kökten: aynı bilgi/eylem birden çok yerde çoğaltılmıştı. Artık `FlowBlock` kendi altına bir "Seviye" satırı, bir "Market" satırı ve Yükselt/Tahsil Et düğmelerini doğrudan basıyor (`action_requested` sinyaliyle yukarı, `FlowCanvas` üzerinden `GameController`'a); denetçi panelinden bu ikisi tamamen kaldırıldı. Üst bardaki Market etiketi tek satıra indirildi ("Market: X gold"). |
| D26 | **Denge aracının "MINIMUM" stratejisi, çıktıyı gereksiz yere satışla bölüyordu** — gerçek oyuncu turuyla karşılaştırınca bulundu, düzeltilmedi (ayrı "Dönüştür" varyantı eklendi) | MINIMUM'un tanımını değiştirmek | Oyuncu tek zinciri "dönüştürerek" (satışı bırakıp %100 araştırmaya yönlendirerek) ~5 gerçek dakikada/4x hızda son araştırmaya ulaştı; araç "MINIMUM" için 2260 sn (~9.4 dk) raporluyordu. İki ayrı hata bulundu: (1) `ACTION_SECONDS` toplam süreye EKLENİYORDU — gerçek oyunda sim tıklama sırasında durmuyor, bu yanlış; (2) MINIMUM modeli hiçbir yeni satın alma gerekmediği hâlde çıktıyı hep {sat, laboratuvar} arasında bölüyordu — oyuncunun "dönüştürme" tarifiyle örtüşmüyordu. "Dönüştür" varyantı (bkz. `tools/balance_playtest_compare.gd`) ~6.1 dk verdi, oyuncunun ~5 dakikasına çok daha yakın. Kalan ~1 dakikalık fark açıklanamadı — telemetri olmadan iddia edilmedi. **Sonuç: mevcut MINIMUM tanımı DEĞİŞTİRİLMEDİ (kullanıcı isteği), ama gelecekteki değer önerileri için hangi strateji varyantının temel alınacağı netleşmeden güvenilir olmayacağı not edildi.** |
| D29 | **İlk 4 aşamalı hat (Maden→Eritme→Sevkiyat→Tahsilat) ekonomisi**: Maden'de maliyeti KATLANAN/hızı TOPLAMSAL artan üretim geliştirmesi, Sevkiyat'ta maliyeti KATLANAN/değeri TOPLAMSAL artan satış geliştirmesi | Her ikisinde de aynı çarpımsal (katlanan) hız modeli; yalnızca birini geliştirilebilir bırakmak | Kapsam yalnızca bu 4 aşama — yeni node YOK, Eritme yükseltilemez halinde kaldı (D27), işçi/gıda sistemi YENİDEN TASARLANMADI. **Üretim hızı**: `BlockType.upgrade_rate_increment` (Maden'de 15.0 cevher/dk/seviye) — `duration_ticks_at_level()` HEDEF hızı (taban + artış×(seviye-1)) hesaplayıp geriye tick süresine çevirir; maliyet `upgrade_cost_growth=2.0` ile KATLANIR (150→300→600 TL) ama hız KATLANMAZ (60→75→90→105 cevher/dk) — `SimStation.effective_duration_ticks()` VE `FlowBlock`'un "sonraki hız" yazısı AYNI bu fonksiyona bakar, ikisi ayrışamaz. **Satış değeri**: `BlockType.sell_multiplier_at()` — her seviye taban fiyata TOPLAMSAL +%100 ekler (×1→×2→×3→×4, seviye farkı hep +1, ÖNCEKİ TOPLAMI katlamaz), `FactorySim._run_sink`'te `item.base_price * count * station.sell_value_multiplier()` olarak uygulanır; maliyet burada da ×2.0 katlanır (900→1800→3600 TL). **Eritme darboğaz KONTROLÜ**: eritme 2 cevheri 14 tick'te işliyor → tavanı 85.7 cevher/dk; Maden'in ilk İKİ seviyesi (60, 75 cevher/dk) bu tavanın altında TAM gerçekleşiyor, 3. seviyede (90) hafifçe (~%5) aşıyor — "ilk birkaç geliştirme görünmeyen darboğazda kaybolmasın" isteği, Eritme'ye DOKUNMADAN, yalnızca artış miktarı (15/dk) seçilerek karşılandı. **Gerçek denge** (`tools/chain_balance.gd`, ayrıntı `tools/chain_balance.md`): "hiç geliştirme alma" stratejisi PARA olarak 1-2 dakikada yeterli olsa da her zaman TAM 10 dakika sürüyor çünkü D27'nin araştırma kapısı en az 1 geliştirme ister — bu, herhangi bir geliştirme almayı otomatik olarak ödüllendiriyor. Yalnızca Maden'i 3 kez geliştirip durmak (RATE_MAX, 1050 TL) ~9 dk'da kendini ödüyor ve sonra sabit bir ek getiri veriyor — düşük risk. Yalnızca Sevkiyat'ı 3 kez geliştirip durmak (VALUE_MAX, 6300 TL) 10-14 dk'ya kadar HENÜZ ödemiyor (çarpımsal etki küçük bir tabana uygulanıyor) ama sonra katlanarak büyüyor — yüksek risk/yüksek getiri. Bu asimetri KASITLI DEĞİL, kullanıcının sabit "+%100 toplamsal, maliyet katlanır" formülünün ÇARPIMSAL bir yükseltmeyi doğası gereği TOPLAMSAL bir yükseltmeden güçlü kılmasının doğal sonucu — tek ayarlanabilir karşı ağırlık Sevkiyat'ın TABAN maliyetiydi (400→900 TL'ye çıkarıldı, büyüme oranı kullanıcı isteği gereği ×2.0 sabit kaldı). **Gıda/işçi darbogazı**: `GameConfig.START_FOOD` 30→300 (5 işçi × 1 gıda/dk upkeep ile eskiden 6 dakikada tükenip istasyonları AÇ/HUNGRY durdururdu — "hiç geliştirme alma" stratejisinin kendisi 10 dk sürdüğünden bu GÖRÜNMEYEN bir darboğaz olurdu); işçi/gıda MEKANİĞİ değişmedi, yalnızca başlangıç STOĞU büyütüldü ve kalıcı olarak sınırsızlaştırılmadı (16 dk'lık gerçek-START_FOOD koşumuyla doğrulandı). Doğrulama: 31 kontrollü geçici bir script (maliyet katlanması, hız/değer toplamsal artışı, tahsilat muhasebesi carpanlı, kayıt/yükleme + ESKİ kayıt geriye dönük uyumluluğu — eski kayıtta `level` alanı hiç yoksa varsayılan 1 = fiyat DEĞİŞMEMİŞ) yazılıp çalıştırılıp silindi; `sim_test.gd`/`workforce_test.gd` regresyonsuz geçti. **Düzeltme (aynı gün)**: kullanıcı geri bildirimiyle Sevkiyat'ın satış-değeri geliştirmesi TAMAMEN KALDIRILDI ("market stall'da upgrade'e gerek yok") — `sevkiyat.tres`'te `upgradeable` tekrar `false`, `BlockType.sell_multiplier_at()`/`SimStation.sell_value_multiplier()`/`FlowBlock`'un "Sell" satırı ve SINK dallanması SİLİNDİ (artık hiçbir yerde çağrılmıyordu, ölü kod bırakılmadı), `_run_sink` eski `base_price * count` hesabına döndü. Maden'in katlanan-maliyet/toplamsal-hız üretim geliştirmesi AYNEN duruyor — yalnızca satış tarafı geri alındı. `tools/chain_balance.md`/`chain_balance.gd` bu kararın ARDINDAN üretilen analizi kayıt altında tutuyor (tarihsel referans), güncellenmedi. |
| D28 | **Sağ panel Denetçi DEĞİL, Araştırma ağacı** — sabit değil, sağ alttaki yüzen "Knowledge" düğmesiyle açılır, tuvale tıklayınca veya tekrar basınca kapanır | Denetçiyi korumak; Araştırmayı ayrı bir tam-ekran modal olarak bırakmak | `BlockInspector`'ın son işlevi (isim düzenleme, İşçi Ata düğmesi, salt-okunur bilgiler) sırayla ANLAMINI YİTİRDİ: bilgiler zaten düğümün üstünde (rozet, ipucu, Seviye/Market satırları — D27), İşçi Ata da Yükselt/Tahsil Et'in izinden buraya taşındı (`FlowBlock._worker_button`, `action_requested` ile `&"worker"`). Geriye kalan tek iş — seçili düğümü göstermek — hiçbir zaman gerekmiyordu artık. `block_inspector/` klasörü SİLİNDİ. Boşalan `RightSplit` yuvasına `ResearchPanel` taşındı (tam-ekran `Dim`/`Center`/`Frame` sarmalayıcısı kaldırıldı, artık `HSplitContainer`'ın normal bir çocuğu — `PanelContainer`, sabit `custom_minimum_size`). Gizliyken `HSplitContainer` onu layout'tan tamamen DIŞLAR (Container kuralı), Canvas otomatik tam genişliğe döner — ayrı bir animasyon/collapse kodu YAZILMADI. Kapatma iki yoldan: yüzen düğmeye tekrar basmak, veya `FlowCanvas._gui_input`'ta eklenen `interacted` sinyali (düğümün kendi Button'ları input'u TÜKETTİĞİ için bu sinyali TETİKLEMEZ — yalnızca boş alan/düğüm sürükleme gibi GraphEdit'in kendisine ulaşan tıklamalar). Üst bardaki "Knowledge" düğmesi kaldırıldı, yerini yüzen düğme aldı. |
| D25 | **Araştırma takip paneli mevcut Araştırma paneline GÖMÜLÜ** (yeni pencere değil), hız ölçümü `RateMeter`'ın (D9 civarı çözülen dalgalanma sorunu) üstüne ince bir katman | Ayrı bir HUD widget'ı; kendi hız algoritmasını yazmak | "Gör → müdahale et → sonucu gör" döngüsü zaten Araştırma panelinde yaşıyor, ayrı pencere ekstra tıklama demek. `ResearchDeliveryTracker`, `RateMeter`'a yalnızca 4 salt-okunur getter (event_count, has_measurement, avg_interval_ticks, ticks_since_last_event) ekleyip MEASURING/STOPPED/VARIABLE/STABLE durumu türetir — dalgalanmayı çözen asıl algoritmaya DOKUNMAZ. Beklenmedik bulgu: Dağıtıcı gibi tipsiz istasyonların çıktı tamponu bir tick içinde dolup boşaldığından, "bu hat hangi ürünü taşıyor" sorusu ANLIK tampona bakarak neredeyse hep BOŞ dönüyordu — `FactorySim._last_transferred_item` (gerçekleşen son aktarımı hatırlayan küçük önbellek) eklenerek düzeltildi. "En yavaş ürün" ile "kök neden atölye" kasıtlı olarak AYNI ŞEY sunulmuyor — "Bul" düğmesi yalnızca DOĞRUDAN besleyen istasyonu seçip ortalıyor, zincirde geriye otomatik yürümüyor (kapsam sınırı, D-notu). |

---

## 4. Tasarım

### 4.1 Katmanlar

```
SUNUM      GraphEdit · FlowBlock · Palet · Araştırma paneli · Üst bar
           (hiçbir şeye sahip değil, sadece yansıtır)
              ↑ sinyal              ↓ komut
ORKESTRA   GameController
              ↑ sinyal              ↓ komut
MANTIK     FactorySim · Economy · ResearchTree      ← gerçeğin sahibi
VERİ       ItemType · Recipe · BlockType · ResearchNode  (.tres)
```

Kural: **sinyal yukarı, çağrı aşağı.** Sunum katmanı veriyi asla doğrudan değiştirmez.
Simülasyon `Node` değil `RefCounted` — sahne ağacında yaşamaz, `_process` kullanmaz.

### 4.2 Simülasyon çekirdeği

```gdscript
class SimStation:                 # RefCounted
    var id: int                   # kalıcı kimlik
    var type: BlockType
    var recipe: Recipe
    var input: Dictionary         # item_id -> adet
    var output: Dictionary
    var progress_ticks: int
    var next_output_link: int     # round-robin sayacı

class SimLink:
    var from_id: int;  var from_port: int
    var to_id: int;    var to_port: int
```

**Tıkanma mekaniği:** `output` dolu bir istasyon yeni üretime başlayamaz. Dolu çıktı →
istasyon durur → ondan öncekinin çıktısı dolar → tıkanma zincir boyunca geriye yürür.
Oyuncunun göreceği ve çözeceği şey bu.

### 4.3 Tick döngüsü

```gdscript
func tick() -> void:
    _tick_count += 1
    _phase_produce()    # üret / ilerlet
    _phase_transfer()   # çıktıdan komşunun girdisine taşı
```

**Üretim fazı** (her istasyon):
- Üretim sürüyorsa `progress_ticks += 1`; dolduğunda çıktı `output`'a düşer
- Boştaysa **ve** girdi reçeteyi karşılıyorsa **ve** çıktıda yer varsa → girdiyi tüket,
  üretime başla
- Kaynak istasyon girdi istemez, sabit aralıkla üretir
- Sevkiyat girdiyi yutar ve `Economy`'ye satışı bildirir

**Taşıma fazı:** her çıkış portundaki bağlantılar **round-robin** denenir. Bir çıkışta iki
bağlantı varsa yük kendiliğinden dengelenir, determinizm bozulmaz.

**Neden iki faz:** Tek fazda id'si küçük zincirler bir tick'te baştan sona akar, büyükler
beklerdi. İki faz "bir tick'te her ürün en fazla bir adım ilerler" garantisi verir.

**Hız kontrolü:**
```gdscript
_accumulator += delta * TICKS_PER_SECOND * speed   # temel 10 tick/sn
while _accumulator >= 1.0 and processed < MAX_PER_FRAME:
    sim.tick(); _accumulator -= 1.0; processed += 1
```
`MAX_PER_FRAME` tavanı zorunlu — yoksa bir kare takıldığında tick borcu birikir ve oyun
kendini daha da yavaşlatarak geri dönemez hâle gelir.

### 4.4 Veri modeli

```gdscript
class_name ItemType extends Resource
    id, display_name, color, icon_char
    base_price: int               # int — float para yuvarlama hatası yapar

class_name Recipe extends Resource
    inputs:  Array[RecipeSlot]    # RecipeSlot = { item: ItemType, count: int }
    outputs: Array[RecipeSlot]
    duration_ticks: int

class_name ResearchNode extends Resource
    requires: PackedStringArray   # id listesi (Resource referansı değil)
    cost_money: int
    cost_items: Array[RecipeSlot] # doluysa Ar-Ge Lab gerektirir
    unlocks_blocks: Array[BlockType]
    slot_bonus: int
```

`BlockType` sadeleşir: kimlik, görsel, maliyet ve **bir reçete referansı** tutar. Port
etiketleri reçeteden türetilir.

### 4.5 MVP içeriği

**Ürün ağacı — 6 kademe**

| Ürün | Reçete | Fiyat |
|---|---|---|
| Cevher | (Maden Ocağı üretir) | — |
| Külçe | 2 Cevher | 10₺ |
| Levha | 1 Külçe | 28₺ |
| Çubuk | 1 Levha | 26₺ |
| Vida | 1 Çubuk → 2 Vida | 20₺ |
| **Gövde** | 2 Levha + 3 Vida | **150₺** |

**Araştırma sırası — 10 düğüm**

Presleme → Fabrika Genişlemesi I → Haddeleme → Kesim → Fabrika Genişlemesi II →
Ara Depo → **Montaj** → Kalite Kontrol → Geri Dönüşüm + Ar-Ge Lab →
**Otomasyon II** (150 × Gövde ister)

Slotlar: başlangıç **5** → Genişleme I **9** → Genişleme II **14**

> Bu sayılar `tools/progression_test.gd` ile ÖLÇÜLEREK ayarlandı, tahmin edilmedi.
> İlk koşum 231 dakika verdi (hedef 60) ve son aşamaya hiç ulaşılamadı. Üç turda
> maden ocağı hızı iki katına çıkarıldı, gövde fiyatı 150 → 220 yapıldı ve
> araştırma maliyetleri yaklaşık yarıya indirildi. Son ölçüm: **63.3 dakika.**

**Ölçülen tempo (son hâli)**

| Aşama | Süre |
|---|---|
| Başlangıç hattı | 0.0 dk |
| Pres | 6.9 dk |
| İkinci ön hat | 10.1 dk |
| Vida hattı | 18.0 dk |
| Montaj hattı | 33.0 dk |
| Kalite Kontrol | 39.4 dk |
| Ar-Ge Laboratuvarı | 50.9 dk |
| Derin Maden (final) | 63.3 dk |

### 4.6 Sunum katmanı

`FlowBlock` artık sim id tutar ve her kare durumunu okur: ilerleme çubuğu, giriş/çıkış
kuyruk sayaçları, `TIKALI` rozeti. Palet sadece açılmış istasyonları gösterir, kilitliler
soluk durur. Üst bara para / slot (7/9) / hız kontrolü girer. Araştırma paneli yeni.

Güncelleme **tek bir döngüden** yapılır: `GameController` her karede sim'i okuyup
FlowBlock'lara yazar — 80 node'un her birine ayrı `_process` konmaz. `Label.text` yazmak
pahalı olduğundan (font shaping) değer değişmediyse yazılmaz.

Kablolarda akan noktalar MVP kapsamı dışında.

### 4.7 Kaydetme

Mevcut JSON şeması genişler: sim durumu (kuyruklar, progress, tick sayacı), para ve
açılmış araştırmalar eklenir. `FORMAT_VERSION` zaten mevcut, geriye dönük kırılma olmaz.
Konumlar `Vector2` yerine ayrı `x`/`y` float olarak yazılmaya devam eder.

### 4.8 Test stratejisi

- **Denge koşumu:** bir hat kur, 36.000 tick (≈1 saat) koştur, gelir/dk ve ürün/dk ölç.
- **Determinizm testi:** iki özdeş koşum → aynı durum parmak izi.
- **Kaydet/yükle turu:** kayıttan devam eden koşum, kesintisiz koşumla aynı sonucu vermeli.
- **Tıkanma ve açlık testleri:** zincirin geriye doğru dolduğu, ve açlığın tıkanmayla
  karışmadığı doğrulanır.

Hepsi `tools/sim_test.gd` içinde:

```bash
godot --headless --path . --script res://tools/sim_test.gd
```

Test koşumu, hiç kontrol çalışmadıysa yanlışlıkla "geçti" demesin diye beklenen
kontrol sayısını da doğrular — bu bir kez başımıza geldi.

Bu koşumların mümkün olması, D8'i (ayrı simülasyon modeli) seçmemizin asıl getirisidir.

---

## 5. MVP tempo taslağı (60 dakika)

| Dakika | Ne olur | Yeni gelen |
|---|---|---|
| 0–5 | Maden Ocağı → Eritme → Sevkiyat. Külçe sat, para aksın. | temel döngü |
| 5–15 | Pres açılır, Levha külçeden değerli. **İlk darboğaz:** Eritme yetişmiyor. | zincir uzatma |
| 15–25 | İkinci Eritme al → **slot dolar.** Fabrika genişlemesi araştır. | kıtlık |
| 25–40 | Hadde + Kesim. **Montaj açılır** — iki ayrı hattı birleştirmek. | asıl tasarım problemi |
| 40–50 | Kalite Kontrol + Geri Dönüşüm. Fire çıkar, geri besleme hattı kur. | döngüsel graf |
| 50–60 | **Ar-Ge Laboratuvarı.** Son araştırma para değil, akıtılan ürün ister. | ikinci döngü |

---

## 6. Riskler

| Risk | Azaltma |
|---|---|
| **60 dk tempo ilk denemede tutmaz** (en büyük risk) | Tüm süre/fiyat sayıları tek yerde; headless koşumla ölç, tahmin etme |
| Tıkanma sinir bozucu olabilir | Tıkalı istasyon net işaretlenir; oyuncu **neden** tıkandığını görmeli |
| Montaj öğrenme eşiği — MVP'nin zirvesi, kavranmazsa oyun orada biter | Montaj açılınca örnek düzen ipucu göster |
| GraphEdit 80+ node'da yavaşlayabilir | Sim zaten ayrı; sıkışırsak sadece görsel kısılır, oyun bozulmaz |

---

## 7. Mevcut durum (bu tasarımdan önce hazır olan)

GraphEdit tuvali, sürükle-bırak palet, `BlockType` resource sistemi, parametre denetçisi,
JSON kaydet/yükle, darboğaz özeti. Mimari zaten "sinyal yukarı / çağrı aşağı" kuralına
uygun — simülasyon katmanı bunun **altına** girecek, üstüne değil.

---

## 8. Sırada ne var

Faz 1-4 uygulandı. Kalan işler, ertelenmiş kararlar ve devam ederken
hatırlanması gerekenler: **[TODO.md](TODO.md)**

Kısaca: Montaj ipucu, bağlanmamış Ret portu uyarısı, çıkış oranı kontrolü
kararı, denge ince ayarı ve kablolarda akan noktalar. Hepsinin önceliği
gerçek oynanış geri bildirimine bağlı — o yüzden ilk adım kod yazmak değil,
oyunu 10-15 dakika oynamak.
