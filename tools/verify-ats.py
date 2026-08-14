#!/usr/bin/env python3
"""Assert the ATS variant stays machine-readable.

Run via `make ats`. The point of the variant is text extraction, so these
checks look at what a parser sees rather than at the rendered page.

Usage: verify-ats.py [cv-ats.pdf]
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

PDF = Path(sys.argv[1] if len(sys.argv) > 1 else "cv-ats.pdf")

# Contact lines must be spelled out, not carried by an icon glyph.
REQUIRED_LABELS = ["Email:", "Website:", "GitHub:", "Google Scholar:", "ORCID:"]

failures: list[str] = []


def run(cmd: list[str]) -> str:
    r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
    if r.returncode != 0:
        sys.exit(f"FATAL: {' '.join(cmd)} failed:\n{r.stderr}")
    return r.stdout


def check(ok: bool, label: str, detail: str = "") -> None:
    print(f"  {'PASS' if ok else 'FAIL'}  {label}" + ("" if ok or not detail else f" -- {detail}"))
    if not ok:
        failures.append(label)


if not PDF.exists():
    sys.exit(f"FATAL: {PDF} not found. Run `make ats` first.")

print(f"Verifying {PDF}\n")

# Raw order, not -layout: this is what a naive parser reads.
text = run(["pdftotext", str(PDF), "-"])

missing = [l for l in REQUIRED_LABELS if l not in text]
check(not missing, "contact lines are spelled out, not iconographic", f"missing {missing}")

# Icon fonts have no Unicode mapping, so they extract as control characters or
# vanish entirely. Their absence is the check that no glyph carries meaning.
fonts = run(["pdffonts", str(PDF)])
check("FontAwesome" not in fonts, "no icon font embedded")

ctrl = sorted({c for c in text if ord(c) < 32 and c not in "\n\r\t\f"})
check(not ctrl, "no control characters in extracted text",
      f"found {[hex(ord(c)) for c in ctrl]}")

# Three or more consecutive spaces in raw extraction means text was positioned
# in columns, which is what reorders content for a parser.
gappy = [ln.strip()[:60] for ln in text.splitlines() if re.search(r"\S {3,}\S", ln)]
check(not gappy, "no column-positioned text", f"{len(gappy)} line(s), e.g. {gappy[:2]}")

# A hyphen-joined date range extracts as a range; an en-dash is fine, but the
# pair must survive as one token rather than being split across lines.
check("Present" in text, "date ranges present in extraction")

pages = int(re.search(r"^Pages:\s+(\d+)$", run(["pdfinfo", str(PDF)]), re.M).group(1))
print(f"\n  note  {pages} pages, {len(text.split())} words extracted\n")

if failures:
    print(f"FAILED: {len(failures)} check(s) did not pass.")
    sys.exit(1)
print("All checks passed.")
