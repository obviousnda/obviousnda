basename=obvious-nda
blanks=blanks.json.temporary
title=Obvious Nondisclosure Agreement
targets=$(basename:=.docx) $(basename:=.pdf) $(basename:.cform.signature)

cf=./node_modules/.bin/commonform
version=$(shell if git describe --exact-match --abbrev=0 > /dev/null 2>&1 ; then echo -n 'version ' && $(json) -f package.json version ; else echo -n 'Development Draft of ' && date --utc ; fi)
website=$(shell if git describe --exact-match --abbrev=0 > /dev/null 2>&1 ; then echo -n 'https:\/\/obviousnda.org' ; else echo -n '[Not Published]' ; fi)
digest=$(shell $(cf) hash < $(basename:=.cform) | cut -c1-6)

all: $(targets)

$(cf):
	npm install

$(blanks): fixed-blanks.json
	cat fixed-blanks.json \
	| sed "s/VERSION/$(version)/" \
	| sed "s/WEBSITE/$(website)/" \
	| sed "s/FINGERPRINT/$(digest)/" \
	> $@

%.docx: %.cform $(blanks) $(cf)
	$(cf) render \
		--format docx \
		--number outline \
		--title '$(title)' \
		--blanks $(blanks) \
    < $< > $@

%.pdf: %.docx
	doc2pdf $<

%.signature: %
	gpg --detach-sign --armor --local-user 'Obvious Nondisclosure Agreement Releases' --output $@ $<

.PHONY: clean

clean:
	rm -f $(targets)
