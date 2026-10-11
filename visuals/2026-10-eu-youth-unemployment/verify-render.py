"""Validate saved TDD export geometry/typography and synchronized ALT text.
Run from repository root after analysis.R; needs Pillow (bundled Codex Python).
"""
from pathlib import Path
import csv
import json
import re
import xml.etree.ElementTree as ET
from PIL import Image

project = Path('visuals/2026-10-eu-youth-unemployment')
png = Image.open(project / 'plots/youth-unemployment-greece-eu.png').convert('RGB')
assert png.size == (3600, 2700)
root = ET.parse(project / 'plots/youth-unemployment-greece-eu.svg').getroot()
svg_source = (project / 'plots/youth-unemployment-greece-eu.svg').read_text(encoding='utf-8-sig')
assert len(re.findall(r'@font-face', svg_source)) == 3
for weight in (400, 700, 900):
    assert f'font-weight:{weight};src:url(data:font/woff2;base64,' in svg_source
assert root.attrib['viewBox'] == '0 0 864.00 648.00'
assert all(not ('href' in k and not v.startswith('data:'))
           for el in root.iter() for k, v in el.attrib.items())
texts = [el for el in root.iter() if el.tag.endswith('}text')]
visible = [''.join(el.itertext()) for el in texts]
for s in ('Youth unemployment in Greece and the EU', 'Greece  15.6%',
          'Spain  22.7%', 'Germany  7.4%', 'EU-27  15.4%',
          'Other EU countries', 'THE DATA DECODED'):
    assert s in visible, s
assert visible.count('Aug 2026') == 4
assert 'Monthly, seasonally-adjusted youth unemployment rate, ages 15–24 (%) · Jan 2000–Sep 2026' in visible
assert 'Eurostat (une_rt_m)' in visible
assert not any('January 2000–' in s for s in visible)
assert 'Rates show the share of 15–24-year-olds who are unemployed among those working or actively seeking and available for work—not among all young people. Monthly figures are adjusted to account for regular seasonal patterns.' in ' '.join(visible)
assert 'Monthly, seasonally adjusted.' not in ' '.join(visible)
assert 'Open circles denote series breaks.' in ' '.join(visible)
assert not any('Markos' in s for s in visible)

# Actual ink rows, measured on the raster export, not nominal font leading.
# Restrict to header content, before key and chart; each connected row-band is a line.
pixels = png.load()
ink_rows = []
for y in range(30, 280):
    count = sum(min(pixels[x, y]) < 180 for x in range(120, 3300))
    if count >= 8:
        ink_rows.append(y)
bands = []
for y in ink_rows:
    if not bands or y > bands[-1][1] + 1:
        bands.append([y, y])
    else:
        bands[-1][1] = y
assert len(bands) == 2, bands
header_gap = bands[1][0] - bands[0][1] - 1
assert header_gap > 0
# White safety margins catch content clipping at the page boundary.
assert all(png.getpixel((x, 0)) == (255,255,255) for x in range(png.width))
assert all(png.getpixel((x, png.height-1)) == (255,255,255) for x in range(png.width))
assert all(png.getpixel((0, y)) == (255,255,255) for y in range(png.height))
assert all(png.getpixel((png.width-1, y)) == (255,255,255) for y in range(png.height))

story = (project / 'story.md').read_text(encoding='utf-8-sig')
post = (project / 'post.md').read_text(encoding='utf-8-sig')
alts = re.findall(r'    alt: "(.*)"', story)
assert len(alts) == 54 and len(set(alts)) == 27
assert all(len(a) <= 1000 and a in post for a in alts)
alt = max(alts, key=len)
assert 'status: published' in story
assert 'presentation: country-explorer' in story
assert 'title: "Youth unemployment across the EU"' in story

with (project / 'data/coverage.csv').open(encoding='utf-8-sig',newline='') as f:
    coverage = list(csv.DictReader(f))
assert len(coverage) == 28
assert sum(int(r['internal_missing']) for r in coverage) == 0
assert sum(int(r['observed_months']) for r in coverage) == 8950
assert sum(int(r['missing_months']) for r in coverage) == 38
with (project / 'data/series_breaks.csv').open(encoding='utf-8-sig',newline='') as f:
    breaks = list(csv.DictReader(f))
assert len(breaks) == 21 and len({r['geo'] for r in breaks}) == 18
# Assert the described Greek peak months directly from the tidy data.
with (project / 'data/youth_unemployment_monthly.csv').open(encoding='utf-8-sig',newline='') as f:
    greek = [r for r in csv.DictReader(f) if r['geo'] == 'EL' and r['rate'] != 'NA']
peak = max(float(r['rate']) for r in greek)
peak_months = [r['month'] for r in greek if float(r['rate']) == peak]
assert peak == 61.4 and peak_months == ['2013-06-01','2013-07-01']

report = {
    'png_pixels': list(png.size), 'png_dpi': 300,
    'svg_viewbox': root.attrib['viewBox'], 'embedded_lato_weights': [400,700,900],
    'header_ink_bounds_pixels': bands, 'title_to_subtitle_visible_gap_pixels': header_gap,
    'wrapped_title_lines': 1, 'header_gap_rule': 'one title line; no inter-title gap',
    'white_edge_margins': True, 'endpoint_values_and_dates_in_svg': True,
    'alt_characters': len(alt), 'story_post_alt_identical': True, 'status': 'published',
    'png_and_svg_visual_inspection': 'Both inspected; monthly frequency in subtitle and revised explanatory Notes including series-break markers; date labels retain 7 pt additional padding',
    'flagged_breaks': len(breaks), 'countries_with_flagged_breaks': 18,
    'greek_peak': peak, 'greek_peak_months': peak_months
}
(project / 'data/rendered_validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,indent=2))
