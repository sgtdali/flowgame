"""Coal crusher: split a pixelized sprite into layers and animate 12 frames.

Usage: python animate_komur_makinesi.py [source.png] [output-prefix]
  defaults: komur_makinesi_16renk.png komur_makinesi_16renk_anim

Layers: body, drum (cylinder-mapped tooth scroll), coal (pile bounce + falling crumbs),
wheel (rotating hub), light (blinking). The whole machine jitters 1px while working.
Coordinates are on the 190x171 hand-cleaned sprite.
"""
from pathlib import Path
import math
import struct as S
import sys
import zlib
import numpy as np
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parent
SRC_NAME=sys.argv[1] if len(sys.argv)>1 else 'komur_makinesi_16renk.png'
OUT=sys.argv[2] if len(sys.argv)>2 else 'komur_makinesi_16renk_anim'
SRC=np.asarray(Image.open(ROOT/SRC_NAME).convert('RGBA')).astype(int)
SH,SW=SRC.shape[:2]
PAD_X,PAD_Y=2,4                 # room for the jitter and falling crumbs
W,H=SW+2*PAD_X,SH+PAD_Y+2
opaque=SRC[...,3]>0
PALETTE=np.unique(SRC[opaque][:,:3],axis=0)

def snap(rgb):
    return tuple(int(v) for v in PALETTE[np.abs(PALETTE-np.array(rgb)).sum(axis=1).argmin()])

CAVITY=(*snap((12,20,31)),255)

def is_orange(c):return (c[...,0]>90)&(c[...,0]-c[...,2]>45)
def lum(c):return .3*c[...,0]+.59*c[...,1]+.11*c[...,2]
yy,xx=np.mgrid[0:SH,0:SW]

def box(x0,y0,x1,y1):return (xx>=x0)&(xx<x1)&(yy>=y0)&(yy<y1)

# --- Drum: the steel between the curved copper rings rotates; the rings stay put. ---
DYC,DR=72,28                    # drum centre row and radius
TEX_Y0,PERIOD=65,29             # one tooth + gap, taken from the front-facing middle row
DX0,DX1,DY0,DY1=44,121,38,105
orange=is_orange(SRC)
# Only big connected copper shapes are rings; stray orange specks on the drum would
# otherwise stay frozen while the teeth scroll past them.
from scipy import ndimage
_lab,_n=ndimage.label(orange&box(DX0,DY0,DX1,DY1))
for _i in range(1,_n+1):
    if (_lab==_i).sum()<12:orange[_lab==_i]=False

def segment_runs(y):
    """Non-copper runs on row y that sit between two rings, in left-to-right order."""
    runs=[];x=DX0;seen_ring=False
    while x<DX1:
        if orange[y,x]:
            seen_ring=True;x+=1;continue
        start=x
        while x<DX1 and not orange[y,x]:x+=1
        if seen_ring and x<DX1:runs.append((start,x))
    return runs

RUNS={y:segment_runs(y) for y in range(DY0,DY1)}
drum_mask=np.zeros((SH,SW),bool)
for y,runs in RUNS.items():
    for a,b in runs[:3]:drum_mask[y,a:b]=True
# Tooth tips poking past the rings would stay frozen; clear them.
tips=box(DX0,DY0,DX1,DY1)&opaque&~orange&~drum_mask&(np.abs(yy-DYC)>DR-3)
# --- Coal: dark, low-saturation lumps left of the drum and in front of it. ---
coal_mask=((box(0,33,44,148)|box(40,104,128,127))&opaque&~is_orange(SRC)&(lum(SRC)<115))
# --- Wheel hub inside the copper ring. ---
WX,WY,WR=171,120,9
wheel_mask=((xx-WX)**2+(yy-WY)**2<=WR*WR)&opaque
LX,LY=50,156                    # status light

body=SRC.copy()
body[drum_mask|tips]=CAVITY
body[coal_mask&box(40,104,128,127)]=CAVITY     # front pile sits in the machine's mouth
body[coal_mask&~box(40,104,128,127)]=0         # left pile hangs outside the frame
body[wheel_mask]=(*snap((10,15,25)),255)
coal=np.where(coal_mask[...,None],SRC,0)
hub=np.where(wheel_mask[...,None],SRC,0).astype(np.uint8)
hub_img=Image.fromarray(hub[WY-WR:WY+WR+1,WX-WR:WX+WR+1],'RGBA')

def drum_frame(f):
    out=np.zeros_like(SRC)
    shift=f*PERIOD/12
    for y,runs in RUNS.items():
        s=(y-DYC)/DR
        if abs(s)>=1:continue                      # beyond the cylinder: show the cavity
        th=math.asin(s)
        v=TEX_Y0+int((DR*th+7.5-shift)%PERIOD)
        k=.55+.45*math.cos(th)
        for seg,(a,b) in enumerate(runs[:3]):
            if seg>=len(RUNS[v]):continue
            ta,tb=RUNS[v][seg]
            for x in range(a,b):
                t=(x-a)/max(1,b-a-1)
                sx=ta+round(t*(tb-ta-1))
                # Copper edge pixels can leak into the runs; borrow steel from a nearby row.
                for dv in (0,1,-1,2,-2,3,-3):
                    c=SRC[TEX_Y0+(v-TEX_Y0+dv)%PERIOD,sx]
                    if c[3] and c[0]-c[2]<=30:break
                out[y,x]=(*snap(c[:3]*k),255)
    return out

COAL_C=[snap(c) for c in ((5,10,18),(22,28,41),(48,57,77),(92,110,135))]
def crumb(d,x,y,size):
    d.rectangle((x,y,x+size,y+size),fill=COAL_C[0])
    if size>=1:d.rectangle((x,y,x+size-1,y+size-1),fill=COAL_C[2])
    d.point((x,y),fill=COAL_C[3])

def coal_frame(f):
    im=Image.new('RGBA',(SW,SH))
    front=np.where(box(40,104,128,127)[...,None],coal,0).astype(np.uint8)
    left=np.where(~box(40,104,128,127)[...,None],coal,0).astype(np.uint8)
    im.alpha_composite(Image.fromarray(left,'RGBA'))
    # The front pile is being chewed: it bobs 1px in a 4-frame rhythm.
    im.alpha_composite(Image.fromarray(front,'RGBA'),(0,-1 if f%4 in (1,2) else 0))
    d=ImageDraw.Draw(im)
    # Lumps slide off the left pile into the drum.
    for n in range(3):
        t=((f+n*4)%12)/12
        x=round(30+t*18);y=round(48+n*16+t*6)
        crumb(d,x,y,2 if n!=1 else 1)
    # Crushed bits drop out under the drum.
    for n in range(4):
        t=((f*2+n*3)%12)/12
        x=58+n*15+(n%2);y=round(101+t*22)
        if t<.9:crumb(d,x,y,1)
    return np.asarray(im).astype(int)

def wheel_frame(f):
    angle=-(f//3)*22.5                       # 4 poses, 3 frames each = one 90 deg turn
    rot=hub_img.rotate(angle,resample=Image.Resampling.NEAREST)
    out=np.zeros_like(SRC)
    a=np.asarray(rot).astype(int)
    region=out[WY-WR:WY+WR+1,WX-WR:WX+WR+1]
    m=(a[...,3]>0)&wheel_mask[WY-WR:WY+WR+1,WX-WR:WX+WR+1]
    region[m]=a[m]
    return out

def light_frame(f):
    im=Image.new('RGBA',(SW,SH));d=ImageDraw.Draw(im)
    on=f%6<3
    d.ellipse((LX-3,LY-3,LX+3,LY+3),fill=snap((15,40,36)))
    d.ellipse((LX-2,LY-2,LX+2,LY+2),fill=(112,214,178) if on else (39,117,100))
    if on:d.point((LX-1,LY-1),fill=snap((210,250,232)))
    return np.asarray(im).astype(int)

def place(arr,dy):
    out=np.zeros((H,W,4),np.uint8)
    out[PAD_Y+dy:PAD_Y+dy+SH,PAD_X:PAD_X+SW]=arr
    return Image.fromarray(out,'RGBA')

frames=[];previews=[]
for f in range(12):
    dy=-1 if f%2 else 0
    layers=[('01 | Govde',body),('02 | Merdane',drum_frame(f)),('03 | Komur',coal_frame(f)),
            ('04 | Cark',wheel_frame(f)),('05 | Isik',light_frame(f))]
    layers=[(n,place(a.astype(np.uint8),dy)) for n,a in layers]
    frames.append(layers)
    im=Image.new('RGBA',(W,H))
    for _,part in layers:im.alpha_composite(part)
    previews.append(im)

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
(ROOT/f'{OUT}.ase').write_bytes(header+b''.join(all_frames))
pf=[]
for im in previews:
    bg=Image.new('RGBA',(W,H),'#142331');bg.alpha_composite(im)
    pf.append(bg.resize((W*3,H*3),Image.Resampling.NEAREST).convert('RGB'))
pf[0].save(ROOT/f'{OUT}_onizleme.gif',save_all=True,append_images=pf[1:],duration=100,loop=0,disposal=2)
sheet=Image.new('RGB',(W*3*4,H*3*3))
for n,im in enumerate(pf):sheet.paste(im,(n%4*W*3,n//4*H*3))
sheet.resize((sheet.width//2,sheet.height//2),Image.Resampling.NEAREST).save(ROOT/f'{OUT}_kareler.png')
strip=Image.new('RGBA',(W*4,H*3))
for n,im in enumerate(previews):strip.paste(im,(n%4*W,n//4*H))
strip.save(ROOT/f'{OUT}_sheet.png')
print(f'KOMUR_OK: {OUT} {W}x{H}, 12 frames, 5 layers')
