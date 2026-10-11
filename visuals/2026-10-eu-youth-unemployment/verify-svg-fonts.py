"""Verify all 28 embedded SVG font subsets. Run from the repository root.
Requires requirements-svg.txt; plotting remains R/ggplot2.
"""
from pathlib import Path
from io import BytesIO
import base64,importlib.util,json,re,sys,xml.etree.ElementTree as ET
sys.dont_write_bytecode=True
from fontTools.ttLib import TTFont
project=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('svg_optimizer',project/'optimize-svg-fonts.py')
optimizer=importlib.util.module_from_spec(spec);spec.loader.exec_module(optimizer)
files=sorted((project/'plots/countries').glob('*.svg'))+[project/'plots/youth-unemployment-greece-eu.svg']
assert len(files)==28
records=[]
for file in files:
    source=file.read_text(encoding='utf-8-sig');root=ET.fromstring(source)
    runs=optimizer.used_text(root)
    embeds=re.findall(r'font-weight:(\d+);src:url\(data:font/(woff2|woff);base64,([^)]*)\)',source)
    assert {int(w) for w,_,_ in embeds}==set(runs)
    assert len(embeds)==len(runs)
    for w,flavor,data in embeds:
        font=TTFont(BytesIO(base64.b64decode(data)));assert font.flavor==flavor
        assert font['OS/2'].usWeightClass==int(w)
        characters=set(''.join(runs[int(w)]))-set('\n\r\t')
        assert set(map(ord,characters))<=set(font.getBestCmap())
        assert any(n.nameID==1 and n.toUnicode()=='TDDSVGSubset' for n in font['name'].names)
        assert any(n.nameID==13 and 'SIL Open Font License' in n.toUnicode() for n in font['name'].names)
    assert root.attrib['viewBox']=='0 0 864.00 648.00'
    records.append({'file':str(file.relative_to(project)).replace('\\','/'),'weights':sorted(runs),'format':embeds[0][1],'all_required_characters_present':True})
assert all(r['format']=='woff2' for r in records)
(project/'data/svg_font_validation.json').write_text(json.dumps({'chart_count':28,'charts':records},indent=2)+'\n',encoding='utf-8')
print('Verified 28 WOFF2 SVGs: only actual font weights, every required character, font licences and canvas dimensions')
