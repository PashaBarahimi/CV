#!/usr/bin/env python3
"""Assert the built CV meets the acceptance tests in CV-SPEC.md.

Run via `make verify`, and in CI after the LaTeX build. Requires poppler's
pdftotext and pdfinfo on PATH (both ship with TeX Live; CI installs
poppler-utils explicitly).

Usage: verify-pdf.py [cv.pdf] [cv.log]

Checks, in order:
  1. Page count is exactly EXPECTED_PAGES          (spec 6, "content creep")
  2. No section or entry heading sits in the       (spec 2.1)
     bottom BOTTOM_BAND of any page, and none is
     left without content beneath it
  3. Every date range uses an en-dash, never a     (spec 2.3, 2.6)
     hyphen, and matches the canonical format
  4. Pages 2+ carry the running header; page 1     (spec 2.2)
     does not
  5. PDF title and author metadata are populated   (spec 8)
  6. The LaTeX log is clean: no undefined          (spec 6, 8)
     references and no overfull box over
     MAX_OVERFULL_PT

Deliberately pure Python with no shell dependency, so `make verify` behaves
identically on Linux, macOS and Windows.

Exit status is 0 only if every check passes.
"""

from __future__ import annotations

import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

PDF = Path(sys.argv[1] if len(sys.argv) > 1 else "cv.pdf")
LOG = Path(sys.argv[2] if len(sys.argv) > 2 else PDF.with_suffix(".log"))

EXPECTED_PAGES = 2

# Spec sec. 8: "overfull hboxes under 5pt or eliminated".
MAX_OVERFULL_PT = 5.0

# Warnings that are known-benign and deliberately tolerated. Empty on purpose:
# the build currently produces a completely clean log, and it should stay that
# way. Add an entry here only with a comment explaining why it is acceptable.
WARNING_ALLOWLIST: list[str] = []

# "No section heading and no entry heading may appear within the last 15% of
# any page" -- CV-SPEC.md 2.1.
BOTTOM_BAND = 0.15

# Section headings, as they appear in cv.tex.
SECTION_HEADINGS = [
    "Education",
    "Research Interests",
    "Publications",
    "Research Experience",
    "Work Experience",
    "Teaching Experience",
    "Honors and Awards",
    "Skills & Languages",
]

# First words of entry headings (\cvevent / \cvpublication / \cvproject).
# An entry heading stranded at the foot of a page is the same defect as a
# stranded section heading.
ENTRY_HEADINGS = [
    "University of Southern California",
    "University of Tehran",
    "Enforcing Control Flow Integrity",
    "Research Assistant",
    "Bachelor's Thesis",
    "Research Intern",
    "Mid-Level Software Engineer",
    "Junior Software Developer",
    "Site Reliability Engineering Intern",
    # Only the enabled projects. This list fails loudly on any heading it
    # cannot find, so entries commented out in sections/projects.tex must not
    # appear here.
]

RUNNING_HEADER = "Pasha Barahimi"

# Canonical: "Mon YYYY -- Mon YYYY" (en-dash) or a bare year. Academic terms in
# Teaching Experience are permitted by spec 2.3 provided they are right-aligned
# and set in body colour and size, which is a rendering property checked by eye.
MONTHS = "Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec"
CANONICAL_RANGE = re.compile(rf"\b(?:{MONTHS})\s+\d{{4}}\s+–\s+(?:(?:{MONTHS})\s+\d{{4}}|Present)\b")
# A month-year pair joined by an ASCII hyphen is the defect spec 2.6 names.
HYPHEN_RANGE = re.compile(rf"\b(?:{MONTHS})\s+\d{{4}}\s*-\s*(?:(?:{MONTHS})\s+\d{{4}}|Present)\b")
# The build-date stamp at the foot of the last page.
LAST_UPDATED = re.compile(rf"Last updated:\s*((?:{MONTHS})\s+\d{{4}})")

failures: list[str] = []
notes: list[str] = []


def run(cmd: list[str]) -> str:
    result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
    if result.returncode != 0:
        sys.exit(f"FATAL: {' '.join(cmd)} failed:\n{result.stderr}")
    return result.stdout


def check(ok: bool, label: str, detail: str = "") -> None:
    if ok:
        print(f"  PASS  {label}")
    else:
        print(f"  FAIL  {label}" + (f" -- {detail}" if detail else ""))
        failures.append(label)


if not PDF.exists():
    sys.exit(f"FATAL: {PDF} not found. Run `make` first.")

print(f"Verifying {PDF}\n")

# --- 1. Page count ---------------------------------------------------------
info = run(["pdfinfo", str(PDF)])
pages = int(re.search(r"^Pages:\s+(\d+)$", info, re.M).group(1))
check(pages == EXPECTED_PAGES, f"page count is exactly {EXPECTED_PAGES}", f"got {pages}")

# --- 5. Metadata (read from the same pdfinfo output) -----------------------
title = re.search(r"^Title:\s*(.*)$", info, re.M).group(1).strip()
author = re.search(r"^Author:\s*(.*)$", info, re.M).group(1).strip()
check(bool(title), "PDF title metadata is populated", "empty")
check(bool(author), "PDF author metadata is populated", "empty")

# --- Parse word geometry ---------------------------------------------------
# -bbox-layout, not -bbox: the latter emits bare <word> elements with no <line>
# grouping, which would make every position check below pass on empty data.
bbox = run(["pdftotext", "-bbox-layout", str(PDF), "-"])
bbox = re.sub(r"<!DOCTYPE[^>]*>", "", bbox, count=1)
# Strip the default namespace so ElementTree queries stay readable.
bbox = re.sub(r'\sxmlns="[^"]+"', "", bbox, count=1)
# Icon glyphs with no Unicode mapping come back as C0 control characters --
# the ORCID mark extracts as 0x1A -- which XML 1.0 forbids, so poppler emits
# output its own parser would reject. Drop the illegal ranges, keeping tab,
# newline and carriage return.
bbox = re.sub(r"[\x00-\x08\x0B\x0C\x0E-\x1F]", "", bbox)
root = ET.fromstring(bbox)

pages_el = root.findall(".//page")

# Rebuild lines of text with their vertical position, per page.
page_lines: list[tuple[float, list[tuple[str, float]]]] = []
for page in pages_el:
    height = float(page.get("height"))
    lines = []
    for line in page.findall(".//line"):
        words = [w.text or "" for w in line.findall("word")]
        ymin = min(float(w.get("yMin")) for w in line.findall("word"))
        lines.append((" ".join(words), ymin))
    page_lines.append((height, lines))

# --- Guard against vacuous heading checks ----------------------------------
# If a heading is renamed in the .tex but not here, the checks below would
# silently pass by matching nothing. Fail loudly instead.
all_line_text = [t for _, lines in page_lines for t, _ in lines]


def norm(s: str) -> str:
    """Fold case and flatten typographic punctuation.

    LaTeX turns ' into U+2019 and -- into U+2013, so literal comparison against
    the strings written in the .tex files would fail.
    """
    return (
        s.replace("’", "'")
        .replace("‘", "'")
        .replace("“", '"')
        .replace("”", '"')
        .casefold()
    )


def find_heading(heading: str) -> list[tuple[int, float, float]]:
    """Return (page_no, ymin, page_height) for each line starting with heading."""
    hits = []
    for page_no, (height, lines) in enumerate(page_lines, start=1):
        for text, ymin in lines:
            # pdftotext renders small caps as plain text; compare case-folded.
            if norm(text).startswith(norm(heading)):
                hits.append((page_no, ymin, height))
    return hits


missing = [h for h in SECTION_HEADINGS + ENTRY_HEADINGS if not find_heading(h)]
check(
    not missing,
    "every heading this script checks is actually present in the PDF",
    f"never matched: {missing}",
)

# --- 2. No heading in the bottom band, and none left without content --------
stranded = []
orphaned = []
for heading in SECTION_HEADINGS + ENTRY_HEADINGS:
    for page_no, ymin, height in find_heading(heading):
        if ymin >= height * (1.0 - BOTTOM_BAND):
            pct = 100.0 * ymin / height
            stranded.append(f"p{page_no} {heading!r} at {pct:.1f}% down")
        # The defect that actually matters: a heading with nothing under it.
        # Require at least two more lines below it on the same page.
        _, lines = page_lines[page_no - 1]
        below = [t for t, y in lines if y > ymin + 1.0]
        if len(below) < 2:
            orphaned.append(f"p{page_no} {heading!r} has {len(below)} line(s) under it")

check(
    not stranded,
    f"no section or entry heading in the bottom {BOTTOM_BAND:.0%} of any page",
    "; ".join(stranded),
)
check(
    not orphaned,
    "every heading is followed by at least two lines on the same page",
    "; ".join(orphaned),
)

# --- 3. Date format --------------------------------------------------------
text_all = run(["pdftotext", "-layout", str(PDF), "-"])

hyphenated = HYPHEN_RANGE.findall(text_all)
check(not hyphenated, "no date range uses an ASCII hyphen", f"found {hyphenated}")

# The last-updated stamp is a legitimate single-point date rather than a range,
# so it is checked on its own terms and then excluded from the range accounting
# below. It must still use the canonical Mon YYYY vocabulary.
stamp = LAST_UPDATED.search(text_all)
check(stamp is not None, "last-updated stamp present, in canonical Mon YYYY form")
dated_text = LAST_UPDATED.sub("", text_all)
if stamp:
    notes.append(f"last updated: {stamp.group(1)}")

ranges = CANONICAL_RANGE.findall(dated_text)
# Every "Mon YYYY" that participates in a range must be part of a canonical
# one. Count bare occurrences and make sure they are all accounted for.
month_years = re.findall(rf"\b(?:{MONTHS})\s+\d{{4}}\b", dated_text)
canonical_spans = sum(
    len(re.findall(rf"\b(?:{MONTHS})\s+\d{{4}}\b", m)) for m in CANONICAL_RANGE.findall(dated_text)
)
check(
    canonical_spans == len(month_years),
    "every Mon-YYYY date belongs to a canonical en-dashed range",
    f"{len(month_years)} month-year tokens, {canonical_spans} inside canonical ranges",
)
notes.append(f"{len(ranges)} canonical date ranges found")

# --- 4. Running header -----------------------------------------------------
per_page_text = text_all.split("\f")
first_page_head = per_page_text[0][:200]
check(
    RUNNING_HEADER not in first_page_head.replace("Pasha Barahimi\n", "", 1)
    or "Page 1 of" not in per_page_text[0],
    "page 1 carries no running header",
    "found a page-number header on page 1",
)
for page_no in range(2, pages + 1):
    body = per_page_text[page_no - 1]
    has_name = RUNNING_HEADER in body[:200]
    has_number = re.search(rf"Page\s+{page_no}\s+of\s+{pages}", body) is not None
    check(has_name and has_number, f"page {page_no} carries name and page number")

# --- 6. LaTeX log hygiene --------------------------------------------------
if not LOG.exists():
    check(False, f"LaTeX log {LOG} exists", "not found; run the build first")
else:
    log_text = LOG.read_text(encoding="utf-8", errors="replace")

    undefined = re.findall(
        r"LaTeX Warning: (?:There were undefined references"
        r"|Reference .* undefined|Citation .* undefined).*",
        log_text,
    )
    check(not undefined, "no undefined references or citations", f"{undefined[:3]}")

    multiply = re.findall(r"LaTeX Warning: Label .* multiply defined.*", log_text)
    check(not multiply, "no multiply-defined labels", f"{multiply[:3]}")

    # Spec sec. 8: "LaTeX log has no unresolved warnings". Checked generically
    # rather than by listing known offenders -- an earlier version of this
    # script grepped only for "LaTeX Warning" and "Package X Warning" and so
    # missed five "LaTeX Font Warning" lines entirely.
    warnings = [
        w.strip()
        for w in re.findall(
            r"^(?:LaTeX|LaTeX Font|Package \S+|Class \S+) Warning:.*", log_text, re.M
        )
        if not any(re.search(p, w) for p in WARNING_ALLOWLIST)
    ]
    check(
        not warnings,
        "LaTeX log has no unresolved warnings",
        "; ".join(warnings[:5]) + (" ..." if len(warnings) > 5 else ""),
    )

    boxes = [
        (float(size), kind)
        for kind, size in re.findall(
            r"Overfull \\([hv])box \(([0-9.]+)pt too (?:wide|high)\)", log_text
        )
    ]
    too_big = [f"{s}pt (\\{k}box)" for s, k in boxes if s > MAX_OVERFULL_PT]
    check(
        not too_big,
        f"no overfull box exceeds {MAX_OVERFULL_PT:g}pt",
        "; ".join(too_big),
    )
    notes.append(f"{len(boxes)} overfull box(es) in the log, largest "
                 f"{max((s for s, _ in boxes), default=0):g}pt")

    underfull = len(re.findall(r"Underfull \\[hv]box", log_text))
    if underfull:
        notes.append(f"{underfull} underfull box(es) (not fatal)")

# --- Report ----------------------------------------------------------------
print()
for note in notes:
    print(f"  note  {note}")
print()
if failures:
    print(f"FAILED: {len(failures)} check(s) did not pass.")
    sys.exit(1)
print("All checks passed.")
