#!/bin/bash
#iterates across blog posts which have changed in git commits
#only signs blog posts which have changed

set -e

branch="$(docker run --rm ruby-blog bundle exec ruby ./make/get_yaml_key.rb github_branch)"
merge_base="$(git merge-base HEAD origin/"${branch}")"
git diff --name-status "${merge_base}" HEAD |
  awk '$0 ~ /_posts\/.*\.md$/ {print $2}' |
  xargs -n1 -- gpg -abs --yes
