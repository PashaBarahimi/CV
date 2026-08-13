# Local build driver. CI runs the same latexmk and the same checks -- see
# .github/workflows/build.yml.

MAIN    := cv
LATEXMK ?= latexmk
# Windows users: `make PYTHON=python verify`
PYTHON  ?= python3

SOURCES := $(MAIN).tex cvstyle.cls $(wildcard sections/*.tex)

.PHONY: all letter watch verify clean distclean help

all: $(MAIN).pdf

$(MAIN).pdf: $(SOURCES)
	$(LATEXMK) -pdf $(MAIN).tex

# US Letter variant. cv.tex names no paper size, so the option is injected on
# the command line rather than edited into the source.
letter:
	$(LATEXMK) -pdf -jobname=$(MAIN)-letter \
	  -pdflatex='pdflatex -interaction=nonstopmode -halt-on-error -file-line-error %O "\PassOptionsToClass{letterpaper}{cvstyle}\input{%S}"' \
	  $(MAIN).tex

# Continuous preview: rebuilds and refreshes the viewer on every save.
watch:
	$(LATEXMK) -pdf -pvc $(MAIN).tex

# The acceptance tests from CV-SPEC.md sec. 8. Run this before pushing.
#
# Runs latexmk unconditionally rather than depending on $(MAIN).pdf: the checks
# read the .log as well as the .pdf, and `make clean` removes the log while
# leaving the PDF -- which would otherwise satisfy the dependency and leave
# verify with no log to read. latexmk is incremental, so this stays cheap.
verify:
	$(LATEXMK) -pdf $(MAIN).tex
	@$(PYTHON) tools/verify-pdf.py $(MAIN).pdf $(MAIN).log

# clean/distclean go through latexmk rather than rm, so they work on Windows
# without a POSIX shell. The leading `-` tolerates a letter build that was
# never made.
clean:
	$(LATEXMK) -c $(MAIN).tex
	-$(LATEXMK) -c -jobname=$(MAIN)-letter $(MAIN).tex

distclean:
	$(LATEXMK) -C $(MAIN).tex
	-$(LATEXMK) -C -jobname=$(MAIN)-letter $(MAIN).tex

help:
	@echo "make            build cv.pdf (A4)"
	@echo "make letter     build cv-letter.pdf (US Letter)"
	@echo "make watch      continuous rebuild + preview"
	@echo "make verify     build, then run the CV-SPEC acceptance tests"
	@echo "make clean      remove auxiliary files"
	@echo "make distclean  remove auxiliary files and the PDFs"
