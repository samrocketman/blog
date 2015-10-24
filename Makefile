
.PHONY: all deps prod

serve:
	bundle exec jekyll serve --watch --config _config.yml,_config_local.yml,_config_dev.yml --drafts --unpublished

prod:
	bundle exec jekyll serve --watch --config _config.yml,_config_local.yml

deps:
	bundle install --jobs=3 --retry=3
