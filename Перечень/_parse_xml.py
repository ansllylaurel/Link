# -*- coding: utf-8 -*-
from pathlib import Path
from xml.etree import ElementTree as ET

p = Path(r"c:\Users\DETarasov\Documents\Link\Перечень\результаты запросов.xml")
ns = {"ss": "urn:schemas-microsoft-com:office:spreadsheet"}
tree = ET.parse(p)
ws = tree.getroot().find("ss:Worksheet", ns)
table = ws.find("ss:Table", ns)

rows = []
for row in table.findall("ss:Row", ns):
    cells = []
    col = 1
    for cell in row.findall("ss:Cell", ns):
        idx = cell.get("{urn:schemas-microsoft-com:office:spreadsheet}Index")
        if idx:
            col = int(idx)
        while len(cells) < col - 1:
            cells.append("")
        data = cell.find("ss:Data", ns)
        val = data.text if data is not None and data.text is not None else ""
        cells.append(val)
        col += 1
    rows.append(cells)

out = Path(r"c:\Users\DETarasov\Documents\Link\Перечень\_parsed_results.txt")
blocks = []
current = []
current_title = None
for r in rows:
    if r and r[0].startswith("Результат"):
        if current_title is not None:
            blocks.append((current_title, current))
        current_title = r[0]
        current = []
        continue
    if current_title is not None:
        current.append(r)
if current_title is not None:
    blocks.append((current_title, current))

with out.open("w", encoding="utf-8") as f:
    f.write(f"total_xml_rows={len(rows)}\nblocks={len(blocks)}\n\n")
    for title, block in blocks:
        nonempty = [r for r in block if any(c.strip() for c in r)]
        f.write("=" * 80 + "\n")
        f.write(title + "\n")
        f.write(f"nonempty_rows={len(nonempty)}\n")
        f.write("=" * 80 + "\n")
        for r in nonempty:
            while r and not r[-1]:
                r = r[:-1]
            f.write("\t".join(r) + "\n")
        f.write("\n")

print(f"blocks={len(blocks)}")
for title, block in blocks:
    nonempty = [r for r in block if any(c.strip() for c in r)]
    print(title, "rows", len(nonempty))
