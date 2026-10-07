"""Run with the bundled Python runtime (pypdf and pypdfium2). Read-only sources."""
from pathlib import Path
import re, csv
from pypdf import PdfReader
import pypdfium2 as pdfium

p = Path(__file__).resolve().parents[1]
source = p / 'data/raw/fy2018-monthly.pdf'
reader = PdfReader(source)
rows = []
for i, page in enumerate(reader.pages):
    text = page.extract_text()
    year = re.search(r'By Month\s*-\s*FY\s*(\d{4})', text)
    if not year or int(year[1]) not in (2017, 2018):
        continue
    line = next(x for x in text.splitlines() if x.startswith('Southwest Border '))
    values = [int(x.replace(',', '')) for x in line.removeprefix('Southwest Border ').split()]
    assert len(values) == 13 and sum(values[:12]) == values[12]
    for month, count in zip([10,11,12,1,2,3,4,5,6,7,8,9], values[:12]):
        rows.append([int(year[1]), month, count, values[12], i+1])
    doc = pdfium.PdfDocument(str(source))
    doc[i].render(scale=1.6).to_pil().save(p / f'narrative/pdf-fy{year[1]}-check.png')
with (p / 'data/processed/pdf_monthly_check.csv').open('w', newline='') as f:
    w = csv.writer(f)
    w.writerow(['fiscal_year','month','monthly_encounters','fiscal_total','pdf_page'])
    w.writerows(rows)
assert len(rows) == 24
