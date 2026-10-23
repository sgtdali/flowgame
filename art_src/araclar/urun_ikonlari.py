"""Ürün simgeleri: 24 ürün, ortak palet, şeritte her biri 32x32 ve oyunda 1:1 görünür.

32x32 çizimi olan ürün art_src/urun_32/<ürün>.png'den olduğu gibi alınır; olmayanlar
burada 16x16 çizilip 2x büyütülür (ekranda eskisiyle aynı görünür).
Sıra data/prototype.json'daki products sırasıyla aynıdır.
python art_src/araclar/urun_ikonlari.py   -> app/art/ui/product_icons.png (768x32)
"""
from pathlib import Path
import json
import math
from PIL import Image, ImageDraw

from palet import PALET

KOK = Path(__file__).resolve().parents[2]
S = 16
HUCRE = 32
YENI = KOK / 'art_src' / 'urun_32'


def c(name):
    return PALET[name]


def poly(d, pts, fill, outline='ink'):
    d.polygon(pts, fill=c(fill), outline=c(outline) if outline else None)


def rect(d, box, fill, outline=None):
    d.rectangle(box, fill=c(fill), outline=c(outline) if outline else None)


def line(d, pts, fill, width=1):
    d.line(pts, fill=c(fill), width=width)


def circle(d, x, y, r, fill, outline=None):
    d.ellipse((x - r, y - r, x + r, y + r), fill=c(fill), outline=c(outline) if outline else None)


def px(d, x, y, col):
    d.point((x, y), fill=c(col))


def ore(d, base, dark, light, specks):
    poly(d, [(1, 9), (3, 4), (8, 2), (13, 4), (14, 10), (11, 13), (4, 13)], base)
    poly(d, [(3, 5), (8, 3), (9, 7), (4, 9)], light, None)
    poly(d, [(9, 8), (13, 6), (13, 10), (10, 12), (6, 12)], dark, None)
    for (x, y), col in zip([(6, 6), (10, 5), (5, 10), (11, 9), (8, 9)], specks):
        px(d, x, y, col)


def ingot(d, top, front, side):
    poly(d, [(4, 5), (14, 5), (12, 8), (2, 8)], top)
    poly(d, [(2, 8), (12, 8), (12, 12), (2, 12)], front)
    poly(d, [(12, 8), (14, 5), (14, 9), (12, 12)], side)
    line(d, [(5, 6), (12, 6)], 'shine' if top != 'gold' else 'yellow')


def iron_ore(d):
    ore(d, 'ore', 'oredark', 'dust', ['dust', 'red', 'oredark', 'red', 'dust'])


def copper_ore(d):
    ore(d, 'mid', 'steel', 'light', ['amber', 'orange', 'amber', 'orange', 'gold'])


def coal(d):
    ore(d, 'coal', 'ink', 'coallight', ['smoke3', 'coallight', 'smoke3', 'coallight', 'smoke3'])


def quartz(d):
    for x0, h, col, hi in ((2, 7, 'light', 'shine'), (9, 6, 'blue', 'light'), (5, 11, 'shine', 'shine')):
        top = 14 - h
        poly(d, [(x0, 14), (x0, top + 2), (x0 + 2, top), (x0 + 4, top + 2), (x0 + 4, 14)], col)
        line(d, [(x0 + 1, top + 2), (x0 + 1, 13)], hi)


def pig_iron(d):
    ingot(d, 'mid', 'steel', 'dark')


def steel_ingot(d):
    ingot(d, 'light', 'mid', 'steel')


def copper_ingot(d):
    ingot(d, 'gold', 'amber', 'orange')


def steel_plate(d):
    poly(d, [(1, 8), (9, 4), (15, 7), (7, 11)], 'light')
    poly(d, [(1, 8), (7, 11), (7, 13), (1, 10)], 'steel')
    poly(d, [(7, 11), (15, 7), (15, 9), (7, 13)], 'mid')
    line(d, [(3, 8), (9, 5)], 'shine')


def steel_rod(d):
    for y in (2, 6, 10):
        rect(d, (1, y, 13, y + 3), 'mid', 'ink')
        line(d, [(2, y + 1), (12, y + 1)], 'light')
        rect(d, (13, y, 14, y + 3), 'light', 'ink')


def insulator(d):
    rect(d, (7, 1, 8, 14), 'mid')
    for y in (3, 7, 11):
        d.ellipse((2, y - 2, 13, y + 2), fill=c('light'), outline=c('ink'))
        line(d, [(4, y - 1), (10, y - 1)], 'shine')
        line(d, [(4, y + 1), (11, y + 1)], 'blue')


def fastener(d):
    line(d, [(5, 6), (13, 14)], 'ink', 4)
    line(d, [(5, 6), (13, 14)], 'mid', 2)
    for t in range(7, 14, 2):
        px(d, t, t, 'light')
    poly(d, [(1, 3), (4, 1), (7, 2), (8, 5), (5, 7), (2, 6)], 'light')
    px(d, 3, 3, 'shine')
    px(d, 4, 3, 'shine')


def shaft(d):
    line(d, [(1, 14), (14, 1)], 'ink', 4)
    line(d, [(1, 14), (14, 1)], 'mid', 2)
    line(d, [(2, 12), (12, 2)], 'light')
    for x, y in ((4, 11), (11, 4)):
        circle(d, x, y, 2, 'steel', 'ink')
    line(d, [(7, 8), (8, 7)], 'orange', 2)


DISLI = [
    '................',
    '......kkkk......',
    '...kk.kook.kk...',
    '..koak.ao.kaok..',
    '..kaoookkooook..',
    '...kook..kook...',
    '.kkok.kddk.kokk.',
    '.koak.kdsk.kaok.',
    '.kook.kdsk.kook.',
    '.kkok.kddk.kokk.',
    '...kook..kook...',
    '..koooakkooaok..',
    '..kook.oa.kook..',
    '...kk.kook.kk...',
    '......kkkk......',
    '................',
]


def gear(d):
    renk = {'k': 'ink', 'o': 'orange', 'a': 'amber', 'd': 'dark', 's': 'steel'}
    for y, satir in enumerate(DISLI):
        for x, ch in enumerate(satir):
            if ch in renk:
                px(d, x, y, renk[ch])


def bearing(d):
    circle(d, 7.5, 7.5, 7, 'mid', 'ink')
    circle(d, 7.5, 7.5, 5, 'deep')
    for i in range(6):
        a = i * math.pi / 3
        px(d, round(7.5 + 4 * math.cos(a)), round(7.5 + 4 * math.sin(a)), 'shine')
    circle(d, 7.5, 7.5, 2.5, 'light', 'ink')
    px(d, 3, 2, 'shine')
    px(d, 2, 3, 'light')


def copper_wire(d):
    rect(d, (4, 3, 11, 12), 'orange', 'ink')
    for y in range(4, 12, 2):
        line(d, [(5, y), (10, y)], 'amber')
    rect(d, (2, 1, 13, 3), 'steel', 'ink')
    rect(d, (2, 12, 13, 14), 'steel', 'ink')
    line(d, [(11, 7), (15, 9)], 'gold')


def metal_scrap(d):
    d.arc((1, 2, 9, 10), 200, 470, fill=c('light'), width=2)
    d.arc((6, 6, 14, 14), 20, 300, fill=c('mid'), width=2)
    d.arc((3, 8, 9, 14), 90, 360, fill=c('steel'), width=1)
    px(d, 4, 4, 'shine')
    px(d, 12, 8, 'light')


def housing(d):
    poly(d, [(2, 5), (9, 2), (14, 4), (7, 7)], 'light')
    poly(d, [(2, 5), (7, 7), (7, 14), (2, 12)], 'mid')
    poly(d, [(7, 7), (14, 4), (14, 11), (7, 14)], 'steel')
    for x, y in ((4, 8), (4, 11), (10, 8), (12, 9)):
        px(d, x, y, 'ink')


def coil(d):
    rect(d, (6, 0, 9, 15), 'steel', 'ink')
    rect(d, (3, 3, 12, 12), 'orange', 'ink')
    for y in range(4, 12):
        line(d, [(4, y), (11, y)], 'amber' if y % 2 else 'orange')
    line(d, [(4, 4), (4, 11)], 'gold')


def gearbox(d):
    rect(d, (1, 3, 14, 14), 'steel', 'ink')
    line(d, [(2, 4), (13, 4)], 'light')
    pts = []
    for i in range(8):
        a = i * math.pi / 4
        for da, r in ((-0.22, 3.4), (-0.12, 4.8), (0.12, 4.8), (0.22, 3.4)):
            pts.append((round(7.5 + r * math.cos(a + da * 3.2)), round(8.5 + r * math.sin(a + da * 3.2))))
    poly(d, pts, 'amber')
    circle(d, 7.5, 8.5, 1.5, 'orange', 'ink')
    rect(d, (14, 7, 15, 9), 'light', 'ink')


def circuit_board(d):
    rect(d, (1, 2, 14, 13), 'mintdark', 'ink')
    for pts in ([(3, 4), (6, 4), (6, 7)], [(9, 11), (12, 11), (12, 8)], [(3, 11), (5, 9)]):
        line(d, pts, 'mint')
    rect(d, (7, 5, 11, 8), 'coal', 'ink')
    rect(d, (3, 8, 5, 10), 'coal')
    for x, y in ((2, 3), (13, 3), (2, 12), (13, 12)):
        px(d, x, y, 'gold')


def electric_motor(d):
    rect(d, (1, 4, 11, 12), 'steel', 'ink')
    for x in (3, 5, 7, 9):
        line(d, [(x, 5), (x, 11)], 'dark')
    line(d, [(2, 5), (10, 5)], 'light')
    rect(d, (11, 5, 12, 11), 'light', 'ink')
    rect(d, (13, 7, 15, 9), 'shine', 'ink')
    rect(d, (2, 13, 10, 14), 'dark', 'ink')


def sensor(d):
    rect(d, (2, 3, 11, 13), 'dark', 'ink')
    line(d, [(3, 4), (10, 4)], 'mid')
    circle(d, 6.5, 8.5, 3, 'blue', 'ink')
    px(d, 5, 7, 'shine')
    line(d, [(11, 8), (15, 8)], 'ink', 2)
    px(d, 13, 8, 'mint')


def actuator(d):
    rect(d, (1, 4, 9, 12), 'orange', 'ink')
    line(d, [(2, 5), (8, 5)], 'amber')
    rect(d, (9, 7, 13, 9), 'shine', 'ink')
    rect(d, (13, 5, 15, 11), 'mid', 'ink')
    px(d, 14, 8, 'ink')
    rect(d, (3, 12, 7, 14), 'dark', 'ink')


def plc(d):
    rect(d, (2, 1, 13, 14), 'light', 'ink')
    rect(d, (4, 3, 11, 6), 'deep', 'ink')
    for x, col in ((5, 'mint'), (7, 'yellow'), (9, 'red')):
        px(d, x, 4, col)
        px(d, x + 1, 4, col)
    for y in (9, 11):
        for x in range(4, 12, 2):
            px(d, x, y, 'steel')
    line(d, [(3, 13), (12, 13)], 'mid')


CIZIMLER = {name: fn for name, fn in globals().items() if callable(fn)}


def main():
    urunler = list(json.loads((KOK / 'data' / 'prototype.json').read_text(encoding='utf-8'))['products'].keys())
    izinli = {tuple(int(v[j:j + 2], 16) for j in (1, 3, 5)) for v in PALET.values()}
    serit = Image.new('RGBA', (HUCRE * len(urunler), HUCRE))
    yeni = []
    for i, urun in enumerate(urunler):
        if (YENI / f'{urun}.png').exists():
            im = Image.open(YENI / f'{urun}.png').convert('RGBA')
            assert im.size == (HUCRE, HUCRE), (urun, im.size)
            yeni.append(urun)
        else:
            im = Image.new('RGBA', (S, S))
            CIZIMLER[urun](ImageDraw.Draw(im))
            im = im.resize((HUCRE, HUCRE), Image.Resampling.NEAREST)
        for r, g, b, a in set(im.get_flattened_data()):
            assert not a or (r, g, b) in izinli, (urun, (r, g, b))
        serit.paste(im, (i * HUCRE, 0))
    hedef = KOK / 'app' / 'art' / 'ui' / 'product_icons.png'
    serit.save(hedef)
    on = Image.new('RGBA', (HUCRE * 8 * 3, HUCRE * 3 * 3), '#142331')
    for i in range(len(urunler)):
        parca = serit.crop((i * HUCRE, 0, (i + 1) * HUCRE, HUCRE)).resize((HUCRE * 2, HUCRE * 2), Image.Resampling.NEAREST)
        on.alpha_composite(parca, (i % 8 * HUCRE * 3 + 16, i // 8 * HUCRE * 3 + 16))
    on.save(Path(__file__).resolve().parent / 'urun_ikonlari_x4.png')
    print('URUN_IKONLARI_OK:', hedef, len(urunler), '32x32 cizimli:', ', '.join(yeni) or '-')

main()
