.PHONY: deps history prod serve test

serve:
	bundle exec jekyll serve --watch --config _config.yml,_config_local.yml,_config_dev.yml --drafts --unpublished

prod:
	bundle exec jekyll serve --watch --config _config.yml,_config_local.yml

deps:
	bundle install --jobs=3 --retry=3

test: history
	git diff --exit-code
	./tests/signatures.sh
	bundle exec jekyll build
	./tests/test_grammar_based_on_commit.sh

history:
	ruby ./tests/update_post_history.rb
