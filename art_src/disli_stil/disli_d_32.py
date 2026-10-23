"""Dişli simgesi, D tarzı (iri 6 diş, güçlü ışık-gölge, göbekte vurgu halkası), 32x32.

Kullanıcı D tarzını seçti ama mavimsi renkleri istemedi; burada mavisiz üç renk takımı var.
Seçilen pirinç takımı art_src/urun_32/gear.png olarak da yazılır; urun_ikonlari.py oradan alır.
python art_src/disli_stil/disli_d_32.py
  -> art_src/disli_stil/disli_d_32_<takim>.png   (32x32 simgeler)
  -> art_src/disli_stil/disli_d_32_karsilastirma.png  (oyundaki boyut ve 4x büyütme)
"""
from pathlib import Path
import math
import sys
from PIL import Image

KLASOR = Path(__file__).resolve().parent
sys.path.insert(0, str(KLASOR.parent / 'araclar'))
from palet import PALET  # noqa: E402

# Rol -> palet rengi. parlak: ışık kenarı, govde: düz yüzey, golge: gölge kenarı,
# derin: en koyu gölge, vurgu/vurgu_acik: göbek halkası.
TAKIMLAR = {
    'sicak_celik': {'parlak': 'shine', 'govde': 'dust', 'golge': 'dustdark', 'derin': 'oredark',
                    'vurgu': 'amber', 'vurgu_acik': 'gold'},
    'pirinc': {'parlak': 'hot', 'govde': 'amber', 'golge': 'orange', 'derin': 'rust',
               'vurgu': 'ember', 'vurgu_acik': 'red'},
    'dokum_demir': {'parlak': 'dust', 'govde': 'dustdark', 'golge': 'oredark', 'derin': 'coal',
                    'vurgu': 'flame', 'vurgu_acik': 'yellow'},
}


def rgb(ad):
    v = PALET[ad]
    return tuple(int(v[i:i + 2], 16) for i in (1, 3, 5)) + (255,)


S, C = 32, 15.5
DIS, GOVDE, UC, DELIK, HALKA = 6, 9.8, 14.9, 3.1, 6.4


def dolu_mu(x, y):
    dx, dy = x - C, y - C
    r = math.hypot(dx, dy)
    if r < DELIK:
        return False
    if r <= GOVDE:
        return True
    # Paralel kenarlı kalın diş; aralarındaki oyuk V biçiminde açılır, ~5 px derin.
    for k in range(DIS):
        a = -math.pi / 2 + k * 2 * math.pi / DIS
        boy = dx * math.cos(a) + dy * math.sin(a)
        yan = -dx * math.sin(a) + dy * math.cos(a)
        yari = 3.7
        if GOVDE - 1 < boy <= UC and abs(yan) <= yari:
            return True
    return False


def ciz(takim):
    T = {rol: rgb(ad) for rol, ad in takim.items()}
    ink = rgb('ink')
    dolu = [[dolu_mu(x, y) for x in range(S)] for y in range(S)]

    def bos(x, y):
        return not (0 <= x < S and 0 <= y < S and dolu[y][x])

    im = Image.new('RGBA', (S, S))
    for y in range(S):
        for x in range(S):
            if not dolu[y][x]:
                continue
            dx, dy = x - C, y - C
            r = math.hypot(dx, dy)
            if any(bos(x + i, y + j) for i, j in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                im.putpixel((x, y), ink)
                continue
            # Bevel: dış kenara 2 px içeride ışık sol üstten. Ölçü: yakındaki boşluğun yönü.
            yon_x = yon_y = 0
            for i in range(-2, 3):
                for j in range(-2, 3):
                    if (i or j) and abs(i) + abs(j) <= 2 and bos(x + i, y + j):
                        yon_x += i
                        yon_y += j
            if r <= HALKA:
                # Göbek: deliği saran vurgu halkası; ışık tarafı açık, iç kenarı koyu bant.
                if r < DELIK + 1.0:
                    rol = 'derin' if (dx + dy) < 0 else 'vurgu'
                elif r > HALKA - 0.9:
                    rol = 'derin' if (dx + dy) > 0 else 'golge'
                else:
                    rol = 'vurgu_acik' if (dx + dy) < -1.0 else 'vurgu'
                im.putpixel((x, y), T[rol])
                continue
            if yon_x or yon_y:
                isik = -(yon_x + yon_y) / math.hypot(yon_x, yon_y) / math.sqrt(2)
                rol = 'parlak' if isik > 0.35 else 'derin' if isik < -0.55 else 'golge' if isik < -0.1 else 'govde'
            else:
                # düz yüzeyde sol üstten sağ alta hafif koyulaşma
                rol = 'govde' if (dx + dy) < 6 else 'golge'
            im.putpixel((x, y), T[rol])
    return im


def main():
    simgeler = {}
    for ad, takim in TAKIMLAR.items():
        im = ciz(takim)
        izinli = {rgb(a)[:3] for a in PALET}
        for r, g, b, a in set(im.get_flattened_data()):
            assert not a or (r, g, b) in izinli, (ad, (r, g, b))
        im.save(KLASOR / f'disli_d_32_{ad}.png')
        if ad == 'pirinc':
            (KLASOR.parent / 'urun_32').mkdir(exist_ok=True)
            im.save(KLASOR.parent / 'urun_32' / 'gear.png')
        simgeler[ad] = im
    kutu = Image.new('RGBA', (44, 44), '#12222e')
    for i in range(44):
        for j in (0, 43):
            kutu.putpixel((i, j), (41, 67, 86, 255))
            kutu.putpixel((j, i), (41, 67, 86, 255))
    gercek = Image.new('RGBA', (56 * len(simgeler) - 12, 44), '#0d1a24')
    for i, im in enumerate(simgeler.values()):
        k = kutu.copy()
        k.alpha_composite(im, (6, 6))
        gercek.alpha_composite(k, (i * 56, 0))
    buyuk = gercek.resize((gercek.width * 4, gercek.height * 4), Image.Resampling.NEAREST)
    son = Image.new('RGBA', (buyuk.width + 24, buyuk.height + gercek.height + 36), '#0d1a24')
    son.alpha_composite(gercek, (12, 12))
    son.alpha_composite(buyuk, (12, gercek.height + 24))
    son.save(KLASOR / 'disli_d_32_karsilastirma.png')
    print('DISLI_D_OK:', ', '.join(simgeler))


main()
