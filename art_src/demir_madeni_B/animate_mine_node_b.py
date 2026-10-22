"""Twelve-frame, layered working cycle for the hand-drawn mining node."""
from pathlib import Path
import math
import struct as S
import zlib
from PIL import Image, ImageDraw, ImageColor

ROOT=Path(__file__).resolve().parent
source=(ROOT/'draw_mine_node_b.py').read_text(encoding='utf-8')
env={'__file__':str(ROOT/'draw_mine_node_b.py')}
exec(compile(source.split('# Editable native document:')[0], 'node_art', 'exec'),env)
base_layers=env['layers']
W,H=env['W'],env['H']
P=env['P']
poly,circle,line,rect,rock=[env[n] for n in ('poly','circle','line','rect','rock')]

# Rebuild the ore layer without its three stationary conveyor nuggets.
ore_code=source[source.index("d=layer('04 |"):source.index("d=layer('05 |")]
ore_code=ore_code.replace('rock(d,112,175,6);rock(d,147,176,5);rock(d,195,175,7)','')
env['layers']=[]
exec(compile(ore_code,'ore_base','exec'),env)
ore_base=env['layers'][0][1]

frames=[]
previews=[]
N=12
for f in range(N):
    phase=f/N
    layers=[(name,im.copy()) for name,im in base_layers]
    mechanism=layers[1][1]
    d=ImageDraw.Draw(mechanism)
    # Clear only the drill bit and draw a rotating helix inside its silhouette.
    rect(d,(65,114,90,154),(0,0,0,0))
    for y in range(114,153):
        half=11 if y<136 else max(0,round((153-y)*11/17))
        for x in range(77-half,78+half):
            xx=(x-77)/max(half,1)
            t=(y+round(phase*14)+round((x-77)*0.38))%7
            color='ink' if abs(x-77)==half else ('light' if t<2 else ('steel' if t<5 else 'dark'))
            if xx>0.5 and color=='light':color='mid'
            mechanism.putpixel((x,y),(*ImageColor.getrgb(P[color]),255))
    # Gear has twelve identical teeth: a 30-degree advance closes the loop.
    gear=Image.new('RGBA',(W,H));d=ImageDraw.Draw(gear)
    pts=[]
    for i in range(12):
        for q,r in [(0,24),(0.16,29),(0.62,29),(0.78,24)]:
            a=(i+q)*math.pi/6+phase*math.pi/6
            pts.append((round(163+r*math.cos(a)),round(91+r*math.sin(a))))
    poly(d,pts,'orange','ink',2)
    # Sparse fixed-direction surface highlights.
    for x,y in pts:
        if x<159 and y<86:line(d,[(x+1,y+1),(x+2,y+1)],'amber')
    circle(d,163,91,20,'rust','ink',2)
    circle(d,163,91,17,'steel','amber')
    circle(d,163,91,13,'light','ink',2)
    circle(d,163,91,9,'mid','dark')
    circle(d,163,91,5,'dark','ink')
    line(d,[(159,86),(164,84),(168,87)],'shine')
    rect(d,(160,90,166,92),'ink')
    layers[2]=(layers[2][0],gear)
    ore=ore_base.copy();d=ImageDraw.Draw(ore)
    for k in range(2):
        x=100+round((k*52+phase*52)%104)
        rock(d,x,175,5)
    # Rollers turn in place, never shifting the conveyor or casing.
    a=phase*math.pi*2
    for x in range(51,204,15):
        circle(d,x,185,5,'ink');circle(d,x,184,3,'orange')
        xx=x+round(2*math.cos(a));yy=184+round(2*math.sin(a))
        rect(d,(xx,yy,xx+1,yy),'amber')
    layers[3]=(layers[3][0],ore)
    dust=Image.new('RGBA',(W,H));d=ImageDraw.Draw(dust)
    for k in range(6):
        age=(f+k*2)%12
        x=77+round((k%3-1)*(3+age*.6))
        y=149+age
        if age<9:
            c='light' if age<3 else 'dust'
            rect(d,(x,y,x+(1 if age<5 else 0),y+(1 if age<5 else 0)),c)
    layers.insert(4,('05 | Kirilan cevher parcaciklari',dust))
    frames.append(layers)
    preview=Image.new('RGBA',(W,H),'#142331')
    for _,im in layers:preview.alpha_composite(im)
    previews.append(preview.resize((W*2,H*2),Image.Resampling.NEAREST).convert('RGB'))

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
S.pack_into('<IHHHHHIH',header,0,128+sum(map(len,all_frames)),0xa5e0,N,W,H,32,1,100)
S.pack_into('<H',header,32,256);header[34]=1;header[35]=1
path=ROOT/'demir_madeni_node_B_anim_v1.ase'
path.write_bytes(header+b''.join(all_frames))
previews[0].save(ROOT/'demir_madeni_node_B_anim_v1_onizleme.gif',save_all=True,append_images=previews[1:],duration=100,loop=0,disposal=2)
print(path)
print('Frames:',N,'Layers:',len(frames[0]),'Loop: 1200 ms')
