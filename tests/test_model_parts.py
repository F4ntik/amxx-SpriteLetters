import sys,unittest,collections,math,tempfile
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from inspect_models import read_model,ROOT
from model_layout import layout
class ModelTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.models={p.stem:read_model(p) for p in (ROOT/'assets/models/SprLett').glob('*.mdl')}
    def test_all_sizes_cover_exactly_with_compiled_components(self):
        maximum=(0,None)
        for w in range(32,513,4):
            for h in range(16,129,4):
                parts=layout(w,h);self.assertLessEqual(len(parts),64)
                if len(parts)>maximum[0]:maximum=(len(parts),(w,h))
                self.assertEqual(sum(p['w']*p['h'] for p in parts),w*h)
                for j,p in enumerate(parts):
                    lo,hi=self.models[p['family']]['models'][p['body']]['bounds']
                    self.assertAlmostEqual(hi[1]-lo[1],p['w']);self.assertAlmostEqual(hi[2]-lo[2],p['h'])
                    self.assertGreaterEqual(p['x'],0);self.assertGreaterEqual(p['y'],0)
                    self.assertLessEqual(p['x']+p['w'],w);self.assertLessEqual(p['y']+p['h'],h)
                    for q in parts[j+1:]:
                        self.assertFalse(min(p['x']+p['w'],q['x']+q['w'])>max(p['x'],q['x']) and min(p['y']+p['h'],q['y']+q['h'])>max(p['y'],q['y']))
        print('3509 sizes; maximum MDL parts:',maximum)
    def test_every_compiled_mesh_is_closed_and_outward(self):
        for family,data in self.models.items():
            for m in data['models']:
                edges=collections.Counter();volume=0
                for t in m['triangles']:
                    a,b,c=t['v'];u=[b[k]-a[k] for k in range(3)];v=[c[k]-a[k] for k in range(3)]
                    cross=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]]
                    # StudioMDL deliberately reverses SMD winding for the GoldSrc renderer.
                    self.assertLess(sum(cross[k]*t['n'][k] for k in range(3)),0,(family,m['body']))
                    volume+=sum(a[k]*cross[k] for k in range(3))/6
                    for x,y in ((a,b),(b,c),(c,a)):edges[tuple(sorted((tuple(x),tuple(y))))]+=1
                self.assertTrue(all(n==2 for n in edges.values()),(family,m['body']))
                self.assertLess(volume,0)
    def test_truncated_model_is_rejected(self):
        p=ROOT/'assets/models/SprLett/panel_corners.mdl'
        with tempfile.TemporaryDirectory() as tmp:
            dest=Path(tmp)/'truncated.mdl';dest.write_bytes(p.read_bytes()[:-1])
            with self.assertRaises(AssertionError):read_model(dest)
if __name__=='__main__':unittest.main()
