"""Read compiled GoldSrc v10 MDL and verify component geometry before packaging."""
from pathlib import Path
import hashlib,json,math,struct
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT.parents[1]/'outputs'

def read_model(path):
    b=path.read_bytes()
    def i(offset):return struct.unpack_from('<i',b,offset)[0]
    def v(offset):return struct.unpack_from('<3f',b,offset)
    def valid(offset,size):assert 0<=offset<=len(b) and 0<=size<=len(b)-offset,(path,offset,size)
    assert b[:4]==b'IDST' and i(4)==10 and i(72)==len(b),(path,'header')
    assert i(140)==1 and i(204)==1
    bone=i(144);valid(bone,112);assert i(bone+32)==-1
    assert all(abs(x)<0.0001 for x in struct.unpack_from('<6f',b,bone+64)),(path,'unexpected bone transform')
    assert i(164)==1
    seq=i(168);valid(seq,176);assert i(seq+56)==1
    tex_count=i(180);tex_offset=i(184);colors=[]
    for t in range(tex_count):
        p=tex_offset+t*80;valid(p,80);w,h,data=i(p+68),i(p+72),i(p+76);valid(data,w*h+768)
        pixel=b[data];color=list(b[data+w*h+pixel*3:data+w*h+pixel*3+3]);colors.append(color)
    valid(i(200),i(192)*i(196)*2)
    skin=struct.unpack_from('<'+str(i(192))+'h',b,i(200))
    body=i(208);valid(body,76);num=i(body+64);assert 1<=num<=32 and i(body+68)==1
    model_offset=i(body+72);models=[]
    for n in range(num):
        p=model_offset+n*112;valid(p,112)
        count,voffset=i(p+80),i(p+88);valid(voffset,count*12);verts=[v(voffset+k*12) for k in range(count)]
        valid(i(p+84),count);assert not any(b[i(p+84):i(p+84)+count])
        normal_count,normal_offset=i(p+92),i(p+100);valid(normal_offset,normal_count*12);normals=[v(normal_offset+k*12) for k in range(normal_count)]
        tris=[]
        for m in range(i(p+72)):
            mp=i(p+76)+m*20;valid(mp,20);expected=i(mp);q=i(mp+4);tex=skin[i(mp+8)];mesh_tris=[]
            while True:
                valid(q,2);cmd=struct.unpack_from('<h',b,q)[0];q+=2
                if not cmd:break
                assert abs(cmd)>=3;valid(q,abs(cmd)*8);indices=[]
                for j in range(abs(cmd)):
                    vi,ni,s,t=struct.unpack_from('<4h',b,q);q+=8
                    assert 0<=vi<count and 0<=ni<normal_count
                    indices.append((vi,ni))
                for j in range(2,len(indices)):
                    ids=(0,j-1,j) if cmd<0 else ((j-2,j-1,j) if j%2==0 else (j-1,j-2,j))
                    selected=[indices[k] for k in ids]
                    mesh_tris.append({'v':[verts[x[0]] for x in selected],'n':normals[selected[0][1]],'color':colors[tex]})
            assert len(mesh_tris)==expected,(path,n,len(mesh_tris),expected)
            tris+=mesh_tris
        bounds=[[min(x[a] for x in verts) for a in range(3)],[max(x[a] for x in verts) for a in range(3)]]
        models.append({'body':n,'bounds':bounds,'triangles':tris})
    return {'name':path.name,'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b),'models':models}

def verify():
    source=json.loads((ROOT/'model-source/geometry.json').read_text())
    result={}
    for family,expected in source.items():
        obj=read_model(ROOT/'assets/models/SprLett'/(family+'.mdl'))
        assert len(obj['models'])==len(expected)
        for actual,wanted in zip(obj['models'],expected):
            allv=[v for tri in wanted['triangles'] for v in tri['v']]
            bounds=[[min(v[a] for v in allv) for a in range(3)],[max(v[a] for v in allv) for a in range(3)]]
            assert all(abs(actual['bounds'][r][a]-bounds[r][a])<0.0001 for r in range(2) for a in range(3)),(family,actual['body'],actual['bounds'],bounds)
            assert len(actual['triangles'])==len(wanted['triangles'])
        result[family]=obj
    (OUT/'mdl-preview-data.json').write_text(json.dumps(result,separators=(',',':')),encoding='utf-8')
    print(json.dumps({k:{'bytes':v['bytes'],'bodies':len(v['models']),'sha256':v['sha256']} for k,v in result.items()},indent=2))
    return result
if __name__=='__main__':verify()
