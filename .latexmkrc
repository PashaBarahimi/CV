# latexmk configuration -- keeps local builds and CI on the same path.

$pdf_mode = 1;                     # pdfLaTeX only (CV-SPEC.md sec. 1)
$postscript_mode = 0;
$dvi_mode = 0;

# -halt-on-error makes a LaTeX error a non-zero exit, so CI actually fails.
$pdflatex = 'pdflatex -interaction=nonstopmode -halt-on-error -file-line-error %O %S';

$max_repeat = 5;                   # enough for lastpage/hyperref to settle
@default_files = ('cv.tex');

$clean_ext = 'synctex.gz run.xml bbl fdb_latexmk fls';
