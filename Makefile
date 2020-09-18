.PHONY: deps history prod serve sign test
OS_KERNEL := $(shell uname -s)
PWD := $(shell pwd)
YEAR := $(shell date +%Y)
MONTH := $(shell date +%m)
DAY := $(shell date +%d)
DATESTAMP := $(shell date +%Y-%m-%d)
RUBY_BLOG := $(shell docker images --filter=reference=ruby-blog:latest -q )
ifndef RUBY_BLOG
	ADDITIONAL_TARGETS := deps
endif

ifneq ($(DRAFT),)
	DRAFT := $(DRAFT)
endif

serve: $(ADDITIONAL_TARGETS)
	docker run -it --rm -v '$(PWD)':/mnt -w /mnt --init --rm -p 4000:4000 -- ruby-blog \
	bundle exec jekyll serve --watch --config _config.yml,_config_local.yml,_config_dev.yml --drafts --unpublished --host=0.0.0.0

prod:
	docker run -it --rm -v '$(PWD)':/mnt -w /mnt --init --rm -p 4000:4000 -- ruby-blog \
	bundle exec jekyll serve --watch --config _config.yml,_config_local.yml --host=0.0.0.0

deps:
	docker build -t ruby-blog .
#	bundle install --jobs=3 --retry=3

test: $(ADDITIONAL_TARGETS) history
	git diff --exit-code
	docker run -t --rm -v '$(PWD)':/mnt -w /mnt --init --rm -- ruby-blog \
	./make/verify_signatures.sh
	docker run -t --rm -v '$(PWD)':/mnt -w /mnt --init --rm -- ruby-blog \
	bundle exec jekyll build
#	./make/test_grammar_based_on_commit.sh

update-gemfile: deps
	\rm -f Gemfile.lock
	docker run -t --rm -v '$(PWD)':/mnt -w /mnt --init --rm -- ruby-blog \
	bundle install --jobs=3 --retry=3

history:
	docker run -t --rm -v '$(PWD)':/mnt -w /mnt --init --rm -- ruby-blog \
	bundle exec ruby ./make/update_post_history.rb

promote:
	set -ex; \
	if [ '$(DRAFT)' = '' ]; then echo 'ERROR: must run "make promote DRAFT=draft.md" for posts in the _drafts folder'; exit 1; fi; \
	if [ ! -f ./_drafts/'$(DRAFT)' ]; then echo 'ERROR: draft post "./_drafts/$(DRAFT)" does not exist'; exit 1; fi; \
	sed -i.bak -e '/---/,/---/s/^year:.*/year: $(YEAR)/' ./_drafts/'$(DRAFT)'; \
	sed -i.bak -e '/---/,/---/s/^month:.*/month: $(MONTH)/' ./_drafts/'$(DRAFT)'; \
	sed -i.bak -e '/---/,/---/s/^day:.*/day: $(DAY)/' ./_drafts/'$(DRAFT)'; \
	\rm ./_drafts/'$(DRAFT)'.bak; \
	mv ./_drafts/'$(DRAFT)' _posts/$(DATESTAMP)-$(DRAFT)

sign:
	./make/gpg_sign_posts.sh $(FILES)
