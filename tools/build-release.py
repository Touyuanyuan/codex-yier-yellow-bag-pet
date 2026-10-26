"""Build only the explicitly listed public release files (Python standard library)."""
from pathlib import Path
import json, zipfile, struct
ROOT=Path(__file__).resolve().parent.parent
VERSION='1.0.0'
PROJECT='codex-yier-yellow-bag-pet'
FILES=['.gitattributes','.gitignore','README.md','LICENSE','ASSET-NOTICE.md','CREDITS.md','CHANGELOG.md','RELEASE-NOTES.md','install.cmd','install.ps1','install-link.txt','install-in-codex.url','install.html','preview.html','pet/pet.json','pet/spritesheet.webp','docs/contact-sheet.png','docs/all-states.gif','docs/look-loop.gif','tools/build-release.py','tests/test-install.ps1']
def build():
    data={name:(ROOT/name).read_bytes() for name in FILES}
    pet=json.loads(data['pet/pet.json'].decode('utf-8-sig'))
    assert pet['id']=='yier-yellow-bag' and pet['displayName']=='小黄包一二' and pet['spriteVersionNumber']==2
    b=data['pet/spritesheet.webp'];assert b[:4]==b'RIFF' and b[8:12]==b'WEBP'
    off=12;size=None
    while off+8<=len(b):
        kind=b[off:off+4];n=int.from_bytes(b[off+4:off+8],'little');c=b[off+8:off+8+n]
        if kind==b'VP8X':size=(int.from_bytes(c[4:7],'little')+1,int.from_bytes(c[7:10],'little')+1)
        if kind==b'VP8L' and size is None:
            bits=int.from_bytes(c[1:5],'little');size=((bits&16383)+1,((bits>>14)&16383)+1)
        off+=8+n+n%2
    assert size==(1536,2288),size
    for name,blob in data.items():
        if Path(name).suffix not in ['.png','.webp','.gif'] and name!='tools/build-release.py':
            text=blob.decode('utf-8-sig')
            assert '.codex/sessions/' not in text and '.codex\\sessions\\' not in text,name
            assert 'C:\\Users\\Song' not in text and 'E:\\02_Codex' not in text,name
    dist=ROOT/'dist';dist.mkdir(exist_ok=True)
    out=dist/f'{PROJECT}-v{VERSION}-windows.zip'
    prefix=f'{PROJECT}-v{VERSION}/'
    with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
        for name,blob in data.items():z.writestr(prefix+name,blob)
    with zipfile.ZipFile(out) as z:
        assert z.testzip() is None
        assert z.read(prefix+'pet/spritesheet.webp')==data['pet/spritesheet.webp']
    print(json.dumps({'archive':out.name,'files':len(FILES),'bytes':out.stat().st_size,'dimensions':size},ensure_ascii=False))
    return out
if __name__=='__main__':build()
