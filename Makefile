agreement = agreement.commonform
sources = $(agreement) fixed-blanks.json
basename = Obvious-Nondisclosure-Agreement
blanks = blanks.json.temporary
title = Obvious Nondisclosure Agreement

docx = $(addsuffix .docx,$(basename))
txt = $(addsuffix .txt,$(basename))
commonform = $(addsuffix .commonform,$(basename))
targets = $(docx) $(txt) $(commonform)

signatures = $(addsuffix .signature,$(targets))
cf = ./node_modules/.bin/commonform
jsontool = ./node_modules/.bin/json
version = $(shell $(jsontool) -f package.json version)

all: $(targets)

$(blanks): fixed-blanks.json package.json
	sed "s/VERSION/$(version)/" fixed-blanks.json > $@

$(commonform): $(agreement)
	cp $(agreement) $@

$(docx): $(sources) $(blanks)
	$(cf) render --title '$(title)' --blanks $(blanks) --format docx < $(agreement) > $@

$(txt): $(sources) $(blanks)
	$(cf) render --title '$(title)' --blanks $(blanks) --format terminal < $(agreement) > $@

signatures: $(signatures)

%.signature: %
	gpg --detach-sign --armor --local-user 'Obvious Nondisclosure Agreement Releases' --output $@ $<

.PHONY: clean

clean:
	rm -f $(targets) $(signatures) $(blanks)
