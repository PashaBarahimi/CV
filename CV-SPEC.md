# CV Formatting & Engineering Specification

The authoritative description of how this CV is built. It records decisions as
they now stand, not the original rebuild brief — the defects that motivated the
rebuild are fixed and no longer listed.

Where this document and the sources disagree, the sources are the bug.

---

## 1. Toolchain

| Decision | Choice | Rationale |
|---|---|---|
| Engine | **pdfLaTeX** | `XCharter` and `fontawesome5` both work under it. Avoids `fontspec` and system-font resolution in CI — the usual cause of "works locally, fails in Actions". |
| Build driver | **latexmk**, configured in `.latexmkrc` | Handles rerun-for-references; `-halt-on-error` means a LaTeX error cannot exit 0. |
| Font | **XCharter** throughout, including real small caps | One family: fewer embedded subsets, no second font to resolve. |
| Icons | `fontawesome5` | |
| Math | Not used. Ordinals such as `1st` are **text mode** (`\cvordinal`), never math. |

`fix-cm` is loaded before any font package. Computer Modern ships only in
discrete sizes and the 10.5pt body size is not one of them; without it the
residual CM families emit size-substitution warnings.

Do not switch to XeLaTeX or LuaLaTeX.

---

## 2. Page geometry & type

- Paper: **A4** by default. `make letter` builds a US Letter variant.
- Margins: **1.8 cm** all round on A4. The Letter variant uses **1.5 cm** — it
  is ~50pt shorter than A4 and does not otherwise hold two pages.
- Body: **10.5pt**. `article` has no 10.5pt option, so the class loads at 11pt
  and steps down via the `fontsize` package. Do not go below 10pt.
- Line spacing: `\linespread{1.05}`.
- Running header (`fancyhdr`): pages 2+ carry the name left and `Page N of M`
  right, at `\footnotesize` in muted grey with a thin rule. Page 1 is exempt.
  The `\pageref*` is unlinked so no header text is accent-coloured.

---

## 3. Colour

Three colours, each with one job:

| Token | Value | Used for |
|---|---|---|
| `accent` | `#1F3864` | Section headings and their rules — **structure only** |
| `cvlink` | `#4F6180` | Every hyperlink |
| `cvmuted` | `#6E6E6E` | Running header, tagline, last-updated stamp — page furniture |

Links are a deliberate step below the accent. When both shared one colour,
inline links out-competed section headings for attention.

`\cvinst` is bold and linked — **all of them or none**; a mix reads as an
error. To disable globally, redefine it as `{\textbf{#2}}`.

`hyperref` is configured `colorlinks=true`, `allcolors=cvlink`, with
`pdftitle`, `pdfauthor` and `pdfsubject` populated from `\cvname`.

No photo, skill bars, percentage meters, or emoji.

---

## 4. Typography

- **Ragged right**, via `ragged2e`. A CV is read in fragments; justification
  bought a flush edge at the cost of visibly stretched word spacing.
- **No automatic hyphenation** (`\hyphenpenalty=10000`). Breaks at hyphens
  already in a word are legal but discouraged (`\exhyphenpenalty=100`) —
  forbidding them outright makes a long hyphenated compound unbreakable, which
  overflows the line.
- `microtype` for protrusion and expansion.
- The name is letterspaced (`\textls[60]`); the tagline is one size down in
  `cvmuted`.
- Section headings: `\large`, bold, small caps, in `accent`, over a full-width
  0.8pt `accent` rule.
- En-dashes (`--`) for ranges. Non-breaking spaces before numerals in
  cross-references.
- `\Csharp` and `\Cpp` exist because those glyphs carry sidebearings sized for
  standalone symbols; unkerned they set as "C #" and "C + +".

### Separators

One mark, one meaning:

- **En-dash** — date ranges only.
- **Comma** — entry title from institution (`\cvevent`), role from course
  (`\cvteaching`), award from qualifier (`\cvhonor`).
- **Middot** — advisor from funding (`\cvadvisor`), and between contact items.

`\cvproject` keeps an en-dash between title and stack: it carries no date, so
nothing collides.

---

## 5. Vertical rhythm & page breaks

Exactly three spacing constants. Nothing else introduces vertical space.

| Constant | Value | Meaning |
|---|---|---|
| `\cvSectionSkip` | 10pt | above a section heading |
| `\cvRuleSkip` | 4pt | below a section rule |
| `\cvEntrySkip` | 5pt | between entries |

Space above a heading exceeds the space below its rule, so headings group with
what follows.

Page-break control:

- `\widowpenalty`, `\clubpenalty`, `\displaywidowpenalty`, `\brokenpenalty` all
  10000.
- `\cvsection` reserves `8\baselineskip`; entries reserve `\cv@entryneed`
  (`6\baselineskip`). That figure is derived: the forbidden bottom 15% band
  begins ~75pt above the foot of the text block on both paper sizes, and six
  baselines is ~79pt.
- The **first** entry after a section heading deliberately skips its own
  `needspace`. `needspace` works by offering a legal breakpoint, so calling it
  immediately after a section rule hands TeX permission to break exactly where
  a heading would be stranded.
- `\raggedbottom`. `\flushbottom` was tried to even out short pages and made
  things worse — it changed the page builder's decisions and added a page.

A consequence worth knowing: entries are atomic, so an entry that does not fit
moves whole and can leave a gap at the foot of a page. That is the accepted
cost of never splitting an entry across pages.

---

## 6. Dates

**Canonical format: `Mon YYYY -- Mon YYYY`** (en-dash), right-aligned, in body
size and colour, in every section.

- Ongoing roles end in `Present`.
- Single-point dates (awards, publications) are the year alone, right-aligned.
- `\cvteaching` may take academic term names instead, where a single range
  would misstate a non-contiguous period. They render with the same alignment,
  size and colour as every other date. Never grey, never small caps.
- The last-updated stamp uses the same abbreviated `Mon YYYY` vocabulary.

---

## 7. Semantic macros

Content files contain no formatting code. If a section file needs `\vspace` or
`\textbf`, the macro is missing from the class.

```latex
\cvsection{Name}
\cvevent{Role}{Institution}{Mon YYYY -- Mon YYYY}{Subtitle}
\cvadvisor[funding note]{Name}
\cvsummary{One clause framing what the work was about}
\cvpublication[venue note]{Title}{Authors}{Venue}{Year}
\cvproject{Title}{Stack}{Subtitle}
\cvhonor{Year}{Award}{Detail}      % inside cvhonorlist
\cvteaching{Role}{Course}{Terms}   % inside cvteachinglist
\cvskill{Label}{List}              % inside cvskilllist
\cvitem{...}                       % inside cvitems
\cvprose{...}
\cvlastupdated
```

Inline: `\cvme` (the author's own name, bolded), `\cvinst{url}{Name}`,
`\cvlink{url}{Text}`, `\cvordinal{1}{st}`, `\cvapprox`, `\Csharp`, `\Cpp`,
`\cvtodo{note}`.

Header: `\cvname`, `\cvtagline`, and inside `cvcontacts` — `\cvemail`,
`\cvwebsite`, `\cvgithub`, `\cvlinkedin`, `\cvscholar`, `\cvorcid`,
`\cvlocation`, plus `\cvcontactbreak` to split the row deliberately.

---

## 8. Repository layout

```
cv.tex                     master document — section order lives here
cvstyle.cls                all design decisions
.latexmkrc                 build settings, shared by local builds and CI
sections/*.tex             content, one file per section
tools/verify-pdf.py        the checks, run locally and in CI
Makefile                   all / letter / watch / verify / clean / distclean
.github/workflows/build.yml
```

`Makefile` targets go through `latexmk` rather than `rm`, so they work without a
POSIX shell. `verify` runs `latexmk` unconditionally — the checks read the
`.log` as well as the `.pdf`, and `clean` removes the log while leaving the PDF.

The built PDF is **not** committed. CI publishes it instead.

---

## 9. Verification

`tools/verify-pdf.py` runs identically locally and in CI, so a green
`make verify` means a green build. It is pure Python with no shell dependency.

Enforced:

- Page count is exactly `EXPECTED_PAGES` (2) — the guardrail against content
  creep. **Shorten content rather than raising it.**
- No section or entry heading in the bottom `BOTTOM_BAND` (15%) of any page,
  and no heading left with fewer than two lines beneath it.
- Every heading the script checks actually exists in the PDF, so renaming a
  section cannot silently turn a check into a no-op.
- No date range uses an ASCII hyphen; every `Mon YYYY` token belongs to a
  canonical en-dashed range; the last-updated stamp is present and canonical.
- Pages 2+ carry name and page number; page 1 does not.
- PDF title and author metadata populated.
- Log clean: no undefined references, no multiply-defined labels, no warnings
  outside `WARNING_ALLOWLIST` (empty), no overfull box above `MAX_OVERFULL_PT`
  (5pt).

Note: poppler extracts glyphs with no Unicode mapping as C0 control characters
— the ORCID mark comes back as `0x1A` — which XML 1.0 forbids, so its own bbox
output is not well-formed. The script strips the illegal ranges before parsing.

---

## 10. GitHub Actions

`.github/workflows/build.yml`. Triggers: push to `main`, pull request, `v*`
tags, manual dispatch. Concurrency keyed on the ref with `cancel-in-progress`.

1. Compile with `xu-cheng/latex-action@4.1.0`, `texlive_version: 2026`.
2. Install `poppler-utils`, then run `tools/verify-pdf.py`.
3. Upload the PDF as `cv-<short-sha>.pdf`, retained 90 days.
4. Create a Release and attach the PDF as `cv.pdf` via the bundled `gh` CLI —
   one fewer third-party action to pin. Runs on a `v*` tag, or on a manual
   dispatch with the `release` input set.

Build artifacts stay sha-stamped so runs can be told apart; the release asset is
renamed to `cv.pdf` so that `releases/latest/download/cv.pdf` is a permanent,
login-free URL for the current version.

The manual path derives its tag from the UTC date as `vYY.MM.DD`, appending
`-2`, `-3` … if that tag already exists. `gh release create --target` creates
the tag at the built commit, so no checkout or `git push` is needed; on a tag
push the tag already exists and the target is ignored. A tag created this way
does not re-trigger the workflow, because pushes made with `GITHUB_TOKEN` do
not start new runs.

Workflow permissions are `contents: read`; only the release job is granted
`contents: write`.

Everything is pinned to an exact release. Reproducibility over freshness.
`upload-artifact` v7 pairs with `download-artifact` v7 — v8 removed the `name`
input, so do not bump one without the other.

---

## 11. Deliberately not built

- **ATS variant** (single column, no icons, black only). Viable — the content
  files are class-agnostic — but not implemented.
- **GitHub Pages publication** for a stable PDF URL. Artifacts expire after 90
  days and need a login; release assets do not expire and are the durable path.
