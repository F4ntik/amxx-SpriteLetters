from pathlib import Path
import json,math
import numpy as np
from PIL import Image,ImageDraw,ImageFont
from model_layout import layout
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT.parents[1]/'outputs'
MODELS=json.loads((OUT/'mdl-preview-data.json').read_text())

def scene(w,h,explode=False,text=False):
    faces=[]
    for p in layout(w,h):
        cx=p['x']+p['w']/2-w/2;cy=p['y']+p['h']/2-h/2;depth=-2
        if explode:
            if p['zone']==0:cx*=1.025;cy*=1.12;depth-=8
            elif p['zone']==1:cy-=12
            elif p['zone']==2:cy+=12
            elif p['zone']==3:cx-=12
            elif p['zone']==4:cx+=12
            else:cx+=12 if cx>0 else -12;cy+=12 if cy>0 else -12
        for t in MODELS[p['family']]['models'][p['body']]['triangles']:
            color=t['color'];n=t['n'];light=.35+.65*max(0,n[0]*.9+n[1]*.2+n[2]*.35)
            color=tuple(round(min(255,c*light)) for c in color)
            verts=[(cx-v[1],cy+v[2],depth+v[0]) for v in t['v']]
            faces.append((verts,color,(-n[1],n[2],n[0])))
    if text:
        atlas=Image.open(OUT/'glyphs-preview.png').convert('RGBA');mapping=json.loads((OUT/'glyph-map.json').read_text(encoding='utf-8'))
        word='ПРИВЕТ';glyph_scale=.75;step=22
        for j,c in enumerate(word):
            glyph=atlas.crop((mapping[c]*32,0,(mapping[c]+1)*32,32))
            for y in range(32):
                for x in range(32):
                    r,g,b,a=glyph.getpixel((x,y))
                    if a<128:continue
                    xx=-(len(word)-1)*step/2-12+j*step+x*glyph_scale;yy=12-y*glyph_scale
                    faces.append(([(xx,yy,0),(xx+glyph_scale,yy,0),(xx+glyph_scale,yy-glyph_scale,0),(xx,yy-glyph_scale,0)],(r,g,b),(0,0,1)))
    return faces

def draw_scene(im,faces,center,scale,yaw=30,pitch=28):
    y=math.radians(yaw);p=math.radians(pitch)
    def project(v):
        x,z=v[0]*math.cos(y)+v[2]*math.sin(y),-v[0]*math.sin(y)+v[2]*math.cos(y)
        return x,v[1]*math.cos(p)-z*math.sin(p),v[1]*math.sin(p)+z*math.cos(p)
    projected=[([project(v) for v in pts],color) for pts,color,n in faces if project(n)[2]>0]
    pixels=np.array(im);depth=np.full((im.height,im.width),-np.inf)
    for pts,color in projected:
        pts=[(center[0]+v[0]*scale,center[1]-v[1]*scale,v[2]) for v in pts]
        for j in range(1,len(pts)-1):
            a,b,c=pts[0],pts[j],pts[j+1]
            x0=max(0,math.floor(min(a[0],b[0],c[0])));x1=min(im.width,math.ceil(max(a[0],b[0],c[0])))
            y0=max(0,math.floor(min(a[1],b[1],c[1])));y1=min(im.height,math.ceil(max(a[1],b[1],c[1])))
            den=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
            if abs(den)<1e-8 or x0>=x1 or y0>=y1:continue
            yy,xx=np.mgrid[y0:y1,x0:x1];xx=xx+.5;yy=yy+.5
            u=((b[1]-c[1])*(xx-c[0])+(c[0]-b[0])*(yy-c[1]))/den
            v=((c[1]-a[1])*(xx-c[0])+(a[0]-c[0])*(yy-c[1]))/den
            w=1-u-v;z=u*a[2]+v*b[2]+w*c[2]
            target=depth[y0:y1,x0:x1];mask=(u>=-1e-8)&(v>=-1e-8)&(w>=-1e-8)&(z>target)
            target[mask]=z[mask];pixels[y0:y1,x0:x1][mask]=color
    im.paste(Image.fromarray(pixels))

def main():
    im=Image.new('RGB',(1440,980),'#f1f3f5');d=ImageDraw.Draw(im)
    def font(s,b=False):return ImageFont.truetype('C:/Windows/Fonts/'+('arialbd.ttf' if b else 'arial.ttf'),s)
    def text(x,y,s,size=24,b=False,fill='#27323d'):d.text((x,y),s,font=font(size,b),fill=fill)
    text(50,32,'Объёмный вариант из настоящих MDL',38,True)
    text(50,91,'Прочитана геометрия скомпилированных моделей • условное освещение',21,fill='#697782')
    d.rounded_rectangle((40,142,1400,494),16,fill='white')
    text(65,162,'СОБРАНО',18,True,fill='#697782')
    draw_scene(im,scene(256,64,text=True),(705,325),3.5,yaw=25,pitch=15)
    text(50,527,'Раздвинутые детали',28,True)
    text(50,572,'Фон + четыре планки + четыре угла. Планки набираются секциями.',22)
    draw_scene(im,scene(256,64,explode=True),(530,754),2.4,yaw=26,pitch=13)
    text(1085,632,'Угол крупно',22,True)
    corner=MODELS['panel_corners']['models'][2]
    faces=[]
    for t in corner['triangles']:
        n=t['n'];light=.35+.65*max(0,n[0]*.9+n[1]*.2+n[2]*.35)
        faces.append(([(-v[1],v[2],v[0]) for v in t['v']],tuple(round(c*light) for c in t['color']),(-n[1],n[2],n[0])))
    draw_scene(im,faces,(1180,770),36,yaw=32,pitch=23)
    text(50,913,'Вся рамка имеет реальную толщину 3 игровых единицы. Её части не растягиваются.',21,fill='#697782')
    text(50,944,'Это просмотр геометрии файлов, а не скриншот из CS 1.6.',20,fill='#697782')
    im.save(OUT/'mdl-frame-parts.png')
    print(OUT/'mdl-frame-parts.png')
if __name__=='__main__':main()
