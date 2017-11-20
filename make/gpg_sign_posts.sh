#!/bin/bash
#iterates across blog posts which have changed in git commits
#only signs blog posts which have changed

set -e

merge_base="$(git merge-base HEAD origin/master)"
git diff --name-status "${merge_base}" HEAD |
  awk '$0 ~ /_posts\/.*\.md$/ {print $2}' |
  xargs -n1 -- gpg -abs --yes
