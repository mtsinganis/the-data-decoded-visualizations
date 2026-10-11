"""Subset only the Lato characters/weights used by an SVG, preserving layout.
Requires fonttools[woff] and uharfbuzz; the plot itself remains R/ggplot2.
"""
from pathlib import Path
from io import BytesIO
from hashlib import sha256
import argparse,base64,json,re,sys,xml.etree.ElementTree as ET
try:
    from fontTools import subset
    from fontTools.ttLib import TTFont
    from fontTools.pens.recordingPen import RecordingPen,DecomposingRecordingPen
    import uharfbuzz as hb
    import brotli
except ImportError as error:
    raise SystemExit('Missing SVG font dependency: '+str(error)+
        '\nInstall with this Python: python -m pip install -r '+
        str(Path(__file__).with_name('requirements-svg.txt')))


FACES={400:'Regular',700:'Bold',900:'Black'}
FONT_DIR=Path(__file__).resolve().parents[2]/'assets/fonts/lato'
_CACHE={}

def weight(style,inherited=400):
    m=re.search(r'font-weight\s*:\s*([^;]+)',style)
    if not m:return inherited
    return {'normal':400,'bold':700}.get(m.group(1).strip(),int(m.group(1)) if m.group(1).strip().isdigit() else inherited)

def used_text(root):
    runs={}
    def scan(node,current=400,in_text=False):
        current=weight(node.attrib.get('style',''),current)
        in_text=in_text or node.tag.endswith('}text') or node.tag=='text'
        if in_text and node.text:
            runs.setdefault(current,[]).append(node.text)
        for child in node:
            scan(child,current,in_text)
            if in_text and child.tail:runs.setdefault(current,[]).append(child.tail)
    scan(root)
    return {w:[s for s in texts if s.strip()] for w,texts in runs.items()}

def sfnt_bytes(font):
    font.flavor=None
    out=BytesIO();font.save(out,reorderTables=True)
    return out.getvalue()

_SHAPE_FONTS={}
def shaped(data,text):
    key=sha256(data).hexdigest()
    if key not in _SHAPE_FONTS:
        font=TTFont(BytesIO(data),recalcTimestamp=False)
        face=hb.Face(data);f=hb.Font(face);f.scale=(face.upem,face.upem);hb.ot_font_set_funcs(f)
        _SHAPE_FONTS[key]=(font.getGlyphOrder(),font.getGlyphSet(),f,{})
    order,glyphs,f,signatures=_SHAPE_FONTS[key]
    buf=hb.Buffer();buf.add_str(text);buf.guess_segment_properties();hb.shape(f,buf)
    result=[]
    for i,p in zip(buf.glyph_infos,buf.glyph_positions):
        g=order[i.codepoint]
        if g not in signatures:
            pen=DecomposingRecordingPen(glyphs);glyphs[g].draw(pen)
            signatures[g]=sha256(repr(pen.value).encode()).hexdigest()
        result.append((signatures[g],i.cluster,p.x_advance,p.y_advance,p.x_offset,p.y_offset))
    return result
def font_subset(w,characters,flavor):
    key=(w,characters,flavor)
    if key in _CACHE:return _CACHE[key]
    source=FONT_DIR/f'Lato-{FACES[w]}.ttf'
    original_data=source.read_bytes(); original=TTFont(BytesIO(original_data),recalcTimestamp=False)
    font=TTFont(BytesIO(original_data),recalcTimestamp=False)
    options=subset.Options()
    options.layout_features=['*'];options.layout_scripts=['*'];options.glyph_names=True
    options.legacy_kern=True;options.hinting=True;options.ignore_missing_unicodes=False
    options.notdef_outline=True;options.recalc_timestamp=False
    options.name_IDs=['*'];options.name_legacy=True;options.name_languages=['*']
    sub=subset.Subsetter(options=options);sub.populate(unicodes=[ord(c) for c in characters]);sub.subset(font)
    # SIL OFL Reserved Font Name: originals stay pinned/unmodified; derivative
    # internal family names change, while SVG CSS still aliases the face as Lato.
    family='TDDSVGSubset';style=FACES[w];suffix=sha256(characters.encode()).hexdigest()[:12]
    replacements={1:family,2:style,3:f'{family}-{style}-{suffix}',4:f'{family} {style}',
                  6:f'{family}-{style}',16:family,17:style,18:f'{family} {style}'}
    for record in font['name'].names:
        if record.nameID in replacements:
            record.string=replacements[record.nameID].encode(record.getEncoding(),errors='strict')
    cmap=font.getBestCmap();old_cmap=original.getBestCmap()
    assert set(map(ord,characters))<=set(cmap)
    old_glyphs=original.getGlyphSet();new_glyphs=font.getGlyphSet()
    for c in characters:
        g=old_cmap[ord(c)];assert cmap[ord(c)]==g
        assert original['hmtx'][g]==font['hmtx'][g]
        a=RecordingPen();b=RecordingPen();old_glyphs[g].draw(a);new_glyphs[g].draw(b)
        assert a.value==b.value,(w,c)
    raw=sfnt_bytes(font)
    font.flavor=flavor;out=BytesIO();font.save(out,reorderTables=True);compressed=out.getvalue()
    decoded=TTFont(BytesIO(compressed),recalcTimestamp=False)
    decoded_data=sfnt_bytes(decoded)
    result=(compressed,original_data,decoded_data,{
        'weight':w,'format':flavor,'characters':characters,
        'codepoints':[f'U+{ord(c):04X}' for c in characters],
        'required_character_count':len(characters),'glyph_count':len(font.getGlyphOrder()),
        'compressed_bytes':len(compressed),'source_sha256':sha256(original_data).hexdigest(),
        'subset_family':family,'cmap_outline_and_advance_checks':True})
    _CACHE[key]=result
    return result

def optimize_svg(source,flavor='woff2'):
    root=ET.fromstring(source);runs=used_text(root);css=[];records=[]
    for w,texts in sorted(runs.items()):
        assert w in FACES,w
        characters=''.join(sorted(set(''.join(texts))-set('\n\r\t')))
        compressed,original,decoded,record=font_subset(w,characters,flavor)
        # Shaping, kerning, ligatures and glyph positions must match each used run.
        for text in texts:assert shaped(original,text)==shaped(decoded,text),(w,text)
        # Titles span three same-weight runs; compare the complete phrase as well.
        for text in [''.join(n.itertext()) for n in root.iter() if n.tag.endswith('}text') and weight(n.attrib.get('style',''))==w]:
            assert shaped(original,text)==shaped(decoded,text),(w,text)
        record=dict(record,shaped_text_runs=len(texts),shaping_verified=True)
        records.append(record)
        css.append(f'@font-face{{font-family:"Lato";font-weight:{w};src:url(data:font/{flavor};base64,'+
                   base64.b64encode(compressed).decode()+f') format("{flavor}");}}')
    output,count=re.subn(r'<style\b[^>]*>.*?</style>',
                        '<style type="text/css"><![CDATA['+''.join(css)+']]></style>',source,count=1,flags=re.S)
    assert count==1
    # Non-font SVG markup must be byte-identical: no geometry/text/layout edits.
    strip=lambda s:re.sub(r'<style\b[^>]*>.*?</style>','STYLE',s,count=1,flags=re.S)
    assert strip(output)==strip(source)
    assert 'SIL OPEN FONT LICENSE' in output
    return output,records

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input',type=Path,nargs='?');parser.add_argument('output',type=Path,nargs='?')
    parser.add_argument('--check',action='store_true',help='Check required font tools before rendering')
    parser.add_argument('--format',choices=['woff2','woff'],default='woff2')
    parser.add_argument('--report',type=Path)
    args=parser.parse_args()
    if args.check:
        for face in FACES.values():assert (FONT_DIR/f'Lato-{face}.ttf').is_file()
        print('SVG font tools and pinned Lato source fonts available')
        return
    if not args.input or not args.output:parser.error('input and output paths are required')
    source=args.input.read_text(encoding='utf-8-sig');output,fonts=optimize_svg(source,args.format)
    args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_text(output,encoding='utf-8')
    if args.report:
        args.report.parent.mkdir(parents=True,exist_ok=True)
        args.report.write_text(json.dumps({'input_bytes':args.input.stat().st_size,
        'output_bytes':args.output.stat().st_size,'format':args.format,'fonts':fonts},indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    print(f'{args.input.name}: {args.input.stat().st_size:,} -> {args.output.stat().st_size:,} bytes ({args.format})')
if __name__=='__main__':main()
