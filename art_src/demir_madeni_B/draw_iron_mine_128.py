"""Demir madeni B, 128x128 sürüm (STANDART.md). Matkap sola, dişli ve huni sağa, altta bant.

python art_src/demir_madeni_B/draw_iron_mine_128.py [--oyuna]
"""
from pathlib import Path
import math
import sys

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT.parent / 'araclar'))
from makine128 import katman, rect, poly, line, circle, px, bolt, tas, disli, kaydet  # noqa: E402


def kasa():
    im, d = katman()
    # ayaklar ve gövde
    rect(d, (14, 110, 26, 119), 'dark', 'ink')
    rect(d, (101, 110, 113, 119), 'dark', 'ink')
    poly(d, [(14, 22), (110, 22), (117, 29), (117, 110), (10, 110), (10, 26)], 'steel', 'ink')
    line(d, [(12, 24), (109, 24)], 'light')
    line(d, [(110, 25), (115, 30)], 'light')
    line(d, [(11, 27), (11, 108)], 'mid')
    line(d, [(116, 31), (116, 108)], 'dark')
    line(d, [(11, 109), (116, 109)], 'dark')
    # üst kapaklar
    rect(d, (22, 16, 38, 23), 'orange', 'ink')
    line(d, [(23, 17), (37, 17)], 'amber')
    rect(d, (92, 18, 102, 23), 'rust', 'ink')
    # iki bölme
    rect(d, (16, 29, 55, 93), 'deep', 'ink')
    rect(d, (61, 29, 111, 93), 'deep', 'ink')
    line(d, [(17, 30), (54, 30)], 'ink')
    line(d, [(62, 30), (110, 30)], 'ink')
    # matkap kılavuz rayları
    line(d, [(20, 33), (20, 78)], 'dark')
    line(d, [(51, 33), (51, 78)], 'dark')
    # matkap başlığı
    rect(d, (24, 32, 47, 40), 'orange', 'ink')
    line(d, [(25, 33), (46, 33)], 'amber')
    bolt(d, 28, 36)
    bolt(d, 43, 36)
    # bölmeler arası aktarma kolu
    rect(d, (47, 44, 64, 47), 'mid', 'ink')
    line(d, [(48, 45), (63, 45)], 'light')
    # dişli yatağı
    circle(d, 84, 50, 17, 'dark', 'ink')
    # huni
    poly(d, [(68, 72), (104, 72), (92, 86), (80, 86)], 'mid', 'ink')
    line(d, [(70, 73), (102, 73)], 'light')
    poly(d, [(86, 74), (101, 74), (91, 85), (88, 85)], 'steel')
    rect(d, (82, 86, 90, 90), 'orange', 'ink')
    # bant çerçevesi
    rect(d, (14, 95, 113, 104), 'dark', 'ink')
    # cıvatalar
    for x, y in ((14, 27), (113, 33), (14, 106), (113, 106), (63, 26)):
        bolt(d, x, y)
    return im


def cevher_yigini():
    im, d = katman()
    for x, y, r in ((24, 88, 5), (33, 86, 6), (44, 89, 4), (28, 82, 3), (39, 81, 4)):
        tas(d, x, y, r)
    for x, y, r in ((74, 69, 4), (82, 67, 5), (92, 69, 4), (99, 70, 3)):
        tas(d, x, y, r, 'ore', 'dust', 'oredark')
    return im


def matkap(f):
    im, d = katman()
    # mil inip çıkar (12 karede bir tur)
    dy = round(2 * math.sin(f / 12 * 2 * math.pi))
    rect(d, (31, 40, 40, 58 + dy), 'mid', 'ink')
    line(d, [(32, 41), (32, 57 + dy)], 'light')
    for y in (44, 51):
        rect(d, (29, y + dy, 42, y + 2 + dy), 'orange', 'ink')
    # helezon uç, çizgiler aşağı kayar
    ust, alt = 59 + dy, 78 + dy
    for y in range(ust, alt + 1):
        yari = max(1, round(5 * (alt - y) / (alt - ust)))
        line(d, [(35 - yari, y), (35 + yari, y)], 'mid')
        if (y + f) % 4 == 0:
            line(d, [(35 - yari, y), (35 + yari, y - 1)], 'light')
        elif (y + f) % 4 == 1:
            line(d, [(35 - yari, y), (35 + yari, y)], 'steel')
        px(d, 35 - yari - 1, y, 'ink')
        px(d, 35 + yari + 1, y, 'ink')
    px(d, 35, alt + 1, 'ink')
    return im


def disli_kat(f):
    im, d = katman()
    # 10 diş, 12 karede bir diş adımı döner -> kesintisiz döngü
    aci = f / 12 * (2 * math.pi / 10)
    disli(d, 84, 50, 15, 12, 10, aci, 'orange')
    circle(d, 84, 50, 10, 'rust', 'ink')
    circle(d, 84, 50, 7, 'steel', 'ink')
    circle(d, 84, 50, 3, 'mid', 'ink')
    px(d, 83, 49, 'light')
    # işaret çentiği dişliyle döner
    a = aci * 1.0
    px(d, round(84 + 8 * math.cos(a)), round(50 + 8 * math.sin(a)), 'amber')
    return im


def bant(f):
    im, d = katman()
    rect(d, (16, 97, 111, 102), 'ink')
    for i in range(12):
        x = 18 + i * 8 + (f * 2) % 8
        if x <= 109:
            circle(d, x, 99, 2, 'orange')
            px(d, x - 1, 98, 'amber')
    # bant üstünde ilerleyen cevher parçaları
    for k in range(3):
        x = 20 + (k * 32 + f * 8 // 3) % 90
        tas(d, x, 93, 3, 'ore', 'dust', 'oredark')
    return im


def kirintilar(f):
    im, d = katman()
    # matkap ucundan sıçrayan parçalar
    for k in range(3):
        t = (f + k * 4) % 12
        x = 35 + (k - 1) * (2 + t)
        y = 80 - (6 - abs(6 - t))
        px(d, x, y, 'dust')
    # huniden düşen cevher
    y = 86 + (f % 4) * 2
    rect(d, (85, y, 86, y + 1), 'ore')
    return im


def cizim(f):
    return [
        ('01 | Kasa', kasa()),
        ('02 | Cevher yigini', cevher_yigini()),
        ('03 | Matkap', matkap(f)),
        ('04 | Disli', disli_kat(f)),
        ('05 | Bant', bant(f)),
        ('06 | Kirintilar', kirintilar(f)),
    ]


kaydet(ROOT, 'iron_mine_128', cizim, 'iron_mine_b', 'iron_mine_sheet.png')
