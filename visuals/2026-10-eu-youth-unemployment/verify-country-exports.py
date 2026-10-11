"""Verify 27 country exports and build their contact sheet. Run after analysis.R.
Requires Pillow; chart authoring remains entirely in R/ggplot2.
"""
from pathlib import Path
from PIL import Image
import csv, json, re, xml.etree.ElementTree as ET

project = Path('visuals/2026-10-eu-youth-unemployment')
settings = json.loads((project/'data/country_chart_settings.json').read_text(encoding='utf-8-sig'))
def rows(name):
    with (project/'data'/name).open(encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))
exports=rows('country_exports.csv')
coverage={r['geo']:r for r in rows('coverage.csv')}
labels=rows('country_endpoint_labels.csv')
audits=rows('country_plotted_values_validation.csv')
layouts=rows('country_layout_validation.csv')
assert len(exports)==27 and len({r['geo'] for r in exports})==27
assert {r['geo'] for r in exports}==set(coverage)-{'EU27_2020'}
assert len(labels)==54 and len(audits)==81 and len(layouts)==27
out=project/'plots/countries'
assert len(list(out.glob('youth-unemployment-*-eu.png')))==27 and len(list(out.glob('youth-unemployment-*-eu.svg')))==27
reference=ET.parse(project/'plots/youth-unemployment-greece-eu.svg').getroot()
def texts(root):
    return [el for el in root.iter() if el.tag.endswith('}text')]
reference_text=texts(reference)
def attrs(el):
    return {k:v for k,v in el.attrib.items() if k!='{http://www.w3.org/XML/1998/namespace}space'}
axis_words=['0%','10%','20%','30%','40%','50%','60%','70%','Jan','2000','2005','2010','2015','2020','Sep','2026']
ref_axes=[attrs(el) for el in reference_text if el.text in axis_words]
ref_footer=[(el.text,attrs(el)) for el in reference_text if float(el.attrib['y'])>530]
ref_header=[el for el in reference_text if el.text and el.text.startswith('Youth unemployment in ')][0]
ref_subtitle=[el for el in reference_text if el.text==settings['subtitle']][0]
validation=[]
for r in exports:
    geo=r['geo']; name=r['country']
    png_path=Path(r['png']); svg_path=Path(r['svg'])
    with Image.open(png_path) as im:
        assert im.size==(3600,2700) and abs(im.info['dpi'][0]-300)<.01
        rgb=im.convert('RGB')
        for edge in (rgb.crop((0,0,3600,1)),rgb.crop((0,2699,3600,2700)),
                     rgb.crop((0,0,1,2700)),rgb.crop((3599,0,3600,2700))):
            assert edge.getextrema()==((255,255),(255,255),(255,255))
    root=ET.parse(svg_path).getroot(); ts=texts(root)
    visible=[''.join(el.itertext()) for el in ts]
    assert root.attrib['viewBox']=='0 0 864.00 648.00'
    source=svg_path.read_text(encoding='utf-8-sig')
    assert source.count('@font-face')==3
    assert all(f'font-weight:{w};src:url(data:font/woff2;base64,' in source for w in (400,700,900))
    assert all(not ('href' in k and not v.startswith('data:')) for el in root.iter() for k,v in el.attrib.items())
    title=[el for el in ts if float(el.attrib['y'])<80]
    assert ''.join(title[0].itertext())==f'Youth unemployment in {name} and the EU'
    assert len(title)==2 and title[-1].text==settings['subtitle']
    spans=list(title[0])
    assert len(spans)==1 and spans[0].text==name and 'fill: #2455FF' in spans[0].attrib['style']
    assert title[0].text=='Youth unemployment in ' and spans[0].tail==' and the EU'
    assert 'fill: #172033' in title[0].attrib['style'] and 'font-weight: 900' in title[0].attrib['style']
    assert title[0].attrib['{http://www.w3.org/XML/1998/namespace}space']=='preserve'
    assert title[0].attrib['x']==ref_header.attrib['x'] and title[0].attrib['y']==ref_header.attrib['y']
    assert attrs(title[-1])==attrs(ref_subtitle)
    assert [attrs(el) for el in ts if el.text in axis_words]==ref_axes
    assert [(el.text,attrs(el)) for el in ts if float(el.attrib['y'])>530]==ref_footer
    for el in ts:
        # textLength is the exported renderer's measured Lato width, in SVG points.
        extent=float(el.attrib.get('textLength','0px')[:-2])
        x=float(el.attrib['x']); anchor=el.attrib.get('text-anchor','start')
        left=x-(extent/2 if anchor=='middle' else extent if anchor=='end' else 0)
        assert left>=25 and left+extent<=839, (geo,el.text,left+extent)
    for g in (geo,'EU27_2020'):
        expected=coverage[g]
        label_name=name if g==geo else 'EU-27'
        value=f"{label_name}  {float(expected['final_rate']):.1f}%"
        assert value in visible
        el=ts[visible.index(value)]
        assert f"fill: {'#2455FF' if g==geo else '#172033'}" in el.attrib['style']
        saved=[x for x in labels if x['featured_geo']==geo and x['geo']==g][0]
        assert float(saved['final_rate'])==float(expected['final_rate'])
        assert saved['latest_month']==expected['latest_month']
        assert saved['endpoint_date'] in visible
    selected=[x for x in labels if x['featured_geo']==geo]
    assert abs(float(selected[0]['label_y'])-float(selected[1]['label_y']))>=5.5-1e-8
    line_paths=[el for el in root.iter() if el.tag.endswith('}polyline')]
    grey=[el for el in line_paths if 'stroke: #A6B0BD;' in el.attrib.get('style','') and 'stroke-width: 0.68;' in el.attrib['style']]
    featured=[el for el in line_paths if 'stroke: #2455FF;' in el.attrib.get('style','') and 'stroke-width: 2.52;' in el.attrib['style']]
    eu=[el for el in line_paths if 'stroke: #172033;' in el.attrib.get('style','') and 'stroke-dasharray:' in el.attrib['style']]
    assert len(grey)==26 and len(featured)==1 and len(eu)==1
    assert max(line_paths.index(el) for el in grey)<line_paths.index(featured[0])<line_paths.index(eu[0])
    assert 'stroke-width: 2.13;' in eu[0].attrib['style'] and 'stroke-dasharray: 11.38,5.69;' in eu[0].attrib['style']
    a=[x for x in audits if x['featured_geo']==geo]
    assert [x['series'] for x in a]==['Other EU countries',geo,'EU27_2020']
    assert all(x['exact_match']=='TRUE' for x in a)
    assert sum(int(x['verified_points']) for x in a)==sum(int(x['observed_months']) for x in coverage.values())
    validation.append({'geo':geo,'country':name,'final_rate':float(coverage[geo]['final_rate']),
                       'endpoint':coverage[geo]['latest_month'],'two_labels_clear':True})
shared_fields=['title_top_inches','subtitle_top_inches','title_lines','subtitle_lines','title_fontsize','subtitle_fontsize',
               'width','height','dpi','plot_top','plot_bottom','metadata_top','source_lines','note_lines']
for key in shared_fields:
    assert len({r[key] for r in layouts})==1,(key,[r[key] for r in layouts])
assert layouts[0]['title_lines']=='1' and layouts[0]['note_lines']=='2'
# Reproducible review contact sheet, ordered alphabetically by full country name.
thumb_w=900; thumb_h=675; gap=18
sheet=Image.new('RGB',(3*thumb_w+4*gap,9*thumb_h+10*gap),'white')
for i,r in enumerate(exports):
    with Image.open(r['png']) as im:
        thumb=im.convert('RGB').resize((thumb_w,thumb_h),Image.Resampling.LANCZOS)
    sheet.paste(thumb,(gap+(i%3)*(thumb_w+gap),gap+(i//3)*(thumb_h+gap)))
sheet_path=project/'plots/youth-unemployment-eu-country-contact-sheet.png'
sheet.save(sheet_path,dpi=(150,150))
report={'country_count':27,'png_count':27,'svg_count':27,'png_pixels':[3600,2700],'dpi':300,
        'common_axes_header_footer_and_typography':True,'featured_title_only_blue':True,'continuous_svg_title_with_inline_colour_span':True,
        'background_countries_per_chart':26,'exact_plotted_values_per_chart':sum(int(x['observed_months']) for x in coverage.values()),
        'grey_featured_eu_layer_order':True,'endpoint_values_dates_and_labels_verified':True,
        'no_text_clipping':True,'self_contained_svg_fonts':True,'contact_sheet':str(sheet_path),
        'countries':validation}
(project/'data/country_rendered_validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k!='countries'},indent=2))
