
.PHONY: all deps

serve:
	bundle exec jekyll serve --watch --config _config.yml,_config_dev.yml --drafts --unpublished

deps:
	bundle install --jobs=3 --retry=3
