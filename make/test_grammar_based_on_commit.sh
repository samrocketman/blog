#!/bin/bash
export PS4='$ '
export DEBIAN_FRONTEND=noninteractive
if [ ! -d ".git" ]; then
  echo 'ERROR: must be run from the root of the repository.  e.g.'
  echo './make/test_grammar_based_on_commit.sh'
  exit 1
fi

#only test posts if they have been modified since origin/master

merge_base="$(git merge-base HEAD origin/master)"
posts="$(git diff --name-status $merge_base HEAD | awk '$0 ~ /(_posts|_drafts)\/.*\.md$/ {print $2}' | tr '\n' ' ' | sed 's/ $/\n/')"

if [ -n "${posts}" ]; then
  bundle exec ruby ./make/grammar.rb ${posts}
fi
