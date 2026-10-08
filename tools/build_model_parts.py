"""Build reusable GoldSrc SMD/QC components. No in-game MDL scale required."""
from pathlib import Path
import json, math, struct
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'model-source'
MODELS=ROOT/'assets/models/SprLett'

def bmp(path, color):
    width=height=16; pixels=bytes(width*height); offset=14+40+1024
    data=struct.pack('<2sIHHI',b'BM',offset+len(pixels),0,0,offset)
    data+=struct.pack('<IiiHHIIiiII',40,width,height,1,8,0,len(pixels),0,0,256,256)
    data+=bytes((color[2],color[1],color[0],0))*256+pixels
    path.write_bytes(data)

def norm(tri):
    a,b,c=tri;u=[b[i]-a[i] for i in range(3)];v=[c[i]-a[i] for i in range(3)]
    n=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]]
    length=math.sqrt(sum(x*x for x in n));assert length>1e-8
    return [x/length for x in n]

def slab(w,h,front,back=-1.5,corner_start=0):
    # Local axes: X out of the wall; -Y right along the sign; +Z up.
    yz=[(-w/2,-h/2),(w/2,-h/2),(w/2,h/2),(-w/2,h/2)]
    a=[(back,y,z) for y,z in yz];b=[(front(y,z),y,z) for y,z in yz]
    quads=[(a,(-1,0,0)),(b[corner_start:]+b[:corner_start],(1,0,0))]
    for j,n in enumerate(((0,0,-1),(0,1,0),(0,0,1),(0,-1,0))):
        k=(j+1)%4;quads.append(([a[j],a[k],b[k],b[j]],n))
    triangles=[]
    for quad,out in quads:
        for ids in ((0,1,2),(0,2,3)):
            tri=[quad[i] for i in ids];normal=norm(tri)
            if sum(normal[i]*out[i] for i in range(3))<0:tri.reverse();normal=norm(tri)
            triangles.append({'v':tri,'n':normal})
    return triangles

def smd(name,triangles,material):
    lines=['version 1','nodes','0 "root" -1','end','skeleton','time 0','0 0 0 0 0 0 0','end','triangles']
    for tri in triangles:
        lines.append(material+'.bmp')
        for v,uv in zip(tri['v'],((0.125,0.125),(0.875,0.125),(0.875,0.875))):
            lines.append('0 '+' '.join(f'{x:.6f}' for x in (*v,*tri['n'],*uv)))
    lines.append('end');(SOURCE/(name+'.smd')).write_text('\n'.join(lines)+'\n',encoding='ascii',newline='\n')

def build():
    SOURCE.mkdir(parents=True,exist_ok=True);MODELS.mkdir(parents=True,exist_ok=True)
    bmp(SOURCE/'back.bmp',(20,24,32));bmp(SOURCE/'edge.bmp',(155,165,175))
    (SOURCE/'idle.smd').write_text('version 1\nnodes\n0 "root" -1\nend\nskeleton\ntime 0\n0 0 0 0 0 0 0\nend\n',encoding='ascii')
    families={'panel_bg_a':[],'panel_bg_b':[],'panel_edges':[],'panel_corners':[]}
    for wx in range(1,10):
        for hy in range(1,8):
            frame=(wx-1)*7+hy-1;w=1<<wx;h=1<<hy;name=f'bg_{frame:02}'
            triangles=slab(w,h,lambda y,z:-0.5)
            smd(name,triangles,'back')
            families['panel_bg_a' if frame<32 else 'panel_bg_b'].append(dict(name=name,w=w,h=h,triangles=triangles,material='back',frame=frame))
    for zone in range(1,5):
        exponents=range(1,10) if zone<=2 else range(1,8)
        for exponent in exponents:
            w,h=((1<<exponent),4) if zone<=2 else (4,(1<<exponent))
            # Top/left outer lip is positive local short axis, bottom/right negative.
            direction=-1 if zone in (1,4) else 1
            front=(lambda y,z,d=direction:0.5+d*z/2) if zone<=2 else (lambda y,z,d=direction:0.5+d*y/2)
            name=f'edge_{zone}_{exponent}';triangles=slab(w,h,front);smd(name,triangles,'edge')
            families['panel_edges'].append(dict(name=name,w=w,h=h,triangles=triangles,material='edge',zone=zone,exponent=exponent))
    for corner in range(4):
        sy=1 if corner in (0,2) else -1;sz=1 if corner in (2,3) else -1
        yz=[(-2,-2),(2,-2),(2,2),(-2,2)];inner=yz.index((-2*sy,-2*sz))
        front=lambda y,z,sy=sy,sz=sz:0.5+max(sy*y,sz*z)/2
        name=f'corner_{corner}';triangles=slab(4,4,front,corner_start=inner);smd(name,triangles,'edge')
        families['panel_corners'].append(dict(name=name,w=4,h=4,triangles=triangles,material='edge',corner=corner))
    for family,models in families.items():
        assert len(models)<=32
        lines=[f'$modelname "../assets/models/SprLett/{family}.mdl"','$cd "."','$cdtexture "."','$scale 1.0','$origin 0 0 0 -90','$gamma 1.0','$bodygroup pieces','{']
        lines += [f' studio "{m["name"]}"' for m in models]
        lines += ['}','$sequence idle "idle" fps 1 loop']
        (SOURCE/(family+'.qc')).write_text('\n'.join(lines)+'\n',encoding='ascii',newline='\n')
    (SOURCE/'geometry.json').write_text(json.dumps(families,separators=(',',':')),encoding='utf-8')
    print(json.dumps({name:len(models) for name,models in families.items()}))
if __name__=='__main__':build()
