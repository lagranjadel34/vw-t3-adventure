import sys
from PIL import Image, ImageOps
f=Image.open('/mnt/project-files/graficos/fichas-ara/dehler-profi-1983.png').convert('RGB')
CX=(2.30-2.13)/2
def ov(render, mirror, pxm_r, anchor_r, pxm_f, anchor_f, crop):
    r=Image.open('ficha/'+render+'.png').convert('RGB')
    if mirror: r=ImageOps.mirror(r); anchor_r=(r.width-anchor_r[0],anchor_r[1])
    s=pxm_f/pxm_r; r=r.resize((int(r.width*s),int(r.height*s)),Image.NEAREST)
    can=Image.new('RGB',f.size,(222,228,230)); can.paste(r,(int(anchor_f[0]-anchor_r[0]*s),int(anchor_f[1]-anchor_r[1]*s)))
    fc=f.crop(crop); cc=can.crop(crop); return fc,cc,Image.blend(fc,cc,0.5)
a=ov('lateral_izq',True,163.64,(480,540),130,(345+CX*130,383),(50,60,670,392))
b=ov('trasera',False,240,(480,624),129,(520,722),(380,425,665,730))
out=Image.new('RGB',(1860,332+305),(255,255,255))
for i,im in enumerate(a): out.paste(im,(i*620,0))
for i,im in enumerate(b): out.paste(im,(i*285,332))
out.save(sys.argv[1])
