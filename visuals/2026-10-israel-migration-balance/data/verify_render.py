from pathlib import Path
from PIL import Image, ImageChops
import json, csv, pdfplumber
p=Path("C:/Code/the-data-decoded-visualizations/visuals/2026-10-israel-migration-balance")
q=p/"data/qa"
slots=list(csv.DictReader((p/"data/header_slots.csv").open(encoding="utf-8-sig")))
audit=[]
for f in sorted((p/"plots").glob("*.png")):
    im=Image.open(f).convert("RGB")
    px=im.load()
    rows=[]
    chart_slots=[r for r in slots if r["chart"]==f.stem]
    header_bottom=round((8.8-float(chart_slots[0]["subtitle_top_inches"])+int(chart_slots[0]["subtitle_lines"])*.23)*240)
    for y in range(40,header_bottom):
        n=sum(1 for x in range(96,2020) if max(px[x,y])<195)
        if n>10: rows.append(y)
    groups=[]
    for y in rows:
        if not groups or y>groups[-1][-1]+8: groups.append([y])
        else: groups[-1].append(y)
    bounds=[(g[0],g[-1]) for g in groups]
    chart_slots=[r for r in slots if r["chart"]==f.stem]
    nt=len(chart_slots); ns=int(chart_slots[0]["subtitle_lines"])
    assert len(bounds)==nt+ns, bounds
    title_gap=bounds[1][0]-bounds[0][1]-1 if nt>1 else None
    subtitle_gap=bounds[nt][0]-bounds[nt-1][1]-1
    if nt>1: assert title_gap<=subtitle_gap and abs(title_gap-subtitle_gap)<=5
    bbox=ImageChops.difference(im,Image.new("RGB",im.size,"white")).getbbox()
    assert bbox[0]>10 and bbox[1]>10 and bbox[2]<2102 and bbox[3]<2102
    audit.append({"chart":f.name,"title_lines":nt,"subtitle_lines":ns,"header_ink_bounds":bounds,"title_line_gap_px":title_gap,
       "title_to_subtitle_gap_px":subtitle_gap,"nonwhite_bounds":bbox})
    key=f.stem
    left=Image.open(q/(key+"-social.png")).convert("RGB")
    right=Image.open(q/(key+"-svg-social.png")).convert("RGB")
    pair=Image.new("RGB",(2160,1080),"white")
    pair.paste(left,(0,0)); pair.paste(right,(1080,0))
    pair.save(q/(key+"-format-comparison.png"))
for count in set((a["title_lines"],a["subtitle_lines"]) for a in audit):
    matched=[a for a in audit if (a["title_lines"],a["subtitle_lines"])==count]
    for line in range(count[0]+1):
        starts=[row["header_ink_bounds"][line][0] for row in matched]
        assert max(starts)-min(starts)<=1, starts
for name in ["rosh-hashana-2026","st02_08-2025"]:
    with pdfplumber.open(p/"data"/(name+".pdf")) as doc:
        doc.pages[0].to_image(resolution=130).save(q/(name+"-source-page.png"))
(q/"rendered_bounds.json").write_text(json.dumps(audit,indent=2)+"\n",encoding="utf8")
print(json.dumps(audit,indent=2))
