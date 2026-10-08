from pathlib import Path
import struct, json
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT.parents[1]/'outputs'
def sprite(path):
    b=path.read_bytes(); magic,ver,kind,tex,radius,w,h,n,beam,sync=struct.unpack_from('<4siiifiiifi',b)
    assert magic==b'IDSP' and ver==2
    nc=struct.unpack_from('<H',b,40)[0]; pal=b[42:42+nc*3]; p=42+nc*3; frames=[]
    for _ in range(n):
        group,x,y,w,h=struct.unpack_from('<iiiii',b,p);p+=20;assert group==0
        im=Image.new('RGBA',(w,h)); pixels=[]
        for v in b[p:p+w*h]:
            color=tuple(pal[v*3:v*3+3]);pixels.append((*color,0 if tex==3 and v==255 else 255))
        im.putdata(pixels);frames.append(im);p+=w*h
    assert p==len(b)
    return frames

def parts(w,h):
    result=[]
    def rect(x,y,rw,rh,zone):
        xx=x
        for wx in range(9,0,-1):
            if not rw&(1<<wx):continue
            yy=y
            for hy in range(7,0,-1):
                if not rh&(1<<hy):continue
                result.append(dict(x=xx,y=yy,w=1<<wx,h=1<<hy,frame=(wx-1)*7+hy-1,zone=zone));yy+=1<<hy
            xx+=1<<wx
    rect(2,2,w-4,h-4,'фон');rect(0,0,w,2,'низ');rect(0,h-2,w,2,'верх');rect(0,2,2,h-4,'лево');rect(w-2,2,2,h-4,'право')
    return result

def main():
    frames=sprite(ROOT/'assets/sprites/SprLett/panel.spr'); glyphs=sprite(ROOT/'assets/sprites/SprLett/Charsets/Default/chars.spr')
    mapping={a:int(b)-1 for a,b in (line.rsplit(' ',1) for line in (ROOT/'assets/sprites/SprLett/Charsets/Default/map.txt').read_text(encoding='utf-8').splitlines())}
    sign=Image.new('RGBA',(256,64)); ps=parts(256,64)
    for p in ps:
        im=frames[p['frame']].copy();im.paste((20,24,32,255) if p['zone']=='фон' else (155,165,175,255),(0,0,im.width,im.height));sign.alpha_composite(im,(p['x'],64-p['y']-p['h']))
    for i,c in enumerate('ПРИВЕТ'):
        glyph=glyphs[mapping[c]];sign.alpha_composite(glyph,(40+i*29,16))
    atlas=Image.new('RGBA',(len(glyphs)*32,32))
    for i,g in enumerate(glyphs):atlas.alpha_composite(g,(i*32,0))
    atlas.save(OUT/'glyphs-preview.png')
    (OUT/'glyph-map.json').write_text(json.dumps(mapping,ensure_ascii=False),encoding='utf-8')
    W,H=1440,980;out=Image.new('RGB',(W,H),'#f1f3f5');d=ImageDraw.Draw(out)
    def font(s,b=False):return ImageFont.truetype('C:/Windows/Fonts/'+('arialbd.ttf' if b else 'arial.ttf'),s)
    def text(pos,s,size=24,fill='#27323d',b=False):d.text(pos,s,font=font(size,b),fill=fill)
    text((50,34),'Из чего складывается спрайтовая рамка',38,b=True)
    text((50,91),'Ресурсы плагина • вид спереди • без игрового освещения',22,fill='#697782')
    d.rounded_rectangle((40,145,1400,430),16,fill='white')
    text((66,163),'СОБРАНО',18,fill='#697782',b=True)
    out.paste(sign.resize((1024,256),Image.Resampling.NEAREST).convert('RGB'),(205,159))
    text((50,463),'Те же детали — раздвинуты',30,b=True)
    text((50,508),f'5 зон: фон и четыре стороны. В размере 256 × 64 это {len(ps)} плашки.',23)
    colors=['#244457','#31576c','#3d697f','#507c91','#60889a','#789cad']
    scale=3.3;ox=250;oy=610
    for k,p in enumerate(ps):
        x=ox+p['x']*scale;y=oy+(64-p['y']-p['h'])*scale
        if p['zone']=='верх':y-=29
        elif p['zone']=='низ':y+=29
        elif p['zone']=='лево':x-=29
        elif p['zone']=='право':x+=29
        gap=2 if p['zone']=='фон' else 0
        d.rectangle((x+gap/2,y+gap/2,x+p['w']*scale-gap/2,y+p['h']*scale-gap/2),fill=colors[k%len(colors)] if p['zone']=='фон' else '#8d99a5')
    text((70,625),'Левая\nсторона',21)
    text((1150,625),'Правая\nсторона',21)
    text((585,553),'Верхняя сторона',19)
    text((591,855),'Нижняя сторона',19)
    text((515,653),'Фон тоже составной',24,fill='white',b=True)
    text((50,907),'Разные цвета и зазоры внизу показаны только для объяснения сборки.',21,fill='#697782')
    text((50,938),'Это точная 2D-композиция ресурсов, а не скриншот из CS 1.6.',20,fill='#697782')
    out.save(OUT/'sprite-frame-parts.png')
    sign.save(OUT/'sprite-frame-actual.png')
    print(json.dumps({'parts':len(ps),'sprite_frames':len(frames),'glyph_frames':len(glyphs),'image':str(OUT/'sprite-frame-parts.png')},ensure_ascii=False))
if __name__=='__main__':main()
