# Denge Denetim Raporu

Üretici: `tools/balance_audit.gd`. Bu, **mevcut `.tres` değerlerinin**
denetimidir — hiçbir değer değiştirilmedi/önerilmedi. Sonuçlar yalnızca
burada modellenen üç strateji için geçerlidir: **bölerek/dönüştürerek**
(mevcut hattı Dağıtıcı ile paylaştırmak), **hedefli yatırım** (paylaşılan
darboğaza — cevher/kulçe arzı — ek kapasite), **ayrı hat** (mevcut geliri
hiç kesmeden bağımsız ikinci zincir). Bir oyuncunun bulabileceği HER olası
strateji için değil. **Ekonomik teşvikleri ölçer, oyuncu keyfini kanıtlamaz.**

## 1. Aşama başına tek karşılaştırma tablosu

"Süre" para biriktirme + kurulum + üretim + eylem süresini (bkz. altta)
hepsini içerir — yalnız simülasyon saniyesi değil. "Kazanç", MINIMUM
stratejiye göre mutlak (saniye) ve yüzde farktır; pozitif = daha hızlı.

| Araştırma | Strateji | Toplam süre | Yatırım | Ek işçi | Kazanç (sn) | Kazanç (%) |
|---|---|---|---|---|---|---|
| Hammer Craft | minimum | 136.2 sn | 350 altın | 0 | — | — |
|  | targeted | 174.2 sn | 600 altın | 1 | -38.0 sn | %-27.9 |
|  | separate | 87.1 sn | 250 altın | 1 | 49.1 sn | %36.0 |

| Shieldcraft | minimum | 301.4 sn | 900 altın | 1 | — | — |
|  | targeted | 347.2 sn | 1150 altın | 2 | -45.8 sn | %-15.2 |
|  | separate | 478.5 sn | 1550 altın | 3 | -177.1 sn | %-58.8 |

| Helmcraft | minimum | 1280.2 sn | 2500 altın | 1 | — | — |
|  | targeted | 839.1 sn | 2800 altın | 3 | 441.1 sn | %34.5 |
|  | separate | 889.6 sn | 5500 altın | 5 | 390.6 sn | %30.5 |

| Helm Banding | minimum | 542.3 sn | 1900 altın | 1 | — | — |
|  | targeted | 143.3 sn | 3100 altın | 4 | 399.0 sn | %73.6 |
|  | separate | 91.2 sn | 2750 altın | 4 | 451.1 sn | %83.2 |

## 2. %20–%35 bandı: zorunlu koşul DEĞİL, teşhis çizgisi

Bu bant hiçbir aşamanın "geçmesi gereken" bir sınav değil — tabloda her
aşamanın gerçek kazancı, banda girsin girmesin, olduğu gibi yukarıda
duruyor. Bandın İKİ ucu da farklı bir riski işaretliyor, iki ucu da
gerekçelendiriliyor:

- **Alt sınırın (%20) altı**: hedefli/ayrı hat yatırımı MINIMUM'a göre
  ölçülebilir bir fark yaratmıyor demektir — oyuncu neden uğraşsın?
  Bu BAŞLI BAŞINA bir hata değil (öğretici aşamalarda KASITLI, bkz.
  aşağı) ama optimizasyon aşamalarında (Kask Zanaati, Kask Bantlama)
  yatırımın görünmez kalması, tasarım hedefiyle ("kapasiteye yatırım
  yapmanın karşılığını görmek") çelişir.
- **Üst sınırın (%35) üstü SORUN sayılıyor** çünkü: eğer hedefli/ayrı
  hat MINIMUM'u ezici farkla geçiyorsa (ör. %74-80), MINIMUM artık
  gerçek bir seçenek değil, bir CEZA halini alır — rasyonel her oyuncu
  HER SEFERINDE yatırım yapar. Bu, orijinal tasarım isteğinin doğrudan
  ihlalidir: "Minimum yatırımla ilerlemek mümkün kalsın" ve "Hiçbiri
  her durumda açıkça üstün olmasın." Üst sınır bu yüzden bir ÜST TAVAN
  değil, "minimum hâlâ gerçek bir seçenek mi" sorusunun sayısal izi.

Bandın kendisi (%20–%35) keyfi bir başlangıç noktasıdır,
`BalanceLib.TARGET_SAVINGS_MIN/MAX` sabitlerinde değiştirilebilir —
evrensel doğru olarak sunulmuyor.

## 3. Araştırmalar boyunca biriken toplam süre (SAF politikalar)

Her satır, oyuncunun BAŞTAN SONA (4 araştırma boyunca) HEP AYNI
stratejiyi seçtiği bir "saf politika" — önceki denetimde eksik olan bu
kısımdı (bkz. DESIGN.md D24, "bilinen sınır" notu), bu turda eklendi.

| Strateji | Aşama | Bu aşama (sn) | Kümülatif (sn) | Kümülatif yatırım | Kümülatif işçi |
|---|---|---|---|---|---|
| minimum | presleme | 136.2 | 136.2 | 350 altın | 0 |
| minimum | kalkan_zanaati | 301.4 | 437.6 | 1250 altın | 1 |
| minimum | kask_zanaati | 1280.2 | 1717.8 | 3750 altın | 2 |
| minimum | kask_bantlama | 542.3 | 2260.1 | 5650 altın | 3 |
| targeted | presleme | 174.2 | 174.2 | 600 altın | 1 |
| targeted | kalkan_zanaati | 160.9 | 335.1 | 1500 altın | 2 |
| targeted | kask_zanaati | 447.1 | 782.2 | 4300 altın | 5 |
| targeted | kask_bantlama | 203.3 | 985.5 | 7100 altın | 7 |
| separate | presleme | 87.1 | 87.1 | 250 altın | 1 |
| separate | kalkan_zanaati | 273.5 | 360.6 | 1800 altın | 4 |
| separate | kask_zanaati | 808.9 | 1169.5 | 7300 altın | 9 |
| separate | kask_bantlama **[KİLİTLENDİ]** | 5759.2 | 6928.7 | 10050 altın | 13 |
| separate | *(kask_bantlama adımında kilitlendi: zaman asimi: arastirma: kask_bantlama (separate, adet=20))* | | | | |

**Kümülatif toplam (tamamlanabildiği kadarıyla)**: minimum 2260.1 sn (4/4 tamamlandı), hedefli 985.5 sn (4/4 tamamlandı), ayrı hat kask_bantlama adımında KİLİTLENDİ (o ana kadar 6928.7 sn).

**Bu KİLİTLENMELER gerçek bir bulgu, model hatası değil**: "hep hedefli"/
"hep ayrı hat" politikası dört araştırma boyunca sürekli yeni işçi
gerektiriyor (bkz. kümülatif işçi sütunu) — mevcut gıda hattı (Çiftlik+
Değirmen+Fırın, 3 işçi) bu kadar işçiyi beslemeye YETMEYEBİLİR. Gerçek
oyunda da bir oyuncu sürekli genişleyip gıda hattını büyütmezse aynı
duvara çarpar — bu, "İşçi ve gıda gereksinimlerini hesaba kat" isteğinin
tam karşılığı.

Kilitlenme anında ölçülen durum (ayrı hat, kask_bantlama öncesi): toplam işçi 18,
yiyecek stoğu 16, açlık sıkıntısı: EVET. Bu, hipotezi DOĞRULUYOR — üretim gıda kıtlığı yüzünden aralıklarla duruyor.

Not: bu üç satır 4 aşama boyunca HEP AYNI stratejiyi varsayıyor — yukarı
bölüm 1'deki tablo ise "o ana kadar minimum oynayan bir oyuncu, BU TEK
aşama için strateji değiştirse ne olur" sorusunu soruyor. İkisi FARKLI
sorular, ikisi de burada ayrı raporlanıyor.

## 4. Hedefe ulaşamayan aşamalar: hangi kısıt belirleyici

"Uygun aday bulunamadı" durumunda otomatik en küçük/en büyük öneri
YAPILMIYOR — bunun yerine ölçülen veriyle hangi kısıtın kararı
verdiği gösteriliyor.

- **Hammer Craft** (öğretici aşama, mevcut adet 24): kazanç %-27.9 — bant
  dışı ama bu aşamanın başarı ölçütü bant değil, MINIMUM'un kısa
  kalması. MINIMUM'un toplam süresi 136.2 sn; bunun 70.0 sn'si (%51.4)
  PARA BİRİKTİRMEYE gidiyor — belirleyici kısıt üretim hızı değil,
  bu aşamada satın alınan yapının (bkz. build_cost) fiyatı.

- **Shieldcraft** (öğretici aşama, mevcut adet 15): kazanç %-15.2 — bant
  dışı ama bu aşamanın başarı ölçütü bant değil, MINIMUM'un kısa
  kalması. MINIMUM'un toplam süresi 301.4 sn; bunun 222.4 sn'si (%73.8)
  PARA BİRİKTİRMEYE gidiyor — belirleyici kısıt üretim hızı değil,
  bu aşamada satın alınan yapının (bkz. build_cost) fiyatı.

- **Helmcraft**: %34.5 ile bant içinde, ayrı bir kısıt analizi gerekmiyor.
- **Helm Banding** (mevcut adet 20): kazanç %73.6, bant dışı.
  MINIMUM 542.3 sn, HEDEFLİ 143.3 sn; MINIMUM'un 0.0 sn'si (%0.0)
  para biriktirmeye gidiyor.

## 5. Shieldcraft (Kalkan Zanaati): 25 → 15 levha değişiminin etkisi

| Levha adedi | Strateji | Süre (sn) | Kazanç (sn) | Kazanç (%) |
|---|---|---|---|---|
| 25 (eski) | minimum | 341.4 | — | — |
| 25 (eski) | targeted | 361.2 | -19.8 | %-5.8 |
| 25 (eski) | separate | 498.5 | -157.1 | %-46.0 |
| 15 (mevcut) | minimum | 301.4 | — | — |
| 15 (mevcut) | targeted | 347.2 | -45.8 | %-15.2 |
| 15 (mevcut) | separate | 478.5 | -177.1 | %-58.8 |

**Yorum**: 25'ten 15'e düşürmek MINIMUM'un süresini kısaltıyor (daha az
levha beklemek gerekiyor) ama bu aşama zaten "öğretici" sınıfında —
hedefli/ayrı hat yatırımının bu aşamada anlamlı bir kazanç sağlaması
tasarım hedefi DEĞİLDİ (bkz. bölüm 2). Miktar küçültmenin optimizasyon
TEŞVİKİ üzerindeki asıl etkisi: MINIMUM zaten hızlı olduğundan, yatırımın
(Dağıtıcı/2. Maden kurulum + bekleme süresi) MINIMUM'u geçmesi daha da
zorlaşıyor — kazanç oranı yukarıdaki tabloda negatife düşüyorsa bu, 
yatırımın bu KISA aşamada kendini amorti edemediğini gösterir, bir hata
değil (öğretici aşamalarda beklenen davranış, bkz. bölüm 2).

## 6. Helm Banding (Kask Bantlama): "yapısal fark" iddiasının genişletilmiş kanıtı

İddia: MINIMUM'un buradaki dezavantajı (Levha'yı Kalkan Ustası VE Kask
Ustası için art arda bölmek zorunda kalması) MİKTARDAN BAĞIMSIZ —
yapısal. Önceki turda yalnız 20 ve 80 test edilmişti; bu turda 10-160
arası 5 kat genişlik tarandı:

| Kask adedi | MINIMUM (sn) | HEDEFLİ (sn) | Kazanç (%) | AYRI HAT (sn) | Kazanç (%) |
|---|---|---|---|---|---|
| 10 | 302.3 | 103.3 | %65.8 | 71.2 | %76.4 |
| 20 | 542.3 | 143.3 | %73.6 | 91.2 | %83.2 |
| 40 | 1022.3 | 223.3 | %78.2 | 131.2 | %87.2 |
| 80 | 1982.3 | 383.3 | %80.7 | 211.2 | %89.3 |
| 160 | 3902.3 | 703.3 | %82.0 | 371.2 | %90.5 |

**Sonuç**: 10–160 aralığında hedefli kazanç %65.8–%82.0 arasında kalıyor
(bant: %20–%35). Fark 16 katlık bir miktar aralığında 16.1 puandan
fazla değişmiyor — bu, iddiayı DESTEKLİYOR: MINIMUM'un dezavantajı bir
eşik/miktar meselesi değil, iki tüketiciye art arda bölme YAPISININ
kendisi. Miktarı değiştirerek düzeltilemez; düzeltmek isteniyorsa
MINIMUM'un kurulum PLANI (ör. tek bölme yerine iki ayrı Dağıtıcı) ya da
build_cost/süre değişmeli — bu denetimin kapsamı dışında (oyun
değerleri değiştirilmedi).

## 7. Adalet denetimi: gereksiz harcama / işsiz atölye / yanlış yönlendirme / yapay bekleme

Kod elle satır satır incelendi ve şu kontroller yapıldı:

- **İşsiz atölye**: her PROCESS/SOURCE/INSPECT istasyonu kurulduğu asamada
  `staff()` ile işçi alıyor mu — tek tek doğrulandı, hepsi işçili.
- **Gereksiz harcama**: her strateji yalnızca KENDİ planı için gerekli
  istasyonları kuruyor (ör. AYRI HAT, gerçekten bağımsız bir zincir için
  gereken Maden+Eritme+Pres+atölyeyi kurup başka bir şey almıyor).
- **Yanlış yönlendirme**: her `wire()` çağrısının port sırası reçeteyle
  (`RecipeSlot` sırası) karşılaştırıldı; Kalkan Ustası'nın port 0=kulçe,
  port 1=levha beklediği, Kask Ustası'nın tek girişinin levha olduğu
  doğrulandı.
- **Yapay bekleme (BULUNAN VE DÜZELTİLEN gerçek hata)**: Kask Zanaati
  aşamasının MINIMUM ve HEDEFLİ planları, yeni Dağıtıcı(lar)ı satın
  almadan ÖNCE Pres'in mevcut gelirini (sevkiyat'a satışını) kesiyordu.
  Bu, parası birikirken GELİR SIFIRDAN başlıyor demekti — MINIMUM'u
  (ve HEDEFLİ'yi) yapay şekilde yavaş gösteren bir ölçüm yanlılığıydı.
  Düzeltme: tüm parayı gerektiren satın almalar, mevcut gelir kesilmeden
  ÖNCE yapılacak şekilde sıra değiştirildi (diğer tüm aşamalarda zaten
  uygulanan disiplin). Etkisi ölçüldü: Kask Zanaati'nde MINIMUM 1460.2
  sn'den 1280.2 sn'ye, HEDEFLİ 1159.1 sn'den 839.1 sn'ye düştü — HEDEFLİ
  daha çok kazandı çünkü eski sırada daha fazla satın alma (2. Maden+
  Eritme+Dağıtıcı) parasız gelir bekliyordu. Kazanç oranı %20.6'dan
  %34.5'e çıktı (yukarıdaki ana tablo DÜZELTİLMİŞ hâli gösteriyor).
- **`money_wait_seconds` teşhisi**: her ölçümde para birikleme süresi
  üretim/akış süresinden AYRI izleniyor (bkz. bölüm 4) — hangi kısmın
  "bekleme" hangi kısmın "gerçek iş" olduğu görünür, gizlenmiyor.

**Sınır**: bu denetim yalnızca burada YAZILI üç stratejinin KENDİ
planlarını inceledi — modellenmeyen dördüncü bir strateji (ör. "önce
hurda geri dönüşümü kur") bu denetimin dışında kalır.