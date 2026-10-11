"""Optional text-to-paths comparison export; requires Inkscape and local Lato.
Usage: python outline-svg-text.py input.svg output.svg --inkscape PATH
This loses text editing. Editable subset WOFF2 remains the main export format.
"""
from pathlib import Path
import argparse,re,shutil,subprocess,tempfile,xml.etree.ElementTree as ET
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('input',type=Path);parser.add_argument('output',type=Path)
parser.add_argument('--inkscape',default=shutil.which('inkscape.com') or shutil.which('inkscape'))
args=parser.parse_args()
if not args.inkscape:parser.error('Inkscape CLI is required; pass --inkscape PATH')
args.output.parent.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory() as tmp:
    source=Path(tmp)/'input.svg';outlined=Path(tmp)/'outlined.svg'
    svg=args.input.read_text(encoding='utf-8-sig')
    svg=re.sub(r'(<(?:text|tspan)\b[^>]*style=[\'"])([^\'"]*)',lambda m:m[1]+'stroke:none;'+m[2],svg)
    source.write_text(svg,encoding='utf-8')
    actions=f'select-by-element:text;object-to-path;export-type:svg;export-plain-svg;export-filename:{outlined.as_posix()};export-do'
    subprocess.run([args.inkscape,str(source),'--actions='+actions],check=True,capture_output=True,timeout=45)
    svg=outlined.read_text(encoding='utf-8-sig')
    svg=re.sub(r'<style\b[^>]*>.*?@font-face.*?</style>','',svg,flags=re.S)
    ET.register_namespace('','http://www.w3.org/2000/svg');ET.register_namespace('xlink','http://www.w3.org/1999/xlink')
    root=ET.fromstring(svg)
    assert not any(n.tag.endswith('}text') for n in root.iter())
    # svglite's path selector otherwise changes glyph fills/strokes on conversion.
    for el in root.iter():
        if 'aria-label' not in el.attrib:continue
        for node in el.iter():
            if not node.tag.endswith('}path'):continue
            style=node.get('style','')+';stroke:none'
            if not re.search(r'(?:^|;)\s*fill\s*:',style):style+=';fill:inherit'
            node.set('style',style)
    ET.ElementTree(root).write(args.output,encoding='utf-8',xml_declaration=True)
print(f'{args.output}: {args.output.stat().st_size:,} bytes; no editable text elements')
