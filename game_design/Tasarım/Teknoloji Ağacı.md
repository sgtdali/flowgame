---
tur: sistem
durum: onayli-ilk-taslak
guncelleme: 2026-10-23
---
# Teknoloji ağacı

## Güncel ağaç: 63 araştırma (K-025)

Ağaç [[Yönetim/Karar Defteri#K-025 — 63 araştırmalık teknoloji ağacı|K-025]] ile onaylandı ve 9 araştırmalık ilk taslağın (K-007) yerine geçti. Tablolar `data/prototype.json` ile aynıdır; bedeller ve etki oranları ilk tahmindir.

**Başlangıçta açık:** madenler (her türden birer adet), Ergitme Fırını (Iron Ingot, Steel Ingot, Copper Ingot), Haddehane (Iron Plate, Iron Rod, Iron Pipe, Steel Plate, Steel Rod), Pres (yalnız Fastener), Depo, Talaş İmha, Laboratuvar 1.

**Puan kademeleri:** K1 Laboratuvar 1 (Steel Plate + Fastener), K2 Laboratuvar 2 (Gear + Copper Wire + Industrial Glass), K3 Laboratuvar 3 (Circuit Board + Coil + Shaft), K4 Laboratuvar 4 (Electric Motor + Microchip + Hydraulic Cylinder).

**Etki araştırmaları:** Maden genişletme sınırı +1 artırır (2026-10-26'dan beri prototipte madeni %25 hızlandırır, çünkü sınırı dağlar belirliyor: K-043); verim araştırmaları makine ya da el üretimi hızına yüzde ekler; kapasite araştırmaları makine tamponlarını yüzdeyle, depoyu sabit miktarla büyütür. Etkiler kayda girer.

### Demir ve hidrolik (DM)

| Kod | Araştırma | Ön koşul | Bedel | Açtığı / etkisi |
|---|---|---|---|---|
| DM-01 | Sac Şekillendirme | — | 20 K1 | `Housing`, `Tank` |
| DM-02 | Döküm | — | 30 K1 | **Foundry**, `Cast Iron Gear`, `Cast Iron Housing` |
| DM-03 | Hurda Geri Kazanımı | MK-01 | 30 K1 | `Iron Ingot`, `Steel Ingot` |
| DM-04 | Hidrolik Silindir | MK-04 | 30 K2 | `Hydraulic Cylinder` |
| DM-05 | Pompa | MK-04, DM-02 | 40 K2 | `Pump` |
| DM-06 | Hidrolik Güç Ünitesi | DM-05, DM-01 | 50 K2 | `Hydraulic Power Unit` |
| DM-07 | Hidrolik Pres Ünitesi | DM-06, DM-04 | 60 K2 + 20 K3 | `Hydraulic Press Unit` |
| DM-08 | Metalürji Modülü | DM-07, AL-04 | 40 K3 | `Metallurgy Module` |

### Çelik ve mekanik (MK)

| Kod | Araştırma | Ön koşul | Bedel | Açtığı / etkisi |
|---|---|---|---|---|
| MK-01 | Talaşlı İmalat | — | 30 K1 | **Machine Shop**, `Shaft` |
| MK-02 | Dişli İşleme | MK-01 | 30 K1 | `Gear` |
| MK-03 | Rulman | MK-01 | 40 K1 | `Bearing` |
| MK-04 | Mekanik Montaj | MK-02, MK-03 | 40 K1 + 20 K2 | **Mechanical Assembly**, `Valve`, `Iron Frame` |
| MK-05 | Dişli Kutusu | MK-04, DM-02 | 50 K1 + 30 K2 | `Gearbox` |
| MK-06 | Lineer Kızak | MK-04 | 40 K2 | `Linear Guide` |
| MK-07 | Hassas İş Mili | MK-06, EL-04 | 50 K2 + 20 K3 | `Precision Spindle` |
| MK-08 | Hassas Mekanik Modülü | MK-05, MK-07, AL-04 | 60 K3 + 20 K4 | `Precision Mechanics Module` |

### Bakır ve elektrik (EL)

| Kod | Araştırma | Ön koşul | Bedel | Açtığı / etkisi |
|---|---|---|---|---|
| EL-01 | Tel Çekme | — | 30 K1 | **Wire Winder**, `Copper Wire` |
| EL-02 | Kablo | EL-01, EK-01 | 40 K1 | `Cable` |
| EL-03 | Bobin | EL-01 | 40 K1 + 20 K2 | `Electromagnetic Coil` |
| EL-04 | Elektrik Motoru | EL-03, MK-03, DM-01 | 50 K2 | **Electrical Assembly**, `Electric Motor` |
| EL-05 | Trafo | EL-03, EL-04 | 50 K2 | `Laminated Core`, `Transformer` |
| EL-06 | Elektrik Panosu | DM-01 | 30 K1 | `Electrical Cabinet` |
| EL-07 | Şalt Panosu | EL-02, EL-06, EL-04 | 50 K2 | `Switchgear` |
| EL-08 | Elektrik Modülü | EL-04, EL-05, EL-07, AL-04 | 50 K3 + 20 K4 | `Electrical Module` |

### Kuvars ve elektronik (EK)

| Kod | Araştırma | Ön koşul | Bedel | Açtığı / etkisi |
|---|---|---|---|---|
| EK-01 | Endüstriyel Cam | — | 30 K1 | `Industrial Glass` |
| EK-02 | Devre Kartı | EL-01, EK-01 | 40 K2 | **Electronics Assembly**, `Circuit Board` |
| EK-03 | Silisyum | EK-01 | 30 K2 | `Silicon` |
| EK-04 | Mikroçip | EK-02, EK-03 | 50 K2 + 20 K3 | `Microchip` |
| EK-05 | Sensör | EK-02, EL-03 | 40 K3 | `Industrial Sensor` |
| EK-06 | Ekran | EK-02 | 40 K3 | `Display` |
| EK-07 | Kontrol Bilgisayarı | EK-04, EK-06, EL-06 | 60 K3 | `Control Computer` |
| EK-08 | Elektronik Modülü | EK-05, EK-07, AL-04 | 60 K3 + 30 K4 | `Electronics Module` |

### Otomasyon ve final (OT)

| Kod | Araştırma | Ön koşul | Bedel | Açtığı / etkisi |
|---|---|---|---|---|
| OT-01 | Hassas Aktüatör | EL-04, MK-05, EK-05 | 50 K3 | **Robotics Assembly**, `Precision Actuator` |
| OT-02 | PLC | EK-05, EL-06 | 60 K3 | `Control Unit (PLC)` |
| OT-03 | Konveyör Hattı | OT-01 | 60 K3 | `Conveyor Line` |
| OT-04 | Robot Kol | OT-01, EL-02 | 40 K4 | `Robot Arm` |
| OT-05 | Otomasyon Modülü | OT-02, OT-03, OT-04, AL-04 | 60 K4 | `Automation Module` |
| OT-06 | Kurucu Çekirdek | DM-08, MK-08, EL-08, EK-08, OT-05 | 100 K4 | **Project Hub**, `Founding Core`, Main Project: Founding Core |

### Altyapı ve laboratuvarlar (AL)

| Kod | Araştırma | Ön koşul | Bedel | Açtığı / etkisi |
|---|---|---|---|---|
| AL-01 | Makine Fabrikası | MK-02 | 40 K1 | **Machine Factory** |
| AL-02 | Laboratuvar 2 | MK-02, EL-01, EK-01 | 40 K1 | **Lab 2** |
| AL-03 | Laboratuvar 3 | EK-02, EL-03 | 60 K2 | **Lab 3** |
| AL-04 | Modül Tesisi | MK-05, DM-01 | 60 K2 + 30 K3 | **Module Plant** |
| AL-05 | Laboratuvar 4 | EL-04, EK-04, DM-04 | 80 K3 | **Lab 4** |

### Maden genişletme (MD)

| Kod | Araştırma | Ön koşul | Bedel | Açtığı / etkisi |
|---|---|---|---|---|
| MD-01 | Demir Madeni II | — | 40 K1 | Demir Madeni kurulum sınırı +1 (prototipte şimdilik hız +%25). |
| MD-02 | Kömür Madeni II | — | 40 K1 | Kömür Madeni kurulum sınırı +1 (prototipte şimdilik hız +%25). |
| MD-03 | Bakır Madeni II | — | 40 K2 | Bakır Madeni kurulum sınırı +1 (prototipte şimdilik hız +%25). |
| MD-04 | Kuvars Ocağı II | — | 40 K2 | Kuvars Ocağı kurulum sınırı +1 (prototipte şimdilik hız +%25). |
| MD-05 | Demir Madeni III | MD-01 | 60 K3 | Demir Madeni kurulum sınırı +1 (prototipte şimdilik hız +%25). |
| MD-06 | Kömür Madeni III | MD-02 | 60 K3 | Kömür Madeni kurulum sınırı +1 (prototipte şimdilik hız +%25). |
| MD-07 | Bakır Madeni III | MD-03 | 60 K3 | Bakır Madeni kurulum sınırı +1 (prototipte şimdilik hız +%25). |
| MD-08 | Kuvars Ocağı III | MD-04 | 60 K3 | Kuvars Ocağı kurulum sınırı +1 (prototipte şimdilik hız +%25). |

### Verim (VR)

| Kod | Araştırma | Ön koşul | Bedel | Açtığı / etkisi |
|---|---|---|---|---|
| VR-01 | El Becerisi | — | 20 K1 | El üretimi %50 hızlanır. |
| VR-02 | Fırın Verimi I | — | 40 K1 | Fırın %25 hızlanır. |
| VR-03 | Şekillendirme Hızı | DM-01 | 30 K2 | Haddehane ve Pres %25 hızlanır. |
| VR-04 | Atölye Hızı | MK-01, DM-02 | 40 K2 | Tezgâh Atölyesi ve Dökümhane %25 hızlanır. |
| VR-05 | Montaj Hızı I | MK-04 | 40 K3 | Montaj makineleri ve Tel Sarım %25 hızlanır. |
| VR-06 | Fırın Verimi II | VR-02 | 50 K3 | Fırın %25 daha hızlanır. |
| VR-07 | Montaj Hızı II | VR-05 | 60 K4 | Montaj makineleri ve Tel Sarım %25 daha hızlanır. |
| VR-08 | Fabrika Hızı | AL-01 | 40 K3 | Makine Fabrikası %50 hızlanır. |

### Kapasite (LJ)

| Kod | Araştırma | Ön koşul | Bedel | Açtığı / etkisi |
|---|---|---|---|---|
| LJ-01 | Depo Kapasitesi I | — | 30 K1 | Depo +100. |
| LJ-02 | Tampon Kapasitesi I | — | 30 K2 | Makine giriş ve çıkış tamponları %50 büyür. |
| LJ-03 | Depo Kapasitesi II | LJ-01 | 40 K3 | Depo +200. |
| LJ-04 | Tampon Kapasitesi II | LJ-02 | 50 K3 | Tamponlar %50 daha büyür. |

Kilitlenme denetimi: `tests/test_production.gd` bütün araştırmaların sırayla açılabildiğini, her araştırmanın puanını üreten laboratuvarın o anda beslenebildiğini ve sonunda bütün ürünlerin üretilebildiğini doğrular.

## Tarihsel: 9 araştırmalık ilk taslak (K-007)

İlk taslak 24 ürüne bağlı 9 araştırmadan (A-01 – A-09) oluşuyordu: üç bağımsız kol (talaşlı imalat, döküm, iletkenler) ve onlardan mekanik aktarım, elektromanyetik sarım, elektrik motoru, temel elektronik, endüstriyel algılama ve otomasyona giden kesişen kollar. K-025 ile yerine geçti.

## Genel yapı ilkeleri ve tarihsel bağlam

### Ödül türleri
1. **Yeni yetenek:** Yeni makine veya daha önce üretilemeyen ürün (`Tezgâh Atölyesi`, `Mekanik Montaj`, `Makine Fabrikası`).
2. **Mevcut üretimin gelişimi:** Kapasite artışı, hız veya kaynak tasarrufu (`DM-03: Hurda Geri Kazanımı`; verim, kapasite ve maden genişletme kolları).
3. **Ağ yönetimi:** İleride eklenebilecek dağıtıcı, filtre veya kapasite kontrol araçları.

### Kilitlenmeyi (Deadlock) önleme kontrolü
Bir araştırma yalnızca kendisinin açacağı teknolojiyle üretilebilen ürünü isteyemez. 63 araştırmalık ağda her araştırmanın puanı, o anda açık ve beslenebilir bir laboratuvardan gelir; bu `tests/test_production.gd` ile denetlenir.

### Oyuncuya gösterim önerisi
Gelecek ürünlerin nerede kullanılacağı önceden görülebilmeli. Kilitli teknoloji hangi ön koşul, üretim kabiliyeti veya malzeme nedeniyle erişilemez olduğunu açıklamalı. Alternatif yolların avantajları anlaşılabilir olmalı.

Bağlantılar: [[Tasarım/Ürün ve Üretim Ağı]], [[Tasarım/Araştırma Ekonomisi]], [[Tasarım/Prosesler Kalite ve Yan Ürünler]], [[Tasarım/Simülasyon İlkeleri]].
