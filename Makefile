
.PHONY: all deps

serve:
	bundle exec jekyll serve --watch

deps:
	bundle install --jobs=3 --retry=3
