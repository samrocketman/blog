#!/bin/bash
export PS4='$ '
export DEBIAN_FRONTEND=noninteractive
if [ ! -d ".git" ]; then
  echo 'ERROR: must be run from the root of the repository.  e.g.'
  echo './tests/signatures.sh'
  exit 1
fi
set -x

echo 'Importing public key for samrocketman.'

set -e

keyfile=$(mktemp --suffix=.gpg)

GPG="gpg --no-default-keyring --keyring ${keyfile}"

curl -sL 'https://keybase.io/samrocketman/key.asc' | ${GPG} --import

#fully trust public key 7257E65F
${GPG} --import-ownertrust <<EOF
8D8BF0E242D8A068572EBF3CE8F732347257E65F:6:
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
    if ! ${GPG} --verify "${x}.asc"; then
      echo "Failed signature for post: ${x}"
      return 1
    fi
  done
)

verify_sigs
STATUS=$?

rm -f "${keyfile}" "${keyfile}~"
exit $STATUS
