
.PHONY: all deps prod

serve:
	bundle exec jekyll serve --watch --config _config.yml,_config_dev.yml --drafts --unpublished

prod:
	bundle exec jekyll serve --watch

deps:
	bundle install --jobs=3 --retry=3
