###
# PATHS
###
PANDOC ?= $(shell which pandoc)
INPUT_FOLDER ?= $(shell pwd)/src
OUTPUT_FOLDER ?= $(shell pwd)/dist
LIB_FOLDER ?= $(shell pwd)/lib

###
# OPTIONS
###
MARKDOWN_OPTIONS ?= markdown+tex_math_dollars+latex_macros
FILTER_OPTIONS ?= --filter pandoc-citeproc
CSS ?= $(LIB_FOLDER)/pandoc.css
HTML_TEMPLATE ?= $(LIB_FOLDER)/template.html
LATEX_TEMPLATE ?= $(LIB_FOLDER)/template.tex
LATEX_FILETYPE ?= pdf

###
# HELPERS
###
# cf. http://stackoverflow.com/a/16198793/1254484
APPEND_NEWLINES ?= sed -i '' -n p *.md

all: clean html pdf

html:
	cd $(INPUT_FOLDER); \
	$(APPEND_NEWLINES); \
	$(PANDOC) $(INPUT_FOLDER)/*.yml $(INPUT_FOLDER)/*.md \
	--from=$(MARKDOWN_OPTIONS) \
	--smart --html-q-tags --section-divs \
	--number-sections --variable numberedSections=true \
	--self-contained \
	--highlight-style=tango \
	--default-image-extension=svg --table-of-contents \
	$(FILTER_OPTIONS) \
	--template=$(HTML_TEMPLATE) --css=$(CSS) --standalone \
	--to=html5 --output=$(OUTPUT_FOLDER)/index.html; \
	echo "HTML done"

pdf:
	cd $(INPUT_FOLDER); \
	$(APPEND_NEWLINES); \
	$(PANDOC) $(INPUT_FOLDER)/*.yml $(INPUT_FOLDER)/*.md \
	--from=$(MARKDOWN_OPTIONS) \
	--default-image-extension=pdf --table-of-contents \
	--number-sections --variable numberedSections=true \
	$(FILTER_OPTIONS) \
	--template=$(LATEX_TEMPLATE) --listings \
	--latex-engine=pdflatex \
	--to=latex --output=$(OUTPUT_FOLDER)/index.$(LATEX_FILETYPE); \
	echo "PDF done"

epub:
	cd $(INPUT_FOLDER); \
	$(APPEND_NEWLINES); \
	$(PANDOC) $(INPUT_FOLDER)/*.yml $(INPUT_FOLDER)/*.md \
	--from=$(MARKDOWN_OPTIONS) \
	--smart --html-q-tags --section-divs \
	--highlight-style=tango \
	--default-image-extension=png --table-of-contents \
	$(FILTER_OPTIONS) \
	--standalone \
	--to=epub3 --output=$(OUTPUT_FOLDER)/index.epub; \
	echo "EPUB done"

text:
	cd $(INPUT_FOLDER); \
	$(APPEND_NEWLINES); \
	$(PANDOC) $(INPUT_FOLDER)/*.yml $(INPUT_FOLDER)/*.md \
	--from=$(MARKDOWN_OPTIONS) \
	--smart --html-q-tags --section-divs \
	--highlight-style=tango \
	--default-image-extension=png --table-of-contents \
	$(FILTER_OPTIONS) \
	--standalone \
	--to=plain --output=$(OUTPUT_FOLDER)/index.text; \
	echo "TEXT done"

stats: text
	wc -w $(OUTPUT_FOLDER)/index.text

clean:
	rm -rf $(OUTPUT_FOLDER)/*
