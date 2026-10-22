"""Flowgame A tower furnace: original layered pixel drawing and twelve poses."""
from pathlib import Path
import math
import struct as S
import zlib
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parent
HELPERS=ROOT.parent.parent/'demir_madeni_B'/'draw_mine_node_b.py'
src=(HELPERS).read_text(encoding='utf-8')
env={'__file__':str(HELPERS)}
exec(compile(src[:src.index('# Structural shell:')],'pixel_helpers','exec'),env)
P=env['P'];P.update({'hot':'#ffc765','whitehot':'#ffe8a2','fire':'#ef873c','firedeep':'#9f442d'})
poly,circle,line,rect,bolt,rock,text=[env[k] for k in ('poly','circle','line','rect','bolt','rock','text')]
env['FONT'].update({'G':['01111','10000','10000','10111','10001','10001','01110'],
 'T':['11111','00100','00100','00100','00100','00100','00100'],
 '4':['00010','00110','01010','10010','11111','00010','00010']})
W=H=288

def fresh():
    im=Image.new('RGBA',(W,H));return im,ImageDraw.Draw(im)

def ingot(d,x,y):
    poly(d,[(x-8,y),(x-3,y-6),(x+8,y-6),(x+5,y+2),(x-5,y+5)],'mid','ink')
    poly(d,[(x-8,y),(x-3,y-6),(x+8,y-6),(x+3,y)],'light')
    line(d,[(x-3,y-6),(x+7,y-6)],'shine')

shell,d=fresh()
# Feet and cool furnace casing, deliberately different from the mine.
poly(d,[(86,229),(201,229),(213,238),(213,245),(74,245),(74,237)],'ink')
rect(d,(80,237,208,241),'steel');line(d,[(82,237),(206,237)],'light')
for x in (87,184):
    rect(d,(x,225,x+17,243),'ink');rect(d,(x+3,226,x+14,239),'orange')
    rect(d,(x+3,226,x+14,228),'amber')
poly(d,[(107,72),(183,72),(198,85),(198,181),(188,194),(100,194),(88,181),(88,87)],'ink')
poly(d,[(108,76),(181,76),(194,88),(194,179),(185,189),(103,189),(92,179),(92,89)],'steel')
poly(d,[(109,78),(178,78),(189,87),(104,87),(97,94),(96,89)],'light')
rect(d,(96,94,106,174),'dark');rect(d,(97,95,99,170),'mid')
rect(d,(179,96,190,172),'dark');rect(d,(180,97,182,168),'mid')
for y in (107,145):
    rect(d,(87,y,109,y+7),'ink');rect(d,(90,y+1,106,y+5),'orange')
    rect(d,(91,y+1,105,y+2),'amber')
rect(d,(120,89,169,176),'ink');rect(d,(124,92,165,173),'rust')
rect(d,(129,96,160,169),'deep')
line(d,[(123,92),(123,174),(166,174)],'mid')
for y in (99,158):
    rect(d,(118,y,128,y+7),'dark');bolt(d,122,y+3)
rect(d,(128,180,163,187),'ink');rect(d,(131,181,160,185),'orange')
# Lower firebox with arched face.
poly(d,[(104,190),(183,190),(201,207),(201,229),(87,229),(87,207)],'ink')
poly(d,[(107,194),(180,194),(196,209),(196,225),(92,225),(92,209)],'mid')
poly(d,[(122,198),(165,198),(178,211),(178,226),(109,226),(109,211)],'ink')
poly(d,[(125,202),(161,202),(173,213),(173,225),(114,225),(114,213)],'rust')
for x,y in [(110,84),(182,87),(104,179),(185,178),(98,216),(189,216)]:bolt(d,x,y)
# Hopper, neck and chimney.
rect(d,(116,59,142,76),'ink');rect(d,(119,61,139,73),'orange')
rect(d,(120,61,138,63),'amber')
poly(d,[(98,24),(158,24),(151,44),(140,61),(117,61),(105,44)],'ink')
poly(d,[(102,29),(154,29),(148,43),(138,56),(120,56),(109,43)],'steel')
poly(d,[(107,30),(125,30),(128,55),(121,55)],'light')
line(d,[(103,27),(153,27)],'shine',2)
rect(d,(173,26,193,76),'ink');rect(d,(177,28,190,75),'steel')
rect(d,(178,28,181,75),'light');rect(d,(186,28,189,75),'dark')
rect(d,(170,22,196,30),'ink');rect(d,(173,23,193,27),'orange')
line(d,[(174,23),(192,23)],'amber')
# A small real-button location on the right side, outside the hot window.
poly(d,[(202,86),(214,86),(219,91),(219,105),(214,110),(202,110),(197,105),(197,91)],'ink')
poly(d,[(204,89),(212,89),(216,93),(216,103),(212,107),(204,107),(200,103),(200,93)],'steel')
# Compact pour spout, catch mold, and separated output socket.
poly(d,[(194,199),(205,199),(233,215),(233,222),(226,223),(198,209)],'ink')
poly(d,[(198,201),(204,202),(229,217),(227,220),(200,206)],'orange')
line(d,[(199,201),(204,201),(230,216)],'amber')
poly(d,[(212,228),(250,228),(255,233),(255,244),(210,244),(207,239),(207,233)],'ink')
poly(d,[(213,230),(248,230),(251,234),(211,234)],'light')
rect(d,(211,235,251,241),'steel');rect(d,(216,232,246,236),'rust')
for x in (214,248):bolt(d,x,239)
# Connector conduits behind the icon sockets.
for y in (110,158):
    rect(d,(25,y-6,92,y+6),'ink');rect(d,(28,y-3,91,y+3),'steel')
    line(d,[(30,y-3),(86,y-3)],'light')
    for x in (39,46,53):line(d,[(x,y),(x,y+3)],'dark')
    rect(d,(79,y-9,88,y+9),'ink');rect(d,(81,y-6,85,y+6),'orange')
rect(d,(195,184,261,196),'ink');rect(d,(198,187,260,193),'mid')
line(d,[(199,186),(259,186)],'light')
rect(d,(249,181,258,199),'ink');rect(d,(251,184,256,196),'orange')
for x,y in [(16,110),(16,158),(270,190)]:
    circle(d,x,y,15,'ink');circle(d,x,y,12,'mid');circle(d,x,y,10,'dark')
    line(d,[(x-7,y-9),(x-2,y-11),(x+6,y-9)],'light')

material,d=fresh()
rock(d,117,24,6);rock(d,129,20,7);rock(d,142,25,6)
rock(d,108,24,4);rock(d,136,27,4)
rock(d,16,110,6)
rock(d,16,158,6)
# Coal uses the same simple silhouette with a darker value range.
for y in range(151,166):
    for x in range(9,24):
        c=material.getpixel((x,y))
        if c[3]:material.putpixel((x,y),(round(c[0]*.38),round(c[1]*.4),round(c[2]*.44),255))
ingot(d,270,190)

plate,d=fresh()
poly(d,[(78,249),(223,249),(231,257),(231,276),(224,283),(78,283),(70,276),(70,257)],'ink')
poly(d,[(80,252),(221,252),(227,258),(227,274),(221,279),(80,279),(74,273),(74,259)],'steel')
rect(d,(78,256,223,275),'deep');line(d,[(79,256),(221,256)],'mid')
circle(d,86,266,5,'ink');circle(d,86,265,3,'mint')
text(d,98,262,'ERGITME')
line(d,[(145,260),(145,272)],'steel')
ingot(d,160,266)
text(d,177,262,'40/DK')

frames=[];previews=[];games=[]
for f in range(12):
    heat,d=fresh()
    rect(d,(130,97,159,168),'firedeep')
    # Tall core, overlapping tongues of fire, warm reflection stays inside casing.
    for j in range(5):
        x=132+j*6
        top=106+round(9*math.sin(f*math.pi/6+j*1.9))
        poly(d,[(x-1,168),(x-1,top+12),(x+1,top),(x+4,top+14),(x+6,168)],'fire')
        poly(d,[(x,167),(x+1,top+20),(x+3,top+12),(x+5,167)],'hot')
    for k in range(5):
        age=(f+k*3)%12;x=134+(k*7)%21;y=166-age*5
        rect(d,(x,y,x+1,y+2),'whitehot')
    poly(d,[(117,224),(118,214),(123,210),(126,214),(130,204+(f%3)),(136,213),
            (142,207),(148,215),(154,206+((f+1)%3)),(161,213),(169,214),(171,224)],'fire')
    poly(d,[(124,224),(129,215),(134,218),(139,211+f%2),(145,218),(153,214),(163,224)],'hot')
    # The molten stream has travelling bright segments.
    line(d,[(199,203),(204,204),(230,219),(230,232)],'fire',4)
    line(d,[(200,202),(204,203),(230,218),(230,231)],'hot',2)
    for k in range(2):
        y=219+((f*2+k*7)%14)
        rect(d,(229,y,230,y+2),'whitehot')
    poly(d,[(217,233),(220,231),(240,231),(245,233),(242,235),(218,235)],'hot')
    line(d,[(221+f%3,232),(232+f%3,232)],'whitehot')
    smoke,d=fresh()
    for k in range(3):
        age=(f+k*4)%12
        x=184+round(age*.7)+round(2*math.sin(k+age*.3));y=19-age*2
        r=2+age//5
        d.rectangle((x-r,y-r,x+r,y+r),fill=(97,126,145,max(15,110-age*8)))
    layers=[('01 | Kule firin kasasi',shell),('02 | Besleme ve portlar',material),
            ('03 | Alev ve metal akisi',heat),('04 | Baca dumani',smoke),('05 | Etiket',plate)]
    frames.append(layers)
    im=Image.new('RGBA',(W,H))
    for _,part in layers:im.alpha_composite(part)
    previews.append(im)
    game=im.copy();gd=ImageDraw.Draw(game)
    rect(gd,(175,259,222,273),'deep')
    for x,y in [(16,110),(16,158),(270,190)]:circle(gd,x,y,9,'dark')
    games.append(game)

def chunk(kind,payload):return S.pack('<IH',len(payload)+6,kind)+payload
all_frames=[]
for f,layers in enumerate(frames):
    chunks=[]
    for n,(name,im) in enumerate(layers):
        if f==0:
            nm=name.encode('utf-8')
            chunks.append(chunk(0x2004,S.pack('<HHHHHHB',3,0,0,W,H,0,255)+b'\0'*3+S.pack('<H',len(nm))+nm))
        cel=S.pack('<HhhBH',n,0,0,255,2)+b'\0'*7+S.pack('<HH',W,H)+zlib.compress(im.tobytes())
        chunks.append(chunk(0x2005,cel))
    body=b''.join(chunks)
    all_frames.append(S.pack('<IHHH',len(body)+16,0xf1fa,len(chunks),100)+b'\0'*2+S.pack('<I',0)+body)
header=bytearray(128)
S.pack_into('<IHHHHHIH',header,0,128+sum(map(len,all_frames)),0xa5e0,12,W,H,32,1,100)
S.pack_into('<H',header,32,256);header[34]=header[35]=1
(ROOT/'ergitme_firini_A_anim_v1.ase').write_bytes(header+b''.join(all_frames))
previews[0].save(ROOT/'ergitme_firini_A_v1.png')
preview_frames=[]
for im in previews:
    bg=Image.new('RGBA',(W,H),'#142331');bg.alpha_composite(im)
    preview_frames.append(bg.resize((W*2,H*2),Image.Resampling.NEAREST).convert('RGB'))
preview_frames[0].save(ROOT/'ergitme_firini_A_anim_v1_onizleme.gif',save_all=True,append_images=preview_frames[1:],duration=100,loop=0,disposal=2)
atlas=Image.new('RGBA',(W*4,H*3))
for n,im in enumerate(games):atlas.paste(im,(n%4*W,n//4*H))
atlas.save(ROOT/'ergitme_firini_A_game_sheet.png')
print('FURNACE_ART_OK: 288x288, 12 frames, 5 layers')
