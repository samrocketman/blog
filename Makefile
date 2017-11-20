.PHONY: deps history prod serve sign test

serve:
	bundle exec jekyll serve --watch --config _config.yml,_config_local.yml,_config_dev.yml --drafts --unpublished

prod:
	bundle exec jekyll serve --watch --config _config.yml,_config_local.yml

deps:
	bundle install --jobs=3 --retry=3

test: history
	git diff --exit-code
	./make/verify_signatures.sh
	bundle exec jekyll build
	./make/test_grammar_based_on_commit.sh

history:
	bundle exec ruby ./make/update_post_history.rb

sign:
	./make/gpg_sign_posts.sh
