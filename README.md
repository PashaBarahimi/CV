# Academic CV

LaTeX sources for a two-page academic CV, built and checked automatically in
GitHub Actions.

Design lives in `cvstyle.cls`. Content lives in `sections/*.tex` and contains no
formatting code — only semantic macros. If you find yourself typing `\vspace` or
`\textbf` into a section file, the macro you need is missing from the class.

---

## Building

```sh
make            # build cv.pdf (A4)
make verify     # build, then run the checks
make watch      # continuous rebuild + preview while editing
make letter     # build cv-letter.pdf (US Letter)
make clean      # remove auxiliary files
make distclean  # remove auxiliary files and the PDFs
make help       # list targets
```

**Requirements:** TeX Live with `latexmk`, plus Python 3 and poppler's
`pdfinfo`/`pdftotext` for `make verify` (both ship with TeX Live).

On Windows, Python is usually `python` rather than `python3`:

```sh
make PYTHON=python verify
```

The built PDF is not committed — CI publishes it instead.

---

## Editing content

Open the relevant file in `sections/` and use these macros.

| Macro | Use |
|---|---|
| `\cvsection{Name}` | Section heading with rule (called from `cv.tex`) |
| `\cvevent{Role}{Institution}{Dates}{Subtitle}` | A job, degree or appointment |
| `\cvadvisor[funding]{Name}` | Advisor credit, on its own line under an entry |
| `\cvsummary{...}` | One clause framing an entry, above its bullets |
| `\cvpublication[note]{Title}{Authors}{Venue}{Year}` | A paper; optional note follows the venue |
| `\cvproject{Title}{Stack}{Subtitle}` | A project (no dates) |
| `\cvhonor{Year}{Award}{Detail}` | An award — inside `cvhonorlist` |
| `\cvteaching{Role}{Course}{Terms}` | A course — inside `cvteachinglist` |
| `\cvskill{Label}{List}` | A skills row — inside `cvskilllist` |
| `\cvprose{...}` | A free-standing paragraph |
| `\cvitem{...}` | A bullet — inside `cvitems` |
| `\cvme` | The author's own name, bolded, for author lists |
| `\cvinst{url}{Name}` | An institution name (bold, linked) |
| `\cvlink{url}{Text}` | Any other hyperlink |
| `\cvordinal{1}{st}` | Text-mode ordinal — never use math mode for this |
| `\Csharp` / `\Cpp` | Correctly kerned "C#" and "C++" — do not type `C\#`, it sets as "C #" |
| `\cvapprox` | Upright text tilde for "approximately" |
| `\cvtodo{note}` | A visible `[TODO: note]` placeholder |

The header uses `\cvname`, `\cvtagline`, and inside `cvcontacts`:
`\cvemail`, `\cvwebsite`, `\cvgithub`, `\cvlinkedin`, `\cvscholar`, `\cvorcid`,
`\cvlocation`, plus `\cvcontactbreak` to split the contact row deliberately.
`\cvlastupdated` sits at the end of `cv.tex`.

To reorder or add a section, edit `cv.tex` — it is just a list of
`\cvsection` + `\input` pairs.

Placeholders are meant to be conspicuous. Before sending the CV anywhere:

```sh
grep -rn 'cvtodo' sections/
```

---

## Continuous integration

`.github/workflows/build.yml` runs on pushes to `main`, on pull requests, on
`v*` tags, and on manual dispatch. Concurrent runs for the same ref cancel each
other.

1. Compiles `cv.tex` with `xu-cheng/latex-action`, pinned to `4.1.0` with
   TeX Live pinned to `2026`.
2. Runs `tools/verify-pdf.py`, which fails the build on any check violation.
3. Uploads the PDF as `cv-<short-sha>.pdf`, retained 90 days.
4. Publishes a GitHub Release with the PDF attached, on a `v*` tag or a manual
   run with the release box ticked. That job is the only one granted
   `contents: write`.

A LaTeX error fails the build rather than producing a broken PDF: `.latexmkrc`
sets `-halt-on-error`, so `latexmk` cannot exit 0 on a broken document.

### Cutting a release

Either run the workflow from the Actions tab with **"Tag vYY.MM.DD and publish
a release"** ticked — the tag is derived from today's date (`v26.08.13`), and
gains a `-2`, `-3` suffix if that tag already exists — or tag by hand:

```sh
git tag v1.0 && git push origin v1.0
```

Release assets do not expire, unlike the 90-day build artifacts, and the asset
is always named `cv.pdf`, so a release gives you a permanent link:

```
https://github.com/<owner>/<repo>/releases/latest/download/cv.pdf
```

That URL always serves the most recent release — use it for a lab page or an
email signature rather than an artifact link, which expires and needs a login.

A tag created by the workflow does not itself re-trigger the workflow, since
pushes made with `GITHUB_TOKEN` do not start new runs.

### What `make verify` checks

The same script runs locally and in CI, so a green `make verify` means a green
build. It asserts the page count, that no heading is stranded at the foot of a
page, that every date uses the same format, that the running header appears on
pages 2+ and not on page 1, that PDF metadata is populated, and that the LaTeX
log is free of warnings and oversized overfull boxes.

It also asserts that every heading it looks for actually exists in the PDF, so
renaming a section cannot silently turn a check into a no-op.

**If the page-count check fails after you add content,** that is the check doing
its job. Shorten something rather than raising `EXPECTED_PAGES`.

---

## Acknowledgement

Based on [jitinnair1/autoCV](https://github.com/jitinnair1/autoCV).
