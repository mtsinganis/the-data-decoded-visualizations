from pathlib import Path
import re,csv,json,pdfplumber
p=Path('visuals/2026-10-israel-migration-balance'); d=p/'data'
with pdfplumber.open(d/'e1-february-2026.pdf') as doc: txt='\n\n'.join(x.extract_text() or '' for x in doc.pages)
e1={}
for line in txt.splitlines():
 m=re.match(r'^(20\d\d)(?:\(4\))?\s+(?:\*\s+)?((?:[\d,]+\s+){6}[\d,]+)\s',line)
 if m and int(m[1])>=2010: e1.setdefault(int(m[1]),int(m[2].split()[-1].replace(',','')))
rows=list(csv.DictReader((d/'israeli_only_balance_audit.csv').open(encoding='utf-8-sig')))
reported={2023:27600,2024:-18600,2025:-20900}
with (d/'historical_reconstruction_audit.csv').open('w',newline='',encoding='utf8') as f:
 w=csv.DictWriter(f,fieldnames=['year','revised_israeli_only_balance','immigrants_and_immigrating_citizens','candidate_sum_not_total','published_total','unexplained_difference','decision']);w.writeheader()
 for r in rows:
  y=int(r['determination_year']);candidate=int(r['israeli_only_balance'])+e1[y]
  w.writerow(dict(year=y,revised_israeli_only_balance=r['israeli_only_balance'],immigrants_and_immigrating_citizens=e1[y],candidate_sum_not_total=candidate,published_total=reported.get(y,''),unexplained_difference=reported[y]-candidate if y in reported else '',decision='Not charted: required other arrivals and aligned timing/definitions not verified'))
