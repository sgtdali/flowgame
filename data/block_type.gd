class_name BlockType
extends Resource

## Bir üretim istasyonunun ARKETİPİ (şablonu).
## Çalışma anındaki değerleri değil, varsayılanlarını tutar.
## Her istasyon türü için bir .tres dosyası -> res://data/block_types/

## Bloğun akış şemasındaki rolü.
enum Category {
	SOURCE,   ## Akışın başlangıcı (hammadde, tedarik) — girişi yok
	PROCESS,  ## İşlem yapan istasyon (eritme, pres, hadde)
	INSPECT,  ## Kontrol / ayırma noktası — birden fazla çıkışı olur
	BUFFER,   ## Ara stok / kuyruk
	SINK,     ## Akışın sonu (mamul depo, sevkiyat) — çıkışı yok
}

@export var id: StringName = &""
@export var display_name: String = "Yeni Blok"
@export var category: Category = Category.PROCESS
@export var accent_color: Color = Color(0.29, 0.64, 0.87)
@export var icon_char: String = "#"
@export_multiline var description: String = ""

@export_group("Portlar")
@export var input_labels: PackedStringArray = PackedStringArray(["Giriş"])
@export var output_labels: PackedStringArray = PackedStringArray(["Çıkış"])

@export_group("Varsayılan Parametreler")
## Bir parçanın bu istasyonda geçirdiği süre (saniye).
@export var cycle_time_s: float = 60.0
## Aynı anda işlenebilen parça sayısı.
@export var capacity: int = 1
## İstasyonu çalıştıran operatör sayısı.
@export var operators: int = 1
## Hurda / fire oranı (0.0 - 1.0).
@export var scrap_rate: float = 0.0


func category_label() -> String:
	match category:
		Category.SOURCE: return "Kaynak"
		Category.PROCESS: return "İşlem"
		Category.INSPECT: return "Kontrol"
		Category.BUFFER: return "Ara Stok"
		Category.SINK: return "Bitiş"
	return "Bilinmiyor"
