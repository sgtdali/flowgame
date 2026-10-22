"""Flowgame A tower furnace v3: built from the reference image (ergitme_firini_referans.png).

The reference is pixelized so the two input sockets sit exactly 48px apart, then cut apart
and re-placed on the 288x288 game frame so the anchors stay where smelter_card.gd expects
them: sockets (16,110) (16,158) (270,190), status dot (86,265), rate label x176-223,
pause button x201-216 y88-106.
Layers: body, materials, window glow, firebox fire, molten metal, smoke, label.
Run with --oyuna to also write the game sheet to app/art/smelter_a/smelter_sheet.png.
"""
from pathlib import Path
from collections import deque
import math
import struct as S
import sys
import zlib
import numpy as np
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parent
HELPERS=ROOT.parent/'demir_madeni_B'/'draw_mine_node_b.py'
src=(HELPERS).read_text(encoding='utf-8')
env={'__file__':str(HELPERS)}
exec(compile(src[:src.index('# Structural shell:')],'pixel_helpers','exec'),env)
P=env['P'];poly,circle,line,rect,text=[env[k] for k in ('poly','circle','line','rect','text')]
env['FONT'].update({'G':['01111','10000','10000','10111','10001','10001','01110'],
 'T':['11111','00100','00100','00100','00100','00100','00100'],
 '4':['00010','00110','01010','10010','11111','00010','00010']})
W=H=288
SCALE=48/90                     # source socket spacing is 90px
K=SCALE/0.5                     # layout numbers below were measured on the 0.5-scale version
def k(v):return int(round(v*K))
def kb(b):return tuple(k(v) for v in b)

def pixelize(path,scale):
    a=np.asarray(Image.open(path).convert('RGB'))[8:348,20:352].astype(int)
    h,w,_=a.shape
    def bgish(p):
        r,g,b=p
        return b>=r and b>=g-4 and r<72 and g<88 and b<112 and b-r>14
    mask=np.zeros((h,w),bool)
    q=deque([(y,x) for x in range(w) for y in (0,h-1)]+[(y,x) for y in range(h) for x in (0,w-1)])
    while q:
        y,x=q.popleft()
        if mask[y,x] or not bgish(a[y,x]):continue
        mask[y,x]=True
        q.extend((y+dy,x+dx) for dy,dx in ((1,0),(-1,0),(0,1),(0,-1)) if 0<=y+dy<h and 0<=x+dx<w)
    H2,W2=round(h*scale),round(w*scale);res=np.zeros((H2,W2,4),np.uint8)
    for by in range(H2):
        y0=int(by/scale);y1=max(y0+1,int((by+1)/scale))
        for bx in range(W2):
            x0=int(bx/scale);x1=max(x0+1,int((bx+1)/scale))
            m=mask[y0:y1,x0:x1]
            if m.mean()>0.5:continue
            res[by,bx,:3]=np.median(a[y0:y1,x0:x1][~m],axis=0);res[by,bx,3]=255
    small=Image.fromarray(res,'RGBA')
    qz=small.convert('RGB').quantize(32,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE).convert('RGB')
    out=Image.new('RGBA',small.size);out.paste(qz,(0,0),small.split()[3])
    return np.asarray(out).copy()

REF=pixelize(ROOT/'ergitme_firini_referans.png',SCALE)
DX,DY=52,110-k(69)              # body offset: left pipe stubs land on y=110/158
SOCKET_FILL=(15,30,46,255)
INK=(7,10,15,255)
PIPE=[(11,16,24),(84,99,122),(130,144,164),(76,93,116),(76,93,116),(42,56,74),(29,42,60),(16,25,37),(0,0,1)]

def blank():return np.zeros((H,W,4),np.uint8)

def paste(dst,srcarr,box,at):
    """Copy non-transparent pixels of srcarr[box] to dst with top-left at `at`."""
    x0,y0,x1,y1=box;ax,ay=at
    part=srcarr[y0:y1,x0:x1]
    region=dst[ay:ay+y1-y0,ax:ax+x1-x0]
    m=part[...,3]>0;region[m]=part[m]

ref=REF.copy()
ref[0:k(25),k(84):k(113)]=0     # smoke baked into the reference; redrawn as its own layer
SOCKETS=[kb((3,56,29,84)),kb((3,101,29,129)),kb((133,85,164,113))]
INNER=[kb((6,59,26,81)),kb((6,104,26,126)),kb((141,89,161,110))]
CENTERS=[(k(16),k(69)),(k(16),k(114)),(k(151),k(99))]
TARGETS=[(16,110),(16,158),(270,190)]
# Socket icons go to the material layer; sockets keep a flat inner fill.
icons=np.zeros_like(ref)
for x0,y0,x1,y1 in INNER:
    icons[y0:y1,x0:x1]=ref[y0:y1,x0:x1]
    ref[y0:y1,x0:x1]=SOCKET_FILL
    flat=np.abs(icons[y0:y1,x0:x1,:3].astype(int)-SOCKET_FILL[:3]).sum(axis=2)<24
    icons[y0:y1,x0:x1][flat]=0

# Hot areas: (name, box, min red-blue gap).
HOT=[('window',kb((72,60,87,103)),50),('fire',kb((58,126,96,151)),50),('metal',kb((104,124,148,160)),60)]
def lum(c):return .3*c[...,0]+.59*c[...,1]+.11*c[...,2]
masks={}
for name,(x0,y0,x1,y1),gap in HOT:
    c=ref[y0:y1,x0:x1].astype(int)
    m=(c[...,3]>0)&(c[...,0]>110)&(c[...,0]-c[...,2]>gap)
    full=np.zeros(ref.shape[:2],bool);full[y0:y1,x0:x1]=m;masks[name]=full
hot_px=np.concatenate([ref[m][:,:3] for m in masks.values()]).astype(int)
order=np.argsort(lum(hot_px))
RAMP=[(92,36,30),(140,58,36)]+[tuple(int(v) for v in hot_px[order[int(q*(len(order)-1))]]) for q in np.linspace(0,1,9)]+[(255,240,200)]
RL=lum(np.array(RAMP,float))
IDX0=np.abs(lum(ref.astype(float))[...,None]-RL).argmin(axis=2)   # each pixel's own ramp step
for m in masks.values():ref[m]=(*RAMP[1],255)   # body keeps a cold ember under the heat layers

def ramp(i):
    return (*RAMP[int(np.clip(round(i),1,len(RAMP)-1))],255)

body=blank()
# Left sockets stay at x=16; their pipes are stretched to meet the shifted body.
for (x0,y0,x1,y1),(cx,cy),(tx,ty) in zip(SOCKETS[:2],CENTERS[:2],TARGETS[:2]):
    paste(body,ref,(x0,y0,x1,y1),(x0+tx-cx,y0+ty-cy))
for y0,y1 in (kb((61,79)),kb((106,124))):
    col=ref[y0:y1,k(35)]
    for x in range(k(29),k(35)+DX):
        seg=body[y0+DY:y1+DY,x];m=col[...,3]>0;seg[m]=col[m]
paste(body,ref,(k(35),0,k(133),ref.shape[0]),(k(35)+DX,DY))  # main furnace
# Output: elbow pipe from the stub down to y=190, then the socket at x=270.
bd=Image.fromarray(body);d=ImageDraw.Draw(bd)
def hpipe(x0,x1,cy):
    for i,c in enumerate(PIPE):d.line([(x0,cy-4+i),(x1,cy-4+i)],fill=c)
def vpipe(cx,y0,y1):
    for i,c in enumerate(PIPE):d.line([(cx-4+i,y0),(cx-4+i,y1)],fill=c)
def coupling(x0,y0,x1,y1):
    d.rectangle((x0,y0,x1,y1),fill=INK);d.rectangle((x0+1,y0+1,x1-1,y1-1),fill=(185,101,55))
    d.line([(x0+1,y0+1),(x1-1,y0+1)],fill=(230,155,83));d.line([(x0+1,y1-1),(x1-1,y1-1)],fill=(105,61,48))
sx,sy=CENTERS[2];stub=k(133)+DX;cy0=sy+DY;ox,oy=TARGETS[2][0]-sx,TARGETS[2][1]-sy
VX=236
hpipe(stub-1,VX,cy0);vpipe(VX,cy0-4,194);hpipe(VX,SOCKETS[2][0]+ox,190)
coupling(VX-6,cy0-7,VX+6,cy0+7);coupling(VX-6,183,VX+6,197)
# Pause-valve plate on the output pipe, under the game's pause button.
d.rectangle((206,106,210,cy0-4),fill=INK);d.line([(208,107),(208,cy0-5)],fill=PIPE[2])
poly(d,[(202,86),(214,86),(219,91),(219,105),(214,110),(202,110),(197,105),(197,91)],INK)
poly(d,[(204,89),(212,89),(216,93),(216,103),(212,107),(204,107),(200,103),(200,93)],PIPE[3])
d.line([(204,89),(212,89)],fill=PIPE[2])
body=np.asarray(bd).copy()
paste(body,ref,SOCKETS[2],(SOCKETS[2][0]+ox,SOCKETS[2][1]+oy))
# Ground shadow under the feet.
foot=DY+ref.shape[0]
shadow=Image.new('RGBA',(W,H));ImageDraw.Draw(shadow).ellipse((DX+k(30),foot-10,DX+k(150),foot+4),fill=(5,10,18,110))
shadow.alpha_composite(Image.fromarray(body));body=np.asarray(shadow).copy()

material=blank()
for (x0,y0,x1,y1),(cx,cy),(tx,ty) in zip(SOCKETS,CENTERS,TARGETS):
    paste(material,icons,(x0,y0,x1,y1),(x0+tx-cx,y0+ty-cy))

plate_im=Image.new('RGBA',(W,H));d=ImageDraw.Draw(plate_im)
poly(d,[(78,249),(223,249),(231,257),(231,276),(224,283),(78,283),(70,276),(70,257)],'ink')
poly(d,[(80,252),(221,252),(227,258),(227,274),(221,279),(80,279),(74,273),(74,259)],'steel')
rect(d,(78,256,223,275),'deep');line(d,[(79,256),(221,256)],'mid')
circle(d,86,266,5,'ink');circle(d,86,265,3,'mint')
text(d,98,262,'ERGITME');line(d,[(145,260),(145,272)],'steel')
poly(d,[(152,266),(157,260),(168,260),(165,268),(155,271)],'mid','ink')
poly(d,[(152,266),(157,260),(168,260),(163,266)],'light');line(d,[(157,260),(167,260)],'shine')
text(d,177,262,'40/DK')

def heat_layer(name,wave):
    out=blank();ys,xs=np.nonzero(masks[name])
    for y,x in zip(ys,xs):out[y+DY,x+DX]=ramp(IDX0[y,x]+wave(x,y))
    return out

def spark(layer,name,x,y,c):
    if 0<=y<ref.shape[0] and 0<=x<ref.shape[1] and masks[name][y,x]:layer[y+DY,x+DX]=(*c,255)

SMOKE=[(76,93,116),(97,114,135),(119,128,142)]
wx0,wy0,wx1,wy1=HOT[0][1];fx0,fy0,fx1,fy1=HOT[1][1]
CHIM=(DX+k(92),DY+k(24))
frames=[];previews=[];games=[]
for f in range(12):
    ph=f/12*2*math.pi
    # Window: heat bands rising, sparks climbing the column.
    win=heat_layer('window',lambda x,y:1+1.6*math.sin(y*2*math.pi/14+ph)+.5*math.sin(x*1.3+ph*2))
    for n in range(6):
        age=(f+n*2)%12;spark(win,'window',wx0+2+(n*5+age//3)%(wx1-wx0-4),wy1-2-age*(wy1-wy0)//13,RAMP[-1])
    # Firebox: tongues flicker per column, strongest at the top edge of the flame.
    fire=heat_layer('fire',lambda x,y:1+2.2*math.sin(x*.9+ph*2)*(1-(y-fy0)/(fy1-fy0))+.5*math.sin(ph+y))
    for n in range(5):
        age=(f*2+n*3)%12;spark(fire,'fire',fx0+6+n*7+age%3,fy1-3-age,RAMP[-2])
    # Molten metal: bright pulses travel down the chute into the mold.
    metal=heat_layer('metal',lambda x,y:1.8*math.sin((x+y)*2*math.pi/11-ph))
    smoke_im=Image.new('RGBA',(W,H));sd=ImageDraw.Draw(smoke_im)
    for n in range(4):
        age=(f+n*3)%12
        x=CHIM[0]+round(age*1.3+2*math.sin(n*1.7+age*.5));y=CHIM[1]-2-age*4
        r=2+age//3;c=SMOKE[min(2,age//4)]
        sd.ellipse((x-r,y-r,x+r,y+r),fill=(*c,max(40,230-age*16)))
    layers=[('01 | Govde',body),('02 | Malzemeler',material),('03 | Pencere isigi',win),
            ('04 | Ocak atesi',fire),('05 | Eriyik metal',metal),
            ('06 | Baca dumani',smoke_im),('07 | Etiket',plate_im)]
    layers=[(n,Image.fromarray(a,'RGBA') if isinstance(a,np.ndarray) else a) for n,a in layers]
    frames.append(layers)
    im=Image.new('RGBA',(W,H))
    for _,part in layers:im.alpha_composite(part)
    previews.append(im)
    game=Image.new('RGBA',(W,H))
    for n,part in layers:
        if not n.startswith('02'):game.alpha_composite(part)
    gd=ImageDraw.Draw(game);rect(gd,(175,259,222,273),'deep')
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
    body_b=b''.join(chunks)
    all_frames.append(S.pack('<IHHH',len(body_b)+16,0xf1fa,len(chunks),100)+b'\0'*2+S.pack('<I',0)+body_b)
header=bytearray(128)
S.pack_into('<IHHHHHIH',header,0,128+sum(map(len,all_frames)),0xa5e0,12,W,H,32,1,100)
S.pack_into('<H',header,32,256);header[34]=header[35]=1
(ROOT/'ergitme_firini_A_anim_v3.ase').write_bytes(header+b''.join(all_frames))
previews[0].save(ROOT/'ergitme_firini_A_v3.png')
pf=[]
for im in previews:
    bg=Image.new('RGBA',(W,H),'#142331');bg.alpha_composite(im)
    pf.append(bg.resize((W*2,H*2),Image.Resampling.NEAREST).convert('RGB'))
pf[0].save(ROOT/'ergitme_firini_A_anim_v3_onizleme.gif',save_all=True,append_images=pf[1:],duration=100,loop=0,disposal=2)
pf[0].save(ROOT/'ergitme_firini_A_v3_onizleme.png')
sheet=Image.new('RGB',(W*4,H*3))
for n,im in enumerate(pf):sheet.paste(im.resize((W,H),Image.Resampling.NEAREST),(n%4*W,n//4*H))
sheet.save(ROOT/'ergitme_firini_A_v3_kareler.png')
atlas=Image.new('RGBA',(W*4,H*3))
for n,im in enumerate(games):atlas.paste(im,(n%4*W,n//4*H))
atlas.save(ROOT/'ergitme_firini_A_game_sheet_v3.png')
# --oyuna: the game reads this sheet directly (flowgame/app/art/smelter_a).
if '--oyuna' in sys.argv:
    GAME_SHEET=ROOT.parent.parent/'app'/'art'/'smelter_a'/'smelter_sheet.png'
    atlas.save(GAME_SHEET);print('oyuna yazildi:',GAME_SHEET)
print('FURNACE_ART_V3_OK: 288x288, 12 frames, 7 layers, ref',REF.shape[1],'x',REF.shape[0])
