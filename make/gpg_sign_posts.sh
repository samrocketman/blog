#!/bin/bash
# Iterates across blog posts which have changed in git commits and only signs
# blog posts which have changed.  Alternately, force-sign a post by passing
# files to sign as arguments.  It will only sign markdown posts in the _posts/
# directory.

set -euxo pipefail

if [ "${#}" -gt 0 ]; then
  for file in "$@"; do
    # only sign valid _posts
    echo "${file}"
    if grep -- "^_posts/.*\\.md\$" <<< "${file}"; then
      gpg -abs --yes "${file}" > "${file}".asc
    fi
  done
else
  branch="$(docker run --rm ruby-blog bundle exec ruby ./make/get_yaml_key.rb github_branch)"
  merge_base="$(git merge-base HEAD origin/"${branch}")"
  git diff --name-status "${merge_base}" HEAD |
    awk '$0 ~ /_posts\/.*\.md$/ {print $2}' | while read file; do
      gpg -abs --yes "${file}" > "${file}".asc
    done
fi
