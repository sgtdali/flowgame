---
tur: sistem
durum: karma
guncelleme: 2026-10-23
---
# Oyun kimliği ve temel döngü

## Oyuncunun yaptığı iş

Oyuncu sonsuz canvas üzerinde makine kartları kurar, makineler arasında ürün akışı oluşturur ve endüstrisini geliştirir. Canvas düzenleme ve bağlama biçimi seçilmiştir. Oyunun kimliğini yalnızca çizgilerle bağlanan çok sayıda ürünün oluşturması yeterli görülmemiştir.

Kaynak konuşmada kullanıcı, ilk yaklaşımın “Factorio'nun konveyörsüz hali” olmasına dikkat çekmiştir. Temel tasarım sorusu buradan doğar: Fiziksel yerleşim bulmacası azalınca oyuncunun ustalaşacağı karar alanı ne olacak?

## Önerilen üç tasarım sütunu

1. **Üretim yöntemi seçimi:** Aynı ürün için birden fazla proses; farklı kaynak, kapasite ve kalite sonuçları.
2. **Kaynak erişimi ve endüstriyel ağ:** Ekonomik bölgelere bağlı girdiler ve sınırlı bölgeler arası aktarım.
3. **Anlamlı ürün tüketicileri:** Araştırma, fabrika genişlemesi ve somut bir ana proje.

İlk iki yön kullanıcı tarafından olumlu karşılanmıştır. Üç sütunun bütün ayrıntıları onaylanmış değildir. Özellikle ana projenin kimliği ve ekonomi kuralları açıktır.

## Önerilen oyuncu döngüsü

Bir sonraki yetenek veya hedef seçilir → gereken ürünler ve özellikleri anlaşılır → uygun makineler/reçeteler bağlanır → ağın gerçek akışı izlenir → darboğaz görülür → daha fazla makine, farklı yöntem veya farklı kaynak/taşıma yatırımı arasında seçim yapılır → ürünler hedefe harcanır → yeni üretim imkânı açılır.

Sonradan seçilen kurallar döngüye somut adımlar ekledi: madenler birer adetle sınırlı olduğundan hammadde artık sınırsız büyütülemez (K-010); yeni makine kurmak için ürün harcanır, oyuncu ürünü karttan veya depodan kendisi alır ve gerekirse el ile üretir (K-011); araştırma laboratuvarlardan sürekli akan kademe puanıyla ilerler (K-008). Bkz. [[Tasarım/Envanter ve El Üretimi]].

Bu döngünün başarısı, oyuncunun her darboğazda yalnızca aynı kartı çoğaltmak zorunda kalmamasına bağlıdır. Kopyalama faydalı bir araç olabilir; bütün stratejinin yerini almamalıdır.

## İlerleme hissi önerisi

| Aşama | Oyuncunun odağı |
|---|---|
| Başlangıç | Basit bir ürünü üretip ilk araştırmayı beslemek |
| İlk genişleme | Bir kaynak veya taşıma darboğazını çözmek |
| Orta oyun | Yöntemleri karşılaştırmak ve bölgesel uzmanlaşma kurmak |
| İleri oyun | Mekanik, kimya, elektronik ve metalürjiyi birleştirmek |
| Geç oyun | Büyük ana hedefi çok bölgeli üretimle beslemek |

Bu aşamalar içerik takvimi veya tamamlanmış senaryo değildir. İlk 60 dakikanın ürün ve araştırma sırası henüz tasarlanmamıştır.

## Başarıyı nasıl anlayacağız?

- Oyuncu neden belirli bir üretim yöntemini seçtiğini açıklayabiliyor mu?
- Yeni teknoloji eski sistemi tamamen çöpe atmadan yeni seçenek yaratıyor mu?
- Bir kapasite sorununda en az iki anlamlı çözüm görüyor mu?
- Ağ büyüdükçe işi tekrar sayısı değil, kararların bağlantısı mı derinleşiyor?
- Üretimin büyümesini somut bir hedefe katkı olarak hissediyor mu?

Bkz. [[Tasarım/Prototip ve Doğrulama]], [[Araştırma/Factory Planner ve Farklılaşma]].
