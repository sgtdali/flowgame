"""Yapay zeka "piksel stili" gorselleri gercek piksel art'a cevirir.

Adimlar:
  1. Arka plan / yari saydam kenarlar: seffaf gorselde alfa esiklenir; opak gorselde
     kenarlardan baslayip arka plan rengine benzeyen pikseller silinir (flood fill).
  2. Kucultme: gorsel bloklara bolunur, her blok ortanca (median) rengini alir.
  3. Renk azaltma: dither'siz median-cut; istenirse baska bir gorselin paleti kullanilir.

Kullanim:
  python pixel_donustur.py girdi.png                  -> girdi_piksel.png (+ _x4 onizleme)
  python pixel_donustur.py klasor/                    -> klasordeki tum png/jpg'ler
  python pixel_donustur.py girdi.png --blok 3 --renk 24
  python pixel_donustur.py girdi.png --olcek 0.4      -> blok yerine dogrudan olcek
  python pixel_donustur.py girdi.png --palet firin.png  -> renkleri o gorselin paletine esle
"""
import argparse
from collections import deque, Counter
from pathlib import Path
import numpy as np
from PIL import Image


def foreground_mask(rgba, tol, alpha_cut):
    """True = on plan. Seffaf gorselde alfa, opakta kenardan flood fill."""
    a = rgba[..., 3]
    if (a < 250).mean() > 0.01:
        return a >= alpha_cut
    rgb = rgba[..., :3].astype(int)
    h, w = a.shape
    border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]])
    common = [np.array(c) for c, _ in Counter(map(tuple, border // 8 * 8)).most_common(6)]

    def bgish(p):
        return min(np.abs(p - c).sum() for c in common) < tol

    bg = np.zeros((h, w), bool)
    q = deque([(y, x) for x in range(w) for y in (0, h - 1)] + [(y, x) for y in range(h) for x in (0, w - 1)])
    while q:
        y, x = q.popleft()
        if bg[y, x] or not bgish(rgb[y, x]):
            continue
        bg[y, x] = True
        q.extend((y + dy, x + dx) for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1))
                 if 0 <= y + dy < h and 0 <= x + dx < w and not bg[y + dy, x + dx])
    return ~bg


def downsample(rgba, fg, scale):
    rgb = rgba[..., :3]
    h, w = fg.shape
    H2, W2 = max(1, round(h * scale)), max(1, round(w * scale))
    out = np.zeros((H2, W2, 4), np.uint8)
    for by in range(H2):
        y0 = int(by / scale); y1 = max(y0 + 1, int((by + 1) / scale))
        for bx in range(W2):
            x0 = int(bx / scale); x1 = max(x0 + 1, int((bx + 1) / scale))
            m = fg[y0:y1, x0:x1]
            if m.mean() < 0.5:
                continue
            out[by, bx, :3] = np.median(rgb[y0:y1, x0:x1][m], axis=0)
            out[by, bx, 3] = 255
    return out


def reduce_colors(small, n, palette_img=None):
    im = Image.fromarray(small, 'RGBA')
    rgb = im.convert('RGB')
    if palette_img is not None:
        pal = palette_img.convert('RGB').quantize(256, dither=Image.Dither.NONE)
        q = rgb.quantize(palette=pal, dither=Image.Dither.NONE)
    else:
        # Palet sadece gorunen piksellerden cikarilsin; seffaf alan siyahi sayilmasin.
        opaque = small[..., 3] > 0
        px = small[opaque][:, :3].astype(float)
        strip = Image.fromarray(small[opaque][:, :3].reshape(1, -1, 3), 'RGB')
        start = strip.quantize(n, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
        centers = np.array(start.getpalette()[:n * 3], float).reshape(-1, 3)
        # Agirlikli k-means: doygun pikseller (turuncu, yesil isik) 5 kat sayilir ki az yer
        # kaplasalar da gri tonlarin icinde erimesinler.
        weight = 1 + 4 * ((px.max(1) - px.min(1)) > 60)
        for _ in range(25):
            label = ((px[:, None] - centers[None]) ** 2).sum(2).argmin(1)
            for i in range(len(centers)):
                m = label == i
                if m.any():
                    centers[i] = (px[m] * weight[m, None]).sum(0) / weight[m].sum()
        pal = Image.new('P', (1, 1))
        # Bos palet girisleri siyah kalirsa koyu pikseller ona kayar; ilk rengi tekrarla.
        flat = [int(round(v)) for v in centers.ravel()]
        pal.putpalette(flat + flat[:3] * (256 - len(centers)))
        q = rgb.quantize(palette=pal, dither=Image.Dither.NONE)
    out = Image.new('RGBA', im.size)
    out.paste(q.convert('RGB'), (0, 0), im.split()[3])
    return out


def convert(path, args, palette_img):
    rgba = np.asarray(Image.open(path).convert('RGBA'))
    fg = foreground_mask(rgba, args.tolerans, args.alfa)
    ys, xs = np.nonzero(fg)
    if len(xs) == 0:
        print(f'{path.name}: on plan bulunamadi, atlandi'); return
    pad = 2
    y0, y1 = max(0, ys.min() - pad), min(fg.shape[0], ys.max() + 1 + pad)
    x0, x1 = max(0, xs.min() - pad), min(fg.shape[1], xs.max() + 1 + pad)
    rgba, fg = rgba[y0:y1, x0:x1], fg[y0:y1, x0:x1]
    scale = args.olcek or 1 / args.blok
    small = downsample(rgba, fg, scale)
    out = reduce_colors(small, args.renk, palette_img)
    dst = Path(args.cikti) if args.cikti and path == args.girdi else path.with_name(path.stem + '_piksel.png')
    if args.cikti and Path(args.cikti).is_dir():
        dst = Path(args.cikti) / (path.stem + '_piksel.png')
    out.save(dst)
    prev = Image.new('RGBA', out.size, args.onizleme_zemin)
    prev.alpha_composite(out)
    prev.resize((out.width * 4, out.height * 4), Image.Resampling.NEAREST).save(dst.with_name(dst.stem + '_x4.png'))
    colors = len(out.getcolors(1 << 16)) - (1 if (np.asarray(out)[..., 3] == 0).any() else 0)
    print(f'{path.name} -> {dst.name}: {out.width}x{out.height}, {colors} renk')


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('girdi', type=Path, help='gorsel dosyasi veya klasor')
    ap.add_argument('-o', '--cikti', help='cikti dosyasi (tek gorsel) veya klasor')
    ap.add_argument('--blok', type=float, default=2, help='kac gorsel pikseli = 1 piksel (varsayilan 2)')
    ap.add_argument('--olcek', type=float, help='blok yerine dogrudan olcek, ornek 0.5')
    ap.add_argument('--renk', type=int, default=32, help='renk sayisi (varsayilan 32)')
    ap.add_argument('--palet', type=Path, help='renkleri bu gorselin paletine esle')
    ap.add_argument('--tolerans', type=int, default=60, help='opak arka plan icin renk toleransi')
    ap.add_argument('--alfa', type=int, default=128, help='bu alfanin alti seffaf sayilir')
    ap.add_argument('--onizleme-zemin', default='#142331', help='x4 onizlemenin zemin rengi')
    args = ap.parse_args()
    palette_img = Image.open(args.palet) if args.palet else None
    if args.girdi.is_dir():
        files = sorted(p for p in args.girdi.iterdir()
                       if p.suffix.lower() in ('.png', '.jpg', '.jpeg', '.webp') and not p.stem.endswith(('_piksel', '_x4')))
    else:
        files = [args.girdi]
    for p in files:
        convert(p, args, palette_img)


if __name__ == '__main__':
    main()
