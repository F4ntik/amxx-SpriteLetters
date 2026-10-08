"""Asset/API contract check; this does not execute Pawn or the GoldSrc renderer."""
import re
from build_gaming import ROOT, DEST, ICONS, read_sprite

def main():
    _, frames = read_sprite(DEST/'chars.spr')
    _, old = read_sprite(DEST.parent/'Default/chars.spr')
    mapping = dict(line.rsplit(' ', 1) for line in (DEST/'map.txt').read_text(encoding='utf-8').splitlines())
    assert len(mapping) == len(frames) == 167
    assert sorted(map(int, mapping.values())) == list(range(1, 168))
    include = (ROOT/'amxmodx/scripting/include/SprLett-Gaming.inc').read_text(encoding='utf-8')
    def values(name):
        block = re.search(name + r'\[\]\[\]\s*=\s*\{(.*?)\};', include, re.S)[1]
        return re.findall(r'"([^"]*)"', block)
    assert values('SL_GAMING_ALIASES') == [f':{a}:' for _, a, _ in ICONS]
    assert values('SL_GAMING_GLYPHS') == [c for c, _, _ in ICONS]
    assert int(re.search(r'SL_GAMING_FIRST_FRAME\s*=\s*(\d+)', include)[1]) == len(old)
    for i, (char, alias, _) in enumerate(ICONS, len(old)):
        assert int(mapping[char])-1 == i < 256
        assert len(char) == 1 and len(char.encode()) < 8
        assert len(char.encode()) <= len(alias)+2  # in-place replacement cannot overflow
        rgba = frames[i][2]
        assert len(rgba.getcolors()) >= 3
        assert rgba.getchannel('A').getextrema() == (0, 255)
        assert any(0 < max(r,g,b)-min(r,g,b) for _, (r,g,b,a) in rgba.getcolors() if a)
    # All original letters retain their geometry and transparency in the combined atlas.
    max_error = 0
    for before, after in zip(old, frames):
        assert before[:2] == after[:2]
        left, right = before[2].tobytes(), after[2].tobytes()
        for offset in range(0, len(left), 4):
            p, q = left[offset:offset+4], right[offset:offset+4]
            assert p[3] == q[3]
            if p[3]: max_error = max(max_error, *(abs(p[i]-q[i]) for i in range(3)))
    assert max_error <= 8, max_error
    print(f'PASS: 167 mapped frames; 10 aliases/glyphs; palette, UTF-8 bounds and transparency; font RGB error <= {max_error}')

if __name__ == '__main__': main()
