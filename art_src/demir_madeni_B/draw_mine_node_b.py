"""Editable pixel-art mining node. Pure drawing, no generated image inputs."""
from pathlib import Path
import math
import random
import struct as S
import zlib
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
W, H = 288, 256
P = {
    'ink': '#111b28', 'deep': '#1a2938', 'dark': '#283c4e',
    'steel': '#425c70', 'mid': '#617e91', 'light': '#9db4bf',
    'shine': '#d2dcd4', 'rust': '#693d30', 'orange': '#b96537',
    'amber': '#e69b53', 'gold': '#f2c078', 'mint': '#70d6b2',
    'mintdark': '#277564', 'dust': '#a69b83',
}
layers = []


def layer(name):
    im = Image.new('RGBA', (W, H))
    layers.append((name, im))
    return ImageDraw.Draw(im)


def rect(d, box, fill, outline=None, width=1):
    d.rectangle(box, fill=P.get(fill, fill), outline=P.get(outline, outline), width=width)


def poly(d, points, fill, outline=None, width=1):
    d.polygon(points, fill=P.get(fill, fill))
    if outline:
        d.line(points + [points[0]], fill=P.get(outline, outline), width=width)


def line(d, points, fill, width=1):
    d.line(points, fill=P.get(fill, fill), width=width)


def circle(d, x, y, r, fill, outline=None, width=1):
    d.ellipse((x-r, y-r, x+r, y+r), fill=P.get(fill, fill),
              outline=P.get(outline, outline), width=width)


def bolt(d, x, y):
    circle(d, x, y, 4, 'ink')
    circle(d, x, y-1, 2, 'mid')
    line(d, [(x-1,y-2),(x+1,y-2)], 'light')
    line(d, [(x-1,y+1),(x+1,y-1)], 'dark')


def rock(d, x, y, r=7, variant=0):
    pts=[(x-r,y-1),(x-r+2,y-r+2),(x+1,y-r),(x+r-1,y-3),
         (x+r,y+r-3),(x+2,y+r),(x-r+2,y+r-2)]
    poly(d, pts, 'mid', 'ink')
    poly(d, [pts[0],pts[1],pts[2],(x,y),(x-r+2,y+3)], 'light')
    poly(d, [(x,y),pts[3],pts[4],pts[5],(x,y+r-1)], 'steel')
    line(d,[pts[1],pts[2],(x+3,y-r+2)],'shine')


FONT={
'D':['11110','10001','10001','10001','10001','10001','11110'],
'E':['11111','10000','10000','11110','10000','10000','11111'],
'M':['10001','11011','10101','10101','10001','10001','10001'],
'I':['111','010','010','010','010','010','111'],
'R':['11110','10001','10001','11110','10100','10010','10001'],
'0':['01110','10001','10011','10101','11001','10001','01110'],
'3':['11110','00001','00001','01110','00001','00001','11110'],
'/':['00001','00001','00010','00100','01000','10000','10000'],
'K':['10001','10010','10100','11000','10100','10010','10001'],
' ':['000']*7,
}


def text(d,x,y,s,color='shine',scale=1):
    for c in s:
        glyph=FONT[c]
        for yy,row in enumerate(glyph):
            for xx,v in enumerate(row):
                if v=='1':
                    rect(d,(x+xx*scale,y+yy*scale,x+(xx+1)*scale-1,y+(yy+1)*scale-1),color)
        x+=(len(glyph[0])+1)*scale


# Structural shell: clipped industrial silhouette, left observation bay.
d=layer('01 | Kasa ve baglanti')
poly(d,[(42,25),(175,25),(186,36),(217,36),(232,51),(232,192),
        (219,208),(41,208),(23,190),(23,44)],'ink')
poly(d,[(44,28),(173,28),(184,39),(215,39),(228,52),(228,190),
        (216,204),(43,204),(27,188),(27,46)],'steel')
poly(d,[(45,30),(171,30),(181,40),(213,40),(222,49),(42,49),
        (31,59),(31,47)],'light')
poly(d,[(216,55),(226,54),(226,189),(214,201),(211,190),(216,177)],'dark')
poly(d,[(44,53),(111,53),(123,65),(123,164),(109,179),(44,179),
        (38,171),(38,62)],'ink')
poly(d,[(46,57),(108,57),(117,66),(117,161),(105,173),(46,173),
        (43,168),(43,65)],'deep')
rect(d,(127,55,211,169),'ink')
rect(d,(131,59,207,165),'deep')
line(d,[(48,55),(107,55),(119,67)],'mid')
line(d,[(130,57),(208,57)],'mid')
rect(d,(59,20,86,28),'ink'); rect(d,(62,20,83,25),'orange')
rect(d,(62,20,83,21),'amber')
rect(d,(180,31,195,39),'ink');rect(d,(183,32,192,37),'orange')
# Outgoing connector has a visible collar and socket.
rect(d,(227,143,259,155),'ink');rect(d,(229,145,259,152),'mid')
rect(d,(232,145,258,147),'light')
for x in (236,242,248):line(d,[(x,148),(x,152)],'dark')
rect(d,(252,139,261,159),'ink');rect(d,(254,142,259,156),'orange')
circle(d,270,149,16,'ink');circle(d,270,149,13,'mid')
circle(d,270,149,11,'dark');line(d,[(261,139),(268,136),(277,139)],'light')
rock(d,270,149,6)
for x,y in [(40,43),(164,40),(215,53),(216,181),(39,185),(119,191)]:bolt(d,x,y)
# Deliberate sparse wear; no raster noise.
for x,y in [(53,38),(143,36),(35,92),(220,112),(30,155),(194,194)]:
    line(d,[(x,y),(x+4,y)],'mid');line(d,[(x+1,y+1),(x+2,y+1)],'dark')

d=layer('02 | Matkap ve mekanizma')
# Rear vertical rails and carriage.
for x in (49,100):
    rect(d,(x,65,x+6,154),'ink');rect(d,(x+1,65,x+3,152),'steel')
    rect(d,(x+1,67,x+1,149),'light')
rect(d,(57,52,98,71),'ink');rect(d,(60,54,95,69),'orange')
rect(d,(61,54,94,56),'amber');rect(d,(64,64,91,70),'rust')
for x in (65,89):bolt(d,x,60)
rect(d,(64,72,91,110),'ink')
rect(d,(66,73,89,108),'steel');rect(d,(69,73,75,108),'light')
rect(d,(76,73,81,108),'mid');rect(d,(84,73,88,108),'dark')
for y in (77,94,108):
    rect(d,(59,y,96,y+7),'ink');rect(d,(61,y+1,94,y+5),'orange')
    rect(d,(63,y+1,92,y+2),'amber')
# Helical drill, bevelled across four flights.
poly(d,[(66,114),(89,114),(88,137),(77,155),(67,138)],'ink')
rect(d,(72,115,82,140),'mid')
for y,width in [(116,23),(123,23),(130,19),(137,13)]:
    x=77-width//2
    poly(d,[(x,y+3),(x+width-3,y-1),(x+width,y+3),(x+3,y+8)],'steel','ink')
    line(d,[(x+2,y+3),(x+width-3,y)],'light',2)
    line(d,[(x+4,y+7),(x+width-1,y+4)],'dark')
poly(d,[(72,145),(82,144),(77,153)],'light','ink')
# Gear drive pipe connects the two mechanisms.
line(d,[(98,82),(115,82),(126,93),(135,93)],'ink',10)
line(d,[(98,80),(115,80),(128,91),(137,91)],'mid',5)
line(d,[(98,78),(115,78)],'light')
# Rear drive ring with five operating segments.
circle(d,163,91,36,'ink');circle(d,163,91,33,'steel')
circle(d,163,91,28,'deep')
for a in range(-105,16,24):
    points=[]
    for r,angles in [(33,range(a,a+18)),(29,range(a+17,a-1,-1))]:
        points.extend([(round(163+r*math.cos(math.radians(t))),round(91+r*math.sin(math.radians(t)))) for t in angles])
    poly(d,points,'mint' if a<0 else 'mintdark')
# Pause key integrated in top right casing.
poly(d,[(199,64),(210,64),(216,70),(216,82),(210,88),(199,88),
        (193,82),(193,70)],'ink')
poly(d,[(200,67),(209,67),(213,71),(213,81),(209,85),(200,85),
        (196,81),(196,71)],'steel')
rect(d,(200,71,202,81),'shine');rect(d,(206,71,208,81),'shine')

d=layer('03 | Disli')
pts=[]
for i in range(12):
    for q,r in [(0,24),(0.16,29),(0.62,29),(0.78,24)]:
        a=(i+q)*math.pi/6
        pts.append((round(163+r*math.cos(a)),round(91+r*math.sin(a))))
poly(d,pts,'orange','ink',2)
line(d,[(143,74),(151,67),(159,66)],'amber',2)
circle(d,163,91,20,'rust','ink',2)
circle(d,163,91,17,'steel','amber')
circle(d,163,91,13,'light','ink',2)
circle(d,163,91,9,'mid','dark')
circle(d,163,91,5,'dark','ink')
line(d,[(159,86),(164,84),(168,87)],'shine')
rect(d,(160,90,166,92),'ink')

d=layer('04 | Cevher ve cikis bandi')
rock(d,56,158,10);rock(d,81,165,12);rock(d,99,155,9)
rock(d,65,170,7);rock(d,104,169,6);rock(d,85,149,7)
# Hopper and ore contents.
poly(d,[(135,137),(207,137),(207,146),(185,175),(165,175),(137,147)],'ink')
poly(d,[(140,141),(202,141),(185,169),(166,169)],'steel')
poly(d,[(143,144),(177,144),(173,168),(167,168)],'mid')
line(d,[(145,145),(165,165)],'light')
rock(d,150,136,8);rock(d,166,132,10);rock(d,183,137,8);rock(d,192,133,6)
rect(d,(134,142,207,147),'ink');rect(d,(137,142,204,144),'light')
rect(d,(168,170,185,179),'ink');rect(d,(170,170,182,176),'orange')
# Conveyor front cover and repeating rollers.
rect(d,(42,177,210,195),'ink');rect(d,(46,180,206,190),'dark')
line(d,[(49,179),(202,179)],'mid')
for x in range(51,204,15):
    circle(d,x,185,5,'ink');circle(d,x,184,3,'orange')
    line(d,[(x-1,182),(x+1,182)],'amber')
rect(d,(46,192,206,196),'steel');line(d,[(48,192),(203,192)],'light')
rock(d,112,175,6);rock(d,147,176,5);rock(d,195,175,7)

d=layer('05 | Etiket ve durum')
poly(d,[(44,202),(207,202),(215,210),(215,232),(208,240),
        (44,240),(35,231),(35,211)],'ink')
poly(d,[(46,205),(205,205),(211,211),(211,230),(205,236),
        (46,236),(39,230),(39,213)],'steel')
rect(d,(44,209,206,232),'deep');line(d,[(45,209),(204,209)],'mid')
circle(d,55,221,6,'ink');circle(d,55,220,4,'mintdark')
circle(d,55,219,3,'mint');rect(d,(53,217,54,218),'shine')
text(d,68,217,'DEMIR',scale=1)
line(d,[(112,214),(112,228)],'steel')
rock(d,126,221,6)
text(d,139,217,'30/DK',scale=1)
for x in (42,208):rect(d,(x,216,x+1,223),'mid')

# Editable native document: each component is a named, full-canvas RGBA layer.
def chunk(kind,payload):
    return S.pack('<IH',len(payload)+6,kind)+payload

chunks=[]
for n,(name,im) in enumerate(layers):
    nm=name.encode('utf-8')
    chunks.append(chunk(0x2004,S.pack('<HHHHHHB',3,0,0,W,H,0,255)+b'\0'*3+S.pack('<H',len(nm))+nm))
    cel=S.pack('<HhhBH',n,0,0,255,2)+b'\0'*7+S.pack('<HH',W,H)+zlib.compress(im.tobytes())
    chunks.append(chunk(0x2005,cel))
frame_data=b''.join(chunks)
frame=S.pack('<IHHH',len(frame_data)+16,0xf1fa,len(chunks),100)+b'\0'*2+S.pack('<I',0)+frame_data
header=bytearray(128)
S.pack_into('<IHHHHHIH',header,0,128+len(frame),0xa5e0,1,W,H,32,1,100)
header[28]=0; S.pack_into('<H',header,32,256);header[34]=1;header[35]=1
ase=ROOT/'demir_madeni_node_B_v1.ase'
ase.write_bytes(header+frame)
composite=Image.new('RGBA',(W,H))
for _,im in layers:composite=Image.alpha_composite(composite,im)
composite.save(ROOT/'demir_madeni_node_B_v1.png')
preview=Image.new('RGBA',(W,H),'#142331');preview.alpha_composite(composite)
preview.resize((W*3,H*3),Image.Resampling.NEAREST).save(ROOT/'demir_madeni_node_B_v1_onizleme.png')
print(ase)
print('Layers:',len(layers),'Canvas:',W,H)
