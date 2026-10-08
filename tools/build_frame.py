"""Generate the bone-controlled frame and inspect its compiled dimensions."""
from pathlib import Path
import sys,struct,json,math
ROOT=Path(__file__).resolve().parents[1]
HERE=ROOT/'model-source'
MODEL=ROOT/'assets/models/SprLett/frame_bones_v1.mdl'
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

BONES=['root','right','top','top_right'];PARENTS=[-1,0,0,1]
def generate():
    HERE.mkdir(parents=True,exist_ok=True);MODEL.parent.mkdir(parents=True,exist_ok=True)
    bmp(HERE/'back.bmp',(20,24,32));bmp(HERE/'edge.bmp',(155,165,175))
    nodes=['version 1','nodes']+[f'{i} "{n}" {PARENTS[i]}' for i,n in enumerate(BONES)]+['end','skeleton','time 0']+[f'{i} 0 0 0 0 0 0' for i in range(4)]+['end']
    lines=nodes+['triangles'];triangles=[]
    def add(w,h,y,z,front,mat,corner_start=0):
        for t in slab(w,h,front,corner_start=corner_start):
            verts=[(v[0],v[1]+y,v[2]+z) for v in t['v']]
            triangles.append((verts,mat));lines.append(mat+'.bmp')
            for v,uv in zip(verts,((.125,.125),(.875,.125),(.875,.875))):
                bone=(1 if v[1]<0 else 0)+(2 if v[2]>0 else 0)
                lines.append(str(bone)+' '+' '.join(f'{x:.6f}' for x in (*v,*t['n'],*uv)))
    add(24,8,0,0,lambda y,z:-.5,'back')
    add(24,4,0,-6,lambda y,z:.5-z/2,'edge');add(24,4,0,6,lambda y,z:.5+z/2,'edge')
    add(4,8,14,0,lambda y,z:.5+y/2,'edge');add(4,8,-14,0,lambda y,z:.5-y/2,'edge')
    yz=[(-2,-2),(2,-2),(2,2),(-2,2)]
    for sy in (-1,1):
        for sz in (-1,1):
            add(4,4,14*sy,6*sz,lambda y,z,sy=sy,sz=sz:.5+max(sy*y,sz*z)/2,'edge',yz.index((-2*sy,-2*sz)))
    lines.append('end');(HERE/'frame.smd').write_text('\n'.join(lines)+'\n',encoding='ascii')
    # Frozen frame 0 is neutral. Frame 1 exists so compiled sequence bounds include every supported size.
    idle=nodes[:-1]+['time 1','0 0 0 0 0 0 0','1 0 -480 0 0 0 0','2 0 0 112 0 0 0','3 0 0 112 0 0 0','end']
    (HERE/'idle.smd').write_text('\n'.join(idle)+'\n',encoding='ascii')
    qc=['$modelname "../assets/models/SprLett/frame_bones_v1.mdl"','$cd "."','$cdtexture "."','$scale 1','$origin 0 0 0 -90','$gamma 1','$body panel "frame"','$controller 0 "right" Y 0 -1020','$controller 1 "top" Z 0 1020','$controller 1 "top_right" Z 0 1020','$bbox -1.5 -496 -8 1.5 16 120','$cbox -1.5 -496 -8 1.5 16 120','$sequence idle "idle" fps 1']
    (HERE/'frame.qc').write_text('\n'.join(qc)+'\n',encoding='ascii')
    print('Generated one model: 4 bones, 3 controller bindings, 2 network values, 108 triangles.')
def check():
    b=MODEL.read_bytes()
    def i(o):return struct.unpack_from('<i',b,o)[0]
    def v(o):return struct.unpack_from('<3f',b,o)
    assert b[:4]==b'IDST' and i(4)==10 and i(72)==len(b)
    assert i(140)==4 and i(148)==3 and i(204)==1
    bones=[]
    for k in range(4):
        p=i(144)+k*112;bones.append(dict(parent=i(p+32),controllers=struct.unpack_from('<6i',b,p+40),base=v(p+64)))
        assert all(abs(x)<1e-5 for x in struct.unpack_from('<3f',b,p+76))
    controls=[struct.unpack_from('<iiffii',b,i(152)+k*24) for k in range(3)]
    assert [c[5] for c in controls]==[0,1,1]
    body=i(208);assert i(body+64)==1
    m=i(body+72);nv=i(m+80);vo=i(m+88);bo=i(m+84)
    seq=i(168);smin=v(seq+96);smax=v(seq+108)
    placements=0
    for w in range(32,513,4):
        for h in range(16,129,4):
            values=[(w-32)//4,(h-16)//4,0,0];world=[]
            for bone in bones:
                pos=list(bone['base'])
                for a,ci in enumerate(bone['controllers'][:3]):
                    if ci>=0:
                        _,_,start,end,_,index=controls[ci];pos[a]+=start+(end-start)*values[index]/255
                if bone['parent']>=0:pos=[pos[a]+world[bone['parent']][a] for a in range(3)]
                world.append(pos)
            verts=[[v(vo+j*12)[a]+world[b[bo+j]][a] for a in range(3)] for j in range(nv)]
            lo=[min(p[a] for p in verts) for a in range(3)];hi=[max(p[a] for p in verts) for a in range(3)]
            assert abs(hi[1]-lo[1]-w)<1e-4 and abs(hi[2]-lo[2]-h)<1e-4,(w,h,lo,hi)
            assert all(smin[a]-1e-4<=lo[a] and hi[a]<=smax[a]+1e-4 for a in range(3)),('sequence bounds',w,h,smin,smax,lo,hi)
            assert sorted({round(-p[1],5) for p in verts})==[-16,-12,w-20,w-16]
            assert sorted({round(p[2],5) for p in verts})==[-8,-4,h-12,h-8]
            if w in (32,128,256,508,512) and h in (16,64,128):
                for pitch,yaw,roll in ((0,0,0),(90,0,0),(-90,0,0),(0,0,90),(30,60,45),(135,270,-45)):
                    sp,cp=math.sin(math.radians(pitch)),math.cos(math.radians(pitch))
                    sy,cy=math.sin(math.radians(yaw)),math.cos(math.radians(yaw))
                    sr,cr=math.sin(math.radians(roll)),math.cos(math.radians(roll))
                    f=(cp*cy,cp*sy,-sp);r=(-sr*sp*cy+cr*sy,-sr*sp*sy-cr*cy,-sr*cp)
                    u=(cr*sp*cy+sr*sy,cr*sp*sy-sr*cy,cr*cp)
                    # GoldSrc AngleMatrix after StudioSetUpTransform's pitch inversion.
                    m=((cp*cy,sr*sp*cy-cr*sy,cr*sp*cy+sr*sy),
                       (cp*sy,sr*sp*sy+cr*cy,cr*sp*sy-sr*cy),(-sp,sr*cp,cr*cp))
                    pos=[r[a]*(16-w/2)+u[a]*(8-h/2)-f[a]*2 for a in range(3)]
                    center=[r[a]*(w/2-16)+u[a]*(h/2-8) for a in range(3)]
                    extent=[abs(r[a])*w/2+abs(u[a])*h/2+abs(f[a])*1.5 for a in range(3)]
                    rotated=[[sum(m[a][k]*p[k] for k in range(3)) for a in range(3)] for p in verts]
                    for a in range(3):
                        mn=min(p[a] for p in rotated);mx=max(p[a] for p in rotated)
                        assert abs(mn-(center[a]-extent[a]))<1e-4 and abs(mx-(center[a]+extent[a]))<1e-4
                        assert abs(pos[a]+(mn+mx)/2+f[a]*2)<1e-4
                    placements+=1
    result=dict(bytes=len(b),bones=len(bones),controllerBindings=len(controls),networkControls=2,dimensionsChecked=3509,placementCases=placements,sequenceBounds=[smin,smax],boundary='Compiled MDL + CPU geometry/reference placement checks; not tested in CS 1.6')
    (ROOT/'model-check.json').write_text(json.dumps(result,indent=2),encoding='utf-8');print(json.dumps(result,indent=2))
if __name__=='__main__':check() if '--check' in sys.argv else generate()
