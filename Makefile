agreement = agreement.commonform
sources = $(agreement) fixed-blanks.json
basename = Obvious-NDA
blanks = blanks.json.temporary
title = Obvious Nondisclosure Agreement

docx = $(addsuffix .docx,$(basename))
txt = $(addsuffix .txt,$(basename))
tex = $(addsuffix .tex,$(basename))
pdf = $(addsuffix .pdf,$(basename))

license = LICENSE.md
license-docx = $(license:.md=.docx)
license-pdf = $(license:.md=.pdf)
licenses = $(license) $(license-docx) $(license-pdf)

readme = README.md
readme-docx = $(readme:.md=.docx)
readme-pdf = $(readme:.md=.pdf)
readmes = $(readme) $(readme-docx) $(readme-pdf)

contributing = CONTRIBUTING.md
contributing-docx = $(contributing:.md=.docx)
contributing-pdf = $(contributing:.md=.pdf)
contributings = $(contributing) $(contributing-docx) $(contributing-pdf)

commonform = $(addsuffix .commonform,$(basename))
targets = $(contributings) $(licenses) $(readmes) $(docx) $(txt) $(commonform) $(pdf)
intermediaries = $(tex) $(blanks)

signatures = $(addsuffix .signature,$(targets))
cf = ./node_modules/.bin/commonform
json = ./node_modules/.bin/json
version = $(shell if git describe --exact-match --abbrev=0 > /dev/null 2>&1 ; then echo -n 'version ' && $(json) -f package.json version ; else echo -n 'Development Draft of ' && date --utc ; fi)
website = $(shell if git describe --exact-match --abbrev=0 > /dev/null 2>&1 ; then echo -n 'http:\/\/obviousnda.org' ; else echo -n '[Not Published]' ; fi)
digest = $(shell $(cf) hash < $(agreement) | cut -c1-6)

all: $(targets)

$(blanks): fixed-blanks.json package.json agreement.commonform
	cp fixed-blanks.json $@
	sed --in-place "s/VERSION/$(version)/" $@
	sed --in-place "s/WEBSITE/$(website)/" $@
	sed --in-place "s/FINGERPRINT/$(digest)/" $@

$(commonform): $(agreement)
	cp $(agreement) $@

$(docx): $(sources) $(blanks)
	$(cf) render --title '$(title)' --blanks $(blanks) --format docx < $(agreement) > $@

$(txt): $(sources) $(blanks)
	$(cf) render --title '$(title)' --blanks $(blanks) --format terminal < $(agreement) > $@

$(pdf): $(tex)
	tex -interaction batchmode $(tex)
	dvipdf *.dvi

%.pdf: %.md
	pandoc -f markdown -t latex -o $@ $<

%.docx: %.md
	pandoc -f markdown -t docx -o $@ $<

$(tex): $(sources) $(blanks)
	echo '\\overfullrule=0pt' > $@
	echo '\\parskip=6pt' >> $@
	echo '\\font\\tenbi=cmbxti10' >> $@
	echo '\\newfam\\bifam \\def\\bi{\\fam\\bifam\\tenbi} \\textfont\\bifam=\\tenbi' >> $@
	echo '\\centerline{\\bf Obvious Nondisclosure Agreement}\n' >> $@
	echo '\\centerline{$(version)}\n' >> $@
	echo '\\vskip 1.5\\parskip' >> $@
	$(cf) render --title '$(title)' --blanks $(blanks) --format tex < $(agreement) >> $@
	echo '' >> $@
	echo '\\noindent{\\leavevmode  \\vbox{\\hrule width\hsize}}' >> $@
	echo '\\bye' >> $@

signatures: $(signatures)

%.signature: %
	gpg --detach-sign --armor --local-user 'Obvious Nondisclosure Agreement Releases' --output $@ $<

.PHONY: clean

clean:
	rm -f $(basename).* *.docx *.pdf $(blanks) $(signatures)
