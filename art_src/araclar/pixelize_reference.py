"""Turn the AI 'pixel-style' reference into real pixel art: crop, drop background, downsample, quantize."""
import sys
from collections import deque
import numpy as np
from PIL import Image

src,out,scale,ncol=sys.argv[1],sys.argv[2],int(sys.argv[3]),int(sys.argv[4])
im=Image.open(src).convert('RGB')
crop=im.crop((20,8,352,348))  # big furnace + sockets + mold
a=np.asarray(crop).astype(int)
h,w,_=a.shape

# Background = blueprint navy + its grid lines; flood from borders through bg-like colors.
bg=a[2,2]
def bgish(p):
    r,g,b=p
    return b>=r and b>=g-4 and r<72 and g<88 and b<112 and (b-r)>14
mask=np.zeros((h,w),bool);q=deque()
for x in range(w):
    for y in (0,h-1):q.append((y,x))
for y in range(h):
    for x in (0,w-1):q.append((y,x))
while q:
    y,x=q.popleft()
    if mask[y,x] or not bgish(a[y,x]):continue
    mask[y,x]=True
    for dy,dx in ((1,0),(-1,0),(0,1),(0,-1)):
        ny,nx=y+dy,x+dx
        if 0<=ny<h and 0<=nx<w and not mask[ny,nx]:q.append((ny,nx))

# Downsample: per block, median colour of foreground pixels; transparent if mostly bg.
H2,W2=h//scale,w//scale
res=np.zeros((H2,W2,4),np.uint8)
for by in range(H2):
    for bx in range(W2):
        blk=a[by*scale:(by+1)*scale,bx*scale:(bx+1)*scale].reshape(-1,3)
        m=mask[by*scale:(by+1)*scale,bx*scale:(bx+1)*scale].reshape(-1)
        if m.mean()>0.5:continue
        fg=blk[~m]
        res[by,bx,:3]=np.median(fg,axis=0);res[by,bx,3]=255
small=Image.fromarray(res,'RGBA')
rgb=small.convert('RGB').quantize(ncol,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE).convert('RGB')
final=Image.new('RGBA',small.size);final.paste(rgb,(0,0),small.split()[3])
final.save(out)
prev=Image.new('RGBA',small.size,'#142331');prev.alpha_composite(final)
prev.resize((small.width*4,small.height*4),Image.Resampling.NEAREST).save(out.replace('.png','_x4.png'))
print(small.size,'colors',len(final.getcolors(4096)))
