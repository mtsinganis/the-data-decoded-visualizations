"""Extract preserved CBS PDFs; invoked by analysis.R with Python + pdfplumber."""
import csv
import re
from pathlib import Path
import pdfplumber

data = Path(__file__).resolve().parent
texts = {}
for name in ("rosh-hashana-2026", "e4-february-2026", "migration-methodology-2024"):
    with pdfplumber.open(data / f"{name}.pdf") as document:
        pages = [page.extract_text() or "" for page in document.pages]
    (data / f"{name}.txt").write_text("\n\f\n".join(pages), encoding="utf-8")
    texts[name] = pages

# Hebrew is returned in visual order. Anchors identify each reported component.
page = texts["rosh-hashana-2026"][0]
patterns = {
    "new_immigrants": r"םישדח םילוע ףלא ([\d,]+)-כ",
    "family_reunification": r"דוחיא תרגסמב ועיגה ףלא ([\d,]+)-כו",
    "returning_israelis": r"ףלא ([\d,]+)-כ ץראל ורזח",
    "israeli_emigrants": r"םילארשי ףלא ([\d,]+)-כ הנממ ואציו",
    "total_migration_balance": r"ףלא ([\d,]+)-כ םילארשיה תייסולכואמ וערגנו",
    "births": r"תוקונית ףלא ([\d,]+)-כ",
    "deaths": r"ףלא ([\d,]+)-כ ורטפנו",
    "population_increase": r"שפנ ףלא ([\d,]+)-כב םילארשיה תייסולכוא הלדג",
}
months = re.search(r"םישדוחה ([\d.]+)-ל", page)
assert months and "םייערא" in page and "282/2026" in page
with (data / "latest_period.csv").open("w", newline="", encoding="utf-8") as stream:
    writer = csv.writer(stream)
    writer.writerow(["component", "people", "period_months", "precision", "status", "source_page"])
    for key, pattern in patterns.items():
        matches = re.findall(pattern, page)
        assert len(matches) == 1, (key, matches)
        sign = -1 if key in ("israeli_emigrants", "total_migration_balance") else 1
        writer.writerow([key, sign * int(matches[0].replace(",", "")) * 1000,
                         months.group(1), "approximately_1000", "provisional", 1])

# Annual E/4 is an audit only; it is never used as the total migration series.
annual = []
for line in texts["e4-february-2026"][0].splitlines():
    match = re.match(r"^(20\d\d)(?:\(\d\))?\s*(\*)?\s+(-?[\d,]+)\s+([\d,]+)\s+([\d,]+)", line)
    if match:
        year, provisional, balance, returns, emigrants = match.groups()
        nums = [int(x.replace(",", "")) for x in (balance, returns, emigrants)]
        assert nums[1] - nums[2] == nums[0]
        annual.append([year, *nums, bool(provisional)])
    if len(annual) == 16:
        break
assert [int(row[0]) for row in annual] == list(range(2010, 2026))
with (data / "israeli_only_balance_audit.csv").open("w", newline="", encoding="utf-8") as stream:
    writer = csv.writer(stream)
    writer.writerow(["determination_year", "israeli_only_balance", "returning_israelis", "israeli_emigrants", "provisional"])
    writer.writerows(annual)
print("Extracted latest-period estimates and 16 E/4 audit rows from preserved PDFs.")
