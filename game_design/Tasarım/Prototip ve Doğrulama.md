---
tur: dogrulama-plani
durum: oneri
guncelleme: 2026-10-23
---
# Prototip ve doğrulama

## Bu bir uygulama emri değildir

Kaynak konuşmada farklı zamanlarda önerilmiş üç deney kapsamı bulunuyor. Bunlar tek prototipte toplanmış veya kullanıcı tarafından kesinleştirilmiş değildir. Kullanıcının oyunu oluşturmaya başlama talebinden sonra prototip adım adım büyüdü: 24 ürünlük ağ, kademeli laboratuvarlar, envanter ve el üretimi çalışıyor. Bölge ve yöntem karşılaştırması deneyleri (B ve C) henüz yapılmadı. Yapılan ve test edilen kısmın güncel kaydı [[Yönetim/Uygulama Durumu]] içindedir; aşağıdaki plan tek başına uygulama emri değildir.

## Deney A — Araştırma tüketim döngüsü

Not: Bu deney K-001 dönemine aittir. K-008 ile araştırma laboratuvarların ürettiği kademe puanıyla yapılır; test soruları buna göre okunmalıdır.

Kaynakta ilk araştırma prototipi için önerilen kapsam: 8 araştırma, 3 alan, 15–20 ürün, çoğaltılabilir tek laboratuvar türü, çok malzemeli deney, aynı anda tek aktif araştırma, ilerlemeyi koruyan araştırma değişimi, gerçek düğüm bağlantıları, giriş/talep/darboğaz ekranı ve bir küçük ana proje aşaması. Sonsuz araştırma önerilmemiştir.

Test sorusu: Oyuncu üretimi büyütmenin araştırmayı neden hızlandırdığını anlıyor ve bundan tatmin oluyor mu? Ek laboratuvarın tedarik olmadan yarar sağlamadığını görebiliyor mu? Araştırma değişimi eski ağını sürekli bozuyor mu?

## Deney B — Yöntem seçimi

Konuşmanın ilerleyen kısmında kapsamın daha da küçültülmesi önerildi: tek bir ürünün üç yöntemle üretilebildiği bir karşılaştırma. Daha önce 10–15 ürün ve üç kalite sınıfı düşüncesi de geçiyor; bu sayılar kesin hedef değildir.

Test sorusu: Oyuncu yalnızca daha fazla makine kurmak yerine yöntem değiştirmeyi anlamlı bir seçenek olarak görüyor mu? Bir yöntem diğerini her durumda geçersiz kılıyor mu? Yan ürünün kullanılması ek zahmetten fazla değer yaratıyor mu?

## Deney C — Ekonomik konum

Önerilen küçük kapsam: 2 bölge, 3 kaynak ve kapasitesi sınırlı tek bölgeler arası bağlantı.

Test sorusu: Ham ürün taşımakla kaynak yanında işlemek arasında gerçek bir tercih var mı? Taşıma yükseltmesi ve yerel üretim yatırımı farklı stratejiler oluşturuyor mu? Kartı canvas üzerinde taşımak ile bölge değiştirmek arasındaki fark anlaşılır mı?

## Önerilen çalışma sırası

Önce kart ölçeği ve reçete modeli netleştirilebilir. Ardından en küçük yöntem seçimi deneyi, sonra taşıma kısıtı, sonra araştırma ve ürün paylaşımı denenebilir. Bu sıra vault kurulumu sırasında yapılan çalışma önerisidir; kaynak konuşmada kesinleşmiş sıra değildir.

## Gözlem kaydı biçimi

Her deney için sürüm/tarih, kullanılan veri, oyuncunun hedefi, beklenen karar, gözlenen davranış, sorun ve bir sonraki değişiklik tutulur. “Eğlenceli” veya “çalışıyor” tek başına kanıt sayılmaz; oyuncunun hangi iki çözümü karşılaştırdığı kaydedilir.

## Teknik doğrulama hedefleri

Prototipte otomatik testlerle denetlenenler [[Yönetim/Uygulama Durumu#Doğrulama kanıtı — 2026-10-23]] içindedir.

- Eksik girdili deney başlamaz; girdiler birlikte tüketilir.
- İki laboratuvar aynı stok birimini iki kez kullanamaz.
- Kayıt/yükleme ilerlemeyi ve çalışan işi tutarlı korur.
- Araştırma tamamlandığında gereksiz yeni deney başlatılmaz.
- Geri dönüşüm veya taşımadan yoktan ürün oluşmaz.
- Teknoloji ve reçeteler erişilemeyen döngü oluşturmaz.

## Ölçek hedefleri

1.000, 5.000 ve 10.000 tesis/makine içeren ölçümler konuşmada test hedefi olarak önerilmiştir. Bunlar kapasite vaadi değildir. “Tesis”in kart mı makine adedi mi sayıldığı, kart gruplama kararından sonra ölçümde açıkça belirtilmelidir. Hedef cihaz, kabul edilebilir gecikme ve kare hızı henüz seçilmedi.

Bağlantılar: [[Tasarım/Simülasyon İlkeleri]], [[Yönetim/Açık Sorular]].
