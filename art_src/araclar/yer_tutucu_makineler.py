"""Henüz çizilmemiş makineler için 128x128 yer tutucu görseller (STANDART.md ölçüleri).

Ortak bir kasa, makinenin rengine en yakın palet rengiyle şerit ve camda kategori simgesi.
Gerçek görseli çizilen makine app/sprite_machine_card.gd'deki SHEETS listesine girer ve
yer tutucusu kullanılmaz olur.
python art_src/araclar/yer_tutucu_makineler.py   -> app/art/placeholder/<makine>.png
"""
from pathlib import Path
import json
from PIL import Image, ImageDraw

from palet import PALET

KOK = Path(__file__).resolve().parents[2]
CIZILMIS = {'iron_mine', 'smelter'}
# build_bar.gd CATEGORIES ile aynı gruplar; değer kategori simgesinin sırası.
KATEGORI = {
    'iron_mine': 0, 'copper_mine': 0, 'coal_mine': 0, 'quartz_quarry': 0,
    'smelter': 1, 'steel_furnace': 1,
    'rolling_mill': 2, 'press': 2, 'foundry': 2,
    'lathe': 3, 'cnc': 3,
    'assembler': 4, 'wire_winder': 4,
    'lab': 5, 'project_hub': 5, 'scrap_disposal': 5,
}


def rgb(hex_renk):
    h = hex_renk.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def en_yakin(hex_renk):
    hedef = rgb(hex_renk)
    return min(PALET.values(), key=lambda v: sum((a - b) ** 2 for a, b in zip(rgb(v), hedef)))


def ciz(vurgu, ikon):
    im = Image.new('RGBA', (128, 128))
    d = ImageDraw.Draw(im)
    P = PALET
    for x in (22, 94):
        d.rectangle((x, 108, x + 12, 119), fill=P['dark'], outline=P['ink'])
    d.rectangle((14, 22, 113, 109), fill=P['steel'], outline=P['ink'])
    d.line([(15, 23), (112, 23)], fill=P['light'])
    d.line([(15, 24), (15, 108)], fill=P['mid'])
    d.line([(112, 24), (112, 108)], fill=P['dark'])
    d.line([(15, 108), (112, 108)], fill=P['dark'])
    d.rectangle((14, 14, 113, 22), fill=vurgu, outline=P['ink'])
    d.line([(15, 15), (112, 15)], fill=P['shine'])
    d.rectangle((36, 36, 91, 91), fill=P['deep'], outline=P['ink'])
    d.rectangle((37, 37, 90, 38), fill=P['dark'])
    im.alpha_composite(ikon.resize((48, 48), Image.Resampling.NEAREST), (40, 40))
    for x, y in ((19, 28), (108, 28), (19, 103), (108, 103)):
        d.rectangle((x - 1, y - 1, x + 1, y + 1), fill=P['ink'])
        d.point((x, y), fill=P['light'])
    for y in (96, 100):
        d.line([(40, y), (87, y)], fill=P['dark'])
    return im


def main():
    katalog = json.loads((KOK / 'data' / 'prototype.json').read_text(encoding='utf-8'))
    ikonlar = Image.open(KOK / 'app' / 'art' / 'ui' / 'category_icons.png').convert('RGBA')
    hedef = KOK / 'app' / 'art' / 'placeholder'
    hedef.mkdir(parents=True, exist_ok=True)
    yazilan = []
    for kind, spec in katalog['machines'].items():
        if kind in CIZILMIS:
            continue
        i = KATEGORI[kind]
        ikon = ikonlar.crop((i * 16, 0, i * 16 + 16, 16))
        ciz(en_yakin('#' + spec['color']), ikon).save(hedef / f'{kind}.png')
        yazilan.append(kind)
    print('YER_TUTUCU_OK:', len(yazilan), 'makine ->', hedef)


main()
