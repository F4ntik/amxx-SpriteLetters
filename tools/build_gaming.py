"""Original, deliberately small gaming atlas. Requires Pillow; no downloaded art."""
from pathlib import Path
import struct
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'assets/sprites/SprLett/Charsets/Gaming_v1'
ICONS = [('🎯', 'aim', 'Прицел'), ('🔫', 'gun', 'Оружие'),
         ('💣', 'bomb', 'Бомба'), ('🛡', 'shield', 'Щит'),
         ('💀', 'skull', 'Череп'), ('🔥', 'fire', 'Огонь'),
         ('🏆', 'trophy', 'Трофей'), ('⚔', 'swords', 'Мечи'),
         ('🔵', 'ct', 'Команда CT'), ('🔴', 'tt', 'Команда T')]

def read_sprite(file):
    b = file.read_bytes()
    header = struct.unpack_from('<4siiifiiifi', b)
    assert header[:4] == (b'IDSP', 2, 3, 3)
    n = struct.unpack_from('<H', b, 40)[0]
    pal = b[42:42+n*3]; p = 42+n*3; frames = []
    for _ in range(header[7]):
        group, x, y, w, h = struct.unpack_from('<iiiii', b, p); p += 20
        assert group == 0
        im = Image.frombytes('P', (w, h), b[p:p+w*h]); im.putpalette(pal)
        im.info['transparency'] = 255
        frames.append((x, y, im.convert('RGBA'))); p += w*h
    assert p == len(b)
    return header, frames

def icon(kind):
    im = Image.new('RGBA', (32, 32)); d = ImageDraw.Draw(im)
    ink = '#182333'; light = '#edf4fa'; gold = '#ffc54b'; blue = '#43b8ff'
    if kind == 'aim':
        d.ellipse((6, 6, 25, 25), outline=ink, width=5)
        d.ellipse((7, 7, 24, 24), outline='#6bef8c', width=2)
        for box in [(14, 2, 17, 10), (14, 21, 17, 29), (2, 14, 10, 17), (21, 14, 29, 17)]: d.rectangle(box, fill=ink)
        for a, b in [((15, 3), (15, 9)), ((15, 22), (15, 28)), ((3, 15), (9, 15)), ((22, 15), (28, 15))]: d.line((a, b), fill='#6bef8c', width=2)
        d.rectangle((14, 14, 17, 17), fill=gold)
    elif kind == 'gun':
        d.polygon([(3, 8), (28, 8), (28, 14), (17, 14), (13, 26), (5, 25), (8, 15), (3, 15)], fill=ink)
        d.rectangle((4, 9, 27, 12), fill='#a2b8cb'); d.rectangle((5, 9, 22, 10), fill=light)
        d.polygon([(9, 15), (14, 15), (11, 24), (7, 23)], fill='#bf8151')
        d.arc((13, 12, 21, 20), 0, 150, fill=gold, width=2)
        d.rectangle((5, 6, 7, 8), fill=ink); d.rectangle((24, 6, 26, 8), fill=ink)
    elif kind == 'bomb':
        d.line([(19, 9), (21, 5), (25, 5), (26, 2)], fill=gold, width=2)
        d.rectangle((13, 6, 20, 11), fill=ink)
        d.ellipse((4, 9, 26, 30), fill=ink); d.ellipse((6, 11, 23, 27), fill='#425571')
        d.arc((8, 13, 20, 24), 180, 270, fill=light, width=3)
        d.line((24, 1, 29, 6), fill='#ff7546', width=2); d.line((29, 1, 24, 6), fill=gold, width=2)
    elif kind == 'shield':
        d.polygon([(16, 1), (29, 6), (26, 20), (16, 30), (6, 22), (3, 6)], fill=ink)
        d.polygon([(16, 4), (26, 8), (23, 20), (16, 27), (9, 20), (6, 8)], fill=blue)
        d.polygon([(16, 6), (24, 9), (21, 19), (16, 24)], fill='#1875b9')
        d.line((11, 15, 15, 19, 22, 11), fill=light, width=3)
    elif kind == 'skull':
        d.ellipse((3, 2, 28, 26), fill=ink); d.rectangle((9, 18, 23, 29), fill=ink)
        d.ellipse((5, 4, 26, 24), fill=light); d.rectangle((11, 20, 21, 27), fill=light)
        d.ellipse((8, 12, 13, 17), fill=ink); d.ellipse((19, 12, 24, 17), fill=ink)
        d.polygon([(16, 17), (13, 21), (18, 21)], fill=ink)
        d.line((14, 25, 14, 28), fill=ink); d.line((18, 25, 18, 28), fill=ink)
    elif kind == 'fire':
        d.polygon([(18, 1), (21, 12), (26, 7), (29, 21), (25, 28), (16, 31), (6, 28), (3, 20), (9, 9), (10, 18)], fill=ink)
        d.polygon([(17, 5), (20, 17), (25, 12), (26, 22), (22, 27), (15, 28), (8, 26), (6, 20), (10, 15), (11, 22)], fill='#ff7038')
        d.polygon([(16, 15), (22, 23), (19, 28), (13, 28), (10, 24)], fill=gold)
        d.polygon([(16, 21), (19, 27), (14, 27)], fill='#fff3b0')
    elif kind == 'trophy':
        d.rounded_rectangle((2, 5, 29, 18), radius=5, outline=gold, width=3)
        d.polygon([(7, 3), (24, 3), (23, 15), (18, 21), (18, 25), (24, 25), (24, 29), (7, 29), (7, 25), (13, 25), (13, 21), (8, 15)], fill=ink)
        d.polygon([(9, 5), (22, 5), (21, 14), (17, 19), (14, 19), (10, 14)], fill=gold)
        d.rectangle((15, 19, 16, 26), fill=gold); d.rectangle((9, 27, 22, 28), fill=gold)
        d.line((11, 6, 12, 12), fill='#fff3b0', width=2)
    elif kind == 'swords':
        for flip in (False, True):
            blade = Image.new('RGBA', (32, 32)); q = ImageDraw.Draw(blade)
            q.polygon([(4, 2), (11, 6), (24, 21), (21, 24), (6, 11)], fill=ink)
            q.polygon([(6, 5), (9, 7), (22, 21), (21, 22), (8, 9)], fill=light)
            q.line((17, 25, 25, 17), fill=gold, width=3); q.line((22, 23, 28, 29), fill='#bf8151', width=3)
            if flip: blade = blade.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            im.alpha_composite(blade)
    else:
        color = blue if kind == 'ct' else '#ff735c'
        d.polygon([(16, 1), (29, 8), (29, 23), (16, 31), (3, 23), (3, 8)], fill=ink)
        d.polygon([(16, 4), (26, 10), (26, 21), (16, 27), (6, 21), (6, 10)], fill=color)
        # Original block lettering: readable without an external font dependency.
        if kind == 'ct':
            d.line((14, 11, 10, 11, 10, 20, 14, 20), fill=ink, width=2)
            d.line((17, 11, 23, 11), fill=ink, width=2); d.line((20, 11, 20, 20), fill=ink, width=2)
        else:
            d.line((11, 11, 22, 11), fill=ink, width=3); d.line((16, 11, 16, 21), fill=ink, width=3)
    return im

def main():
    header, old = read_sprite(ROOT / 'assets/sprites/SprLett/Charsets/Default/chars.spr')
    assert len(old) == 157 and all(im.size == (32, 32) for _, _, im in old)
    frames = old + [(-16, 16, icon(alias)) for _, alias, _ in ICONS]
    # One shared palette, index 255 reserved for binary transparency.
    sheet = Image.new('RGB', (32 * len(frames), 32), 'white')
    for i, (_, _, im) in enumerate(frames): sheet.paste(im, (i*32, 0), im)
    palette = sheet.quantize(colors=255, method=Image.Quantize.MEDIANCUT)
    rgb = palette.getpalette()[:765]
    rgb += [0] * (765-len(rgb)) + [0, 0, 255]
    palette.putpalette(rgb)
    encoded = []
    for x, y, im in frames:
        indexed = im.convert('RGB').quantize(palette=palette, dither=Image.Dither.NONE)
        data = bytearray(indexed.tobytes())
        for p, alpha in enumerate(im.getchannel('A').tobytes()):
            if alpha < 128: data[p] = 255
        encoded.append(struct.pack('<iiiii', 0, x, y, 32, 32) + data)
    hdr = list(header); hdr[7] = len(frames)
    DEST.mkdir(parents=True, exist_ok=True)
    (DEST/'chars.spr').write_bytes(struct.pack('<4siiifiiifi', *hdr) + struct.pack('<H', 256) + bytes(rgb) + b''.join(encoded))
    old_map = (DEST.parent/'Default/map.txt').read_text(encoding='utf-8')
    (DEST/'map.txt').write_text(old_map.rstrip() + '\n' + ''.join(f'{char} {158+i}\n' for i, (char, _, _) in enumerate(ICONS)), encoding='utf-8')
    _, decoded = read_sprite(DEST/'chars.spr')
    assert len(decoded) == 167 <= 256
    for (x, y, before), (xx, yy, after) in zip(frames, decoded):
        assert (x, y) == (xx, yy)
        assert before.getchannel('A').tobytes() == after.getchannel('A').tobytes()
    assert len(decoded[157][2].getcolors()) > 3
    preview = Image.new('RGB', (1000, 360), '#111b29'); d = ImageDraw.Draw(preview)
    font_file = Path('C:/Windows/Fonts/arial.ttf')
    font = ImageFont.truetype(str(font_file), 20) if font_file.exists() else ImageFont.load_default(size=20)
    small = ImageFont.truetype(str(font_file), 16) if font_file.exists() else ImageFont.load_default(size=16)
    for i, (_, alias, label) in enumerate(ICONS):
        x, y = 200*(i%5), 180*(i//5)
        preview.paste(decoded[157+i][2].resize((96,96), Image.Resampling.NEAREST), (x+52, y+12), decoded[157+i][2].resize((96,96), Image.Resampling.NEAREST))
        d.text((x+100,y+114), ':'+alias+':', anchor='mt', font=font, fill='white')
        d.text((x+100,y+142), label, anchor='mt', font=small, fill='#adc0d5')
    (ROOT/'docs').mkdir(exist_ok=True)
    preview.save(ROOT/'docs/gaming-preview.png')
    print(f'Gaming_v1: {len(decoded)} frames; 10 icons; transparency and frame bounds OK')

if __name__ == '__main__': main()
