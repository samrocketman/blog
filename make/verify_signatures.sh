#!/bin/bash
export PS4='$ '
export DEBIAN_FRONTEND=noninteractive
if [ ! -d ".git" ]; then
  echo 'ERROR: must be run from the root of the repository.  e.g.'
  echo './make/verify_signatures.sh'
  exit 1
fi
set -x

echo 'Importing public key for samrocketman.'

set -e

keyfile=$(mktemp --suffix=.gpg)

GPG=( gpg --no-default-keyring --keyring "${keyfile}" )
keybase_user="$(bundle exec ruby ./make/get_yaml_key.rb keybase_user)"
gpg_key="$(bundle exec ruby ./make/get_yaml_key.rb gpg_key)"
gpg_key_url="$(bundle exec ruby ./make/get_yaml_key.rb gpg_key_url)"

if [ -f "${gpg_key_url}" ]; then
  "${GPG[@]}" --batch --import < "${gpg_key_url}"
else
  curl -sL "${gpg_key_url}" | "${GPG[@]}" --batch --import
fi

#fully trust public key for verification
"${GPG[@]}" --import-ownertrust <<EOF
${gpg_key}:6:
EOF

echo 'Verifying post signatures.'

set +e

function verify_sigs() (
  cd _posts
  for x in *.md; do
    if [ ! -e "${x}.asc" ]; then
      echo "Missing signature for post: ${x}"
      return 1
    fi
    if ! "${GPG[@]}" --verify-options show-primary-uid-only --verify "${x}.asc"; then
      echo "Failed signature for post: ${x}"
      return 1
    fi
  done
)

verify_sigs
STATUS=$?

rm -f "${keyfile}" "${keyfile}~"
exit $STATUS
