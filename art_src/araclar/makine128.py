"""128x128 makine görselleri için ortak yardımcılar: çizim, palet denetimi, .ase/sheet/önizleme.

Bir makine script'i `cizim(f)` fonksiyonu yazar; f = 0..11 kare numarası, dönen değer
[(katman_adi, Image), ...]. Sonra `kaydet(...)` her şeyi üretir.
"""
from pathlib import Path
import math
import struct as S
import sys
import zlib
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from palet import PALET  # noqa: E402

W = H = 128
KARE = 12
APP_ART = Path(__file__).resolve().parents[2] / 'app' / 'art'


def renk(c):
    return PALET.get(c, c) if c else None


def katman():
    im = Image.new('RGBA', (W, H))
    return im, ImageDraw.Draw(im)


def rect(d, box, fill, outline=None):
    d.rectangle(box, fill=renk(fill), outline=renk(outline))


def poly(d, pts, fill, outline=None):
    d.polygon(pts, fill=renk(fill), outline=renk(outline))


def line(d, pts, fill, width=1):
    d.line(pts, fill=renk(fill), width=width)


def circle(d, x, y, r, fill, outline=None):
    d.ellipse((x - r, y - r, x + r, y + r), fill=renk(fill), outline=renk(outline))


def px(d, x, y, c):
    d.point((x, y), fill=renk(c))


def bolt(d, x, y):
    rect(d, (x - 1, y - 1, x + 1, y + 1), 'ink')
    px(d, x, y, 'light')


def tas(d, x, y, r=4, ana='mid', acik='light', golge='steel'):
    """Küçük kaya/cevher parçası."""
    pts = [(x - r, y), (x - r + 1, y - r + 1), (x + 1, y - r), (x + r, y - 1), (x + r - 1, y + r - 1), (x - r + 1, y + r - 1)]
    poly(d, pts, ana, 'ink')
    if r >= 3:
        line(d, [(x - r + 2, y - 1), (x, y - r + 2)], acik)
        line(d, [(x + 1, y + r - 2), (x + r - 2, y)], golge)


def disli(d, cx, cy, r_dis, r_ic, dis_sayisi, aci, fill, outline='ink'):
    """Dönen dişli; aci radyan."""
    pts = []
    adim = 2 * math.pi / dis_sayisi
    for i in range(dis_sayisi):
        a = aci + i * adim
        for da, r in ((-0.28, r_ic), (-0.16, r_dis), (0.16, r_dis), (0.28, r_ic)):
            pts.append((round(cx + r * math.cos(a + da * adim * 1.6)), round(cy + r * math.sin(a + da * adim * 1.6))))
    poly(d, pts, fill, outline)


def palet_denetle(katmanlar_listesi):
    izinli = {tuple(int(v[i:i + 2], 16) for i in (1, 3, 5)) for v in PALET.values()}
    for f, katmanlar in enumerate(katmanlar_listesi):
        for ad, im in katmanlar:
            for r, g, b, a in set(im.getdata()):
                if a and (r, g, b) not in izinli:
                    raise SystemExit(f'Palet dışı renk {(r, g, b)} kare {f} katman {ad}')
            bbox = im.getbbox()
            if bbox and (bbox[2] > W or bbox[3] > H):
                raise SystemExit(f'Tuval dışı: {ad}')


def _ase(yol, kareler):
    def chunk(kind, payload):
        return S.pack('<IH', len(payload) + 6, kind) + payload
    tum = []
    for f, katmanlar in enumerate(kareler):
        chunks = []
        for n, (ad, im) in enumerate(katmanlar):
            if f == 0:
                nm = ad.encode('utf-8')
                chunks.append(chunk(0x2004, S.pack('<HHHHHHB', 3, 0, 0, W, H, 0, 255) + b'\0' * 3 + S.pack('<H', len(nm)) + nm))
            cel = S.pack('<HhhBH', n, 0, 0, 255, 2) + b'\0' * 7 + S.pack('<HH', W, H) + zlib.compress(im.tobytes())
            chunks.append(chunk(0x2005, cel))
        govde = b''.join(chunks)
        tum.append(S.pack('<IHHH', len(govde) + 16, 0xf1fa, len(chunks), 100) + b'\0' * 2 + S.pack('<I', 0) + govde)
    header = bytearray(128)
    S.pack_into('<IHHHHHIH', header, 0, 128 + sum(map(len, tum)), 0xa5e0, len(kareler), W, H, 32, 1, 100)
    S.pack_into('<H', header, 32, 256)
    header[34] = header[35] = 1
    yol.write_bytes(header + b''.join(tum))


def kaydet(klasor, ad, cizim, oyun_klasoru, oyun_adi):
    """12 kareyi çizer, denetler; .ase, önizleme, gif ve (--oyuna ile) oyun sheet'ini yazar."""
    kareler = [cizim(f) for f in range(KARE)]
    palet_denetle(kareler)
    birlesik = []
    for katmanlar in kareler:
        im = Image.new('RGBA', (W, H))
        for _, k in katmanlar:
            im.alpha_composite(k)
        birlesik.append(im)
    _ase(klasor / f'{ad}.ase', kareler)
    sheet = Image.new('RGBA', (W * 4, H * 3))
    for n, im in enumerate(birlesik):
        sheet.paste(im, (n % 4 * W, n // 4 * H))
    sheet.save(klasor / f'{ad}_sheet.png')
    zemin = []
    for im in birlesik:
        bg = Image.new('RGBA', (W, H), '#142331')
        bg.alpha_composite(im)
        zemin.append(bg.resize((W * 4, H * 4), Image.Resampling.NEAREST).convert('RGB'))
    zemin[0].save(klasor / f'{ad}_onizleme.png')
    zemin[0].save(klasor / f'{ad}.gif', save_all=True, append_images=zemin[1:], duration=100, loop=0, disposal=2)
    ggovde = birlesik[0].getbbox()
    print(f'{ad}: 128x128, {KARE} kare, {len(kareler[0])} katman, gövde {ggovde}')
    if '--oyuna' in sys.argv:
        hedef = APP_ART / oyun_klasoru / oyun_adi
        sheet.save(hedef)
        print('oyuna yazildi:', hedef)
