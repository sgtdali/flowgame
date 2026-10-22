"""Ergitme fırını A, 128x128 sürüm (STANDART.md). Kule fırın: kömür hunisi, baca, pencere,
ocak ağzı ve sağda eriyik döken oluk. Boru ve soket yok; bağlantılar kartın portlarıdır.

python art_src/ergitme_firini_A/draw_smelter_128.py [--oyuna]
"""
from pathlib import Path
import math
import sys

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT.parent / 'araclar'))
from makine128 import katman, rect, poly, line, circle, px, bolt, kaydet  # noqa: E402


def govde():
    im, d = katman()
    # taban ve ayaklar
    rect(d, (26, 108, 102, 115), 'dark', 'ink')
    line(d, [(27, 109), (101, 109)], 'mid')
    for x in (28, 90):
        rect(d, (x, 115, x + 10, 120), 'deep', 'ink')
    # alt ocak bloğu
    rect(d, (30, 74, 98, 108), 'steel', 'ink')
    line(d, [(31, 75), (97, 75)], 'light')
    line(d, [(31, 76), (31, 107)], 'mid')
    line(d, [(97, 76), (97, 107)], 'dark')
    # ocak ağzı (kemer)
    rect(d, (44, 84, 84, 106), 'ink')
    poly(d, [(44, 86), (48, 82), (80, 82), (84, 86)], 'ink')
    rect(d, (46, 86, 82, 105), 'ember')
    # kemer taşı
    line(d, [(43, 85), (47, 81), (81, 81), (85, 85)], 'orange')
    line(d, [(48, 80), (80, 80)], 'amber')
    # üst gövde (şaft)
    rect(d, (38, 34, 90, 74), 'steel', 'ink')
    line(d, [(39, 35), (89, 35)], 'light')
    line(d, [(39, 36), (39, 73)], 'mid')
    line(d, [(89, 36), (89, 73)], 'dark')
    # bakır kuşaklar
    for y in (44, 66):
        rect(d, (36, y, 92, y + 3), 'orange', 'ink')
        line(d, [(37, y + 1), (91, y + 1)], 'amber')
    # pencere çerçevesi
    rect(d, (54, 38, 74, 70), 'dark', 'ink')
    rect(d, (57, 41, 71, 67), 'ink')
    # tepe kapağı
    rect(d, (36, 28, 92, 34), 'mid', 'ink')
    line(d, [(37, 29), (91, 29)], 'light')
    # kömür hunisi (sol)
    poly(d, [(36, 14), (60, 14), (54, 27), (42, 27)], 'mid', 'ink')
    line(d, [(37, 15), (59, 15)], 'light')
    poly(d, [(50, 16), (58, 16), (53, 26), (49, 26)], 'steel')
    # baca (sağ)
    rect(d, (70, 12, 80, 28), 'steel', 'ink')
    line(d, [(71, 13), (71, 27)], 'light')
    rect(d, (68, 10, 82, 14), 'orange', 'ink')
    line(d, [(69, 11), (81, 11)], 'amber')
    # eriyik oluğu ve pota (sağ alt)
    poly(d, [(98, 88), (110, 92), (110, 95), (98, 92)], 'orange', 'ink')
    rect(d, (103, 106, 119, 119), 'dark', 'ink')
    rect(d, (105, 107, 117, 109), 'ember')
    line(d, [(104, 110), (118, 110)], 'steel')
    line(d, [(104, 107), (104, 118)], 'mid')
    # cıvatalar
    for x, y in ((34, 78), (94, 78), (34, 104), (94, 104), (42, 38), (86, 38), (42, 62), (86, 62)):
        bolt(d, x, y)
    return im


def komur():
    im, d = katman()
    for x, y in ((41, 12), (46, 10), (51, 12), (56, 11), (44, 14), (53, 14)):
        circle(d, x, y, 3, 'coal', 'ink')
        px(d, x - 1, y - 1, 'coallight')
    return im


def pencere(f):
    im, d = katman()
    t = 0.5 + 0.5 * math.sin(f / 12 * 2 * math.pi)
    rect(d, (58, 42, 70, 66), 'red')
    rect(d, (59, 46 - round(t * 2), 69, 66), 'flame')
    rect(d, (61, 52 - round(t * 3), 67, 66), 'yellow')
    rect(d, (63, 58 - round(t * 2), 65, 66), 'hot')
    # yükselen kıvılcımlar
    for k in range(3):
        y = 64 - ((f * 2 + k * 8) % 22)
        px(d, 60 + k * 4, y, 'gold')
    return im


def ates(f):
    im, d = katman()
    for i, x in enumerate(range(48, 81, 6)):
        h = 8 + round(5 * (0.5 + 0.5 * math.sin((f + i * 3) / 12 * 2 * math.pi)))
        poly(d, [(x - 3, 105), (x, 105 - h), (x + 3, 105)], 'flame')
        poly(d, [(x - 1, 105), (x, 105 - h + 4), (x + 1, 105)], 'yellow')
    # kor yatağı
    for x in range(47, 82, 3):
        px(d, x, 104, 'hot' if (x + f) % 4 == 0 else 'yellow')
    return im


def eriyik(f):
    im, d = katman()
    line(d, [(99, 90), (109, 93)], 'yellow')
    # oluktan potaya damlayan metal
    for k in range(2):
        y = 95 + ((f + k * 6) % 12) * 11 // 12
        rect(d, (110, y, 111, y + 1), 'flame' if k else 'yellow')
    for x in range(106, 117):
        px(d, x, 107, 'hot' if (x + f) % 5 == 0 else 'yellow')
    return im


def duman(f):
    im, d = katman()
    renkler = ('smoke1', 'smoke2', 'smoke3')
    for k in range(3):
        yas = (f + k * 4) % 12
        x = 75 + round(yas * 0.6 + 1.5 * math.sin(k * 1.7 + yas * 0.6))
        y = 8 - yas * 7 // 12
        r = 1 + yas // 5
        circle(d, x, y, r, renkler[min(2, yas // 4)])
    return im


def cizim(f):
    return [
        ('01 | Govde', govde()),
        ('02 | Komur', komur()),
        ('03 | Pencere isigi', pencere(f)),
        ('04 | Ocak atesi', ates(f)),
        ('05 | Eriyik metal', eriyik(f)),
        ('06 | Baca dumani', duman(f)),
    ]


kaydet(ROOT, 'smelter_128', cizim, 'smelter_a', 'smelter_sheet.png')
