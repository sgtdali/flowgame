"""İnşa çubuğu kategori simgeleri: 16x16, ortak palet, oyunda 2x gösterilir.

Sıra build_bar.gd'deki CATEGORIES ile aynıdır: hammadde, metalürji, şekillendirme,
talaşlı imalat, montaj, hedefler.
python art_src/araclar/kategori_ikonlari.py   -> app/art/ui/category_icons.png (96x16)
"""
from pathlib import Path
from PIL import Image

from palet import PALET

KOK = Path(__file__).resolve().parents[2]
RENK = {'.': None, 'k': 'ink', 'd': 'dark', 's': 'steel', 'm': 'mid', 'l': 'light', 'w': 'shine',
        'r': 'rust', 'o': 'orange', 'a': 'amber', 'g': 'gold', 'e': 'ember', 'R': 'red',
        'f': 'flame', 'y': 'yellow', 'h': 'hot', 'n': 'mintdark', 't': 'mint', 'b': 'blue'}

IKONLAR = {
    'hammadde': [  # kazma
        '................',
        '....kkkkkkkk....',
        '..kkwllllllmkk..',
        '.kwlkkkmmkkkmmk.',
        '.klk..kook..kmk.',
        '.kk...kook...kk.',
        '......kook......',
        '......kook......',
        '......kook......',
        '......kook......',
        '......kook......',
        '......krok......',
        '......krrk......',
        '......krrk......',
        '......kkkk......',
        '................',
    ],
    'metalurji': [  # alev
        '................',
        '.......k........',
        '......kfk.......',
        '......kfk...k...',
        '.....kffRk.kfk..',
        '....kfffRk.kfk..',
        '...kffyffRkffk..',
        '...kfyyyfRRffk..',
        '..kffyhyyfffRk..',
        '..kfyyhhyyffRk..',
        '..kfyhhhhyyfRk..',
        '..kRfyhhhyfRek..',
        '...kRfyyyfRek...',
        '....kkRRRekk....',
        '......kkkk......',
        '................',
    ],
    'sekillendirme': [  # örs
        '................',
        '................',
        '................',
        '.kkkkkkkkkkkkk..',
        'kwlllllllllllmk.',
        '.kmmmmmmmmmmmsk.',
        '..kkksmmmmsskk..',
        '.....ksmmmsk....',
        '.....ksmmssk....',
        '....ksmmmmssk...',
        '...kssmmmmsssk..',
        '..kddddddddddk..',
        '..kkkkkkkkkkkk..',
        '................',
        '................',
        '................',
    ],
    'talasli': [  # dişli
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
    ],
    'montaj': [  # İngiliz anahtarı
        '................',
        '..........kkk...',
        '.........klk.k..',
        '........klk..lk.',
        '........kwk.klk.',
        '........kllllk..',
        '.......kllmmk...',
        '......klmmkk....',
        '.....klmmk......',
        '....klmmk.......',
        '...klmmk........',
        '..klmmk.........',
        '.kwlmk..........',
        '.klmk...........',
        '..kk............',
        '................',
    ],
    'hedef': [  # deney şişesi
        '................',
        '.....kkkkkk.....',
        '.....kwllmk.....',
        '......klmk......',
        '......klmk......',
        '......klmk......',
        '.....kllmmk.....',
        '....klwlmmmk....',
        '...kllllmmmmk...',
        '..knnnnnnnnnnk..',
        '..kttttnttntnk..',
        '.kttwttttnttnnk.',
        '.ktttttttttnnnk.',
        '.knnnnnnnnnnnnk.',
        '..kkkkkkkkkkkk..',
        '................',
    ],
}


def ciz(satirlar):
    im = Image.new('RGBA', (16, 16))
    for y, satir in enumerate(satirlar):
        assert len(satir) == 16, satir
        for x, c in enumerate(satir):
            if RENK[c]:
                v = PALET[RENK[c]]
                im.putpixel((x, y), tuple(int(v[i:i + 2], 16) for i in (1, 3, 5)) + (255,))
    return im


serit = Image.new('RGBA', (16 * len(IKONLAR), 16))
for i, satirlar in enumerate(IKONLAR.values()):
    serit.paste(ciz(satirlar), (i * 16, 0))
hedef = KOK / 'app' / 'art' / 'ui' / 'category_icons.png'
hedef.parent.mkdir(parents=True, exist_ok=True)
serit.save(hedef)
bg = Image.new('RGBA', serit.size, '#142331')
bg.alpha_composite(serit)
bg.resize((serit.width * 4, 64), Image.Resampling.NEAREST).save(Path(__file__).resolve().parent / 'kategori_ikonlari_x4.png')
print('KATEGORI_IKONLARI_OK:', hedef, serit.size)
