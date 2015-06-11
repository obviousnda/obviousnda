agreement = agreement.commonform
sources = $(agreement) fixed-blanks.json
basename = Obvious-Nondisclosure-Agreement
blanks = blanks.json.temporary
title = Obvious Nondisclosure Agreement

docx = $(addsuffix .docx,$(basename))
txt = $(addsuffix .txt,$(basename))
tex = $(addsuffix .tex,$(basename))
pdf = $(addsuffix .pdf,$(basename))
commonform = $(addsuffix .commonform,$(basename))
targets = $(docx) $(txt) $(commonform) $(pdf)
intermediaries = $(tex) $(blanks)

signatures = $(addsuffix .signature,$(targets))
cf = ./node_modules/.bin/commonform
jsontool = ./node_modules/.bin/json
version = $(shell $(jsontool) -f package.json version)
digest = $(shell $(cf) hash < $(agreement) | fold -w4 | paste -sd- -)

all: $(targets)

$(blanks): fixed-blanks.json package.json
	cp fixed-blanks.json $@
	sed --in-place "s/VERSION/$(version)/" $@
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

$(tex): $(sources) $(blanks)
	echo '\\overfullrule=0pt' > $@
	echo '\\parskip=6pt' >> $@
	echo '\\font\\tenbi=cmbxti10' >> $@
	echo '\\newfam\\bifam \\def\\bi{\\fam\\bifam\\tenbi} \\textfont\\bifam=\\tenbi' >> $@
	echo '\\centerline{\\bf Obvious Nondisclosure Agreement}\n' >> $@
	echo '\\centerline{version $(version)}\n' >> $@
	echo '\\vskip 1.5\\parskip' >> $@
	$(cf) render --title '$(title)' --blanks $(blanks) --format tex < $(agreement) >> $@
	echo '' >> $@
	echo '\\centerline{' >> $@
	echo '{\\leavevmode  \\vbox{\\hrule width2in}}' >> $@
	echo '{The Agreement ends here.}' >> $@
	echo '{\\leavevmode  \\vbox{\\hrule width2in}}' >> $@
	echo '}' >> $@
	echo '\\bye' >> $@

signatures: $(signatures)

%.signature: %
	gpg --detach-sign --armor --local-user 'Obvious Nondisclosure Agreement Releases' --output $@ $<

.PHONY: clean

clean:
	rm -f $(basename).* $(blanks)
