"""Flowgame A tower furnace v2: closer to the reference (chunky tower, square sockets).

Game anchors kept from v1: sockets (16,110) (16,158) (270,190), status dot (86,265),
rate label x176-223, pause button x201-216 y88-106.
"""
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
P=env['P'];P.update({'hot':'#ffc765','whitehot':'#fff1c2','fire':'#ef873c','firedeep':'#9f442d',
                     'ember':'#5c2a22','copper':'#c8763e','coal':'#20242c','coallit':'#4a5260'})
poly,circle,line,rect,bolt,rock,text=[env[k] for k in ('poly','circle','line','rect','bolt','rock','text')]
env['FONT'].update({'G':['01111','10000','10000','10111','10001','10001','01110'],
 'T':['11111','00100','00100','00100','00100','00100','00100'],
 '4':['00010','00110','01010','10010','11111','00010','00010']})
W=H=288

def fresh():
    im=Image.new('RGBA',(W,H));return im,ImageDraw.Draw(im)

def panel(d,box,fill='steel',hi='light',lo='dark'):
    """Ink-outlined plate with a lit top/left edge and a shaded bottom/right edge."""
    x0,y0,x1,y1=box
    rect(d,box,'ink');rect(d,(x0+1,y0+1,x1-1,y1-1),fill)
    line(d,[(x0+1,y1-1),(x0+1,y0+1),(x1-1,y0+1)],hi)
    line(d,[(x0+2,y1-1),(x1-1,y1-1),(x1-1,y0+2)],lo)

def rivet(d,x,y):
    rect(d,(x,y,x+1,y+1),'light');rect(d,(x+1,y+1,x+2,y+2),'ink');d.point((x,y),fill=P['shine'])

def band(d,box):
    """Copper strap / bracket."""
    x0,y0,x1,y1=box
    rect(d,box,'ink');rect(d,(x0+1,y0+1,x1-1,y1-1),'orange')
    line(d,[(x0+1,y0+1),(x1-1,y0+1)],'amber');line(d,[(x0+1,y1-1),(x1-1,y1-1)],'rust')

def flange(d,x,y,h=10):
    rect(d,(x,y-h,x+6,y+h),'ink');rect(d,(x+1,y-h+1,x+5,y+h-1),'mid')
    line(d,[(x+1,y-h+1),(x+1,y+h-1)],'light');line(d,[(x+5,y-h+2),(x+5,y+h-1)],'dark')

def socket(d,x,y):
    rect(d,(x-15,y-15,x+15,y+15),'ink')
    rect(d,(x-14,y-14,x+14,y+14),'mid')
    rect(d,(x-12,y-12,x+12,y+12),'deep')
    line(d,[(x-14,y-14),(x+14,y-14)],'light');line(d,[(x-14,y-14),(x-14,y+14)],'light')
    for cx,cy in ((x-14,y-14),(x+14,y-14),(x-14,y+14),(x+14,y+14)):d.point((cx,cy),fill=P['ink'])

def ingot(d,x,y):
    poly(d,[(x-8,y),(x-3,y-6),(x+8,y-6),(x+5,y+2),(x-5,y+5)],'mid','ink')
    poly(d,[(x-8,y),(x-3,y-6),(x+8,y-6),(x+3,y)],'light')
    line(d,[(x-3,y-6),(x+7,y-6)],'shine')

def coal(d,x,y,r=4):
    pts=[(x-r,y),(x-r+1,y-r+1),(x+1,y-r),(x+r,y-1),(x+r-1,y+r-1),(x-r+2,y+r)]
    poly(d,pts,'coal','ink');line(d,[pts[1],pts[2]],'coallit');d.point((x-1,y-1),fill=P['coallit'])

shell,d=fresh()
# --- Base plate and feet ---
poly(d,[(80,236),(206,236),(214,243),(214,247),(72,247),(72,243)],'ink')
rect(d,(76,240,210,244),'steel');line(d,[(78,240),(208,240)],'light')
for x0 in (82,174):
    panel(d,(x0,222,x0+30,242),'steel')
    rect(d,(x0+4,226,x0+26,229),'dark');rivet(d,x0+4,234);rivet(d,x0+24,234)
# --- Lower firebox housing (wider than the tower) ---
poly(d,[(84,168),(202,168),(208,174),(208,226),(78,226),(78,174)],'ink')
poly(d,[(85,170),(201,170),(206,175),(206,224),(80,224),(80,175)],'steel')
line(d,[(81,175),(85,171),(200,171)],'light');line(d,[(81,224),(205,224),(205,176)],'dark')
for x in (84,198):
    for y in (178,194,210):rivet(d,x,y)
# Arched fire mouth with a riveted frame.
poly(d,[(104,180),(182,180),(192,190),(192,224),(94,224),(94,190)],'ink')
poly(d,[(105,182),(181,182),(190,191),(190,222),(96,222),(96,191)],'mid')
line(d,[(97,191),(105,183),(180,183)],'light')
for x in range(104,184,13):rivet(d,x,184)
poly(d,[(110,188),(176,188),(184,196),(184,224),(102,224),(102,196)],'ink')
poly(d,[(111,190),(175,190),(182,197),(182,224),(104,224),(104,197)],'ember')
# --- Middle ledge separating tower and firebox ---
rect(d,(76,160,210,170),'ink');rect(d,(77,161,209,168),'mid')
line(d,[(77,161),(209,161)],'light');line(d,[(77,168),(209,168)],'dark')
for x in range(82,208,14):rivet(d,x,164)
# --- Upper tower ---
poly(d,[(92,62),(194,62),(198,66),(198,160),(88,160),(88,66)],'ink')
rect(d,(89,66,197,159),'steel')
# Side columns, darker and riveted.
for x0,x1 in ((89,104),(182,197)):
    rect(d,(x0,66,x1,159),'dark');line(d,[(x0,67),(x0,158)],'mid')
    line(d,[(x1,67),(x1,158)],'ink')
    for y in range(74,156,12):rivet(d,x0+6,y)
# Roof cap.
poly(d,[(96,54),(190,54),(200,62),(200,68),(86,68),(86,62)],'ink')
poly(d,[(97,56),(189,56),(197,62),(197,66),(89,66),(89,62)],'mid')
line(d,[(90,62),(97,57),(188,57)],'shine');line(d,[(89,66),(197,66)],'dark')
# Copper corner straps.
for x0,x1 in ((86,106),(180,200)):
    band(d,(x0,70,x1,76));band(d,(x0,150,x1,156))
# Central riveted plate around the window.
panel(d,(108,72,178,158),'steel')
for x,y in ((112,76),(172,76),(112,152),(172,152),(112,114),(172,114)):rivet(d,x,y)
# Window frame and recessed glass slot.
rect(d,(122,78,164,154),'ink');rect(d,(124,80,162,152),'dark')
line(d,[(124,80),(162,80)],'mid');line(d,[(124,80),(124,152)],'mid')
rect(d,(128,86,158,148),'ink');rect(d,(129,87,157,147),'ember')
band(d,(126,80,160,86));band(d,(126,148,160,154))
# --- Hopper neck, funnel and coal tray ---
panel(d,(110,40,132,58),'steel')
band(d,(108,48,134,53))
poly(d,[(92,18),(150,18),(146,26),(132,40),(110,40),(96,26)],'ink')
poly(d,[(95,20),(147,20),(144,25),(131,38),(111,38),(98,25)],'steel')
poly(d,[(97,21),(118,21),(117,37),(111,37),(99,25)],'light')
line(d,[(131,37),(144,25),(146,21)],'dark')
rect(d,(90,14,152,21),'ink');rect(d,(92,15,150,19),'mid');line(d,[(92,15),(150,15)],'shine')
# --- Chimney ---
panel(d,(160,26,180,56),'steel')
rect(d,(162,28,165,54),'light');rect(d,(176,28,178,54),'dark')
rect(d,(157,20,183,28),'ink');rect(d,(159,21,181,26),'mid');line(d,[(159,21),(181,21)],'shine')
rect(d,(165,22,175,25),'deep')
band(d,(158,42,182,48))
# --- Right side: vertical steam pipe with copper couplings + pause valve ---
rect(d,(200,64,210,170),'ink');rect(d,(202,64,208,170),'steel')
line(d,[(203,64),(203,170)],'light');line(d,[(207,64),(207,170)],'dark')
poly(d,[(194,58),(206,58),(210,62),(210,68),(198,68),(194,64)],'ink')
rect(d,(196,60,207,66),'mid')
for y in (118,140):band(d,(198,y,212,y+6))
poly(d,[(202,86),(214,86),(219,91),(219,105),(214,110),(202,110),(197,105),(197,91)],'ink')
poly(d,[(204,89),(212,89),(216,93),(216,103),(212,107),(204,107),(200,103),(200,93)],'mid')
line(d,[(204,89),(212,89)],'light')
# --- Left input pipes with flanges into square sockets ---
for y in (110,158):
    rect(d,(31,y-5,88,y+5),'ink');rect(d,(31,y-3,88,y+3),'steel')
    line(d,[(31,y-3),(88,y-3)],'light');line(d,[(31,y+3),(88,y+3)],'dark')
    flange(d,40,y,8);flange(d,62,y,8)
    band(d,(78,y-10,88,y+10))
    socket(d,16,y)
# --- Output conduit to right socket ---
rect(d,(206,184,256,196),'ink');rect(d,(206,187,256,193),'mid')
line(d,[(206,187),(256,187)],'light');line(d,[(206,193),(256,193)],'dark')
flange(d,222,190,8);band(d,(246,180,256,200))
socket(d,270,190)
# --- Pour spout and catch mold ---
poly(d,[(190,198),(206,198),(236,214),(236,222),(228,223),(192,208)],'ink')
poly(d,[(193,200),(205,201),(232,216),(230,220),(196,206)],'mid')
line(d,[(193,200),(205,200),(233,215)],'light')
poly(d,[(210,226),(252,226),(257,231),(257,244),(208,244),(205,239),(205,231)],'ink')
rect(d,(209,229,253,242),'steel');line(d,[(209,229),(253,229)],'light')
rect(d,(214,231,248,236),'ember')
for x in (212,250):rivet(d,x,239)

material,d=fresh()
# Coal heaped in the hopper tray.
for x,y,r in ((100,12,4),(108,10,5),(117,9,5),(126,9,5),(135,10,5),(143,12,4),
              (104,15,3),(121,13,4),(131,14,3),(140,15,3)):coal(d,x,y,r)
for x,y,r in ((11,113,5),(21,113,5),(16,105,5)):rock(d,x,y,r)
for x,y,r in ((11,160,4),(19,161,5),(15,154,4)):coal(d,x,y,r)
ingot(d,270,191)

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
    t=f*math.pi/6
    heat,d=fresh()
    # Tall window: deep rim, molten column, white-hot core, rising sparks.
    rect(d,(129,87,157,147),'firedeep')
    rect(d,(131,89,155,147),'fire')
    for j in range(4):
        x=134+j*6;top=96+round(5*math.sin(t+j*1.7))
        poly(d,[(x-2,147),(x-2,top+10),(x+1,top),(x+4,top+10),(x+4,147)],'hot')
    rect(d,(139,104+round(3*math.sin(t)),147,147),'whitehot')
    for k in range(6):
        age=(f+k*2)%12;x=132+(k*5+age)%23;y=146-age*5
        rect(d,(x,y,x+1,y+1),'whitehot' if age<6 else 'hot')
    line(d,[(129,87),(157,87)],'firedeep')
    # Firebox: warm back-glow, then flames in the arch.
    poly(d,[(111,190),(175,190),(182,197),(182,224),(104,224),(104,197)],'firedeep')
    poly(d,[(108,202),(178,202),(181,206),(181,224),(105,224),(105,206)],'rust')
    rect(d,(104,214,182,224),'firedeep')
    tongues=[]
    for j in range(7):
        x=108+j*11;h=16+round(6*math.sin(t+j*2.1))
        poly(d,[(x-5,224),(x-3,224-h//2),(x,224-h),(x+3,224-h//2+2),(x+6,224)],'fire')
        poly(d,[(x-2,224),(x,224-h//2-2),(x+3,224)],'hot')
    for j in range(9):
        x=106+j*9;rect(d,(x,219,x+5,223),'hot' if (j+f)%3 else 'whitehot')
    line(d,[(106,223),(180,223)],'firedeep')
    # Mold glow + travelling molten stream.
    rect(d,(214,231,248,236),'fire');rect(d,(217,232,245,234),'hot')
    line(d,[(221+f%4,232),(232+f%4,232)],'whitehot')
    line(d,[(197,203),(205,204),(231,218),(231,230)],'fire',3)
    line(d,[(198,203),(205,203),(231,217),(231,229)],'hot',1)
    for k in range(2):
        y=218+((f*2+k*6)%12);rect(d,(230,y,231,y+1),'whitehot')
    smoke,d=fresh()
    for k in range(4):
        age=(f+k*3)%12
        x=170+round(age*1.1)+round(2*math.sin(k+age*.4));y=18-age*1.5
        r=2+age//4
        d.ellipse((x-r,y-r,x+r,y+r),fill=(110,138,156,max(20,150-age*11)))
    layers=[('01 | Kule firin kasasi',shell),('02 | Besleme ve portlar',material),
            ('03 | Alev ve metal akisi',heat),('04 | Baca dumani',smoke),('05 | Etiket',plate)]
    frames.append(layers)
    im=Image.new('RGBA',(W,H))
    for _,part in layers:im.alpha_composite(part)
    previews.append(im)
    game=im.copy();gd=ImageDraw.Draw(game)
    rect(gd,(175,259,222,273),'deep')
    for x,y in [(16,110),(16,158),(270,190)]:rect(gd,(x-12,y-12,x+12,y+12),'deep')
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
(ROOT/'ergitme_firini_A_anim_v2.ase').write_bytes(header+b''.join(all_frames))
previews[0].save(ROOT/'ergitme_firini_A_v2.png')
preview_frames=[]
for im in previews:
    bg=Image.new('RGBA',(W,H),'#142331');bg.alpha_composite(im)
    preview_frames.append(bg.resize((W*2,H*2),Image.Resampling.NEAREST).convert('RGB'))
preview_frames[0].save(ROOT/'ergitme_firini_A_anim_v2_onizleme.gif',save_all=True,append_images=preview_frames[1:],duration=100,loop=0,disposal=2)
preview_frames[0].save(ROOT/'ergitme_firini_A_v2_onizleme.png')
atlas=Image.new('RGBA',(W*4,H*3))
for n,im in enumerate(games):atlas.paste(im,(n%4*W,n//4*H))
atlas.save(ROOT/'ergitme_firini_A_game_sheet_v2.png')
print('FURNACE_ART_V2_OK: 288x288, 12 frames, 5 layers')
