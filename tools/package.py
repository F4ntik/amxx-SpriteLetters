"""Package an already verified four-plugin build; no compiler or live-server changes."""
from pathlib import Path, PureWindowsPath
import argparse, hashlib, json, zipfile

ROOT = Path(__file__).resolve().parents[1]
PLUGINS = ('SprLetters', 'SprLett-Saver', 'SprLett-Editor', 'SprLett-Gradient')

def sha(data): return hashlib.sha256(data).hexdigest()

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build-dir', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--previous', type=Path, help='Check that existing client resources stay unchanged')
    args = parser.parse_args()
    receipt = json.loads((args.build_dir/'build-receipt.json').read_text(encoding='utf-8-sig'))
    files = {}
    def tree(base, prefix):
        for p in sorted(base.rglob('*')):
            if p.is_file() and '__pycache__' not in p.parts and p.suffix != '.pyc':
                name = prefix+'/'+p.relative_to(base).as_posix()
                assert name not in files
                files[name] = p.read_bytes()
    assert {PureWindowsPath(item['source']).stem for item in receipt['files']} == set(PLUGINS)
    for item in receipt['files']:
        source = ROOT/'amxmodx/scripting'/PureWindowsPath(item['source']).name
        assert sha(source.read_bytes()) == item['source_sha256'], source
        data = (args.build_dir/item['binary']).read_bytes()
        assert data[:4] == b'XXMA' and sha(data) == item['binary_sha256']
        files['addons/amxmodx/plugins/'+item['binary']] = data
        item['source'] = source.relative_to(ROOT).as_posix()
    receipt['compiler'] = PureWindowsPath(receipt['compiler']).name
    receipt['include_directories'] = ['amxmodx/scripting/include', 'AMXX compiler include directory']
    receipt['boundary'] = 'Compiled and source-reviewed; no CS client/server runtime verification'
    files['build-receipt.json'] = json.dumps(receipt, ensure_ascii=False, indent=2).encode('utf-8')
    tree(ROOT/'amxmodx/data', 'addons/amxmodx/data')
    tree(ROOT/'assets', '')
    files = {name.lstrip('/'): data for name, data in files.items()}
    files['addons/amxmodx/configs/plugins-SprLett.ini'] = ''.join(p+'.amxx\n' for p in PLUGINS).encode()
    files['README.md'] = (ROOT/'README.md').read_bytes()
    tree(ROOT/'docs', 'docs')
    for directory in ('amxmodx/scripting', 'model-source', 'tools'):
        tree(ROOT/directory, 'source/SpriteLetters/'+directory)
    tree(ROOT/'assets', 'source/SpriteLetters/assets')
    if args.previous:
        with zipfile.ZipFile(args.previous) as old:
            common = [n for n in files if n.startswith(('sprites/', 'models/')) and n in old.namelist()]
            assert common
            assert all(old.read(n) == files[n] for n in common), 'Existing resource path changed'
    files['MANIFEST.sha256'] = ''.join(sha(data)+'  '+name+'\n' for name, data in sorted(files.items())).encode()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(args.output, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for name, data in sorted(files.items()): z.writestr(name, data)
    with zipfile.ZipFile(args.output) as z:
        assert z.testzip() is None
        for line in z.read('MANIFEST.sha256').decode().splitlines():
            digest, name = line.split('  ', 1)
            assert sha(z.read(name)) == digest
    print(json.dumps({'archive': args.output.name, 'files': len(files), 'bytes': args.output.stat().st_size,
                      'sha256': sha(args.output.read_bytes()), 'checks': 'build hashes, existing resources, ZIP CRC, manifest'}, indent=2))

if __name__ == '__main__': main()
